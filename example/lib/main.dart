import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppSettings settings = await AppSettings.load();
  runApp(FaceLivenessDemo(settings: settings));
}

/// FacePlugin Face Liveness demo for Flutter.
///
/// The home, settings and about screens are Flutter; the two camera screens are the **native**
/// FacePlugin ones, launched through the plugin, so liveness behaves exactly as it does in the
/// Android and iOS apps.
class FaceLivenessDemo extends StatelessWidget {
  const FaceLivenessDemo({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Faceplugin-Face-Liveness',
      debugShowCheckedModeBanner: false,
      theme: FP.theme(),
      home: HomeScreen(settings: settings),
    );
  }
}
