// صفحه‌ی منزل — میزبانِ گونه‌های تمرین.
//
// زمان‌بندیِ لحظه‌ی پاسخِ درست (بخش ۷٫۳):
//   0ms       بازخوردِ لمسی
//   0–120ms   گزینه به فیروزه می‌رود و ۱٫۰۳ برابر می‌شود  (در exercises.dart)
//   100–700ms رشته‌ی نور از راست به چپ واژه را روشن می‌کند  (NureVajeh)
//   250ms     نوارِ پیشرفت با کششِ فنری پر می‌شود
//   400ms     سه ذره‌ی زر از واژه بلند می‌شوند
//
// پاسخِ نادرست: لرزشِ افقی، سپس کارتِ توضیح از پایین. بدونِ صدای تنبیهی،
// بدونِ قرمزکردنِ صفحه، بدونِ سرزنش.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings.dart';
import '../../core/sound.dart';
import '../../data/progress_repository.dart';
import '../../design/emblems.dart';
import '../../design/nur_e_vajeh.dart';
import '../../design/nur_glow.dart';
import '../../design/tokens.g.dart';
import '../../design/widgets.dart';
import '../../shared/content_repository.dart';
import '../../shared/models.dart';
import '../journey/progress.dart';
import 'exercises.dart';
import 'goftar.dart';
import 'lesson_controller.dart';

class LessonPage extends ConsumerWidget {
  const LessonPage({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    return content.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: SarehEmpty(message: 'محتوا خوانده نشد.\n$error')),
      data: (_) => _LessonView(stationId: stationId),
    );
  }
}

class _LessonView extends ConsumerWidget {
  const _LessonView({required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(lessonControllerProvider(stationId));
    final controller = ref.read(lessonControllerProvider(stationId).notifier);

    if (state.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const SarehEmpty(message: 'این منزل هنوز واژه‌ای ندارد.'),
      );
    }

    if (state.isFinished) {
      return _StationComplete(state: state, stationId: stationId);
    }

    final question = state.current!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(SarehSpace.md),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'بازگشت به هفت‌خان',
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: colors.onSurfaceMuted,
                      onPressed: () => context.pop(),
                    ),
                  ),
                  Expanded(
                    child: SarehProgressBar(
                      value: state.progress,
                      semanticLabel: 'پیشرفتِ منزل',
                    ),
                  ),
                  const SizedBox(width: SarehSpace.md),
                  Text(
                    '${toPersianDigits(state.index + 1)}'
                    '/${toPersianDigits(state.questions.length)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SarehShake(
                trigger: state.shakeCounter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(SarehSpace.lg),
                  child: _QuestionView(
                    // کلید تضمین می‌کند حالتِ گونه با هر پرسش از نو آغاز شود.
                    key: ValueKey('${question.kind}-${state.index}'),
                    question: question,
                    onAnswer: ({required bool correct}) {
                      HapticFeedback.lightImpact();
                      ref
                          .read(soundProvider)
                          .play(correct ? Sfx.dorost : Sfx.nadorost);
                      controller.answer(correct: correct);
                    },
                    onPractice: (word, {required correct, required answerMs}) =>
                        controller.practise(
                      word: word,
                      correct: correct,
                      answerMs: answerMs,
                      kind: question.kind,
                    ),
                  ),
                ),
              ),
            ),
            if (state.lastAnswerCorrect case final answered?)
              _Feedback(
                correct: answered,
                word: question.word,
                gain: state.lastGain,
                onNext: controller.next,
              ),
          ],
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    super.key,
    required this.question,
    required this.onAnswer,
    required this.onPractice,
  });

  final Question question;
  final AnswerCallback onAnswer;
  final PracticeCallback onPractice;

  @override
  Widget build(BuildContext context) => switch (question) {
        final GozineshQuestion q => GozineshExercise(question: q, onAnswer: onAnswer),
        final JaygoziniQuestion q => JaygoziniExercise(question: q, onAnswer: onAnswer),
        final JoftsazQuestion q => JoftsazExercise(question: q, onAnswer: onAnswer),
        final BeityabQuestion q => BeityabExercise(question: q, onAnswer: onAnswer),
        final RishehyabQuestion q =>
          RishehyabExercise(question: q, onAnswer: onAnswer),
        final VajechinQuestion q =>
          VajechinExercise(question: q, onAnswer: onAnswer),
        final NeviseshQuestion q =>
          NeviseshExercise(question: q, onAnswer: onAnswer),
        final DastanakQuestion q =>
          DastanakExercise(question: q, onAnswer: onAnswer),
        final TirArashQuestion q => TirArashExercise(
            question: q,
            onAnswer: onAnswer,
            onPractice: onPractice,
          ),
      };
}

/// نوارِ بازخورد. لحنش هرگز شرمنده‌کننده نیست (بخش ۱۴).
class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.correct,
    required this.word,
    required this.gain,
    required this.onNext,
  });

  final bool correct;
  final Word word;

  /// فَرِّ همین پاسخ — صفر برای پاسخِ نادرست.
  final int gain;

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SarehSpace.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: correct ? colors.action : colors.error)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (correct)
            _CorrectPanel(word: word, gain: gain)
          else
            _WrongPanel(word: word),
          const SizedBox(height: SarehSpace.md),
          SarehButton(label: correct ? 'دنبالش کن' : 'باشد', onPressed: onNext),
        ],
      ),
    );
  }
}

/// پاسخِ درست — «نورِ واژه» اینجا اجرا می‌شود.
class _CorrectPanel extends StatefulWidget {
  const _CorrectPanel({required this.word, required this.gain});
  final Word word;
  final int gain;

  @override
  State<_CorrectPanel> createState() => _CorrectPanelState();
}

class _CorrectPanelState extends State<_CorrectPanel> {
  bool _showLight = false;

  @override
  void initState() {
    super.initState();
    // نور بی‌درنگ آغاز نمی‌شود: نخست دکمه واکنش نشان می‌دهد، سپس
    // واژه نوشته می‌شود.
    Future.delayed(SarehSignature.startDelay, () {
      if (mounted) setState(() => _showLight = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final word = widget.word;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: SarehType.h2 * 1.6,
          child: _showLight
              ? NureVajeh(word: word.sare)
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: SarehSpace.sm),
        Text(
          // «درست. «پرماس» از پهلویِ parmāsītan.» — نه «آفرین! عالی بود!»
          word.pahlavi != null
              ? 'درست. «${word.sare}» از پهلویِ ${word.pahlavi}.'
              : 'درست. ${word.definition}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (widget.gain > 0) ...[
          const SizedBox(height: SarehSpace.sm),
          // فَرِّ همین پاسخ — شمارِ آشکار، نه ستایشِ تهی. پاداشِ زنجیره
          // (FarrRules.comboBonus) خودش را همین‌جا نشان می‌دهد.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FarrIcon(size: SarehType.md, colour: colors.achievement),
              const SizedBox(width: SarehSpace.xs),
              Text(
                '${toPersianDigits(widget.gain)}+ فَرّ',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: colors.achievement),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// پاسخِ نادرست — کارتِ توضیح، با برابرِ درست و یک نمونه‌ی کاربرد.
class _WrongPanel extends StatelessWidget {
  const _WrongPanel({required this.word});
  final Word word;

  @override
  Widget build(BuildContext context) {
    final example = word.examples.isEmpty ? null : word.examples.first;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'برابرِ «${word.loan}»، «${word.sare}» است. ببین کجا به کار می‌رود:',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (example != null) ...[
          const SizedBox(height: SarehSpace.sm),
          Text(example.sare, style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (word.citations.isNotEmpty) ...[
          const SizedBox(height: SarehSpace.sm),
          Text(
            word.citations.first.display,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ],
    );
  }
}

/// پایانِ منزل — لحظه‌ی جشن. رد شدن از آن همیشه ممکن است.
///
/// چرا این‌قدر جدا از باقیِ اپ می‌درخشد: باقیِ رابط عمداً ساکت است تا
/// لحظه‌ی پاداش برجسته بماند. اینجا سیمرغ سخن می‌گوید، فَرّ از صفر
/// شمرده می‌شود (شمارشِ صعودی، انتظارِ خوشایند می‌سازد) و باران زر
/// بالا می‌رود. در حالتِ بی‌حرکت همه‌چیز ساکن و یک‌باره می‌نشیند.
class _StationComplete extends ConsumerStatefulWidget {
  const _StationComplete({required this.state, required this.stationId});

  final LessonState state;
  final String stationId;

  @override
  ConsumerState<_StationComplete> createState() => _StationCompleteState();
}

class _StationCompleteState extends ConsumerState<_StationComplete> {
  late final GoftarLine _line;
  late final bool _perfect;
  late final int _awarded;

  @override
  void initState() {
    super.initState();
    final total = widget.state.questions.length;
    _perfect = total > 0 && widget.state.wrong.isEmpty;
    _awarded = widget.state.farr +
        FarrRules.station +
        (_perfect ? FarrRules.perfectBonus : 0);
    // سطرِ سیمرغ پیش از ثبتِ پیشرفت برگزیده می‌شود تا شمارنده‌ی چرخش،
    // خودِ همین منزل را نشمرده باشد.
    _line = Goftar.forStation(
      isPerfect: _perfect,
      hadWrong: widget.state.wrong.isNotEmpty,
      completedBefore: ref.read(progressProvider).completedStations.length,
    );
    ref.read(soundProvider).play(_perfect ? Sfx.gohar : Sfx.manzel);
    // پیشرفت همان‌جا ثبت می‌شود، نه پس از پایانِ انیمیشنِ جشن.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progressProvider.notifier).completeStation(
            widget.stationId,
            ratio: total == 0 ? 0 : widget.state.correct / total,
            earnedFarr: widget.state.farr,
            perfect: _perfect,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = widget.state;
    final total = state.questions.length;
    final ratio = total == 0 ? 0.0 : state.correct / total;
    final still = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // هاله پشتِ متن می‌نشیند و تعامل را نمی‌گیرد.
            const Padding(
              padding: EdgeInsets.only(top: SarehSpace.xxl),
              child: NurGlow(),
            ),
            if (!still) const Positioned.fill(child: _ZarBaran()),
            Padding(
              padding: const EdgeInsets.all(SarehSpace.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SimorghEmblem(
                      size: SarehSpace.xxl + SarehSpace.xl,
                      colour: colors.action,
                      accent: colors.achievement,
                    ),
                  ),
                  const SizedBox(height: SarehSpace.md),
                  Text(
                    'منزل گذشت.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: SarehSpace.sm),
                  // گفتارِ سیمرغ — دلگرمی، هرگز سرزنش.
                  Text(
                    _line.by == null ? _line.text : '«${_line.text}»',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: colors.accentSoft),
                  ),
                  if (_line.by != null)
                    Text(
                      '— ${_line.by}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: colors.onSurfaceMuted),
                    ),
                  const SizedBox(height: SarehSpace.lg),
                  _FarrCountUp(total: _awarded, still: still),
                  if (_perfect) ...[
                    const SizedBox(height: SarehSpace.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GoharIcon(size: SarehType.lg, colour: colors.action),
                        const SizedBox(width: SarehSpace.xs),
                        Text(
                          'یک گوهر — منزلِ بی‌لغزش',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: SarehSpace.lg),
                  Text(
                    '${toPersianDigits(state.correct)} از '
                    '${toPersianDigits(total)} درست.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: SarehSpace.md),
                  SarehProgressBar(value: ratio, semanticLabel: 'درصدِ درست'),
                  if (state.wrong.isNotEmpty) ...[
                    const SizedBox(height: SarehSpace.lg),
                    Text(
                      // نه سرزنش — تنها خبر از اینکه دوباره می‌بینی‌شان.
                      'این‌ها را دوباره می‌بینی:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: SarehSpace.sm),
                    Wrap(
                      spacing: SarehSpace.sm,
                      runSpacing: SarehSpace.xs,
                      children: [
                        for (final word in state.wrong)
                          Chip(label: Text('${word.sare} / ${word.loan}')),
                      ],
                    ),
                  ],
                  const SizedBox(height: SarehSpace.xl),
                  SarehButton(
                    label: 'بازگشت به راه',
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شمارنده‌ی فَرّ — از صفر تا فَرِّ به‌دست‌آمده.
class _FarrCountUp extends StatelessWidget {
  const _FarrCountUp({required this.total, required this.still});

  final int total;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: colors.achievement,
          fontWeight: FontWeight.bold,
        );
    return Semantics(
      label: 'فَرِّ این منزل: ${toPersianDigits(total)}',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FarrIcon(size: SarehType.xl, colour: colors.achievement),
          const SizedBox(width: SarehSpace.sm),
          still
              ? Text('${toPersianDigits(total)}+ فَرّ', style: style)
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: total.toDouble()),
                  duration: SarehJashn.countUp,
                  curve: SarehMotion.heroCurve,
                  builder: (context, value, _) => Text(
                    '${toPersianDigits(value.round())}+ فَرّ',
                    style: style,
                  ),
                ),
        ],
      ),
    );
  }
}

/// بارانِ زر — ذره‌هایی که از پایین برمی‌خیزند و محو می‌شوند.
///
/// بالا رفتن، نه فروافتادن: پیشرفت در همه‌ی فرهنگ‌ها «بالا» است و
/// فروافتادنِ ذره، حسِ پایانِ چیزی را می‌دهد نه آغازِ چیزی.
class _ZarBaran extends StatefulWidget {
  const _ZarBaran();

  @override
  State<_ZarBaran> createState() => _ZarBaranState();
}

class _ZarBaranState extends State<_ZarBaran>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SarehJashn.particleDuration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ZarBaranPainter(
            progress: _controller.value,
            colour: colors.achievement,
          ),
        ),
      ),
    );
  }
}

class _ZarBaranPainter extends CustomPainter {
  _ZarBaranPainter({required this.progress, required this.colour});

  final double progress;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    // قطعی، نه تصادفیِ هر فریم: هر ذره سرنوشتِ خودش را از شماره‌اش می‌گیرد.
    final rng = math.Random(7);
    for (var i = 0; i < SarehJashn.particleCount; i++) {
      final x = rng.nextDouble() * size.width;
      final delay = rng.nextDouble() * 0.5;
      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final eased = SarehMotion.kamanArash.transform(t);
      final y = size.height - eased * (SarehJashn.particleRise + size.height * 0.3);
      final alpha = (1 - t) * 0.9;
      final radius = 1.5 + rng.nextDouble() * 2.5;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = colour.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_ZarBaranPainter old) => old.progress != progress;
}
