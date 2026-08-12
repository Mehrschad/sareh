//! اعتبارسنجیِ طرح‌واره‌ی واژه‌ها
//!
//! The rule from بخش ۲ that this file exists to enforce: **مدخل بی‌منبع در CI رد
//! می‌شود.** Everything else here is in service of keeping the corpus honest
//! enough that a learner can trust it.
//!
//! Shared by `tools/validate_words.rs` (CI) and the word editor, so a
//! contributor gets the same verdict locally that the pull request will get.

use serde::Deserialize;
use std::collections::HashMap;
use std::fmt;
use std::path::{Path, PathBuf};

use crate::normalize::fold_for_search;

pub const ACCEPTANCE: [&str; 3] = ["زنده", "خفته", "نوساخته"];
pub const REGISTER: [&str; 4] = ["گفتاری", "رسمی", "ادبی", "دانشی"];
pub const STATUS: [&str; 3] = ["proposed", "reviewed", "verified"];

#[derive(Debug, Deserialize)]
pub struct Citation {
    pub source: String,
    #[serde(default)]
    pub r#ref: Option<String>,
    #[serde(default)]
    pub verse: Option<String>,
    #[serde(default)]
    pub book: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct Example {
    pub sare: String,
    pub loan: String,
}

#[derive(Debug, Deserialize, Default)]
pub struct Roots {
    #[serde(default)]
    pub pahlavi: Option<String>,
    #[serde(default)]
    pub avestan: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct Word {
    pub id: String,
    pub sare: String,
    pub loan: String,
    pub loan_origin: String,
    pub pos: String,
    pub acceptance: String,
    pub ipa: String,
    pub definition: String,
    pub english: String,
    pub register: String,
    pub frequency_rank: u32,
    pub difficulty: u8,
    pub examples: Vec<Example>,
    pub citations: Vec<Citation>,
    #[serde(default)]
    pub roots: Roots,
    #[serde(default)]
    pub related: Vec<String>,
    #[serde(default)]
    pub audio: Option<String>,
    pub status: String,
    #[serde(default)]
    pub contributors: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Problem {
    pub file: PathBuf,
    pub message: String,
}

impl fmt::Display for Problem {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}: {}", self.file.display(), self.message)
    }
}

/// یک فایل را می‌سنجد. Parse failures come back as a problem, not a panic —
/// a contributor with a YAML typo deserves a readable message.
pub fn validate_file(path: &Path, source: &str) -> (Option<Word>, Vec<Problem>) {
    let problem = |message: String| Problem {
        file: path.to_path_buf(),
        message,
    };

    let word: Word = match serde_yaml::from_str(source) {
        Ok(word) => word,
        Err(e) => return (None, vec![problem(format!("YAML خوانده نشد: {e}"))]),
    };

    let mut problems = Vec::new();
    let mut fail = |message: String| problems.push(problem(message));

    let stem = path
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or_default();
    if stem != word.id {
        fail(format!("نامِ فایل «{stem}» با id «{}» نمی‌خواند", word.id));
    }
    if !word
        .id
        .chars()
        .all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '-')
    {
        fail(format!("id «{}» باید ascii و kebab-case باشد", word.id));
    }

    for (name, value) in [
        ("sare", &word.sare),
        ("loan", &word.loan),
        ("definition", &word.definition),
        ("english", &word.english),
        ("ipa", &word.ipa),
        ("pos", &word.pos),
        ("loan_origin", &word.loan_origin),
    ] {
        if value.trim().is_empty() {
            fail(format!("«{name}» خالی است"));
        }
    }

    if word.sare == word.loan {
        fail("سره و وام‌واژه یکی‌اند".into());
    }
    if !ACCEPTANCE.contains(&word.acceptance.as_str()) {
        fail(format!("acceptance «{}» شناخته نشد", word.acceptance));
    }
    if !REGISTER.contains(&word.register.as_str()) {
        fail(format!("register «{}» شناخته نشد", word.register));
    }
    if !STATUS.contains(&word.status.as_str()) {
        fail(format!("status «{}» شناخته نشد", word.status));
    }
    if !(1..=5).contains(&word.difficulty) {
        fail(format!(
            "difficulty باید ۱ تا ۵ باشد، نه {}",
            word.difficulty
        ));
    }
    if !(word.ipa.starts_with('/') && word.ipa.ends_with('/') && word.ipa.len() > 2) {
        fail(format!("ipa باید میان دو / باشد: «{}»", word.ipa));
    }

    // قاعده‌ی سخت: مدخل بی‌منبع رد می‌شود.
    if word.citations.is_empty() {
        fail("مدخل بی‌منبع است — دست‌کم یک منبع لازم است".into());
    }
    for (i, citation) in word.citations.iter().enumerate() {
        if citation.source.trim().is_empty() {
            fail(format!("منبعِ {} نامِ source ندارد", i + 1));
        }
        if citation.r#ref.is_none() && citation.verse.is_none() && citation.book.is_none() {
            fail(format!(
                "منبعِ «{}» هیچ‌یک از ref/verse/book را ندارد",
                citation.source
            ));
        }
    }

    if word.examples.is_empty() {
        fail("مدخل دست‌کم یک نمونه‌ی کاربرد می‌خواهد".into());
    }
    for (i, example) in word.examples.iter().enumerate() {
        let n = i + 1;
        if example.sare.trim().is_empty() || example.loan.trim().is_empty() {
            fail(format!("نمونه‌ی {n} ناقص است"));
            continue;
        }
        if example.sare == example.loan {
            fail(format!("دو سویِ نمونه‌ی {n} یکی‌اند"));
        }
        // The whole point of the pair is to show the swap in place.
        if !contains_word(&example.sare, &word.sare) {
            fail(format!("نمونه‌ی {n} واژه‌ی «{}» را ندارد", word.sare));
        }
        if !contains_word(&example.loan, &word.loan) {
            fail(format!("نمونه‌ی {n} وام‌واژه‌ی «{}» را ندارد", word.loan));
        }
    }

    if word.related.iter().any(|r| r == &word.sare) {
        fail("واژه در فهرستِ related خودش آمده".into());
    }
    if word.status == "verified" && word.contributors.len() < 2 {
        // See content/SOURCES.md — verified means two people opened the book.
        fail("status: verified دست‌کم دو contributor می‌خواهد".into());
    }
    if let Some(audio) = &word.audio {
        if !audio.ends_with(".opus") {
            fail(format!("audio باید opus باشد: «{audio}»"));
        }
    }

    (Some(word), problems)
}

/// سنجش‌هایی که تنها با دیدنِ همه‌ی مدخل‌ها ممکن‌اند.
pub fn validate_corpus(words: &[(PathBuf, Word)]) -> Vec<Problem> {
    let mut problems = Vec::new();
    let mut ids: HashMap<&str, &Path> = HashMap::new();
    let mut pairs: HashMap<(String, String), &Path> = HashMap::new();

    for (path, word) in words {
        if let Some(first) = ids.insert(&word.id, path) {
            problems.push(Problem {
                file: path.clone(),
                message: format!("id «{}» تکراری است (نخست در {})", word.id, first.display()),
            });
        }
        let key = (fold_for_search(&word.sare), fold_for_search(&word.loan));
        if let Some(first) = pairs.insert(key, path) {
            problems.push(Problem {
                file: path.clone(),
                message: format!(
                    "جفتِ «{}»/«{}» تکراری است (نخست در {})",
                    word.sare,
                    word.loan,
                    first.display()
                ),
            });
        }
    }
    problems
}

/// Whole-word containment after folding, so «پرماس» matches «پرماسِ سنگ» but a
/// stray substring inside a longer word does not count.
///
/// Multi-word entries («دستور زبان», «بنای یادبود») match as a token run, and
/// each token may carry an ezafe or a suffix — «دستورِ زبان» counts.
fn contains_word(sentence: &str, word: &str) -> bool {
    let needle: Vec<String> = tokenize(&fold_for_search(word));
    if needle.is_empty() {
        return false;
    }
    let hay = tokenize(&fold_for_search(sentence));
    hay.windows(needle.len()).any(|run| {
        run.iter()
            .zip(&needle)
            .all(|(token, want)| token.starts_with(want))
    })
}

fn tokenize(folded: &str) -> Vec<String> {
    folded
        .split(|c: char| c.is_whitespace() || "،.؛:؟!«»()".contains(c))
        .filter(|t| !t.is_empty())
        .map(str::to_owned)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    const GOOD: &str = r#"
id: parmas-lams
sare: پرماس
loan: لمس
loan_origin: عربی
pos: اسم
acceptance: خفته
ipa: /paɾˈmɒːs/
definition: دست ساییدن بر چیزی
english: touch
register: ادبی
frequency_rank: 340
difficulty: 3
examples:
  - sare: انگشتانش را بر ساز پرماس کرد.
    loan: انگشتانش را بر ساز لمس کرد.
citations:
  - source: لغت‌نامه دهخدا
    ref: مدخل «پرماس»
roots:
  pahlavi: parmāsītan
  avestan: null
related: [پرماسیدن]
audio: null
status: proposed
contributors: [sareh-seed]
"#;

    fn check(yaml: &str) -> Vec<String> {
        let path = PathBuf::from("parmas-lams.yaml");
        let (_, problems) = validate_file(&path, yaml);
        problems.into_iter().map(|p| p.message).collect()
    }

    #[test]
    fn a_complete_entry_passes() {
        assert!(check(GOOD).is_empty(), "{:?}", check(GOOD));
    }

    #[test]
    fn an_entry_without_citations_is_rejected() {
        let yaml = GOOD.replace(
            "citations:\n  - source: لغت‌نامه دهخدا\n    ref: مدخل «پرماس»",
            "citations: []",
        );
        assert!(check(&yaml).iter().any(|m| m.contains("بی‌منبع")));
    }

    #[test]
    fn a_citation_without_a_reference_is_rejected() {
        let yaml = GOOD.replace("    ref: مدخل «پرماس»\n", "");
        assert!(check(&yaml).iter().any(|m| m.contains("ref/verse/book")));
    }

    #[test]
    fn examples_must_actually_contain_the_words() {
        let yaml = GOOD.replace("بر ساز پرماس کرد.", "بر ساز بساوش کرد.");
        assert!(check(&yaml).iter().any(|m| m.contains("پرماس")));
    }

    #[test]
    fn inflected_examples_are_accepted() {
        // «پرماسِ سنگ» carries an ezafe; the check must not demand a bare form.
        let yaml = GOOD
            .replace("انگشتانش را بر ساز پرماس کرد.", "پرماسِ سنگ سرد بود.")
            .replace("انگشتانش را بر ساز لمس کرد.", "لمسِ سنگ سرد بود.");
        assert!(check(&yaml).is_empty(), "{:?}", check(&yaml));
    }

    #[test]
    fn multi_word_entries_match_as_a_token_run() {
        assert!(contains_word("دستورِ زبان را خوب می‌داند.", "دستور زبان"));
        assert!(contains_word(
            "بنای یادبودِ شهیدان را ساختند.",
            "بنای یادبود"
        ));
        assert!(contains_word("این جمله‌ی خبری نادرست است.", "جمله خبری"));
        // Right tokens, wrong order or split apart — not a match.
        assert!(!contains_word("زبانِ دستور را خوب می‌داند.", "دستور زبان"));
        assert!(!contains_word("دستورِ این زبان روشن است.", "دستور زبان"));
    }

    #[test]
    fn a_prefix_of_a_longer_unrelated_word_does_not_count() {
        assert!(contains_word("سپاسگزارم از تو.", "سپاس"));
        assert!(!contains_word("او را بساوید.", "پرماس"));
    }

    #[test]
    fn unknown_enum_values_are_rejected() {
        assert!(check(&GOOD.replace("acceptance: خفته", "acceptance: مرده"))
            .iter()
            .any(|m| m.contains("acceptance")));
        assert!(check(&GOOD.replace("register: ادبی", "register: خیابانی"))
            .iter()
            .any(|m| m.contains("register")));
        assert!(check(&GOOD.replace("status: proposed", "status: perfect"))
            .iter()
            .any(|m| m.contains("status")));
    }

    #[test]
    fn difficulty_outside_one_to_five_is_rejected() {
        assert!(check(&GOOD.replace("difficulty: 3", "difficulty: 9"))
            .iter()
            .any(|m| m.contains("difficulty")));
    }

    #[test]
    fn malformed_ipa_is_rejected() {
        assert!(check(&GOOD.replace("ipa: /paɾˈmɒːs/", "ipa: parmas"))
            .iter()
            .any(|m| m.contains("ipa")));
    }

    #[test]
    fn filename_must_match_id() {
        let (_, problems) = validate_file(&PathBuf::from("wrong-name.yaml"), GOOD);
        assert!(problems.iter().any(|p| p.message.contains("نامِ فایل")));
    }

    #[test]
    fn verified_status_needs_two_contributors() {
        let yaml = GOOD.replace("status: proposed", "status: verified");
        assert!(check(&yaml).iter().any(|m| m.contains("verified")));
        let yaml = yaml.replace("contributors: [sareh-seed]", "contributors: [a, b]");
        assert!(check(&yaml).is_empty(), "{:?}", check(&yaml));
    }

    #[test]
    fn broken_yaml_reports_instead_of_panicking() {
        let (word, problems) = validate_file(&PathBuf::from("x.yaml"), "id: [unclosed");
        assert!(word.is_none());
        assert_eq!(problems.len(), 1);
        assert!(problems[0].message.contains("YAML"));
    }

    #[test]
    fn duplicate_ids_and_pairs_are_caught_across_files() {
        let (a, _) = validate_file(&PathBuf::from("parmas-lams.yaml"), GOOD);
        let (b, _) = validate_file(&PathBuf::from("parmas-lams.yaml"), GOOD);
        let words = vec![
            (PathBuf::from("one.yaml"), a.unwrap()),
            (PathBuf::from("two.yaml"), b.unwrap()),
        ];
        let problems = validate_corpus(&words);
        assert!(problems.iter().any(|p| p.message.contains("تکراری")));
    }

    #[test]
    fn duplicate_detection_sees_through_spelling_variants() {
        // Same word typed with an Arabic Yeh must not slip past as new.
        let (a, _) = validate_file(&PathBuf::from("parmas-lams.yaml"), GOOD);
        let variant = GOOD
            .replace("id: parmas-lams", "id: parmas-lams-2")
            .replace("sare: پرماس", "sare: پرماس ");
        let (b, _) = validate_file(&PathBuf::from("parmas-lams-2.yaml"), &variant);
        let words = vec![
            (PathBuf::from("one.yaml"), a.unwrap()),
            (PathBuf::from("two.yaml"), b.unwrap()),
        ];
        assert!(validate_corpus(&words)
            .iter()
            .any(|p| p.message.contains("جفت")));
    }
}
