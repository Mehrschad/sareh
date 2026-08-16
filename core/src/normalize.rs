//! نرمال‌سازی متن فارسی
//!
//! Persian text arrives from keyboards, dictionaries and copy-paste in shapes
//! that look identical but compare unequal: Arabic Yeh vs Persian Yeh, Arabic
//! Kaf vs Keheh, three families of digits, optional diacritics, and a
//! zero-width non-joiner that users type inconsistently.
//!
//! Two levels, deliberately separate:
//!
//! * [`normalize`] — safe, لossless enough to store and display. Fixes
//!   character confusions and spacing but preserves آ, ه/ة distinctions and
//!   half-spaces (نیم‌فاصله), because those change meaning and appearance.
//! * [`fold_for_search`] — aggressive. Everything [`normalize`] does, plus
//!   folding alef and hamze variants and dropping half-spaces entirely, so that
//!   «پیام‌رسان» and «پیام رسان» and «پيام رسان» all match one key.
//!
//! Never store the folded form. It is a lookup key, not text.

/// نیم‌فاصله — zero-width non-joiner.
pub const ZWNJ: char = '\u{200C}';

/// Persian digits ۰..۹ start here.
const PERSIAN_ZERO: u32 = 0x06F0;

/// اعراب و علائم — combining marks that carry no lexical weight in modern
/// Persian orthography and must not affect comparison.
fn is_diacritic(c: char) -> bool {
    matches!(c,
        '\u{064B}'..='\u{0652}'   // tanwin, fatha..sukun
        | '\u{0653}'..='\u{0655}' // maddah, hamza above/below
        | '\u{0670}'              // superscript alef
        | '\u{06D6}'..='\u{06ED}' // Quranic annotation marks
        | '\u{0640}'              // tatweel/kashida — decorative elongation
    )
}

/// Character-level confusions that are always safe to fix.
fn canonical_char(c: char) -> Option<char> {
    Some(match c {
        // Arabic Yeh / Alef Maksura → Persian Yeh
        '\u{064A}' | '\u{0649}' | '\u{06CD}' | '\u{06D0}' => '\u{06CC}',
        // Arabic Kaf and its variants → Persian Keheh
        '\u{0643}' | '\u{06AA}' | '\u{06AC}' => '\u{06A9}',
        // Arabic-Indic digits ٠..٩ → Persian ۰..۹
        '\u{0660}'..='\u{0669}' => char::from_u32(c as u32 - 0x0660 + PERSIAN_ZERO).unwrap_or(c),
        // ASCII digits → Persian (اعداد پیش‌فرض پارسی — بخش ۳٫۲)
        '0'..='9' => char::from_u32(c as u32 - '0' as u32 + PERSIAN_ZERO).unwrap_or(c),
        // Heh Goal / Heh with Yeh above → plain Heh
        '\u{06C0}' | '\u{06C1}' | '\u{06C2}' => '\u{0647}',
        // Arabic comma/semicolon/question stay as the Persian forms
        '\u{060C}' => '\u{060C}',
        // Various spaces → plain space (but never ZWNJ, handled separately)
        '\u{00A0}' | '\u{2000}'..='\u{200B}' | '\u{202F}' | '\u{205F}' | '\u{3000}' => ' ',
        _ => return None,
    })
}

/// Folds applied only for search keys, where losing a distinction is cheaper
/// than missing a match.
fn fold_char(c: char) -> Option<char> {
    Some(match c {
        '\u{0622}' | '\u{0623}' | '\u{0625}' | '\u{0671}' => '\u{0627}', // آ أ إ ٱ → ا
        '\u{0629}' => '\u{0647}',                                        // ة → ه
        '\u{0624}' => '\u{0648}',                                        // ؤ → و
        '\u{0626}' => '\u{06CC}',                                        // ئ → ی
        '\u{0621}' => return Some('\0'),                                 // ء → dropped
        _ => return None,
    })
}

/// نرمال‌سازیِ امن — for storage, display and equality of user-visible text.
///
/// Collapses runs of whitespace, trims, removes diacritics, unifies letter and
/// digit variants, and cleans up ZWNJ that sits next to a space or repeats.
pub fn normalize(input: &str) -> String {
    let mut out = String::with_capacity(input.len());
    let mut pending_space = false;
    let mut pending_zwnj = false;

    for raw in input.chars() {
        if is_diacritic(raw) {
            continue;
        }
        let c = canonical_char(raw).unwrap_or(raw);

        if c == ZWNJ {
            // A half-space only means something between two letters.
            if !out.is_empty() && !pending_space {
                pending_zwnj = true;
            }
            continue;
        }
        if c.is_whitespace() {
            if !out.is_empty() {
                pending_space = true;
            }
            // A space wins over a half-space: «پیام ‌رسان» → «پیام رسان».
            pending_zwnj = false;
            continue;
        }
        if pending_space {
            out.push(' ');
            pending_space = false;
        } else if pending_zwnj {
            out.push(ZWNJ);
        }
        pending_zwnj = false;
        out.push(c);
    }
    out
}

/// کلیدِ جست‌وجو — aggressive folding. Not for storage.
pub fn fold_for_search(input: &str) -> String {
    let normalized = normalize(input);
    let mut out = String::with_capacity(normalized.len());
    for c in normalized.chars() {
        if c == ZWNJ {
            continue; // «پیام‌رسان» and «پیامرسان» share one key
        }
        match fold_char(c) {
            Some('\0') => {}
            Some(folded) => out.push(folded),
            None => out.push(c.to_lowercase().next().unwrap_or(c)),
        }
    }
    out
}

/// اعداد پارسی → اعداد لاتین. For anything that must parse as a number.
pub fn to_latin_digits(input: &str) -> String {
    input
        .chars()
        .map(|c| match c as u32 {
            n @ 0x06F0..=0x06F9 => char::from_u32(n - PERSIAN_ZERO + '0' as u32).unwrap_or(c),
            n @ 0x0660..=0x0669 => char::from_u32(n - 0x0660 + '0' as u32).unwrap_or(c),
            _ => c,
        })
        .collect()
}

/// اعداد لاتین → اعداد پارسی. اعداد پیش‌فرض در سره پارسی‌اند.
pub fn to_persian_digits(input: &str) -> String {
    input
        .chars()
        .map(|c| match c {
            '0'..='9' => char::from_u32(c as u32 - '0' as u32 + PERSIAN_ZERO).unwrap_or(c),
            _ => c,
        })
        .collect()
}

/// آیا دو نوشته پس از تاکردن یکی‌اند؟ The comparison the exercise engine uses
/// when grading a typed answer.
///
/// Whitespace is dropped as well as ZWNJ, which `fold_for_search` keeps. A
/// learner who types «گفت وگو» for «گفت‌وگو» knew the word; on most phone
/// keyboards the half-space is buried two layers deep, and marking that
/// wrong grades the keyboard rather than the vocabulary.
///
/// This is deliberately *not* what the search index does: there, a space
/// separates tokens and dropping it would collapse distinct multi-word
/// entries onto one key.
pub fn equivalent(a: &str, b: &str) -> bool {
    fn tight(input: &str) -> String {
        fold_for_search(input)
            .chars()
            .filter(|c| !c.is_whitespace())
            .collect()
    }
    tight(a) == tight(b)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn typed_space_stands_in_for_a_half_space() {
        // On a phone keyboard the ZWNJ is buried; the learner still knew it.
        assert!(equivalent("گفت وگو", "گفت\u{200C}وگو"));
        assert!(equivalent("پیام رسان", "پیام\u{200C}رسان"));
        // But two genuinely different words still differ.
        assert!(!equivalent("سخن", "دشواری"));
    }

    #[test]
    fn search_folding_still_keeps_word_boundaries() {
        // equivalent() drops spaces; the search key must not, or multi-word
        // entries would collide.
        assert_ne!(fold_for_search("راجع به"), fold_for_search("راجعبه"));
    }

    #[test]
    fn arabic_yeh_and_kaf_become_persian() {
        // U+064A ARABIC YEH, U+0643 ARABIC KAF — the single most common
        // source of "identical but unequal" strings in Persian data.
        assert_eq!(normalize("كتاب"), "کتاب");
        assert_eq!(normalize("مي‌ايد"), "می\u{200C}اید");
        assert!(normalize("كتاب").chars().all(|c| c != '\u{0643}'));
    }

    #[test]
    fn diacritics_and_kashida_are_stripped() {
        assert_eq!(normalize("مُحَرِّک"), "محرک");
        assert_eq!(normalize("سـپـاس"), "سپاس"); // tatweel between letters
                                                 // Repeated real letters are not decoration and must survive.
        assert_eq!(normalize("سپاااس"), "سپاااس");
    }

    #[test]
    fn digits_default_to_persian() {
        assert_eq!(normalize("۱۲۳"), "۱۲۳");
        assert_eq!(normalize("123"), "۱۲۳");
        assert_eq!(normalize("١٢٣"), "۱۲۳"); // Arabic-Indic
    }

    #[test]
    fn digit_conversion_round_trips() {
        assert_eq!(to_latin_digits("۱۴۰۳"), "1403");
        assert_eq!(to_persian_digits("1403"), "۱۴۰۳");
        assert_eq!(to_latin_digits(&to_persian_digits("2026")), "2026");
        assert_eq!(to_latin_digits("١٢٣"), "123");
    }

    #[test]
    fn whitespace_is_collapsed_and_trimmed() {
        assert_eq!(normalize("  سپاس   بسیار  "), "سپاس بسیار");
        assert_eq!(normalize("سپاس\n\tبسیار"), "سپاس بسیار");
        assert_eq!(normalize("سپاس\u{00A0}بسیار"), "سپاس بسیار");
    }

    #[test]
    fn half_space_is_preserved_but_cleaned() {
        let with_zwnj = "پیام\u{200C}رسان";
        assert_eq!(normalize(with_zwnj), with_zwnj);
        // Doubled ZWNJ collapses.
        assert_eq!(normalize("پیام\u{200C}\u{200C}رسان"), with_zwnj);
        // ZWNJ touching a space loses to the space.
        assert_eq!(normalize("پیام \u{200C}رسان"), "پیام رسان");
        // Leading and trailing ZWNJ are meaningless.
        assert_eq!(normalize("\u{200C}پیام\u{200C}"), "پیام");
    }

    #[test]
    fn search_folding_unifies_spacing_variants() {
        let forms = ["پیام‌رسان", "پیام رسان", "پیامرسان", "پيام‌رسان"];
        let keys: Vec<String> = forms.iter().map(|f| fold_for_search(f)).collect();
        // «پیام رسان» keeps its space; the rest collapse to one key.
        assert_eq!(keys[0], keys[2]);
        assert_eq!(keys[0], keys[3]);
        assert_eq!(fold_for_search("پیام رسان").replace(' ', ""), keys[0]);
    }

    #[test]
    fn search_folding_unifies_alef_and_hamze() {
        assert_eq!(fold_for_search("آماج"), fold_for_search("اماج"));
        assert_eq!(fold_for_search("مسأله"), fold_for_search("مساله"));
        assert_eq!(fold_for_search("مؤلف"), fold_for_search("مولف"));
        assert_eq!(fold_for_search("پائیز"), fold_for_search("پاییز"));
    }

    #[test]
    fn normalize_keeps_alef_madda_but_folding_drops_it() {
        // آ is a different letter for display; only the search key folds it.
        assert_eq!(normalize("آماج"), "آماج");
        assert_ne!(normalize("آماج"), normalize("اماج"));
        assert!(equivalent("آماج", "اماج"));
    }

    #[test]
    fn equivalence_grades_typed_answers_forgivingly() {
        assert!(equivalent("پرماس", " پرماس "));
        assert!(equivalent("پرْماس", "پرماس"));
        assert!(equivalent("گفت‌وگو", "گفتوگو"));
        assert!(!equivalent("پرماس", "بساوش"));
    }

    #[test]
    fn normalize_is_idempotent() {
        for input in [
            "  مُحَرِّک  ",
            "پیام\u{200C}\u{200C}رسان",
            "كتاب ١٢٣",
            "سـپـ__اس",
            "",
        ] {
            let once = normalize(input);
            assert_eq!(normalize(&once), once, "not idempotent for {input:?}");
        }
    }

    #[test]
    fn folding_is_idempotent() {
        for input in ["آماج", "مسأله", "پیام‌رسان", "۱۲۳"] {
            let once = fold_for_search(input);
            assert_eq!(fold_for_search(&once), once);
        }
    }

    #[test]
    fn empty_and_whitespace_only_inputs_are_empty() {
        assert_eq!(normalize(""), "");
        assert_eq!(normalize("   \n\t "), "");
        assert_eq!(normalize("\u{200C}"), "");
        assert_eq!(fold_for_search(""), "");
    }

    #[test]
    fn latin_text_passes_through_lowercased_in_search_keys() {
        assert_eq!(normalize("Touch"), "Touch");
        assert_eq!(fold_for_search("Touch"), "touch");
    }
}
