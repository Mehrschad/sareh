#!/usr/bin/env python3
"""از روی `content/words/` منزل‌ها و خان‌ها را از نو می‌سازد.

چرا هست
-------
پیش‌تر منزل‌ها از یک اسکریپتِ بذرافشانیِ بیرونِ مخزن ساخته می‌شدند. یعنی هرکس
واژه‌ای می‌افزود یا برمی‌داشت، نمی‌توانست منزل‌ها را هم‌سان کند. اکنون
`content/words/` یگانه منبعِ حقیقت است و این ابزار باقی را از آن می‌سازد.

عضویتِ خان از پرونده‌های کنونیِ `content/lessons/` خوانده می‌شود، پس
جابه‌جاییِ دستیِ واژه میانِ خان‌ها نگه داشته می‌شود؛ تنها گروه‌بندی و شمارشِ
منزل‌ها از نو حساب می‌شود.

    python3 tools/rebuild_lessons.py
"""

from __future__ import annotations

import pathlib
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
WORDS = ROOT / "content" / "words"
LESSONS = ROOT / "content" / "lessons"
KHANS_FILE = ROOT / "content" / "khans.yaml"

KHANS = [
    (1, "شیر", "گفت‌وگوی هرروز", "khan-1-shir"),
    (2, "دیو تشنگی", "تن، تندرستی و احساس", "khan-2-div-teshnegi"),
    (3, "اژدها", "خانه، خوراک و خرید", "khan-3-ezhdeha"),
    (4, "جادو", "کار، پیشه و پول", "khan-4-jadu"),
    (5, "اولاد", "اندیشه، دانش و سخن", "khan-5-owlad"),
    (6, "ارژنگ", "مردم، مهر و رفتار", "khan-6-arzhang"),
    (7, "دیو سپید", "جهان، جا، زمان و اندازه", "khan-7-div-sepid"),
]

# هر منزل دستِ‌کم چهار گونه دارد — یکنواختی، قاتلِ تداوم است.
# «شنیدار» و «گفتار» اینجا نیستند: هر دو به صدا نیاز دارند و صدا هنوز نیست.
# منزلی که گونه‌ای را اعلام کند که ساخته نشده، وعده‌ای می‌دهد که موتور
# نمی‌تواند نگه دارد و ناچار به «گزینش» برمی‌گردد.
EXERCISE_ROTATION = [
    ["گزینش", "جفت‌ساز", "جای‌گزینی", "واژه‌چین"],
    ["گزینش", "واژه‌چین", "نویسش", "داستانک"],
    ["گزینش", "جای‌گزینی", "ریشه‌یاب", "تیر آرش"],
    ["جفت‌ساز", "بیت‌یاب", "گزینش", "نویسش"],
    ["گزینش", "داستانک", "تیر آرش", "واژه‌چین"],
    ["جای‌گزینی", "گزینش", "تیر آرش", "بیت‌یاب"],
]


def chunk_balanced(items, target=9, max_groups=8):
    """۸ تا ۱۲ واژه در هر منزل، و دستِ‌بالا ۸ منزل در هر خان."""
    n = len(items)
    groups = max(1, round(n / target))
    while n / groups > 12:
        groups += 1
    while groups > 1 and n / groups < 8:
        groups -= 1
    groups = min(groups, max_groups)
    out, start = [], 0
    for i in range(groups):
        size = (n - start) // (groups - i)
        out.append(items[start:start + size])
        start += size
    return out


def dump(path: pathlib.Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        yaml.dump(data, allow_unicode=True, sort_keys=False,
                  default_flow_style=False, width=100),
        encoding="utf-8",
    )


def main() -> int:
    entries = {}
    for path in sorted(WORDS.glob("*.yaml")):
        entry = yaml.safe_load(path.read_text(encoding="utf-8"))
        entries[entry["id"]] = entry

    # عضویتِ خان را از منزل‌های کنونی برمی‌داریم.
    membership: dict[str, int] = {}
    for _num, _guardian, _realm, slug in KHANS:
        path = LESSONS / f"{slug}.yaml"
        if not path.exists():
            continue
        lesson = yaml.safe_load(path.read_text(encoding="utf-8"))
        for station in lesson["stations"]:
            for wid in station["words"]:
                membership[wid] = lesson["khan"]

    orphans = [wid for wid in entries if wid not in membership]
    if orphans:
        print(f"⚠ {len(orphans)} واژه به هیچ خانی بسته نیست: "
              f"{'، '.join(orphans[:8])}")
        print("  به خانِ ۱ بسته شد؛ اگر جایش آنجا نیست، دستی جابه‌جا کنید.")
        for wid in orphans:
            membership[wid] = 1

    khans_out, total_stations = [], 0
    for num, guardian, realm, slug in KHANS:
        members = [e for wid, e in entries.items() if membership.get(wid) == num]
        # آسان‌ترین‌ها نخست: پربسامدترین وام‌واژه با کم‌دشوارترین برابر.
        members.sort(key=lambda e: (e["difficulty"], -e["zipf"]))
        groups = chunk_balanced(members)
        stations = []
        for i, group in enumerate(groups, start=1):
            station_id = f"{slug}-manzel-{i}"
            stations.append({
                "id": station_id,
                "title": f"منزلِ {i}",
                "exercises": EXERCISE_ROTATION[(i - 1) % len(EXERCISE_ROTATION)],
                "words": [e["id"] for e in group],
            })
            assert 8 <= len(group) <= 12, f"{station_id}: {len(group)} واژه"
        assert 5 <= len(stations) <= 8, f"{slug}: {len(stations)} منزل"
        total_stations += len(stations)
        dump(LESSONS / f"{slug}.yaml", {
            "id": slug,
            "khan": num,
            "guardian": guardian,
            "realm": realm,
            "stations": stations,
            "boss": {
                "id": f"{slug}-negahban",
                "title": f"نگهبانِ خان — {guardian}",
                "word_count": 12,
                "exercises": ["گزینش", "جای‌گزینی", "بیت‌یاب", "تیر آرش"],
                "pass_ratio": 0.8,
            },
        })
        median = sorted(e["zipf"] for e in members)[len(members) // 2]
        khans_out.append({
            "khan": num, "id": slug, "guardian": guardian, "realm": realm,
            "stations": len(stations), "words": len(members),
            "median_zipf": round(median, 2),
        })

    dump(KHANS_FILE, {"khans": khans_out})

    print(f"واژه‌ها: {len(entries)}   منزل‌ها: {total_stations}")
    for k in khans_out:
        print(f"  خان {k['khan']} {k['guardian']:<12} {k['words']:>3} واژه / "
              f"{k['stations']} منزل   میانه‌ی Zipf {k['median_zipf']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
