import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';
import 'typography.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: CrColors.gold,
      onPrimary: CrColors.onGold,
      secondary: CrColors.gold2,
      onSecondary: CrColors.onGold,
      surface: CrColors.surface,
      onSurface: CrColors.text,
      error: CrColors.danger,
      onError: CrColors.onGold,
      outline: CrColors.line2,
      outlineVariant: CrColors.line,
    );

    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(CrRadius.sm),
          borderSide: BorderSide(color: color),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: CrColors.bg,
      canvasColor: CrColors.bg,
      dividerColor: CrColors.line,
      textTheme: CrText.textTheme,
      // No ink ripples or grey highlights: each Crescendo widget styles its own feedback.
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: CrColors.gold,
        selectionColor: Color(0x66E9B54A),
        selectionHandleColor: CrColors.gold,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CrColors.bg2,
        hintStyle: CrText.body(color: CrColors.muted),
        labelStyle: CrText.body(size: 14, weight: FontWeight.w600, color: CrColors.text2),
        contentPadding: const EdgeInsets.symmetric(horizontal: CrSpace.lg, vertical: CrSpace.lg),
        enabledBorder: border(CrColors.line2),
        focusedBorder: border(CrColors.gold),
        errorBorder: border(CrColors.danger),
        focusedErrorBorder: border(CrColors.danger),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CrescendoPageTransitionsBuilder(),
        TargetPlatform.iOS: CrescendoPageTransitionsBuilder(),
      }),
    );
  }
}
