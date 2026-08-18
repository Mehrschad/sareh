#!/usr/bin/env python3
"""مدخلِ یک واژه را از یک فرهنگِ نامبرده می‌گیرد — نه از جست‌وجو.

چرا این ابزار جای `lookup_vajehyab.py` را در سنجشِ خاستگاه می‌گیرد
------------------------------------------------------------------
جست‌وجوی واژه‌یاب هر مدخلی را که سرواژه‌اش همان واژه است برمی‌گرداند، و
هم‌نگاشت‌ها را در هم می‌آمیزد. سه نمونه، که هر سه در پیکره‌ی ما بودند:

    روند   جست‌وجو: «انگلیسی»   ← مدخلِ رُند (round)، نه رَوَند
    آخر    جست‌وجو: «فارسی»     ← مدخلِ آخُر (جای علفِ ستور)، نه آخِر
    تبار   جست‌وجو: «عربی»      ← مدخلِ تَبار (نابودی)، نه تبارِ پارسی

نشانیِ مستقیمِ فرهنگ (`vajehyab.com/amid/<واژه>`) یک مدخل می‌دهد، با تلفظ و
با خاستگاه در میدانِ `kind`:

    آخر  →  (صفت) [عربی: آخِر]              خاستگاه: عربی
    روند →  (اسم)                            خاستگاه: —  (پارسی)
    کانون→  (اسم) [سریانی، مٲخوذ از اکدی]   خاستگاه: سریانی

تلفظ، هم‌نگاشتِ باقی‌مانده را هم آشکار می‌کند: اگر فرهنگ `rond` بگوید و ما
`ravand` بخواهیم، مدخل آنِ ما نیست.

    python3 tools/lookup_dictionary.py آخر روند کانون
    python3 tools/lookup_dictionary.py --corpus     # همه‌ی وام‌واژه‌ها و برابرها
"""

from __future__ import annotations

import html
import json
import pathlib
import re
import sys
import time
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
CACHE = ROOT / "tools" / ".dictionary-cache.json"
WORDS = ROOT / "content" / "words"

UA = (
    "sareh-lexicon-research/0.1 "
    "(https://github.com/mehrschad/sareh; open-source Persian vocabulary project)"
)
DELAY_SECONDS = 0.4

INITIAL = re.compile(r"window\.__INITIAL_DATA__\s*=\s*(\{.*?\});?\s*</script>", re.S)

# ترتیب مهم است: عمید خاستگاه را ماشین‌خوان می‌نویسد، پس نخست از او می‌پرسیم.
# فرهنگستان در پایان می‌آید، چون تنها واژه‌های نوساخته را دارد — «بالگرد»،
# «رایانامه»، «سامانه» — که سه فرهنگِ پیشین هنوز ثبت نکرده‌اند.
DICTIONARIES = ("amid", "dehkhoda", "moein", "farhangestan")

# نام‌های زبان چنان‌که در میدانِ `kind` می‌آیند. عمید تمام می‌نویسد؛ معین
# کوتاه‌نوشت دارد («[ ع . ]»).
LANGUAGE_PATTERNS = [
    (r"عربی", "عربی"),
    (r"فرانسه|فرانسوی", "فرانسه"),
    (r"انگلیسی", "انگلیسی"),
    (r"ترکی", "ترکی"),
    (r"مغولی", "مغولی"),
    (r"روسی", "روسی"),
    (r"یونانی", "یونانی"),
    (r"سریانی", "سریانی"),
    (r"اکدی", "اکدی"),
    (r"عبری", "عبری"),
    (r"آرامی", "آرامی"),
    (r"سنسکریت", "سنسکریت"),
    (r"هندی", "هندی"),
    (r"چینی", "چینی"),
    (r"ژاپنی", "ژاپنی"),
    (r"لاتین", "لاتین"),
    (r"آلمانی", "آلمانی"),
    (r"ایتالیایی", "ایتالیایی"),
    (r"اسپانیایی", "اسپانیایی"),
    (r"پرتغالی", "پرتغالی"),
    (r"ارمنی", "ارمنی"),
    (r"پهلوی|فارسی میانه", "پهلوی"),
    (r"اوستایی", "اوستایی"),
    (r"فارسی باستان", "فارسی باستان"),
]
ABBREVIATIONS = {
    "ع": "عربی", "فر": "فرانسه", "انگ": "انگلیسی", "تر": "ترکی",
    "روس": "روسی", "یو": "یونانی", "پهل": "پهلوی", "په": "پهلوی",
    "سنس": "سنسکریت",
    "مغ": "مغولی", "لات": "لاتین", "آل": "آلمانی", "ایت": "ایتالیایی",
    "سر": "سریانی", "عب": "عبری", "ارم": "ارمنی", "هن": "هندی",
}
BRACKETS = re.compile(r"[\[\(]([^\]\)]*)[\]\)]")
ABBREVIATION = re.compile(r"^\s*([آ-ی]{1,4})\s*\.\s*$")
TAGS = re.compile(r"<[^>]+>")


DIACRITICS = dict.fromkeys(range(0x064B, 0x0653), None)
FOLD = str.maketrans({"ي": "ی", "ك": "ک", "ٔ": ""})


def bare(word: str) -> str:
    """صورتِ بی‌اعراب برای پرسش. فرهنگ سرواژه را بی‌اعراب نمایه کرده است؛
    پرسیدنِ «دَم» پاسخی نمی‌آورد، «دم» می‌آورد."""
    return word.translate(FOLD).translate(DIACRITICS).strip()


def strip_html(text: str) -> str:
    return html.unescape(TAGS.sub(" ", text or "")).strip()


def origins(kind: str) -> list[str]:
    """زبان‌هایی که میدانِ `kind` نام می‌برد، به ترتیبِ آمدن."""
    return [name for name, _form in origin_forms(kind)]


def origin_forms(kind: str) -> list[tuple[str, str]]:
    """جفتِ (زبان، صورتِ اصلی) از میدانِ `kind`.

    عمید صورت را پس از دونقطه می‌آورد — «[پهلوی: mazg]»، «[عربی: آخِر]» — و
    همین، ریشه‌ی مستندی است که میدانِ `roots` می‌خواهد.
    """
    found: list[tuple[str, str]] = []
    seen: set[str] = set()
    for chunk in BRACKETS.findall(kind or ""):
        for piece in re.split(r"[،,]", chunk):
            match = ABBREVIATION.match(piece)
            if match and match.group(1) in ABBREVIATIONS:
                hits = [(0, ABBREVIATIONS[match.group(1)])]
            else:
                # به ترتیبِ آمدن در متن، نه به ترتیبِ فهرست: «[پهلوی: zamān و
                # عربی]» یعنی واژه پهلوی است و عربی هم آن را گرفته — اگر
                # «عربی» را نخست بخوانیم، واژه‌ای پارسی را وام‌واژه می‌شماریم.
                hits = sorted(
                    (found_at.start(), name)
                    for pattern, name in LANGUAGE_PATTERNS
                    if (found_at := re.search(pattern, piece))
                )
            for _position, name in hits:
                if name in seen:
                    continue
                seen.add(name)
                _, _, tail = piece.partition(":")
                found.append((name, re.split(r"\s+و\s+", tail.strip())[0]))
    return found


def fetch(word: str, dictionary: str, tries: int = 3) -> dict | None:
    url = urllib.parse.quote(
        f"https://www.vajehyab.com/{dictionary}/{bare(word)}", safe=":/?&=#"
    )
    for attempt in range(tries):
        try:
            request = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(request, timeout=30) as response:
                page = response.read().decode("utf-8", "replace")
            match = INITIAL.search(page)
            if not match:
                return None
            document = (json.loads(match.group(1)).get("result") or {}).get("document")
            return document or None
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return None            # فرهنگ این واژه را ندارد؛ پاسخِ درست است
            if attempt == tries - 1:
                return None
            time.sleep(1.5 * (attempt + 1))
        except Exception:
            if attempt == tries - 1:
                return None
            time.sleep(1.5 * (attempt + 1))
    return None


def load_cache() -> dict:
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict) -> None:
    CACHE.write_text(
        json.dumps(cache, ensure_ascii=False, indent=0, sort_keys=True),
        encoding="utf-8",
    )


def lookup(word: str, cache: dict, all_dictionaries: bool = False) -> dict:
    """مدخل‌های این واژه. پیش‌فرض: تا نخستین فرهنگی که دارَدش.

    `all_dictionaries` وقتی به کار می‌آید که خاستگاه بحث‌انگیز است و می‌خواهیم
    هر سه فرهنگ را کنار هم ببینیم.
    """
    # کلیدِ کش هم بی‌اعراب است، وگرنه «دَم» و «دم» دو مدخلِ جدا می‌شوند.
    word = bare(word)
    record = cache.setdefault(word, {})
    for dictionary in DICTIONARIES:
        if dictionary in record:
            if record[dictionary] and not all_dictionaries:
                return record
            continue
        document = fetch(word, dictionary)
        time.sleep(DELAY_SECONDS)
        record[dictionary] = {
            "kind": strip_html(document.get("kind", "")),
            "pronunciation": strip_html(document.get("pronunciation", "")),
            "definition": strip_html(document.get("description", ""))[:400],
        } if document else None
        if record[dictionary] and not all_dictionaries:
            break
    return record


def summarize(record: dict) -> dict:
    """یک نمای یگانه از سه فرهنگ."""
    attested = [d for d in DICTIONARIES if record.get(d)]
    langs: list[str] = []
    for dictionary in DICTIONARIES:
        entry = record.get(dictionary)
        if not entry:
            continue
        for name in origins(entry["kind"]):
            if name not in langs:
                langs.append(name)
    pronunciation = ""
    for dictionary in DICTIONARIES:
        entry = record.get(dictionary)
        if entry and entry.get("pronunciation"):
            pronunciation = entry["pronunciation"]
            break
    return {"attested": attested, "languages": langs, "pronunciation": pronunciation}


def corpus_tokens() -> list[str]:
    import yaml

    words: list[str] = []
    for path in sorted(WORDS.glob("*.yaml")):
        entry = yaml.safe_load(path.read_text(encoding="utf-8"))
        for field in ("loan", "sare"):
            for token in entry[field].split():
                head = token.strip("ِ")
                if head and head not in words:
                    words.append(head)
    return words


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    cache = load_cache()
    every = "--all" in sys.argv
    words = corpus_tokens() if "--corpus" in sys.argv else args
    if not words:
        print(__doc__)
        return 2

    asked = 0
    for word in words:
        before = json.dumps(cache.get(word, {}), sort_keys=True)
        record = lookup(word, cache, all_dictionaries=every or bool(args))
        if json.dumps(record, sort_keys=True) != before:
            asked += 1
            if asked % 40 == 0:
                save_cache(cache)
                print(f"  … {asked} پرسیده شد", flush=True)
        if args:
            view = summarize(record)
            print(f"\n  {word}   [{'، '.join(view['attested']) or 'در هیچ فرهنگی نیست'}]")
            print(f"     خاستگاه: {'، '.join(view['languages']) or '— (پارسی)'}")
            print(f"     تلفظ: {view['pronunciation'] or '—'}")
            for dictionary in DICTIONARIES:
                entry = record.get(dictionary)
                if entry:
                    print(f"     {dictionary}: {entry['kind']} {entry['definition'][:100]}")

    save_cache(cache)
    if not args:
        print(f"\n{len(words)} واژه ({asked} تازه پرسیده شد).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
