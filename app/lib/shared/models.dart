// مدل‌های محتوا.
//
// این کلاس‌ها آینه‌ی طرح‌واره‌ی `content/words/*.yaml` هستند. هر تغییری اینجا
// باید در `core/src/validate.rs` هم بازتاب یابد، وگرنه CI و اپ دو چیز متفاوت
// می‌فهمند.

import 'package:meta/meta.dart';

/// درجه‌ی پذیرشِ یک واژه‌ی سره (بخش ۲).
enum Acceptance {
  /// هنوز در گفتار یا نوشتار به کار می‌رود.
  zende('زنده'),

  /// در متون کهن هست ولی از گفتار افتاده.
  khofte('خفته'),

  /// ساخته‌ی فرهنگستان یا سره‌گرایان معاصر.
  nowsakhte('نوساخته');

  const Acceptance(this.label);
  final String label;

  static Acceptance parse(String value) => Acceptance.values.firstWhere(
        (a) => a.label == value,
        orElse: () => Acceptance.zende,
      );
}

/// وضعیتِ بازبینیِ یک مدخل. بنگرید به content/SOURCES.md.
enum ReviewStatus {
  proposed,
  reviewed,
  verified;

  static ReviewStatus parse(String value) => ReviewStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => ReviewStatus.proposed,
      );
}

@immutable
class WordExample {
  const WordExample({required this.sare, required this.loan});
  final String sare;
  final String loan;
}

@immutable
class Citation {
  const Citation({required this.source, this.ref, this.verse, this.book});
  final String source;
  final String? ref;
  final String? verse;
  final String? book;

  /// یک خط برای نمایش در کارتِ واژه.
  String get display {
    final detail = ref ?? book ?? verse;
    return detail == null ? source : '$source — $detail';
  }
}

@immutable
class Word {
  const Word({
    required this.id,
    required this.sare,
    required this.loan,
    required this.loanOrigin,
    required this.pos,
    required this.acceptance,
    required this.ipa,
    required this.definition,
    required this.english,
    required this.register,
    required this.frequencyRank,
    required this.difficulty,
    required this.examples,
    required this.citations,
    required this.related,
    required this.status,
    this.pahlavi,
    this.avestan,
    this.audio,
  });

  final String id;
  final String sare;
  final String loan;
  final String loanOrigin;
  final String pos;
  final Acceptance acceptance;
  final String ipa;
  final String definition;
  final String english;
  final String register;
  final int frequencyRank;
  final int difficulty;
  final List<WordExample> examples;
  final List<Citation> citations;
  final List<String> related;
  final ReviewStatus status;
  final String? pahlavi;
  final String? avestan;
  final String? audio;

  /// آیا زنجیره‌ی ریشه‌ای برای تمرینِ «ریشه‌یاب» بس است؟
  bool get hasEtymology => pahlavi != null || avestan != null;

  factory Word.fromYaml(Map<dynamic, dynamic> yaml) {
    final roots = (yaml['roots'] as Map<dynamic, dynamic>?) ?? const {};
    return Word(
      id: yaml['id'] as String,
      sare: yaml['sare'] as String,
      loan: yaml['loan'] as String,
      loanOrigin: yaml['loan_origin'] as String,
      pos: yaml['pos'] as String,
      acceptance: Acceptance.parse(yaml['acceptance'] as String),
      ipa: yaml['ipa'] as String,
      definition: yaml['definition'] as String,
      english: yaml['english'] as String,
      register: yaml['register'] as String,
      frequencyRank: yaml['frequency_rank'] as int,
      difficulty: yaml['difficulty'] as int,
      examples: [
        for (final e in (yaml['examples'] as List<dynamic>? ?? const []))
          WordExample(
            sare: (e as Map<dynamic, dynamic>)['sare'] as String,
            loan: e['loan'] as String,
          ),
      ],
      citations: [
        for (final c in (yaml['citations'] as List<dynamic>? ?? const []))
          Citation(
            source: (c as Map<dynamic, dynamic>)['source'] as String,
            ref: c['ref'] as String?,
            verse: c['verse'] as String?,
            book: c['book'] as String?,
          ),
      ],
      related: [
        for (final r in (yaml['related'] as List<dynamic>? ?? const [])) r as String,
      ],
      status: ReviewStatus.parse(yaml['status'] as String? ?? 'proposed'),
      pahlavi: roots['pahlavi'] as String?,
      avestan: roots['avestan'] as String?,
      audio: yaml['audio'] as String?,
    );
  }
}

/// گونه‌های تمرین (بخش ۵٫۳). گونه‌ی هفتم امضای محصول است.
enum ExerciseKind {
  gozinesh('گزینش'),
  joftsaz('جفت‌ساز'),
  jaygozini('جای‌گزینی'),
  vajechin('واژه‌چین'),
  shenidar('شنیدار'),
  goftar('گفتار'),
  beityab('بیت‌یاب'),
  rishehyab('ریشه‌یاب'),
  nevisesh('نویسش'),
  tirArash('تیر آرش'),
  dastanak('داستانک'),
  ruyaruei('رویارویی');

  const ExerciseKind(this.label);
  final String label;

  static ExerciseKind? tryParse(String value) {
    for (final kind in ExerciseKind.values) {
      if (kind.label == value) return kind;
    }
    return null;
  }
}

@immutable
class Station {
  const Station({
    required this.id,
    required this.title,
    required this.exercises,
    required this.wordIds,
  });

  final String id;
  final String title;
  final List<ExerciseKind> exercises;
  final List<String> wordIds;

  factory Station.fromYaml(Map<dynamic, dynamic> yaml) => Station(
        id: yaml['id'] as String,
        title: yaml['title'] as String,
        exercises: [
          for (final e in (yaml['exercises'] as List<dynamic>? ?? const []))
            if (ExerciseKind.tryParse(e as String) case final kind?) kind,
        ],
        wordIds: [
          for (final w in (yaml['words'] as List<dynamic>? ?? const [])) w as String,
        ],
      );
}

/// یکی از هفت خان.
@immutable
class Khan {
  const Khan({
    required this.number,
    required this.id,
    required this.guardian,
    required this.realm,
    required this.stations,
  });

  final int number;
  final String id;

  /// نگهبانِ خان — آزمونِ پایانی به نامِ اوست.
  final String guardian;
  final String realm;
  final List<Station> stations;

  String get title => 'خانِ ${_ordinals[number] ?? '$number'} — $guardian';

  static const Map<int, String> _ordinals = {
    1: 'یکم',
    2: 'دوم',
    3: 'سوم',
    4: 'چهارم',
    5: 'پنجم',
    6: 'ششم',
    7: 'هفتم',
  };

  factory Khan.fromYaml(Map<dynamic, dynamic> yaml) => Khan(
        number: yaml['khan'] as int,
        id: yaml['id'] as String,
        guardian: yaml['guardian'] as String,
        realm: yaml['realm'] as String,
        stations: [
          for (final s in (yaml['stations'] as List<dynamic>? ?? const []))
            Station.fromYaml(s as Map<dynamic, dynamic>),
        ],
      );
}

/// بیتی از پیکره، برای تمرینِ «بیت‌یاب».
@immutable
class Verse {
  const Verse({
    required this.id,
    required this.poet,
    required this.work,
    required this.first,
    required this.second,
    required this.blankSurface,
    required this.blankHemistich,
    this.wordId,
    this.meter,
  });

  final String id;
  final String poet;
  final String work;
  final String first;
  final String second;
  final String blankSurface;

  /// ۱ یا ۲ — کدام مصرع جای خالی دارد.
  final int blankHemistich;
  final String? wordId;

  /// وزنِ عروضی. اگر null باشد ضربِ تنبک پخش نمی‌شود — بهتر از خواندنِ نادرست.
  final String? meter;

  bool get isUsable => wordId != null && blankSurface.isNotEmpty;

  static Verse? tryFromYaml(Map<dynamic, dynamic> yaml, {String? defaultMeter}) {
    final surface = yaml['blank_surface'] as String?;
    final hemistich = yaml['blank_hemistich'] as int?;
    if (surface == null || hemistich == null) return null;
    return Verse(
      id: yaml['id'] as String,
      poet: yaml['poet'] as String,
      work: yaml['work'] as String,
      first: yaml['hemistich_1'] as String,
      second: yaml['hemistich_2'] as String,
      blankSurface: surface,
      blankHemistich: hemistich,
      wordId: yaml['blank_word_id'] as String?,
      meter: (yaml['meter'] as String?) ?? defaultMeter,
    );
  }
}

/// وام‌واژه‌ای که برابرِ جاافتاده ندارد (content/NO_EQUIVALENT.yaml).
///
/// این هم بخشی از محتواست، نه نبودِ محتوا. صداقت، اعتبارِ محصول را می‌سازد.
@immutable
class NoEquivalent {
  const NoEquivalent({
    required this.loan,
    required this.origin,
    required this.reason,
    required this.proposed,
    this.relatedWordId,
  });

  final String loan;
  final String origin;
  final String reason;
  final List<String> proposed;
  final String? relatedWordId;

  factory NoEquivalent.fromYaml(Map<dynamic, dynamic> yaml) => NoEquivalent(
        loan: yaml['loan'] as String,
        origin: yaml['origin'] as String,
        reason: (yaml['reason'] as String).trim(),
        proposed: [
          for (final p in (yaml['proposed'] as List<dynamic>? ?? const [])) p as String,
        ],
        relatedWordId: yaml['has_entry'] as String?,
      );
}
