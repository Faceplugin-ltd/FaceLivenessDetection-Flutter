import 'package:face_liveness_sdk/face_liveness_sdk.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

/// About — company, product, what the licence unlocks, and contact.
///
/// Mirrors Android `ui/AboutActivity` and iOS `AboutViewController`.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LicenseStatus license = FaceLivenessEngine.instance.license;
    return Scaffold(
      backgroundColor: FP.bg,
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: <Widget>[
          Center(child: Image.asset('assets/fp_logo.png', height: 44)),
          const SizedBox(height: 20),
          const Center(
            child: Text('FacePlugin',
                style: TextStyle(color: FP.text, fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('Face Liveness SDK',
                style: TextStyle(color: FP.accent, fontSize: 15)),
          ),
          const SizedBox(height: 16),
          _card(Text('License: ${license.label}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: FP.text, fontSize: 13))),
          const SizedBox(height: 16),
          _card(const Text(
            'FacePlugin builds on-device identity technology — face recognition, liveness, and '
            'document reading — so biometric data never has to leave the phone.',
            style: TextStyle(color: FP.text, fontSize: 14, height: 1.35),
          )),
          const SizedBox(height: 16),
          _card(const Text(
            'This app demos face liveness on Flutter: passive anti-spoofing from a single frame, '
            'and active liveness as an anti-spoofing gate followed by a guided challenge '
            'sequence. Both screens are the native FacePlugin implementations, and everything '
            'runs fully on-device.',
            style: TextStyle(color: FP.text, fontSize: 14, height: 1.35),
          )),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => launchUrl(Uri.parse('https://faceplugin.com'),
                  mode: LaunchMode.externalApplication),
              child: const Text('faceplugin.com',
                  style: TextStyle(color: FP.accent, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('© 2026 FacePlugin. All rights reserved.',
                style: TextStyle(color: FP.muted, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _card(Widget child) => Container(
        decoration: fpCard(),
        padding: const EdgeInsets.all(16),
        child: child,
      );
}
