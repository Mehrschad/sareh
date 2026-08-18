// جایی که پاسخِ کاربر به زمان‌بندیِ مرور تبدیل می‌شود.
//
// این تنها حلقه‌ای است که هر سه تکه را به هم می‌بندد: رفتارِ کاربر (درست بود؟
// چند میلی‌ثانیه طول کشید؟) → FSRS در Rust → ردیفی در SQLite.
//
// **درجه از رفتار می‌آید، نه از خودسنجی.** هیچ‌جا از کاربر پرسیده نمی‌شود
// «چقدر سخت بود؟». پرسیدن، هم جریانِ تمرین را می‌شکند و هم پاسخِ صادقانه
// نمی‌گیرد؛ زمانِ پاسخ سنجه‌ی بهتری است (docs/ETHICS.md).

import '../../data/progress_repository.dart';
import '../../src/rust/api.dart';

class ReviewRecorder {
  const ReviewRecorder(this._repository, {this.desiredRetention = 0.9});

  final ProgressRepository _repository;

  /// نسبتِ یادسپاریِ هدف. ۰٫۹ یعنی «می‌خواهم هنگامِ مرور، ۹۰٪ را به یاد
  /// بیاورم». بالاتر بردنش یعنی مرورِ بیشتر و کارِ بیشتر.
  final double desiredRetention;

  static const int _msPerDay = 24 * 60 * 60 * 1000;

  /// یک پاسخ را ثبت می‌کند و موعدِ مرورِ بعدی را برمی‌گرداند.
  ///
  /// اگر واژه پیش‌تر دیده نشده باشد، `schedule_first` است؛ وگرنه
  /// `schedule_review` با فاصله‌ی واقعی از آخرین دیدار — نه با فاصله‌ی
  /// برنامه‌ریزی‌شده. کاربری که سه روز دیر آمده، سه روز دیر آمده.
  Future<DateTime> record({
    required String wordId,
    required bool correct,
    required int answerMs,
    required String exercise,
    bool hesitated = false,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    final rating = await rateAnswer(
      correct: correct,
      answerMs: answerMs,
      hesitated: hesitated,
    );

    final previous = await _repository.wordState(wordId);
    final double elapsedDays;
    final ReviewOutcome outcome;
    if (previous == null) {
      elapsedDays = 0;
      outcome = await scheduleFirst(
        ratingCode: rating,
        desiredRetention: desiredRetention,
      );
    } else {
      elapsedDays =
          (now.millisecondsSinceEpoch - previous.lastReviewAt) / _msPerDay;
      outcome = await scheduleReview(
        state: ReviewState(
          stability: previous.stability,
          difficulty: previous.difficulty,
        ),
        elapsedDays: elapsedDays,
        ratingCode: rating,
        desiredRetention: desiredRetention,
      );
    }

    final dueAt = now.add(Duration(days: outcome.intervalDays));
    await _repository.recordReview(
      wordId: wordId,
      stability: outcome.stability,
      difficulty: outcome.difficulty,
      dueAt: dueAt,
      rating: rating,
      elapsedDays: elapsedDays,
      answerMs: answerMs,
      exercise: exercise,
      at: now,
    );
    return dueAt;
  }
}
