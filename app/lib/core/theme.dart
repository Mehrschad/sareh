// تمِ سره — پل میانِ `tokens.g.dart` و `ThemeData`.
//
// هیچ رنگی اینجا ساخته نمی‌شود؛ همه از توکن‌ها می‌آید. تنها کارِ این فایل
// نگاشتنِ توکن‌ها به قراردادهای Material است، به‌علاوه‌ی حالتِ دیس‌لکسی و
// اندازه‌ی قلمِ مستقل از سیستم (بخش ۱۱).

import 'package:flutter/material.dart';

import '../design/nur_e_vajeh.dart' show SarehTheme;
import '../design/tokens.g.dart';

class SarehThemeData {
  const SarehThemeData._();

  static ThemeData dark({bool dyslexic = false}) => _build(SarehColors.dark, Brightness.dark, dyslexic);

  static ThemeData light({bool dyslexic = false}) =>
      _build(SarehColors.light, Brightness.light, dyslexic);

  static ThemeData _build(SarehColors colors, Brightness brightness, bool dyslexic) {
    final family = dyslexic ? SarehType.dyslexicFamily : SarehType.bodyFamily;
    final spacing = dyslexic ? SarehType.dyslexicLetterSpacing : 0.0;

    TextStyle style(double size, double lineHeight, {FontWeight? weight, Color? colour}) =>
        TextStyle(
          fontFamily: family,
          fontSize: size,
          // ارتفاعِ خط برای فارسی هرگز زیر ۱٫۷ نمی‌رود (بخش ۳٫۲).
          height: lineHeight,
          letterSpacing: spacing,
          fontWeight: weight ?? FontWeight.w400,
          color: colour ?? colors.onBackground,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.action,
        onPrimary: colors.onAction,
        secondary: colors.accentSoft,
        onSecondary: colors.background,
        tertiary: colors.achievement,
        onTertiary: colors.background,
        error: colors.error,
        onError: colors.onAction,
        surface: colors.surface,
        onSurface: colors.onSurface,
        outline: colors.outline,
      ),
      textTheme: TextTheme(
        displayLarge: style(SarehType.h1, SarehType.h1Line, weight: FontWeight.w700),
        displayMedium: style(SarehType.h2, SarehType.h2Line, weight: FontWeight.w700),
        displaySmall: style(SarehType.h3, SarehType.h3Line, weight: FontWeight.w700),
        headlineMedium: style(SarehType.xxl, SarehType.xxlLine, weight: FontWeight.w600),
        headlineSmall: style(SarehType.xl, SarehType.xlLine, weight: FontWeight.w600),
        titleLarge: style(SarehType.lg, SarehType.lgLine, weight: FontWeight.w600),
        bodyLarge: style(SarehType.md, SarehType.mdLine),
        bodyMedium: style(SarehType.sm, SarehType.smLine, colour: colors.onSurfaceMuted),
        labelSmall: style(SarehType.xs, SarehType.xsLine, colour: colors.onSurfaceMuted),
      ),
      extensions: <ThemeExtension<dynamic>>[
        SarehTheme(colors: colors, symbolPack: 'ostoore'),
      ],
    );
  }
}

/// چارچوبِ اپ: راست‌به‌چپ، فارسی، و اندازه‌ی قلمِ مستقل از سیستم.
///
/// کاربر باید بتواند قلمِ سره را بزرگ کند بی‌آنکه کلِ گوشی را بزرگ کند، و
/// برعکس (بخش ۱۱).
class SarehShell extends StatelessWidget {
  const SarehShell({
    super.key,
    required this.child,
    this.textScale = 1.0,
    this.reducedMotion = false,
  });

  final Widget child;
  final double textScale;

  /// اگر کاربر خودش «بدون حرکت» را برگزیند، بی‌آنکه سیستم آن را بخواهد.
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MediaQuery(
        data: media.copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: media.disableAnimations || reducedMotion,
        ),
        child: child,
      ),
    );
  }
}
