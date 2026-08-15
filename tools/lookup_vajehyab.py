#!/usr/bin/env python3
"""واژه‌یاب را می‌پرسد: خاستگاه، تلفظ، معنی و برابرِ پارسی.

چرا این ابزار هست
-----------------
«به پارسی» می‌گوید یک واژه بیگانه است و برابرش چیست، ولی نمی‌گوید **از کدام
زبان** آمده. تا امروز `loan_origin` را دستی می‌نوشتیم، که یعنی حدس.

[واژه‌یاب](https://www.vajehyab.com) ۲۶ فرهنگ را یک‌جا دارد — دهخدا، معین،
عمید، سره، مترادف — و مدخل‌های عمید برچسبِ ماشین‌خوانِ زبان دارند
(`languages: ["ARA"]`) به‌علاوه‌ی گونه‌ی دستوری و تلفظ.

هم‌سنجیِ هم‌نگاشت
----------------
برچسبِ زبان تنها از مدخلی گرفته می‌شود که **سرواژه‌اش دقیقاً همان واژه** است.
بی این قید، «سخن» عربی از کار درمی‌آید، چون عربی واژه‌ی هم‌نگاشتِ «سُخْن» (گرم)
دارد و فرهنگ هر دو را زیر یک جست‌وجو می‌آورد. همان دامی که پیش‌تر «شهر» را
عربی نشان داده بود.

بنابراین خروجی این ابزار **نشانه است، نه حکم**: جاهایی را نشان می‌دهد که
نوشته‌ی ما با فرهنگ نمی‌خواند، تا آدمی نگاه کند.

    python3 tools/lookup_vajehyab.py مشکل حرارت    # واژه‌های نامبرده
    python3 tools/lookup_vajehyab.py --corpus      # همه‌ی وام‌واژه‌های پیکره
    python3 tools/lookup_vajehyab.py --report      # گزارش از روی کش
"""

from __future__ import annotations

import json
import pathlib
import re
import sys
import time
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
CACHE = ROOT / "tools" / ".vajehyab-cache.json"
WORDS = ROOT / "content" / "words"

UA = (
    "sareh-lexicon-research/0.1 "
    "(https://github.com/mehrschad/sareh; open-source Persian vocabulary project)"
)
DELAY_SECONDS = 0.4

INITIAL = re.compile(r"window\.__INITIAL_DATA__\s*=\s*(\{.*?\});?\s*</script>", re.S)

# کدهای زبانِ واژه‌یاب → نامی که در پیکره به کار می‌بریم.
LANGUAGES = {
    "ARA": "عربی",
    "FRA": "فرانسه",
    "ENG": "انگلیسی",
    "TUR": "ترکی",
    "RUS": "روسی",
    "GRE": "یونانی",
    "FAS": "فارسی",
    "PAH": "پهلوی",
    "SAN": "سنسکریت",
    "MON": "مغولی",
}

FOLD = str.maketrans({"ي": "ی", "ك": "ک", "‌": "", "ٔ": ""})
DIACRITICS = dict.fromkeys(range(0x064B, 0x0653), None)


def norm(text: str) -> str:
    return text.translate(FOLD).translate(DIACRITICS).strip()


def load_cache() -> dict:
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict) -> None:
    CACHE.write_text(
        json.dumps(cache, ensure_ascii=False, indent=0, sort_keys=True),
        encoding="utf-8",
    )


def fetch(word: str, tries: int = 3) -> dict | None:
    url = urllib.parse.quote(
        "https://www.vajehyab.com/?q=" + word, safe=":/?&=#"
    )
    for attempt in range(tries):
        try:
            request = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(request, timeout=30) as response:
                page = response.read().decode("utf-8", "replace")
            match = INITIAL.search(page)
            return json.loads(match.group(1)) if match else None
        except Exception:
            if attempt == tries - 1:
                return None
            time.sleep(1.5 * (attempt + 1))
    return None


def extract(payload: dict, word: str) -> dict:
    """آنچه به کار می‌آید، از انبوهِ داده‌ی برگه."""
    result = payload.get("result") or {}
    wordbox = result.get("wordbox") or {}
    sections = {s.get("section"): s.get("description", "") for s in wordbox.get("sections", [])}

    target = norm(word)
    languages: list[str] = []
    kinds: list[str] = []
    for group in result.get("results", []):
        for hit in group.get("hits", []):
            # تنها مدخلی که سرواژه‌اش همان واژه است؛ وگرنه هم‌نگاشت‌ها
            # («سُخْن» عربی در برابرِ «سخن» پارسی) برچسب را آلوده می‌کنند.
            if norm(hit.get("title", "")) != target:
                continue
            raw = hit.get("languages")
            if raw:
                try:
                    values = json.loads(raw) if isinstance(raw, str) else raw
                except Exception:
                    values = [raw]
                for value in values:
                    name = LANGUAGES.get(str(value), str(value))
                    if name not in languages:
                        languages.append(name)
            kind = hit.get("kind")
            if kind and kind not in kinds:
                kinds.append(kind)

    alternatives = [
        a.strip() for a in re.split(r"[،,]", sections.get("alternative", "")) if a.strip()
    ]
    return {
        "pronunciation": wordbox.get("subtitle") or "",
        "meaning": sections.get("meaning", ""),
        "alternatives": alternatives,
        "english": sections.get("dictionary", ""),
        "languages": languages,
        "kinds": kinds,
    }


def lookup(word: str, cache: dict) -> dict:
    if word in cache:
        return cache[word]
    payload = fetch(word)
    entry = extract(payload, word) if payload else {
        "pronunciation": "", "meaning": "", "alternatives": [],
        "english": "", "languages": [], "kinds": [],
    }
    time.sleep(DELAY_SECONDS)
    cache[word] = entry
    return entry


def corpus_loanwords() -> list[str]:
    import yaml

    words = []
    for path in sorted(WORDS.glob("*.yaml")):
        entry = yaml.safe_load(path.read_text(encoding="utf-8"))
        head = entry["loan"].split()[0].strip("ِ")
        if head not in words:
            words.append(head)
    return words


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    cache = load_cache()

    if "--report" in sys.argv:
        tagged = {k: v for k, v in cache.items() if v.get("languages")}
        print(f"کش: {len(cache)} واژه؛ {len(tagged)} تا برچسبِ زبان دارند.")
        for word, data in sorted(tagged.items()):
            print(f"  {word:<14} {'، '.join(data['languages']):<16} {data['pronunciation']}")
        return 0

    words = corpus_loanwords() if "--corpus" in sys.argv else args
    if not words:
        print(__doc__)
        return 2

    asked = 0
    for word in words:
        fresh = word not in cache
        data = lookup(word, cache)
        if fresh:
            asked += 1
            if asked % 50 == 0:
                save_cache(cache)
                print(f"  … {asked} پرسیده شد", flush=True)
        if args:
            print(f"  {word}")
            print(f"     زبان: {'، '.join(data['languages']) or '—'}")
            print(f"     تلفظ: {data['pronunciation'] or '—'}")
            print(f"     گونه: {data['kinds'][0] if data['kinds'] else '—'}")
            print(f"     معنی: {data['meaning'][:90] or '—'}")
            print(f"     برابر: {'، '.join(data['alternatives'][:6]) or '—'}")

    save_cache(cache)
    tagged = sum(1 for w in words if cache.get(w, {}).get("languages"))
    print(f"\n{len(words)} واژه ({asked} تازه)؛ {tagged} تا برچسبِ زبان داشتند.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
