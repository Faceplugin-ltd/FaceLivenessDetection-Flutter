import 'package:face_liveness_sdk/face_liveness_sdk.dart';
import 'package:flutter/material.dart';

import 'settings.dart';
import 'theme.dart';

/// Settings — camera lens, passive threshold, active-liveness configuration.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  LivenessSettings? _s;

  @override
  void initState() {
    super.initState();
    loadSettings().then((LivenessSettings s) {
      if (mounted) setState(() => _s = s);
    });
  }

  Future<void> _update(void Function(LivenessSettings) patch) async {
    final LivenessSettings? current = _s;
    if (current == null) return;
    patch(current);
    setState(() {});
    await saveSettings(current);
  }

  @override
  Widget build(BuildContext context) {
    final LivenessSettings? s = _s;
    return Scaffold(
      backgroundColor: FP.bg,
      appBar: AppBar(
        backgroundColor: FP.bg,
        foregroundColor: FP.text,
        title: const Text('Settings'),
      ),
      body: s == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: <Widget>[
                _section('Camera'),
                _card(
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text('Camera lens', style: _title),
                      ),
                      SegmentedButton<bool>(
                        segments: const <ButtonSegment<bool>>[
                          ButtonSegment<bool>(value: true, label: Text('Front')),
                          ButtonSegment<bool>(value: false, label: Text('Back')),
                        ],
                        selected: <bool>{s.useFrontCamera},
                        onSelectionChanged: (Set<bool> next) {
                          _update((LivenessSettings v) {
                            v.useFrontCamera = next.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                _section('Passive liveness'),
                _stepper(
                  title: 'Score threshold',
                  summary:
                      'Minimum score to count as live (0.0–1.0). Engine default 0.5.',
                  value: s.livenessThreshold,
                  step: 0.05,
                  min: 0,
                  max: 1,
                  decimals: 2,
                  onChanged: (double v) => _update((LivenessSettings x) {
                    x.livenessThreshold = v;
                  }),
                ),
                _section('Active liveness'),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Challenges — pool the sequence is drawn from',
                    style: TextStyle(color: FP.muted, fontSize: 13),
                  ),
                ),
                ...ActiveCheck.values.map((ActiveCheck check) {
                  final bool on = s.pool.contains(check);
                  return _card(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(check.title, style: _title),
                      value: on,
                      activeThumbColor: FP.text,
                      activeTrackColor: FP.accent,
                      onChanged: (bool next) {
                        _update((LivenessSettings x) {
                          final Set<ActiveCheck> wanted = x.pool.toSet();
                          if (next) {
                            wanted.add(check);
                          } else {
                            wanted.remove(check);
                          }
                          if (wanted.isEmpty) return;
                          x.pool = ActiveCheck.values
                              .where(wanted.contains)
                              .toList(growable: false);
                        });
                      },
                    ),
                  );
                }),
                _stepper(
                  title: 'Challenges per attempt',
                  summary: 'How many challenges one attempt asks for.',
                  value: s.count.toDouble(),
                  step: 1,
                  min: 1,
                  max: ActiveLivenessOptions.maxChecks.toDouble(),
                  decimals: 0,
                  onChanged: (double v) => _update((LivenessSettings x) {
                    x.count = v.round();
                  }),
                ),
                _card(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Randomize order', style: _title),
                    subtitle: const Text(
                      'Shuffle the challenge sequence each attempt.',
                      style: TextStyle(color: FP.muted, fontSize: 12),
                    ),
                    value: s.randomize,
                    activeThumbColor: FP.text,
                    activeTrackColor: FP.accent,
                    onChanged: (bool next) => _update((LivenessSettings x) {
                      x.randomize = next;
                    }),
                  ),
                ),
                _stepper(
                  title: 'Frames to wait',
                  value: s.framesWait.toDouble(),
                  step: 10,
                  min: 30,
                  max: 300,
                  decimals: 0,
                  onChanged: (double v) => _update((LivenessSettings x) {
                    x.framesWait = v.round();
                  }),
                ),
                _stepper(
                  title: 'Yaw threshold (°)',
                  value: s.yaw,
                  step: 1,
                  min: 5,
                  max: 45,
                  decimals: 0,
                  onChanged: (double v) => _update((LivenessSettings x) {
                    x.yaw = v;
                  }),
                ),
                _stepper(
                  title: 'Pitch threshold (°)',
                  value: s.pitch,
                  step: 1,
                  min: 5,
                  max: 45,
                  decimals: 0,
                  onChanged: (double v) => _update((LivenessSettings x) {
                    x.pitch = v;
                  }),
                ),
                _stepper(
                  title: 'Smile threshold',
                  value: s.smile,
                  step: 0.05,
                  min: 0,
                  max: 1,
                  decimals: 2,
                  onChanged: (double v) => _update((LivenessSettings x) {
                    x.smile = v;
                  }),
                ),
                _stepper(
                  title: 'Blink threshold',
                  value: s.blink,
                  step: 0.05,
                  min: 0,
                  max: 1,
                  decimals: 2,
                  onChanged: (double v) => _update((LivenessSettings x) {
                    x.blink = v;
                  }),
                ),
                _stepper(
                  title: 'Blinks required',
                  value: s.blinksNumber.toDouble(),
                  step: 1,
                  min: 1,
                  max: 5,
                  decimals: 0,
                  onChanged: (double v) => _update((LivenessSettings x) {
                    x.blinksNumber = v.round();
                  }),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    final LivenessSettings next = await restoreDefaults();
                    if (mounted) setState(() => _s = next);
                  },
                  child: const Text('Restore default settings'),
                ),
              ],
            ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: FP.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: fpCard(radius: 14),
        child: child,
      );

  Widget _stepper({
    required String title,
    String? summary,
    required double value,
    required double step,
    required double min,
    required double max,
    required int decimals,
    required ValueChanged<double> onChanged,
  }) {
    final String shown = value.toStringAsFixed(decimals);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: _title),
          if (summary != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(summary, style: const TextStyle(color: FP.muted, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () => onChanged((value - step).clamp(min, max)),
                icon: const Icon(Icons.remove_circle_outline, color: FP.accent),
              ),
              Expanded(
                child: Text(
                  shown,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: FP.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onChanged((value + step).clamp(min, max)),
                icon: const Icon(Icons.add_circle_outline, color: FP.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const TextStyle _title = TextStyle(color: FP.text, fontWeight: FontWeight.w600);
