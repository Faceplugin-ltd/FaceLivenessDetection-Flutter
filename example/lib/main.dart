import 'package:flutter/material.dart';

import 'home_page.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FaceLivenessApp());
}

class FaceLivenessApp extends StatelessWidget {
  const FaceLivenessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Faceplugin-Face-Liveness',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: FP.bg,
        colorScheme: const ColorScheme.dark(
          primary: FP.accent,
          secondary: FP.statusOk,
          surface: FP.surface,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
