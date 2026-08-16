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
        // گونه‌های دیگر (شنیدار، گفتار، واژه‌چین، ریشه‌یاب، نویسش، تیر آرش،
        // داستانک، رویارویی) روی همین موتور سوار می‌شوند؛ هنوز ساخته نشده‌اند.
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
