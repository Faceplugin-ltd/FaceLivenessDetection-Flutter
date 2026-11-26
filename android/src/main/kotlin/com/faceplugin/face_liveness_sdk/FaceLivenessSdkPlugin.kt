package com.faceplugin.face_liveness_sdk

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.camera.core.CameraSelector
import com.faceplugin.face_liveness_sdk.passive.PassiveLivenessActivity
import com.faceplugin.faceliveness.active.ActiveCheck
import com.faceplugin.faceliveness.active.ActiveLivenessActivity
import com.faceplugin.faceliveness.active.ActiveLivenessOptions
import com.faceplugin.faceliveness.active.ActiveLivenessResult
import com.faceplugin.faceliveness.kit.FaceEngine
import com.faceplugin.faceliveness.kit.LicenseStatus
import com.faceplugin.facerecognitionsdk.FaceRecognitionSDK
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Bridges Flutter to the native FacePlugin liveness implementation.
 *
 * The engine and both camera screens are the native ones — [FaceEngine] from `face-liveness-kit`,
 * [ActiveLivenessActivity] from `face-liveness-active`, and [PassiveLivenessActivity], a port of
 * the native demo's passive screen. Nothing about liveness is re-implemented in Dart, so the
 * camera preview, the anti-spoofing gate, the challenge sequence and the result card behave
 * exactly as they do in Face-LivenessDetection-Android.
 */
class FaceLivenessSdkPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val main = Handler(Looper.getMainLooper())

    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    /** The pending `startActiveLiveness` call, answered from [onActivityResult]. */
    private var activeResult: MethodChannel.Result? = null

    // region FlutterPlugin

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // endregion

    // region ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        attach(binding)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        attach(binding)
    }

    override fun onDetachedFromActivity() {
        detach()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detach()
    }

    private fun attach(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    private fun detach() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activity = null
    }

    // endregion

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                val license = call.argument<String>("license").orEmpty()
                if (license.isBlank()) {
                    result.error("E_LICENSE", "A license key is required.", null)
                    return
                }
                // The kit activates and initialises on its own worker and calls back on the main
                // thread, so this is already off the platform thread.
                FaceEngine.start(context, license) { code -> result.success(code) }
            }

            "licenseStatus" -> FaceEngine.async {
                val status = FaceEngine.licenseStatus()
                main.post { result.success(status.toMap()) }
            }

            "lastLicenseError" -> result.success(FaceEngine.lastLicenseError())

            "machineCode" -> FaceEngine.async {
                val code = try {
                    synchronized(FaceEngine.lock) { FaceRecognitionSDK.machineCode(context) }
                } catch (_: Throwable) {
                    ""
                }
                main.post { result.success(code.orEmpty()) }
            }

            "startActiveLiveness" -> startActiveLiveness(call, result)

            "startPassiveLiveness" -> {
                val host = activity
                if (host == null) {
                    result.error("E_NO_ACTIVITY", "The screen needs a foreground Activity.", null)
                    return
                }
                host.startActivity(
                    PassiveLivenessActivity.intent(
                        host,
                        useFrontCamera = call.argument<Boolean>("useFrontCamera") ?: true,
                        livenessThreshold = (call.argument<Number>("livenessThreshold"))?.toFloat()
                            ?: ActiveLivenessOptions.DEFAULT_LIVENESS_THRESHOLD,
                    ),
                )
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun startActiveLiveness(call: MethodCall, result: MethodChannel.Result) {
        val host = activity
        if (host == null) {
            result.error("E_NO_ACTIVITY", "The screen needs a foreground Activity.", null)
            return
        }
        if (activeResult != null) {
            result.error("E_BUSY", "An active-liveness attempt is already running.", null)
            return
        }
        val options = optionsFrom(call)
        val lens = if (call.argument<Boolean>("useFrontCamera") == false) {
            CameraSelector.LENS_FACING_BACK
        } else {
            CameraSelector.LENS_FACING_FRONT
        }
        activeResult = result
        host.startActivityForResult(
            ActiveLivenessActivity.intent(host, options, lens),
            REQUEST_ACTIVE_LIVENESS,
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_ACTIVE_LIVENESS) return false
        val pending = activeResult ?: return true
        activeResult = null
        // A closed screen produces no result, which Dart reads as null.
        pending.success(ActiveLivenessActivity.result(data)?.toMap())
        return true
    }

    /** Builds the native options from the Dart payload, falling back to the engine's defaults. */
    private fun optionsFrom(call: MethodCall): ActiveLivenessOptions {
        val defaults = ActiveLivenessOptions()
        val keys = call.argument<List<String>>("pool").orEmpty().toSet()
        // Keep the canonical enum order so the pool is stable when randomize is off.
        val pool = ActiveCheck.entries.filter { keys.contains(it.key) }
        return ActiveLivenessOptions(
            pool = pool.ifEmpty { ActiveLivenessOptions.DEFAULT_POOL },
            count = call.argument<Number>("count")?.toInt() ?: defaults.count,
            randomize = call.argument<Boolean>("randomize") ?: defaults.randomize,
            livenessThreshold = call.argument<Number>("livenessThreshold")?.toFloat()
                ?: defaults.livenessThreshold,
            passiveSamples = call.argument<Number>("passiveSamples")?.toInt()
                ?: defaults.passiveSamples,
            framesWait = call.argument<Number>("framesWait")?.toInt() ?: defaults.framesWait,
            yawThreshold = call.argument<Number>("yawThreshold")?.toFloat() ?: defaults.yawThreshold,
            pitchThreshold = call.argument<Number>("pitchThreshold")?.toFloat()
                ?: defaults.pitchThreshold,
            smileThreshold = call.argument<Number>("smileThreshold")?.toFloat()
                ?: defaults.smileThreshold,
            blinkThreshold = call.argument<Number>("blinkThreshold")?.toFloat()
                ?: defaults.blinkThreshold,
            blinksNumber = call.argument<Number>("blinksNumber")?.toInt() ?: defaults.blinksNumber,
            perspectiveThreshold = call.argument<Number>("perspectiveThreshold")?.toFloat()
                ?: defaults.perspectiveThreshold,
            alignAngle = call.argument<Number>("alignAngle")?.toFloat() ?: defaults.alignAngle,
            minFaceFraction = call.argument<Number>("minFaceFraction")?.toFloat()
                ?: defaults.minFaceFraction,
            qualityThreshold = call.argument<Number>("qualityThreshold")?.toFloat()
                ?: defaults.qualityThreshold,
            invertTurn = call.argument<Boolean>("invertTurn") ?: defaults.invertTurn,
            invertTilt = call.argument<Boolean>("invertTilt") ?: defaults.invertTilt,
        )
    }

    private companion object {
        const val CHANNEL = "face_liveness_sdk"
        const val REQUEST_ACTIVE_LIVENESS = 0xFA11
    }
}

private fun LicenseStatus.toMap(): Map<String, Any?> = mapOf(
    "licensed" to licensed,
    "level" to level,
    "levelName" to levelName,
    "recognition" to recognition,
    "liveness" to liveness,
    "label" to label,
)

private fun ActiveLivenessResult.toMap(): Map<String, Any?> = mapOf(
    "passed" to passed,
    "failure" to failure.name,
    "passiveScore" to passiveScore,
    "passivePassed" to passivePassed,
    "challenges" to challenges.map { it.key },
    "outcomes" to outcomes.map { it.name },
    "durationMs" to durationMs,
)
