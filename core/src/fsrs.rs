//! FSRS — Free Spaced Repetition Scheduler (نسخه‌ی ۵)
//!
//! چرا FSRS و نه SM-2: دقیق‌تر است، متن‌باز است، و در دنیای Anki استاندارد شده.
//!
//! The whole scheduler lives here so the app, the web build and any CLI tool
//! share one implementation. Nothing in this module touches I/O or time zones —
//! callers pass elapsed days and get back a new memory state, which is what
//! makes it exhaustively testable.

use std::f64::consts::E;

/// Power-law forgetting curve exponent (FSRS-4.5 and later).
const DECAY: f64 = -0.5;

/// Chosen so that R = 0.9 exactly when elapsed days equal stability.
/// FACTOR = 0.9^(1/DECAY) − 1 = 19/81.
const FACTOR: f64 = 19.0 / 81.0;

const MIN_DIFFICULTY: f64 = 1.0;
const MAX_DIFFICULTY: f64 = 10.0;
/// Below ~1 minute there is nothing left to schedule.
const MIN_STABILITY: f64 = 0.001;
const MAX_STABILITY: f64 = 36500.0;

/// The nineteen FSRS-5 weights.
pub const DEFAULT_PARAMS: [f64; 19] = [
    0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046, 1.54575, 0.1192, 1.01925,
    1.9395, 0.11, 0.29605, 2.2698, 0.2315, 2.9898, 0.51655, 0.6621,
];

/// چهار پاسخِ کاربر. The app never shows four buttons — it maps its own
/// feedback onto these (see `Rating::from_answer`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Rating {
    /// دوباره — forgotten
    Again = 1,
    /// دشوار
    Hard = 2,
    /// درست
    Good = 3,
    /// آسان
    Easy = 4,
}

impl Rating {
    fn as_f64(self) -> f64 {
        self as i32 as f64
    }

    /// سره تنها «درست/نادرست» می‌پرسد؛ Hard و Easy از رفتار کاربر برداشت
    /// می‌شوند تا کاربر مجبور به خودسنجی نباشد.
    ///
    /// `answer_ms` is how long the learner took; `hesitated` is set by the
    /// exercise when the learner changed their selection before submitting.
    pub fn from_answer(correct: bool, answer_ms: u32, hesitated: bool) -> Rating {
        if !correct {
            return Rating::Again;
        }
        if hesitated || answer_ms > 8_000 {
            Rating::Hard
        } else if answer_ms < 2_500 {
            Rating::Easy
        } else {
            Rating::Good
        }
    }
}

/// حالت حافظه‌ی یک واژه برای یک کاربر.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct MemoryState {
    /// پایداری — days until retrievability falls to 0.9.
    pub stability: f64,
    /// دشواری — 1.0 (easy) to 10.0 (hard).
    pub difficulty: f64,
}

/// خروجیِ زمان‌بندی.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Scheduled {
    pub state: MemoryState,
    /// فاصله‌ی مرور بعدی به روز.
    pub interval_days: u32,
}

#[derive(Debug, Clone)]
pub struct Fsrs {
    params: [f64; 19],
    /// نگه‌داشتِ خواسته‌شده — the retention the learner is scheduled for.
    desired_retention: f64,
    maximum_interval: u32,
}

impl Default for Fsrs {
    fn default() -> Self {
        Fsrs {
            params: DEFAULT_PARAMS,
            desired_retention: 0.9,
            maximum_interval: 36500,
        }
    }
}

impl Fsrs {
    pub fn new(params: [f64; 19], desired_retention: f64, maximum_interval: u32) -> Self {
        Fsrs {
            params,
            desired_retention: desired_retention.clamp(0.7, 0.99),
            maximum_interval: maximum_interval.max(1),
        }
    }

    pub fn desired_retention(&self) -> f64 {
        self.desired_retention
    }

    /// بازیابی‌پذیری — probability of recall after `elapsed_days`.
    ///
    /// R(t, S) = (1 + FACTOR · t/S)^DECAY
    pub fn retrievability(&self, state: &MemoryState, elapsed_days: f64) -> f64 {
        if state.stability <= 0.0 {
            return 0.0;
        }
        let t = elapsed_days.max(0.0);
        (1.0 + FACTOR * t / state.stability).powf(DECAY)
    }

    /// فاصله‌ی مرور برای رسیدن به نگه‌داشتِ خواسته‌شده.
    ///
    /// I(r, S) = S/FACTOR · (r^(1/DECAY) − 1)
    pub fn interval_days(&self, stability: f64) -> u32 {
        let raw = stability / FACTOR * (self.desired_retention.powf(1.0 / DECAY) - 1.0);
        (raw.round().max(1.0) as u32).min(self.maximum_interval)
    }

    /// نخستین دیدارِ یک واژه.
    pub fn schedule_first(&self, rating: Rating) -> Scheduled {
        let stability = self.initial_stability(rating);
        let difficulty = self.initial_difficulty(rating);
        let state = MemoryState {
            stability: clamp_stability(stability),
            difficulty: clamp_difficulty(difficulty),
        };
        Scheduled {
            state,
            interval_days: self.interval_days(state.stability),
        }
    }

    /// مرورِ بعدی. `elapsed_days` فاصله‌ی واقعی از مرورِ پیشین است.
    ///
    /// Same-day reviews (elapsed < 1 day) take the short-term path: they nudge
    /// stability without pretending a day of forgetting happened.
    pub fn schedule_review(
        &self,
        state: &MemoryState,
        elapsed_days: f64,
        rating: Rating,
    ) -> Scheduled {
        let w = &self.params;
        let elapsed = elapsed_days.max(0.0);
        let r = self.retrievability(state, elapsed);

        let difficulty = self.next_difficulty(state.difficulty, rating);

        let stability = if elapsed < 1.0 {
            self.short_term_stability(state.stability, rating)
        } else if rating == Rating::Again {
            // فراموشی — stability drops, but never below the short-term floor.
            let post_lapse = w[11]
                * state.difficulty.powf(-w[12])
                * ((state.stability + 1.0).powf(w[13]) - 1.0)
                * E.powf(w[14] * (1.0 - r));
            post_lapse.min(state.stability)
        } else {
            let hard_penalty = if rating == Rating::Hard { w[15] } else { 1.0 };
            let easy_bonus = if rating == Rating::Easy { w[16] } else { 1.0 };
            state.stability
                * (1.0
                    + E.powf(w[8])
                        * (11.0 - state.difficulty)
                        * state.stability.powf(-w[9])
                        * (E.powf(w[10] * (1.0 - r)) - 1.0)
                        * hard_penalty
                        * easy_bonus)
        };

        let next = MemoryState {
            stability: clamp_stability(stability),
            difficulty: clamp_difficulty(difficulty),
        };
        Scheduled {
            state: next,
            interval_days: self.interval_days(next.stability),
        }
    }

    fn initial_stability(&self, rating: Rating) -> f64 {
        self.params[rating as usize - 1]
    }

    fn initial_difficulty(&self, rating: Rating) -> f64 {
        self.params[4] - E.powf(self.params[5] * (rating.as_f64() - 1.0)) + 1.0
    }

    /// دشواریِ بعدی: تغییر خطی با میرایی، سپس بازگشت به میانگین.
    fn next_difficulty(&self, difficulty: f64, rating: Rating) -> f64 {
        let w = &self.params;
        let delta = -w[6] * (rating.as_f64() - 3.0);
        // Linear damping: the closer difficulty is to 10, the less it moves.
        let damped = difficulty + delta * (10.0 - difficulty) / 9.0;
        // Mean reversion toward the difficulty of an "Easy" first answer.
        let target = self.initial_difficulty(Rating::Easy);
        w[7] * target + (1.0 - w[7]) * damped
    }

    /// مرورِ همان‌روز — بی‌آنکه وانمود کنیم روزی گذشته است.
    fn short_term_stability(&self, stability: f64, rating: Rating) -> f64 {
        let w = &self.params;
        stability * E.powf(w[17] * (rating.as_f64() - 3.0 + w[18]))
    }
}

fn clamp_difficulty(d: f64) -> f64 {
    if d.is_nan() {
        return MIN_DIFFICULTY;
    }
    d.clamp(MIN_DIFFICULTY, MAX_DIFFICULTY)
}

fn clamp_stability(s: f64) -> f64 {
    if s.is_nan() {
        return MIN_STABILITY;
    }
    s.clamp(MIN_STABILITY, MAX_STABILITY)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn fsrs() -> Fsrs {
        Fsrs::default()
    }

    #[test]
    fn retrievability_is_one_at_zero_elapsed() {
        let s = MemoryState {
            stability: 5.0,
            difficulty: 5.0,
        };
        assert!((fsrs().retrievability(&s, 0.0) - 1.0).abs() < 1e-12);
    }

    #[test]
    fn retrievability_is_desired_retention_at_stability() {
        // The FACTOR constant exists precisely to make this true.
        for stability in [0.5, 1.0, 7.0, 365.0] {
            let s = MemoryState {
                stability,
                difficulty: 5.0,
            };
            let r = fsrs().retrievability(&s, stability);
            assert!((r - 0.9).abs() < 1e-9, "S={stability} R={r}");
        }
    }

    #[test]
    fn retrievability_decreases_monotonically() {
        let s = MemoryState {
            stability: 10.0,
            difficulty: 5.0,
        };
        let f = fsrs();
        let mut previous = f.retrievability(&s, 0.0);
        for day in 1..400 {
            let r = f.retrievability(&s, day as f64);
            assert!(r < previous, "R rose at day {day}");
            assert!((0.0..=1.0).contains(&r));
            previous = r;
        }
    }

    #[test]
    fn retrievability_of_zero_stability_is_zero() {
        let s = MemoryState {
            stability: 0.0,
            difficulty: 5.0,
        };
        assert_eq!(fsrs().retrievability(&s, 3.0), 0.0);
    }

    #[test]
    fn negative_elapsed_is_treated_as_zero() {
        // Clock skew and time-zone travel must not hand back R > 1.
        let s = MemoryState {
            stability: 4.0,
            difficulty: 5.0,
        };
        assert!((fsrs().retrievability(&s, -7.0) - 1.0).abs() < 1e-12);
    }

    #[test]
    fn interval_round_trips_through_retrievability() {
        let f = fsrs();
        for stability in [1.0, 3.0, 30.0, 300.0] {
            let days = f.interval_days(stability);
            let s = MemoryState {
                stability,
                difficulty: 5.0,
            };
            let r = f.retrievability(&s, days as f64);
            // Rounding to whole days is the only slack allowed.
            assert!(
                (r - f.desired_retention()).abs() < 0.05,
                "S={stability} R={r}"
            );
        }
    }

    #[test]
    fn interval_is_at_least_one_day_and_respects_maximum() {
        let f = Fsrs::new(DEFAULT_PARAMS, 0.9, 30);
        assert_eq!(f.interval_days(0.0001), 1);
        assert_eq!(f.interval_days(100_000.0), 30);
    }

    #[test]
    fn higher_desired_retention_shortens_intervals() {
        let relaxed = Fsrs::new(DEFAULT_PARAMS, 0.8, 36500);
        let strict = Fsrs::new(DEFAULT_PARAMS, 0.97, 36500);
        assert!(strict.interval_days(50.0) < relaxed.interval_days(50.0));
    }

    #[test]
    fn desired_retention_is_clamped_to_sane_range() {
        assert_eq!(Fsrs::new(DEFAULT_PARAMS, 0.1, 100).desired_retention(), 0.7);
        assert_eq!(
            Fsrs::new(DEFAULT_PARAMS, 1.5, 100).desired_retention(),
            0.99
        );
    }

    #[test]
    fn first_stability_ranks_in_rating_order() {
        let f = fsrs();
        let again = f.schedule_first(Rating::Again).state.stability;
        let hard = f.schedule_first(Rating::Hard).state.stability;
        let good = f.schedule_first(Rating::Good).state.stability;
        let easy = f.schedule_first(Rating::Easy).state.stability;
        assert!(again < hard && hard < good && good < easy);
    }

    #[test]
    fn first_difficulty_ranks_inversely_to_rating() {
        let f = fsrs();
        let again = f.schedule_first(Rating::Again).state.difficulty;
        let good = f.schedule_first(Rating::Good).state.difficulty;
        let easy = f.schedule_first(Rating::Easy).state.difficulty;
        assert!(again > good && good > easy);
        assert!((MIN_DIFFICULTY..=MAX_DIFFICULTY).contains(&again));
    }

    #[test]
    fn successful_review_grows_stability() {
        let f = fsrs();
        let s = MemoryState {
            stability: 10.0,
            difficulty: 5.0,
        };
        let next = f.schedule_review(&s, 10.0, Rating::Good);
        assert!(next.state.stability > s.stability);
    }

    #[test]
    fn lapse_never_grows_stability() {
        let f = fsrs();
        for stability in [0.5, 2.0, 20.0, 200.0, 2000.0] {
            for difficulty in [1.0, 5.0, 10.0] {
                let s = MemoryState {
                    stability,
                    difficulty,
                };
                let next = f.schedule_review(&s, stability, Rating::Again);
                assert!(
                    next.state.stability <= stability + 1e-9,
                    "S={stability} D={difficulty} -> {}",
                    next.state.stability
                );
            }
        }
    }

    #[test]
    fn easy_beats_good_beats_hard_on_the_same_review() {
        let f = fsrs();
        let s = MemoryState {
            stability: 12.0,
            difficulty: 5.0,
        };
        let hard = f.schedule_review(&s, 12.0, Rating::Hard).state.stability;
        let good = f.schedule_review(&s, 12.0, Rating::Good).state.stability;
        let easy = f.schedule_review(&s, 12.0, Rating::Easy).state.stability;
        assert!(hard < good && good < easy);
    }

    #[test]
    fn harder_words_gain_less_stability() {
        let f = fsrs();
        let easy_word = MemoryState {
            stability: 10.0,
            difficulty: 2.0,
        };
        let hard_word = MemoryState {
            stability: 10.0,
            difficulty: 9.0,
        };
        let a = f
            .schedule_review(&easy_word, 10.0, Rating::Good)
            .state
            .stability;
        let b = f
            .schedule_review(&hard_word, 10.0, Rating::Good)
            .state
            .stability;
        assert!(b < a);
    }

    #[test]
    fn again_raises_difficulty_and_easy_lowers_it() {
        let f = fsrs();
        let s = MemoryState {
            stability: 10.0,
            difficulty: 5.0,
        };
        assert!(f.schedule_review(&s, 10.0, Rating::Again).state.difficulty > 5.0);
        assert!(f.schedule_review(&s, 10.0, Rating::Easy).state.difficulty < 5.0);
    }

    #[test]
    fn difficulty_stays_inside_bounds_under_abuse() {
        let f = fsrs();
        let mut state = MemoryState {
            stability: 5.0,
            difficulty: 5.0,
        };
        for _ in 0..500 {
            state = f.schedule_review(&state, 1.0, Rating::Again).state;
            assert!((MIN_DIFFICULTY..=MAX_DIFFICULTY).contains(&state.difficulty));
        }
        assert!(state.difficulty <= MAX_DIFFICULTY);

        let mut state = MemoryState {
            stability: 5.0,
            difficulty: 5.0,
        };
        for _ in 0..500 {
            state = f.schedule_review(&state, 1.0, Rating::Easy).state;
            assert!((MIN_DIFFICULTY..=MAX_DIFFICULTY).contains(&state.difficulty));
        }
    }

    #[test]
    fn stability_stays_inside_bounds_under_abuse() {
        let f = fsrs();
        let mut state = MemoryState {
            stability: 1.0,
            difficulty: 5.0,
        };
        for _ in 0..2000 {
            state = f.schedule_review(&state, 365.0, Rating::Easy).state;
            assert!(state.stability <= MAX_STABILITY);
            assert!(state.stability >= MIN_STABILITY);
        }
    }

    #[test]
    fn same_day_review_takes_the_short_term_path() {
        let f = fsrs();
        let s = MemoryState {
            stability: 10.0,
            difficulty: 5.0,
        };
        // A same-day "Again" must not be scored as a full-blown lapse.
        let same_day = f.schedule_review(&s, 0.2, Rating::Again).state.stability;
        let next_day = f.schedule_review(&s, 10.0, Rating::Again).state.stability;
        assert!(same_day > next_day);
        // And a same-day "Good" nudges rather than leaps.
        let good = f.schedule_review(&s, 0.2, Rating::Good).state.stability;
        assert!(good > s.stability && good < s.stability * 2.0);
    }

    #[test]
    fn a_long_correct_streak_produces_growing_intervals() {
        let f = fsrs();
        let mut sched = f.schedule_first(Rating::Good);
        let mut previous = sched.interval_days;
        for _ in 0..12 {
            sched = f.schedule_review(&sched.state, previous as f64, Rating::Good);
            assert!(
                sched.interval_days >= previous,
                "interval shrank: {previous} -> {}",
                sched.interval_days
            );
            previous = sched.interval_days;
        }
        // Twelve correct reviews should be measured in months, not days.
        assert!(previous > 60, "interval only reached {previous} days");
    }

    #[test]
    fn rating_is_derived_from_behaviour_not_self_report() {
        assert_eq!(Rating::from_answer(false, 500, false), Rating::Again);
        assert_eq!(Rating::from_answer(true, 1_200, false), Rating::Easy);
        assert_eq!(Rating::from_answer(true, 4_000, false), Rating::Good);
        assert_eq!(Rating::from_answer(true, 12_000, false), Rating::Hard);
        // Hesitation outranks speed: a fast but second-guessed answer is Hard.
        assert_eq!(Rating::from_answer(true, 900, true), Rating::Hard);
    }

    #[test]
    fn nan_inputs_degrade_to_bounds_instead_of_propagating() {
        let f = fsrs();
        let s = MemoryState {
            stability: f64::NAN,
            difficulty: f64::NAN,
        };
        let next = f.schedule_review(&s, 5.0, Rating::Good);
        assert!(next.state.stability.is_finite());
        assert!(next.state.difficulty.is_finite());
        assert!(next.interval_days >= 1);
    }
}
