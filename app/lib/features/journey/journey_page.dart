// صفحه‌ی هفت‌خان — درختِ مهارت.
//
// منزل‌ها روی پلکانِ رفت‌وبرگشتیِ آپادانا بالا می‌روند، نه روی خطِ عمودیِ ساده
// (بخش ۳٫۳). پس‌زمینه کنگره است که با اسکرول بسیار کند پارالاکس می‌خورد.
//
// حالت‌های یک منزل (بخش ۷٫۳):
//   قفل‌شده  — خاکستری، کدر ۰٫۴
//   باز      — نبضِ بسیار ملایم، ۱٫۰ تا ۱٫۰۲، دو ثانیه، بی‌نهایت
//   گذشته    — پر، با نشانِ خان

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings.dart';
import '../../design/emblems.dart';
import '../../design/kongere.dart';
import '../../design/tokens.g.dart';
import '../../design/widgets.dart';
import '../../shared/content_repository.dart';
import '../../shared/models.dart';
import 'progress.dart';
import 'settings_sheet.dart';

class JourneyPage extends ConsumerStatefulWidget {
  const JourneyPage({super.key});

  @override
  ConsumerState<JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends ConsumerState<JourneyPage> {
  final ScrollController _scroll = ScrollController();
  double _offset = 0;

  /// خوشامد تنها یک بار در عمرِ این صفحه فرستاده می‌شود، حتی اگر تنظیمات
  /// چند بار بازخوانی شود.
  bool _welcomed = false;

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

  void _maybeWelcome(bool? onboarded) {
    // null یعنی هنوز از دیسک نخوانده‌ایم — صبر، نه پرش.
    if (onboarded != false || _welcomed) return;
    _welcomed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.push('/welcome');
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
    _maybeWelcome(ref.watch(settingsProvider.select((s) => s.onboarded)));

    return Scaffold(
      body: Kongere(
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

class _JourneyHeader extends ConsumerWidget {
  const _JourneyHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final wallet = ref.watch(walletProvider).valueOrNull;
    final streak = ref.watch(streakProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: colors.surface,
          padding: const EdgeInsets.fromLTRB(
            SarehSpace.lg,
            SarehSpace.sm,
            SarehSpace.lg,
            SarehSpace.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'واژه‌ها منتظرند.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'تنظیمات',
                    child: IconButton(
                      icon: const Icon(Icons.tune),
                      color: colors.onSurfaceMuted,
                      onPressed: () => showSettingsSheet(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SarehSpace.xs),
              Text(
                'هفت خان، هفت قلمرو.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: SarehSpace.md),
              // شمارگان: فَرّ، زنجیره، گوهر. صفرها هم دیده می‌شوند —
              // شمارنده‌ای که پنهان شود، انگیزه‌ای هم نمی‌سازد.
              Row(
                children: [
                  _Stat(
                    icon: FarrIcon(size: SarehType.lg, colour: colors.achievement),
                    value: wallet?.farr ?? 0,
                    label: 'فَرّ',
                  ),
                  const SizedBox(width: SarehSpace.lg),
                  _Stat(
                    icon: AtashIcon(size: SarehType.lg, colour: colors.error),
                    value: streak?.currentDays ?? 0,
                    label: 'روزِ پیاپی',
                  ),
                  const SizedBox(width: SarehSpace.lg),
                  _Stat(
                    icon: GoharIcon(size: SarehType.lg, colour: colors.action),
                    value: wallet?.gohar ?? 0,
                    label: 'گوهر',
                  ),
                ],
              ),
            ],
          ),
        ),
        // سرصفحه با لبه‌ی کنگره‌دار تمام می‌شود، نه با خطِ صاف.
        KongereEdge(colour: colors.surface),
      ],
    );
  }
}

/// یک شمارگان با آیکن، شماره و نامِ کوچک.
class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final Widget icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: '$label: ${toPersianDigits(value)}',
      child: Row(
        children: [
          icon,
          const SizedBox(width: SarehSpace.xs),
          Text(
            toPersianDigits(value),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: SarehSpace.xs),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: colors.onSurfaceMuted),
          ),
        ],
      ),
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
    final height = khan.stations.length * _stationGap + SarehSpace.xl;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accentPair = SarehKhanColors.of(khan.number);
    final accent = dark ? accentPair.dark : accentPair.light;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SarehSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SarehSpace.lg),
            child: Row(
              children: [
                // نگهبانِ خان به رنگِ رنگدانه‌ی خودش — کاربر پیش از خواندنِ
                // نام می‌داند کجاست.
                GuardianEmblem(
                  khan: khan.number,
                  size: SarehSpace.xl + SarehSpace.md,
                  colour: accent,
                ),
                const SizedBox(width: SarehSpace.md),
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
                        painter: _PelekanPainter(
                          points: positions,
                          colour: accent.withValues(alpha: 0.45),
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
                          accent: accent,
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

  /// منزل‌ها یک‌درمیان چپ و راست می‌نشینند — رفت‌وبرگشتِ پلکان.
  static List<Offset> _positions(double width, int count) => [
        for (var i = 0; i < count; i++)
          Offset(
            width / 2 + (i.isEven ? -1 : 1) * width * 0.24,
            SarehSpace.lg + i * _stationGap,
          ),
      ];
}

/// پلکانِ آپادانا — مسیرِ منزل‌ها.
///
/// نه ساقه‌ی پیچان، نه خطِ راست: پلکانی رفت‌وبرگشتی، همان که در تختِ جمشید
/// از حیاط تا ایوان بالا می‌رود. سراسر زاویه‌ی قائم است، پس هم هخامنشی است و
/// هم مدرن به چشم می‌آید — برخلافِ پیچشِ گیاهی که کهنه می‌نماید.
class _PelekanPainter extends CustomPainter {
  _PelekanPainter({required this.points, required this.colour});

  final List<Offset> points;
  final Color colour;

  /// پخِ گوشه‌ها. صفر یعنی گوشه‌ی تیز؛ اندکی پخ، همان دندانه‌ی کنگره را
  /// یادآوری می‌کند بی‌آنکه مسیر را نرم و گیاهی کند.
  static const double _chamfer = 10;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final rail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.miter
      ..color = colour;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final from = points[i - 1];
      final to = points[i];
      final midY = (from.dy + to.dy) / 2;
      final towardRight = to.dx > from.dx;
      final step = towardRight ? _chamfer : -_chamfer;
      path
        // پایین آمدن تا نیمه‌ی فاصله
        ..lineTo(from.dx, midY - _chamfer)
        ..lineTo(from.dx + step, midY)
        // پاگردِ افقی
        ..lineTo(to.dx - step, midY)
        ..lineTo(to.dx, midY + _chamfer)
        // پایین آمدن تا منزلِ بعد
        ..lineTo(to.dx, to.dy);
    }
    canvas.drawPath(path, rail);

    // پله‌ها: خط‌های کوتاهِ عمود بر پاگرد، مثلِ کفِ پله‌های آپادانا.
    final tread = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = colour;
    for (var i = 1; i < points.length; i++) {
      final from = points[i - 1];
      final to = points[i];
      final midY = (from.dy + to.dy) / 2;
      final left = math.min(from.dx, to.dx) + _chamfer;
      final right = math.max(from.dx, to.dx) - _chamfer;
      const treads = 4;
      for (var t = 1; t <= treads; t++) {
        final x = left + (right - left) * t / (treads + 1);
        canvas.drawLine(Offset(x, midY - 5), Offset(x, midY + 5), tread);
      }
    }
  }

  @override
  bool shouldRepaint(_PelekanPainter old) =>
      old.points != points || old.colour != colour;
}

class _StationNode extends StatefulWidget {
  const _StationNode({
    required this.station,
    required this.index,
    required this.state,
    required this.wordCount,
    required this.accent,
  });

  static const double diameter = 72;

  final Station station;
  final int index;
  final StationState state;
  final int wordCount;

  /// رنگِ خان — منزل هم‌رنگِ قلمروِ خودش است.
  final Color accent;

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
      StationState.completed => widget.accent,
    };
    final border = switch (widget.state) {
      StationState.locked => colors.outline,
      StationState.unlocked => widget.accent,
      StationState.completed => widget.accent,
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
