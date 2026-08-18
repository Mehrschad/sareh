#!/usr/bin/env python3
"""خاستگاهِ وام‌واژه‌ها را با واژه‌یاب می‌سنجد.

`loan_origin` تا امروز دستی نوشته می‌شد. این ابزار همان را با برچسبِ زبانِ
فرهنگ عمید (از راهِ واژه‌یاب) رودررو می‌کند و سه دسته می‌سازد:

  هم‌داستان   — فرهنگ همان زبان را می‌گوید که ما نوشته‌ایم
  ناهم‌داستان — فرهنگ زبانِ دیگری می‌گوید؛ باید دستی نگاه شود
  بی‌برچسب    — فرهنگ برچسبِ زبان ندارد؛ نوشته‌ی ما بی‌سند می‌ماند

دسته‌ی سوم کم نیست و پنهانش نمی‌کنیم: پوششِ برچسبِ زبان در فرهنگ‌ها ناقص است.

    python3 tools/verify_origins.py            # همه
    python3 tools/verify_origins.py --diff     # تنها ناهم‌داستان‌ها
"""

from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CACHE = ROOT / "tools" / ".vajehyab-cache.json"
WORDS = ROOT / "content" / "words"

FOLD = str.maketrans({"ي": "ی", "ك": "ک", "‌": "", "ٔ": ""})
DIACRITICS = dict.fromkeys(range(0x064B, 0x0653), None)


def norm(text: str) -> str:
    return text.translate(FOLD).translate(DIACRITICS).replace(" ", "").strip()


def main() -> int:
    if not CACHE.exists():
        print("کشِ واژه‌یاب نیست. نخست: python3 tools/lookup_vajehyab.py --corpus")
        return 1

    import yaml

    cache: dict[str, dict] = json.loads(CACHE.read_text(encoding="utf-8"))
    agree, differ, untagged = [], [], []
    equivalent_hits = equivalent_checked = 0

    for path in sorted(WORDS.glob("*.yaml")):
        entry = yaml.safe_load(path.read_text(encoding="utf-8"))
        head = entry["loan"].split()[0].strip("ِ")
        data = cache.get(head) or {}
        languages = data.get("languages") or []

        if not languages:
            untagged.append(entry)
        elif entry["loan_origin"] in languages:
            agree.append(entry)
        else:
            differ.append((entry, languages))

        # برابرهای واژه‌یاب — سنجه‌ی سومِ مستقل، پس از خودمان و «به پارسی».
        alternatives = [norm(a) for a in data.get("alternatives") or []]
        if alternatives:
            equivalent_checked += 1
            ours = norm(entry["sare"])
            if any(ours == a or ours.startswith(a) or a.startswith(ours) for a in alternatives):
                equivalent_hits += 1

    checked = len(agree) + len(differ)
    total = checked + len(untagged)
    print(f"مدخل‌ها: {total}")
    print(f"برچسبِ زبان دارند: {checked}   بی‌برچسب: {len(untagged)}")
    if checked:
        print(f"خاستگاه هم‌داستان: {len(agree)} ({len(agree) * 100 // checked}٪)")
        print(f"خاستگاه ناهم‌داستان: {len(differ)}")
    if equivalent_checked:
        share = equivalent_hits * 100 // equivalent_checked
        print(
            f"\nبرابرِ ما در فهرستِ واژه‌یاب: {equivalent_hits}/{equivalent_checked} ({share}٪)"
        )

    if differ:
        print("\n— خاستگاهی که با فرهنگ نمی‌خواند —")
        for entry, languages in sorted(differ, key=lambda r: -r[0]["zipf"]):
            print(
                f"  {entry['loan']:<13} ما: {entry['loan_origin']:<9}"
                f" فرهنگ: {'، '.join(languages)}"
            )
    return 0


if __name__ == "__main__":
    sys.exit(main())
