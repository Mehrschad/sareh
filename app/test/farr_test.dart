// آزمونِ فَرّ — قاعده‌های امتیاز، از پاسخ تا کیف.
//
// سه لایه: قاعده‌ی خالص (FarrRules)، انباشت در موتورِ تمرین
// (LessonController)، و ریختن به کیف هنگامِ پایانِ منزل (ProgressNotifier
// با پایگاهِ درون‌حافظه).

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sareh/data/database.dart';
import 'package:sareh/data/progress_repository.dart';
import 'package:sareh/features/journey/progress.dart';
import 'package:sareh/features/lesson/lesson_controller.dart';
import 'package:sareh/shared/models.dart';

import 'lesson_controller_test.dart' show bundleOf, stationOf, word;

LessonController controllerOf(List<Word> words) => LessonController(
      station: stationOf(words, const [ExerciseKind.gozinesh]),
      bundle: bundleOf(words),
      random: Random(1),
    );

List<Word> squad(int n) =>
    [for (var i = 0; i < n; i++) word('w$i', sare: 'سره$i', loan: 'وام$i')];

void main() {
  group('FarrRules', () {
    test('زیرِ آستانه، پایه؛ از آستانه به بعد، پایه + پاداش', () {
      expect(FarrRules.gain(1), FarrRules.correct);
      expect(FarrRules.gain(FarrRules.comboThreshold - 1), FarrRules.correct);
      expect(
        FarrRules.gain(FarrRules.comboThreshold),
        FarrRules.correct + FarrRules.comboBonus,
      );
    });
  });

  group('انباشتِ فَرّ در منزل', () {
    test('سه درستِ پیاپی: دو پایه و یکی با پاداشِ زنجیره', () {
      final controller = controllerOf(squad(6));
      for (var i = 0; i < 3; i++) {
        controller.answer(correct: true);
        controller.next();
      }
      expect(
        controller.state.farr,
        FarrRules.correct * 3 + FarrRules.comboBonus,
      );
      expect(controller.state.comboRun, 3);
    });

    test('پاسخِ نادرست زنجیره را صفر می‌کند ولی فَرّ را نمی‌کاهد', () {
      final controller = controllerOf(squad(6));
      controller.answer(correct: true);
      controller.next();
      final before = controller.state.farr;
      controller.answer(correct: false);
      controller.next();
      expect(controller.state.farr, before, reason: 'فَرّ هرگز کم نمی‌شود');
      expect(controller.state.comboRun, 0);
      expect(controller.state.lastGain, 0);
    });

    test('lastGain فَرِّ همان پاسخ را می‌گوید', () {
      final controller = controllerOf(squad(6));
      controller.answer(correct: true);
      expect(controller.state.lastGain, FarrRules.correct);
    });

    test('practise تنها برای درست، فَرِّ کوچک می‌دهد', () {
      final controller = controllerOf(squad(6));
      final target = controller.state.questions.first.word;
      controller.practise(
        word: target,
        correct: true,
        answerMs: 900,
        kind: ExerciseKind.tirArash,
      );
      controller.practise(
        word: target,
        correct: false,
        answerMs: 900,
        kind: ExerciseKind.tirArash,
      );
      expect(controller.state.farr, FarrRules.practise);
    });
  });

  group('پایانِ منزل و کیف', () {
    late SarehDatabase db;
    late ProgressRepository repo;

    setUp(() {
      db = SarehDatabase.memory();
      repo = ProgressRepository(db);
    });

    tearDown(() => db.close());

    test('منزلِ معمولی: فَرِّ منزل + پاداشِ پایان، بی‌گوهر', () async {
      final notifier = ProgressNotifier(repo);
      await notifier.completeStation('m1', ratio: 0.8, earnedFarr: 55);
      final wallet = await repo.wallet();
      expect(wallet.farr, 55 + FarrRules.station);
      expect(wallet.gohar, 0);
    });

    test('منزلِ بی‌لغزش: پاداشِ افزوده و یک گوهر', () async {
      final notifier = ProgressNotifier(repo);
      await notifier.completeStation(
        'm1',
        earnedFarr: 80,
        perfect: true,
      );
      final wallet = await repo.wallet();
      expect(
        wallet.farr,
        80 + FarrRules.station + FarrRules.perfectBonus,
      );
      expect(wallet.gohar, FarrRules.perfectGohar);
    });

    test('watchWallet با هر واریز تازه می‌شود', () async {
      final seen = <int>[];
      final sub = repo.watchWallet().listen((w) => seen.add(w.farr));
      await repo.earn(farr: 10);
      await repo.earn(farr: 5);
      await pumpEventQueue();
      await sub.cancel();
      expect(seen.last, 15);
    });
  });
}
