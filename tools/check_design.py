#!/usr/bin/env python3
"""نگهبانِ سامانه‌ی طراحی.

دو قاعده‌ی سختِ بخش ۹٫۴ و ۱۱ را می‌سنجد:

  ۱. هیچ رنگ یا مقدارِ طراحیِ هارد‌کد‌شده‌ای در ویجت‌ها نیست. همه از
     `tokens.g.dart` می‌آید.
  ۲. کنتراستِ هر جفتِ متن/زمینه دست‌کم WCAG AA است.

به Flutter نیاز ندارد تا CI بتواند پیش از هر چیزِ دیگری آن را اجرا کند:

    python3 tools/check_design.py
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TOKENS = ROOT / "design" / "tokens.json"
APP_LIB = ROOT / "app" / "lib"

# تنها فایلی که حق دارد رنگِ خام داشته باشد، همانی است که از توکن‌ها ساخته شده.
GENERATED = {"tokens.g.dart"}

HEX = re.compile(r"Color\(0x[0-9A-Fa-f]{8}\)")
MATERIAL_COLOR = re.compile(r"\bColors\.(?!transparent\b)[a-zA-Z]+")

# مقادیرِ طراحی که باید از توکن بیایند: شعاع، فاصله و مدتِ زمان.
RADIUS = re.compile(r"BorderRadius\.circular\(\s*\d")
DURATION = re.compile(r"Duration\(\s*milliseconds:\s*\d+")
EDGE_INSETS = re.compile(r"EdgeInsets\.\w+\(\s*[\d.]+")

BODY_TEXT_MIN = 4.5
GRAPHIC_MIN = 3.0

# جفت‌هایی که متن روی زمینه‌اند و باید کفِ متن را داشته باشند.
TEXT_PAIRS = [
    ("onBackground", "background"),
    ("onSurface", "surface"),
    ("onSurfaceMuted", "surface"),
    ("onSurfaceMuted", "background"),
    ("onAction", "action"),
    ("achievement", "surface"),
    ("accentSoft", "surface"),
]

# جفت‌هایی که عنصرِ گرافیکی‌اند (حاشیه، نشانگر) و کفِ ۳:۱ برایشان بس است.
GRAPHIC_PAIRS = [
    ("action", "background"),
    ("error", "surface"),
    ("outline", "surface"),
]


def relative_luminance(hex_colour: str) -> float:
    value = hex_colour.lstrip("#")[:6]
    channels = [int(value[i : i + 2], 16) / 255 for i in (0, 2, 4)]
    linear = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast(a: str, b: str) -> float:
    la, lb = relative_luminance(a), relative_luminance(b)
    high, low = max(la, lb), min(la, lb)
    return (high + 0.05) / (low + 0.05)


def resolve(value: str, palette: dict) -> str:
    if value.startswith("{") and value.endswith("}"):
        return palette[value[1:-1].split(".")[-1]]["value"]
    return value


def check_contrast(tokens: dict) -> list[str]:
    problems = []
    palette = tokens["palette"]
    for theme_name, theme in tokens["color"].items():
        for pairs, floor, label in (
            (TEXT_PAIRS, BODY_TEXT_MIN, "متن"),
            (GRAPHIC_PAIRS, GRAPHIC_MIN, "گرافیکی"),
        ):
            for foreground, background in pairs:
                if foreground not in theme or background not in theme:
                    continue
                # رنگ‌های نیمه‌شفاف روی زمینه‌ی خودشان سنجیده نمی‌شوند؛
                # کنتراستشان به آنچه پشتشان است بستگی دارد.
                fg = resolve(theme[foreground], palette)
                bg = resolve(theme[background], palette)
                if len(fg.lstrip("#")) == 8 or len(bg.lstrip("#")) == 8:
                    continue
                ratio = contrast(fg, bg)
                if ratio < floor:
                    problems.append(
                        f"کنتراستِ {label} در پوسته‌ی {theme_name}: "
                        f"{foreground} روی {background} = {ratio:.2f}، کف {floor}"
                    )
    return problems


def check_khan_accents(tokens: dict) -> list[str]:
    """هر رنگِ خان باید روی زمینه‌ی پوسته‌ی خودش دستِ‌کم ۳:۱ باشد.

    این رنگ‌ها مسیر و نشانِ نگهبان را می‌کشند — عنصرِ گرافیکی‌اند، نه متن.
    """
    problems = []
    palette = tokens["palette"]
    accents = tokens.get("khan", {}).get("accents", [])
    if len(accents) != 7:
        problems.append(f"خان‌ها هفت‌تا هستند، نه {len(accents)}")
    backgrounds = {
        theme: resolve(spec["background"], palette)
        for theme, spec in tokens["color"].items()
    }
    for accent in accents:
        for theme, background in backgrounds.items():
            ratio = contrast(accent[theme], background)
            if ratio < GRAPHIC_MIN:
                problems.append(
                    f"رنگِ خانِ «{accent['fa']}» در پوسته‌ی {theme}: "
                    f"{ratio:.2f} روی زمینه، کف {GRAPHIC_MIN}"
                )
    return problems


def check_hardcoded_values() -> list[str]:
    problems = []
    for path in sorted(APP_LIB.rglob("*.dart")):
        if path.name in GENERATED:
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            code = line.split("//")[0]
            where = f"{path.relative_to(ROOT)}:{number}"
            if HEX.search(code):
                problems.append(f"{where}: رنگِ خام — از SarehColors بگیر")
            if MATERIAL_COLOR.search(code):
                problems.append(f"{where}: رنگِ Material — از SarehColors بگیر")
            if RADIUS.search(code):
                problems.append(f"{where}: شعاعِ خام — از SarehRadius بگیر")
            if DURATION.search(code):
                problems.append(f"{where}: مدتِ خام — از SarehMotion بگیر")
            if EDGE_INSETS.search(code):
                problems.append(f"{where}: فاصله‌ی خام — از SarehSpace بگیر")
    return problems


def main() -> int:
    if not TOKENS.exists():
        print(f"✗ {TOKENS} یافت نشد")
        return 1
    tokens = json.loads(TOKENS.read_text(encoding="utf-8"))

    problems = check_contrast(tokens) + check_khan_accents(tokens)
    if APP_LIB.exists():
        problems += check_hardcoded_values()

    if problems:
        for problem in problems:
            print(f"✗ {problem}")
        print(f"\n{len(problems)} ایراد.")
        return 1

    print("✓ توکن‌ها یکتا و کنتراست‌ها در حدِ WCAG AA.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
