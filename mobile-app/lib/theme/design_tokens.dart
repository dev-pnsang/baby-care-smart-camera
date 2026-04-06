import 'package:flutter/material.dart';

/// Design system colors from `requirement/UI/design` (Baby Blue, Neutral, semantic palettes).
abstract final class DesignTokens {
  // —— Baby Blue ——
  static const Color babyBlue1 = Color(0xFFF3F9FF);
  static const Color babyBlue2 = Color(0xFFE2F1FF);
  static const Color babyBlue3 = Color(0xFFCCE6FF);
  static const Color babyBlue4 = Color(0xFFB4DAFF);
  static const Color babyBlue5 = Color(0xFF9DCFFF);
  static const Color babyBlue6 = Color(0xFF88C4FF);
  static const Color babyBlue7 = Color(0xFF74A7D9);
  static const Color babyBlue8 = Color(0xFF618BB5);
  static const Color babyBlue9 = Color(0xFF4E7091);
  static const Color babyBlue10 = Color(0xFF3D5873);

  // —— Neutral ——
  static const Color neutral1 = Color(0xFFFDFDFD);
  static const Color neutral2 = Color(0xFFF9F9FA);
  static const Color neutral3 = Color(0xFFF4F5F7);
  static const Color neutral4 = Color(0xFFEFF1F3);
  static const Color neutral5 = Color(0xFFEBECEF);
  static const Color neutral8 = Color(0xFFC3C9D1);
  static const Color neutral9 = Color(0xFF949EAC);
  static const Color neutral10 = Color(0xFF627185);
  static const Color neutral11 = Color(0xFF334661);
  static const Color neutral12 = Color(0xFF061D3E);
  static const Color neutral13 = Color(0xFF051935);

  // —— Sunlight Yellow ——
  static const Color sunlight1 = Color(0xFFFFFBED);
  static const Color sunlight2 = Color(0xFFFFF6D3);
  static const Color sunlight6 = Color(0xFFFFDB49);

  // —— Semantic ——
  static const Color error6 = Color(0xFFDA1E28);
  static const Color warning1 = Color(0xFFFEF6E8);
  static const Color warning6 = Color(0xFFF1A61B);
  static const Color success6 = Color(0xFF25A249);

  /// App screen background: light blue → warm cream (Gradient spec + mockups).
  static const LinearGradient screenBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [babyBlue2, sunlight1],
  );

  static const LinearGradient progressNavyGradient = LinearGradient(
    colors: [neutral12, neutral11],
  );
}
