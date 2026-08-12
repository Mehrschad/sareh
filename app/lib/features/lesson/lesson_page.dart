// صفحه‌ی منزل — میزبانِ گونه‌های تمرین.
//
// زمان‌بندیِ لحظه‌ی پاسخِ درست (بخش ۷٫۳):
//   0ms       بازخوردِ لمسی
//   0–120ms   گزینه به فیروزه می‌رود و ۱٫۰۳ برابر می‌شود  (در exercises.dart)
//   100–700ms رشته‌ی نور مسیرِ نستعلیقِ واژه را می‌پیماید  (NureVajeh)
//   250ms     نوارِ پیشرفت با کششِ فنری پر می‌شود
//   400ms     سه ذره‌ی زر از واژه بلند می‌شوند
//
// پاسخِ نادرست: لرزشِ افقی، سپس کارتِ توضیح از پایین. بدونِ صدای تنبیهی،
// بدونِ قرمزکردنِ صفحه، بدونِ سرزنش.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design/nur_e_vajeh.dart';
import '../../design/nur_glow.dart';
import '../../design/tokens.g.dart';
import '../../design/widgets.dart';
import '../../shared/content_repository.dart';
import '../../shared/models.dart';
import '../journey/progress.dart';
import 'exercises.dart';
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
                      controller.answer(correct: correct);
                    },
                  ),
                ),
              ),
            ),
            if (state.lastAnswerCorrect case final answered?)
              _Feedback(
                correct: answered,
                word: question.word,
                onNext: controller.next,
              ),
          ],
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({super.key, required this.question, required this.onAnswer});

  final Question question;
  final AnswerCallback onAnswer;

  @override
  Widget build(BuildContext context) => switch (question) {
        final GozineshQuestion q => GozineshExercise(question: q, onAnswer: onAnswer),
        final JaygoziniQuestion q => JaygoziniExercise(question: q, onAnswer: onAnswer),
        final JoftsazQuestion q => JoftsazExercise(question: q, onAnswer: onAnswer),
        final BeityabQuestion q => BeityabExercise(question: q, onAnswer: onAnswer),
      };
}

/// نوارِ بازخورد. لحنش هرگز شرمنده‌کننده نیست (بخش ۱۴).
class _Feedback extends StatelessWidget {
  const _Feedback({required this.correct, required this.word, required this.onNext});

  final bool correct;
  final Word word;
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
            _CorrectPanel(word: word)
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
  const _CorrectPanel({required this.word});
  final Word word;

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
    final word = widget.word;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: SarehType.h2 * 1.6,
          child: _showLight
              ? NureVajeh(
                  word: word.sare,
                  calligraphy: WordPathCache.instance[word.id],
                )
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

/// پایانِ منزل. جشن هست، ولی رد شدن از آن همیشه ممکن است.
class _StationComplete extends ConsumerStatefulWidget {
  const _StationComplete({required this.state, required this.stationId});

  final LessonState state;
  final String stationId;

  @override
  ConsumerState<_StationComplete> createState() => _StationCompleteState();
}

class _StationCompleteState extends ConsumerState<_StationComplete> {
  @override
  void initState() {
    super.initState();
    // پیشرفت همان‌جا ثبت می‌شود، نه پس از پایانِ انیمیشنِ جشن.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progressProvider.notifier).completeStation(widget.stationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final total = state.questions.length;
    final ratio = total == 0 ? 0.0 : state.correct / total;

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
            Padding(
              padding: const EdgeInsets.all(SarehSpace.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'منزل گذشت.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
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
                    const SizedBox(height: SarehSpace.xl),
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
