#!/usr/bin/env python3
"""Fix mixed Latin/Cyrillic and trim author commentary from meal details."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

PERSONAL_MARKERS = [
    ". Сегодня",
    ". Сегодняшний",
    ". В среду",
    ". Если уж мы",
    ". Если вы",
    ". До боли",
    ". ЭТО ИНТЕРЕСНО",
    ". Начните",
    ". Утро мы",
    ". •",
    ". Предлагаю",
]

CLASSIC_BREAKFAST = "Классический завтрак: йогурт/кефир, орехи, отруби."


def trim_personal_commentary(details: str) -> str:
    for marker in PERSONAL_MARKERS:
        if marker in details:
            details = details.split(marker, 1)[0].rstrip()
            if not details.endswith("."):
                details += "."
            return details
    return details


def fix_fun_meal(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    text = text.replace("йогurt", "йогурт")
    text = re.sub(
        r"details: 'Классический завтрак: йогурт/кефир, орехи, отруби\.[^']*'",
        f"details: '{CLASSIC_BREAKFAST}'",
        text,
    )
    path.write_text(text, encoding="utf-8")


def fix_gourmet_prep_breakfasts(path: Path) -> None:
    text = path.read_text(encoding="utf-8")

    def repl(match: re.Match[str]) -> str:
        details = match.group(1)
        cleaned = trim_personal_commentary(details)
        return f"details: '{cleaned}'"

    # Only prep plan breakfasts (first ~100 lines / gourmetPrepPlan section)
    parts = text.split("const List<PrepDay> gourmetPrepPlan = [", 1)
    if len(parts) != 2:
        return
    head, tail = parts
    rest = tail.split("];", 1)
    if len(rest) != 2:
        return
    prep, after = rest
    prep = re.sub(
        r"(PrepMeal\(name: 'Завтрак', )details: '([^']*)'",
        lambda m: f"{m.group(1)}details: '{trim_personal_commentary(m.group(2))}'",
        prep,
    )
    path.write_text(head + "const List<PrepDay> gourmetPrepPlan = [" + prep + "];" + after, encoding="utf-8")


def fix_latin_c_in_russian_words(path: Path) -> None:
    text = path.read_text(encoding="utf-8")

    def fix_word(word: str) -> str:
        if not word or word[0] != "c":
            return word
        if len(word) == 1:
            return word
        second = word[1]
        if "а" <= second <= "я" or second in "ёЁ":
            return "с" + word[1:]
        return word

    def fix_string(match: re.Match[str]) -> str:
        quote = match.group(1)
        body = match.group(2)
        body = re.sub(r"\b\w+\b", lambda m: fix_word(m.group(0)), body)
        return f"{quote}{body}{quote}"

    text = re.sub(r"(['\"])(.*?)\1", fix_string, text)
    path.write_text(text, encoding="utf-8")


def main() -> None:
    fix_fun_meal(ROOT / "lib/data/fun/fun_meal_data.dart")
    fix_gourmet_prep_breakfasts(ROOT / "lib/data/gourmet/gourmet_meal_data.dart")

    literature = ROOT / "lib/data/literature_data.dart"
    literature.write_text(
        literature.read_text(encoding="utf-8").replace("Cамара", "Самара"),
        encoding="utf-8",
    )

    fix_latin_c_in_russian_words(ROOT / "lib/data/fun/fun_recipes_data.dart")

    print("Done.")


if __name__ == "__main__":
    main()
