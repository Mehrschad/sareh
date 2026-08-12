//! اعتبارسنجِ محتوا — the gate every content pull request passes through.
//!
//! ```text
//! cargo run -p sareh-tools --bin validate_words            # سنجش
//! cargo run -p sareh-tools --bin validate_words -- --stats # سنجش + گزارش
//! ```
//!
//! Exit code 0 means the corpus is publishable. Anything else prints one line
//! per problem, in the order a reviewer would want to fix them.

use std::collections::BTreeMap;
use std::path::{Path, PathBuf};
use std::process::ExitCode;

use sareh_core::validate::{validate_corpus, validate_file, Problem, Word};

const WORDS_DIR: &str = "content/words";
const LESSONS_DIR: &str = "content/lessons";

fn main() -> ExitCode {
    let show_stats = std::env::args().any(|a| a == "--stats");
    let root = repo_root();

    let words_dir = root.join(WORDS_DIR);
    let files = match yaml_files(&words_dir) {
        Ok(files) => files,
        Err(e) => {
            eprintln!("{} خوانده نشد: {e}", words_dir.display());
            return ExitCode::FAILURE;
        }
    };
    if files.is_empty() {
        eprintln!("هیچ واژه‌ای در {} نیست", words_dir.display());
        return ExitCode::FAILURE;
    }

    let mut problems: Vec<Problem> = Vec::new();
    let mut words: Vec<(PathBuf, Word)> = Vec::new();

    for path in &files {
        match std::fs::read_to_string(path) {
            Ok(source) => {
                let (word, mut found) = validate_file(path, &source);
                problems.append(&mut found);
                if let Some(word) = word {
                    words.push((path.clone(), word));
                }
            }
            Err(e) => problems.push(Problem {
                file: path.clone(),
                message: format!("خوانده نشد: {e}"),
            }),
        }
    }

    problems.extend(validate_corpus(&words));
    problems.extend(check_lessons(&root.join(LESSONS_DIR), &words));

    problems.sort_by(|a, b| a.file.cmp(&b.file).then_with(|| a.message.cmp(&b.message)));

    if show_stats {
        print_stats(&words);
    }

    if problems.is_empty() {
        println!("✓ {} واژه سنجیده شد؛ ایرادی نبود.", words.len());
        return ExitCode::SUCCESS;
    }
    for problem in &problems {
        println!("✗ {problem}");
    }
    println!("\n{} ایراد در {} واژه.", problems.len(), words.len());
    ExitCode::FAILURE
}

/// Walk up from the current directory until the content tree appears, so the
/// tool works from the repo root or from any crate directory.
fn repo_root() -> PathBuf {
    let mut dir = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    loop {
        if dir.join(WORDS_DIR).is_dir() {
            return dir;
        }
        if !dir.pop() {
            return std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
        }
    }
}

fn yaml_files(dir: &Path) -> std::io::Result<Vec<PathBuf>> {
    let mut files: Vec<PathBuf> = std::fs::read_dir(dir)?
        .filter_map(Result::ok)
        .map(|e| e.path())
        .filter(|p| {
            p.extension()
                .is_some_and(|ext| ext == "yaml" || ext == "yml")
        })
        .collect();
    files.sort();
    Ok(files)
}

/// درس‌ها نباید به واژه‌ی ناموجود ارجاع دهند، و هیچ واژه‌ای نباید بی‌منزل بماند.
fn check_lessons(dir: &Path, words: &[(PathBuf, Word)]) -> Vec<Problem> {
    let mut problems = Vec::new();
    let Ok(files) = yaml_files(dir) else {
        return vec![Problem {
            file: dir.to_path_buf(),
            message: "پوشه‌ی درس‌ها خوانده نشد".into(),
        }];
    };

    let known: Vec<&str> = words.iter().map(|(_, w)| w.id.as_str()).collect();
    let mut placed: Vec<String> = Vec::new();

    for path in files {
        let Ok(source) = std::fs::read_to_string(&path) else {
            continue;
        };
        let doc: serde_yaml::Value = match serde_yaml::from_str(&source) {
            Ok(doc) => doc,
            Err(e) => {
                problems.push(Problem {
                    file: path.clone(),
                    message: format!("YAML: {e}"),
                });
                continue;
            }
        };
        let stations = doc.get("stations").and_then(|s| s.as_sequence());
        let Some(stations) = stations else {
            problems.push(Problem {
                file: path.clone(),
                message: "stations ندارد".into(),
            });
            continue;
        };
        if !(5..=8).contains(&stations.len()) {
            problems.push(Problem {
                file: path.clone(),
                message: format!("هر خان ۵ تا ۸ منزل دارد، نه {}", stations.len()),
            });
        }
        for station in stations {
            let id = station.get("id").and_then(|v| v.as_str()).unwrap_or("?");
            let exercises = station
                .get("exercises")
                .and_then(|v| v.as_sequence())
                .map(|s| s.len())
                .unwrap_or(0);
            // قاعده‌ی بخش ۵٫۳: یکنواختی، قاتل تداوم است.
            if exercises < 4 {
                problems.push(Problem {
                    file: path.clone(),
                    message: format!("منزلِ «{id}» تنها {exercises} گونه تمرین دارد؛ کف ۴ است"),
                });
            }
            let ids = station.get("words").and_then(|v| v.as_sequence());
            let Some(ids) = ids else {
                problems.push(Problem {
                    file: path.clone(),
                    message: format!("منزلِ «{id}» واژه ندارد"),
                });
                continue;
            };
            if !(8..=12).contains(&ids.len()) {
                problems.push(Problem {
                    file: path.clone(),
                    message: format!("منزلِ «{id}»: هر منزل ۸ تا ۱۲ واژه دارد، نه {}", ids.len()),
                });
            }
            for value in ids {
                let word_id = value.as_str().unwrap_or_default();
                if !known.contains(&word_id) {
                    problems.push(Problem {
                        file: path.clone(),
                        message: format!("منزلِ «{id}» به واژه‌ی ناموجودِ «{word_id}» ارجاع می‌دهد"),
                    });
                } else {
                    placed.push(word_id.to_string());
                }
            }
        }
    }

    for (path, word) in words {
        if !placed.contains(&word.id) {
            problems.push(Problem {
                file: path.clone(),
                message: "این واژه در هیچ منزلی نیست".into(),
            });
        }
    }
    problems
}

fn print_stats(words: &[(PathBuf, Word)]) {
    let mut acceptance: BTreeMap<&str, usize> = BTreeMap::new();
    let mut status: BTreeMap<&str, usize> = BTreeMap::new();
    let mut origin: BTreeMap<&str, usize> = BTreeMap::new();
    let mut difficulty: BTreeMap<u8, usize> = BTreeMap::new();
    let mut without_roots = 0usize;

    for (_, word) in words {
        *acceptance.entry(&word.acceptance).or_default() += 1;
        *status.entry(&word.status).or_default() += 1;
        *origin.entry(&word.loan_origin).or_default() += 1;
        *difficulty.entry(word.difficulty).or_default() += 1;
        if word.roots.pahlavi.is_none() && word.roots.avestan.is_none() {
            without_roots += 1;
        }
    }

    println!("\n— گزارشِ پیکره —");
    println!("واژه‌ها: {}", words.len());
    for (label, map) in [
        ("پذیرش", &acceptance),
        ("وضعیت", &status),
        ("خاستگاه", &origin),
    ] {
        let line: Vec<String> = map.iter().map(|(k, v)| format!("{k}: {v}")).collect();
        println!("{label}: {}", line.join("  ·  "));
    }
    let line: Vec<String> = difficulty
        .iter()
        .map(|(k, v)| format!("{k}: {v}"))
        .collect();
    println!("دشواری: {}", line.join("  ·  "));
    println!("بی‌ریشه‌ی ثبت‌شده: {without_roots}");
    println!("(«verified» دستی است — بنگرید به content/SOURCES.md)\n");
}
