// آزمونِ پلِ Rust.
//
// این آزمون **به‌راستی** به Rust زنگ می‌زند — بدلی در کار نیست. کتابخانه‌ی
// بومی را از `target/` برمی‌دارد، پس پیش از اجرا باید ساخته شده باشد:
//
//     make bridge
//
// اگر ساخته نشده باشد، آزمون‌ها با پیامی روشن رد می‌شوند، نه با خطای مبهمِ
// بارگذاریِ کتابخانه.
//
// چرا ارزشش را دارد: تا پیش از این، هسته‌ی Rust ۷۵ آزمون داشت و اپ هیچ‌کدام
// از آنها را صدا نمی‌زد. کدِ آزموده‌ای که کسی اجرایش نمی‌کند، کدِ مرده است.

import 'dart:io';

// ExternalLibrary تنها از این درگاه بیرون داده می‌شود.
// ignore: invalid_use_of_internal_member
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sareh/src/rust/api.dart';
import 'package:sareh/src/rust/frb_generated.dart';

/// `<repo>/target/<profile>/libsareh_core.so`
File? _nativeLibrary() {
  var dir = Directory.current;
  while (true) {
    for (final profile in ['release', 'debug']) {
      final file = File('${dir.path}/target/$profile/libsareh_core.so');
      if (file.existsSync()) return file;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

void main() {
  final library = _nativeLibrary();

  setUpAll(() async {
    if (library == null) return;
    await SarehRust.init(
      externalLibrary: ExternalLibrary.open(library.path),
    );
  });

  group('پلِ Rust', skip: library == null ? 'نخست `make bridge` را بزنید' : null,
      () {
    test('نرمال‌سازیِ فارسی از سویِ Dart همان می‌دهد که در Rust', () async {
      // «ي» و «ك» عربی باید فارسی شوند.
      expect(await normalizeText(input: 'كتابي'), 'کتابی');
    });

    test('پاسخِ تایپ‌شده با نیم‌فاصله هم پذیرفته می‌شود', () async {
      expect(
        await answersMatch(typed: 'گفت وگو', expected: 'گفت‌وگو'),
        isTrue,
      );
      expect(await answersMatch(typed: 'سخن', expected: 'دشواری'), isFalse);
    });

    test('اعداد پارسی می‌شوند', () async {
      expect(await persianDigits(input: '1402'), '۱۴۰۲');
    });

    test('نمایه ساخته می‌شود و جست‌وجو نتیجه می‌دهد', () async {
      final built = await buildIndex(
        rows: [
          const WordRow(
            id: 'harf-sokhan',
            sare: 'سخن',
            loan: 'حرف',
            english: 'speech',
          ),
          const WordRow(
            id: 'moshkel-doshvari',
            sare: 'دشواری',
            loan: 'مشکل',
            english: 'problem',
          ),
        ],
      );
      expect(built, 2);

      final hits = await searchWords(query: 'سخن', limit: 5);
      expect(hits, isNotEmpty);
      expect(hits.first.id, 'harf-sokhan');
      expect(hits.first.field, 'sare');
    });

    test('جست‌وجوی بی‌نتیجه فهرستِ تهی می‌دهد، نه خطا', () async {
      await buildIndex(rows: []);
      expect(await searchWords(query: 'هیچ', limit: 5), isEmpty);
    });

    test('درجه از روی رفتار می‌آید، نه از خودسنجی', () async {
      // پاسخِ نادرست همیشه «دوباره» است.
      expect(await rateAnswer(correct: false, answerMs: 500, hesitated: false), 1);
      // پاسخِ درست و سریع و بی‌درنگ، بالاترین درجه.
      final quick = await rateAnswer(correct: true, answerMs: 800, hesitated: false);
      final slow = await rateAnswer(correct: true, answerMs: 9000, hesitated: true);
      expect(quick, greaterThan(slow));
    });

    test('زمان‌بندیِ FSRS از سویِ Dart کار می‌کند', () async {
      final first = await scheduleFirst(ratingCode: 3, desiredRetention: 0.9);
      expect(first.stability, greaterThan(0));
      expect(first.intervalDays, greaterThanOrEqualTo(1));

      final next = await scheduleReview(
        state: ReviewState(
          stability: first.stability,
          difficulty: first.difficulty,
        ),
        elapsedDays: first.intervalDays.toDouble(),
        ratingCode: 3,
        desiredRetention: 0.9,
      );
      expect(
        next.intervalDays,
        greaterThan(first.intervalDays),
        reason: 'پاسخِ درست باید فاصله را بلندتر کند',
      );
    });

    test('یادآوری با گذرِ زمان افت می‌کند', () async {
      const state = ReviewState(stability: 10, difficulty: 5);
      final fresh = await retrievability(state: state, elapsedDays: 0);
      final later = await retrievability(state: state, elapsedDays: 30);
      expect(fresh, greaterThan(later));
      expect(fresh, lessThanOrEqualTo(1.0));
      expect(later, greaterThanOrEqualTo(0.0));
    });
  });
}
