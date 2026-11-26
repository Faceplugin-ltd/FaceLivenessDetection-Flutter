import 'package:face_liveness_sdk/face_liveness_sdk.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_settings.dart';
import '../license.dart';
import '../theme.dart';
import 'about_screen.dart';
import 'settings_screen.dart';

/// Home: engine status, the two liveness demos, settings and about.
///
/// Mirrors Android `ui/MainActivity` + `activity_main.xml` and iOS `ViewController` — hero header
/// with the status pill, an Active-liveness and a Passive-liveness card, Settings and About tiles,
/// and a row that opens the integration guide.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FaceLivenessEngine _engine = FaceLivenessEngine.instance;

  String _status = 'Loading on-device models…';
  Color _statusColor = FP.statusInfo;
  bool _livenessAllowed = false;

  @override
  void initState() {
    super.initState();
    _startEngine();
  }

  Future<void> _startEngine() async {
    await _engine.start(kLicenseKey);
    final String message = await _engine.statusMessage();
    if (!mounted) return;
    setState(() {
      _status = message;
      _statusColor = _engine.isReady ? FP.statusOk : FP.statusError;
      _livenessAllowed = _engine.license.liveness;
    });
  }

  // MARK: actions

  bool _ensureLivenessAllowed() {
    if (!_engine.isReady) {
      _toast('SDK not ready');
      return false;
    }
    if (!_livenessAllowed) {
      _toast('Liveness is not available on this license');
      return false;
    }
    return true;
  }

  Future<void> _openActive() async {
    if (!_ensureLivenessAllowed()) return;
    final ActiveLivenessResult? result =
        await FaceLiveness.startActiveLiveness(widget.settings.activeLiveness());
    if (result == null || !mounted) return;
    _toast(_describe(result));
  }

  /// The demo only reports the verdict; a real integration would act on it.
  String _describe(ActiveLivenessResult result) {
    if (result.passed) return 'Liveness confirmed — live person';
    if (!result.passivePassed) {
      return 'Anti-spoofing check failed — no challenges were asked';
    }
    final ActiveCheck? failed = result.failedCheck;
    if (failed != null) {
      return 'Liveness not confirmed — “${failed.title}” was not completed';
    }
    return 'Liveness not confirmed';
  }

  Future<void> _openPassive() async {
    if (!_ensureLivenessAllowed()) return;
    await FaceLiveness.startPassiveLiveness(
      useFrontCamera: widget.settings.useFrontCamera,
      livenessThreshold: widget.settings.livenessThreshold,
    );
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _toast(url);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: FP.surfaceAlt,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
  }

  // MARK: build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FP.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _hero(),
              const SizedBox(height: 22),
              _sectionLabel('LIVENESS CHECKS'),
              const SizedBox(height: 12),
              _bigCard(
                icon: Icons.bolt,
                title: 'Active liveness',
                subtitle: 'Anti-spoofing gate, then blink, smile, turn your head',
                gradient: true,
                onTap: _openActive,
                enabled: _livenessAllowed,
              ),
              const SizedBox(height: 12),
              _bigCard(
                icon: Icons.center_focus_strong,
                title: 'Passive liveness',
                subtitle: 'Single-frame anti-spoofing with a live score HUD',
                gradient: false,
                onTap: _openPassive,
                enabled: _livenessAllowed,
              ),
              const SizedBox(height: 22),
              _sectionLabel('MORE'),
              const SizedBox(height: 12),
              // Do not stretch in a scroll view — unbounded height breaks Android layout.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _smallTile(
                      icon: Icons.tune,
                      title: 'Settings',
                      subtitle: 'Camera, thresholds, challenge sequence',
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => SettingsScreen(settings: widget.settings),
                        ));
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _smallTile(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'SDK, license and contact',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const AboutScreen(),
                      )),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _docsRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      decoration: BoxDecoration(
        gradient: FP.heroGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: FP.stroke),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: () => _openUrl('https://faceplugin.com'),
            child: Image.asset('assets/fp_logo.png', height: 40, fit: BoxFit.contain,
                alignment: Alignment.centerLeft),
          ),
          const SizedBox(height: 16),
          const Text('On-device face liveness',
              style: TextStyle(
                  color: FP.text, fontSize: 26, fontWeight: FontWeight.bold, height: 1.15)),
          const SizedBox(height: 10),
          const Text(
            'Passive anti-spoofing and guided active checks. Every frame is processed on this '
            'phone — no biometric data leaves the device.',
            style: TextStyle(color: FP.muted, fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerLeft, child: _statusPill()),
        ],
      ),
    );
  }

  /// The accent carries the state, so the fill stays a tint of it.
  Widget _statusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _statusColor.withValues(alpha: 0.40)),
      ),
      child: Text(_status,
          style: TextStyle(color: _statusColor, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: FP.muted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6),
      );

  Widget _bigCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool gradient,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    final Widget card = Container(
      decoration: BoxDecoration(
        gradient: gradient ? FP.primaryTileGradient : null,
        color: gradient ? null : FP.surface,
        borderRadius: BorderRadius.circular(24),
        border: gradient ? null : Border.all(color: FP.stroke),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: <Widget>[
          _iconBubble(icon,
              tint: gradient ? Colors.white : FP.accent,
              background: gradient ? Colors.white24 : FP.accentDim),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: TextStyle(
                        color: gradient ? Colors.white : FP.text,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        color: gradient ? Colors.white.withValues(alpha: 0.85) : FP.muted,
                        fontSize: 13,
                        height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: gradient ? Colors.white : FP.muted),
        ],
      ),
    );
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }

  Widget _smallTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: fpCard(radius: 24),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _iconBubble(icon, tint: FP.accent, background: FP.accentDim),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      color: FP.text, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: FP.muted, fontSize: 12, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _docsRow() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openUrl('https://doc.faceplugin.com'),
        child: Container(
          decoration: fpCard(),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              const Icon(Icons.menu_book, color: FP.accent),
              const SizedBox(width: 14),
              const Expanded(
                child: Text('Open the integration guide',
                    style: TextStyle(
                        color: FP.text, fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              const Icon(Icons.chevron_right, color: FP.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBubble(IconData icon, {required Color tint, required Color background}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(22)),
      child: Icon(icon, color: tint, size: 22),
    );
  }
}
