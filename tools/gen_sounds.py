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


def pluck(freq: float, seconds: float, damp: float = 0.996) -> np.ndarray:
    """یک سیمِ زخمه‌خورده — Karplus–Strong."""
    period = max(2, int(RATE / freq))
    rng = np.random.default_rng(int(freq * 7))  # قطعی: هر بار همان صدا.
    buf = rng.uniform(-1.0, 1.0, period)
    out = np.empty(int(RATE * seconds))
    for i in range(len(out)):
        j = i % period
        out[i] = buf[j]
        buf[j] = damp * 0.5 * (buf[j] + buf[(j + 1) % period])
    return out


def santur(freq: float, seconds: float, damp: float = 0.996) -> np.ndarray:
    """دو سیمِ هم‌کوک با ناکوکیِ ریز — جوهرِ صدای سنتور."""
    a = pluck(freq, seconds, damp)
    b = pluck(freq * 1.004, seconds, damp)
    return (a + b) / 2


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


def write(name: str, sound: np.ndarray, gain: float = 0.85) -> None:
    sound = fade(sound.copy())
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
    # درست: دو ضربِ روشنِ بالارونده — پاداش، کوتاه‌تر از آنکه مزاحم شود.
    write(
        "dorost.wav",
        mix((santur(784.0, 0.4), 0.0), (santur(1046.5, 0.45), 0.07)),
    )
    # نادرست: یک ضربِ بمِ خفه و آرام‌تر — خبر، نه تنبیه.
    write(
        "nadorost.wav",
        santur(220.0, 0.32, damp=0.987),
        gain=0.5,
    )
    # پایانِ منزل: پویه‌ی بالارونده‌ی پنج‌ضربی در مایه‌ی شور (ر).
    run = [(293.7, 0.0), (349.2, 0.1), (392.0, 0.2), (440.0, 0.3), (587.3, 0.42)]
    write(
        "manzel.wav",
        mix(*((santur(f, 1.0 if f == 587.3 else 0.5), at) for f, at in run)),
    )
    # گوهر (منزلِ بی‌لغزش): همان پویه با تاجِ یک اکتاو بالاتر.
    crown = run + [(880.0, 0.54), (1174.7, 0.66)]
    write(
        "gohar.wav",
        mix(*((santur(f, 1.1 if f > 800 else 0.5), at) for f, at in crown)),
    )
    total = sum(p.stat().st_size for p in OUT.glob("*.wav"))
    print(f"  جمع: {total / 1024:.0f}KB (کف‌نامه: زیر ۵۰۰KB)")
    assert total < 500 * 1024, "بسته‌ی صدا از ۵۰۰KB گذشت"


if __name__ == "__main__":
    main()
