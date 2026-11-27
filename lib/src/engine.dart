import 'package:flutter/foundation.dart';

import 'channel.dart';
import 'models.dart';

/// Process-wide engine owner: activation and init, and a listenable state for the UI.
///
/// The engine is `FaceRecognitionSDK` — the same build the native Android and iOS liveness apps
/// run, loaded natively. Call [start] once, then watch [state] (a [ValueListenable]) or read
/// [licenseStatus].
///
/// Mirrors Android `face-liveness-kit/FaceEngine` and iOS `FaceEngine`.
class FaceLivenessEngine {
  FaceLivenessEngine._();

  static final FaceLivenessEngine instance = FaceLivenessEngine._();

  final ValueNotifier<EngineState> _state =
      ValueNotifier<EngineState>(EngineState.loading);

  /// Engine state, for `ValueListenableBuilder`.
  ValueListenable<EngineState> get state => _state;

  bool get isReady => _state.value.isReady;

  LicenseStatus _license = LicenseStatus.notLicensed;

  /// What the last [start] found the key to unlock.
  LicenseStatus get license => _license;

  /// The engine's return code from the last [start].
  int get lastCode => _lastCode;
  int _lastCode = SdkCode.initFailed;

  /// Activate with [license] and load the models. Safe to call more than once; a ready engine
  /// returns immediately.
  Future<int> start(String license) async {
    if (isReady) return SdkCode.success;
    _state.value = EngineState.loading;

    // Native Android / iOS expose one `start` that activates and inits together.
    final int code = await FaceLivenessChannel.start(license);
    _lastCode = code;
    _state.value = SdkCode.toState(code);
    _license = await FaceLivenessChannel.licenseStatus();
    return code;
  }

  Future<LicenseStatus> refreshLicense() async {
    _license = await FaceLivenessChannel.licenseStatus();
    return _license;
  }

  Future<String> lastLicenseError() => FaceLivenessChannel.lastLicenseError();

  Future<String> machineCode() => FaceLivenessChannel.machineCode();

  /// The message the native home screen shows in its status pill.
  Future<String> statusMessage() async {
    switch (_state.value) {
      case EngineState.loading:
        return 'Loading on-device models…';
      case EngineState.ready:
        return 'Ready · ${_license.label}';
      case EngineState.failed:
        final String detail = (await lastLicenseError()).trim();
        return detail.isEmpty ? 'Init error!' : 'Init error! $detail';
      case EngineState.notActivated:
      case EngineState.licenseInvalid:
      case EngineState.licenseExpired:
        final String detail = (await lastLicenseError()).trim();
        final String base = SdkCode.message(_lastCode);
        return detail.isEmpty ? base : '$base $detail';
    }
  }
}
