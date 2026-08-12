// GENERATED FILE — دست نزنید.
//
// منبع:      design/tokens.json
// سازنده:    tools/gen_tokens.dart
// بازتولید:  dart run tools/gen_tokens.dart
//
// زبانِ طراحی: خَط و نور  ·  نسخه: 1.0.0

import 'package:flutter/painting.dart';

/// رنگ‌های یک پوسته. دو نمونه دارد: [dark] و [light].
class SarehColors {
  const SarehColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.onBackground,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.action,
    required this.onAction,
    required this.accentSoft,
    required this.achievement,
    required this.error,
    required this.outline,
    required this.scrim,
    required this.gerehchini,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color onBackground;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color action;
  final Color onAction;
  final Color accentSoft;
  final Color achievement;
  final Color error;
  final Color outline;
  final Color scrim;
  final Color gerehchini;

  static const SarehColors dark = SarehColors(
    background: Color(0xFF0A1730),
    surface: Color(0xFF122A4E),
    surfaceRaised: Color(0x90173460),
    onBackground: Color(0xFFF5F0E6),
    onSurface: Color(0xFFF5F0E6),
    onSurfaceMuted: Color(0xFFD9C7A7),
    action: Color(0xFF2BA8A8),
    onAction: Color(0xFF0A1730),
    accentSoft: Color(0xFF5FD3C4),
    achievement: Color(0xFFE8B04B),
    error: Color(0xFFD9503F),
    outline: Color(0x3D2BA8A8),
    scrim: Color(0xCC0A1730),
    gerehchini: Color(0x0FF5F0E6),
  );

  static const SarehColors light = SarehColors(
    background: Color(0xFFF5F0E6),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0x0A0A1730),
    onBackground: Color(0xFF0A1730),
    onSurface: Color(0xFF0A1730),
    onSurfaceMuted: Color(0xFF5A6A82),
    action: Color(0xFF15716D),
    onAction: Color(0xFFFFFFFF),
    accentSoft: Color(0xFF17685C),
    achievement: Color(0xFF8A6520),
    error: Color(0xFFB83A2B),
    outline: Color(0x290A1730),
    scrim: Color(0x660A1730),
    gerehchini: Color(0x0D0A1730),
  );
}

/// مقیاسِ تایپ. `Line` ارتفاعِ خط است و هرگز زیر ۱٫۷ نمی‌رود.
class SarehType {
  static const double xs = 12.0;
  static const double xsLine = 1.75;
  static const double sm = 14.0;
  static const double smLine = 1.75;
  static const double md = 16.0;
  static const double mdLine = 1.75;
  static const double lg = 20.0;
  static const double lgLine = 1.7;
  static const double xl = 25.0;
  static const double xlLine = 1.7;
  static const double xxl = 31.0;
  static const double xxlLine = 1.7;
  static const double h3 = 39.0;
  static const double h3Line = 1.7;
  static const double h2 = 49.0;
  static const double h2Line = 1.7;
  static const double h1 = 61.0;
  static const double h1Line = 1.7;

  static const String displayFamily = 'Gulzar';
  static const String bodyFamily = 'Vazirmatn';
  static const String dyslexicFamily = 'Estedad';
  static const double dyslexicLetterSpacing = 0.06;
}

/// فاصله‌ها.
class SarehSpace {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 40.0;
  static const double xxl = 64.0;
}

/// شعاعِ گوشه‌ها. کارت‌ها [card]، دکمه‌ها [capsule]، ورودی‌ها [input].
class SarehRadius {
  static const double sharp = 4.0;
  static const double input = 10.0;
  static const double card = 20.0;
  static const double capsule = 999.0;
}

/// کدری‌ها.
class SarehOpacity {
  static const double gerehchiniMin = 0.03;
  static const double gerehchiniMax = 0.06;
  static const double lockedStation = 0.4;
  static const double disabled = 0.38;
}

/// منحنی‌ها و زمان‌بندی‌ها.
class SarehMotion {
  static const Cubic kamanArash = Cubic(0.16, 0.84, 0.24, 1.0);
  static const Cubic kamanTiz = Cubic(0.4, 0.0, 0.2, 1.0);

  static const Duration micro = Duration(milliseconds: 120);
  static const Duration element = Duration(milliseconds: 220);
  static const Duration page = Duration(milliseconds: 340);
  static const Duration hero = Duration(milliseconds: 600);
  static const Duration celebration = Duration(milliseconds: 1200);

  static const Cubic microCurve = kamanTiz;
  static const Cubic elementCurve = kamanArash;
  static const Cubic pageCurve = kamanArash;
  static const Cubic heroCurve = kamanArash;
  static const Cubic celebrationCurve = kamanArash;

  static const double springStiffness = 180.0;
  static const double springDamping = 20.0;
  static const double springMass = 1.0;
  static const double shakeAmplitude = 8.0;
  static const int shakeCycles = 3;
  static const Duration shake = Duration(milliseconds: 300);
}

/// دسترس‌پذیری.
class SarehA11y {
  static const double minTouchTarget = 48.0;
}

/// عنصرِ امضا — «نورِ واژه».
class SarehSignature {
  static const Duration startDelay = Duration(milliseconds: 100);
  static const Duration duration = Duration(milliseconds: 600);
  static const double strokeWidth = 3.0;
  static const double glowSigma = 6.0;
  static const double trailFraction = 0.18;
  static const int particleCount = 3;
  static const Duration particleAt = Duration(milliseconds: 400);
  static const double particleRise = 28.0;
  static const Duration particleFade = Duration(milliseconds: 500);
}
