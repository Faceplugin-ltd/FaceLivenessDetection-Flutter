import 'package:flutter/material.dart';

/// Palette from Face-LivenessDetection-Android `colors.xml`.
abstract final class FP {
  static const Color bg = Color(0xFF0B0B12);
  static const Color surface = Color(0xFF14141D);
  static const Color text = Color(0xFFF2F0F7);
  static const Color muted = Color(0xFF9B96AC);
  static const Color accent = Color(0xFFA48CFF);
  static const Color stroke = Color(0xFF262635);
  static const Color brandViolet = Color(0xFF7C5CFF);
  static const Color brandVioletDeep = Color(0xFF4A2BB5);
  static const Color statusError = Color(0xFFE5484D);
  static const Color statusOk = Color(0xFF2EE6A6);
  static const Color statusInfo = Color(0xFF5B8DEF);
  static const Color heroFrom = Color(0xFF241B46);
  static const Color heroTo = Color(0xFF101019);
}

BoxDecoration fpCard({double radius = 20}) => BoxDecoration(
      color: FP.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: FP.stroke),
    );
