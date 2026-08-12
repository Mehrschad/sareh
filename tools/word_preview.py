#!/usr/bin/env python3
"""پیش‌نمایشِ کارتِ واژه برای کامنتِ PR.

بازبین باید بدون clone کردن ببیند چه واژه‌ای اضافه یا عوض شده است — کدام
منبع، کدام درجه‌ی پذیرش، کدام نمونه. بی این، بازبینیِ محتوا به diffِ YAML
تبدیل می‌شود و کسی آن را نمی‌خواند.

    python3 tools/word_preview.py <base-sha> > preview.md
"""

from __future__ import annotations

import pathlib
import subprocess
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
WORDS = "content/words"

PERSIAN_DIGITS = str.maketrans("0123456789", "۰۱۲۳۴۵۶۷۸۹")


def fa(value: object) -> str:
    """اعداد در سره پارسی‌اند — در پیش‌نمایش هم."""
    return str(value).translate(PERSIAN_DIGITS)


ACCEPTANCE_NOTE = {
    "زنده": "هنوز به کار می‌رود",
    "خفته": "در متونِ کهن هست، از گفتار افتاده",
    "نوساخته": "ساخته‌ی فرهنگستان یا سره‌گرایانِ معاصر",
}


def changed_files(base: str) -> list[pathlib.Path]:
    result = subprocess.run(
        ["git", "diff", "--name-only", "--diff-filter=ACM", base, "--", WORDS],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return [
        ROOT / line
        for line in result.stdout.splitlines()
        if line.endswith((".yaml", ".yml"))
    ]


def card(word: dict) -> str:
    lines = [
        f"### {word['sare']}  ←  {word['loan']}",
        "",
        f"**{word.get('definition', '—')}**",
        "",
    ]

    acceptance = word.get("acceptance", "—")
    note = ACCEPTANCE_NOTE.get(acceptance, "")
    facts = [
        f"پذیرش: `{acceptance}`" + (f" — {note}" if note else ""),
        f"گونه: {word.get('pos', '—')} · گفتمان: {word.get('register', '—')}",
        f"آوا: `{word.get('ipa', '—')}` · دشواری: {fa(word.get('difficulty', '—'))}/۵",
        f"خاستگاهِ وام‌واژه: {word.get('loan_origin', '—')}",
        f"وضعیت: `{word.get('status', 'proposed')}`",
    ]
    roots = word.get("roots") or {}
    if roots.get("pahlavi") or roots.get("avestan"):
        chain = " ← ".join(
            part
            for part in (roots.get("avestan"), roots.get("pahlavi"), word["sare"])
            if part
        )
        facts.append(f"ریشه: {chain}")
    lines += [f"- {fact}" for fact in facts]

    examples = word.get("examples") or []
    if examples:
        lines += ["", "**نمونه**", ""]
        for example in examples:
            lines += [
                f"> {example['sare']}",
                f"> <sub>وام‌دار: {example['loan']}</sub>",
                "",
            ]

    citations = word.get("citations") or []
    lines += ["", "**منبع**", ""]
    if citations:
        for citation in citations:
            detail = citation.get("ref") or citation.get("book") or citation.get("verse")
            lines.append(f"- {citation['source']}" + (f" — {detail}" if detail else ""))
    else:
        lines.append("- ⚠️ **بی‌منبع — این مدخل رد می‌شود.**")

    return "\n".join(lines)


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: word_preview.py <base-sha>", file=sys.stderr)
        return 2

    paths = changed_files(sys.argv[1])
    if not paths:
        print("این PR واژه‌ای را عوض نکرده است.")
        return 0

    out = [f"## پیش‌نمایشِ واژه ({fa(len(paths))} مدخل)", ""]
    for path in sorted(paths):
        if not path.exists():
            continue
        try:
            word = yaml.safe_load(path.read_text(encoding="utf-8"))
        except yaml.YAMLError as error:
            out += [f"### `{path.name}`", "", f"⚠️ YAML خوانده نشد: `{error}`", ""]
            continue
        out += [card(word), "", "---", ""]

    out.append(
        "<sub>ساخته‌ی `tools/word_preview.py` · "
        "قاعده‌ها در [CONTENT_GUIDE](../blob/main/docs/CONTENT_GUIDE.md)</sub>"
    )
    print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
