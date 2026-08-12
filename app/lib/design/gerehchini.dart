// گره‌چینی — بافتِ پس‌زمینه (بخش ۳٫۳).
//
// ستاره‌ی هشت‌پر (شمسه) با `CustomPainter` کشیده می‌شود، نه به‌صورت تصویر: در
// هر چگالیِ پیکسلی تیز می‌ماند، حجمِ بسته را بالا نمی‌برد، و رنگش از توکن‌ها
// می‌آید. کدری میان ۰٫۰۳ تا ۰٫۰۶ — اگر دیده شود، بلندتر از آن است که باید.
//
// با اسکرول، بسیار کند پارالاکس می‌خورد. در حالتِ «بدون حرکت» پارالاکس خاموش
// است ولی بافت می‌ماند؛ بافت تزئین است، حرکتش نه.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.g.dart';

class Gerehchini extends StatelessWidget {
  const Gerehchini({
    super.key,
    required this.colour,
    this.scrollOffset = 0,
    this.tile = 96,
    this.opacity = SarehOpacity.gerehchiniMax,
    this.child,
  });

  final Color colour;

  /// جابه‌جاییِ اسکرول. پارالاکس یک‌دهمِ آن حرکت می‌کند — تقریباً نامحسوس.
  final double scrollOffset;

  final double tile;
  final double opacity;
  final Widget? child;

  static const double _parallaxFactor = 0.1;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;
    return CustomPaint(
      painter: _GerehchiniPainter(
        colour: colour.withValues(alpha: opacity),
        offset: reduced ? 0 : scrollOffset * _parallaxFactor,
        tile: tile,
      ),
      isComplex: true,
      willChange: !reduced,
      child: child,
    );
  }
}

class _GerehchiniPainter extends CustomPainter {
  _GerehchiniPainter({
    required this.colour,
    required this.offset,
    required this.tile,
  });

  final Color colour;
  final double offset;
  final double tile;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = colour;

    final star = _shamse(tile);
    // شروع از یک ردیف بالاتر تا هنگامِ پارالاکس، لبه خالی نماند.
    final shift = offset % tile;
    for (double y = -tile + shift; y < size.height + tile; y += tile) {
      for (double x = -tile; x < size.width + tile; x += tile) {
        canvas.save();
        canvas.translate(x, y);
        canvas.drawPath(star, paint);
        canvas.restore();
      }
    }
  }

  /// شمسه — ستاره‌ی هشت‌پر: دو مربعِ هم‌مرکز با چرخشِ ۴۵ درجه، به‌صورتِ یک
  /// چندضلعیِ پیوسته با هشت رأسِ بیرونی و هشت رأسِ درونی.
  static Path _shamse(double tile) {
    final centre = Offset(tile / 2, tile / 2);
    final outer = tile * 0.42;
    final inner = outer * 0.55;
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = math.pi * i / 8 - math.pi / 2;
      final point = Offset(
        centre.dx + radius * math.cos(angle),
        centre.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    // بندهای گره‌چینی: خطوطی که ستاره‌ها را به هم می‌دوزند.
    path
      ..moveTo(0, tile / 2)
      ..lineTo(centre.dx - outer, tile / 2)
      ..moveTo(centre.dx + outer, tile / 2)
      ..lineTo(tile, tile / 2)
      ..moveTo(tile / 2, 0)
      ..lineTo(tile / 2, centre.dy - outer)
      ..moveTo(tile / 2, centre.dy + outer)
      ..lineTo(tile / 2, tile);
    return path;
  }

  @override
  bool shouldRepaint(_GerehchiniPainter old) =>
      old.colour != colour || old.offset != offset || old.tile != tile;
}

/// مقرنس — لبه‌ی پلکانیِ نرمِ پایانِ سرصفحه (بخش ۳٫۳).
///
/// سرصفحه‌ها با خطِ صاف تمام نمی‌شوند. هر پله یک نیم‌کمان است، مثلِ رجِ
/// مقرنسِ زیرِ گنبد.
class MoqarnasEdge extends StatelessWidget {
  const MoqarnasEdge({
    super.key,
    required this.colour,
    this.height = 18,
    this.steps = 9,
  });

  final Color colour;
  final double height;
  final int steps;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(double.infinity, height),
        painter: _MoqarnasPainter(colour: colour, steps: steps),
      );
}

class _MoqarnasPainter extends CustomPainter {
  _MoqarnasPainter({required this.colour, required this.steps});

  final Color colour;
  final int steps;

  @override
  void paint(Canvas canvas, Size size) {
    if (steps <= 0) return;
    final width = size.width / steps;
    final path = Path()..moveTo(0, 0);
    for (var i = 0; i < steps; i++) {
      final left = i * width;
      // هر رج یک نیم‌کمانِ رو به پایین.
      path.arcToPoint(
        Offset(left + width, 0),
        radius: Radius.elliptical(width / 2, size.height),
        clockwise: false,
      );
    }
    path
      ..lineTo(size.width, -1)
      ..lineTo(0, -1)
      ..close();
    canvas.drawPath(path, Paint()..color = colour);
  }

  @override
  bool shouldRepaint(_MoqarnasPainter old) => old.colour != colour || old.steps != steps;
}
