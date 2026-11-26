import 'active_check.dart';

/// How one active-liveness attempt is run.
///
/// [pool] is what the sequence may be drawn from, [count] how many challenges one attempt asks
/// for, and [randomize] shuffles the order per attempt so a recorded session cannot be replayed.
/// Every attempt begins with the passive anti-spoofing gate, which the face has to clear at
/// [livenessThreshold] before any challenge is asked.
///
/// The thresholds are what the native `ActiveLivenessSession` judges each challenge against; the
/// angles are degrees, as the engine reports head pose. Defaults are the engine's own operating
/// points and match Android `ActiveLivenessOptions` / iOS `ActiveLivenessOptions` exactly.
class ActiveLivenessOptions {
  const ActiveLivenessOptions({
    this.pool = ActiveCheck.defaultPool,
    this.count = defaultCount,
    this.randomize = defaultRandomize,
    this.livenessThreshold = defaultLivenessThreshold,
    this.passiveSamples = defaultPassiveSamples,
    this.framesWait = defaultFramesWait,
    this.yawThreshold = defaultYaw,
    this.pitchThreshold = defaultPitch,
    this.smileThreshold = defaultSmile,
    this.blinkThreshold = defaultBlink,
    this.blinksNumber = defaultBlinksNumber,
    this.perspectiveThreshold = defaultPerspective,
    this.alignAngle = defaultAlignAngle,
    this.minFaceFraction = defaultMinFace,
    this.qualityThreshold = defaultQuality,
    this.invertTurn = false,
    this.invertTilt = false,
    this.useFrontCamera = true,
  });

  final List<ActiveCheck> pool;
  final int count;
  final bool randomize;
  final double livenessThreshold;
  final int passiveSamples;
  final int framesWait;
  final double yawThreshold;
  final double pitchThreshold;
  final double smileThreshold;
  final double blinkThreshold;
  final int blinksNumber;
  final double perspectiveThreshold;
  final double alignAngle;

  /// Smallest the face may be, as a fraction of the frame's short side, to be scored.
  final double minFaceFraction;

  /// Lowest image quality the engine's own score may report and still be judged.
  final double qualityThreshold;
  final bool invertTurn;
  final bool invertTilt;
  final bool useFrontCamera;

  static const int maxChecks = 6;
  static const int defaultCount = 3;
  static const bool defaultRandomize = true;

  /// The engine's own passive-liveness operating point.
  static const double defaultLivenessThreshold = 0.5;

  /// Frames the passive gate averages before it decides.
  static const int defaultPassiveSamples = 3;

  /// About 15 analyzed frames a second on a mid-range phone.
  static const int defaultFramesWait = 150;
  static const double defaultYaw = 25;
  static const double defaultPitch = 15;
  static const double defaultSmile = 0.5;
  static const double defaultBlink = 0.3;
  static const int defaultBlinksNumber = 2;
  static const double defaultPerspective = 0.15;
  static const double defaultAlignAngle = 12;

  /// A face smaller than this much of the frame is too far away to score reliably.
  static const double defaultMinFace = 0.3;

  /// The engine's image quality below which a frame is not worth judging.
  static const double defaultQuality = 0.3;

  ActiveLivenessOptions copyWith({
    List<ActiveCheck>? pool,
    int? count,
    bool? randomize,
    double? livenessThreshold,
    int? framesWait,
    double? yawThreshold,
    double? pitchThreshold,
    double? smileThreshold,
    double? blinkThreshold,
    int? blinksNumber,
    double? perspectiveThreshold,
    double? alignAngle,
    double? minFaceFraction,
    double? qualityThreshold,
    bool? invertTurn,
    bool? invertTilt,
    bool? useFrontCamera,
  }) {
    return ActiveLivenessOptions(
      pool: pool ?? this.pool,
      count: count ?? this.count,
      randomize: randomize ?? this.randomize,
      livenessThreshold: livenessThreshold ?? this.livenessThreshold,
      passiveSamples: passiveSamples,
      framesWait: framesWait ?? this.framesWait,
      yawThreshold: yawThreshold ?? this.yawThreshold,
      pitchThreshold: pitchThreshold ?? this.pitchThreshold,
      smileThreshold: smileThreshold ?? this.smileThreshold,
      blinkThreshold: blinkThreshold ?? this.blinkThreshold,
      blinksNumber: blinksNumber ?? this.blinksNumber,
      perspectiveThreshold: perspectiveThreshold ?? this.perspectiveThreshold,
      alignAngle: alignAngle ?? this.alignAngle,
      minFaceFraction: minFaceFraction ?? this.minFaceFraction,
      qualityThreshold: qualityThreshold ?? this.qualityThreshold,
      invertTurn: invertTurn ?? this.invertTurn,
      invertTilt: invertTilt ?? this.invertTilt,
      useFrontCamera: useFrontCamera ?? this.useFrontCamera,
    );
  }

  /// The payload the native side reads to build its own options object.
  Map<String, Object?> toMap() => <String, Object?>{
        'pool': pool.map((ActiveCheck c) => c.key).toList(growable: false),
        'count': count,
        'randomize': randomize,
        'livenessThreshold': livenessThreshold,
        'passiveSamples': passiveSamples,
        'framesWait': framesWait,
        'yawThreshold': yawThreshold,
        'pitchThreshold': pitchThreshold,
        'smileThreshold': smileThreshold,
        'blinkThreshold': blinkThreshold,
        'blinksNumber': blinksNumber,
        'perspectiveThreshold': perspectiveThreshold,
        'alignAngle': alignAngle,
        'minFaceFraction': minFaceFraction,
        'qualityThreshold': qualityThreshold,
        'invertTurn': invertTurn,
        'invertTilt': invertTilt,
        'useFrontCamera': useFrontCamera,
      };
}
