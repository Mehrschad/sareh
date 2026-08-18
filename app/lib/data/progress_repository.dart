// لایه‌ی میانِ پایگاه داده و رابط.
//
// صفحه‌ها با جدول کار نمی‌کنند، با این کار می‌کنند. سود: قاعده‌های بازی —
// زنجیره، جامِ جم، فَرّ — یک‌جا می‌نشینند و آزمودنی‌اند، به‌جای اینکه در
// ویجت‌ها پخش شوند.

import 'package:drift/drift.dart';

import 'database.dart';

/// روزِ محلیِ کاربر به‌صورتِ `YYYY-MM-DD`.
///
/// عمداً محلی و نه UTC: زنجیره‌ی روزانه با روزی که کاربر زندگی می‌کند کار
/// دارد. کسی که ساعت ۲۳:۵۰ تمرین می‌کند نباید روزش را به منطقه‌ی زمانی ببازد.
String localDay(DateTime at) => '${at.year.toString().padLeft(4, '0')}-'
    '${at.month.toString().padLeft(2, '0')}-'
    '${at.day.toString().padLeft(2, '0')}';

/// وضعیتِ زنجیره پس از یک روزِ فعال.
enum StreakOutcome {
  /// همان روز، بارِ دوم — چیزی عوض نشد.
  alreadyCounted,

  /// روزِ پیاپی — زنجیره یکی بلندتر شد.
  extended,

  /// روزی جا افتاد ولی جامِ جم آن را پوشاند.
  shielded,

  /// زنجیره شکست و از یک آغاز شد.
  reset,

  /// نخستین روز.
  started,
}

class ProgressRepository {
  ProgressRepository(this.db);

  final SarehDatabase db;

  /// بیشینه‌ی جامِ جم. در کد نگه داشته می‌شود، نه تنها در طرح‌واره.
  static const int maxJamEJam = 2;

  // ─── هفت‌خان ───

  Future<Set<String>> completedStations() async {
    final rows = await (db.select(db.stationProgresses)
          ..where((t) => t.completedAt.isNotNull()))
        .get();
    return rows.map((r) => r.stationId).toSet();
  }

  /// یک منزل را تمام‌شده ثبت می‌کند.
  ///
  /// `bestRatio` هرگز پایین نمی‌آید: اگر کاربر منزلی را دوباره و بدتر بازی
  /// کند، رکوردش نباید خراب شود — وگرنه بازی‌کردنِ دوباره تنبیه می‌شود.
  Future<void> completeStation(String stationId, double ratio) async {
    await db.transaction(() async {
      final previous = await (db.select(db.stationProgresses)
            ..where((t) => t.stationId.equals(stationId)))
          .getSingleOrNull();
      // بیشینه پیش از نوشتن حساب می‌شود. اگر نخست upsert کنیم و بعد MAX
      // بگیریم، رکوردِ پیشین همان upsert از میان رفته است.
      final best =
          (previous?.bestRatio ?? 0) > ratio ? previous!.bestRatio : ratio;
      await db.into(db.stationProgresses).insertOnConflictUpdate(
            StationProgressesCompanion.insert(
              stationId: stationId,
              completedAt: Value(DateTime.now().millisecondsSinceEpoch),
              bestRatio: Value(best),
            ),
          );
    });
  }

  Stream<Set<String>> watchCompletedStations() =>
      (db.select(db.stationProgresses)..where((t) => t.completedAt.isNotNull()))
          .watch()
          .map((rows) => rows.map((r) => r.stationId).toSet());

  // ─── حالتِ واژه‌ها ───

  Future<WordStateRow?> wordState(String wordId) =>
      (db.select(db.wordStates)..where((t) => t.wordId.equals(wordId)))
          .getSingleOrNull();

  /// واژه‌هایی که موعدِ مرورشان رسیده، نزدیک‌ترین موعد نخست.
  Future<List<WordStateRow>> due(DateTime at, {int limit = 50}) => (db
          .select(db.wordStates)
        ..where((t) => t.dueAt.isSmallerOrEqualValue(at.millisecondsSinceEpoch))
        ..orderBy([(t) => OrderingTerm.asc(t.dueAt)])
        ..limit(limit))
      .get();

  /// یک مرور را ثبت می‌کند: هم حالتِ تازه، هم سطری در تاریخچه.
  ///
  /// هر دو در یک تراکنش می‌روند. اگر تاریخچه بنویسد ولی حالت نه، پارامترهای
  /// FSRS بعداً روی داده‌ای بازآموزی می‌شوند که با حالتِ واقعی نمی‌خواند.
  Future<void> recordReview({
    required String wordId,
    required double stability,
    required double difficulty,
    required DateTime dueAt,
    required int rating,
    required double elapsedDays,
    required int answerMs,
    required String exercise,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    await db.transaction(() async {
      final previous = await wordState(wordId);
      final lapsed = rating == 1;
      await db.into(db.wordStates).insertOnConflictUpdate(
            WordStatesCompanion.insert(
              wordId: wordId,
              stability: stability,
              difficulty: difficulty,
              dueAt: dueAt.millisecondsSinceEpoch,
              lastReviewAt: now.millisecondsSinceEpoch,
              reps: Value((previous?.reps ?? 0) + 1),
              lapses: Value((previous?.lapses ?? 0) + (lapsed ? 1 : 0)),
            ),
          );
      await db.into(db.reviewLogs).insert(
            ReviewLogsCompanion.insert(
              wordId: wordId,
              reviewedAt: now.millisecondsSinceEpoch,
              rating: rating,
              elapsedDays: elapsedDays,
              answerMs: answerMs,
              exercise: exercise,
            ),
          );
    });
  }

  Future<List<ReviewLogRow>> history(String wordId) => (db.select(db.reviewLogs)
        ..where((t) => t.wordId.equals(wordId))
        ..orderBy([(t) => OrderingTerm.asc(t.reviewedAt)]))
      .get();

  // ─── زنجیره ───

  Future<StreakRow> streak() =>
      (db.select(db.streaks)..where((t) => t.id.equals(1))).getSingle();

  /// روزِ فعال را ثبت می‌کند و می‌گوید بر سرِ زنجیره چه آمد.
  ///
  /// قاعده‌ها:
  ///   • همان روز، بارِ دوم → هیچ.
  ///   • فردای روزِ پیشین → زنجیره یکی بلندتر.
  ///   • یک روز جا افتاده و جامِ جم داریم → جام خرج می‌شود، زنجیره می‌ماند.
  ///   • وگرنه → از یک آغاز.
  ///
  /// جامِ جم تنها **یک** روزِ جاافتاده را می‌پوشاند. دو روز غیبت یعنی
  /// زنجیره رفته؛ وگرنه «زنجیره» چیزی را نمی‌سنجد.
  Future<StreakOutcome> markActiveDay([DateTime? at]) async {
    final now = at ?? DateTime.now();
    final today = localDay(now);
    final row = await streak();

    if (row.lastActiveOn == today) return StreakOutcome.alreadyCounted;

    final StreakOutcome outcome;
    final int current;
    var jam = row.jamEJam;

    if (row.lastActiveOn.isEmpty) {
      outcome = StreakOutcome.started;
      current = 1;
    } else {
      final gap = _dayGap(row.lastActiveOn, today);
      if (gap == 1) {
        outcome = StreakOutcome.extended;
        current = row.currentDays + 1;
      } else if (gap == 2 && jam > 0) {
        outcome = StreakOutcome.shielded;
        jam -= 1;
        current = row.currentDays + 1;
      } else {
        outcome = StreakOutcome.reset;
        current = 1;
      }
    }

    await (db.update(db.streaks)..where((t) => t.id.equals(1))).write(
      StreaksCompanion(
        currentDays: Value(current),
        longestDays:
            Value(current > row.longestDays ? current : row.longestDays),
        lastActiveOn: Value(today),
        jamEJam: Value(jam),
      ),
    );
    return outcome;
  }

  /// فاصله‌ی دو روزِ محلی، به روز.
  static int _dayGap(String from, String to) {
    final a = DateTime.parse(from);
    final b = DateTime.parse(to);
    return b.difference(a).inDays;
  }

  Future<void> grantJamEJam() async {
    final row = await streak();
    if (row.jamEJam >= maxJamEJam) return;
    await (db.update(db.streaks)..where((t) => t.id.equals(1)))
        .write(StreaksCompanion(jamEJam: Value(row.jamEJam + 1)));
  }

  // ─── کیف ───

  Future<WalletRow> wallet() =>
      (db.select(db.wallets)..where((t) => t.id.equals(1))).getSingle();

  Future<void> earn({int farr = 0, int gohar = 0}) async {
    final row = await wallet();
    await (db.update(db.wallets)..where((t) => t.id.equals(1))).write(
      WalletsCompanion(
        farr: Value(row.farr + farr),
        gohar: Value(row.gohar + gohar),
      ),
    );
  }

  // ─── تنظیمات ───

  Future<String?> setting(String key) async {
    final row = await (db.select(db.settings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> putSetting(String key, String value) =>
      db.into(db.settings).insertOnConflictUpdate(
            SettingsCompanion.insert(key: key, value: value),
          );
}
