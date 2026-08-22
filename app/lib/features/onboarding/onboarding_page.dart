// خوشامد — نخستین دیدار با سره.
//
// چهار پرده: سیمرغ خودش را می‌شناساند، «چرا» گفته می‌شود، هفت‌خان نشان
// داده می‌شود، و «نورِ واژه» یک بار جلوی چشم اجرا می‌شود — چون امضای
// محصول را باید دید، نه خواند.
//
// قاعده‌ها: رد شدن همیشه ممکن است (دکمه‌ی «بگذر» از پرده‌ی نخست هست)؛
// در حالتِ بی‌حرکت هیچ پرده‌ای انیمیشن ندارد و همه‌چیز یک‌باره می‌نشیند؛
// و این صفحه تنها یک بار خودش را نشان می‌دهد — پرچمش در تنظیمات می‌ماند.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings.dart';
import '../../design/emblems.dart';
import '../../design/kongere.dart';
import '../../design/nur_e_vajeh.dart';
import '../../design/tokens.g.dart';
import '../../design/widgets.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pages = PageController();
  int _page = 0;

  static const int _pageCount = 4;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(settingsProvider.notifier).markOnboarded();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _next() {
    if (_page >= _pageCount - 1) {
      _finish();
      return;
    }
    _pages.nextPage(
      duration: SarehMotion.page,
      curve: SarehMotion.pageCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final still = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      body: Kongere(
        colour: colors.onBackground,
        child: SafeArea(
          child: Column(
            children: [
              // «بگذر» از همان پرده‌ی نخست — هیچ‌کس به تماشا وادار نمی‌شود.
              Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: const EdgeInsets.all(SarehSpace.sm),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      'بگذر',
                      style: TextStyle(color: colors.onSurfaceMuted),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: [
                    _Parde(
                      still: still,
                      art: SimorghEmblem(size: 180, colour: colors.action),
                      title: 'درود! من سیمرغم.',
                      body: 'همان که زال را پرورد و رستم را راه نمود. '
                          'این بار همراهِ توام — تا واژه‌هایی را که فارسی '
                          'از یاد برده، با هم پس بگیریم.',
                    ),
                    _Parde(
                      still: still,
                      art: _WordSwap(still: still),
                      title: 'زبانت برابر دارد.',
                      body: '«سخن» به‌جای «حرف»، «بها» به‌جای «قیمت». '
                          'هیچ واژه‌ای را ما نساخته‌ایم — هر برابر در '
                          'دهخدا، معین، عمید یا فرهنگستان مدخل دارد.',
                    ),
                    _Parde(
                      still: still,
                      art: _KhanRow(still: still),
                      title: 'هفت خان در پیش است.',
                      body: 'هفت قلمرو، هفت نگهبان، هر یک به رنگی از '
                          'رنگدانه‌های کهنِ ایران. پاسخِ درست فَرّ می‌آورد '
                          'و منزلِ بی‌لغزش، گوهر.',
                    ),
                    _Parde(
                      still: still,
                      art: const _NurDemo(),
                      title: 'و این، نورِ واژه است.',
                      body: 'هر پاسخِ درست، واژه را از راست به چپ روشن '
                          'می‌کند — همان سویی که می‌نویسی.',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(SarehSpace.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // نشانگرِ صفحه، گلِ دوازده‌پرِ آپادانا — صفحه‌ی
                        // کنونی باز و روشن، بقیه کوچک و کم‌رنگ.
                        for (var i = 0; i < _pageCount; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SarehSpace.xs,
                            ),
                            child: PersepolisRosette(
                              size: i == _page ? SarehSpace.lg : SarehSpace.md,
                              colour:
                                  i == _page ? colors.action : colors.outline,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: SarehSpace.lg),
                    SarehButton(
                      label: _page >= _pageCount - 1 ? 'آغاز کن' : 'پیش برو',
                      onPressed: _next,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// یک پرده‌ی خوشامد: نگاره، سرنویس، تن.
class _Parde extends StatelessWidget {
  const _Parde({
    required this.still,
    required this.art,
    required this.title,
    required this.body,
  });

  final bool still;
  final Widget art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final column = Padding(
      padding: const EdgeInsets.symmetric(horizontal: SarehSpace.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          art,
          const SizedBox(height: SarehSpace.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: SarehSpace.md),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
    if (still) return column;
    return column
        .animate()
        .fadeIn(duration: SarehMotion.page, curve: SarehMotion.pageCurve)
        .slideY(
          begin: 0.04,
          end: 0,
          duration: SarehMotion.page,
          curve: SarehMotion.pageCurve,
        );
  }
}

/// وام‌واژه که به برابرِ سره می‌گردد — چکیده‌ی کارِ اپ در یک نگاه.
class _WordSwap extends StatelessWidget {
  const _WordSwap({required this.still});

  final bool still;

  static const _pairs = [
    ('حرف', 'سخن'),
    ('قیمت', 'بها'),
    ('مشکل', 'دشواری'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final loanStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colors.onSurfaceMuted,
          decoration: TextDecoration.lineThrough,
          decorationColor: colors.onSurfaceMuted,
        );
    final sareStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colors.action,
          fontWeight: FontWeight.bold,
        );
    return Column(
      children: [
        for (final (i, (loan, sare)) in _pairs.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: SarehSpace.xs),
            child: Builder(
              builder: (context) {
                final row = Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(loan, style: loanStyle),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SarehSpace.md,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: SarehType.lg,
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                    Text(sare, style: sareStyle),
                  ],
                );
                if (still) return row;
                return row.animate(delay: SarehMotion.element * i).fadeIn(
                      duration: SarehMotion.page,
                      curve: SarehMotion.pageCurve,
                    );
              },
            ),
          ),
      ],
    );
  }
}

/// هفت نگهبان، هفت رنگ — پیش‌نمایشِ راه.
class _KhanRow extends StatelessWidget {
  const _KhanRow({required this.still});

  final bool still;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: SarehSpace.md,
      runSpacing: SarehSpace.md,
      children: [
        for (var khan = 1; khan <= 7; khan++)
          Builder(
            builder: (context) {
              final accent = SarehKhanColors.of(khan);
              final emblem = GuardianEmblem(
                khan: khan,
                size: 56,
                colour: dark ? accent.dark : accent.light,
              );
              if (still) return emblem;
              return emblem
                  .animate(delay: SarehMotion.micro * khan)
                  .fadeIn(duration: SarehMotion.element)
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: SarehMotion.element,
                    curve: SarehMotion.elementCurve,
                  );
            },
          ),
      ],
    );
  }
}

/// «نورِ واژه» روی نامِ خودِ اپ — امضای محصول، زنده.
class _NurDemo extends StatelessWidget {
  const _NurDemo();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: SarehType.h1 * 1.7,
        child: NureVajeh(word: 'سَره'),
      );
}
