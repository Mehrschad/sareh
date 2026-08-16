// کنگره — بافتِ پس‌زمینه و لبه‌ی سرصفحه (بخش ۳٫۳).
//
// نقشِ پایه، کنگره‌ی تختِ جمشید است: همان دندانه‌ی پلکانی که بالای دیوارها و
// درگاه‌های هخامنشی نشسته. چرا این و نه گره‌چینی: گره‌چینی و شمسه و مقرنس
// هنرِ دورانِ اسلامی‌اند. سره از ایرانِ پیش از آن می‌آید، و کنگره کهن‌ترین
// نشانِ معماریِ ایرانی است که هنوز مدرن به چشم می‌آید — چون سراسر خطِ راست و
// زاویه‌ی قائم است، نه پیچ‌وخمِ اسلیمی.
//
// با `CustomPainter` کشیده می‌شود، نه به‌صورت تصویر: در هر چگالیِ پیکسلی تیز
// می‌ماند، حجمِ بسته را بالا نمی‌برد، و رنگش از توکن‌ها می‌آید. کدری میان
// ۰٫۰۴ تا ۰٫۰۹ — اگر خوانده شود، بلندتر از آن است که باید.
//
// با اسکرول، بسیار کند پارالاکس می‌خورد. در حالتِ «بدون حرکت» پارالاکس خاموش
// است ولی بافت می‌ماند؛ بافت تزئین است، حرکتش نه.

import 'package:flutter/material.dart';

import 'tokens.g.dart';

class Kongere extends StatelessWidget {
  const Kongere({
    super.key,
    required this.colour,
    this.scrollOffset = 0,
    this.tile = 96,
    this.opacity = SarehOpacity.kongereMax,
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
      painter: _KongerePainter(
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

/// دندانه‌ی پلکانی — سه پله بالا، یک تختِ کوتاه، سه پله پایین.
///
/// بیرون از کلاس است تا [KongereEdge] هم از همان هندسه بهره ببرد؛ یک شکل،
/// دو کاربرد.
Path merlonPath({
  required double width,
  required double height,
  int steps = 3,
  double plateauRatio = 0.24,
}) {
  final inset = width * (1 - plateauRatio) / 2 / steps;
  final rise = height / steps;
  final path = Path()..moveTo(0, height);
  // بالا رفتن: هر پله یک ایستاده و یک خوابیده.
  for (var k = 0; k < steps; k++) {
    path
      ..lineTo(k * inset, height - (k + 1) * rise)
      ..lineTo((k + 1) * inset, height - (k + 1) * rise);
  }
  // پایین آمدن: آینه‌ی همان، وارونه پیموده. نخستین پاره، تختِ بالاست.
  for (var k = steps - 1; k >= 0; k--) {
    path
      ..lineTo(width - (k + 1) * inset, height - (k + 1) * rise)
      ..lineTo(width - k * inset, height - (k + 1) * rise);
  }
  return path..lineTo(width, height);
}

class _KongerePainter extends CustomPainter {
  _KongerePainter({
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
      ..strokeJoin = StrokeJoin.miter
      ..color = colour;

    final width = tile * 0.66;
    final merlon = merlonPath(width: width, height: tile * 0.52);
    final margin = (tile - width) / 2;

    // شروع از یک ردیف بالاتر تا هنگامِ پارالاکس، لبه خالی نماند.
    final shift = offset % tile;
    var row = 0;
    for (double y = -tile + shift; y < size.height + tile; y += tile) {
      // ردیف‌ها نیم‌خشت جابه‌جا می‌شوند، مثلِ رجِ آجر — وگرنه شبکه‌ی
      // مستطیلی می‌شود و چشم آن را «کاغذِ شطرنجی» می‌خواند.
      final stagger = row.isEven ? 0.0 : tile / 2;
      for (double x = -tile; x < size.width + tile; x += tile) {
        canvas.save();
        canvas.translate(x + margin + stagger, y);
        canvas.drawPath(merlon, paint);
        canvas.restore();
      }
      // خطِ جرزِ دیوار که دندانه‌ها روی آن نشسته‌اند.
      canvas.drawLine(
        Offset(0, y + tile * 0.52),
        Offset(size.width, y + tile * 0.52),
        paint,
      );
      row++;
    }
  }

  @override
  bool shouldRepaint(_KongerePainter old) =>
      old.colour != colour || old.offset != offset || old.tile != tile;
}

/// لبه‌ی کنگره‌دارِ پایانِ سرصفحه (بخش ۳٫۳).
///
/// سرصفحه‌ها با خطِ صاف تمام نمی‌شوند؛ با ردیفی از دندانه‌ی هخامنشی تمام
/// می‌شوند. همه‌اش خطِ راست است — همان چیزی که این نقش را مدرن نگه می‌دارد.
class KongereEdge extends StatelessWidget {
  const KongereEdge({
    super.key,
    required this.colour,
    this.height = 18,
    this.teeth = 9,
  });

  final Color colour;
  final double height;
  final int teeth;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(double.infinity, height),
        painter: _KongereEdgePainter(colour: colour, teeth: teeth),
      );
}

class _KongereEdgePainter extends CustomPainter {
  _KongereEdgePainter({required this.colour, required this.teeth});

  final Color colour;
  final int teeth;

  @override
  void paint(Canvas canvas, Size size) {
    if (teeth <= 0) return;
    final width = size.width / teeth;
    final tooth = merlonPath(width: width, height: size.height, steps: 2);
    final path = Path();
    for (var i = 0; i < teeth; i++) {
      path.addPath(tooth, Offset(i * width, 0));
    }
    // بالای دندانه‌ها را می‌بندد تا سرصفحه یک‌پارچه پر شود.
    path
      ..lineTo(size.width, -1)
      ..lineTo(0, -1)
      ..close();
    canvas.drawPath(path, Paint()..color = colour);
  }

  @override
  bool shouldRepaint(_KongereEdgePainter old) =>
      old.colour != colour || old.teeth != teeth;
}
