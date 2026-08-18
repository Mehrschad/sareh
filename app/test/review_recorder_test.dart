// آزمونِ حلقه‌ی کامل: رفتارِ کاربر → FSRS در Rust → ردیفی در SQLite.
//
// هیچ‌کدام از سه تکه بدل نیستند. اگر این آزمون سبز باشد، مرورِ فاصله‌دار
// به‌راستی کار می‌کند؛ اگر نه، جایی در زنجیره پاره است.
//
// نیازمندِ `make bridge` است — بنگرید به rust_bridge_test.dart.

import 'dart:io';

// ignore: invalid_use_of_internal_member
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sareh/data/database.dart';
import 'package:sareh/data/progress_repository.dart';
import 'package:sareh/features/lesson/review_recorder.dart';
import 'package:sareh/src/rust/frb_generated.dart';

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
  late SarehDatabase db;
  late ProgressRepository repo;
  late ReviewRecorder recorder;

  setUpAll(() async {
    if (library == null) return;
    await SarehRust.init(externalLibrary: ExternalLibrary.open(library.path));
  });

  setUp(() {
    db = SarehDatabase.memory();
    repo = ProgressRepository(db);
    recorder = ReviewRecorder(repo);
  });

  tearDown(() => db.close());

  group(
    'ثبتِ مرور',
    skip: library == null ? 'نخست `make bridge` را بزنید' : null,
    () {
      test('نخستین پاسخ، واژه را زمان‌بندی می‌کند', () async {
        final due = await recorder.record(
          wordId: 'harf-sokhan',
          correct: true,
          answerMs: 1500,
          exercise: 'گزینش',
        );
        expect(due.isAfter(DateTime.now()), isTrue);

        final state = await repo.wordState('harf-sokhan');
        expect(state, isNotNull);
        expect(state!.stability, greaterThan(0));
        expect(state.reps, 1);
        expect(state.lapses, 0);
      });

      test('پاسخِ نادرست لغزش می‌شود و موعد را نزدیک می‌کند', () async {
        final good = await recorder.record(
          wordId: 'a',
          correct: true,
          answerMs: 1200,
          exercise: 'گزینش',
        );
        final bad = await recorder.record(
          wordId: 'b',
          correct: false,
          answerMs: 1200,
          exercise: 'گزینش',
        );
        expect(
          bad.isBefore(good),
          isTrue,
          reason: 'واژه‌ای که ندانستی زودتر باید برگردد',
        );
        expect((await repo.wordState('b'))!.lapses, 1);
      });

      test('پاسخِ سریع فاصله‌ی بلندتری از پاسخِ کند می‌گیرد', () async {
        final quick = await recorder.record(
          wordId: 'q',
          correct: true,
          answerMs: 900, // زیر ۲٫۵ ثانیه → «آسان»
          exercise: 'گزینش',
        );
        final slow = await recorder.record(
          wordId: 's',
          correct: true,
          answerMs: 9000, // بالای ۸ ثانیه → «سخت»
          exercise: 'گزینش',
        );
        expect(quick.isAfter(slow), isTrue);
      });

      test('مرورِ دوم روی حالتِ پیشین سوار می‌شود', () async {
        final start = DateTime(2026, 4, 1);
        await recorder.record(
          wordId: 'w',
          correct: true,
          answerMs: 1500,
          exercise: 'گزینش',
          at: start,
        );
        final first = await repo.wordState('w');

        await recorder.record(
          wordId: 'w',
          correct: true,
          answerMs: 1500,
          exercise: 'بیت‌یاب',
          at: start.add(const Duration(days: 3)),
        );
        final second = await repo.wordState('w');

        expect(second!.reps, 2);
        expect(
          second.stability,
          greaterThan(first!.stability),
          reason: 'یادآوریِ درست باید پایداری را بالا ببرد',
        );

        final log = await repo.history('w');
        expect(log, hasLength(2));
        expect(log.last.exercise, 'بیت‌یاب');
        expect(
          log.last.elapsedDays,
          closeTo(3, 0.01),
          reason: 'فاصله‌ی واقعی ثبت می‌شود، نه فاصله‌ی برنامه‌ریزی‌شده',
        );
      });

      test('واژه‌ی زمان‌بندی‌شده در فهرستِ موعدرسیده می‌آید', () async {
        final start = DateTime(2026, 4, 1);
        await recorder.record(
          wordId: 'w',
          correct: true,
          answerMs: 1500,
          exercise: 'گزینش',
          at: start,
        );
        expect(await repo.due(start), isEmpty);
        final much = start.add(const Duration(days: 3650));
        expect((await repo.due(much)).map((r) => r.wordId), ['w']);
      });
    },
  );
}
