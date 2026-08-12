// چهار گونه‌ی تمرین.
//
// همه یک قرارداد دارند: `onAnswer(bool correct)`. موتور نمی‌داند کاربر چگونه
// پاسخ داده؛ گونه نمی‌داند پس از پاسخ چه می‌شود. بنابراین افزودنِ گونه‌ی پنجم
// هیچ فایلِ دیگری را دست نمی‌زند.

import 'package:flutter/material.dart';

import '../../design/tokens.g.dart';
import '../../design/widgets.dart';
import '../../shared/models.dart';
import 'lesson_controller.dart';

typedef AnswerCallback = void Function({required bool correct});

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
