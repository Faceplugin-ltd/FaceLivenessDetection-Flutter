import 'package:face_liveness_sdk/face_liveness_sdk.dart';
import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../theme.dart';

/// Settings — camera lens, the passive score threshold, and the full active-liveness configuration.
///
/// Mirrors Android `ui/SettingsActivity` + `xml/root_preferences` and iOS `SettingsViewController`.
/// The screen only writes preferences; [AppSettings] turns them into an [ActiveLivenessOptions].
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings get s => widget.settings;

  Future<void> _save(Future<void> Function() write) async {
    await write();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FP.bg,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          _card('Camera', <Widget>[
            _choiceRow<bool>(
              title: 'Camera lens',
              value: s.useFrontCamera,
              options: const <bool, String>{true: 'Front', false: 'Back'},
              onChanged: (bool v) => _save(() => s.setUseFrontCamera(v)),
            ),
          ]),
          const SizedBox(height: 16),
          _card('Passive liveness', <Widget>[
            _sliderRow(
              title: 'Score threshold',
              summary: 'Minimum score to count as live (0.0–1.0). The engine’s own operating '
                  'point is 0.5, and the active check uses the same gate.',
              value: s.livenessThreshold,
              onChanged: (double v) => _save(() => s.setLivenessThreshold(v)),
            ),
          ]),
          const SizedBox(height: 16),
          _card('Active liveness', <Widget>[
            _navRow(
              title: 'Challenges',
              summary: 'Pool the sequence is drawn from',
              trailing: '${s.pool.length} of ${ActiveCheck.values.length}',
              onTap: _editPool,
            ),
            _choiceRow<int>(
              title: 'Challenges per attempt',
              value: s.count,
              options: <int, String>{for (int i = 1; i <= 5; i++) i: '$i'},
              onChanged: (int v) => _save(() => s.setCount(v)),
            ),
            _switchRow(
              title: 'Random order',
              summary: 'Shuffle the sequence on every attempt so a recording cannot be replayed',
              value: s.randomize,
              onChanged: (bool v) => _save(() => s.setRandomize(v)),
            ),
          ]),
          const SizedBox(height: 16),
          _card('Active liveness tuning', <Widget>[
            _numberRow(
              title: 'Frames allowed per stage',
              summary: 'About 15 frames a second. Higher is more forgiving, lower fails '
                  'faster (30–600)',
              value: s.framesWait.toString(),
              onSubmit: (String v) async {
                final int? parsed = int.tryParse(v);
                if (parsed != null) await _save(() => s.setFramesWait(parsed));
              },
            ),
            _numberRow(
              title: 'Head turn angle (°)',
              value: _trim(s.yaw),
              onSubmit: (String v) async {
                final double? parsed = double.tryParse(v);
                if (parsed != null) await _save(() => s.setYaw(parsed));
              },
            ),
            _numberRow(
              title: 'Head tilt angle (°)',
              value: _trim(s.pitch),
              onSubmit: (String v) async {
                final double? parsed = double.tryParse(v);
                if (parsed != null) await _save(() => s.setPitch(parsed));
              },
            ),
            _sliderRow(
              title: 'Smile confidence',
              value: s.smile,
              onChanged: (double v) => _save(() => s.setSmile(v)),
            ),
            _sliderRow(
              title: 'Eye-closed confidence',
              value: s.blink,
              onChanged: (double v) => _save(() => s.setBlink(v)),
            ),
            _numberRow(
              title: 'Blinks required',
              value: s.blinksNumber.toString(),
              onSubmit: (String v) async {
                final int? parsed = int.tryParse(v);
                if (parsed != null) await _save(() => s.setBlinksNumber(parsed));
              },
            ),
            _sliderRow(
              title: 'Move-closer growth',
              value: s.perspective,
              onChanged: (double v) => _save(() => s.setPerspective(v)),
            ),
            _numberRow(
              title: 'Start alignment tolerance (°)',
              value: _trim(s.alignAngle),
              onSubmit: (String v) async {
                final double? parsed = double.tryParse(v);
                if (parsed != null) await _save(() => s.setAlignAngle(parsed));
              },
            ),
            _sliderRow(
              title: 'Minimum face size',
              summary: 'How much of the frame the face has to fill before it can be scored',
              value: s.minFace,
              onChanged: (double v) => _save(() => s.setMinFace(v)),
            ),
            _sliderRow(
              title: 'Minimum image quality',
              summary: 'Below this the frame is called too dark or blurry to judge',
              value: s.quality,
              onChanged: (double v) => _save(() => s.setQuality(v)),
            ),
            _switchRow(
              title: 'Invert left / right',
              summary: 'Flip this if the turn challenges accept the opposite direction on '
                  'your device',
              value: s.invertTurn,
              onChanged: (bool v) => _save(() => s.setInvertTurn(v)),
            ),
            _switchRow(
              title: 'Invert up / down',
              summary: 'Flip this if the look-up and look-down challenges are the wrong '
                  'way round',
              value: s.invertTilt,
              onChanged: (bool v) => _save(() => s.setInvertTilt(v)),
            ),
          ]),
          const SizedBox(height: 16),
          _card('Reset', <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _save(() => s.restoreDefaults()),
                child: const Text('Restore default settings',
                    style: TextStyle(color: FP.accent, fontSize: 16)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  static String _trim(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  // MARK: rows

  Widget _card(String title, List<Widget> rows) {
    return Container(
      decoration: fpCard(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title,
              style: const TextStyle(
                  color: FP.muted, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _label(String title, {String? summary}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(color: FP.text, fontSize: 16)),
          if (summary != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(summary,
                style: const TextStyle(color: FP.muted, fontSize: 12, height: 1.3)),
          ],
        ],
      );

  Widget _sliderRow({
    required String title,
    String? summary,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _label(title, summary: summary)),
              Text(value.toStringAsFixed(2),
                  style: const TextStyle(color: FP.accent, fontSize: 15)),
            ],
          ),
          Slider(
            value: value.clamp(0, 1),
            activeColor: FP.accent,
            inactiveColor: FP.stroke,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _switchRow({
    required String title,
    String? summary,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(child: _label(title, summary: summary)),
          Switch(value: value, activeThumbColor: FP.accent, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _choiceRow<T>({
    required String title,
    required T value,
    required Map<T, String> options,
    required ValueChanged<T> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(child: _label(title)),
          DropdownButton<T>(
            value: value,
            dropdownColor: FP.surfaceAlt,
            underline: const SizedBox.shrink(),
            style: const TextStyle(color: FP.accent, fontSize: 15),
            items: options.entries
                .map((MapEntry<T, String> e) =>
                    DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
                .toList(growable: false),
            onChanged: (T? v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _navRow({
    required String title,
    String? summary,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Expanded(child: _label(title, summary: summary)),
            Text(trailing, style: const TextStyle(color: FP.accent, fontSize: 15)),
            const Icon(Icons.chevron_right, color: FP.muted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _numberRow({
    required String title,
    String? summary,
    required String value,
    required Future<void> Function(String) onSubmit,
  }) {
    return InkWell(
      onTap: () async {
        final TextEditingController controller = TextEditingController(text: value);
        final String? entered = await showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            backgroundColor: FP.surfaceAlt,
            title: Text(title, style: const TextStyle(color: FP.text, fontSize: 18)),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: const TextStyle(color: FP.text),
              decoration: const InputDecoration(hintText: 'Enter a value'),
            ),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                  child: const Text('Save')),
            ],
          ),
        );
        if (entered != null && entered.isNotEmpty) await onSubmit(entered);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Expanded(child: _label(title, summary: summary)),
            Text(value, style: const TextStyle(color: FP.accent, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  /// The pool the sequence is drawn from — one switch per challenge.
  Future<void> _editPool() async {
    final Set<ActiveCheck> selected = s.pool.toSet();
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setLocal) => AlertDialog(
          backgroundColor: FP.surfaceAlt,
          title: const Text('Challenges', style: TextStyle(color: FP.text, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ActiveCheck.values
                  .map((ActiveCheck check) => SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: FP.accent,
                        title: Text(check.title,
                            style: const TextStyle(color: FP.text, fontSize: 15)),
                        value: selected.contains(check),
                        onChanged: (bool on) => setLocal(() {
                          if (on) {
                            selected.add(check);
                          } else {
                            selected.remove(check);
                          }
                        }),
                      ))
                  .toList(growable: false),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
    if (selected.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick at least one challenge')),
        );
      }
      return;
    }
    await _save(() => s.setPool(selected.toList()));
  }
}
