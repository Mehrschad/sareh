#!/usr/bin/env python3
"""مدخل‌های پیکره را با «به پارسی» می‌سنجد.

هر مدخلِ سره یک ادعا دارد: «برابرِ فلان وام‌واژه، این واژه‌ی پارسی است.» این
ابزار همان ادعا را از یک منبعِ بیرونی می‌پرسد و سه پاسخ می‌گیرد:

  هم‌داستان   — سامانه هم همین برابر را می‌دهد
  ناهم‌داستان — سامانه برابر دارد، ولی این یکی در فهرستش نیست
  بی‌نظر      — سامانه این وام‌واژه را نمی‌شناسد یا برایش برابری ندارد

«ناهم‌داستان» به‌خودی‌خود خطا نیست — گاهی برابرِ ما بهتر است، گاهی بدتر. ولی
هر کدام باید دستی نگاه شود.

    python3 tools/audit_equivalents.py           # خلاصه
    python3 tools/audit_equivalents.py --diff    # تنها ناهم‌داستان‌ها
"""

from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CACHE = ROOT / "tools" / ".beparsi-cache.json"
WORDS = ROOT / "content" / "words"

FOLD = str.maketrans({"ي": "ی", "ك": "ک", "‌": "", "ٔ": ""})


def norm(text: str) -> str:
    return text.translate(FOLD).replace(" ", "").strip()


def main() -> int:
    if not CACHE.exists():
        print("کشِ «به پارسی» نیست. نخست: python3 tools/lookup_beparsi.py --top 2500")
        return 1

    import yaml

    cache: dict[str, list[str]] = json.loads(CACHE.read_text(encoding="utf-8"))
    lookup = {norm(k): v for k, v in cache.items()}

    agree, differ, silent = [], [], []
    for path in sorted(WORDS.glob("*.yaml")):
        entry = yaml.safe_load(path.read_text(encoding="utf-8"))
        loan = entry["loan"].split()[0].strip("ِ")
        equivalents = lookup.get(norm(loan))
        if not equivalents:
            silent.append(entry)
            continue
        ours = norm(entry["sare"])
        theirs = [norm(e) for e in equivalents]
        # صورتِ صرف‌شده هم هم‌داستانی است: «گرما» و «گرمای».
        if any(ours == t or ours.startswith(t) or t.startswith(ours) for t in theirs):
            agree.append(entry)
        else:
            differ.append((entry, equivalents))

    total = len(agree) + len(differ) + len(silent)
    checked = len(agree) + len(differ)
    print(f"مدخل‌ها: {total}   سنجیده: {checked}   بی‌نظرِ سامانه: {len(silent)}")
    if checked:
        print(f"هم‌داستان: {len(agree)} ({len(agree) * 100 // checked}٪ از سنجیده‌ها)")
        print(f"ناهم‌داستان: {len(differ)}\n")

    if differ:
        print("— جاهایی که سامانه چیز دیگری می‌گوید —")
        for entry, equivalents in sorted(differ, key=lambda r: -r[0]["zipf"]):
            print(
                f"  {entry['loan']:<12} ما: {entry['sare']:<14}"
                f" سامانه: {' · '.join(equivalents[:4])}"
            )
    if "--diff" not in sys.argv and silent:
        print(f"\n(سامانه درباره‌ی {len(silent)} مدخل نظری نداد — بیشترشان"
              " وام‌واژه‌های فرنگی یا واژه‌های کم‌کاربردند.)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
