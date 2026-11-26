/// One active-liveness challenge.
///
/// The engine reports face attributes per frame — head pose, eye openness, smile, face size — and
/// the native `ActiveLivenessSession` decides from those when a challenge is satisfied. This enum
/// is the description of it, and [key] is the wire value shared with the native side.
///
/// Mirrors Android `face-liveness-active/ActiveCheck` and iOS `ActiveCheck`.
enum ActiveCheck {
  blink('blink', 'Blink', 'Blink your eyes a couple of times'),
  smile('smile', 'Smile', 'Give the camera a clear smile'),
  turnLeft('turn_left', 'Turn left', 'Turn your head to your left'),
  turnRight('turn_right', 'Turn right', 'Turn your head to your right'),
  turnUp('turn_up', 'Look up', 'Tilt your head up, keep your eyes on the screen'),
  turnDown('turn_down', 'Look down', 'Tilt your head down slowly'),
  perspective('perspective', 'Move closer', 'Bring the phone a little closer to your face');

  const ActiveCheck(this.key, this.title, this.hint);

  /// Stable wire key, matching the native `ActiveCheck.key` values.
  final String key;

  /// Label shown on the challenge card and in the result list.
  final String title;

  /// One-line instruction shown under the title.
  final String hint;

  /// True for the challenges where turning the other way is a recoverable mistake.
  bool get isDirectional =>
      this == ActiveCheck.turnLeft ||
      this == ActiveCheck.turnRight ||
      this == ActiveCheck.turnUp ||
      this == ActiveCheck.turnDown;

  /// Every challenge but "move closer", which not every placement of the phone allows.
  static const List<ActiveCheck> defaultPool = <ActiveCheck>[
    ActiveCheck.blink,
    ActiveCheck.smile,
    ActiveCheck.turnLeft,
    ActiveCheck.turnRight,
    ActiveCheck.turnUp,
    ActiveCheck.turnDown,
  ];

  static ActiveCheck? fromKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final check in ActiveCheck.values) {
      if (check.key.toLowerCase() == key.toLowerCase()) return check;
    }
    return null;
  }
}
