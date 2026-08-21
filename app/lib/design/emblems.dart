// نشان‌های سره — سیمرغ، نگهبانانِ هفت خان و آیکن‌های شمارگان.
//
// همه CustomPainter اند، نه تصویر: در هر اندازه تیزند، رنگشان از توکن‌ها
// می‌آید و پوسته‌ی روشن/تیره را خودبه‌خود دنبال می‌کنند، و APK را سنگین
// نمی‌کنند. زبانِ خط همان زبانِ نقشِ برجسته‌ی تختِ جمشید است: خطِ راست،
// چهل‌وپنج درجه و کمانِ ساده — نه پیچشِ گیاهیِ دوره‌های پسین.
//
// چرا سیمرغ: در شاهنامه سیمرغ راهنماست — زال را می‌پرورد و رستم را در
// سخت‌ترین جا راه می‌نماید. همراهِ راهِ آموختن باید همین باشد: پشتیبان،
// نه داور. هفت پرِ دمش، هفت خان است.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'tokens.g.dart';

/// سیمرغ — همراهِ کاربر در سراسرِ راه.
class SimorghEmblem extends StatelessWidget {
  const SimorghEmblem({
    super.key,
    required this.size,
    required this.colour,
    this.accent,
  });

  final double size;

  /// رنگِ بدنه و دم.
  final Color colour;

  /// رنگِ چشم‌های پرِ دم؛ اگر ندهید، همان [colour] کم‌رنگ.
  final Color? accent;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _SimorghPainter(
          colour: colour,
          accent: accent ?? colour.withValues(alpha: 0.5),
        ),
      );
}

class _SimorghPainter extends CustomPainter {
  _SimorghPainter({required this.colour, required this.accent});

  final Color colour;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 120;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = SarehSimorgh.strokeWidth * s
      ..strokeCap = StrokeCap.round
      ..color = colour;
    final fill = Paint()..color = accent;

    // دم: بادبزنی از هفت پر که از تهیگاه می‌گسترد — هفت خان.
    final root = Offset(78 * s, 78 * s);
    const spread = math.pi * 0.62;
    const tilt = math.pi * 0.78; // رو به بالا-چپ؛ پرها پشتِ سرِ مرغ.
    for (var i = 0; i < SarehSimorgh.rayCount; i++) {
      final t =
          SarehSimorgh.rayCount == 1 ? 0.5 : i / (SarehSimorgh.rayCount - 1);
      final angle = tilt - spread / 2 + spread * t;
      final len = (34 + 10 * math.sin(math.pi * t)) * s;
      final tip = root + Offset(math.cos(angle) * len, -math.sin(angle) * len);
      canvas.drawLine(root, tip, stroke);
      // چشمِ پر — مثلِ پرِ طاووس، نقطه‌ی پایانِ هر خان.
      canvas.drawCircle(tip, 3.2 * s, fill);
    }

    // بدنه: بادامی ساده.
    final body = Path()
      ..moveTo(78 * s, 78 * s)
      ..quadraticBezierTo(58 * s, 92 * s, 40 * s, 82 * s)
      ..quadraticBezierTo(30 * s, 76 * s, 34 * s, 66 * s)
      ..quadraticBezierTo(46 * s, 52 * s, 70 * s, 62 * s)
      ..close();
    canvas.drawPath(body, stroke);

    // گردن و سر: کمانی بلند و برافراشته — سیمرغ سر خم نمی‌کند.
    final neck = Path()
      ..moveTo(40 * s, 70 * s)
      ..quadraticBezierTo(28 * s, 58 * s, 30 * s, 40 * s)
      ..quadraticBezierTo(31 * s, 30 * s, 24 * s, 26 * s);
    canvas.drawPath(neck, stroke);
    // منقار: دو خطِ کوتاهِ تیز.
    canvas.drawLine(Offset(24 * s, 26 * s), Offset(14 * s, 28 * s), stroke);
    canvas.drawLine(Offset(24 * s, 26 * s), Offset(16 * s, 32 * s), stroke);
    // تاج: دو پرِ کوچک — نشانِ فرمانروایی بر پرندگان.
    canvas.drawLine(Offset(28 * s, 24 * s), Offset(32 * s, 12 * s), stroke);
    canvas.drawLine(Offset(32 * s, 26 * s), Offset(40 * s, 16 * s), stroke);
    // چشم.
    canvas.drawCircle(Offset(26 * s, 30 * s), 1.6 * s, fill);

    // بال: سه کمانِ پیاپی روی بدنه.
    for (var i = 0; i < 3; i++) {
      final wing = Path()
        ..moveTo((48 + i * 8) * s, (60 + i * 4) * s)
        ..quadraticBezierTo(
          (66 + i * 8) * s,
          (44 + i * 6) * s,
          (86 + i * 6) * s,
          (48 + i * 8) * s,
        );
      canvas.drawPath(wing, stroke);
    }
  }

  @override
  bool shouldRepaint(_SimorghPainter old) =>
      old.colour != colour || old.accent != accent;
}

/// نشانِ فَرّ — قرصِ بالدار، ساده‌شده تا سه خطِ پرواز و یک قرص.
class FarrIcon extends StatelessWidget {
  const FarrIcon({super.key, required this.size, required this.colour});

  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _FarrPainter(colour),
      );
}

class _FarrPainter extends CustomPainter {
  _FarrPainter(this.colour);
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 24;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..color = colour;
    // قرص.
    canvas.drawCircle(Offset(12 * s, 10 * s), 4.4 * s, stroke);
    // سه خطِ بال در هر سو.
    for (final side in const [-1, 1]) {
      for (var i = 0; i < 3; i++) {
        final y = (8.0 + i * 3.4) * s;
        canvas.drawLine(
          Offset((12 + side * 6.5) * s, y),
          Offset((12 + side * (10.5 - i * 1.6)) * s, y),
          stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FarrPainter old) => old.colour != colour;
}

/// نشانِ زنجیره — آتشِ جاویدان بر پایه‌ی پلکانی.
class AtashIcon extends StatelessWidget {
  const AtashIcon({super.key, required this.size, required this.colour});

  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _AtashPainter(colour),
      );
}

class _AtashPainter extends CustomPainter {
  _AtashPainter(this.colour);
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 24;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = colour;
    // شعله: لوزیِ کشیده.
    final flame = Path()
      ..moveTo(12 * s, 2.5 * s)
      ..lineTo(16.5 * s, 10 * s)
      ..lineTo(12 * s, 15 * s)
      ..lineTo(7.5 * s, 10 * s)
      ..close();
    canvas.drawPath(flame, stroke);
    // پایه‌ی پلکانی — آتشدانِ هخامنشی.
    final base = Path()
      ..moveTo(6 * s, 21.5 * s)
      ..lineTo(6 * s, 19.5 * s)
      ..lineTo(9 * s, 19.5 * s)
      ..lineTo(9 * s, 17.5 * s)
      ..lineTo(15 * s, 17.5 * s)
      ..lineTo(15 * s, 19.5 * s)
      ..lineTo(18 * s, 19.5 * s)
      ..lineTo(18 * s, 21.5 * s)
      ..close();
    canvas.drawPath(base, stroke);
  }

  @override
  bool shouldRepaint(_AtashPainter old) => old.colour != colour;
}

/// نشانِ گوهر — لوزیِ تراش‌خورده.
class GoharIcon extends StatelessWidget {
  const GoharIcon({super.key, required this.size, required this.colour});

  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _GoharPainter(colour),
      );
}

class _GoharPainter extends CustomPainter {
  _GoharPainter(this.colour);
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 24;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeJoin = StrokeJoin.round
      ..color = colour;
    final gem = Path()
      ..moveTo(5 * s, 9 * s)
      ..lineTo(9 * s, 4.5 * s)
      ..lineTo(15 * s, 4.5 * s)
      ..lineTo(19 * s, 9 * s)
      ..lineTo(12 * s, 20 * s)
      ..close();
    canvas.drawPath(gem, stroke);
    // خطوطِ تراش.
    canvas.drawLine(Offset(5 * s, 9 * s), Offset(19 * s, 9 * s), stroke);
    canvas.drawLine(Offset(9 * s, 4.5 * s), Offset(12 * s, 20 * s), stroke);
    canvas.drawLine(Offset(15 * s, 4.5 * s), Offset(12 * s, 20 * s), stroke);
  }

  @override
  bool shouldRepaint(_GoharPainter old) => old.colour != colour;
}

/// نشانِ نگهبانِ یک خان — هندسیِ ساده، به رنگِ همان خان.
///
/// شماره‌ی خان ۱ تا ۷ است؛ بیرون از بازه، نگهبانِ نخست کشیده می‌شود
/// (همان قراردادِ [SarehKhanColors.of]).
class GuardianEmblem extends StatelessWidget {
  const GuardianEmblem({
    super.key,
    required this.khan,
    required this.size,
    required this.colour,
  });

  final int khan;
  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _GuardianPainter(khan: khan, colour: colour),
      );
}

class _GuardianPainter extends CustomPainter {
  _GuardianPainter({required this.khan, required this.colour});

  final int khan;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 48;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = colour;
    final fill = Paint()..color = colour.withValues(alpha: 0.35);

    switch (khan >= 1 && khan <= 7 ? khan : 1) {
      case 1: // شیر — یالِ کنگره‌ای، نیم‌رخِ نگهبانِ دروازه.
        final mane = Path()
          ..moveTo(10 * s, 40 * s)
          ..lineTo(10 * s, 22 * s)
          ..lineTo(15 * s, 22 * s)
          ..lineTo(15 * s, 14 * s)
          ..lineTo(21 * s, 14 * s)
          ..lineTo(21 * s, 8 * s)
          ..lineTo(30 * s, 8 * s)
          ..lineTo(30 * s, 14 * s)
          ..lineTo(36 * s, 14 * s)
          ..lineTo(36 * s, 22 * s)
          ..lineTo(36 * s, 26 * s);
        canvas.drawPath(mane, stroke);
        // پوزه رو به پیش.
        canvas.drawLine(Offset(36 * s, 26 * s), Offset(43 * s, 26 * s), stroke);
        canvas.drawLine(Offset(43 * s, 26 * s), Offset(43 * s, 32 * s), stroke);
        canvas.drawLine(Offset(43 * s, 32 * s), Offset(34 * s, 32 * s), stroke);
        canvas.drawLine(Offset(34 * s, 32 * s), Offset(30 * s, 40 * s), stroke);
        canvas.drawLine(Offset(30 * s, 40 * s), Offset(10 * s, 40 * s), stroke);
        canvas.drawCircle(Offset(35 * s, 22 * s), 1.8 * s, fill);
      case 2: // دیو تشنگی — سرِ شاخدار و قطره‌ای که می‌جوید.
        canvas.drawArc(
          Rect.fromCircle(center: Offset(24 * s, 28 * s), radius: 12 * s),
          math.pi * 0.05,
          math.pi * 0.9,
          false,
          stroke,
        );
        canvas.drawLine(Offset(13 * s, 24 * s), Offset(8 * s, 10 * s), stroke);
        canvas.drawLine(Offset(35 * s, 24 * s), Offset(40 * s, 10 * s), stroke);
        final drop = Path()
          ..moveTo(24 * s, 20 * s)
          ..quadraticBezierTo(30 * s, 30 * s, 24 * s, 34 * s)
          ..quadraticBezierTo(18 * s, 30 * s, 24 * s, 20 * s)
          ..close();
        canvas.drawPath(drop, fill);
      case 3: // اژدها — پیکرِ زیگزاگِ قائم با زبانِ دوشاخه.
        final serpent = Path()
          ..moveTo(8 * s, 40 * s)
          ..lineTo(20 * s, 40 * s)
          ..lineTo(20 * s, 30 * s)
          ..lineTo(32 * s, 30 * s)
          ..lineTo(32 * s, 20 * s)
          ..lineTo(20 * s, 20 * s)
          ..lineTo(20 * s, 12 * s)
          ..lineTo(34 * s, 12 * s);
        canvas.drawPath(serpent, stroke);
        canvas.drawLine(Offset(34 * s, 12 * s), Offset(40 * s, 8 * s), stroke);
        canvas.drawLine(Offset(34 * s, 12 * s), Offset(40 * s, 16 * s), stroke);
        canvas.drawCircle(Offset(31 * s, 10 * s), 1.6 * s, fill);
      case 4: // جادو — ستاره‌ی هشت‌پرِ رزتِ تختِ جمشید و هلال.
        for (var i = 0; i < 8; i++) {
          final angle = math.pi * i / 4;
          canvas.drawLine(
            Offset(
              24 * s + math.cos(angle) * 5 * s,
              24 * s + math.sin(angle) * 5 * s,
            ),
            Offset(
              24 * s + math.cos(angle) * 15 * s,
              24 * s + math.sin(angle) * 15 * s,
            ),
            stroke,
          );
        }
        canvas.drawCircle(Offset(24 * s, 24 * s), 5 * s, stroke);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(24 * s, 24 * s), radius: 19 * s),
          -math.pi * 0.25,
          math.pi * 0.5,
          false,
          stroke,
        );
      case 5: // اولاد — بندِ گرفتار: دو چهارگوشِ درهم.
        canvas.drawRect(
          Rect.fromLTWH(10 * s, 16 * s, 20 * s, 20 * s),
          stroke,
        );
        canvas.drawRect(
          Rect.fromLTWH(18 * s, 10 * s, 20 * s, 20 * s),
          stroke,
        );
        canvas.drawCircle(Offset(24 * s, 23 * s), 2 * s, fill);
      case 6: // ارژنگ — گرزِ گاوسر.
        canvas.drawLine(Offset(24 * s, 42 * s), Offset(24 * s, 22 * s), stroke);
        canvas.drawCircle(Offset(24 * s, 15 * s), 7 * s, stroke);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(15 * s, 9 * s), radius: 6 * s),
          math.pi * 0.1,
          math.pi * 0.75,
          false,
          stroke,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(33 * s, 9 * s), radius: 6 * s),
          math.pi * 0.15,
          math.pi * 0.75,
          false,
          stroke,
        );
        canvas.drawCircle(Offset(21 * s, 14 * s), 1.4 * s, fill);
        canvas.drawCircle(Offset(27 * s, 14 * s), 1.4 * s, fill);
      case 7: // دیو سپید — نقابِ پهن با دو شاخِ بزرگِ خمیده.
        canvas.drawRect(
          Rect.fromLTWH(14 * s, 20 * s, 20 * s, 18 * s),
          stroke,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(10 * s, 16 * s), radius: 9 * s),
          -math.pi * 0.1,
          math.pi * 0.7,
          false,
          stroke,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(38 * s, 16 * s), radius: 9 * s),
          math.pi * 0.4,
          math.pi * 0.7,
          false,
          stroke,
        );
        canvas.drawCircle(Offset(20 * s, 27 * s), 1.8 * s, fill);
        canvas.drawCircle(Offset(28 * s, 27 * s), 1.8 * s, fill);
        canvas.drawLine(Offset(20 * s, 33 * s), Offset(28 * s, 33 * s), stroke);
    }
  }

  @override
  bool shouldRepaint(_GuardianPainter old) =>
      old.khan != khan || old.colour != colour;
}
