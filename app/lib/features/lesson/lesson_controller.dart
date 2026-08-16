// موتورِ تمرین.
//
// یک منزل را می‌گیرد و پرسش‌ها را می‌سازد. قاعده‌ی بخش ۵٫۳: هر منزل دست‌کم
// چهار گونه‌ی متفاوت دارد — یکنواختی، قاتلِ تداوم است. اگر داده‌ی گونه‌ای نبود
// (مثلاً بیتی برای «بیت‌یاب» نداریم)، آن گونه کنار می‌رود و جایش با گونه‌ای
// پر می‌شود که داده دارد؛ منزل هرگز کوتاه نمی‌آید.
//
// این فایل هیچ ویجتی نمی‌شناسد تا بی‌نیاز از رابط آزمودنی بماند.

import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../../shared/content_repository.dart';
import '../../shared/models.dart';
import '../journey/progress.dart';
import 'review_recorder.dart';

/// یک پرسش. هر گونه‌ی تمرین یک زیرگونه دارد.
@immutable
sealed class Question {
  const Question({required this.word, required this.kind});
  final Word word;
  final ExerciseKind kind;
}

/// گزینش — وام‌واژه داده می‌شود، از میان چهار برابر، سره را برگزین.
@immutable
final class GozineshQuestion extends Question {
  const GozineshQuestion({required super.word, required this.options})
      : super(kind: ExerciseKind.gozinesh);

  final List<String> options;
  String get answer => word.sare;
}

/// جای‌گزینی — جمله‌ای واقعی داده می‌شود؛ روی وام‌واژه ضربه بزن و سره را
/// جایگزین کن.
@immutable
final class JaygoziniQuestion extends Question {
  const JaygoziniQuestion({
    required super.word,
    required this.sentence,
    required this.loanToken,
    required this.options,
  }) : super(kind: ExerciseKind.jaygozini);

  /// جمله‌ی وام‌دار، به‌صورتِ نشانه‌های جدا.
  final List<String> sentence;

  /// نمایه‌ی نشانه‌ای که باید عوض شود.
  final int loanToken;
  final List<String> options;

  String get answer => word.sare;
}

/// جفت‌ساز — دو ستون واژه، خط بکش.
@immutable
final class JoftsazQuestion extends Question {
  const JoftsazQuestion({required super.word, required this.pairs})
      : super(kind: ExerciseKind.joftsaz);

  /// چهار تا شش جفتِ سره/وام که باید به هم وصل شوند.
  final List<Word> pairs;
}

/// بیت‌یاب ⭐ — بیتی با یک جای خالی. امضای محصول.
@immutable
final class BeityabQuestion extends Question {
  const BeityabQuestion({
    required super.word,
    required this.verse,
    required this.options,
  }) : super(kind: ExerciseKind.beityab);

  final Verse verse;
  final List<String> options;

  String get answer => verse.blankSurface;
}

/// یک پله از زنجیره‌ی ریشه — یک زبان و صورتِ واژه در آن.
@immutable
class EtymologyStep {
  const EtymologyStep({required this.language, required this.form});

  /// «اوستایی»، «پارسی باستان»، «پهلوی».
  final String language;

  /// صورتِ آوانویسی‌شده: `druj-`، `rōšn`.
  final String form;
}

/// ریشه‌یاب ⭐ — زنجیره‌ی ریشه‌ی واژه را از صورت‌های به‌هم‌ریخته بازبساز.
///
/// مادرْ‌سند این را «درختِ ریشه‌شناسیِ به‌هم‌ریخته را مرتب کن» نوشته بود. با
/// داده‌ی واقعی آن‌گونه در نمی‌آید: از ۴۷۷ واژه تنها ۳۱ تا بیش از یک صورتِ
/// کهن دارند، و مرتب‌کردنِ زنجیره‌ی دوتایی (پهلوی ← امروز) تمرین نیست.
///
/// پس شکلِ تمرین این است: واژه‌ی امروز داده می‌شود و برای هر زبانِ کهنی که
/// ثبت شده یک جای خالی هست. صورت‌های پیشنهادی، درست‌ها به‌علاوه‌ی فریب‌هایی
/// از **همان زبان**‌اند — صورتِ پهلویِ واژه‌ای دیگر در برابرِ صورتِ پهلوی —
/// وگرنه از روی شکلِ خط هم می‌شد پاسخ داد.
///
/// اوستایی و پارسیِ باستان هم‌دوره‌اند، نه پیاپی. چون هر جای خالی نامِ زبانِ
/// خودش را دارد، از کاربر پرسیده نمی‌شود کدام کهن‌تر است — پرسیده می‌شود کدام
/// صورت از آنِ کدام زبان است. ادعای نادرستی در کار نیست.
@immutable
final class RishehyabQuestion extends Question {
  const RishehyabQuestion({
    required super.word,
    required this.steps,
    required this.options,
  }) : super(kind: ExerciseKind.rishehyab);

  /// پله‌ها، کهن‌ترین نخست. واژه‌ی امروز پله نیست؛ پرسش است.
  final List<EtymologyStep> steps;

  /// صورت‌های به‌هم‌ریخته: درست‌ها و فریب‌های هم‌زبان.
  final List<String> options;

  List<String> get answer => [for (final step in steps) step.form];
}

/// واژه‌چین — جمله‌ای واقعی به کاشی‌های به‌هم‌ریخته شکسته شده؛ دوباره بچینش.
///
/// جمله از نمونه‌های خودِ مدخل می‌آید، پس واژه‌ی سره در بافتی دیده می‌شود که
/// یک آدم نوشته، نه در فهرست.
@immutable
final class VajechinQuestion extends Question {
  const VajechinQuestion({
    required super.word,
    required this.tiles,
    required this.sentence,
  }) : super(kind: ExerciseKind.vajechin);

  /// کاشی‌ها، به‌هم‌ریخته.
  final List<String> tiles;

  /// نشانه‌های جمله به ترتیبِ درست.
  final List<String> sentence;
}

/// نویسش — برابر را بنویس.
///
/// تنها گونه‌ای که پاسخ را تایپ می‌گیرد، پس تنها گونه‌ای که `answers_match`
/// هسته‌ی Rust را به کار می‌برد: نیم‌فاصله، «ی» و «ک» عربی، اعراب و اعداد
/// همه نادیده گرفته می‌شوند. کاربر باید واژه را بداند، نه صفحه‌کلید را.
@immutable
final class NeviseshQuestion extends Question {
  const NeviseshQuestion({required super.word, required this.hint})
      : super(kind: ExerciseKind.nevisesh);

  /// تعریفِ واژه — راهنمای نوشتن.
  final String hint;

  String get answer => word.sare;
}

/// داستانک — پاراگرافی کوتاه با سه جای خالی.
///
/// بافتِ بلندتر از یک جمله: سه جمله‌ی پیاپی که هرکدام یک واژه‌ی منزل را در
/// خود دارند. کاربر هر سه را از یک انبانِ مشترک پر می‌کند، پس نمی‌تواند
/// جای خالی را از روی جای دیگر حدس بزند.
@immutable
final class DastanakQuestion extends Question {
  const DastanakQuestion({
    required super.word,
    required this.blanks,
    required this.options,
  }) : super(kind: ExerciseKind.dastanak);

  /// جمله‌ها به ترتیب؛ در هر کدام جای خالی با [blankMark] نشان شده.
  final List<DastanakBlank> blanks;

  /// انبانِ مشترکِ گزینه‌ها.
  final List<String> options;

  static const String blankMark = '▁▁▁';

  List<String> get answer => [for (final b in blanks) b.answer];
}

@immutable
class DastanakBlank {
  const DastanakBlank({required this.sentence, required this.answer});

  /// جمله با [DastanakQuestion.blankMark] به‌جای واژه.
  final String sentence;
  final String answer;
}

/// تیر آرش — شصت ثانیه، هرچه بیشتر.
///
/// تنها تایمرِ مجازِ سره. ETHICS §۱ شمارشِ معکوس را ممنوع کرده، ولی این را
/// استثنا می‌کند: کاربر خودش واردش شده و پایانش چیزی را نمی‌سوزاند — نه
/// زنجیره‌ای می‌شکند، نه امتیازی پس گرفته می‌شود.
///
/// برخلافِ گونه‌های دیگر، این پرسش چند واژه دارد. هر واژه‌ای که در این شصت
/// ثانیه پاسخ داده شود، جداگانه برای مرورِ فاصله‌دار ثبت می‌شود؛ ولی منزل
/// یک گام جلو می‌رود، نه چند گام.
@immutable
final class TirArashQuestion extends Question {
  const TirArashQuestion({
    required super.word,
    required this.rounds,
    required this.seconds,
    required this.passRatio,
  }) : super(kind: ExerciseKind.tirArash);

  /// پرسش‌های تندِ پیاپی.
  final List<TirArashRound> rounds;
  final int seconds;

  /// نسبتِ درستی که برای «گذراندن» بس است.
  final double passRatio;
}

@immutable
class TirArashRound {
  const TirArashRound({required this.word, required this.options});

  final Word word;
  final List<String> options;

  String get answer => word.sare;
}

@immutable
class LessonState {
  const LessonState({
    required this.stationId,
    required this.questions,
    required this.index,
    required this.correct,
    required this.wrong,
    required this.lastAnswerCorrect,
    required this.shakeCounter,
  });

  final String stationId;
  final List<Question> questions;
  final int index;
  final int correct;

  /// واژه‌هایی که کاربر در آنها لغزید — پایانِ منزل همین‌ها را دوباره می‌آورد.
  final List<Word> wrong;

  /// null یعنی هنوز پاسخ نداده.
  final bool? lastAnswerCorrect;

  /// هر بار افزایش می‌یابد تا لرزشِ پاسخِ نادرست دوباره اجرا شود.
  final int shakeCounter;

  bool get isFinished => index >= questions.length;
  Question? get current => isFinished ? null : questions[index];
  double get progress => questions.isEmpty ? 1 : index / questions.length;

  LessonState copyWith({
    int? index,
    int? correct,
    List<Word>? wrong,
    bool? lastAnswerCorrect,
    bool clearLastAnswer = false,
    int? shakeCounter,
  }) =>
      LessonState(
        stationId: stationId,
        questions: questions,
        index: index ?? this.index,
        correct: correct ?? this.correct,
        wrong: wrong ?? this.wrong,
        lastAnswerCorrect: clearLastAnswer ? null : (lastAnswerCorrect ?? this.lastAnswerCorrect),
        shakeCounter: shakeCounter ?? this.shakeCounter,
      );
}

class LessonController extends StateNotifier<LessonState> {
  LessonController({
    required Station station,
    required ContentBundle bundle,
    Random? random,
    this.recorder,
  }) : super(
          LessonState(
            stationId: station.id,
            questions: buildQuestions(
              station: station,
              bundle: bundle,
              random: random ?? Random(),
            ),
            index: 0,
            correct: 0,
            wrong: const [],
            lastAnswerCorrect: null,
            shakeCounter: 0,
          ),
        );

  /// اگر null باشد، پاسخ‌ها زمان‌بندی نمی‌شوند. آزمون‌های موتور آن را
  /// نمی‌دهند تا بی‌نیاز از پایگاه داده و پل بمانند.
  final ReviewRecorder? recorder;

  DateTime _questionShownAt = DateTime.now();

  /// میلی‌ثانیه‌ای که کاربر روی پرسشِ کنونی گذرانده — خوراکِ درجه‌بندیِ FSRS.
  int get elapsedMs => DateTime.now().difference(_questionShownAt).inMilliseconds;

  void answer({required bool correct}) {
    if (state.isFinished || state.lastAnswerCorrect != null) return;
    final question = state.current!;
    final answerMs = elapsedMs;
    state = state.copyWith(
      correct: correct ? state.correct + 1 : state.correct,
      wrong: correct ? state.wrong : [...state.wrong, question.word],
      lastAnswerCorrect: correct,
      shakeCounter: correct ? state.shakeCounter : state.shakeCounter + 1,
    );
    // زمان‌بندی پشتِ سر انجام می‌شود. بازخوردِ کاربر نباید منتظرِ SQLite و
    // پل بماند؛ دیرکردِ چند میلی‌ثانیه‌ای در نوشتن، هیچ‌کس را نمی‌آزارد،
    // ولی رابطِ کند می‌آزارد.
    unawaited(
      recorder?.record(
        wordId: question.word.id,
        correct: correct,
        answerMs: answerMs,
        exercise: question.kind.label,
      ),
    );
  }

  /// پاسخی که برای مرورِ فاصله‌دار ثبت می‌شود ولی منزل را جلو نمی‌برد.
  ///
  /// «تیر آرش» در شصت ثانیه ده‌ها واژه را از جلوی چشم می‌گذراند. اگر تنها
  /// واژه‌ی لنگرِ آن پرسش ثبت شود، کاربر کار کرده و حافظه‌اش ثبت نشده.
  void practise({
    required Word word,
    required bool correct,
    required int answerMs,
    required ExerciseKind kind,
  }) {
    unawaited(
      recorder?.record(
        wordId: word.id,
        correct: correct,
        answerMs: answerMs,
        exercise: kind.label,
      ),
    );
  }

  /// پس از دیدنِ بازخورد. انیمیشن هیچ‌گاه تعامل را بلوکه نمی‌کند، پس کاربر
  /// می‌تواند پیش از پایانِ جشن این را صدا بزند (بخش ۷٫۴).
  void next() {
    if (state.isFinished) return;
    _questionShownAt = DateTime.now();
    state = state.copyWith(index: state.index + 1, clearLastAnswer: true);
  }

  /// ساختِ پرسش‌ها. جدا و ایستا نگه داشته شده تا مستقل آزمودنی باشد.
  static List<Question> buildQuestions({
    required Station station,
    required ContentBundle bundle,
    required Random random,
  }) {
    final words = bundle.wordsOf(station);
    if (words.isEmpty) return const [];

    final distractorPool = bundle.words.values.toList();
    final questions = <Question>[];
    final kinds = station.exercises.isEmpty ? [ExerciseKind.gozinesh] : station.exercises;

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final kind = kinds[i % kinds.length];
      final built = _build(
        kind: kind,
        word: word,
        words: words,
        pool: distractorPool,
        bundle: bundle,
        random: random,
      );
      // اگر داده‌ی آن گونه نبود، «گزینش» همیشه ممکن است.
      questions.add(built ?? _gozinesh(word, distractorPool, random));
    }
    return questions;
  }

  static Question? _build({
    required ExerciseKind kind,
    required Word word,
    required List<Word> words,
    required List<Word> pool,
    required ContentBundle bundle,
    required Random random,
  }) =>
      switch (kind) {
        ExerciseKind.gozinesh => _gozinesh(word, pool, random),
        ExerciseKind.jaygozini => _jaygozini(word, pool, random),
        ExerciseKind.joftsaz => _joftsaz(word, words, random),
        ExerciseKind.beityab => _beityab(word, bundle, pool, random),
        ExerciseKind.rishehyab => _rishehyab(word, pool, random),
        ExerciseKind.vajechin => _vajechin(word),
        ExerciseKind.nevisesh => _nevisesh(word),
        ExerciseKind.dastanak => _dastanak(word, words, pool, random),
        ExerciseKind.tirArash => _tirArash(word, words, pool, random),
        // «گفتار» به میکروفون نیاز دارد و در مادرْ‌سند اختیاری است؛
        // «رویارویی» به بک‌اند نیاز دارد و فازِ دوم است.
        _ => null,
      };

  static GozineshQuestion _gozinesh(Word word, List<Word> pool, Random random) =>
      GozineshQuestion(
        word: word,
        options: _optionsFor(word, pool, random),
      );

  static JaygoziniQuestion? _jaygozini(Word word, List<Word> pool, Random random) {
    for (final example in word.examples) {
      final tokens = example.loan.split(' ');
      final index = tokens.indexWhere((t) => _stripPunctuation(t).startsWith(word.loan));
      if (index >= 0) {
        return JaygoziniQuestion(
          word: word,
          sentence: tokens,
          loanToken: index,
          options: _optionsFor(word, pool, random),
        );
      }
    }
    return null;
  }

  static JoftsazQuestion? _joftsaz(Word word, List<Word> words, Random random) {
    if (words.length < 4) return null;
    final others = [...words.where((w) => w.id != word.id)]..shuffle(random);
    return JoftsazQuestion(
      word: word,
      pairs: [word, ...others.take(3)]..shuffle(random),
    );
  }

  static BeityabQuestion? _beityab(
    Word word,
    ContentBundle bundle,
    List<Word> pool,
    Random random,
  ) {
    final verses = bundle.versesFor(word.id);
    if (verses.isEmpty) return null;
    final verse = verses[random.nextInt(verses.length)];
    final options = <String>{verse.blankSurface};
    final shuffled = [...pool]..shuffle(random);
    for (final candidate in shuffled) {
      if (options.length == 4) break;
      options.add(candidate.sare);
    }
    return BeityabQuestion(
      word: word,
      verse: verse,
      options: options.toList()..shuffle(random),
    );
  }

  /// چهار گزینه: پاسخِ درست به‌علاوه‌ی سه واژه‌ی سره‌ی دیگر.
  ///
  /// حواس‌پرت‌کن‌ها از واژه‌های هم‌دشواری برداشته می‌شوند تا پرسش نه بی‌معنا
  /// آسان باشد نه ناعادلانه.
  /// کمترین شمارِ کاشی. سه کاشی شش چیدمان دارد — به سختیِ یک گزینشِ
  /// چهارگزینه‌ای، پس تمرین است نه تشریفات. با چهار کاشی، نیمی از واژه‌ها
  /// نمونه‌ی بلندِ کافی ندارند و به گزینش برمی‌گردند؛ با سه، ۹۲٪ می‌سازند.
  static const int _minTiles = 3;

  /// شمارِ جای خالی در داستانک — مادرْ‌سند سه گفته است.
  static const int _dastanakBlanks = 3;

  static const int _tirArashSeconds = 60;
  static const double _tirArashPass = 0.7;
  static const int _tirArashRounds = 12;

  static VajechinQuestion? _vajechin(Word word) {
    for (final example in word.examples) {
      final tokens = example.sare.split(' ').where((t) => t.isNotEmpty).toList();
      if (tokens.length < _minTiles) continue;
      // چرخشی به‌هم می‌ریزیم، نه تصادفی: تضمین می‌کند هیچ کاشی سرِ جای
      // خودش نماند، پس تمرین هیچ‌وقت از پیش حل‌شده نیست.
      final shuffled = [
        for (var i = 0; i < tokens.length; i++) tokens[(i + 1) % tokens.length],
      ];
      return VajechinQuestion(word: word, tiles: shuffled, sentence: tokens);
    }
    return null;
  }

  static NeviseshQuestion _nevisesh(Word word) =>
      NeviseshQuestion(word: word, hint: word.definition);

  static DastanakQuestion? _dastanak(
    Word word,
    List<Word> words,
    List<Word> pool,
    Random random,
  ) {
    // سه واژه‌ی همین منزل، تا داستانک با آنچه کاربر همین‌جا می‌آموزد بخواند.
    final companions = [...words.where((w) => w.id != word.id)]..shuffle(random);
    final chosen = [word, ...companions.take(_dastanakBlanks - 1)];
    if (chosen.length < _dastanakBlanks) return null;

    final blanks = <DastanakBlank>[];
    for (final each in chosen) {
      final example = each.examples
          .where((e) => e.sare.contains(each.sare))
          .firstOrNull;
      if (example == null) return null;
      blanks.add(
        DastanakBlank(
          sentence: example.sare
              .replaceFirst(each.sare, DastanakQuestion.blankMark),
          answer: each.sare,
        ),
      );
    }

    // انبانِ مشترک: پاسخ‌ها به‌علاوه‌ی چند فریب. اگر انبان فقط پاسخ‌ها باشد،
    // جای خالیِ سوم را می‌شود از راهِ حذف پر کرد.
    final options = {for (final b in blanks) b.answer};
    final distractors = [...pool.where((w) => !options.contains(w.sare))]
      ..shuffle(random);
    for (final candidate in distractors) {
      if (options.length >= blanks.length + 2) break;
      options.add(candidate.sare);
    }

    return DastanakQuestion(
      word: word,
      blanks: blanks,
      options: options.toList()..shuffle(random),
    );
  }

  static TirArashQuestion _tirArash(
    Word word,
    List<Word> words,
    List<Word> pool,
    Random random,
  ) {
    final others = [...words.where((w) => w.id != word.id)]..shuffle(random);
    final line = [word, ...others].take(_tirArashRounds).toList();
    return TirArashQuestion(
      word: word,
      rounds: [
        for (final each in line)
          TirArashRound(word: each, options: _optionsFor(each, pool, random)),
      ],
      seconds: _tirArashSeconds,
      passRatio: _tirArashPass,
    );
  }

  /// شمارِ ثابتِ گزینه‌ها. هر چه پله بیشتر، فریب کمتر — تا دشواری با شمارِ
  /// صورت‌های ثبت‌شده بالا و پایین نرود.
  static const int _rishehyabOptions = 5;

  static RishehyabQuestion? _rishehyab(Word word, List<Word> pool, Random random) {
    final steps = <EtymologyStep>[
      if (word.avestan case final form?)
        EtymologyStep(language: 'اوستایی', form: form),
      if (word.oldPersian case final form?)
        EtymologyStep(language: 'پارسی باستان', form: form),
      if (word.pahlavi case final form?)
        EtymologyStep(language: 'پهلوی', form: form),
    ];
    if (steps.isEmpty) return null;

    final correct = {for (final step in steps) step.form};
    final options = {...correct};

    // فریب‌ها به نوبت از زبانِ هر پله می‌آیند، تا هر جای خالی دستِ‌کم یک
    // رقیبِ هم‌زبان داشته باشد.
    final byLanguage = {
      for (final step in steps)
        step.language: pool
            .map((w) => _formIn(w, step.language))
            .whereType<String>()
            .where((form) => !correct.contains(form))
            .toSet()
            .toList()
          ..shuffle(random),
    };
    var round = 0;
    while (options.length < _rishehyabOptions) {
      var added = false;
      for (final step in steps) {
        final candidates = byLanguage[step.language]!;
        if (round < candidates.length) {
          options.add(candidates[round]);
          added = true;
          if (options.length == _rishehyabOptions) break;
        }
      }
      if (!added) break; // پیکره بیش از این صورتِ هم‌زبان ندارد
      round++;
    }

    return RishehyabQuestion(
      word: word,
      steps: steps,
      options: options.toList()..shuffle(random),
    );
  }

  static String? _formIn(Word word, String language) => switch (language) {
        'اوستایی' => word.avestan,
        'پارسی باستان' => word.oldPersian,
        _ => word.pahlavi,
      };

  static List<String> _optionsFor(Word word, List<Word> pool, Random random) {
    final sameDifficulty = pool
        .where((w) => w.id != word.id && (w.difficulty - word.difficulty).abs() <= 1)
        .toList()
      ..shuffle(random);
    final fallback = pool.where((w) => w.id != word.id).toList()..shuffle(random);

    final options = <String>{word.sare};
    for (final candidate in [...sameDifficulty, ...fallback]) {
      if (options.length == 4) break;
      options.add(candidate.sare);
    }
    return options.toList()..shuffle(random);
  }

  static String _stripPunctuation(String token) =>
      token.replaceAll(RegExp(r'[،.؛:؟!«»()]'), '');
}

/// کنترلرِ یک منزل. با شناسه‌ی منزل ساخته می‌شود و با خروج از صفحه می‌میرد.
final lessonControllerProvider =
    StateNotifierProvider.autoDispose.family<LessonController, LessonState, String>(
  (ref, stationId) {
    final bundle = ref.watch(contentProvider).requireValue;
    final station = bundle.khans
        .expand((k) => k.stations)
        .firstWhere((s) => s.id == stationId);
    return LessonController(
      station: station,
      bundle: bundle,
      recorder: ReviewRecorder(ref.watch(progressRepositoryProvider)),
    );
  },
);
