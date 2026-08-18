#!/usr/bin/env python3
"""نامزدهای مدخل را از کشِ «به پارسی» و داده‌ی بسامدی می‌سازد.

روش
---
۱. **کدام واژه بیگانه است؟** داورش «به پارسی» است، نه صافیِ املایی و نه گمانِ
   ما. اگر برای واژه‌ای برابر پیشنهاد کرده، آن را بیگانه می‌داند.

۲. **کدام برابر به کار می‌آید؟** خودِ سامانه را بر پیشنهادهایش می‌سنجیم: اگر
   «به پارسی» برای یک برابرِ پیشنهادی *هم* برابر دارد (مثلاً برای «ولی» که خودش
   عربی است)، آن پیشنهاد کنار می‌رود. سنجشِ سامانه با خودش.

۳. **آیا ارزشِ آموختن دارد؟** وام‌واژه باید در گفتار زنده باشد (Zipf ≥ ۳) و
   برابرش نباید چنان مرده باشد که کسی نتواند به کارش ببرد.

خروجی فهرستِ نامزد است برای بازبینیِ انسانی، نه مدخلِ آماده. واژه‌نگار باید
معنی، نمونه و ریشه را خودش بنویسد.

    python3 tools/propose_words.py            # نامزدهای تازه
    python3 tools/propose_words.py --all      # با آنهایی که داریم
"""

from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CACHE = ROOT / "tools" / ".beparsi-cache.json"
WORDS = ROOT / "content" / "words"

# وام‌واژه باید در گفتار زنده باشد.
MIN_LOAN_ZIPF = 3.0
# برابر باید دستِ‌کم نشانی از زندگی داشته باشد، وگرنه در گفتار نمی‌نشیند.
MIN_SARE_ZIPF = 2.5


def load_corpus() -> tuple[set[str], set[str]]:
    loans, sares = set(), set()
    if not WORDS.is_dir():
        return loans, sares
    import yaml

    for path in WORDS.glob("*.yaml"):
        entry = yaml.safe_load(path.read_text(encoding="utf-8"))
        loans.add(entry["loan"])
        loans.add(entry["loan"].split()[0].strip("ِ"))
        sares.add(entry["sare"])
    return loans, sares


def main() -> int:
    if not CACHE.exists():
        print("کشِ «به پارسی» نیست. نخست: python3 tools/lookup_beparsi.py --top 2500")
        return 1

    from wordfreq import zipf_frequency

    def usability(phrase: str) -> float:
        """بسامدِ یک عبارت در پیکره نیست؛ محتاطانه کم‌بسامدترین واژه‌اش را
        می‌گیریم، وگرنه «از روی مهر» به‌خاطرِ «از» نمره‌ی بالا می‌گیرد."""
        tokens = [t for t in phrase.split() if t]
        if not tokens:
            return 0.0
        return min(zipf_frequency(t, "fa") for t in tokens)

    cache: dict[str, list[str]] = json.loads(CACHE.read_text(encoding="utf-8"))
    known_loans, known_sares = load_corpus()
    show_all = "--all" in sys.argv

    # هر واژه‌ای که سامانه برایش برابر دارد، از دید سامانه بیگانه است.
    flagged = {word for word, equivalents in cache.items() if equivalents}

    proposals = []
    for loan, equivalents in cache.items():
        if not equivalents:
            continue
        if not show_all and loan in known_loans:
            continue
        loan_zipf = usability(loan)
        if loan_zipf < MIN_LOAN_ZIPF:
            continue

        usable = []
        for candidate in equivalents:
            # سامانه خودش این را بیگانه می‌داند — پس برابر نیست.
            if candidate in flagged:
                continue
            if candidate in known_sares:
                continue
            zipf = usability(candidate)
            if zipf < MIN_SARE_ZIPF:
                continue
            usable.append((zipf, candidate))
        if not usable:
            continue
        usable.sort(reverse=True)
        proposals.append((loan_zipf, loan, usable))

    proposals.sort(reverse=True)
    print(f"# نامزد: {len(proposals)}   (کش: {len(cache)} پرسش، {len(flagged)} بیگانه)\n")
    print(f"{'وام‌واژه':<14}{'Zipf':>5}   برابرهای پیشنهادیِ «به پارسی» (با Zipf)")
    print("-" * 92)
    for loan_zipf, loan, usable in proposals:
        shown = " · ".join(f"{w} ({z:.1f})" for z, w in usable[:4])
        print(f"{loan:<14}{loan_zipf:>5.1f}   {shown}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
