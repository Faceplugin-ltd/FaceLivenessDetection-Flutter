import 'active_check.dart';

/// Outcome of one challenge, or of the anti-spoofing gate.
///
/// Mirrors the native `ActiveLivenessSession.StepState`.
enum StepState {
  pending('PENDING', 'Not reached'),
  active('ACTIVE', 'Not reached'),
  passed('PASSED', 'Passed'),
  failed('FAILED', 'Failed');

  const StepState(this.wire, this.label);

  final String wire;

  /// The word the native result card shows for this outcome.
  final String label;

  static StepState fromWire(String? value) {
    for (final state in StepState.values) {
      if (state.wire == value) return state;
    }
    return StepState.pending;
  }
}

/// Why an attempt did not pass.
///
/// Mirrors the native `ActiveLivenessSession.Failure`.
enum ActiveLivenessFailure {
  none('NONE'),
  spoof('SPOOF'),
  check('CHECK'),
  timeout('TIMEOUT'),
  cancelled('CANCELLED');

  const ActiveLivenessFailure(this.wire);

  final String wire;

  static ActiveLivenessFailure fromWire(String? value) {
    for (final failure in ActiveLivenessFailure.values) {
      if (failure.wire == value) return failure;
    }
    return ActiveLivenessFailure.none;
  }
}

/// What one attempt came to, handed back by the native active-liveness screen.
///
/// [passed] is the only thing most callers need: it is true when the passive anti-spoofing gate
/// cleared *and* every challenge was completed. [failure] says why it did not.
///
/// Mirrors Android/iOS `ActiveLivenessResult`.
class ActiveLivenessResult {
  const ActiveLivenessResult({
    required this.passed,
    required this.failure,
    required this.passiveScore,
    required this.passivePassed,
    required this.challenges,
    required this.outcomes,
    required this.durationMs,
  });

  final bool passed;
  final ActiveLivenessFailure failure;

  /// Averaged passive anti-spoofing score, or -1 when the engine never returned one.
  final double passiveScore;
  final bool passivePassed;

  /// The challenges asked, in the order they were asked.
  final List<ActiveCheck> challenges;

  /// One outcome per entry of [challenges].
  final List<StepState> outcomes;
  final int durationMs;

  /// The challenge that ended the attempt, when one did.
  ActiveCheck? get failedCheck {
    final int index = outcomes.indexOf(StepState.failed);
    if (index < 0 || index >= challenges.length) return null;
    return challenges[index];
  }

  /// How long the attempt took, in seconds, as the native result card shows it.
  double get durationSeconds => durationMs / 1000.0;

  static ActiveLivenessResult? fromMap(Map<Object?, Object?>? map) {
    if (map == null) return null;
    final List<ActiveCheck> challenges = <ActiveCheck>[
      for (final Object? key in (map['challenges'] as List<Object?>? ?? const <Object?>[]))
        if (ActiveCheck.fromKey(key as String?) case final ActiveCheck check) check,
    ];
    final List<StepState> outcomes = <StepState>[
      for (final Object? value in (map['outcomes'] as List<Object?>? ?? const <Object?>[]))
        StepState.fromWire(value as String?),
    ];
    return ActiveLivenessResult(
      passed: map['passed'] as bool? ?? false,
      failure: ActiveLivenessFailure.fromWire(map['failure'] as String?),
      passiveScore: (map['passiveScore'] as num?)?.toDouble() ?? -1,
      passivePassed: map['passivePassed'] as bool? ?? false,
      challenges: challenges,
      outcomes: outcomes,
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
    );
  }
}
