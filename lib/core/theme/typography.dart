import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Fraunces for display type, Instrument Sans for everything else (same as the web app).
abstract final class CrText {
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w800,
    FontStyle style = FontStyle.normal,
    Color color = CrColors.text,
  }) =>
      GoogleFonts.getFont(
        'Fraunces',
        fontSize: size,
        fontWeight: weight,
        fontStyle: style,
        color: color,
        height: 1.0,
        letterSpacing: -0.045 * size, // CSS: letter-spacing: -.045em
      );

  static TextStyle body({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color color = CrColors.text,
    double height = 1.5,
  }) =>
      GoogleFonts.getFont('Instrument Sans', fontSize: size, fontWeight: weight, color: color, height: height);

  /// Small gold uppercase label ("THE TRACK-BY-TRACK MUSIC DIARY"). Pass uppercase text.
  static TextStyle eyebrow({Color color = CrColors.gold}) =>
      body(size: 12, weight: FontWeight.w700, color: color).copyWith(letterSpacing: 1.9);

  /// Scores like "4.5": bold gold with tabular figures so columns line up.
  static TextStyle score({double size = 15}) => body(size: size, weight: FontWeight.w700, color: CrColors.gold2)
      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextTheme get textTheme => TextTheme(
        displayLarge: display(56),
        displayMedium: display(44),
        headlineLarge: display(34, weight: FontWeight.w700),
        headlineMedium: display(28, weight: FontWeight.w600),
        titleLarge: body(size: 20, weight: FontWeight.w600),
        titleMedium: body(size: 17, weight: FontWeight.w600),
        bodyLarge: body(size: 16),
        bodyMedium: body(size: 15, color: CrColors.text2),
        bodySmall: body(size: 13, color: CrColors.muted),
        labelLarge: body(size: 15, weight: FontWeight.w600),
      );
}
