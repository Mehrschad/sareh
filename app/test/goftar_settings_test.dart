// آزمونِ گفتارِ سیمرغ و ماندگاریِ تنظیمات.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sareh/core/settings.dart';
import 'package:sareh/data/database.dart';
import 'package:sareh/data/progress_repository.dart';
import 'package:sareh/features/lesson/goftar.dart';

void main() {
  group('گفتارِ سیمرغ', () {
    test('بی‌لغزش از انبانِ ستایشِ ویژه می‌آید', () {
      final line = Goftar.forStation(
        isPerfect: true,
        hadWrong: false,
        completedBefore: 0,
      );
      expect(Goftar.perfect, contains(line));
    });

    test('منزلِ پرلغزش سطرِ رو به پیش می‌گیرد، نه سرزنش', () {
      final line = Goftar.forStation(
        isPerfect: false,
        hadWrong: true,
        completedBefore: 0,
      );
      expect(Goftar.onward, contains(line));
    });

    test('چرخش قطعی است و دو منزلِ پیاپی یک سطر نمی‌گیرند', () {
      GoftarLine at(int n) => Goftar.forStation(
            isPerfect: false,
            hadWrong: true,
            completedBefore: n,
          );
      expect(at(0), isNot(at(1)));
      expect(at(0), at(Goftar.onward.length), reason: 'چرخش کامل');
    });

    test('تنها سطرهای شاهنامه گوینده دارند', () {
      for (final line in [...Goftar.station, ...Goftar.onward]) {
        expect(line.by, isNull);
      }
      expect(
        Goftar.perfect.where((l) => l.by == 'فردوسی'),
        isNotEmpty,
        reason: 'ستایشِ ویژه بیتِ فردوسی هم دارد',
      );
    });
  });

  group('ماندگاریِ تنظیمات', () {
    late SarehDatabase db;
    late ProgressRepository repo;

    setUp(() {
      db = SarehDatabase.memory();
      repo = ProgressRepository(db);
    });

    tearDown(() => db.close());

    test('هر تغییر می‌ماند و بازخوانی همان را برمی‌گرداند', () async {
      final first = SettingsNotifier(repo);
      await pumpEventQueue();
      first
        ..setSound(on: false)
        ..setDyslexic(on: true)
        ..setThemeMode(ThemeMode.light)
        ..markOnboarded();
      await pumpEventQueue();
      first.dispose();

      final second = SettingsNotifier(repo);
      await pumpEventQueue();
      expect(second.state.sound, isFalse);
      expect(second.state.dyslexic, isTrue);
      expect(second.state.themeMode, ThemeMode.light);
      expect(second.state.onboarded, isTrue);
      second.dispose();
    });

    test('نخستین اجرا: onboarded آشکارا false است، نه null', () async {
      final notifier = SettingsNotifier(repo);
      expect(notifier.state.onboarded, isNull, reason: 'پیش از خواندنِ دیسک');
      await pumpEventQueue();
      expect(notifier.state.onboarded, isFalse, reason: 'پس از خواندنِ دیسک');
      notifier.dispose();
    });
  });
}
