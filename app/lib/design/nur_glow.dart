// هاله‌ی نور — پشتِ لحظه‌ی پایانِ منزل.
//
// با سایه‌زنِ قطعه‌ای (`shaders/nur.frag`) کشیده می‌شود، نه با انباشتِ ویجت‌های
// شفاف (بخش ۷٫۴): یک بار draw call، بی‌آنکه هر لایه دوباره ترکیب شود.
//
// اگر سایه‌زن بارگذاری نشد — سکوی قدیمی، وب بی‌WebGL — هیچ‌چیز نشان داده
// نمی‌شود. هاله تزئین است؛ نبودش نباید صفحه را بشکند یا خطایی جلوی کاربر
// بگذارد.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'tokens.g.dart';
import 'widgets.dart';

class NurGlow extends StatefulWidget {
  const NurGlow({super.key, this.colour, this.size = const Size(280, 280)});

  /// اگر ندهید، زرِ فَرّ برداشته می‌شود — هاله تنها برای لحظه‌ی دستاورد است.
  final Color? colour;
  final Size size;

  @override
  State<NurGlow> createState() => _NurGlowState();
}

class _NurGlowState extends State<NurGlow> with SingleTickerProviderStateMixin {
  static Future<ui.FragmentProgram>? _programFuture;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SarehMotion.celebration,
  );

  @override
  void initState() {
    super.initState();
    // برنامه یک بار برای کلِ اپ بارگذاری می‌شود، نه به‌ازای هر جشن.
    _programFuture ??= ui.FragmentProgram.fromAsset('shaders/nur.frag');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.of(context).disableAnimations && !_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return const SizedBox.shrink();

    final colour = widget.colour ?? context.colors.achievement;
    return IgnorePointer(
      child: FutureBuilder<ui.FragmentProgram>(
        future: _programFuture,
        builder: (context, snapshot) {
          final program = snapshot.data;
          if (program == null) return SizedBox.fromSize(size: widget.size);
          return RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                size: widget.size,
                painter: _GlowPainter(
                  shader: program.fragmentShader(),
                  progress: _controller.value,
                  colour: colour,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({
    required this.shader,
    required this.progress,
    required this.colour,
  });

  final ui.FragmentShader shader;
  final double progress;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    // ترتیب باید دقیقاً با ترتیبِ uniformها در nur.frag یکی باشد:
    // uSize (۰،۱) · uProgress (۲) · uColour (۳..۶)
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, progress)
      ..setFloat(3, colour.r)
      ..setFloat(4, colour.g)
      ..setFloat(5, colour.b)
      ..setFloat(6, colour.a);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.progress != progress || old.colour != colour;
}
