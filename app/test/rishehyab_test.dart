// آزمونِ «ریشه‌یاب» — هم ساختِ پرسش، هم رفتارِ ویجت.
//
// دو چیز را نگه می‌دارد که به‌سادگی می‌شکنند: فریب‌ها باید هم‌زبانِ جای خالی
// باشند (وگرنه از روی شکلِ خط هم می‌شود پاسخ داد)، و پس از پاسخ صورتِ درست
// باید دیده شود، حتی اگر کاربر آن را نزده باشد.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sareh/core/theme.dart';
import 'package:sareh/features/lesson/exercises.dart';
import 'package:sareh/features/lesson/lesson_controller.dart';
import 'package:sareh/shared/models.dart';

import 'lesson_controller_test.dart' show bundleOf, stationOf, word;

RishehyabQuestion buildFor(Word target, List<Word> pool, {int seed = 3}) {
  final questions = LessonController.buildQuestions(
    station: stationOf([target], const [ExerciseKind.rishehyab]),
    bundle: bundleOf([target, ...pool]),
    random: Random(seed),
  );
  return questions.single as RishehyabQuestion;
}

/// همان قابی که `lesson_page` به تمرین می‌دهد — از جمله اسکرول، وگرنه
/// آزمون سرریزی می‌بیند که در اپ رخ نمی‌دهد.
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

void main() {
  group('ساختِ پرسشِ ریشه‌یاب', () {
    test('واژه‌ی بی‌ریشه به گزینش برمی‌گردد، نه به پرسشِ خالی', () {
      final questions = LessonController.buildQuestions(
        station: stationOf([word('a')], const [ExerciseKind.rishehyab]),
        bundle: bundleOf([word('a'), word('b'), word('c'), word('d')]),
        random: Random(1),
      );
      expect(questions.single, isA<GozineshQuestion>());
    });

    test('یک صورتِ کهن، یک جای خالی می‌سازد', () {
      final target = word('t', pahlavi: 'dard');
      final question = buildFor(target, [
        word('x', pahlavi: 'rōšn'),
        word('y', pahlavi: 'tan'),
        word('z', pahlavi: 'band'),
      ]);
      expect(question.steps, hasLength(1));
      expect(question.steps.single.language, 'پهلوی');
      expect(question.answer, ['dard']);
    });

    test('زنجیره از کهن به امروز مرتب است', () {
      final target = word(
        't',
        avestan: 'druj-',
        oldPersian: 'drauga',
        pahlavi: 'drōz',
      );
      final question = buildFor(target, [word('x', pahlavi: 'rōšn')]);
      expect(
        question.steps.map((s) => s.language),
        ['اوستایی', 'پارسی باستان', 'پهلوی'],
      );
      expect(question.answer, ['druj-', 'drauga', 'drōz']);
    });

    test('فریب‌ها هم‌زبانِ جای خالی‌اند', () {
      final target = word('t', pahlavi: 'dard');
      final pool = [
        word('x', pahlavi: 'rōšn'),
        word('y', pahlavi: 'tan'),
        word('z', pahlavi: 'band'),
        // اوستایی‌ها نباید بیایند: این واژه جای خالیِ اوستایی ندارد.
        word('q', avestan: 'aēšma-'),
      ];
      final question = buildFor(target, pool);
      expect(question.options, contains('dard'));
      expect(question.options, isNot(contains('aēšma-')));
    });

    test('گزینه‌ها یکتا هستند و پاسخ میانشان است', () {
      final target = word('t', avestan: 'yasna-', pahlavi: 'jašn');
      final question = buildFor(target, [
        word('x', avestan: 'druj-', pahlavi: 'rōšn'),
        word('y', avestan: 'banda-', pahlavi: 'tan'),
      ]);
      expect(question.options.toSet(), hasLength(question.options.length));
      for (final form in question.answer) {
        expect(question.options, contains(form));
      }
    });

    test('پیکره‌ی کم‌مایه پرسش را نمی‌شکند', () {
      // تنها یک صورتِ هم‌زبانِ دیگر در پیکره هست.
      final target = word('t', pahlavi: 'dard');
      final question = buildFor(target, [word('x', pahlavi: 'rōšn')]);
      expect(question.options, hasLength(2));
      expect(question.options, contains('dard'));
    });
  });

  group('ویجتِ ریشه‌یاب', () {
    final target = word('t', avestan: 'druj-', pahlavi: 'drōz');

    testWidgets('چیدنِ درستِ همه‌ی جاها پاسخِ درست می‌دهد', (tester) async {
      final question = buildFor(target, [
        word('x', avestan: 'yasna-', pahlavi: 'rōšn'),
        word('y', avestan: 'banda-', pahlavi: 'tan'),
      ]);
      bool? outcome;
      await tester.pumpWidget(
        host(
          RishehyabExercise(
            question: question,
            onAnswer: ({required correct}) => outcome = correct,
          ),
        ),
      );

      for (final form in question.answer) {
        await tester.tap(find.widgetWithText(GestureDetector, form).last);
        await tester.pump();
      }
      expect(outcome, isTrue);
    });

    testWidgets('چیدنِ نادرست پاسخِ نادرست می‌دهد', (tester) async {
      final question = buildFor(target, [
        word('x', avestan: 'yasna-', pahlavi: 'rōšn'),
        word('y', avestan: 'banda-', pahlavi: 'tan'),
      ]);
      // ترتیبِ وارونه: صورتِ پهلوی در جای اوستایی.
      final wrongOrder = question.answer.reversed.toList();
      bool? outcome;
      await tester.pumpWidget(
        host(
          RishehyabExercise(
            question: question,
            onAnswer: ({required correct}) => outcome = correct,
          ),
        ),
      );

      for (final form in wrongOrder) {
        await tester.tap(find.widgetWithText(GestureDetector, form).last);
        await tester.pump();
      }
      expect(outcome, isFalse);
    });

    testWidgets('پس از پاسخ، صورتِ درست دیده می‌شود', (tester) async {
      final question = buildFor(target, [
        word('x', avestan: 'yasna-', pahlavi: 'rōšn'),
        word('y', avestan: 'banda-', pahlavi: 'tan'),
      ]);
      await tester.pumpWidget(
        host(
          RishehyabExercise(
            question: question,
            onAnswer: ({required correct}) {},
          ),
        ),
      );

      for (final form in question.answer.reversed) {
        await tester.tap(find.widgetWithText(GestureDetector, form).last);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      // هر دو صورتِ درست باید روی زنجیره باشند، هرچند کاربر جابه‌جا گذاشتشان.
      for (final form in question.answer) {
        expect(find.text(form), findsWidgets, reason: 'صورتِ درست: $form');
      }
    });

    testWidgets('واژه‌ی امروز از پیش روی زنجیره است', (tester) async {
      final question = buildFor(target, [word('x', pahlavi: 'rōšn')]);
      await tester.pumpWidget(
        host(
          RishehyabExercise(
            question: question,
            onAnswer: ({required correct}) {},
          ),
        ),
      );
      expect(find.text('امروز'), findsOneWidget);
      expect(find.text(target.sare), findsOneWidget);
    });

    testWidgets('صورتِ گذاشته‌شده را می‌توان برداشت', (tester) async {
      final question = buildFor(target, [
        word('x', avestan: 'yasna-', pahlavi: 'rōšn'),
      ]);
      var answers = 0;
      await tester.pumpWidget(
        host(
          RishehyabExercise(
            question: question,
            onAnswer: ({required correct}) => answers++,
          ),
        ),
      );

      final first = question.answer.first;
      await tester.tap(find.widgetWithText(GestureDetector, first).last);
      await tester.pump();
      // برداشتنِ آن از زنجیره: ضربه روی خودِ حلقه.
      await tester.tap(find.widgetWithText(GestureDetector, first).first);
      await tester.pump();
      expect(answers, 0, reason: 'هنوز زنجیره کامل نشده');
    });
  });
}
