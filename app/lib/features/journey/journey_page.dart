// صفحه‌ی هفت‌خان — درختِ مهارت.
//
// منزل‌ها روی یک مسیرِ اسلیمیِ پیچان بالا می‌روند، نه روی خطِ عمودیِ ساده
// (بخش ۳٫۳). پس‌زمینه گره‌چینی است که با اسکرول بسیار کند پارالاکس می‌خورد.
//
// حالت‌های یک منزل (بخش ۷٫۳):
//   قفل‌شده  — خاکستری، کدر ۰٫۴
//   باز      — نبضِ بسیار ملایم، ۱٫۰ تا ۱٫۰۲، دو ثانیه، بی‌نهایت
//   گذشته    — پر، با نشانِ خان

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design/gerehchini.dart';
import '../../design/tokens.g.dart';
import '../../design/widgets.dart';
import '../../shared/content_repository.dart';
import '../../shared/models.dart';
import 'progress.dart';

class JourneyPage extends ConsumerStatefulWidget {
  const JourneyPage({super.key});

  @override
  ConsumerState<JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends ConsumerState<JourneyPage> {
  final ScrollController _scroll = ScrollController();
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      // پارالاکس تنها به بازترسیمِ بافت نیاز دارد، نه به چیدمانِ دوباره.
      if ((_scroll.offset - _offset).abs() > 1) {
        setState(() => _offset = _scroll.offset);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = ref.watch(contentProvider);
    final progress = ref.watch(progressProvider);

    return Scaffold(
      body: Gerehchini(
        colour: colors.onBackground,
        scrollOffset: _offset,
        child: SafeArea(
          child: content.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => SarehEmpty(
              message: 'محتوا خوانده نشد.\n$error',
            ),
            data: (bundle) {
              if (bundle.khans.isEmpty) {
                return const SarehEmpty(
                  message: 'هنوز خانی ساخته نشده. از content/lessons آغاز کن.',
                );
              }
              return CustomScrollView(
                controller: _scroll,
                slivers: [
                  const SliverToBoxAdapter(child: _JourneyHeader()),
                  for (final khan in bundle.khans)
                    SliverToBoxAdapter(
                      child: _KhanSection(
                        khan: khan,
                        bundle: bundle,
                        progress: progress,
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: SarehSpace.xxl),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: colors.surface,
          padding: const EdgeInsets.fromLTRB(
            SarehSpace.lg,
            SarehSpace.lg,
            SarehSpace.lg,
            SarehSpace.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('واژه‌ها منتظرند.', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: SarehSpace.xs),
              Text(
                'هفت خان، هفت قلمرو.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        // سرصفحه با لبه‌ی مقرنس‌وار تمام می‌شود، نه با خطِ صاف.
        MoqarnasEdge(colour: colors.surface),
      ],
    );
  }
}

class _KhanSection extends StatelessWidget {
  const _KhanSection({
    required this.khan,
    required this.bundle,
    required this.progress,
  });

  final Khan khan;
  final ContentBundle bundle;
  final JourneyProgress progress;

  /// فاصله‌ی عمودیِ دو منزل روی مسیر.
  static const double _stationGap = 132;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final height = khan.stations.length * _stationGap + SarehSpace.xl;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SarehSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SarehSpace.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(khan.title, style: Theme.of(context).textTheme.titleLarge),
                      Text(khan.realm, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                Text(
                  '${toPersianDigits(progress.completedIn(khan))}'
                  '/${toPersianDigits(khan.stations.length)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: SarehSpace.md),
          SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final positions = _positions(constraints.maxWidth, khan.stations.length);
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _EslimiPainter(
                          points: positions,
                          colour: colors.action.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    for (var i = 0; i < khan.stations.length; i++)
                      Positioned(
                        left: positions[i].dx - _StationNode.diameter / 2,
                        top: positions[i].dy - _StationNode.diameter / 2,
                        child: _StationNode(
                          station: khan.stations[i],
                          index: i,
                          state: progress.stateOf(khan, i),
                          wordCount: bundle.wordsOf(khan.stations[i]).length,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// منزل‌ها روی یک موجِ آرام می‌نشینند — همان پیچشی که مسیر اسلیمی می‌گیرد.
  static List<Offset> _positions(double width, int count) => [
        for (var i = 0; i < count; i++)
          Offset(
            width / 2 + math.sin(i * 0.9) * width * 0.26,
            SarehSpace.lg + i * _stationGap,
          ),
      ];
}

/// مسیرِ اسلیمی — نه خطِ راست، نه زیگزاگ؛ یک ساقه‌ی پیچانِ گیاهی.
class _EslimiPainter extends CustomPainter {
  _EslimiPainter({required this.points, required this.colour});

  final List<Offset> points;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final stem = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = colour;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final from = points[i - 1];
      final to = points[i];
      // مهارها را افقی می‌گیریم تا پیچش نرم و گیاهی بماند، نه مکانیکی.
      final sway = (to.dx - from.dx).abs() * 0.6 + 24;
      path.cubicTo(
        from.dx + (to.dx > from.dx ? sway : -sway),
        from.dy + (to.dy - from.dy) * 0.35,
        to.dx + (to.dx > from.dx ? -sway : sway),
        to.dy - (to.dy - from.dy) * 0.35,
        to.dx,
        to.dy,
      );
    }
    canvas.drawPath(path, stem);

    // برگ‌های اسلیمی: قلاب‌های کوچکی که از ساقه می‌رویند.
    final leaf = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = colour;
    for (final metric in path.computeMetrics()) {
      for (var t = 0.18; t < 1.0; t += 0.22) {
        final tangent = metric.getTangentForOffset(metric.length * t);
        if (tangent == null) continue;
        final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
        final base = tangent.position;
        final tip = base + normal * 16;
        canvas.drawPath(
          Path()
            ..moveTo(base.dx, base.dy)
            ..quadraticBezierTo(
              base.dx + normal.dx * 12 + tangent.vector.dx * 10,
              base.dy + normal.dy * 12 + tangent.vector.dy * 10,
              tip.dx,
              tip.dy,
            ),
          leaf,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_EslimiPainter old) => old.points != points || old.colour != colour;
}

class _StationNode extends StatefulWidget {
  const _StationNode({
    required this.station,
    required this.index,
    required this.state,
    required this.wordCount,
  });

  static const double diameter = 72;

  final Station station;
  final int index;
  final StationState state;
  final int wordCount;

  @override
  State<_StationNode> createState() => _StationNodeState();
}

class _StationNodeState extends State<_StationNode> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldPulse =
        widget.state == StationState.unlocked && !MediaQuery.of(context).disableAnimations;
    if (shouldPulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!shouldPulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locked = widget.state == StationState.locked;
    final done = widget.state == StationState.completed;

    final fill = switch (widget.state) {
      StationState.locked => colors.surface,
      StationState.unlocked => colors.surface,
      StationState.completed => colors.action,
    };
    final border = switch (widget.state) {
      StationState.locked => colors.outline,
      StationState.unlocked => colors.action,
      StationState.completed => colors.action,
    };

    final node = Container(
      width: _StationNode.diameter,
      height: _StationNode.diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: done ? 2 : 1.5),
      ),
      child: Text(
        toPersianDigits(widget.index + 1),
        style: TextStyle(
          fontFamily: SarehType.bodyFamily,
          fontSize: SarehType.lg,
          height: SarehType.lgLine,
          fontWeight: FontWeight.w600,
          color: done ? colors.onAction : colors.onSurface,
        ),
      ),
    );

    return Semantics(
      button: !locked,
      label: locked
          ? '${widget.station.title} — هنوز باز نشده'
          : '${widget.station.title}، ${toPersianDigits(widget.wordCount)} واژه',
      child: Opacity(
        opacity: locked ? SarehOpacity.lockedStation : 1.0,
        child: GestureDetector(
          onTap: locked ? null : () => context.push('/lesson/${widget.station.id}'),
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Transform.scale(
              // نبضِ بسیار ملایم — اگر دیده شود، بلند است.
              scale: 1.0 + _pulse.value * 0.02,
              child: child,
            ),
            child: node,
          ),
        ),
      ),
    );
  }
}
