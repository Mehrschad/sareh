//! جست‌وجوی فازی روی واژه‌نامه
//!
//! Budget: under 5ms for a query across 5000+ entries, on a mid-range phone —
//! which is why this is here and not in Dart. The index is built once at
//! startup from the content YAML and then only read.
//!
//! Matching runs in tiers so that an exact hit never loses to a fuzzy one, and
//! the expensive edit-distance pass only sees candidates that survive two cheap
//! filters (length band, then character-bag overlap).

use crate::normalize::fold_for_search;

/// Edit distance beyond this is not a typo, it is a different word.
const MAX_EDITS: usize = 2;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Entry {
    pub id: String,
    pub sare: String,
    pub loan: String,
    pub english: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Field {
    Sare,
    Loan,
    English,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Hit {
    pub id: String,
    /// Which field produced the match — the UI labels the row with it.
    pub field: Field,
    /// Higher is better. Tiers never overlap, so ordering is stable.
    pub score: u32,
}

struct Key {
    field: Field,
    entry: usize,
    chars: Vec<char>,
    /// Presence bitmap of the key's characters, for a cheap overlap filter.
    bag: u64,
}

pub struct WordIndex {
    entries: Vec<Entry>,
    keys: Vec<Key>,
}

fn char_bag(chars: &[char]) -> u64 {
    chars
        .iter()
        .fold(0u64, |bag, c| bag | 1u64 << ((*c as u32) % 64))
}

impl WordIndex {
    pub fn build(entries: Vec<Entry>) -> Self {
        let mut keys = Vec::with_capacity(entries.len() * 3);
        for (i, entry) in entries.iter().enumerate() {
            for (field, text) in [
                (Field::Sare, &entry.sare),
                (Field::Loan, &entry.loan),
                (Field::English, &entry.english),
            ] {
                let folded = fold_for_search(text);
                if folded.is_empty() {
                    continue;
                }
                let chars: Vec<char> = folded.chars().collect();
                keys.push(Key {
                    field,
                    entry: i,
                    bag: char_bag(&chars),
                    chars,
                });
            }
        }
        WordIndex { entries, keys }
    }

    pub fn len(&self) -> usize {
        self.entries.len()
    }

    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    pub fn entry(&self, id: &str) -> Option<&Entry> {
        self.entries.iter().find(|e| e.id == id)
    }

    /// جست‌وجو. Returns at most `limit` hits, best first.
    pub fn search(&self, query: &str, limit: usize) -> Vec<Hit> {
        let folded = fold_for_search(query);
        if folded.is_empty() || limit == 0 {
            return Vec::new();
        }
        let needle: Vec<char> = folded.chars().collect();
        let needle_bag = char_bag(&needle);

        // Best score per entry — an entry matching on two fields appears once.
        let mut best: Vec<Option<(Field, u32)>> = vec![None; self.entries.len()];

        for key in &self.keys {
            let Some(score) = score_key(&needle, needle_bag, key) else {
                continue;
            };
            let slot = &mut best[key.entry];
            if slot.is_none_or(|(_, existing)| score > existing) {
                *slot = Some((key.field, score));
            }
        }

        let mut hits: Vec<Hit> = best
            .into_iter()
            .enumerate()
            .filter_map(|(i, slot)| {
                slot.map(|(field, score)| Hit {
                    id: self.entries[i].id.clone(),
                    field,
                    score,
                })
            })
            .collect();

        // Ties break by id so results never shuffle between identical queries.
        hits.sort_by(|a, b| b.score.cmp(&a.score).then_with(|| a.id.cmp(&b.id)));
        hits.truncate(limit);
        hits
    }
}

fn score_key(needle: &[char], needle_bag: u64, key: &Key) -> Option<u32> {
    let hay = &key.chars;

    if hay == needle {
        return Some(1000);
    }
    if hay.starts_with(needle) {
        // Shorter keys are better prefix matches: «مهر» beats «مهربانی» for "مهر".
        return Some(900 - (hay.len() - needle.len()).min(99) as u32);
    }
    if let Some(pos) = subslice_position(hay, needle) {
        return Some(700 - pos.min(99) as u32);
    }

    // Fuzzy tier. Two cheap rejections before the O(n·m) work.
    let length_gap = hay.len().abs_diff(needle.len());
    if length_gap > MAX_EDITS {
        return None;
    }
    if (needle_bag & key.bag).count_ones() + MAX_EDITS as u32 * 2
        < needle_bag.count_ones().min(key.bag.count_ones())
    {
        return None;
    }
    let distance = bounded_levenshtein(hay, needle, MAX_EDITS)?;
    Some(500 - (distance as u32) * 100)
}

fn subslice_position(hay: &[char], needle: &[char]) -> Option<usize> {
    if needle.len() > hay.len() {
        return None;
    }
    (0..=hay.len() - needle.len()).find(|&i| &hay[i..i + needle.len()] == needle)
}

/// Levenshtein distance, abandoned as soon as it cannot come in under `max`.
fn bounded_levenshtein(a: &[char], b: &[char], max: usize) -> Option<usize> {
    if a.len().abs_diff(b.len()) > max {
        return None;
    }
    let mut previous: Vec<usize> = (0..=b.len()).collect();
    let mut current = vec![0usize; b.len() + 1];

    for (i, &ac) in a.iter().enumerate() {
        current[0] = i + 1;
        let mut row_best = current[0];
        for (j, &bc) in b.iter().enumerate() {
            let cost = usize::from(ac != bc);
            current[j + 1] = (previous[j] + cost)
                .min(previous[j + 1] + 1)
                .min(current[j] + 1);
            row_best = row_best.min(current[j + 1]);
        }
        if row_best > max {
            return None;
        }
        std::mem::swap(&mut previous, &mut current);
    }
    let distance = previous[b.len()];
    (distance <= max).then_some(distance)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn entry(id: &str, sare: &str, loan: &str, english: &str) -> Entry {
        Entry {
            id: id.into(),
            sare: sare.into(),
            loan: loan.into(),
            english: english.into(),
        }
    }

    fn index() -> WordIndex {
        WordIndex::build(vec![
            entry("parmas-lams", "پرماس", "لمس", "touch"),
            entry("basavesh-lamese", "بساوش", "لامسه", "sense of touch"),
            entry("sepas-tashakkor", "سپاس", "تشکر", "thanks"),
            entry("mehr-mohabbat", "مهر", "محبت", "affection"),
            entry("mehrabani-lotf", "مهربانی", "لطف", "kindness"),
            entry("payamresan-messenger", "پیام‌رسان", "مسنجر", "messenger"),
        ])
    }

    #[test]
    fn exact_match_outranks_everything() {
        let hits = index().search("مهر", 10);
        assert_eq!(hits[0].id, "mehr-mohabbat");
        assert_eq!(hits[0].score, 1000);
        assert_eq!(hits[0].field, Field::Sare);
    }

    #[test]
    fn prefix_match_prefers_the_shorter_word() {
        let hits = index().search("مهربا", 10);
        assert_eq!(hits[0].id, "mehrabani-lotf");
    }

    #[test]
    fn searching_the_loanword_finds_the_sare_entry() {
        let hits = index().search("لمس", 10);
        assert_eq!(hits[0].id, "parmas-lams");
        assert_eq!(hits[0].field, Field::Loan);
    }

    #[test]
    fn english_is_searchable_too() {
        let hits = index().search("touch", 10);
        assert!(hits
            .iter()
            .any(|h| h.id == "parmas-lams" && h.field == Field::English));
    }

    #[test]
    fn typos_still_find_the_word() {
        // One substitution.
        let hits = index().search("پرمیس", 10);
        assert_eq!(hits[0].id, "parmas-lams");
        // One deletion.
        let hits = index().search("سپس", 10);
        assert!(hits.iter().any(|h| h.id == "sepas-tashakkor"));
    }

    #[test]
    fn arabic_keyboard_input_finds_persian_entries() {
        // Typed with Arabic Yeh and no half-space.
        let hits = index().search("پيام رسان", 10);
        assert!(hits.iter().any(|h| h.id == "payamresan-messenger"));
        let hits = index().search("پیامرسان", 10);
        assert_eq!(hits[0].id, "payamresan-messenger");
    }

    #[test]
    fn unrelated_queries_return_nothing() {
        assert!(index().search("قانون‌گذاری", 10).is_empty());
    }

    #[test]
    fn empty_query_returns_nothing() {
        assert!(index().search("", 10).is_empty());
        assert!(index().search("   ", 10).is_empty());
        assert!(index().search("مهر", 0).is_empty());
    }

    #[test]
    fn an_entry_appears_at_most_once() {
        // «لمس» hits both the loan of parmas and, fuzzily, «لامسه».
        let hits = index().search("لمس", 10);
        let mut ids: Vec<&str> = hits.iter().map(|h| h.id.as_str()).collect();
        ids.sort_unstable();
        let count = ids.len();
        ids.dedup();
        assert_eq!(ids.len(), count, "duplicate entry in results");
    }

    #[test]
    fn results_are_capped_and_ordered() {
        let hits = index().search("م", 3);
        assert!(hits.len() <= 3);
        for pair in hits.windows(2) {
            assert!(pair[0].score >= pair[1].score);
        }
    }

    #[test]
    fn results_are_deterministic() {
        let idx = index();
        assert_eq!(idx.search("لمس", 10), idx.search("لمس", 10));
    }

    #[test]
    fn bounded_distance_rejects_far_words() {
        let a: Vec<char> = "پرماس".chars().collect();
        let b: Vec<char> = "بساوش".chars().collect();
        assert_eq!(bounded_levenshtein(&a, &b, 2), None);
        let c: Vec<char> = "پرماص".chars().collect();
        assert_eq!(bounded_levenshtein(&a, &c, 2), Some(1));
        assert_eq!(bounded_levenshtein(&a, &a, 2), Some(0));
    }

    #[test]
    fn lookup_by_id_works() {
        let idx = index();
        assert_eq!(idx.entry("مهر"), None);
        assert_eq!(idx.entry("mehr-mohabbat").unwrap().sare, "مهر");
        assert_eq!(idx.len(), 6);
        assert!(!idx.is_empty());
    }

    #[test]
    fn search_stays_within_budget_on_a_large_index() {
        // بخش ۹٫۲: جست‌وجوی فازی روی ۵۰۰۰+ واژه باید زیر ۵ms باشد.
        let syllables = [
            "پر", "ما", "س", "بس", "او", "ش", "مه", "ر", "با", "نی", "سپ", "اس",
        ];
        let entries: Vec<Entry> = (0..5000)
            .map(|i| {
                let word: String = (0..4)
                    .map(|k| syllables[(i * 7 + k * 3) % syllables.len()])
                    .collect();
                entry(
                    &format!("w{i}"),
                    &word,
                    &format!("وام{i}"),
                    &format!("gloss{i}"),
                )
            })
            .collect();
        let idx = WordIndex::build(entries);
        assert_eq!(idx.len(), 5000);

        let queries = ["پرماس", "مهربانی", "سپاسما", "بساوش", "وام۴۲", "gloss900"];
        let start = std::time::Instant::now();
        let rounds = 50;
        for _ in 0..rounds {
            for q in queries {
                idx.search(q, 20);
            }
        }
        let per_query = start.elapsed() / (rounds * queries.len() as u32);
        println!(
            "fuzzy search: {per_query:?} per query over {} entries",
            idx.len()
        );

        // Debug builds run roughly an order of magnitude slower than the
        // release binary the app ships, so only release asserts the real budget.
        let budget = if cfg!(debug_assertions) {
            std::time::Duration::from_millis(50)
        } else {
            std::time::Duration::from_millis(5)
        };
        assert!(per_query < budget, "{per_query:?} exceeds {budget:?}");
    }
}
