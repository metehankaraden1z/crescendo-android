import 'package:flutter/widgets.dart';

/// Brand colours, matching the CSS custom properties in the web app's app.css.
abstract final class CrColors {
  static const bg = Color(0xFF0E0D0A);
  static const bg2 = Color(0xFF14130F);
  static const surface = Color(0xFF1B1914);
  static const surface2 = Color(0xFF24211A);
  static const surface3 = Color(0xFF2E2A21);
  static const line = Color(0x14F3EBDD); // cream @ 8%
  static const line2 = Color(0x24F3EBDD); // cream @ 14%
  static const text = Color(0xFFF3EBDD);
  static const text2 = Color(0xFFC9BFAD);
  static const muted = Color(0xFF8E8676);
  static const gold = Color(0xFFE9B54A);
  static const gold2 = Color(0xFFF4D66A);
  static const goldDeep = Color(0xFFA9782A);
  static const goldSoft = Color(0x24E9B54A); // gold @ 14%
  static const starEmpty = Color(0xFF3A3529);
  static const danger = Color(0xFFE7745F);
  static const ok = Color(0xFF8FCB8B);
  static const onGold = Color(0xFF15120A);

  static const goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gold2, gold],
  );
}

abstract final class CrRadius {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 26.0;
  static const pill = 999.0;
}

abstract final class CrSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

abstract final class CrShadow {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0xCC000000), blurRadius: 80, spreadRadius: -30, offset: Offset(0, 30)),
  ];
  static const goldGlow = <BoxShadow>[
    BoxShadow(color: Color(0x99E9B54A), blurRadius: 30, spreadRadius: -10, offset: Offset(0, 10)),
  ];
}
