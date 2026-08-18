// پایگاه داده‌ی محلی — طرح‌واره‌ی بخش ۴ معماری.
//
// همه‌چیز روی همین دستگاه می‌ماند. هیچ جدولی شناسه‌ی کاربر ندارد و هیچ چیزی
// جایی فرستاده نمی‌شود؛ سره آفلاین‌اول است و تحلیل‌گرِ شخصِ ثالث ندارد
// (docs/ETHICS.md).
//
// چرا Drift و نه یک `Map` در حافظه: پیشرفت باید از بستنِ اپ جان به در ببرد.
// تا پیش از این، هر بار که کاربر اپ را می‌بست، هفت‌خانش از نو آغاز می‌شد و
// زمان‌بندیِ FSRS معنایی نداشت.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// حالتِ حافظه‌ی هر واژه. یک ردیف به‌ازای هر واژه‌ی دیده‌شده.
@DataClassName('WordStateRow')
class WordStates extends Table {
  /// = `content/words/<id>.yaml`
  TextColumn get wordId => text()();

  /// پایداریِ FSRS، به روز.
  RealColumn get stability => real()();

  /// ۱٫۰ تا ۱۰٫۰
  RealColumn get difficulty => real()();

  IntColumn get dueAt => integer()();
  IntColumn get lastReviewAt => integer()();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {wordId};
}

/// تاریخچه‌ی خام. برای بازآموزیِ پارامترهای FSRS روی داده‌ی خودِ کاربر لازم
/// است؛ بی‌آن، بهینه‌سازی ممکن نیست. هرس نمی‌شود.
@DataClassName('ReviewLogRow')
class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get wordId => text().references(WordStates, #wordId)();
  IntColumn get reviewedAt => integer()();

  /// ۱..۴ — دوباره، سخت، خوب، آسان.
  IntColumn get rating => integer()();
  RealColumn get elapsedDays => real()();
  IntColumn get answerMs => integer()();

  /// گزینش، بیت‌یاب، …
  TextColumn get exercise => text()();
}

/// پیشرفت در هفت‌خان.
@DataClassName('StationProgressRow')
class StationProgresses extends Table {
  TextColumn get stationId => text()();

  /// NULL یعنی هنوز تمام نشده.
  IntColumn get completedAt => integer().nullable()();
  RealColumn get bestRatio => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {stationId};
}

/// آتشِ جاویدان و شمارنده‌های بازی. تک‌ردیف.
@DataClassName('StreakRow')
class Streaks extends Table {
  IntColumn get id => integer()();
  IntColumn get currentDays => integer().withDefault(const Constant(0))();
  IntColumn get longestDays => integer().withDefault(const Constant(0))();

  /// تاریخِ محلی `YYYY-MM-DD` — نه unix. زنجیره با «روزِ کاربر» کار دارد؛
  /// کسی که ساعت ۲۳:۵۰ تمرین می‌کند نباید به‌خاطر منطقه‌ی زمانی روزش را ببازد.
  TextColumn get lastActiveOn => text()();

  /// محافظِ زنجیره. بیشینه ۲ — در کد نگه داشته می‌شود، نه تنها در طرح‌واره.
  IntColumn get jamEJam => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'CHECK (id = 1)',
        'CHECK (jam_e_jam BETWEEN 0 AND 2)',
      ];
}

/// فَرّ و گوهر. تک‌ردیف.
@DataClassName('WalletRow')
class Wallets extends Table {
  IntColumn get id => integer()();
  IntColumn get farr => integer().withDefault(const Constant(0))();
  IntColumn get gohar => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = 1)'];
}

/// تنظیمات. کلید/مقدار تا افزودنِ تنظیمِ تازه مهاجرت نخواهد.
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    WordStates,
    ReviewLogs,
    StationProgresses,
    Streaks,
    Wallets,
    Settings,
  ],
)
class SarehDatabase extends _$SarehDatabase {
  SarehDatabase(super.executor);

  /// پایگاه دادهٔ درون‌حافظه برای آزمون‌ها.
  SarehDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // تک‌ردیف‌ها همان آغاز ساخته می‌شوند تا هیچ‌جای کد مجبور نشود
          // «اگر نبود بساز» بنویسد.
          await into(streaks).insert(
            StreaksCompanion.insert(id: const Value(1), lastActiveOn: ''),
          );
          await into(wallets).insert(const WalletsCompanion(id: Value(1)));
        },
        beforeOpen: (details) async {
          // کلیدِ بیگانه در SQLite پیش‌فرض خاموش است؛ بی این، ارجاعِ
          // review_log به word_state تنها یک نظر است، نه یک قاعده.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

/// پایگاه دادهٔ روی دیسک، در پوشه‌ی داده‌ی اپ.
LazyDatabase openOnDisk() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(dir.path, 'sareh.sqlite')),
      );
    });
