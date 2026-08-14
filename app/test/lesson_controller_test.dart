// آزمونِ موتورِ تمرین.
//
// موتور هیچ ویجتی نمی‌شناسد، پس اینجا هیچ `pumpWidget`ی لازم نیست.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sareh/features/lesson/lesson_controller.dart';
import 'package:sareh/shared/content_repository.dart';
import 'package:sareh/shared/models.dart';

Word word(
  String id, {
  String? sare,
  String? loan,
  double zipf = 5.0,
  int difficulty = 2,
  List<WordExample> examples = const [],
}) =>
    Word(
      id: id,
      sare: sare ?? 'سره_$id',
      loan: loan ?? 'وام_$id',
      loanOrigin: 'عربی',
      pos: 'اسم',
      acceptance: Acceptance.zende,
      ipa: '/test/',
      definition: 'تعریفِ $id',
      english: 'gloss',
      register: 'رسمی',
      frequencyRank: 100,
      zipf: zipf,
      difficulty: difficulty,
      examples: examples,
      citations: const [Citation(source: 'لغت‌نامه دهخدا', ref: 'مدخل')],
      related: const [],
      status: ReviewStatus.reviewed,
    );

ContentBundle bundleOf(List<Word> words, {List<Verse> verses = const []}) => ContentBundle(
      words: {for (final w in words) w.id: w},
      khans: const [],
      verses: verses,
      noEquivalents: const [],
    );

Station stationOf(List<Word> words, List<ExerciseKind> kinds) => Station(
      id: 'manzel',
      title: 'منزلِ آزمون',
      exercises: kinds,
      wordIds: [for (final w in words) w.id],
    );

void main() {
  final random = Random(7);

  group('ساختِ پرسش', () {
    test('برای هر واژه یک پرسش می‌سازد', () {
      final words = [for (var i = 0; i < 8; i++) word('w$i')];
      final questions = LessonController.buildQuestions(
        station: stationOf(words, [ExerciseKind.gozinesh]),
        bundle: bundleOf(words),
        random: random,
      );
      expect(questions, hasLength(words.length));
    });

    test('گونه‌ها را می‌چرخاند تا منزل یکنواخت نشود', () {
      final words = [for (var i = 0; i < 8; i++) word('w$i')];
      final questions = LessonController.buildQuestions(
        station: stationOf(words, [ExerciseKind.gozinesh, ExerciseKind.joftsaz]),
        bundle: bundleOf(words),
        random: random,
      );
      expect(questions.map((q) => q.kind).toSet(), hasLength(2));
    });

    test('گزینش چهار گزینه‌ی یکتا دارد که یکی‌شان درست است', () {
      final words = [for (var i = 0; i < 8; i++) word('w$i')];
      final questions = LessonController.buildQuestions(
        station: stationOf(words, [ExerciseKind.gozinesh]),
        bundle: bundleOf(words),
        random: random,
      );
      for (final question in questions.cast<GozineshQuestion>()) {
        expect(question.options.toSet(), hasLength(4));
        expect(question.options, contains(question.answer));
      }
    });

    test('گونه‌ی بی‌داده به گزینش برمی‌گردد، نه به پرسشِ خالی', () {
      // «بیت‌یاب» بی‌بیت شدنی نیست؛ منزل نباید کوتاه بیاید.
      final words = [for (var i = 0; i < 8; i++) word('w$i')];
      final questions = LessonController.buildQuestions(
        station: stationOf(words, [ExerciseKind.beityab]),
        bundle: bundleOf(words),
        random: random,
      );
      expect(questions, hasLength(8));
      expect(questions.every((q) => q.kind == ExerciseKind.gozinesh), isTrue);
    });

    test('جای‌گزینی نشانه‌ی وام‌واژه را در جمله می‌یابد', () {
      final target = word(
        'parmas',
        sare: 'پرماس',
        loan: 'لمس',
        examples: const [
          WordExample(
            sare: 'انگشتانش را بر ساز پرماس کرد.',
            loan: 'انگشتانش را بر ساز لمس کرد.',
          ),
        ],
      );
      final words = [target, for (var i = 0; i < 5; i++) word('w$i')];
      final questions = LessonController.buildQuestions(
        station: stationOf([target], [ExerciseKind.jaygozini]),
        bundle: bundleOf(words),
        random: random,
      );
      final question = questions.single as JaygoziniQuestion;
      expect(question.sentence[question.loanToken], startsWith('لمس'));
      expect(question.answer, 'پرماس');
    });

    test('بیت‌یاب تنها با بیتِ همان واژه ساخته می‌شود', () {
      final target = word('kherad', sare: 'خرد', loan: 'عقل');
      const verse = Verse(
        id: 'sh-001',
        poet: 'فردوسی',
        work: 'شاهنامه',
        first: 'به نام خداوند جان و خرد',
        second: 'کزین برتر اندیشه برنگذرد',
        blankSurface: 'خرد',
        blankHemistich: 1,
        wordId: 'kherad',
      );
      final words = [target, for (var i = 0; i < 5; i++) word('w$i')];
      final questions = LessonController.buildQuestions(
        station: stationOf([target], [ExerciseKind.beityab]),
        bundle: bundleOf(words, verses: const [verse]),
        random: random,
      );
      final question = questions.single as BeityabQuestion;
      expect(question.verse.id, 'sh-001');
      expect(question.options, contains('خرد'));
    });

    test('منزلِ بی‌واژه پرسشی نمی‌سازد، ولی نمی‌ترکد', () {
      expect(
        LessonController.buildQuestions(
          station: stationOf(const [], [ExerciseKind.gozinesh]),
          bundle: bundleOf(const []),
          random: random,
        ),
        isEmpty,
      );
    });
  });

  group('پیشرویِ منزل', () {
    LessonController controllerOf() {
      final words = [for (var i = 0; i < 8; i++) word('w$i')];
      return LessonController(
        station: stationOf(words, [ExerciseKind.gozinesh]),
        bundle: bundleOf(words),
        random: Random(1),
      );
    }

    test('پاسخِ درست شمارنده را بالا می‌برد', () {
      final controller = controllerOf();
      controller.answer(correct: true);
      expect(controller.state.correct, 1);
      expect(controller.state.lastAnswerCorrect, isTrue);
      expect(controller.state.wrong, isEmpty);
    });

    test('پاسخِ نادرست واژه را برای مرور نگه می‌دارد و لرزش را برمی‌انگیزد', () {
      final controller = controllerOf();
      final shakeBefore = controller.state.shakeCounter;
      controller.answer(correct: false);
      expect(controller.state.correct, 0);
      expect(controller.state.wrong, hasLength(1));
      expect(controller.state.shakeCounter, shakeBefore + 1);
    });

    test('پاسخِ دوباره به یک پرسش نادیده گرفته می‌شود', () {
      final controller = controllerOf();
      controller
        ..answer(correct: true)
        ..answer(correct: false);
      expect(controller.state.correct, 1);
      expect(controller.state.wrong, isEmpty);
    });

    test('next بازخورد را پاک می‌کند و جلو می‌رود', () {
      final controller = controllerOf();
      controller
        ..answer(correct: true)
        ..next();
      expect(controller.state.index, 1);
      expect(controller.state.lastAnswerCorrect, isNull);
    });

    test('منزل پس از آخرین پرسش تمام می‌شود و آنجا می‌ماند', () {
      final controller = controllerOf();
      for (var i = 0; i < 8; i++) {
        controller
          ..answer(correct: true)
          ..next();
      }
      expect(controller.state.isFinished, isTrue);
      expect(controller.state.current, isNull);
      expect(controller.state.progress, 1.0);

      // فراتر رفتن از پایان نباید چیزی را بشکند.
      controller
        ..next()
        ..answer(correct: false);
      expect(controller.state.index, 8);
    });
  });
}
