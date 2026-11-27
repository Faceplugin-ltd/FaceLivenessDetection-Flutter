import 'package:face_liveness_sdk/face_liveness_sdk.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

/// About — company, product, licence label, contact.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final LicenseStatus license = FaceLivenessEngine.instance.license;
    return Scaffold(
      backgroundColor: FP.bg,
      appBar: AppBar(
        backgroundColor: FP.bg,
        foregroundColor: FP.text,
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          Image.asset('assets/fp_logo.png', height: 44),
          const SizedBox(height: 20),
          const Text(
            'FacePlugin',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FP.text,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Face Liveness SDK',
            textAlign: TextAlign.center,
            style: TextStyle(color: FP.muted, fontSize: 16),
          ),
          const SizedBox(height: 20),
          _Card(child: Text('License: ${license.label}', style: _body)),
          const SizedBox(height: 12),
          const _Card(
            child: Text(
              'FacePlugin builds on-device identity technology — face recognition, '
              'liveness, and document reading — so biometric data never has to leave '
              'the phone.',
              style: _body,
            ),
          ),
          const SizedBox(height: 12),
          const _Card(
            child: Text(
              'This app demos face liveness on Flutter: passive anti-spoofing from a '
              'single frame, and active liveness as an anti-spoofing gate followed by a '
              'guided challenge sequence. Both screens are the native FacePlugin '
              'implementations, and everything runs fully on-device.',
              style: _body,
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => launchUrl(Uri.parse('https://faceplugin.com')),
            child: const Text('faceplugin.com'),
          ),
          const SizedBox(height: 12),
          const Text(
            '© 2026 FacePlugin. All rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FP.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

const TextStyle _body = TextStyle(color: FP.text, fontSize: 14, height: 1.4);

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: fpCard(),
      child: child,
    );
  }
}
