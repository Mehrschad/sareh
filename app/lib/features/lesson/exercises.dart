// نه گونه‌ی تمرین.
//
// همه یک قرارداد دارند: `onAnswer(bool correct)`. موتور نمی‌داند کاربر چگونه
// پاسخ داده؛ گونه نمی‌داند پس از پاسخ چه می‌شود. بنابراین افزودنِ گونه‌ی پنجم
// هیچ فایلِ دیگری را دست نمی‌زند.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../design/tokens.g.dart';
import '../../design/widgets.dart';
import '../../shared/models.dart';
import '../../src/rust/api.dart';
import 'lesson_controller.dart';

typedef AnswerCallback = void Function({required bool correct});

/// پاسخی که برای مرورِ فاصله‌دار ثبت می‌شود ولی منزل را جلو نمی‌برد.
///
/// تنها «تیر آرش» به آن نیاز دارد: در شصت ثانیه ده‌ها واژه از جلوی چشم
/// می‌گذرند و هر کدام باید زمان‌بندیِ خودش را بگیرد، وگرنه کاربر کار کرده و
/// حافظه‌اش ثبت نشده.
typedef PracticeCallback = void Function(
  Word word, {
  required bool correct,
  required int answerMs,
});

/// گزینه‌ی چهارتاییِ مشترکِ «گزینش»، «جای‌گزینی» و «بیت‌یاب».
class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.options,
    required this.answer,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final String answer;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: SarehSpace.sm),
            child: _OptionTile(
              label: option,
              // پس از پاسخ، گزینه‌ی درست همیشه روشن می‌شود — چه کاربر آن را
              // زده باشد چه نه. یاد گرفتن مهم‌تر از داوری است.
              state: switch ((selected, option)) {
                (null, _) => _OptionState.idle,
                (_, final o) when o == answer => _OptionState.correct,
                (final chosen, final o) when o == chosen => _OptionState.wrong,
                _ => _OptionState.idle,
              },
              onTap: selected == null ? () => onSelect(option) : null,
              colors: colors,
            ),
          ),
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.state,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final _OptionState state;
  final VoidCallback? onTap;
  final SarehColors colors;

  @override
  Widget build(BuildContext context) {
    // شنگرف تنها روی حاشیه می‌نشیند. خطا نباید صفحه را قرمز کند (بخش ۷٫۳).
    final border = switch (state) {
      _OptionState.idle => colors.outline,
      _OptionState.correct => colors.action,
      _OptionState.wrong => colors.error,
    };
    final fill = switch (state) {
      _OptionState.correct => colors.action,
      _ => colors.surface,
    };
    final ink = state == _OptionState.correct ? colors.onAction : colors.onSurface;

    return Semantics(
      button: onTap != null,
      selected: state != _OptionState.idle,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          // ۰ تا ۱۲۰ms — گزینه‌ی درست ۱٫۰۳ برابر بزرگ می‌شود.
          scale: state == _OptionState.correct ? 1.03 : 1.0,
          duration: SarehMotion.micro,
          curve: SarehMotion.microCurve,
          child: AnimatedContainer(
            duration: SarehMotion.element,
            curve: SarehMotion.elementCurve,
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: SarehA11y.minTouchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: SarehSpace.md,
              vertical: SarehSpace.sm,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(SarehRadius.capsule),
              border: Border.all(color: border, width: state == _OptionState.idle ? 1 : 2),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: SarehType.bodyFamily,
                fontSize: SarehType.lg,
                height: SarehType.lgLine,
                color: ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ۱. گزینش — وام‌واژه داده می‌شود، سره را برگزین.
class GozineshExercise extends StatefulWidget {
  const GozineshExercise({super.key, required this.question, required this.onAnswer});

  final GozineshQuestion question;
  final AnswerCallback onAnswer;

  @override
  State<GozineshExercise> createState() => _GozineshExerciseState();
}

class _GozineshExerciseState extends State<GozineshExercise> {
  String? _selected;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Prompt(
            hint: 'برابرِ پارسی کدام است؟',
            focus: widget.question.word.loan,
          ),
          const SizedBox(height: SarehSpace.xl),
          _OptionGrid(
            options: widget.question.options,
            answer: widget.question.answer,
            selected: _selected,
            onSelect: (choice) {
              setState(() => _selected = choice);
              widget.onAnswer(correct: choice == widget.question.answer);
            },
          ),
        ],
      );
}

/// ۳. جای‌گزینی — روی وام‌واژه‌ی جمله ضربه بزن و سره را جایش بگذار.
///
/// جمله با انیمیشن بازچینش می‌شود: نشانه‌ی تازه در جای همان نشانه‌ی کهنه
/// می‌نشیند و جمله دورش باز می‌شود.
class JaygoziniExercise extends StatefulWidget {
  const JaygoziniExercise({super.key, required this.question, required this.onAnswer});

  final JaygoziniQuestion question;
  final AnswerCallback onAnswer;

  @override
  State<JaygoziniExercise> createState() => _JaygoziniExerciseState();
}

class _JaygoziniExerciseState extends State<JaygoziniExercise> {
  String? _selected;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final question = widget.question;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('وام‌واژه را بردار.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: SarehSpace.md),
        SarehCard(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: SarehSpace.xs,
            runSpacing: SarehSpace.xs,
            children: [
              for (var i = 0; i < question.sentence.length; i++)
                if (i == question.loanToken)
                  AnimatedSize(
                    duration: SarehMotion.element,
                    curve: SarehMotion.elementCurve,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SarehSpace.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _revealed ? colors.action : colors.surfaceRaised,
                        borderRadius: BorderRadius.circular(SarehRadius.input),
                      ),
                      child: Text(
                        _revealed ? question.answer : question.sentence[i],
                        style: TextStyle(
                          fontFamily: SarehType.bodyFamily,
                          fontSize: SarehType.lg,
                          height: SarehType.lgLine,
                          color: _revealed ? colors.onAction : colors.onSurface,
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    question.sentence[i],
                    style: TextStyle(
                      fontFamily: SarehType.bodyFamily,
                      fontSize: SarehType.lg,
                      height: SarehType.lgLine,
                      color: colors.onSurface,
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: SarehSpace.lg),
        _OptionGrid(
          options: question.options,
          answer: question.answer,
          selected: _selected,
          onSelect: (choice) {
            final correct = choice == question.answer;
            setState(() {
              _selected = choice;
              // جمله همیشه صورتِ درست را نشان می‌دهد، چه کاربر زده باشد چه نه.
              _revealed = true;
            });
            widget.onAnswer(correct: correct);
          },
        ),
      ],
    );
  }
}

/// ۲. جفت‌ساز — دو ستون واژه، خط بکش.
class JoftsazExercise extends StatefulWidget {
  const JoftsazExercise({super.key, required this.question, required this.onAnswer});

  final JoftsazQuestion question;
  final AnswerCallback onAnswer;

  @override
  State<JoftsazExercise> createState() => _JoftsazExerciseState();
}

class _JoftsazExerciseState extends State<JoftsazExercise> {
  String? _pendingSare;
  final Set<String> _matched = {};
  bool _slipped = false;
  late final List<Word> _loanColumn = [...widget.question.pairs.reversed];

  void _tapSare(Word word) {
    if (_matched.contains(word.id)) return;
    setState(() => _pendingSare = word.id);
  }

  void _tapLoan(Word word) {
    final pending = _pendingSare;
    if (pending == null || _matched.contains(word.id)) return;

    if (pending == word.id) {
      setState(() {
        _matched.add(word.id);
        _pendingSare = null;
      });
      if (_matched.length == widget.question.pairs.length) {
        // درست یعنی همه‌ی جفت‌ها بی‌لغزش بسته شده باشند.
        widget.onAnswer(correct: !_slipped);
      }
    } else {
      setState(() {
        _slipped = true;
        _pendingSare = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('جفت‌ها را به هم برسان.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: SarehSpace.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (final word in widget.question.pairs)
                      _PairChip(
                        label: word.sare,
                        matched: _matched.contains(word.id),
                        pending: _pendingSare == word.id,
                        onTap: () => _tapSare(word),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: SarehSpace.md),
              Expanded(
                child: Column(
                  children: [
                    for (final word in _loanColumn)
                      _PairChip(
                        label: word.loan,
                        matched: _matched.contains(word.id),
                        pending: false,
                        onTap: () => _tapLoan(word),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
}

class _PairChip extends StatelessWidget {
  const _PairChip({
    required this.label,
    required this.matched,
    required this.pending,
    required this.onTap,
  });

  final String label;
  final bool matched;
  final bool pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: SarehSpace.sm),
      child: Semantics(
        button: !matched,
        selected: matched,
        label: label,
        child: GestureDetector(
          onTap: matched ? null : onTap,
          child: AnimatedOpacity(
            opacity: matched ? SarehOpacity.lockedStation : 1,
            duration: SarehMotion.element,
            child: AnimatedContainer(
              duration: SarehMotion.element,
              curve: SarehMotion.elementCurve,
              constraints: const BoxConstraints(minHeight: SarehA11y.minTouchTarget),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: SarehSpace.sm,
                vertical: SarehSpace.sm,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(SarehRadius.input),
                border: Border.all(
                  color: pending ? colors.accentSoft : colors.outline,
                  width: pending ? 2 : 1,
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: SarehType.bodyFamily,
                  fontSize: SarehType.md,
                  height: SarehType.mdLine,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ۷. بیت‌یاب ⭐ — امضای محصول.
///
/// بیت با یک جای خالی نمایش داده می‌شود. وقتی درست شد، کلِ بیت روشن می‌شود.
/// ضربِ تنبک تنها روی بیتی پخش می‌شود که وزنش ثبت شده باشد — بهتر است ساکت
/// بماند تا اینکه بیت را نادرست بخواند.
class BeityabExercise extends StatefulWidget {
  const BeityabExercise({super.key, required this.question, required this.onAnswer});

  final BeityabQuestion question;
  final AnswerCallback onAnswer;

  @override
  State<BeityabExercise> createState() => _BeityabExerciseState();
}

class _BeityabExerciseState extends State<BeityabExercise> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final verse = widget.question.verse;
    final solved = _selected == widget.question.answer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${verse.poet} — ${verse.work}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: SarehSpace.md),
        SarehCard(
          borderColour: solved ? colors.action : null,
          padding: const EdgeInsets.symmetric(
            horizontal: SarehSpace.md,
            vertical: SarehSpace.lg,
          ),
          child: Column(
            children: [
              _Hemistich(
                text: verse.first,
                blank: verse.blankHemistich == 1 ? verse.blankSurface : null,
                filled: _selected,
                lit: solved,
              ),
              const SizedBox(height: SarehSpace.sm),
              _Hemistich(
                text: verse.second,
                blank: verse.blankHemistich == 2 ? verse.blankSurface : null,
                filled: _selected,
                lit: solved,
              ),
              if (verse.meter case final meter?) ...[
                const SizedBox(height: SarehSpace.sm),
                Text(meter, style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
        ),
        const SizedBox(height: SarehSpace.lg),
        _OptionGrid(
          options: widget.question.options,
          answer: widget.question.answer,
          selected: _selected,
          onSelect: (choice) {
            setState(() => _selected = choice);
            widget.onAnswer(correct: choice == widget.question.answer);
          },
        ),
      ],
    );
  }
}

class _Hemistich extends StatelessWidget {
  const _Hemistich({
    required this.text,
    required this.blank,
    required this.filled,
    required this.lit,
  });

  final String text;
  final String? blank;
  final String? filled;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = TextStyle(
      fontFamily: SarehType.bodyFamily,
      fontSize: SarehType.lg,
      height: SarehType.lgLine,
      color: lit ? colors.accentSoft : colors.onSurface,
    );

    if (blank == null) {
      return AnimatedDefaultTextStyle(
        duration: SarehMotion.element,
        style: style,
        child: Text(text, textAlign: TextAlign.center),
      );
    }

    // جای خالی درست همان‌جایی می‌نشیند که واژه در بیت بوده است.
    final parts = text.split(blank!);
    final before = parts.first;
    final after = parts.length > 1 ? parts.sublist(1).join(blank!) : '';

    return AnimatedDefaultTextStyle(
      duration: SarehMotion.element,
      style: style,
      child: RichText(
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        text: TextSpan(
          style: style,
          children: [
            TextSpan(text: before),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: AnimatedContainer(
                duration: SarehMotion.element,
                curve: SarehMotion.elementCurve,
                constraints: const BoxConstraints(minWidth: 56),
                padding: const EdgeInsets.symmetric(horizontal: SarehSpace.sm),
                decoration: BoxDecoration(
                  color: filled == null ? colors.surfaceRaised : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: lit ? colors.accentSoft : colors.outline,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  filled ?? ' ',
                  textAlign: TextAlign.center,
                  style: style.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            TextSpan(text: after),
          ],
        ),
      ),
    );
  }
}

/// سرِ پرسش: راهنمای کوتاه، سپس واژه‌ی کانونی.
/// ریشه‌یاب ⭐ — زنجیره‌ی ریشه‌ی واژه را بازبساز.
///
/// واژه‌ی امروز پایینِ زنجیره ایستاده و از پیش پر است. بالای آن، برای هر
/// زبانِ کهنی که ثبت شده یک جای خالی هست. کاربر صورت‌ها را از میان
/// پیشنهادها برمی‌دارد و در جای خودشان می‌گذارد؛ با پر شدنِ آخرین جای خالی
/// پاسخ سنجیده می‌شود.
///
/// زنجیره از بالا به پایین خوانده می‌شود — کهن‌ترین در بالا — تا حرکتِ چشم
/// همان حرکتِ زمان باشد.
class RishehyabExercise extends StatefulWidget {
  const RishehyabExercise({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  final RishehyabQuestion question;
  final AnswerCallback onAnswer;

  @override
  State<RishehyabExercise> createState() => _RishehyabExerciseState();
}

class _RishehyabExerciseState extends State<RishehyabExercise> {
  late final List<String?> _placed =
      List<String?>.filled(widget.question.steps.length, null);
  bool _answered = false;

  int get _nextEmpty => _placed.indexOf(null);

  void _place(String form) {
    if (_answered || _placed.contains(form)) return;
    final slot = _nextEmpty;
    if (slot < 0) return;
    setState(() => _placed[slot] = form);
    if (_nextEmpty >= 0) return;

    // آخرین جای خالی پر شد — همین‌جا داوری می‌شود، بی‌دکمه‌ی «ثبت».
    setState(() => _answered = true);
    final answer = widget.question.answer;
    var correct = true;
    for (var i = 0; i < answer.length; i++) {
      if (_placed[i] != answer[i]) correct = false;
    }
    widget.onAnswer(correct: correct);
  }

  void _lift(int slot) {
    if (_answered) return;
    setState(() => _placed[slot] = null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final question = widget.question;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _answered ? 'ریشه‌ی واژه' : 'هر صورت را در زبانِ خودش بگذار',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: SarehSpace.md),
        SarehCard(
          padding: const EdgeInsets.symmetric(
            horizontal: SarehSpace.md,
            vertical: SarehSpace.md,
          ),
          child: Column(
            children: [
              for (var i = 0; i < question.steps.length; i++) ...[
                _ChainSlot(
                  language: question.steps[i].language,
                  form: _placed[i],
                  expected: question.answer[i],
                  answered: _answered,
                  onLift: () => _lift(i),
                  colors: colors,
                ),
                const _ChainLink(),
              ],
              _ChainSlot(
                language: 'امروز',
                form: question.word.sare,
                expected: question.word.sare,
                answered: true,
                given: true,
                onLift: null,
                colors: colors,
              ),
            ],
          ),
        ),
        const SizedBox(height: SarehSpace.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: SarehSpace.sm,
          runSpacing: SarehSpace.sm,
          children: [
            for (final option in question.options)
              _FormChip(
                form: option,
                used: _placed.contains(option),
                onTap: _answered ? null : () => _place(option),
                colors: colors,
              ),
          ],
        ),
      ],
    );
  }
}

/// یک حلقه از زنجیره: نامِ زبان، و صورتی که در آن نشسته.
class _ChainSlot extends StatelessWidget {
  const _ChainSlot({
    required this.language,
    required this.form,
    required this.expected,
    required this.answered,
    required this.onLift,
    required this.colors,
    this.given = false,
  });

  final String language;
  final String? form;
  final String expected;
  final bool answered;
  final bool given;
  final VoidCallback? onLift;
  final SarehColors colors;

  @override
  Widget build(BuildContext context) {
    final right = form == expected;
    // شنگرف تنها روی حاشیه می‌نشیند؛ خطا صفحه را قرمز نمی‌کند (بخش ۷٫۳).
    final border = switch ((answered, form)) {
      (true, _) when right => colors.action,
      (true, final chosen) when chosen != null => colors.error,
      (_, null) => colors.outline,
      _ => colors.accentSoft,
    };
    // پس از پاسخ، صورتِ درست همیشه نشان داده می‌شود — یاد گرفتن مهم‌تر از
    // داوری است.
    final shown = answered && !right ? expected : form;

    return Semantics(
      label: '$language: ${shown ?? 'خالی'}',
      button: onLift != null && form != null,
      child: GestureDetector(
        onTap: form == null ? null : onLift,
        child: AnimatedContainer(
          duration: SarehMotion.element,
          curve: SarehMotion.elementCurve,
          constraints: const BoxConstraints(minHeight: SarehA11y.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: SarehSpace.md,
            vertical: SarehSpace.sm,
          ),
          decoration: BoxDecoration(
            color: given ? colors.action : colors.surface,
            borderRadius: BorderRadius.circular(SarehRadius.input),
            border: Border.all(
              color: border,
              width: form == null ? 1 : 2,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  language,
                  style: TextStyle(
                    fontFamily: SarehType.bodyFamily,
                    fontSize: SarehType.sm,
                    height: SarehType.smLine,
                    color: given ? colors.onAction : colors.onSurfaceMuted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  shown ?? '—',
                  // آوانویسیِ لاتین است؛ راست‌به‌چپ خواندنش خراب می‌کند.
                  textDirection:
                      given ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: given ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    fontFamily: SarehType.bodyFamily,
                    fontSize: SarehType.lg,
                    height: SarehType.lgLine,
                    color: given
                        ? colors.onAction
                        : form == null
                            ? colors.onSurfaceMuted
                            : colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// پیوندِ میانِ دو حلقه — نشانه‌ی «از این، آن شد».
class _ChainLink extends StatelessWidget {
  const _ChainLink();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: SarehSpace.md,
        child: Center(
          child: Container(
            width: 2,
            height: SarehSpace.md,
            color: context.colors.outline,
          ),
        ),
      );
}

/// صورتِ پیشنهادی — برداشته می‌شود و در زنجیره می‌نشیند.
class _FormChip extends StatelessWidget {
  const _FormChip({
    required this.form,
    required this.used,
    required this.onTap,
    required this.colors,
  });

  final String form;
  final bool used;
  final VoidCallback? onTap;
  final SarehColors colors;

  @override
  Widget build(BuildContext context) => Semantics(
        button: onTap != null,
        selected: used,
        label: form,
        child: GestureDetector(
          onTap: used ? null : onTap,
          child: AnimatedOpacity(
            duration: SarehMotion.element,
            curve: SarehMotion.elementCurve,
            opacity: used ? SarehOpacity.disabled : 1,
            child: Container(
              constraints:
                  const BoxConstraints(minHeight: SarehA11y.minTouchTarget),
              padding: const EdgeInsets.symmetric(
                horizontal: SarehSpace.md,
                vertical: SarehSpace.sm,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(SarehRadius.capsule),
                border: Border.all(color: colors.outline),
              ),
              child: Text(
                form,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontFamily: SarehType.bodyFamily,
                  fontSize: SarehType.lg,
                  height: SarehType.lgLine,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
        ),
      );
}

/// واژه‌چین — جمله را از کاشی‌ها دوباره بچین.
class VajechinExercise extends StatefulWidget {
  const VajechinExercise({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  final VajechinQuestion question;
  final AnswerCallback onAnswer;

  @override
  State<VajechinExercise> createState() => _VajechinExerciseState();
}

class _VajechinExerciseState extends State<VajechinExercise> {
  /// نمایه‌ی کاشی‌های برداشته‌شده، به ترتیبِ برداشتن.
  final List<int> _picked = [];
  bool _answered = false;

  void _pick(int index) {
    if (_answered || _picked.contains(index)) return;
    setState(() => _picked.add(index));
    if (_picked.length < widget.question.tiles.length) return;

    setState(() => _answered = true);
    final built = [for (final i in _picked) widget.question.tiles[i]];
    final correct = built.join(' ') == widget.question.sentence.join(' ');
    widget.onAnswer(correct: correct);
  }

  void _undo() {
    if (_answered || _picked.isEmpty) return;
    setState(_picked.removeLast);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final question = widget.question;
    final built = [for (final i in _picked) question.tiles[i]];
    final right = built.join(' ') == question.sentence.join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Prompt(hint: 'جمله را بچین', focus: question.word.sare),
        const SizedBox(height: SarehSpace.lg),
        SarehCard(
          borderColour: _answered ? (right ? colors.action : colors.error) : null,
          padding: const EdgeInsets.symmetric(
            horizontal: SarehSpace.md,
            vertical: SarehSpace.md,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: SarehSpace.xs,
              runSpacing: SarehSpace.xs,
              children: [
                if (built.isEmpty)
                  Text(
                    'کاشی‌ها را به ترتیب بزن',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                for (final token in _answered ? question.sentence : built)
                  Text(token, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: SarehSpace.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: SarehSpace.sm,
          runSpacing: SarehSpace.sm,
          children: [
            for (var i = 0; i < question.tiles.length; i++)
              _Tile(
                label: question.tiles[i],
                used: _picked.contains(i),
                onTap: _answered ? null : () => _pick(i),
                colors: colors,
              ),
          ],
        ),
        if (!_answered && _picked.isNotEmpty) ...[
          const SizedBox(height: SarehSpace.md),
          Align(
            child: TextButton(onPressed: _undo, child: const Text('واپس')),
          ),
        ],
      ],
    );
  }
}

/// نویسش — برابر را بنویس.
///
/// سنجش با `answers_match` هسته‌ی Rust است، پس نیم‌فاصله و «ی» عربی و اعراب
/// پاسخ را رد نمی‌کنند. سنجه‌گر تزریق‌شدنی است تا آزمون به پل نیاز نداشته
/// باشد.
class NeviseshExercise extends StatefulWidget {
  const NeviseshExercise({
    super.key,
    required this.question,
    required this.onAnswer,
    this.grader = answersMatch,
  });

  final NeviseshQuestion question;
  final AnswerCallback onAnswer;
  final Future<bool> Function({required String typed, required String expected})
      grader;

  @override
  State<NeviseshExercise> createState() => _NeviseshExerciseState();
}

class _NeviseshExerciseState extends State<NeviseshExercise> {
  final TextEditingController _input = TextEditingController();
  bool _answered = false;
  bool _right = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_answered || _input.text.trim().isEmpty) return;
    final right = await widget.grader(
      typed: _input.text,
      expected: widget.question.answer,
    );
    if (!mounted) return;
    setState(() {
      _answered = true;
      _right = right;
    });
    widget.onAnswer(correct: right);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final question = widget.question;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Prompt(hint: question.hint, focus: question.word.loan),
        const SizedBox(height: SarehSpace.lg),
        TextField(
          controller: _input,
          enabled: !_answered,
          autofocus: true,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          style: TextStyle(
            fontFamily: SarehType.bodyFamily,
            fontSize: SarehType.xl,
            height: SarehType.xlLine,
            color: colors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'برابرِ پارسی',
            filled: true,
            fillColor: colors.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SarehRadius.input),
              borderSide: BorderSide(color: colors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SarehRadius.input),
              borderSide: BorderSide(color: colors.action, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SarehRadius.input),
              borderSide: BorderSide(
                color: _right ? colors.action : colors.error,
                width: 2,
              ),
            ),
          ),
        ),
        if (_answered && !_right) ...[
          const SizedBox(height: SarehSpace.md),
          // پاسخِ درست همیشه نشان داده می‌شود — یاد گرفتن مهم‌تر از داوری است.
          Text(
            question.answer,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
        if (!_answered) ...[
          const SizedBox(height: SarehSpace.lg),
          SarehButton(label: 'بسنج', onPressed: _submit),
        ],
      ],
    );
  }
}

/// داستانک — پاراگرافی کوتاه با سه جای خالی.
class DastanakExercise extends StatefulWidget {
  const DastanakExercise({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  final DastanakQuestion question;
  final AnswerCallback onAnswer;

  @override
  State<DastanakExercise> createState() => _DastanakExerciseState();
}

class _DastanakExerciseState extends State<DastanakExercise> {
  late final List<String?> _filled =
      List<String?>.filled(widget.question.blanks.length, null);
  bool _answered = false;

  int get _nextEmpty => _filled.indexOf(null);

  void _place(String option) {
    if (_answered || _filled.contains(option)) return;
    final slot = _nextEmpty;
    if (slot < 0) return;
    setState(() => _filled[slot] = option);
    if (_nextEmpty >= 0) return;

    setState(() => _answered = true);
    final answer = widget.question.answer;
    var correct = true;
    for (var i = 0; i < answer.length; i++) {
      if (_filled[i] != answer[i]) correct = false;
    }
    widget.onAnswer(correct: correct);
  }

  void _lift(int slot) {
    if (_answered) return;
    setState(() => _filled[slot] = null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final question = widget.question;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'داستانک را کامل کن',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: SarehSpace.md),
        SarehCard(
          padding: const EdgeInsets.symmetric(
            horizontal: SarehSpace.md,
            vertical: SarehSpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < question.blanks.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: SarehSpace.sm),
                  child: GestureDetector(
                    onTap: _filled[i] == null ? null : () => _lift(i),
                    child: _BlankLine(
                      sentence: question.blanks[i].sentence,
                      filled: _answered && _filled[i] != question.answer[i]
                          ? question.answer[i]
                          : _filled[i],
                      state: switch ((_answered, _filled[i])) {
                        (true, final f) when f == question.answer[i] =>
                          _OptionState.correct,
                        (true, _) => _OptionState.wrong,
                        _ => _OptionState.idle,
                      },
                      colors: colors,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: SarehSpace.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: SarehSpace.sm,
          runSpacing: SarehSpace.sm,
          children: [
            for (final option in question.options)
              _Tile(
                label: option,
                used: _filled.contains(option),
                onTap: _answered ? null : () => _place(option),
                colors: colors,
              ),
          ],
        ),
      ],
    );
  }
}

/// یک جمله‌ی داستانک، با جای خالی‌اش.
class _BlankLine extends StatelessWidget {
  const _BlankLine({
    required this.sentence,
    required this.filled,
    required this.state,
    required this.colors,
  });

  final String sentence;
  final String? filled;
  final _OptionState state;
  final SarehColors colors;

  @override
  Widget build(BuildContext context) {
    final parts = sentence.split(DastanakQuestion.blankMark);
    final ink = switch (state) {
      _OptionState.correct => colors.action,
      _OptionState.wrong => colors.error,
      _OptionState.idle => colors.accentSoft,
    };
    final body = Theme.of(context).textTheme.titleMedium;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: parts.first, style: body),
          TextSpan(
            text: filled ?? DastanakQuestion.blankMark,
            style: body?.copyWith(
              color: filled == null ? colors.onSurfaceMuted : ink,
              decoration: TextDecoration.underline,
              decorationColor: ink,
            ),
          ),
          if (parts.length > 1) TextSpan(text: parts.last, style: body),
        ],
      ),
      textAlign: TextAlign.right,
    );
  }
}

/// تیر آرش — شصت ثانیه، هرچه بیشتر.
///
/// تنها تایمرِ مجازِ سره (ETHICS §۱): کاربر خودش واردش شده و پایانش چیزی را
/// نمی‌سوزاند. پس از پایان، هیچ زنجیره‌ای نمی‌شکند و هیچ امتیازی پس گرفته
/// نمی‌شود؛ تنها شمارش می‌ایستد.
class TirArashExercise extends StatefulWidget {
  const TirArashExercise({
    super.key,
    required this.question,
    required this.onAnswer,
    this.onPractice,
  });

  final TirArashQuestion question;
  final AnswerCallback onAnswer;

  /// هر واژه‌ی این دور جداگانه برای مرورِ فاصله‌دار ثبت می‌شود.
  final PracticeCallback? onPractice;

  @override
  State<TirArashExercise> createState() => _TirArashExerciseState();
}

class _TirArashExerciseState extends State<TirArashExercise> {
  Timer? _clock;
  int _left = 0;
  int _round = 0;
  int _hits = 0;
  bool _running = false;
  bool _done = false;
  DateTime _roundStartedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _left = widget.question.seconds;
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _roundStartedAt = DateTime.now();
    });
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) _finish();
    });
  }

  void _answer(String choice) {
    if (!_running || _done) return;
    final current = widget.question.rounds[_round];
    final right = choice == current.answer;
    if (right) _hits++;
    widget.onPractice?.call(
      current.word,
      correct: right,
      answerMs: DateTime.now().difference(_roundStartedAt).inMilliseconds,
    );
    if (_round + 1 >= widget.question.rounds.length) {
      _finish();
      return;
    }
    setState(() {
      _round++;
      _roundStartedAt = DateTime.now();
    });
  }

  void _finish() {
    if (_done) return;
    _clock?.cancel();
    setState(() {
      _done = true;
      _running = false;
    });
    final attempted = _round + 1;
    widget.onAnswer(
      correct: _hits / attempted >= widget.question.passRatio,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final question = widget.question;

    if (!_running && !_done) {
      return Column(
        children: [
          _Prompt(
            hint: 'تیر آرش — ${_persian(question.seconds)} ثانیه، هرچه بیشتر',
            focus: 'آماده‌ای؟',
          ),
          const SizedBox(height: SarehSpace.lg),
          SarehButton(label: 'رها کن', onPressed: _start),
        ],
      );
    }

    if (_done) {
      return _Prompt(
        hint: 'از ${_persian(_round + 1)} پرسش',
        focus: '${_persian(_hits)} درست',
      );
    }

    final current = question.rounds[_round];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // شمارنده وضعیت را نشان می‌دهد، نه تهدید را: نه رنگ سرخ می‌شود، نه
        // می‌لرزد. پایانش چیزی را نمی‌گیرد.
        Text(
          '${_persian(_left)} ثانیه  ·  ${_persian(_hits)} درست',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: SarehSpace.sm),
        SarehProgressBar(value: _left / question.seconds),
        const SizedBox(height: SarehSpace.lg),
        _Prompt(hint: 'برابرِ پارسی؟', focus: current.word.loan),
        const SizedBox(height: SarehSpace.lg),
        for (final option in current.options)
          Padding(
            padding: const EdgeInsets.only(bottom: SarehSpace.sm),
            child: _OptionTile(
              label: option,
              state: _OptionState.idle,
              onTap: () => _answer(option),
              colors: colors,
            ),
          ),
      ],
    );
  }

  static String _persian(int value) => value
      .toString()
      .split('')
      .map((d) => String.fromCharCode(d.codeUnitAt(0) - 48 + 0x06F0))
      .join();
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.used,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool used;
  final VoidCallback? onTap;
  final SarehColors colors;

  @override
  Widget build(BuildContext context) => Semantics(
        button: onTap != null,
        selected: used,
        label: label,
        child: GestureDetector(
          onTap: used ? null : onTap,
          child: AnimatedOpacity(
            duration: SarehMotion.element,
            curve: SarehMotion.elementCurve,
            opacity: used ? SarehOpacity.disabled : 1,
            child: Container(
              constraints:
                  const BoxConstraints(minHeight: SarehA11y.minTouchTarget),
              padding: const EdgeInsets.symmetric(
                horizontal: SarehSpace.md,
                vertical: SarehSpace.sm,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(SarehRadius.capsule),
                border: Border.all(color: colors.outline),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: SarehType.bodyFamily,
                  fontSize: SarehType.lg,
                  height: SarehType.lgLine,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
        ),
      );
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.hint, required this.focus});

  final String hint;
  final String focus;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(hint, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: SarehSpace.sm),
          Text(
            focus,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ],
      );
}
