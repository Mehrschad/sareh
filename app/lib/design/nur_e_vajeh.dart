// «نورِ واژه» — عنصرِ امضای سره (بخش ۳٫۵).
//
// وقتی کاربر پاسخِ درست می‌دهد، واژه‌ی سره با قلمِ نمایشیِ هندسی ظاهر می‌شود و
// یک رشته‌ی نور از **راست به چپ** — جهتِ نوشتنِ فارسی — در ۶۰۰ میلی‌ثانیه از
// رویش می‌گذرد. پیشِ رشته، حرف‌ها خاموش‌اند؛ پشتِ سرش روشن و درخشان.
// مثلِ تابلوی نئون که بند‌بند روشن می‌شود.
//
// چرا این و نه ردیابیِ نستعلیق: طرحِ نخست، مسیرِ قلمِ خطاط را می‌پیمود. زیبا
// بود ولی دو ایراد داشت — به داده‌ی خوشنویسیِ دستیِ هر واژه نیاز داشت که
// هرگز ساخته نشد، و لحنش کهنه بود. سره برای کسی است که امروز فارسی حرف
// می‌زند، نه برای قابِ روی دیوار. حرکتِ نور همان است؛ آنچه نور رویش می‌رود
// عوض شده.
//
// جهتِ راست‌به‌چپ خودش امضاست: هیچ اپِ انگلیسی‌زبانی این حرکت را ندارد.
//
// در حالتِ «بدون حرکت» واژه یک‌باره و کامل و روشن نمایش داده می‌شود. هیچ
// کارکردی از دست نمی‌رود (بخش ۷٫۴).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'tokens.g.dart';

class NureVajeh extends StatefulWidget {
  const NureVajeh({
    super.key,
    required this.word,
    this.fontSize = SarehType.h2,
    this.onComplete,
  });

  /// واژه‌ی سره — همان که رونمایی می‌شود.
  final String word;

  final double fontSize;

  /// پس از پایانِ انیمیشن صدا زده می‌شود. انیمیشن هرگز تعامل را بلوکه نمی‌کند؛
  /// این تنها برای زنجیره‌کردنِ جشن است.
  final VoidCallback? onComplete;

  @override
  State<NureVajeh> createState() => _NureVajehState();
}

class _NureVajehState extends State<NureVajeh> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SarehSignature.duration,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete?.call();
    });

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      // بدونِ حرکت: واژه همان‌جا کامل است.
      _controller.value = 1.0;
      widget.onComplete?.call();
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant NureVajeh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word != widget.word && !MediaQuery.of(context).disableAnimations) {
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
    final colors = Theme.of(context).extension<SarehTheme>()!.colors;
    final reduced = MediaQuery.of(context).disableAnimations;

    return Semantics(
      // صفحه‌خوان واژه را می‌خواند، نه انیمیشن را.
      label: widget.word,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                _Filament(
                  word: widget.word,
                  progress: progress,
                  ink: colors.onSurface,
                  glow: colors.accentSoft,
                  fontSize: widget.fontSize,
                ),
                if (!reduced)
                  _GoldParticles(
                    progress: progress,
                    colour: colors.achievement,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// رشته‌ی نور — واژه‌ای که از راست به چپ روشن می‌شود.
///
/// سه لایه روی هم: هاله‌ی محو در پس، حرف‌ها در میان، و تکِ نورِ پیش‌رونده در
/// پیش. هر سه با یک شیب‌رنگِ مشترک برش می‌خورند، پس هیچ‌وقت از هم جدا
/// نمی‌افتند.
class _Filament extends StatelessWidget {
  const _Filament({
    required this.word,
    required this.progress,
    required this.ink,
    required this.glow,
    required this.fontSize,
  });

  final String word;
  final double progress;
  final Color ink;
  final Color glow;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      word,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: SarehType.displayFamily,
        fontSize: fontSize,
        height: SarehType.h2Line,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    );

    if (progress >= 1.0) return text;

    // ۰ = لبه‌ی راست، ۱ = لبه‌ی چپ. نور از سرِ واژه می‌آید.
    //
    // حرف‌های روشن‌نشده ناپیدا نیستند، کم‌رنگ‌اند (`unlitAlpha`) — لوله‌ی
    // نئونِ بی‌برق. اگر ناپیدا باشند، واژه «تایپ» می‌شود نه «روشن».
    ui.Gradient sweep(Rect rect, Color lit, Color front, Color unlit) =>
        ui.Gradient.linear(
          rect.centerRight,
          rect.centerLeft,
          [lit, lit, front, unlit, unlit],
          [
            0.0,
            math.max(0.0, progress - SarehSignature.trailFraction),
            progress,
            math.min(1.0, progress + SarehSignature.frontSharpness),
            1.0,
          ],
        );

    return Stack(
      alignment: Alignment.center,
      children: [
        // هاله: همان واژه، محو و به رنگِ نور. تنها پشتِ سرِ رشته دیده می‌شود.
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: SarehSignature.glowSigma,
            sigmaY: SarehSignature.glowSigma,
          ),
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (rect) => sweep(
              rect,
              glow.withValues(alpha: SarehSignature.haloAlpha),
              glow,
              Colors.transparent,
            ),
            child: text,
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => sweep(
            rect,
            ink,
            glow,
            ink.withValues(alpha: SarehSignature.unlitAlpha),
          ),
          child: text,
        ),
        // تکِ نور: باریکه‌ای که جلو می‌رود. همان چیزی که چشم دنبالش می‌کند.
        Positioned.fill(
          child: CustomPaint(
            painter: _FrontPainter(progress: progress, colour: glow),
          ),
        ),
      ],
    );
  }
}

class _FrontPainter extends CustomPainter {
  _FrontPainter({required this.progress, required this.colour});

  final double progress;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * (1 - progress);
    final paint = Paint()
      ..color = colour
      ..strokeWidth = SarehSignature.strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        SarehSignature.glowSigma / 2,
      );
    canvas.drawLine(
      Offset(x, size.height * 0.12),
      Offset(x, size.height * 0.88),
      paint,
    );
  }

  @override
  bool shouldRepaint(_FrontPainter old) =>
      old.progress != progress || old.colour != colour;
}

class _GoldParticles extends StatelessWidget {
  const _GoldParticles({required this.progress, required this.colour});

  final double progress;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final start = SarehSignature.particleAt.inMilliseconds /
        SarehSignature.duration.inMilliseconds;
    if (progress < start) return const SizedBox.shrink();

    final local = ((progress - start) / (1 - start)).clamp(0.0, 1.0);
    return IgnorePointer(
      child: CustomPaint(
        size: Size(SarehSignature.particleRise * 3, SarehSignature.particleRise * 2),
        painter: _ParticlePainter(progress: local, colour: colour),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.progress, required this.colour});

  final double progress;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = colour.withValues(alpha: 1 - progress);
    for (var i = 0; i < SarehSignature.particleCount; i++) {
      // پخشِ ثابت و بی‌تصادف، تا هر بار یکسان دیده شود.
      final offset = (i - (SarehSignature.particleCount - 1) / 2) / SarehSignature.particleCount;
      final drift = math.sin(progress * math.pi + i) * 4;
      final centre = Offset(
        size.width / 2 + offset * size.width * 0.6 + drift,
        size.height / 2 - SarehSignature.particleRise * progress,
      );
      canvas.drawCircle(centre, 2.0 * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress || old.colour != colour;
}

/// افزونه‌ی تمِ سره — رنگ‌ها را بی‌واسطه از توکن‌ها به ویجت‌ها می‌رساند.
///
/// اینجا تعریف شده تا `nur_e_vajeh` به هیچ ویجتِ دیگری وابسته نباشد؛
/// `core/theme.dart` آن را می‌سازد.
@immutable
class SarehTheme extends ThemeExtension<SarehTheme> {
  const SarehTheme({required this.colors, required this.symbolPack});

  final SarehColors colors;

  /// بسته‌ی نمادِ برگزیده (بخش ۳٫۴) — «اسطوره» پیش‌فرض است.
  final String symbolPack;

  @override
  SarehTheme copyWith({SarehColors? colors, String? symbolPack}) => SarehTheme(
        colors: colors ?? this.colors,
        symbolPack: symbolPack ?? this.symbolPack,
      );

  @override
  SarehTheme lerp(SarehTheme? other, double t) => t < 0.5 ? this : (other ?? this);
}
