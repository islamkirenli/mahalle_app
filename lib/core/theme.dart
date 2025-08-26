import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Buradan seç → tüm uygulamayı etkiler.
enum AppFont { inter, rubik, notoSans }
const selectedAppFont = AppFont.rubik;

TextTheme _applyAppFont(TextTheme base) {
  switch (selectedAppFont) {
    case AppFont.inter:
      return GoogleFonts.interTextTheme(base);
    case AppFont.rubik:
      return GoogleFonts.rubikTextTheme(base);
    case AppFont.notoSans:
      return GoogleFonts.notoSansTextTheme(base);
  }
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF2F8BFF),
    brightness: Brightness.light,
  );

  return base.copyWith(
    textTheme: _applyAppFont(base.textTheme),
    primaryTextTheme: _applyAppFont(base.primaryTextTheme),
  );
}

