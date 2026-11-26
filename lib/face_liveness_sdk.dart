/// FacePlugin Face Liveness Detection SDK for Flutter.
///
/// Passive anti-spoofing and guided active liveness, running fully on the device. The engine and
/// both camera screens are the **native** FacePlugin implementations — the same code the
/// Face-LivenessDetection-Android and Face-LivenessDetection-iOS apps run — so the camera preview,
/// the anti-spoofing gate, the challenge sequence and the result card behave identically here.
///
/// ```dart
/// await FaceLivenessEngine.instance.start(licenseKey);
///
/// final result = await FaceLiveness.startActiveLiveness(
///   const ActiveLivenessOptions(count: 3),
/// );
/// if (result?.passed ?? false) {
///   // live person
/// }
/// ```
library face_liveness_sdk;

import 'src/active_liveness_options.dart';
import 'src/active_liveness_result.dart';
import 'src/channel.dart';

export 'src/active_check.dart';
export 'src/active_liveness_options.dart';
export 'src/active_liveness_result.dart';
export 'src/engine.dart';
export 'src/models.dart';

/// Launches the native liveness screens.
///
/// [FaceLivenessEngine.start] has to have succeeded first; the screens refuse to run on an engine
/// that is not ready.
abstract final class FaceLiveness {
  /// Opens the guided active-liveness screen and waits for the attempt to finish.
  ///
  /// One attempt runs in three stages: the face is found and aligned, the **passive
  /// anti-spoofing gate** scores it, and only then are the challenges asked — so a printed photo
  /// or a replayed video is turned away before it is ever invited to blink.
  ///
  /// Returns `null` when the user closed the screen before an attempt produced a result.
  static Future<ActiveLivenessResult?> startActiveLiveness([
    ActiveLivenessOptions options = const ActiveLivenessOptions(),
  ]) {
    return FaceLivenessChannel.startActiveLiveness(options);
  }

  /// Opens the passive-liveness screen: every camera frame is scored on its own, with no action
  /// asked of the user, and the HUD shows liveness, quality and head pose.
  static Future<void> startPassiveLiveness({
    bool useFrontCamera = true,
    double livenessThreshold = ActiveLivenessOptions.defaultLivenessThreshold,
  }) {
    return FaceLivenessChannel.startPassiveLiveness(
      useFrontCamera: useFrontCamera,
      livenessThreshold: livenessThreshold,
    );
  }
}
