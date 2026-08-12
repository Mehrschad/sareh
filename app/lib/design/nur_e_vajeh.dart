// «نورِ واژه» — عنصرِ امضای سره (بخش ۳٫۵).
//
// وقتی کاربر پاسخِ درست می‌دهد، واژه‌ی سره با قلمِ نستعلیق ظاهر می‌شود و یک
// رشته‌ی نور دقیقاً مسیرِ قلم را — از سرِ حرف تا پایانِ کشیده‌گی — در ۶۰۰
// میلی‌ثانیه می‌پیماید، انگار خطاط همان لحظه نوشته باشد.
//
// این تنها جایی است که ولخرجیِ بصری مجاز است. باقیِ رابط ساکت و منضبط می‌ماند.
//
// دو حالت:
//
//   ۱. **ردیابی** — وقتی مسیرِ خوشنویسیِ واژه را داریم. `PathMetric` طولِ مسیر
//      را می‌دهد و رشته‌ی نور روی آن حرکت می‌کند. واژه پشتِ سرِ نور نوشته
//      می‌شود، نه پیش از آن.
//   ۲. **پشتیبان** — وقتی مسیر نداریم. واژه با همان قلم نوشته می‌شود و یک
//      درخششِ باریک از راست به چپ (جهتِ نوشتنِ فارسی) از رویش می‌گذرد.
//      کم‌جان‌تر است، ولی هرگز چیزی نمایش داده نمی‌شود که خطاط نمی‌نوشت.
//
// در حالتِ «بدون حرکت» هر دو حالت واژه را یک‌باره و کامل نشان می‌دهند. هیچ
// کارکردی از دست نمی‌رود (بخش ۷٫۴).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'tokens.g.dart';

/// مسیرهای خوشنویسیِ از پیش محاسبه‌شده.
///
/// استخراج مسیر از قلم گران است؛ برای واژه‌های پرتکرار یک بار حساب و کش
/// می‌شود (بخش ۳٫۵).
class WordPathCache {
  WordPathCache._();
  static final WordPathCache instance = WordPathCache._();

  final Map<String, Path> _paths = {};

  Path? operator [](String wordId) => _paths[wordId];

  void put(String wordId, Path path) => _paths[wordId] = path;

  bool contains(String wordId) => _paths.containsKey(wordId);

  void clear() => _paths.clear();
}

class NureVajeh extends StatefulWidget {
  const NureVajeh({
    super.key,
    required this.word,
    this.calligraphy,
    this.fontSize = SarehType.h2,
    this.onComplete,
  });

  /// واژه‌ی سره — همان که رونمایی می‌شود.
  final String word;

  /// مسیرِ قلمِ واژه در دستگاهِ مختصاتِ خودش. اگر null باشد حالتِ پشتیبان.
  final Path? calligraphy;

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
                if (widget.calligraphy case final path?)
                  _TraceView(
                    path: path,
                    progress: progress,
                    ink: colors.onSurface,
                    glow: colors.accentSoft,
                    fontSize: widget.fontSize,
                  )
                else
                  _SweepView(
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

/// حالتِ ردیابی — نور روی مسیرِ واقعیِ قلم.
class _TraceView extends StatelessWidget {
  const _TraceView({
    required this.path,
    required this.progress,
    required this.ink,
    required this.glow,
    required this.fontSize,
  });

  final Path path;
  final double progress;
  final Color ink;
  final Color glow;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final bounds = path.getBounds();
    final aspect = bounds.height == 0 ? 1.0 : bounds.width / bounds.height;
    return SizedBox(
      height: fontSize * 1.6,
      width: fontSize * 1.6 * aspect,
      child: CustomPaint(
        painter: _TracePainter(path: path, progress: progress, ink: ink, glow: glow),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter({
    required this.path,
    required this.progress,
    required this.ink,
    required this.glow,
  });

  final Path path;
  final double progress;
  final Color ink;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = path.getBounds();
    if (bounds.isEmpty) return;

    // مسیر را در فضای ویجت جا می‌دهیم بی‌آنکه نسبتش را به‌هم بزنیم.
    final scale = math.min(size.width / bounds.width, size.height / bounds.height);
    canvas.save();
    canvas.translate(
      (size.width - bounds.width * scale) / 2 - bounds.left * scale,
      (size.height - bounds.height * scale) / 2 - bounds.top * scale,
    );
    canvas.scale(scale);

    final inkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = SarehSignature.strokeWidth / scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (SarehSignature.strokeWidth * 1.6) / scale
      ..strokeCap = StrokeCap.round
      ..color = glow
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, SarehSignature.glowSigma / scale);

    for (final metric in path.computeMetrics()) {
      final length = metric.length;
      if (length == 0) continue;
      final head = length * progress;
      final tail = math.max(0.0, head - length * SarehSignature.trailFraction);

      // مرکّبِ نوشته‌شده: هرچه نور از آن گذشته است.
      canvas.drawPath(metric.extractPath(0, head), inkPaint);
      // رشته‌ی نور: تنها سرِ قلم.
      if (head > tail) {
        canvas.drawPath(metric.extractPath(tail, head), glowPaint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TracePainter old) =>
      old.progress != progress || old.path != path || old.ink != ink || old.glow != glow;
}

/// حالتِ پشتیبان — درخششی که از راست به چپ، هم‌جهتِ نوشتنِ فارسی، می‌گذرد.
class _SweepView extends StatelessWidget {
  const _SweepView({
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
        color: ink,
      ),
    );

    if (progress >= 1.0) return text;

    // لبه‌ی روشن جلو می‌رود و هرچه پشتِ سرش می‌ماند، نوشته شده است.
    final edge = progress;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (rect) => ui.Gradient.linear(
        rect.centerRight,
        rect.centerLeft,
        [ink, ink, glow, Colors.transparent],
        [
          0.0,
          math.max(0.0, edge - SarehSignature.trailFraction),
          edge,
          math.min(1.0, edge + 0.02),
        ],
      ),
      child: text,
    );
  }
}

/// سه ذره‌ی زر که در ۴۰۰ میلی‌ثانیه از واژه بلند می‌شوند و محو می‌شوند.
///
/// زر تنها برای لحظه‌های دستاورد است؛ اگر همه‌جا باشد دیگر دستاورد نیست.
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
