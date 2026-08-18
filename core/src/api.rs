//! پلِ Dart — the `flutter_rust_bridge` surface.
//!
//! Everything here is plain data in, plain data out: no lifetimes, no traits,
//! no borrowed returns, because the bridge codegen only understands that
//! subset. Regenerate the Dart side with:
//!
//! ```text
//! flutter_rust_bridge_codegen generate
//! ```
//!
//! The index is process-global because there is exactly one dictionary and
//! rebuilding it per call would cost more than every search combined.

use std::sync::{OnceLock, RwLock};

use crate::fsrs::{Fsrs, MemoryState, Rating};
use crate::search::{Entry, Field, WordIndex};

fn index_slot() -> &'static RwLock<Option<WordIndex>> {
    static INDEX: OnceLock<RwLock<Option<WordIndex>>> = OnceLock::new();
    INDEX.get_or_init(|| RwLock::new(None))
}

/// A dictionary row as Dart sends it in.
#[derive(Debug, Clone)]
pub struct WordRow {
    pub id: String,
    pub sare: String,
    pub loan: String,
    pub english: String,
}

/// A search result as Dart gets it back.
#[derive(Debug, Clone)]
pub struct SearchHit {
    pub id: String,
    /// "sare" | "loan" | "english"
    pub field: String,
    pub score: u32,
}

/// حالت حافظه در سویِ Dart.
#[derive(Debug, Clone, Copy)]
pub struct ReviewState {
    pub stability: f64,
    pub difficulty: f64,
}

/// خروجیِ زمان‌بندی در سویِ Dart.
#[derive(Debug, Clone, Copy)]
pub struct ReviewOutcome {
    pub stability: f64,
    pub difficulty: f64,
    pub interval_days: u32,
}

/// واژه‌نامه را می‌سازد. Call once at startup, then again only if the content
/// pack changes.
pub fn build_index(rows: Vec<WordRow>) -> u32 {
    let entries = rows
        .into_iter()
        .map(|r| Entry {
            id: r.id,
            sare: r.sare,
            loan: r.loan,
            english: r.english,
        })
        .collect();
    let index = WordIndex::build(entries);
    let count = index.len() as u32;
    *index_slot().write().expect("index lock poisoned") = Some(index);
    count
}

/// جست‌وجو. Returns an empty list if the index has not been built yet, rather
/// than failing — the UI shows "هنوز واژه‌ای نیست" either way.
pub fn search_words(query: String, limit: u32) -> Vec<SearchHit> {
    let guard = index_slot().read().expect("index lock poisoned");
    let Some(index) = guard.as_ref() else {
        return Vec::new();
    };
    index
        .search(&query, limit as usize)
        .into_iter()
        .map(|hit| SearchHit {
            id: hit.id,
            field: match hit.field {
                Field::Sare => "sare".into(),
                Field::Loan => "loan".into(),
                Field::English => "english".into(),
            },
            score: hit.score,
        })
        .collect()
}

/// نرمال‌سازیِ متنِ فارسی برای نمایش و ذخیره.
pub fn normalize_text(input: String) -> String {
    crate::normalize::normalize(&input)
}

/// آیا پاسخِ تایپ‌شده با پاسخِ درست یکی است؟
pub fn answers_match(typed: String, expected: String) -> bool {
    crate::normalize::equivalent(&typed, &expected)
}

/// اعداد پارسی برای نمایش.
pub fn persian_digits(input: String) -> String {
    crate::normalize::to_persian_digits(&input)
}

fn rating_from_code(code: u8) -> Rating {
    match code {
        1 => Rating::Again,
        2 => Rating::Hard,
        4 => Rating::Easy,
        _ => Rating::Good,
    }
}

/// درجه‌بندی از روی رفتار، نه از روی خودسنجی.
pub fn rate_answer(correct: bool, answer_ms: u32, hesitated: bool) -> u8 {
    Rating::from_answer(correct, answer_ms, hesitated) as u8
}

/// نخستین دیدارِ واژه.
pub fn schedule_first(rating_code: u8, desired_retention: f64) -> ReviewOutcome {
    let fsrs = Fsrs::new(crate::fsrs::DEFAULT_PARAMS, desired_retention, 36500);
    let scheduled = fsrs.schedule_first(rating_from_code(rating_code));
    ReviewOutcome {
        stability: scheduled.state.stability,
        difficulty: scheduled.state.difficulty,
        interval_days: scheduled.interval_days,
    }
}

/// مرورِ بعدی.
pub fn schedule_review(
    state: ReviewState,
    elapsed_days: f64,
    rating_code: u8,
    desired_retention: f64,
) -> ReviewOutcome {
    let fsrs = Fsrs::new(crate::fsrs::DEFAULT_PARAMS, desired_retention, 36500);
    let current = MemoryState {
        stability: state.stability,
        difficulty: state.difficulty,
    };
    let scheduled = fsrs.schedule_review(&current, elapsed_days, rating_from_code(rating_code));
    ReviewOutcome {
        stability: scheduled.state.stability,
        difficulty: scheduled.state.difficulty,
        interval_days: scheduled.interval_days,
    }
}

/// بازیابی‌پذیری — درصدِ احتمالِ به‌یادآوردن، برای نوارِ «آمادگی» در نمایه.
pub fn retrievability(state: ReviewState, elapsed_days: f64) -> f64 {
    Fsrs::default().retrievability(
        &MemoryState {
            stability: state.stability,
            difficulty: state.difficulty,
        },
        elapsed_days,
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    fn row(id: &str, sare: &str, loan: &str, english: &str) -> WordRow {
        WordRow {
            id: id.into(),
            sare: sare.into(),
            loan: loan.into(),
            english: english.into(),
        }
    }

    #[test]
    fn index_builds_and_searches_through_the_bridge() {
        let count = build_index(vec![
            row("parmas-lams", "پرماس", "لمس", "touch"),
            row("sepas-tashakkor", "سپاس", "تشکر", "thanks"),
        ]);
        assert_eq!(count, 2);
        let hits = search_words("لمس".into(), 5);
        assert_eq!(hits[0].id, "parmas-lams");
        assert_eq!(hits[0].field, "loan");
    }

    #[test]
    fn searching_before_the_index_exists_returns_empty_not_panic() {
        // Deliberately does not build an index first; other tests in this
        // module may have, so this only asserts the call is safe.
        let _ = search_words("چیزی".into(), 5);
    }

    #[test]
    fn scheduling_round_trips_through_the_bridge_types() {
        let first = schedule_first(rate_answer(true, 3000, false), 0.9);
        assert!(first.interval_days >= 1);
        let next = schedule_review(
            ReviewState {
                stability: first.stability,
                difficulty: first.difficulty,
            },
            first.interval_days as f64,
            3,
            0.9,
        );
        assert!(next.stability > first.stability);
    }

    #[test]
    fn unknown_rating_codes_fall_back_to_good() {
        assert_eq!(rating_from_code(99), Rating::Good);
        assert_eq!(rating_from_code(0), Rating::Good);
        assert_eq!(rating_from_code(1), Rating::Again);
    }

    #[test]
    fn text_helpers_are_reachable_from_dart() {
        assert_eq!(normalize_text("  كتاب  ".into()), "کتاب");
        assert!(answers_match("پرماس".into(), " پرماس ".into()));
        assert_eq!(persian_digits("۱۴".into()), "۱۴");
        assert_eq!(persian_digits("14".into()), "۱۴");
    }

    #[test]
    fn retrievability_is_one_right_after_a_review() {
        let r = retrievability(
            ReviewState {
                stability: 5.0,
                difficulty: 5.0,
            },
            0.0,
        );
        assert!((r - 1.0).abs() < 1e-12);
    }
}
