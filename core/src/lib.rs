//! هسته‌ی سره — the shared Rust core.
//!
//! Why Rust and not Dart (بخش ۹٫۲):
//!
//! * FSRS is written once and runs everywhere — app, web, CLI tools.
//! * Persian normalization is fiddly and called on every keystroke.
//! * Fuzzy search over 5000+ entries has to stay under 5ms.
//! * It opens the door to Rust contributors.
//!
//! `api` is the surface `flutter_rust_bridge` generates glue for. Everything
//! else is plain Rust with no Flutter knowledge.

/// چسبِ تولیدشده‌ی `flutter_rust_bridge`. با `make bridge` ساخته می‌شود و در
/// git نیست؛ کدِ دست‌نویس هرگز به آن ارجاع نمی‌دهد.
///
/// پشتِ ویژگیِ `bridge` است تا هسته روی یک checkoutِ تمیز — بی‌آنکه پل
/// ساخته شده باشد — بسازد و آزمون بدهد.
#[cfg(feature = "bridge")]
mod frb_generated;

pub mod api;
pub mod fsrs;
pub mod normalize;
pub mod search;
pub mod validate;

pub use fsrs::{Fsrs, MemoryState, Rating, Scheduled};
pub use normalize::{equivalent, fold_for_search, normalize, to_latin_digits, to_persian_digits};
pub use search::{Entry, Field, Hit, WordIndex};
