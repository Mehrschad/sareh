// آزمونِ ماندگاری.
//
// روی SQLite واقعی (درون‌حافظه) اجرا می‌شود، نه روی بدل. قاعده‌های زنجیره و
// جامِ جم اینجا نگه داشته می‌شوند — همان‌هایی که ETHICS.md وعده داده است.

import 'package:flutter_test/flutter_test.dart';
import 'package:sareh/data/database.dart';
import 'package:sareh/data/progress_repository.dart';

void main() {
  late SarehDatabase db;
  late ProgressRepository repo;

  setUp(() {
    db = SarehDatabase.memory();
    repo = ProgressRepository(db);
  });

  tearDown(() => db.close());

  group('منزل‌ها', () {
    test('پیشرفت از بستنِ اپ جان به در می‌برد', () async {
      expect(await repo.completedStations(), isEmpty);
      await repo.completeStation('khan-1-shir-manzel-1', 0.9);
      expect(await repo.completedStations(), {'khan-1-shir-manzel-1'});
    });

    test('بازیِ دوباره‌ی بدتر، رکورد را خراب نمی‌کند', () async {
      await repo.completeStation('m1', 0.9);
      await repo.completeStation('m1', 0.4);
      final row = await (db.select(db.stationProgresses)
            ..where((t) => t.stationId.equals('m1')))
          .getSingle();
      expect(row.bestRatio, 0.9);
    });

    test('رکوردِ بهتر بالا می‌رود', () async {
      await repo.completeStation('m1', 0.4);
      await repo.completeStation('m1', 0.95);
      final row = await (db.select(db.stationProgresses)
            ..where((t) => t.stationId.equals('m1')))
          .getSingle();
      expect(row.bestRatio, 0.95);
    });
  });

  group('مرورِ واژه', () {
    Future<void> review(String id, {int rating = 3, DateTime? at}) =>
        repo.recordReview(
          wordId: id,
          stability: 3.2,
          difficulty: 5.0,
          dueAt: (at ?? DateTime.now()).add(const Duration(days: 3)),
          rating: rating,
          elapsedDays: 1,
          answerMs: 1800,
          exercise: 'گزینش',
          at: at,
        );

    test('حالت و تاریخچه با هم نوشته می‌شوند', () async {
      await review('harf-sokhan');
      final state = await repo.wordState('harf-sokhan');
      expect(state, isNotNull);
      expect(state!.reps, 1);
      expect(await repo.history('harf-sokhan'), hasLength(1));
    });

    test('تکرار شمرده می‌شود و لغزش جدا', () async {
      await review('w', rating: 3);
      await review('w', rating: 1);
      await review('w', rating: 4);
      final state = await repo.wordState('w');
      expect(state!.reps, 3);
      expect(state.lapses, 1, reason: 'تنها درجه‌ی ۱ لغزش است');
    });

    test('تاریخچه هرس نمی‌شود', () async {
      for (var i = 0; i < 5; i++) {
        await review('w', at: DateTime(2026, 1, i + 1));
      }
      expect(await repo.history('w'), hasLength(5));
    });

    test('موعدرسیده‌ها به ترتیبِ موعد می‌آیند', () async {
      final now = DateTime(2026, 5, 1);
      for (final (id, days) in [('a', -3), ('b', -1), ('c', 5)]) {
        await repo.recordReview(
          wordId: id,
          stability: 1,
          difficulty: 5,
          dueAt: now.add(Duration(days: days)),
          rating: 3,
          elapsedDays: 1,
          answerMs: 1000,
          exercise: 'گزینش',
          at: now,
        );
      }
      final due = await repo.due(now);
      expect(
        due.map((r) => r.wordId),
        ['a', 'b'],
        reason: 'c هنوز موعدش نرسیده',
      );
    });

    test('تاریخچه بی‌حالتِ واژه نوشته نمی‌شود', () async {
      // کلیدِ بیگانه روشن است؛ سطرِ یتیم باید رد شود.
      await expectLater(
        db.into(db.reviewLogs).insert(
              ReviewLogsCompanion.insert(
                wordId: 'واژه‌ای که نیست',
                reviewedAt: 0,
                rating: 3,
                elapsedDays: 1,
                answerMs: 100,
                exercise: 'گزینش',
              ),
            ),
        throwsA(anything),
      );
    });
  });

  group('زنجیره', () {
    test('نخستین روز زنجیره را آغاز می‌کند', () async {
      expect(
        await repo.markActiveDay(DateTime(2026, 3, 1)),
        StreakOutcome.started,
      );
      expect((await repo.streak()).currentDays, 1);
    });

    test('دو بار در یک روز، دو روز نمی‌شود', () async {
      await repo.markActiveDay(DateTime(2026, 3, 1, 9));
      expect(
        await repo.markActiveDay(DateTime(2026, 3, 1, 21)),
        StreakOutcome.alreadyCounted,
      );
      expect((await repo.streak()).currentDays, 1);
    });

    test('روزِ پیاپی زنجیره را بلند می‌کند', () async {
      await repo.markActiveDay(DateTime(2026, 3, 1));
      await repo.markActiveDay(DateTime(2026, 3, 2));
      expect(
        await repo.markActiveDay(DateTime(2026, 3, 3)),
        StreakOutcome.extended,
      );
      expect((await repo.streak()).currentDays, 3);
    });

    test('نیمه‌شب زنجیره را نمی‌شکند', () async {
      // ۲۳:۵۰ و بعد ۰۰:۱۰ — دو روزِ محلیِ پیاپی، نه یک شکاف.
      await repo.markActiveDay(DateTime(2026, 3, 1, 23, 50));
      expect(
        await repo.markActiveDay(DateTime(2026, 3, 2, 0, 10)),
        StreakOutcome.extended,
      );
      expect((await repo.streak()).currentDays, 2);
    });

    test('بی‌جامِ جم، یک روز غیبت زنجیره را می‌شکند', () async {
      await repo.markActiveDay(DateTime(2026, 3, 1));
      expect(
        await repo.markActiveDay(DateTime(2026, 3, 3)),
        StreakOutcome.reset,
      );
      expect((await repo.streak()).currentDays, 1);
    });

    test('جامِ جم یک روزِ جاافتاده را می‌پوشاند و خرج می‌شود', () async {
      await repo.grantJamEJam();
      await repo.markActiveDay(DateTime(2026, 3, 1));
      expect(
        await repo.markActiveDay(DateTime(2026, 3, 3)),
        StreakOutcome.shielded,
      );
      final row = await repo.streak();
      expect(row.currentDays, 2);
      expect(row.jamEJam, 0, reason: 'جام خرج شد');
    });

    test('جامِ جم دو روزِ غیبت را نمی‌پوشاند', () async {
      await repo.grantJamEJam();
      await repo.markActiveDay(DateTime(2026, 3, 1));
      expect(
        await repo.markActiveDay(DateTime(2026, 3, 4)),
        StreakOutcome.reset,
      );
      expect((await repo.streak()).jamEJam, 1, reason: 'جام خرج نشد');
    });

    test('جامِ جم از دو بیشتر نمی‌شود', () async {
      for (var i = 0; i < 5; i++) {
        await repo.grantJamEJam();
      }
      expect((await repo.streak()).jamEJam, ProgressRepository.maxJamEJam);
    });

    test('بلندترین زنجیره پایین نمی‌آید', () async {
      await repo.markActiveDay(DateTime(2026, 3, 1));
      await repo.markActiveDay(DateTime(2026, 3, 2));
      await repo.markActiveDay(DateTime(2026, 3, 3));
      await repo.markActiveDay(DateTime(2026, 3, 20)); // شکست
      final row = await repo.streak();
      expect(row.currentDays, 1);
      expect(row.longestDays, 3);
    });
  });

  group('کیف و تنظیمات', () {
    test('فَرّ و گوهر جمع می‌شوند', () async {
      await repo.earn(farr: 10);
      await repo.earn(farr: 5, gohar: 2);
      final w = await repo.wallet();
      expect(w.farr, 15);
      expect(w.gohar, 2);
    });

    test('تنظیم نوشته و خوانده می‌شود', () async {
      expect(await repo.setting('theme'), isNull);
      await repo.putSetting('theme', 'dark');
      await repo.putSetting('theme', 'light');
      expect(await repo.setting('theme'), 'light');
    });

    test('تک‌ردیف‌ها همان آغاز هستند', () async {
      expect((await repo.wallet()).id, 1);
      expect((await repo.streak()).id, 1);
    });
  });
}
