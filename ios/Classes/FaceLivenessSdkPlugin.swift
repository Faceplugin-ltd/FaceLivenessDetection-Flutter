import Flutter
import UIKit

/// Bridges Flutter to the native FacePlugin liveness implementation.
///
/// The engine and both camera screens are the native ones — `FaceEngine` from the vendored
/// `FaceLivenessKit`, `ActiveLivenessViewController` and `LivenessCameraViewController`. Nothing
/// about liveness is re-implemented in Dart, so the camera preview, the anti-spoofing gate, the
/// challenge sequence and the result card behave exactly as they do in
/// Face-LivenessDetection-iOS.
public class FaceLivenessSdkPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "face_liveness_sdk",
                                           binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(FaceLivenessSdkPlugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            guard let license = (call.arguments as? [String: Any])?["license"] as? String,
                  !license.trimmingCharacters(in: .whitespaces).isEmpty
            else {
                result(FlutterError(code: "E_LICENSE",
                                    message: "A license key is required.", details: nil))
                return
            }
            // The kit activates and initialises on its own worker and calls back on the main
            // queue, so this is already off the platform thread.
            FaceEngine.shared.start(license: license) { code in result(code) }

        case "licenseStatus":
            FaceEngine.shared.async {
                let status = FaceEngine.shared.licenseStatus()
                DispatchQueue.main.async { result(Self.map(status)) }
            }

        case "lastLicenseError":
            result(FaceEngine.shared.lastLicenseError())

        case "machineCode":
            FaceEngine.shared.async {
                let code = FaceEngine.shared.machineCode()
                DispatchQueue.main.async { result(code) }
            }

        case "startActiveLiveness":
            startActiveLiveness(call.arguments as? [String: Any] ?? [:], result)

        case "startPassiveLiveness":
            startPassiveLiveness(call.arguments as? [String: Any] ?? [:], result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Screens

    private func startActiveLiveness(_ args: [String: Any], _ result: @escaping FlutterResult) {
        guard let host = Self.topViewController() else {
            result(FlutterError(code: "E_NO_VIEW_CONTROLLER",
                                message: "No view controller to present from.", details: nil))
            return
        }
        AppSettings.useFrontCamera = args["useFrontCamera"] as? Bool ?? true
        AppSettings.livenessThreshold =
            (args["livenessThreshold"] as? NSNumber)?.floatValue
                ?? ActiveLivenessOptions.defaultLivenessThreshold

        ActiveLivenessViewController.present(from: host, options: Self.options(from: args)) { outcome in
            // A closed screen produces no result, which Dart reads as null.
            result(outcome.map(Self.map))
        }
    }

    private func startPassiveLiveness(_ args: [String: Any], _ result: @escaping FlutterResult) {
        guard let host = Self.topViewController() else {
            result(FlutterError(code: "E_NO_VIEW_CONTROLLER",
                                message: "No view controller to present from.", details: nil))
            return
        }
        AppSettings.useFrontCamera = args["useFrontCamera"] as? Bool ?? true
        AppSettings.livenessThreshold =
            (args["livenessThreshold"] as? NSNumber)?.floatValue ?? 0.5

        let controller = LivenessCameraViewController()
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        nav.setNavigationBarHidden(true, animated: false)
        host.present(nav, animated: true)
        result(nil)
    }

    // MARK: - Mapping

    /// Builds the native options from the Dart payload, falling back to the engine's defaults.
    private static func options(from args: [String: Any]) -> ActiveLivenessOptions {
        var options = ActiveLivenessOptions()
        if let keys = args["pool"] as? [String] {
            // Keep the canonical enum order so the pool is stable when randomize is off.
            let wanted = Set(keys)
            let pool = ActiveCheck.allCases.filter { wanted.contains($0.key) }
            if !pool.isEmpty { options.pool = pool }
        }
        func int(_ key: String) -> Int? { (args[key] as? NSNumber)?.intValue }
        func float(_ key: String) -> Float? { (args[key] as? NSNumber)?.floatValue }
        func bool(_ key: String) -> Bool? { args[key] as? Bool }

        options.count = int("count") ?? options.count
        options.randomize = bool("randomize") ?? options.randomize
        options.livenessThreshold = float("livenessThreshold") ?? options.livenessThreshold
        options.passiveSamples = int("passiveSamples") ?? options.passiveSamples
        options.framesWait = int("framesWait") ?? options.framesWait
        options.yawThreshold = float("yawThreshold") ?? options.yawThreshold
        options.pitchThreshold = float("pitchThreshold") ?? options.pitchThreshold
        options.smileThreshold = float("smileThreshold") ?? options.smileThreshold
        options.blinkThreshold = float("blinkThreshold") ?? options.blinkThreshold
        options.blinksNumber = int("blinksNumber") ?? options.blinksNumber
        options.perspectiveThreshold = float("perspectiveThreshold") ?? options.perspectiveThreshold
        options.alignAngle = float("alignAngle") ?? options.alignAngle
        options.minFaceFraction = float("minFaceFraction") ?? options.minFaceFraction
        options.qualityThreshold = float("qualityThreshold") ?? options.qualityThreshold
        options.invertTurn = bool("invertTurn") ?? options.invertTurn
        options.invertTilt = bool("invertTilt") ?? options.invertTilt
        return options
    }

    private static func map(_ status: LicenseStatus) -> [String: Any] {
        [
            "licensed": status.licensed,
            "level": status.level,
            "levelName": status.levelName,
            "recognition": status.recognition,
            "liveness": status.liveness,
            "label": status.label,
        ]
    }

    private static func map(_ result: ActiveLivenessResult) -> [String: Any] {
        [
            "passed": result.passed,
            "failure": wire(result.failure),
            "passiveScore": result.passiveScore,
            "passivePassed": result.passivePassed,
            "challenges": result.challenges.map { $0.key },
            "outcomes": result.outcomes.map(wire),
            "durationMs": result.durationMs,
        ]
    }

    /// The wire names Dart and Android share.
    private static func wire(_ failure: ActiveLivenessSession.Failure) -> String {
        switch failure {
        case .none: return "NONE"
        case .spoof: return "SPOOF"
        case .check: return "CHECK"
        case .timeout: return "TIMEOUT"
        case .cancelled: return "CANCELLED"
        }
    }

    private static func wire(_ step: ActiveLivenessSession.StepState) -> String {
        switch step {
        case .pending: return "PENDING"
        case .active: return "ACTIVE"
        case .passed: return "PASSED"
        case .failed: return "FAILED"
        }
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
            ?? scenes.first?.windows.first
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
