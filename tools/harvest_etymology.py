#!/usr/bin/env python3
"""برداشتِ ریشه‌ی پهلوی و اوستایی از ویکی‌واژه.

چرا این ابزار هست: نوشتنِ ریشه از حافظه یعنی ساختنِ ریشه. این ابزار صورت‌های
پهلوی (`pal`) و اوستایی (`ae`) را از بخشِ ریشه‌شناسیِ ویکی‌واژه‌ی انگلیسی بیرون
می‌کشد تا هر ریشه‌ای که در پیکره می‌نشیند، دستِ‌کم یک نشانیِ بیرونی داشته باشد.

**ویکی‌واژه منبعِ دستِ‌سوم است.** خروجی این ابزار `status: proposed` می‌گیرد و
تا سنجیده‌نشدن با «فرهنگ ریشه‌شناختی زبان فارسی» (حسن‌دوست، فرهنگستان) یا
MacKenzie تأییدشده به‌شمار نمی‌رود. بنگرید به content/SOURCES.md.

    python3 tools/harvest_etymology.py            # همه‌ی واژه‌های بی‌ریشه
    python3 tools/harvest_etymology.py خرد مهر    # واژه‌های نامبرده
    python3 tools/harvest_etymology.py --apply    # نوشتن در content/words/
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
WORDS = ROOT / "content" / "words"
CACHE = ROOT / "tools" / ".etymology-cache.json"

UA = (
    "sareh-lexicon-research/0.1 "
    "(https://github.com/mehrschad/sareh; open-source Persian vocabulary project)"
)
# ویکی‌مدیا سختگیر است و حق دارد؛ آرام می‌رویم.
DELAY_SECONDS = 0.4

# {{inh|fa|pal|𐭧𐭥𐭠𐭲|tr=xrad}} · {{der|fa|ae|𐬀𐬴𐬀}} · {{inh|fa|peo|...}}
# پهلوی، اوستایی و پارسیِ باستان — هر سه‌ای که خواسته شده‌اند.
LANGUAGES = {"pal": "pahlavi", "ae": "avestan", "peo": "old_persian"}
TEMPLATE = re.compile(
    r"\{\{(?:inh|der|bor|inh\+|der\+|bor\+|desc)\|fa\|(pal|ae|peo)\|([^}]*)\}\}"
)


def load_cache() -> dict:
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict) -> None:
    CACHE.write_text(
        json.dumps(cache, ensure_ascii=False, indent=1, sort_keys=True),
        encoding="utf-8",
    )


def fetch_wikitext(word: str, tries: int = 4) -> str:
    url = (
        "https://en.wiktionary.org/w/api.php?action=parse&page="
        + urllib.parse.quote(word)
        + "&prop=wikitext&format=json&formatversion=2"
    )
    for attempt in range(tries):
        try:
            request = urllib.request.Request(
                url, headers={"User-Agent": UA, "Accept": "application/json"}
            )
            with urllib.request.urlopen(request, timeout=30) as response:
                payload = json.load(response)
            return payload.get("parse", {}).get("wikitext", "") or ""
        except Exception:
            if attempt == tries - 1:
                return ""
            time.sleep(2**attempt)
    return ""


def persian_section(wikitext: str) -> str:
    """تنها بخشِ فارسیِ برگه — وگرنه ریشه‌ی واژه‌ی عثمانی را برمی‌داریم."""
    match = re.search(r"\n==\s*Persian\s*==\n(.*?)(?=\n==[^=]|\Z)", wikitext, re.S)
    return match.group(1) if match else ""


def clean(raw: str) -> str | None:
    """`𐭧𐭥𐭠𐭲|tr=xrad` → `xrad` — آوانویسی بر خطِ میخی برتری دارد.

    خطِ پهلوی و اوستایی برای کاربر خواندنی نیست؛ اگر آوانویسی نبود، مدخل
    بی‌ریشه می‌ماند تا کسی دستی پرش کند.
    """
    parts = [p.strip() for p in raw.split("|")]
    for prefix in ("tr=", "ts="):
        value = next((p[3:].strip() for p in parts if p.startswith(prefix)), None)
        if value:
            return value
    head = parts[0].split("<")[0].strip() if parts else ""
    # «-» یعنی «صورتی ثبت نشده»؛ ریشه‌ی خالی بدتر از نبودِ ریشه است.
    if head in {"", "-", "–", "—", "?"}:
        return None
    # خطِ پهلوی و اوستاییِ بی‌آوانویسی برای کاربر خواندنی نیست.
    if any(ord(c) > 0x2000 for c in head):
        return None
    return head


def roots_for(word: str, cache: dict) -> dict:
    if word in cache:
        return cache[word]
    section = persian_section(fetch_wikitext(word))
    time.sleep(DELAY_SECONDS)
    found = {"pahlavi": None, "avestan": None, "old_persian": None}
    for language, body in TEMPLATE.findall(section):
        value = clean(body)
        if not value:
            continue
        key = LANGUAGES[language]
        if found[key] is None:
            found[key] = value
    cache[word] = found
    return found


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    apply_changes = "--apply" in sys.argv

    cache = load_cache()
    files = sorted(WORDS.glob("*.yaml"))
    if not files:
        print("پوشه‌ی واژه‌ها خالی است.")
        return 1

    import yaml

    found = filled = 0
    for path in files:
        entry = yaml.safe_load(path.read_text(encoding="utf-8"))
        if args and entry["sare"] not in args:
            continue
        roots = entry.get("roots") or {}
        if all(roots.get(k) for k in ("pahlavi", "avestan", "old_persian")):
            continue

        harvested = roots_for(entry["sare"], cache)
        if not any(harvested.values()):
            continue
        found += 1
        line = f"  {entry['sare']:<14}"
        if harvested["pahlavi"]:
            line += f" pal={harvested['pahlavi']:<16}"
        if harvested["avestan"]:
            line += f" ae={harvested['avestan']:<14}"
        if harvested["old_persian"]:
            line += f" peo={harvested['old_persian']}"
        print(line)

        if apply_changes:
            changed = False
            for key in ("pahlavi", "avestan", "old_persian"):
                if not roots.get(key) and harvested[key]:
                    roots[key] = harvested[key]
                    changed = True
            if changed:
                entry["roots"] = roots
                path.write_text(
                    yaml.dump(
                        entry,
                        allow_unicode=True,
                        sort_keys=False,
                        default_flow_style=False,
                        width=100,
                    ),
                    encoding="utf-8",
                )
                filled += 1

    save_cache(cache)
    print(f"\n{found} واژه ریشه داشت؛ {filled} فایل نوشته شد.")
    if not apply_changes:
        print("برای نوشتن: --apply")
    return 0


if __name__ == "__main__":
    sys.exit(main())
