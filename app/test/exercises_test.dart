// آزمونِ چهار گونه‌ی تازه: واژه‌چین، نویسش، داستانک، تیر آرش.
//
// هیچ‌کدام به پل یا پایگاه داده نیاز ندارند: سنجه‌گرِ «نویسش» تزریق می‌شود و
// «تیر آرش» با `onPractice` بدلی سنجیده می‌شود.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sareh/core/theme.dart';
import 'package:sareh/features/lesson/exercises.dart';
import 'package:sareh/features/lesson/lesson_controller.dart';
import 'package:sareh/shared/models.dart';

import 'lesson_controller_test.dart' show bundleOf, stationOf, word;

Widget host(Widget child) => MaterialApp(
      theme: SarehThemeData.dark(),
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

WordExample sentence(String sare) => WordExample(sare: sare, loan: sare);

Question buildOne(
  List<Word> words,
  ExerciseKind kind, {
  int seed = 5,
  List<Word> extra = const [],
}) =>
    LessonController.buildQuestions(
      station: stationOf(words, [kind]),
      bundle: bundleOf([...words, ...extra]),
      random: Random(seed),
    ).first;

void main() {
  group('واژه‌چین', () {
    final target = word(
      't',
      sare: 'سخن',
      examples: [sentence('سخنِ او درست بود')],
    );

    test('جمله به کاشی شکسته می‌شود', () {
      final q = buildOne([target], ExerciseKind.vajechin) as VajechinQuestion;
      expect(q.sentence, ['سخنِ', 'او', 'درست', 'بود']);
      expect(q.tiles.toSet(), q.sentence.toSet());
    });

    test('هیچ کاشی سرِ جای خودش نمی‌ماند', () {
      final q = buildOne([target], ExerciseKind.vajechin) as VajechinQuestion;
      for (var i = 0; i < q.tiles.length; i++) {
        expect(q.tiles[i], isNot(q.sentence[i]), reason: 'کاشی $i جابه‌جا نشده');
      }
    });

    test('جمله‌ی کوتاه به گزینش برمی‌گردد', () {
      final short = word('s', examples: [sentence('کوتاه بود')]);
      expect(
        buildOne([short], ExerciseKind.vajechin, extra: [word('a'), word('b')]),
        isA<GozineshQuestion>(),
      );
    });

    testWidgets('چیدنِ درست، پاسخِ درست می‌دهد', (tester) async {
      final q = buildOne([target], ExerciseKind.vajechin) as VajechinQuestion;
      bool? outcome;
      await tester.pumpWidget(
        host(
          VajechinExercise(
            question: q,
            onAnswer: ({required correct}) => outcome = correct,
          ),
        ),
      );
      for (final token in q.sentence) {
        await tester.tap(find.widgetWithText(GestureDetector, token).last);
        await tester.pump();
      }
      expect(outcome, isTrue);
    });

    testWidgets('چیدنِ وارونه، پاسخِ نادرست می‌دهد', (tester) async {
      final q = buildOne([target], ExerciseKind.vajechin) as VajechinQuestion;
      bool? outcome;
      await tester.pumpWidget(
        host(
          VajechinExercise(
            question: q,
            onAnswer: ({required correct}) => outcome = correct,
          ),
        ),
      );
      for (final token in q.sentence.reversed) {
        await tester.tap(find.widgetWithText(GestureDetector, token).last);
        await tester.pump();
      }
      expect(outcome, isFalse);
    });
  });

  group('نویسش', () {
    final target = word('t', sare: 'دشواری', loan: 'مشکل');

    testWidgets('پاسخِ درست پذیرفته می‌شود', (tester) async {
      final q = buildOne([target], ExerciseKind.nevisesh) as NeviseshQuestion;
      bool? outcome;
      await tester.pumpWidget(
        host(
          NeviseshExercise(
            question: q,
            onAnswer: ({required correct}) => outcome = correct,
            grader: ({required typed, required expected}) async =>
                typed.trim() == expected,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'دشواری');
      await tester.tap(find.text('بسنج'));
      await tester.pumpAndSettle();
      expect(outcome, isTrue);
    });

    testWidgets('پاسخِ نادرست، برابرِ درست را نشان می‌دهد', (tester) async {
      final q = buildOne([target], ExerciseKind.nevisesh) as NeviseshQuestion;
      await tester.pumpWidget(
        host(
          NeviseshExercise(
            question: q,
            onAnswer: ({required correct}) {},
            grader: ({required typed, required expected}) async => false,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'چیزِ دیگر');
      await tester.tap(find.text('بسنج'));
      await tester.pumpAndSettle();
      expect(find.text('دشواری'), findsOneWidget);
    });

    testWidgets('ورودیِ تهی چیزی را ثبت نمی‌کند', (tester) async {
      final q = buildOne([target], ExerciseKind.nevisesh) as NeviseshQuestion;
      var answers = 0;
      await tester.pumpWidget(
        host(
          NeviseshExercise(
            question: q,
            onAnswer: ({required correct}) => answers++,
            grader: ({required typed, required expected}) async => true,
          ),
        ),
      );
      await tester.tap(find.text('بسنج'));
      await tester.pumpAndSettle();
      expect(answers, 0);
    });
  });

  group('داستانک', () {
    List<Word> trio() => [
          word('a', sare: 'سخن', examples: [sentence('سخن او کوتاه بود')]),
          word('b', sare: 'دشواری', examples: [sentence('دشواری کار پیدا شد')]),
          word('c', sare: 'بها', examples: [sentence('بها را پرسیدم')]),
        ];

    test('سه جای خالی می‌سازد و واژه را از جمله برمی‌دارد', () {
      final q = buildOne(trio(), ExerciseKind.dastanak) as DastanakQuestion;
      expect(q.blanks, hasLength(3));
      for (final blank in q.blanks) {
        expect(blank.sentence, contains(DastanakQuestion.blankMark));
        expect(blank.sentence, isNot(contains(blank.answer)));
      }
    });

    test('انبان فریب هم دارد، وگرنه سومی از راهِ حذف پر می‌شود', () {
      final q = buildOne(
        trio(),
        ExerciseKind.dastanak,
        extra: [word('d', sare: 'رهنمود'), word('e', sare: 'گستره')],
      ) as DastanakQuestion;
      expect(q.options.length, greaterThan(q.blanks.length));
      for (final answer in q.answer) {
        expect(q.options, contains(answer));
      }
    });

    testWidgets('پر کردنِ درستِ هر سه، پاسخِ درست می‌دهد', (tester) async {
      final q = buildOne(trio(), ExerciseKind.dastanak) as DastanakQuestion;
      bool? outcome;
      await tester.pumpWidget(
        host(
          DastanakExercise(
            question: q,
            onAnswer: ({required correct}) => outcome = correct,
          ),
        ),
      );
      for (final answer in q.answer) {
        await tester.tap(find.widgetWithText(GestureDetector, answer).last);
        await tester.pump();
      }
      expect(outcome, isTrue);
    });
  });

  group('تیر آرش', () {
    List<Word> squad() => [
          for (var i = 0; i < 5; i++) word('w$i', sare: 'سره$i', loan: 'وام$i'),
        ];

    test('چند دور می‌سازد و شصت ثانیه وقت می‌دهد', () {
      final q = buildOne(squad(), ExerciseKind.tirArash) as TirArashQuestion;
      expect(q.seconds, 60);
      expect(q.rounds.length, greaterThan(1));
      expect(q.rounds.first.word.id, 'w0', reason: 'واژه‌ی لنگر نخست می‌آید');
      for (final round in q.rounds) {
        expect(round.options, contains(round.answer));
      }
    });

    testWidgets('تا رها نکنی، تایمر نمی‌شمارد', (tester) async {
      final q = buildOne(squad(), ExerciseKind.tirArash) as TirArashQuestion;
      await tester.pumpWidget(
        host(
          TirArashExercise(question: q, onAnswer: ({required correct}) {}),
        ),
      );
      expect(find.text('رها کن'), findsOneWidget);
      // تایمر هنوز نرفته؛ اگر رفته بود، pump بعدی می‌شمرد.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('رها کن'), findsOneWidget);
    });

    testWidgets('هر دور جداگانه برای مرور ثبت می‌شود', (tester) async {
      final q = buildOne(squad(), ExerciseKind.tirArash) as TirArashQuestion;
      final practised = <String>[];
      await tester.pumpWidget(
        host(
          TirArashExercise(
            question: q,
            onAnswer: ({required correct}) {},
            onPractice: (w, {required correct, required answerMs}) =>
                practised.add(w.id),
          ),
        ),
      );
      await tester.tap(find.text('رها کن'));
      await tester.pump();

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text(q.rounds[i].answer).last);
        await tester.pump();
      }
      expect(practised, ['w0', q.rounds[1].word.id, q.rounds[2].word.id]);
      // تایمر را می‌بندیم تا آزمون با ساعتِ باز تمام نشود.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('پایانِ دورها کارنامه را نشان می‌دهد', (tester) async {
      final short = squad().take(2).toList();
      final q = buildOne(short, ExerciseKind.tirArash) as TirArashQuestion;
      bool? outcome;
      await tester.pumpWidget(
        host(
          TirArashExercise(
            question: q,
            onAnswer: ({required correct}) => outcome = correct,
          ),
        ),
      );
      await tester.tap(find.text('رها کن'));
      await tester.pump();
      for (final round in q.rounds) {
        await tester.tap(find.text(round.answer).last);
        await tester.pump();
      }
      expect(outcome, isTrue, reason: 'همه درست بود');
      expect(find.textContaining('درست'), findsWidgets);
    });
  });
}
