// GENERATED FILE — دست نزنید.
//
// منبع:      design/tokens.json
// سازنده:    tools/gen_tokens.dart
// بازتولید:  dart run tools/gen_tokens.dart
//
// زبانِ طراحی: کنگره و نور  ·  نسخه: 1.0.0

import 'package:flutter/animation.dart';
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
    required this.kongere,
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
  final Color kongere;

  static const SarehColors dark = SarehColors(
    background: Color(0xFF070D1C),
    surface: Color(0xFF101A33),
    surfaceRaised: Color(0x90162445),
    onBackground: Color(0xFFF2F5FA),
    onSurface: Color(0xFFF2F5FA),
    onSurfaceMuted: Color(0xFFA9B6CC),
    action: Color(0xFF19D9C6),
    onAction: Color(0xFF070D1C),
    accentSoft: Color(0xFF7CF5E3),
    achievement: Color(0xFFF0B94F),
    error: Color(0xFFFF5F49),
    outline: Color(0x3D19D9C6),
    scrim: Color(0xCC070D1C),
    kongere: Color(0x12F2F5FA),
  );

  static const SarehColors light = SarehColors(
    background: Color(0xFFF2F5FA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0x0A070D1C),
    onBackground: Color(0xFF070D1C),
    onSurface: Color(0xFF070D1C),
    onSurfaceMuted: Color(0xFF5A6780),
    action: Color(0xFF15716D),
    onAction: Color(0xFFFFFFFF),
    accentSoft: Color(0xFF17685C),
    achievement: Color(0xFF8A6520),
    error: Color(0xFFB83A2B),
    outline: Color(0x29070D1C),
    scrim: Color(0x66070D1C),
    kongere: Color(0x0D070D1C),
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

  static const String displayFamily = 'Estedad';
  static const FontWeight displayWeight = FontWeight.w900;
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
  static const double kongereMin = 0.04;
  static const double kongereMax = 0.09;
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
  static const double unlitAlpha = 0.14;
  static const double haloAlpha = 0.55;
  static const double frontSharpness = 0.03;
  static const int particleCount = 3;
  static const Duration particleAt = Duration(milliseconds: 400);
  static const double particleRise = 28.0;
  static const Duration particleFade = Duration(milliseconds: 500);
}

/// جشنِ پایانِ منزل.
class SarehJashn {
  static const int particleCount = 24;
  static const double particleRise = 140.0;
  static const Duration particleDuration = Duration(milliseconds: 1600);
  static const Duration countUp = Duration(milliseconds: 900);
}

/// سیمرغ — همراهِ راه.
class SarehSimorgh {
  static const int rayCount = 7;
  static const double strokeWidth = 2.2;
}

/// رنگِ هفت خان — هرکدام یک رنگدانه‌ی کهنِ ایرانی، هم‌معنا با نگهبانش.
///
/// شماره‌ی خان (۱ تا ۷) را به [of] بدهید؛ بیرون از بازه، رنگِ خانِ
/// نخست برمی‌گردد تا محتوای ناهم‌خوان صفحه را نشکند.
class SarehKhanColors {
  const SarehKhanColors._(this.dark, this.light);

  final Color dark;
  final Color light;

  /// کهربا — شیر
  static const kahroba = SarehKhanColors._(Color(0xFFFFB13D), Color(0xFF8A5E10));
  /// فیروزه — دیو تشنگی
  static const firuze = SarehKhanColors._(Color(0xFF19D9C6), Color(0xFF0F7A6E));
  /// زنگار — اژدها
  static const zangar = SarehKhanColors._(Color(0xFF53DE83), Color(0xFF1E7A46));
  /// ارغوان — جادو
  static const arghavan = SarehKhanColors._(Color(0xFFD989F0), Color(0xFF8A3D9E));
  /// لاجوردِ روشن — اولاد
  static const lajevard = SarehKhanColors._(Color(0xFF6FA8FF), Color(0xFF2B5FC4));
  /// مسِ گداخته — ارژنگ
  static const mes = SarehKhanColors._(Color(0xFFFF9166), Color(0xFFA44A22));
  /// سیمینِ برف — دیو سپید
  static const simin = SarehKhanColors._(Color(0xFFC9E4F5), Color(0xFF44708C));

  static const List<SarehKhanColors> all = [
    kahroba,
    firuze,
    zangar,
    arghavan,
    lajevard,
    mes,
    simin,
  ];

  static SarehKhanColors of(int khan) =>
      khan >= 1 && khan <= all.length ? all[khan - 1] : all.first;
}
