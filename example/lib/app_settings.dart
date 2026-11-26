import 'package:face_liveness_sdk/face_liveness_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every preference this demo stores, in one place.
///
/// The plugin takes its configuration as arguments, so this is the only part of the app that
/// knows about persistence: it reads what the user chose and builds an [ActiveLivenessOptions]
/// for the native active-liveness screen.
///
/// The keys and defaults mirror Android `data/AppSettings` and iOS `AppSettings`, so the three
/// demos behave the same. Defaults are the engine's own operating points.
class AppSettings {
  AppSettings._(this._prefs);

  static const String keyCameraLens = 'camera_lens';
  static const String keyLivenessThreshold = 'liveness_threshold';
  static const String keyChecks = 'active_checks';
  static const String keyCount = 'active_check_count';
  static const String keyRandomize = 'active_randomize';
  static const String keyFramesWait = 'active_frames_wait';
  static const String keyYaw = 'active_yaw';
  static const String keyPitch = 'active_pitch';
  static const String keySmile = 'active_smile';
  static const String keyBlink = 'active_blink';
  static const String keyBlinksNumber = 'active_blinks_number';
  static const String keyPerspective = 'active_perspective';
  static const String keyAlignAngle = 'active_align_angle';
  static const String keyMinFace = 'active_min_face';
  static const String keyQuality = 'active_quality';
  static const String keyInvertTurn = 'active_invert_turn';
  static const String keyInvertTilt = 'active_invert_tilt';

  final SharedPreferences _prefs;

  static Future<AppSettings> load() async {
    return AppSettings._(await SharedPreferences.getInstance());
  }

  // MARK: camera

  bool get useFrontCamera => (_prefs.getString(keyCameraLens) ?? 'front') != 'back';
  Future<void> setUseFrontCamera(bool front) =>
      _prefs.setString(keyCameraLens, front ? 'front' : 'back');

  // MARK: passive liveness

  double get livenessThreshold =>
      _prefs.getDouble(keyLivenessThreshold) ?? ActiveLivenessOptions.defaultLivenessThreshold;
  Future<void> setLivenessThreshold(double value) =>
      _prefs.setDouble(keyLivenessThreshold, value);

  // MARK: active liveness

  List<ActiveCheck> get pool {
    final List<String>? keys = _prefs.getStringList(keyChecks);
    if (keys == null) return ActiveCheck.defaultPool;
    // Keep the canonical enum order so the pool is stable when randomize is off.
    final List<ActiveCheck> picked =
        ActiveCheck.values.where((ActiveCheck c) => keys.contains(c.key)).toList();
    return picked.isEmpty ? ActiveCheck.defaultPool : picked;
  }

  Future<void> setPool(List<ActiveCheck> checks) => _prefs.setStringList(
        keyChecks,
        ActiveCheck.values
            .where(checks.contains)
            .map((ActiveCheck c) => c.key)
            .toList(growable: false),
      );

  int get count => _prefs.getInt(keyCount) ?? ActiveLivenessOptions.defaultCount;
  Future<void> setCount(int value) => _prefs.setInt(keyCount, value);

  bool get randomize => _prefs.getBool(keyRandomize) ?? ActiveLivenessOptions.defaultRandomize;
  Future<void> setRandomize(bool value) => _prefs.setBool(keyRandomize, value);

  int get framesWait => _prefs.getInt(keyFramesWait) ?? ActiveLivenessOptions.defaultFramesWait;
  Future<void> setFramesWait(int value) => _prefs.setInt(keyFramesWait, value.clamp(30, 600));

  double get yaw => _prefs.getDouble(keyYaw) ?? ActiveLivenessOptions.defaultYaw;
  Future<void> setYaw(double value) => _prefs.setDouble(keyYaw, value);

  double get pitch => _prefs.getDouble(keyPitch) ?? ActiveLivenessOptions.defaultPitch;
  Future<void> setPitch(double value) => _prefs.setDouble(keyPitch, value);

  double get smile => _prefs.getDouble(keySmile) ?? ActiveLivenessOptions.defaultSmile;
  Future<void> setSmile(double value) => _prefs.setDouble(keySmile, value);

  double get blink => _prefs.getDouble(keyBlink) ?? ActiveLivenessOptions.defaultBlink;
  Future<void> setBlink(double value) => _prefs.setDouble(keyBlink, value);

  int get blinksNumber =>
      _prefs.getInt(keyBlinksNumber) ?? ActiveLivenessOptions.defaultBlinksNumber;
  Future<void> setBlinksNumber(int value) =>
      _prefs.setInt(keyBlinksNumber, value.clamp(1, 6));

  double get perspective =>
      _prefs.getDouble(keyPerspective) ?? ActiveLivenessOptions.defaultPerspective;
  Future<void> setPerspective(double value) => _prefs.setDouble(keyPerspective, value);

  double get alignAngle =>
      _prefs.getDouble(keyAlignAngle) ?? ActiveLivenessOptions.defaultAlignAngle;
  Future<void> setAlignAngle(double value) => _prefs.setDouble(keyAlignAngle, value);

  double get minFace => _prefs.getDouble(keyMinFace) ?? ActiveLivenessOptions.defaultMinFace;
  Future<void> setMinFace(double value) => _prefs.setDouble(keyMinFace, value);

  double get quality => _prefs.getDouble(keyQuality) ?? ActiveLivenessOptions.defaultQuality;
  Future<void> setQuality(double value) => _prefs.setDouble(keyQuality, value);

  bool get invertTurn => _prefs.getBool(keyInvertTurn) ?? false;
  Future<void> setInvertTurn(bool value) => _prefs.setBool(keyInvertTurn, value);

  bool get invertTilt => _prefs.getBool(keyInvertTilt) ?? false;
  Future<void> setInvertTilt(bool value) => _prefs.setBool(keyInvertTilt, value);

  /// What the native active-liveness screen should run, as the user has it configured.
  ActiveLivenessOptions activeLiveness() => ActiveLivenessOptions(
        pool: pool,
        count: count,
        randomize: randomize,
        livenessThreshold: livenessThreshold,
        framesWait: framesWait,
        yawThreshold: yaw,
        pitchThreshold: pitch,
        smileThreshold: smile,
        blinkThreshold: blink,
        blinksNumber: blinksNumber,
        perspectiveThreshold: perspective,
        alignAngle: alignAngle,
        minFaceFraction: minFace,
        qualityThreshold: quality,
        invertTurn: invertTurn,
        invertTilt: invertTilt,
        useFrontCamera: useFrontCamera,
      );

  /// Clears every key this demo owns, so the next read returns the engine's defaults.
  Future<void> restoreDefaults() async {
    for (final String key in <String>[
      keyCameraLens, keyLivenessThreshold, keyChecks, keyCount, keyRandomize,
      keyFramesWait, keyYaw, keyPitch, keySmile, keyBlink, keyBlinksNumber,
      keyPerspective, keyAlignAngle, keyMinFace, keyQuality, keyInvertTurn, keyInvertTilt,
    ]) {
      await _prefs.remove(key);
    }
  }
}
