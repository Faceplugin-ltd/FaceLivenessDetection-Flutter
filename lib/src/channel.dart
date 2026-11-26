import 'package:flutter/services.dart';

import 'active_liveness_options.dart';
import 'active_liveness_result.dart';
import 'models.dart';

/// Thin transport over the platform channel. Everything here maps one-to-one onto a native
/// entry point; the friendlier API lives in [FaceLivenessEngine] and [FaceLiveness].
abstract final class FaceLivenessChannel {
  static const MethodChannel channel = MethodChannel('face_liveness_sdk');

  /// Activate with [license] and load the models. Returns an `SdkCode`.
  ///
  /// Native Android / iOS expose a single `start` entry that does both steps.
  static Future<int> start(String license) async {
    final int? code = await channel.invokeMethod<int>('start', <String, Object?>{
      'license': license,
    });
    return code ?? SdkCode.initFailed;
  }

  static Future<LicenseStatus> licenseStatus() async {
    final Map<Object?, Object?>? map =
        await channel.invokeMethod<Map<Object?, Object?>>('licenseStatus');
    return LicenseStatus.fromMap(map);
  }

  static Future<String> lastLicenseError() async {
    return await channel.invokeMethod<String>('lastLicenseError') ?? '';
  }

  static Future<String> machineCode() async {
    return await channel.invokeMethod<String>('machineCode') ?? '';
  }

  /// Opens the native active-liveness screen and waits for the attempt to finish.
  /// Returns `null` when the screen was closed before producing a result.
  static Future<ActiveLivenessResult?> startActiveLiveness(
    ActiveLivenessOptions options,
  ) async {
    final Map<Object?, Object?>? map =
        await channel.invokeMethod<Map<Object?, Object?>>(
      'startActiveLiveness',
      options.toMap(),
    );
    return ActiveLivenessResult.fromMap(map);
  }

  /// Opens the native passive-liveness screen. It has no result; the user closes it.
  static Future<void> startPassiveLiveness({
    required bool useFrontCamera,
    required double livenessThreshold,
  }) {
    return channel.invokeMethod<void>('startPassiveLiveness', <String, Object?>{
      'useFrontCamera': useFrontCamera,
      'livenessThreshold': livenessThreshold,
    });
  }
}
