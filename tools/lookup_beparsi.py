#!/usr/bin/env python3
"""برابرهای پارسی را از «به پارسی» (beparsi.com) می‌پرسد.

چرا این ابزار هست
-----------------
گزینشِ برابرِ پارسی از روی دانشِ شخصی، هر قدر هم دقیق، سند نیست. «به پارسی»
سامانه‌ای است که از ۱۳۸۷ به کوششِ حسین اقوامی گردآوری شده و سیاستِ ویرایشی‌اش
همان چیزی است که سره به آن نیاز دارد:

    «در این سامانه واژه‌ای ساخته نمی‌شود، بلکه واژه‌های پارسی که از دیرباز در
     زبان و فرهنگِ پارسی‌زبان‌ها هستند پیشنهاد می‌شوند.»

پس داورِ اینکه «آیا این واژه بیگانه است و برابرِ پارسی دارد» این سامانه است،
نه صافیِ املایی و نه گمانِ ما. هر مدخلی که از اینجا می‌آید، نشانیِ بیرونی
دارد: `https://www.beparsi.com/q/<واژه>`.

کاربرد
------
    python3 tools/lookup_beparsi.py مشکل حرارت      # واژه‌های نامبرده
    python3 tools/lookup_beparsi.py --top 2000      # پویشِ فهرستِ بسامدی
    python3 tools/lookup_beparsi.py --report        # گزارش از روی کش

نکته‌ی ادب: یک درخواست در ثانیه، با کش. سامانه‌ای که رایگان در دسترس گذاشته
شده را نباید کوبید.
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
CACHE = ROOT / "tools" / ".beparsi-cache.json"

BASE = "https://www.beparsi.com"
UA = (
    "sareh-lexicon-research/0.1 "
    "(https://github.com/mehrschad/sareh; open-source Persian vocabulary project)"
)
DELAY_SECONDS = 1.0

# <span class='nPR'><b>سرواژه</b>: برابر  - برابر  - برابر  </span>
ROW = re.compile(r"<span class='nPR'><b>(.*?)</b>\s*:\s*(.*?)</span>", re.S)
TAGS = re.compile(r"<[^>]+>")

# نویسه‌های عربی که باید به پارسی برگردند تا سنجشِ برابری درست باشد.
FOLD = str.maketrans({"ي": "ی", "ك": "ک", "‌": "", "ٔ": ""})


def normalize(text: str) -> str:
    return TAGS.sub("", html.unescape(text)).translate(FOLD).strip()


def load_cache() -> dict:
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict) -> None:
    CACHE.write_text(
        json.dumps(cache, ensure_ascii=False, indent=0, sort_keys=True),
        encoding="utf-8",
    )


def fetch(word: str, tries: int = 3) -> str:
    url = f"{BASE}/q/" + urllib.parse.quote(word)
    for attempt in range(tries):
        try:
            request = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(request, timeout=40) as response:
                return response.read().decode("utf-8", "replace")
        except Exception:
            if attempt == tries - 1:
                return ""
            time.sleep(2 ** attempt)
    return ""


def parse(page: str, word: str) -> list[str]:
    """تنها سطری که سرواژه‌اش دقیقاً همان واژه است.

    سامانه ترکیب‌ها را هم برمی‌گرداند («رفع مشکل»، «مشکل پسند»). آنها برابرِ
    خودِ واژه نیستند و نباید با آن اشتباه شوند.
    """
    target = normalize(word)
    for raw_head, raw_body in ROW.findall(page):
        if normalize(raw_head) != target:
            continue
        parts = [p.strip(" ‌.،") for p in normalize(raw_body).split("-")]
        return [p for p in parts if p and p != target]
    return []


def lookup(word: str, cache: dict) -> list[str]:
    if word in cache:
        return cache[word]
    result = parse(fetch(word), word)
    time.sleep(DELAY_SECONDS)
    cache[word] = result
    return result


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    cache = load_cache()

    if "--report" in sys.argv:
        found = {k: v for k, v in cache.items() if v}
        print(f"کش: {len(cache)} واژه پرسیده شد، {len(found)} برابر داشت.")
        for word, equivalents in sorted(found.items()):
            print(f"  {word:<14} → {' · '.join(equivalents)}")
        return 0

    words: list[str] = args
    if "--top" in sys.argv:
        index = sys.argv.index("--top")
        limit = int(sys.argv[index + 1]) if index + 1 < len(sys.argv) else 2000
        from wordfreq import top_n_list

        # همه‌ی واژه‌های پربسامد پرسیده می‌شوند، نه گزیده‌ای که ما پسندیده‌ایم.
        # اگر واژه‌ای ایرانی‌تبار باشد، سامانه چیزی برنمی‌گرداند و همان پاسخ است.
        words = [w for w in top_n_list("fa", limit) if len(w) >= 3]

    if not words:
        print(__doc__)
        return 2

    asked = hits = 0
    for word in words:
        fresh = word not in cache
        equivalents = lookup(word, cache)
        if fresh:
            asked += 1
        if equivalents:
            hits += 1
            print(f"  {word:<14} → {' · '.join(equivalents)}", flush=True)
        if asked and asked % 50 == 0:
            save_cache(cache)

    save_cache(cache)
    print(f"\n{len(words)} واژه پرسیده شد ({asked} تازه)؛ {hits} برابر داشت.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
