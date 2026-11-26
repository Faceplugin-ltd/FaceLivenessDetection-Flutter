/// Engine lifecycle state, mirroring Android `FaceEngine.State` and iOS `FaceEngine.State`.
enum EngineState {
  loading,
  ready,
  notActivated,
  licenseInvalid,
  licenseExpired,
  failed;

  bool get isReady => this == EngineState.ready;
}

/// The engine's own return codes (`FaceRecognitionSDK.SDK_*`).
abstract final class SdkCode {
  static const int success = 0;
  static const int licenseInvalid = 1;
  static const int licenseExpired = 2;
  static const int notActivated = 3;
  static const int initFailed = 4;

  static EngineState toState(int code) => switch (code) {
        success => EngineState.ready,
        licenseInvalid => EngineState.licenseInvalid,
        licenseExpired => EngineState.licenseExpired,
        notActivated => EngineState.notActivated,
        _ => EngineState.failed,
      };

  /// The short message the native home screen shows in its status pill.
  static String message(int code) => switch (code) {
        licenseInvalid => 'Invalid license!',
        licenseExpired => 'License expired!',
        notActivated => 'No activated!',
        initFailed => 'Init error!',
        _ => 'SDK not ready: $code',
      };
}

/// License capabilities from the engine.
///
/// The liveness screens unlock when [liveness] is granted (a "Liveness only" or
/// "Recognition + Liveness" key). Mirrors Android/iOS `LicenseStatus`.
class LicenseStatus {
  const LicenseStatus({
    required this.licensed,
    required this.level,
    required this.levelName,
    required this.recognition,
    required this.liveness,
    required this.label,
  });

  final bool licensed;
  final int level;
  final String levelName;
  final bool recognition;
  final bool liveness;
  final String label;

  static const LicenseStatus notLicensed = LicenseStatus(
    licensed: false,
    level: -1,
    levelName: 'None',
    recognition: false,
    liveness: false,
    label: 'Not licensed',
  );

  static LicenseStatus fromMap(Map<Object?, Object?>? map) {
    if (map == null) return notLicensed;
    final String raw = (map['label'] as String?) ?? '';
    final String levelName = (map['levelName'] as String?) ?? '';
    return LicenseStatus(
      licensed: map['licensed'] as bool? ?? false,
      level: (map['level'] as num?)?.toInt() ?? -1,
      levelName: levelName.isEmpty ? 'None' : levelName,
      recognition: map['recognition'] as bool? ?? false,
      liveness: map['liveness'] as bool? ?? false,
      label: raw.isEmpty ? 'Not licensed' : raw,
    );
  }
}
