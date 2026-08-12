// آزمونِ سامانه‌ی طراحی.
//
// این آزمون‌ها قاعده‌های بخش ۳ و ۱۱ را نگه می‌دارند. اگر کسی توکنی را عوض کرد
// که کنتراست یا ارتفاعِ خط را می‌شکند، اینجا می‌شکند، نه در دستِ کاربر.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sareh/design/svg_path.dart';
import 'package:sareh/design/tokens.g.dart';

double _luminance(Color colour) {
  double channel(double value) =>
      value <= 0.03928 ? value / 12.92 : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(colour.r) + 0.7152 * channel(colour.g) + 0.0722 * channel(colour.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('کنتراست — WCAG AA', () {
    for (final theme in [('تیره', SarehColors.dark), ('روشن', SarehColors.light)]) {
      final name = theme.$1;
      final colors = theme.$2;

      test('متن روی زمینه در پوسته‌ی $name دست‌کم ۴٫۵:۱ است', () {
        expect(contrast(colors.onBackground, colors.background), greaterThanOrEqualTo(4.5));
        expect(contrast(colors.onSurface, colors.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(colors.onSurfaceMuted, colors.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(colors.onAction, colors.action), greaterThanOrEqualTo(4.5));
      });

      test('لهجه‌ها در پوسته‌ی $name خوانا می‌مانند', () {
        expect(contrast(colors.achievement, colors.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(colors.accentSoft, colors.surface), greaterThanOrEqualTo(4.5));
        // شنگرف تنها روی حاشیه می‌نشیند، پس کفِ عنصرِ گرافیکی برایش بس است.
        expect(contrast(colors.error, colors.surface), greaterThanOrEqualTo(3.0));
      });
    }
  });

  group('قاعده‌های تایپ', () {
    test('ارتفاعِ خط هرگز زیر ۱٫۷ نمی‌رود', () {
      // فارسی نویسه‌های زیرین و زبرین دارد؛ فشردگیِ لاتین برایش سم است.
      const heights = [
        SarehType.xsLine,
        SarehType.smLine,
        SarehType.mdLine,
        SarehType.lgLine,
        SarehType.xlLine,
        SarehType.xxlLine,
        SarehType.h3Line,
        SarehType.h2Line,
        SarehType.h1Line,
      ];
      for (final height in heights) {
        expect(height, greaterThanOrEqualTo(1.7));
      }
    });

    test('مقیاس با ضریبِ ۱٫۲۵ از پایه‌ی ۱۶ بالا می‌رود', () {
      const scale = [
        SarehType.xs,
        SarehType.sm,
        SarehType.md,
        SarehType.lg,
        SarehType.xl,
        SarehType.xxl,
        SarehType.h3,
        SarehType.h2,
        SarehType.h1,
      ];
      expect(scale, [12.0, 14.0, 16.0, 20.0, 25.0, 31.0, 39.0, 49.0, 61.0]);
      for (var i = 3; i < scale.length; i++) {
        expect((scale[i] / scale[i - 1] - 1.25).abs(), lessThan(0.03));
      }
    });
  });

  group('هندسه و حرکت', () {
    test('شعاع‌ها همان چهارتای سامانه‌اند', () {
      expect(
        [SarehRadius.sharp, SarehRadius.input, SarehRadius.card, SarehRadius.capsule],
        [4.0, 10.0, 20.0, 999.0],
      );
    });

    test('هدفِ لمس دست‌کم ۴۸ پیکسل است', () {
      expect(SarehA11y.minTouchTarget, greaterThanOrEqualTo(48.0));
    });

    test('گره‌چینی در محدوده‌ی نامحسوس می‌ماند', () {
      expect(SarehOpacity.gerehchiniMin, greaterThanOrEqualTo(0.03));
      expect(SarehOpacity.gerehchiniMax, lessThanOrEqualTo(0.06));
    });

    test('زمان‌بندی‌ها از ریزکنش تا جشن بالا می‌روند', () {
      expect(SarehMotion.micro.inMilliseconds, 120);
      expect(SarehMotion.element.inMilliseconds, 220);
      expect(SarehMotion.page.inMilliseconds, 340);
      expect(SarehMotion.hero.inMilliseconds, 600);
      expect(SarehMotion.celebration.inMilliseconds, 1200);
    });

    test('«نورِ واژه» ۶۰۰ میلی‌ثانیه است و ذراتش در ۴۰۰ بلند می‌شوند', () {
      expect(SarehSignature.duration, SarehMotion.hero);
      expect(SarehSignature.particleAt.inMilliseconds, 400);
      expect(SarehSignature.particleCount, 3);
      expect(SarehSignature.particleAt, lessThan(SarehSignature.duration));
    });
  });

  group('تجزیه‌ی مسیرِ SVG', () {
    test('خطِ ساده را می‌خواند', () {
      final path = parseSvgPath('M 0 0 L 10 0 L 10 10 Z');
      expect(path.getBounds(), const Rect.fromLTRB(0, 0, 10, 10));
    });

    test('فرمانِ نسبی همان جای فرمانِ مطلق می‌رسد', () {
      final absolute = parseSvgPath('M 10 10 L 20 10');
      final relative = parseSvgPath('m 10 10 l 10 0');
      expect(relative.getBounds(), absolute.getBounds());
    });

    test('جفت‌مختصاتِ پس از moveto، lineto ضمنی است', () {
      final implicit = parseSvgPath('M 0 0 10 0 10 10');
      final explicit = parseSvgPath('M 0 0 L 10 0 L 10 10');
      expect(implicit.getBounds(), explicit.getBounds());
    });

    test('منحنی‌ها طول می‌سازند تا نور چیزی برای پیمودن داشته باشد', () {
      final path = parseSvgPath('M 0 0 C 10 0 20 10 20 20');
      final metric = path.computeMetrics().first;
      expect(metric.length, greaterThan(20));
    });

    test('S و T از نقطه‌ی مهارِ پیشین بازتاب می‌گیرند', () {
      final path = parseSvgPath('M 0 0 C 5 0 10 5 10 10 S 20 20 30 10');
      expect(path.getBounds().width, closeTo(30, 1));
    });

    test('کمان بسته می‌شود و ابعادِ درست دارد', () {
      final path = parseSvgPath('M 0 10 A 10 10 0 0 1 20 10');
      final bounds = path.getBounds();
      expect(bounds.width, closeTo(20, 0.5));
    });

    test('کمانِ درجازده به خط تبدیل می‌شود، نه به خطا', () {
      final path = parseSvgPath('M 0 0 A 0 0 0 0 1 10 10');
      expect(path.getBounds(), const Rect.fromLTRB(0, 0, 10, 10));
    });

    test('ورودیِ نامعتبر خطای روشن می‌دهد', () {
      expect(() => parseSvgPath('L 10 10'), throwsA(isA<SvgPathParseException>()));
      expect(() => parseSvgPath('M 0 0 X 5'), throwsA(isA<SvgPathParseException>()));
    });

    test('جداکننده‌های کاما و فاصله یکسان‌اند', () {
      expect(
        parseSvgPath('M0,0L10,10').getBounds(),
        parseSvgPath('M 0 0 L 10 10').getBounds(),
      );
    });
  });
}
