// آزمونِ سامانه‌ی طراحی.
//
// این آزمون‌ها قاعده‌های بخش ۳ و ۱۱ را نگه می‌دارند. اگر کسی توکنی را عوض کرد
// که کنتراست یا ارتفاعِ خط را می‌شکند، اینجا می‌شکند، نه در دستِ کاربر.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sareh/design/kongere.dart';
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

    test('کنگره در محدوده‌ی نامحسوس می‌ماند', () {
      expect(SarehOpacity.kongereMin, greaterThanOrEqualTo(0.03));
      expect(SarehOpacity.kongereMax, lessThanOrEqualTo(0.10));
    });

    test('قلمِ نمایشی هندسی است، نه نستعلیق', () {
      // اگر روزی به نستعلیق برگشتیم، این آزمون باید آگاهانه عوض شود.
      expect(SarehType.displayFamily, isNot('Gulzar'));
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

  group('کنگره', () {
    // دندانه‌ی هخامنشی: سراسر خطِ راست، و آینه‌وار قرینه. اگر این بشکند،
    // نقش دیگر کنگره نیست.
    Path merlon({int steps = 3}) =>
        merlonPath(width: 64, height: 32, steps: steps);

    List<Offset> corners(Path path) {
      final points = <Offset>[];
      for (final metric in path.computeMetrics()) {
        for (var i = 0; i <= 200; i++) {
          final d = metric.length * i / 200;
          points.add(metric.getTangentForOffset(d)!.position);
        }
      }
      return points;
    }

    test('از پای دیوار آغاز و به پای دیوار ختم می‌شود', () {
      final points = corners(merlon());
      expect(points.first.dx, closeTo(0, 0.01));
      expect(points.first.dy, closeTo(32, 0.01));
      expect(points.last.dx, closeTo(64, 0.01));
      expect(points.last.dy, closeTo(32, 0.01));
    });

    test('تمامِ پهنا و بلندای خشت را می‌گیرد', () {
      final bounds = merlon().getBounds();
      expect(bounds.left, closeTo(0, 0.01));
      expect(bounds.right, closeTo(64, 0.01));
      expect(bounds.top, closeTo(0, 0.01));
      expect(bounds.bottom, closeTo(32, 0.01));
    });

    test('قرینه‌ی آینه‌ای است', () {
      final points = corners(merlon());
      for (var i = 0; i < points.length; i++) {
        final mirrored = points[points.length - 1 - i];
        expect(64 - mirrored.dx, closeTo(points[i].dx, 0.05));
        expect(mirrored.dy, closeTo(points[i].dy, 0.05));
      }
    });

    test('تختِ بالا در میانه می‌نشیند', () {
      final flat = corners(merlon()).where((p) => p.dy < 0.05).toList();
      final centre = (flat.first.dx + flat.last.dx) / 2;
      expect(centre, closeTo(32, 0.1));
    });

    test('شمارِ پله‌ها را می‌پذیرد', () {
      expect(merlon(steps: 2).getBounds(), merlon(steps: 4).getBounds());
    });
  });
}
