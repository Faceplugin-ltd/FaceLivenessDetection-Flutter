import 'package:face_liveness_sdk/face_liveness_sdk.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'about_page.dart';
import 'license.dart';
import 'settings.dart';
import 'settings_page.dart';
import 'theme.dart';

/// Home: engine status, Active / Passive liveness, Settings and About.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'Loading on-device models…';
  Color _statusColor = FP.statusInfo;
  bool _livenessAllowed = false;
  LivenessSettings _settings = LivenessSettings.defaults();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final LivenessSettings settings = await loadSettings();
    try {
      await FaceLivenessEngine.instance.start(demoLicense());
      final String message = await FaceLivenessEngine.instance.statusMessage();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _status = message;
        _statusColor =
            FaceLivenessEngine.instance.isReady ? FP.statusOk : FP.statusError;
        _livenessAllowed = FaceLivenessEngine.instance.license.liveness;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _status = error is Error ? error.toString() : '$error';
        _statusColor = FP.statusError;
        _livenessAllowed = false;
      });
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _ensureAllowed() {
    if (!FaceLivenessEngine.instance.isReady) {
      _toast('SDK not ready');
      return false;
    }
    if (!_livenessAllowed) {
      _toast('Liveness is not available on this license');
      return false;
    }
    return true;
  }

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

  Future<void> _openActive() async {
    if (!_ensureAllowed()) return;
    final LivenessSettings current = await loadSettings();
    final ActiveLivenessResult? result =
        await FaceLiveness.startActiveLiveness(current.toOptions());
    if (result != null && mounted) _toast(_describe(result));
  }

  Future<void> _openPassive() async {
    if (!_ensureAllowed()) return;
    final LivenessSettings current = await loadSettings();
    await FaceLiveness.startPassiveLiveness(
      useFrontCamera: current.useFrontCamera,
      livenessThreshold: current.livenessThreshold,
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
    );
    final LivenessSettings settings = await loadSettings();
    if (mounted) setState(() => _settings = settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FP.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: <Widget>[
            _Hero(status: _status, statusColor: _statusColor),
            const SizedBox(height: 16),
            _LivenessCard(
              title: 'Active liveness',
              body:
                  'Anti-spoofing gate, then a short guided sequence of challenges.',
              gradient: true,
              onTap: _openActive,
            ),
            const SizedBox(height: 12),
            _LivenessCard(
              title: 'Passive liveness',
              body:
                  'Live camera anti-spoofing with liveness, quality and pose — no actions asked.',
              gradient: false,
              onTap: _openPassive,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _Tile(
                    title: 'Settings',
                    onTap: _openSettings,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Tile(
                    title: 'About',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AboutPage()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => launchUrl(Uri.parse('https://doc.faceplugin.com')),
              child: Text(
                'Integration guide  ·  camera lens ${_settings.useFrontCamera ? 'front' : 'back'}',
                style: const TextStyle(color: FP.muted, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.status, required this.statusColor});

  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[FP.heroFrom, FP.heroTo],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Image.asset('assets/fp_logo.png', height: 36),
          const SizedBox(height: 16),
          const Text(
            'Face Liveness',
            style: TextStyle(
              color: FP.text,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'On-device anti-spoofing for KYC and remote identity checks.',
            style: TextStyle(color: FP.muted, fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: FP.bg.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: statusColor.withValues(alpha: 0.45)),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LivenessCard extends StatelessWidget {
  const _LivenessCard({
    required this.title,
    required this.body,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String body;
  final bool gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Decoration decoration = gradient
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[FP.brandViolet, FP.brandVioletDeep],
            ),
          )
        : fpCard();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: decoration,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: gradient ? Colors.white : FP.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: TextStyle(
                    color: gradient ? Colors.white70 : FP.muted,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: fpCard(radius: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FP.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
