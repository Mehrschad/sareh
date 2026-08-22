#!/usr/bin/env python3
"""سازنده‌ی جلوه‌های صوتیِ سره — سنتورِ ساختگی.

چرا ساختگی و نه ضبط‌شده: ضبطِ سنتورِ واقعی یا حقِ پخشِ ناروشن دارد یا
میکروفون و نوازنده می‌خواهد؛ هیچ‌کدام در مخزنِ متن‌باز جا نمی‌گیرد. سنتزِ
Karplus–Strong همان فیزیکِ سیمِ زخمه‌خورده را شبیه‌سازی می‌کند و برای ضربِ
کوتاهِ بازخورد، از ضبط جداناپذیر است. هر نُت دو سیمِ اندکی ناکوک دارد —
همان چیزی که صدای سنتور را «سنتور» می‌کند.

قاعده‌های ETHICS: صدای پاسخِ نادرست نرم و کوتاه است، نه بوقِ خطا؛ هیچ
صدایی بلندتر از ضربِ پاداش نیست؛ و کلِ بسته زیرِ ۵۰۰KB می‌ماند (نقشه‌ی راه).

    python3 tools/gen_sounds.py

خروجی‌ها در app/assets/sounds/ کامیت می‌شوند تا ساختِ اپ به numpy نیازمند
نشود؛ این اسکریپت تنها هنگامِ تغییرِ طراحیِ صدا لازم است.
"""

from __future__ import annotations

import pathlib
import wave

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "app" / "assets" / "sounds"
RATE = 22050


def soften(signal: np.ndarray, cutoff: float) -> np.ndarray:
    """صافیِ یک‌قطبیِ پایین‌گذر.

    هارمونیک‌های بالای Karplus–Strong تیزند و همان تیزی است که پس از
    بیستمین بار شنیدن روی اعصاب می‌رود. این صافی نوکِ آن را می‌گیرد و
    صدا را از «دینگ» به «تُنگ» می‌برد.
    """
    alpha = 1.0 - np.exp(-2.0 * np.pi * cutoff / RATE)
    out = np.empty_like(signal)
    acc = 0.0
    for i, sample in enumerate(signal):
        acc += alpha * (sample - acc)
        out[i] = acc
    return out


def pluck(freq: float, seconds: float, damp: float = 0.994) -> np.ndarray:
    """یک سیمِ زخمه‌خورده — Karplus–Strong با مضرابِ نرم.

    برانگیزنده نویزِ سفیدِ خام نیست بلکه نویزِ صاف‌شده است: مضرابِ نمدی
    به‌جای مضرابِ فلزی. آغازِ صدا همان‌قدر روشن نیست، ولی چیزی که
    ده‌ها بار در دقیقه شنیده می‌شود نباید روشن باشد.
    """
    period = max(2, int(RATE / freq))
    rng = np.random.default_rng(int(freq * 7))  # قطعی: هر بار همان صدا.
    buf = soften(rng.uniform(-1.0, 1.0, period), cutoff=freq * 3)
    out = np.empty(int(RATE * seconds))
    for i in range(len(out)):
        j = i % period
        out[i] = buf[j]
        buf[j] = damp * 0.5 * (buf[j] + buf[(j + 1) % period])
    return out


def santur(freq: float, seconds: float, damp: float = 0.994) -> np.ndarray:
    """دو سیمِ هم‌کوک با ناکوکیِ ریز — جوهرِ صدای سنتور."""
    a = pluck(freq, seconds, damp)
    b = pluck(freq * 1.004, seconds, damp)
    return soften((a + b) / 2, cutoff=freq * 6)


def fade(sound: np.ndarray, ms: int = 30) -> np.ndarray:
    n = int(RATE * ms / 1000)
    sound[-n:] *= np.linspace(1.0, 0.0, n)
    sound[:64] *= np.linspace(0.0, 1.0, 64)
    return sound


def mix(*parts: tuple[np.ndarray, float]) -> np.ndarray:
    """رویه‌گذاریِ چند نُت، هرکدام با زمانِ آغازِ خودش (ثانیه)."""
    end = max(int(RATE * at) + len(p) for p, at in parts)
    out = np.zeros(end)
    for p, at in parts:
        start = int(RATE * at)
        out[start : start + len(p)] += p
    return out


def write(
    name: str,
    sound: np.ndarray,
    gain: float = 0.85,
    cutoff: float = 2600.0,
) -> None:
    """صافیِ پایانی، سپس هم‌ترازی و نوشتن.

    [cutoff] نوکِ تیزیِ نهایی را می‌برد. صدایی که پرتکرارتر است باید
    بم‌تر باشد: مغز هارمونیکِ بالای ۲ کیلوهرتز را «هشدار» می‌خواند و
    هشدارِ پیاپی همان چیزی است که آزار می‌شود.
    """
    sound = fade(soften(sound.copy(), cutoff))
    peak = np.abs(sound).max()
    if peak > 0:
        sound = sound / peak * gain
    data = (sound * 32767).astype("<i2")
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data.tobytes())
    print(f"  {name:14} {path.stat().st_size / 1024:6.1f}KB")


def main() -> None:
    # ── چرا این نسخه از نسخه‌ی نخست آرام‌تر و بم‌تر است ──
    #
    # نخستین نسخه روی مخِ کاربر رفت، و سه دلیل داشت که هر سه اینجا
    # وارونه شده‌اند:
    #
    #   ۱. زیر بود. سُل و دوی اکتاوِ پنجم (۷۸۴ و ۱۰۴۶ هرتز) درست در
    #      حساس‌ترین باندِ شنواییِ آدمی‌اند. یک اکتاو پایین آمد.
    #   ۲. بلند بود. صدایی که ده‌ها بار در دقیقه پخش می‌شود باید در
    #      حاشیه‌ی آگاهی بنشیند، نه در مرکزش. بهره‌ها نصف شد.
    #   ۳. دراز بود. دنباله‌ی نیم‌ثانیه‌ای با پاسخِ بعدی روی هم می‌افتاد و
    #      انبوهه می‌ساخت. همه کوتاه‌تر شد.
    #
    # صدای «نادرست» بیش از همه پایین آمد: همان است که وقتی کاربر
    # کلافه است بیشتر می‌شنود.

    # درست: دو ضربِ نرمِ بالارونده (سُل و دوی اکتاوِ چهارم).
    write(
        "dorost.wav",
        mix((santur(392.0, 0.26), 0.0), (santur(523.3, 0.30), 0.06)),
        gain=0.42,
        cutoff=1500,
    )
    # نادرست: یک ضربِ بمِ خفه و کوتاه — خبر، نه تنبیه.
    write(
        "nadorost.wav",
        santur(146.8, 0.22, damp=0.984),
        gain=0.26,
        cutoff=1100,
    )
    # پایانِ منزل: پویه‌ی بالارونده‌ی پنج‌ضربی در مایه‌ی شور (ر).
    # این یکی در هر منزل یک بار شنیده می‌شود، پس می‌تواند بلندتر بماند.
    run = [(146.8, 0.0), (174.6, 0.1), (196.0, 0.2), (220.0, 0.3), (293.7, 0.42)]
    write(
        "manzel.wav",
        mix(*((santur(f, 0.9 if f == 293.7 else 0.45), at) for f, at in run)),
        gain=0.6,
        cutoff=2200,
    )
    # گوهر (منزلِ بی‌لغزش): همان پویه با تاجِ یک اکتاو بالاتر.
    crown = run + [(440.0, 0.54), (587.3, 0.66)]
    write(
        "gohar.wav",
        mix(*((santur(f, 1.0 if f > 400 else 0.45), at) for f, at in crown)),
        gain=0.66,
        cutoff=2600,
    )
    total = sum(p.stat().st_size for p in OUT.glob("*.wav"))
    print(f"  جمع: {total / 1024:.0f}KB (کف‌نامه: زیر ۵۰۰KB)")
    assert total < 500 * 1024, "بسته‌ی صدا از ۵۰۰KB گذشت"


if __name__ == "__main__":
    main()
