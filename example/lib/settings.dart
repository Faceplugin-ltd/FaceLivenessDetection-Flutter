import 'dart:convert';

import 'package:face_liveness_sdk/face_liveness_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Demo preferences — fields match Android `AppSettings` / iOS `AppSettings`.
class LivenessSettings {
  LivenessSettings({
    required this.useFrontCamera,
    required this.livenessThreshold,
    required this.pool,
    required this.count,
    required this.randomize,
    required this.framesWait,
    required this.yaw,
    required this.pitch,
    required this.smile,
    required this.blink,
    required this.blinksNumber,
    required this.perspective,
    required this.alignAngle,
    required this.minFace,
    required this.quality,
    required this.invertTurn,
    required this.invertTilt,
  });

  bool useFrontCamera;
  double livenessThreshold;
  List<ActiveCheck> pool;
  int count;
  bool randomize;
  int framesWait;
  double yaw;
  double pitch;
  double smile;
  double blink;
  int blinksNumber;
  double perspective;
  double alignAngle;
  double minFace;
  double quality;
  bool invertTurn;
  bool invertTilt;

  static LivenessSettings defaults() => LivenessSettings(
        useFrontCamera: true,
        livenessThreshold: ActiveLivenessOptions.defaultLivenessThreshold,
        pool: List<ActiveCheck>.from(ActiveCheck.defaultPool),
        count: ActiveLivenessOptions.defaultCount,
        randomize: ActiveLivenessOptions.defaultRandomize,
        framesWait: ActiveLivenessOptions.defaultFramesWait,
        yaw: ActiveLivenessOptions.defaultYaw,
        pitch: ActiveLivenessOptions.defaultPitch,
        smile: ActiveLivenessOptions.defaultSmile,
        blink: ActiveLivenessOptions.defaultBlink,
        blinksNumber: ActiveLivenessOptions.defaultBlinksNumber,
        perspective: ActiveLivenessOptions.defaultPerspective,
        alignAngle: ActiveLivenessOptions.defaultAlignAngle,
        minFace: ActiveLivenessOptions.defaultMinFace,
        quality: ActiveLivenessOptions.defaultQuality,
        invertTurn: false,
        invertTilt: false,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'useFrontCamera': useFrontCamera,
        'livenessThreshold': livenessThreshold,
        'pool': pool.map((ActiveCheck c) => c.key).toList(),
        'count': count,
        'randomize': randomize,
        'framesWait': framesWait,
        'yaw': yaw,
        'pitch': pitch,
        'smile': smile,
        'blink': blink,
        'blinksNumber': blinksNumber,
        'perspective': perspective,
        'alignAngle': alignAngle,
        'minFace': minFace,
        'quality': quality,
        'invertTurn': invertTurn,
        'invertTilt': invertTilt,
      };

  factory LivenessSettings.fromJson(Map<String, Object?> json) {
    final LivenessSettings d = LivenessSettings.defaults();
    final List<ActiveCheck> pool = <ActiveCheck>[
      for (final Object? key in (json['pool'] as List<Object?>? ?? const <Object?>[]))
        if (ActiveCheck.fromKey(key as String?) case final ActiveCheck check) check,
    ];
    return LivenessSettings(
      useFrontCamera: json['useFrontCamera'] as bool? ?? d.useFrontCamera,
      livenessThreshold:
          (json['livenessThreshold'] as num?)?.toDouble() ?? d.livenessThreshold,
      pool: pool.isEmpty ? d.pool : pool,
      count: (json['count'] as num?)?.toInt() ?? d.count,
      randomize: json['randomize'] as bool? ?? d.randomize,
      framesWait: (json['framesWait'] as num?)?.toInt() ?? d.framesWait,
      yaw: (json['yaw'] as num?)?.toDouble() ?? d.yaw,
      pitch: (json['pitch'] as num?)?.toDouble() ?? d.pitch,
      smile: (json['smile'] as num?)?.toDouble() ?? d.smile,
      blink: (json['blink'] as num?)?.toDouble() ?? d.blink,
      blinksNumber: (json['blinksNumber'] as num?)?.toInt() ?? d.blinksNumber,
      perspective: (json['perspective'] as num?)?.toDouble() ?? d.perspective,
      alignAngle: (json['alignAngle'] as num?)?.toDouble() ?? d.alignAngle,
      minFace: (json['minFace'] as num?)?.toDouble() ?? d.minFace,
      quality: (json['quality'] as num?)?.toDouble() ?? d.quality,
      invertTurn: json['invertTurn'] as bool? ?? d.invertTurn,
      invertTilt: json['invertTilt'] as bool? ?? d.invertTilt,
    );
  }

  ActiveLivenessOptions toOptions() => ActiveLivenessOptions(
        pool: pool.isEmpty ? ActiveCheck.defaultPool : pool,
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
}

const String _storageKey = 'faceplugin.liveness.settings';

Future<LivenessSettings> loadSettings() async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return LivenessSettings.defaults();
    final Object decoded = jsonDecode(raw);
    return LivenessSettings.fromJson(
      Map<String, Object?>.from(decoded as Map<dynamic, dynamic>),
    );
  } catch (_) {
    return LivenessSettings.defaults();
  }
}

Future<void> saveSettings(LivenessSettings settings) async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(settings.toJson()));
  } catch (_) {}
}

Future<LivenessSettings> restoreDefaults() async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  } catch (_) {}
  return LivenessSettings.defaults();
}
