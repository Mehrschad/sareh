#!/usr/bin/env python3
"""هر مدخل را با فرهنگ می‌سنجد و می‌گوید کجا سند نداریم.

چه چیز را می‌سنجد
-----------------
۱. **برابرِ پارسی در فرهنگ هست؟** سره واژه نمی‌سازد. اگر «برابری» که پیشنهاد
   می‌کنیم در دهخدا یا معین یا عمید مدخل نداشته باشد، ساخته‌ی ماست و باید برود.
   مترادف‌نامه و فرهنگِ دوزبانه گواه نیستند — آنها واژه را ثبت نمی‌کنند،
   ترجمه‌اش می‌کنند.

۲. **برابر خودش وام‌واژه نیست؟** جایگزین کردنِ یک واژه‌ی عربی با واژه‌ی عربیِ
   دیگر کاری نمی‌کند. برچسبِ زبانِ عمید روی خودِ برابر این را می‌گیرد.

۳. **خاستگاهِ وام‌واژه با فرهنگ می‌خواند؟** میدانِ `loan_origin` باید برچسبِ
   زبانِ فرهنگ باشد، نه حدسِ ما.

۴. **وام‌واژه به‌راستی وام است؟** اگر فرهنگ آن را «فارسی» برچسب زده باشد،
   مدخل بی‌جاست.

خروجی حکم نیست، فهرستِ کار است: هر خط جایی است که آدمی باید نگاه کند.

    python3 tools/verify_corpus.py            # گزارش
    python3 tools/verify_corpus.py --apply    # سندها را در YAML می‌نویسد
    python3 tools/verify_corpus.py --strict   # نگهبانِ CI

`--strict` روی سه آزمونِ نخست سخت می‌گیرد و می‌شکند. آزمونِ چهارم (خاستگاهِ
بی‌سند) هشدار می‌ماند: فرهنگ برای هر واژه‌ای برچسبِ زبان ندارد، و نداشتنِ
برچسب گناهِ مدخل نیست.

کش (`tools/.dictionary-cache.json`) در مخزن است، پس CI به شبکه نمی‌رود. اگر
واژه‌ای بیفزایید، نخست `python3 tools/lookup_dictionary.py <واژه>` را بزنید و
کشِ به‌روزشده را با PR بفرستید — همان کاری که وارسی را بازتولیدپذیر می‌کند.
"""

from __future__ import annotations

import pathlib
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
WORDS = ROOT / "content" / "words"

sys.path.insert(0, str(ROOT / "tools"))
from lookup_dictionary import (  # noqa: E402
    bare, load_cache, origin_forms, summarize,
)

# زبانِ عمید → میدانِ `roots` که صورتش را در آن می‌نویسیم.
ROOT_FIELDS = {
    "پهلوی": "pahlavi",
    "اوستایی": "avestan",
    "فارسی باستان": "old_persian",
}

DICTIONARY_NAMES = {
    "amid": "فرهنگ عمید",
    "dehkhoda": "لغت‌نامه دهخدا",
    "moein": "فرهنگ فارسی معین",
    "farhangestan": "فرهنگستان زبان و ادب فارسی",
}

# زبان‌هایی که «وام» نیستند: نیای خودِ فارسی‌اند. واژه‌ای که عمید آن را پهلوی
# می‌داند، درست همان چیزی است که سره در پیِ آن است.
NATIVE = ("فارسی", "پهلوی", "اوستایی", "فارسی باستان", "سنسکریت")

# هم‌نگاشت‌هایی که نشانیِ مستقیمِ فرهنگ هم جدایشان نمی‌کند: یک املا، دو واژه،
# و عمید سرواژه‌ی عربی را برگزیده است. هر کدام دستی وارسی شده — تلفظ و معنیِ
# مدخل با واژه‌ی ما نمی‌خوانَد. اگر با یکی هم‌داستان نیستید، Issue بزنید.
CHECKED_HOMOGRAPHS = {
    "بو": "مدخلِ عمید «بو» = مخففِ اَبو (پدر) است؛ بویِ ما پهلویِ bōd است",
    "انجام": "مدخلِ عمید «اَنجام» = جمعِ نَجم است؛ انجامِ ما پایان است",
    "مهر": "مدخلِ عمید «مَهر» = کابینِ عقد است؛ مهرِ ما اوستاییِ miθra است",
    "سرا": "مدخلِ عمید «سَرّاء» = شادی است؛ سرایِ ما خانه است",
    "کانون": "سریانی است نه عربی، و هزار سال است پارسی شده؛ "
             "«به پارسی» هم نخستین برابرِ «مرکز» را همین می‌داند",
}


def heads(text: str) -> list[str]:
    return [t.strip("ِ") for t in text.split() if t.strip("ِ")]


def load_entries() -> list[tuple[pathlib.Path, dict]]:
    return [
        (path, yaml.safe_load(path.read_text(encoding="utf-8")))
        for path in sorted(WORDS.glob("*.yaml"))
    ]


def attest(word: str, cache: dict) -> list[str]:
    """فرهنگ‌های معتبری که این واژه در آنها مدخل دارد."""
    return summarize(cache.get(bare(word)) or {})["attested"]


# وندهای زایای پارسی. واژه‌ای که با وندِ پارسی از بُنِ ثبت‌شده‌ی پارسی ساخته
# شده باشد، ساخته‌ی ما نیست — ساختِ خودِ زبان است. «شمارگان» را فرهنگ ندارد،
# ولی «شمار» را دارد و «ـگان» وندِ خودِ زبان است.
SUFFIXES = ("گان", "مند", "وند", "گاه", "نده", "یی", "ها", "ان", "ی", "ه", "م")
PREFIXES = ("بی", "با", "هم", "نا", "فرا", "بر", "در", "پیش", "پس", "باز")


def parts(word: str) -> list[str]:
    """جزءهای یک ترکیب: «گاه‌شمار» → گاه، شمار."""
    return [p for p in bare(word).replace("‌", " ").split() if p not in ("و", "ی")]


def stems(word: str) -> list[str]:
    """صورت‌هایی که باید در فرهنگ جست: خودِ واژه و بُنِ آن پس از کندنِ وند."""
    forms = [word]
    # واوِ عطف در «گفت‌وگو»؛ ولی «واژه» را نباید به «اژه» شکست، پس هر دو
    # صورت را می‌آزماییم و به فرهنگ می‌گذاریم که بگوید کدام واژه است.
    if word.startswith("و") and len(word) > 2:
        forms.append(word[1:])
    for prefix in PREFIXES:
        if word.startswith(prefix) and len(word) - len(prefix) >= 2:
            forms.append(word[len(prefix):])
    for suffix in SUFFIXES:
        if word.endswith(suffix) and len(word) - len(suffix) >= 2:
            forms.append(word[: -len(suffix)])
    return forms


def rooted(word: str, cache: dict, depth: int = 2) -> bool:
    """آیا این واژه از مایه‌ی ثبت‌شده‌ی پارسی ساخته شده است؟

    دو آزمون، از تنگ به گشاد. دومی تنها وقتی به کار می‌آید که نخستین شکسته
    باشد: واژه‌ای که به واژه‌های فرهنگ‌دار بخش می‌شود — «گرد» و «همایی»، یا
    «در» و «بر» و «گیرنده» — ترکیبِ خودِ زبان است، نه ساخته‌ی ما.
    """
    if any(attest(form, cache) for form in stems(word)):
        return True
    if depth <= 0:
        return False
    for cut in range(2, len(word) - 1):
        if attest(word[:cut], cache) and rooted(word[cut:], cache, depth - 1):
            return True
    return False


def languages(word: str, cache: dict) -> list[str]:
    """برچسبِ زبانِ خودِ این واژه، بی‌کم‌وکاست."""
    return summarize(cache.get(bare(word)) or {})["languages"]


def origin_of(word: str, cache: dict) -> list[str]:
    """خاستگاهِ وام‌واژه؛ اگر خودش برچسب ندارد، از بُنش.

    «آخرین» را عمید برچسب نمی‌زند، چون صورتی است پارسی‌ساخت از «آخر». ولی
    مایه‌اش عربی است و آموزنده باید همین را بداند — پس بُن را می‌پرسیم.

    این فروکاست تنها برای وام‌واژه است. اگر آن را بر برابرِ پارسی هم ببندیم،
    «هموند» را از راهِ «وند» عربی می‌شمارد و کارِ درست را خراب می‌کند.
    """
    tags = languages(word, cache)
    if tags:
        return tags
    for form in stems(bare(word))[1:]:
        tags = summarize(cache.get(form) or {})["languages"]
        if tags:
            return tags
    return []


def main() -> int:
    cache = load_cache()
    entries = load_entries()
    apply_changes = "--apply" in sys.argv

    unattested_sare: list[tuple[str, str]] = []
    borrowed_sare: list[tuple[str, str, str]] = []
    origin_conflict: list[tuple[str, str, str, str]] = []
    origin_unsourced: list[tuple[str, str]] = []
    not_a_loan: list[tuple[str, str]] = []
    changed = 0

    for path, entry in entries:
        wid, sare, loan = entry["id"], entry["sare"], entry["loan"]

        # ۱ و ۲ — برابرِ پارسی
        sare_tokens = heads(sare)
        proven = [t for t in sare_tokens if attest(t, cache)]
        if not proven:
            # ترکیبی مانند «گاه‌شمار» یا مشتقی مانند «شمارگان» شاید مدخلِ خود
            # نداشته باشد؛ اگر هر جزءش — یا بُنِ هر جزءش — در فرهنگ باشد،
            # ساخته‌ی ما نیست: ساختِ خودِ زبان است از مایه‌ی ثبت‌شده.
            pieces = [p for t in sare_tokens for p in parts(t)]
            grounded = all(rooted(piece, cache) for piece in pieces)
            if not (pieces and grounded):
                unattested_sare.append((wid, sare))
        for token in sare_tokens:
            tags = languages(token, cache)
            foreign = [lang for lang in tags if lang not in NATIVE]
            # «زمان» را عمید «[پهلوی: zamān و عربی]» می‌نویسد: واژه‌ای پارسی که
            # عربی هم آن را گرفته است. برچسبِ بومی، برچسبِ بیگانه را می‌شکند.
            if (foreign and not any(lang in NATIVE for lang in tags)
                    and token not in CHECKED_HOMOGRAPHS):
                borrowed_sare.append((wid, token, "، ".join(foreign)))

        # ۳ و ۴ — خاستگاهِ وام‌واژه
        head = heads(loan)[0]
        tags = origin_of(head, cache)
        if not tags:
            origin_unsourced.append((wid, loan))
        elif "فارسی" in tags and entry["loan_origin"] not in tags:
            not_a_loan.append((wid, loan))
        elif entry["loan_origin"] not in tags:
            origin_conflict.append((wid, loan, entry["loan_origin"], "، ".join(tags)))

        if apply_changes:
            added = False

            # سندِ برابر: کدام فرهنگ این واژه را مدخل دارد.
            existing = {c["source"] for c in entry["citations"]}
            for slug in attest(sare_tokens[0], cache):
                name = DICTIONARY_NAMES[slug]
                if name in existing:
                    continue
                entry["citations"].append({
                    "source": name,
                    "ref": f"https://www.vajehyab.com/{slug}/"
                           f"{bare(sare_tokens[0])}",
                })
                existing.add(name)
                added = True

            # ریشه‌ی مستند: عمید صورتِ اصلی را در کروشه می‌آورد —
            # «مغز» → «[پهلوی: mazg]». همان چیزی که میدانِ roots می‌خواهد.
            amid = (cache.get(bare(sare_tokens[0])) or {}).get("amid")
            for language, form in origin_forms((amid or {}).get("kind", "")):
                field = ROOT_FIELDS.get(language)
                if field and form and not entry["roots"].get(field):
                    entry["roots"][field] = form
                    added = True

            # مدخلی که برابرش در فرهنگ ثبت است و خاستگاهش سند دارد، دیگر
            # «پیشنهاد» نیست؛ کسی آن را با فرهنگ سنجیده است.
            if (attest(sare_tokens[0], cache) and origin_of(head, cache)
                    and entry["status"] == "proposed"):
                entry["status"] = "reviewed"
                added = True

            if added:
                path.write_text(
                    yaml.dump(entry, allow_unicode=True, sort_keys=False,
                              default_flow_style=False, width=100),
                    encoding="utf-8",
                )
                changed += 1

    total = len(entries)
    print(f"پیکره: {total} مدخل\n")

    print(f"■ برابرِ پارسیِ بی‌مدخل در فرهنگ — {len(unattested_sare)}")
    print("  (دهخدا/معین/عمید هیچ‌کدام این واژه را ندارند؛ یا نویسه‌گردانی است"
          " یا ساخته)")
    for wid, sare in unattested_sare[:40]:
        print(f"    {sare:<18} {wid}")
    if len(unattested_sare) > 40:
        print(f"    … و {len(unattested_sare) - 40} تای دیگر")

    print(f"\n■ برابری که خودش وام‌واژه است — {len(borrowed_sare)}")
    print("  (معنیِ فرهنگ را بخوانید: شاید مدخل، هم‌نگاشتِ واژه‌ی ما باشد)")
    for wid, token, langs in borrowed_sare:
        gloss = ""
        for dictionary in DICTIONARY_NAMES:
            found = (cache.get(token) or {}).get(dictionary)
            if found:
                gloss = found["definition"][:60].replace("\n", " ")
                break
        print(f"    {token:<14} {langs:<16} {wid}")
        print(f"        فرهنگ: {gloss}")

    print(f"\n■ خاستگاهِ ناهم‌خوان با فرهنگ — {len(origin_conflict)}")
    for wid, loan, ours, theirs in origin_conflict:
        print(f"    {loan:<18} ما: {ours:<10} فرهنگ: {theirs:<16} {wid}")

    print(f"\n■ واژه‌ای که فرهنگ آن را فارسی می‌داند — {len(not_a_loan)}")
    for wid, loan in not_a_loan:
        print(f"    {loan:<18} {wid}")

    print(f"\n■ خاستگاهِ بی‌سند (فرهنگ برچسبِ زبان ندارد) — "
          f"{len(origin_unsourced)}")

    sourced = total - len(origin_unsourced)
    print(f"\nخاستگاهِ سنجیده: {sourced}/{total} "
          f"({100 * sourced / total:.0f}٪)")
    proven_count = total - len(unattested_sare)
    print(f"برابرِ ثبت‌شده در فرهنگ: {proven_count}/{total} "
          f"({100 * proven_count / total:.0f}٪)")
    if apply_changes:
        print(f"\n{changed} پرونده به‌روز شد.")

    if "--strict" in sys.argv:
        broken = (len(unattested_sare) + len(borrowed_sare)
                  + len(origin_conflict) + len(not_a_loan))
        if broken:
            print(f"\n✗ {broken} مدخل با فرهنگ نمی‌خوانَد.")
            return 1
        print("\n✓ هر برابر در فرهنگ مدخل دارد و هیچ برابری خودش وام‌واژه نیست.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
