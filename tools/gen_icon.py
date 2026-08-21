#!/usr/bin/env python3
"""آیکنِ اپ — کنگره و نور.

همان هویتِ tokens.json: کنگره‌ی سه‌پله‌ی تختِ جمشید به زرِ فَرّ بر شبِ
لاجورد، و بالای آن قرصِ فیروزه‌ی «نورِ واژه» با هاله. قاعده‌ی خودِ
tokens.json («فیروزه و زر کنارِ هم پررنگ نمی‌نشینند») اینجا آگاهانه یک
استثنا دارد: آیکن، لحظه‌ی دستاوردِ خودِ محصول است.

خروجی‌ها:
  • آیکنِ سازگار (API 26+): پیش‌زمینه‌ی PNG در هر چگالی + رنگِ پس‌زمینه
  • آیکنِ کهنه: ic_launcher.png در هر چگالی
  • لایه‌ی تک‌رنگ برای آیکنِ پوسته‌ایِ اندروید ۱۳+

رنگ‌ها از design/tokens.json خوانده می‌شوند، نه دوباره نوشته.

    python3 tools/gen_icon.py
"""

from __future__ import annotations

import json
import pathlib

from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
RES = ROOT / "app" / "android" / "app" / "src" / "main" / "res"
TOKENS = json.loads((ROOT / "design" / "tokens.json").read_text(encoding="utf-8"))
PALETTE = {k: v["value"] for k, v in TOKENS["palette"].items()}

BACKGROUND = PALETTE["shabLajevard"]
GOLD = PALETTE["zareFarr"]
TURQUOISE = PALETTE["firuze"]

# چگالی‌ها: (پوشه، اندازه‌ی کهنه، اندازه‌ی پیش‌زمینه‌ی سازگار)
DENSITIES = [
    ("mdpi", 48, 108),
    ("hdpi", 72, 162),
    ("xhdpi", 96, 216),
    ("xxhdpi", 144, 324),
    ("xxxhdpi", 192, 432),
]

MASTER = 1024


def merlon_points(cx: float, base_y: float, width: float, height: float):
    """کنگره‌ی سه‌پله — همان merlonPath در kongere.dart."""
    steps, plateau_ratio = 3, 0.24
    inset = width * (1 - plateau_ratio) / 2 / steps
    rise = height / steps
    x0 = cx - width / 2
    points = [(x0, base_y)]
    for k in range(steps):
        points += [
            (x0 + k * inset, base_y - (k + 1) * rise),
            (x0 + (k + 1) * inset, base_y - (k + 1) * rise),
        ]
    for k in range(steps - 1, -1, -1):
        points += [
            (x0 + width - (k + 1) * inset, base_y - (k + 1) * rise),
            (x0 + width - k * inset, base_y - (k + 1) * rise),
        ]
    points.append((x0 + width, base_y))
    return points


def draw_mark(scale: float = 1.0, mono: str | None = None) -> Image.Image:
    """نقشِ آیکن روی بومِ شفافِ ۱۰۲۴. [scale] نقش را حولِ مرکز می‌فشرد."""
    img = Image.new("RGBA", (MASTER, MASTER), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    gold = mono or GOLD
    turquoise = mono or TURQUOISE

    cx = MASTER / 2
    w = 620 * scale
    h = 330 * scale
    base_y = cx + 245 * scale
    light_y = base_y - h - 165 * scale
    radius = 62 * scale

    # هاله‌ی نور — تنها در رنگی؛ لایه‌ی تک‌رنگ باید تخت بماند.
    if mono is None:
        halo = Image.new("RGBA", (MASTER, MASTER), (0, 0, 0, 0))
        ImageDraw.Draw(halo).ellipse(
            [cx - radius * 2.6, light_y - radius * 2.6,
             cx + radius * 2.6, light_y + radius * 2.6],
            fill=TURQUOISE + "55",
        )
        img = Image.alpha_composite(
            img, halo.filter(ImageFilter.GaussianBlur(46 * scale))
        )
        draw = ImageDraw.Draw(img)

    # قرصِ نور.
    draw.ellipse(
        [cx - radius, light_y - radius, cx + radius, light_y + radius],
        fill=turquoise,
    )
    # کنگره.
    draw.polygon(merlon_points(cx, base_y, w, h), fill=gold)
    return img


def on_background(mark: Image.Image) -> Image.Image:
    img = Image.new("RGBA", (MASTER, MASTER), BACKGROUND)
    return Image.alpha_composite(img, mark)


def save(img: Image.Image, path: pathlib.Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(path)
    print(f"  {path.relative_to(ROOT)}  {size}×{size}")


def main() -> None:
    # کهنه: نقش روی زمینه، اندکی بزرگ‌تر چون ماسک نمی‌خورد.
    legacy = on_background(draw_mark(scale=0.92))
    # سازگار: نقش در ناحیه‌ی امن (۶۶ از ۱۰۸dp ≈ ۰٫۶۱ پهنا).
    foreground = draw_mark(scale=0.58)
    monochrome = draw_mark(scale=0.58, mono="#FFFFFF")

    for density, legacy_size, adaptive_size in DENSITIES:
        save(legacy, RES / f"mipmap-{density}" / "ic_launcher.png", legacy_size)
        save(
            foreground,
            RES / f"mipmap-{density}" / "ic_launcher_foreground.png",
            adaptive_size,
        )
        save(
            monochrome,
            RES / f"mipmap-{density}" / "ic_launcher_monochrome.png",
            adaptive_size,
        )

    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n'
        "</adaptive-icon>\n",
        encoding="utf-8",
    )
    values = RES / "values"
    (values / "ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        f'    <color name="ic_launcher_background">{BACKGROUND}</color>\n'
        "</resources>\n",
        encoding="utf-8",
    )
    print("  mipmap-anydpi-v26/ic_launcher.xml و رنگِ پس‌زمینه نوشته شد.")


if __name__ == "__main__":
    main()
