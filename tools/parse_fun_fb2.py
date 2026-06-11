#!/usr/bin/env python3
"""Extract «Худеем интересно» meal plans from FB2 into Dart source."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FB2 = ROOT / "docs" / "Hudeem-interesno-Recepty.fb2"
OUT = ROOT / "lib" / "data" / "fun" / "fun_meal_data.dart"

INGREDIENT_HINTS = {
    "кефир": "Кефир",
    "йогурт": "Йогурт",
    "творог": "Творог",
    "орех": "Грецкие орехи",
    "миндаль": "Миндаль",
    "кедр": "Кедровые орехи",
    "отруб": "Отруби",
    "яблок": "Яблоки",
    "грейпфрут": "Грейпфрут",
    "огур": "Огурцы",
    "помидор": "Помидоры",
    "перец": "Болгарский перец",
    "капуст": "Капуста",
    "морков": "Морковь",
    "сельдер": "Сельдерей",
    "брокколи": "Брокколи",
    "баклажан": "Баклажаны",
    "яйц": "Яйца",
    "белок": "Яйца",
    "фасол": "Фасоль",
    "чечевиц": "Чечевица",
    "куриц": "Курица",
    "индейк": "Индейка",
    "лосос": "Лосось",
    "рыб": "Рыба",
    "треск": "Треска",
    "мясо": "Говядина",
    "оливков": "Оливковое масло",
    "сыр": "Сыр",
    "груш": "Груши",
}


def guess_ingredients(text: str) -> list[str]:
    lower = text.lower()
    found = []
    for key, val in INGREDIENT_HINTS.items():
        if key in lower and val not in found:
            found.append(val)
    if not found:
        found = ["Огурцы", "Помидоры"]
    return found[:6]


def clean(s: str) -> str:
    s = re.sub(r"<[^>]+>", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def dart_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


def recipe_titles(chunk: str) -> list[str]:
    skip = (
        "подъем", "гуляем", "тренировк", "завтрак", "обед", "ужин",
        "полдник", "день ", "неделя", "этап", "чай", "омлет", "белок",
    )
    titles = []
    for m in re.finditer(r"<title>\s*<p>([^<]+)</p>\s*</title>", chunk):
        t = clean(m.group(1))
        low = t.lower()
        if any(w in low for w in skip):
            continue
        if len(t) < 4 or t.startswith("«"):
            continue
        titles.append(t)
    return titles


def parse_stage1_day(chunk: str) -> list[dict]:
    titles = recipe_titles(chunk)
    dinner = titles[-1] if titles else "Овощной салат по методике"

    bf_note = ""
    if m := re.search(r"9\.00.*?завтрак\.?\s*(.*?)</p>", chunk, re.S | re.I):
        bf_note = clean(m.group(1))[:80]

    tea = next((t for t in titles if "чай" in t.lower()), None)
    bf = f"Классический завтрак: йогurt/кефир, орехи, отруби. {bf_note}".strip()
    if tea:
        bf = f"{tea}. {bf}"[:200]

    return [
        {
            "name": "Завтрак",
            "details": bf[:200],
            "ingredients": guess_ingredients(bf),
        },
        {
            "name": "Перекус",
            "details": "3–4 яблока, отруби, чай и кофе без ограничений",
            "ingredients": ["Яблоки", "Отруби"],
        },
        {
            "name": "Ужин",
            "details": dinner[:200],
            "ingredients": guess_ingredients(dinner),
        },
        {
            "name": "Перед сном",
            "details": "2 яичных белка (желтки не нужны)",
            "ingredients": ["Яйца"],
        },
    ]


def parse_stage2_day(chunk: str) -> list[dict]:
    titles = recipe_titles(chunk)
    if not titles:
        titles = ["Завтрак по методике", "Обед", "Ужин — салат"]

    breakfast = titles[0]
    lunch_parts = titles[1:3] if len(titles) >= 3 else titles[1:2]
    lunch = " + ".join(lunch_parts) if lunch_parts else "Обед по методике"
    dinner = titles[3] if len(titles) > 3 else (titles[-2] if len(titles) > 2 else "Овощной салат")
    bedtime = titles[-1] if titles and ("омлет" in titles[-1].lower() or "белок" in titles[-1].lower()) else "Пикантный омлет из белков"

    return [
        {
            "name": "Завтрак",
            "details": breakfast[:200],
            "ingredients": guess_ingredients(breakfast),
        },
        {
            "name": "Обед",
            "details": lunch[:200],
            "ingredients": guess_ingredients(lunch),
        },
        {
            "name": "Полдник",
            "details": "Отруби и фрукты (груша, яблоко или цитрусовые)",
            "ingredients": ["Отруби", "Яблоки"],
        },
        {
            "name": "Ужин",
            "details": dinner[:200],
            "ingredients": guess_ingredients(dinner),
        },
        {
            "name": "Перед сном",
            "details": bedtime[:200],
            "ingredients": ["Яйца"],
        },
    ]


def split_stage_days(text: str, stage: int) -> list[str]:
    if stage == 1:
        start = text.find("<p>Итак, начинаем! Первый этап</p>")
        end = text.find("<p>Рецепты салатов для первого этапа</p>")
        region = text[start:end]
        pattern = r"(?=<title>\s*<p>Первый этап\.)"
    else:
        start = text.find("<p>Второй этап</p>", text.find("Рецепты салатов"))
        end = text.find("<p>Салаты для второго этапа</p>")
        region = text[start:end]
        pattern = r"(?=<title>\s*<p>Второй этап\.)"

    parts = re.split(pattern, region)
    return [p for p in parts if "день" in p[:300].lower() or "День" in p[:300]]


def emit_dart(all_stages: list[list[list[dict]]]) -> str:
    lines = [
        "// AUTO-GENERATED from docs/Hudeem-interesno-Recepty.fb2",
        "// ignore_for_file: lines_longer_than_80_chars",
        "",
        "import 'package:my_diet/data/prep_plan_data.dart';",
        "",
        "const List<List<PrepDay>> funStagePlans = [",
    ]
    names = ["funPrepPlan", "funMainPlan", "funConsolidationPlan"]
    for name in names:
        lines.append(f"  {name},")
    lines.append("];")
    lines.append("")

    for stage, name in zip(all_stages, names):
        lines.append(f"const List<PrepDay> {name} = [")
        for di, day_meals in enumerate(stage, 1):
            lines.append(f"  PrepDay(day: {di}, meals: [")
            for m in day_meals:
                ings = ", ".join(f"'{dart_escape(i)}'" for i in m["ingredients"])
                lines.append(
                    f"    PrepMeal(name: '{dart_escape(m['name'])}', "
                    f"details: '{dart_escape(m['details'])}', "
                    f"ingredients: [{ings}]),"
                )
            lines.append("  ]),")
        lines.append("];")
        lines.append("")
    return "\n".join(lines)


def main():
    text = FB2.read_text(encoding="utf-8")
    s1_chunks = split_stage_days(text, 1)
    s2_chunks = split_stage_days(text, 2)

    stage1 = [parse_stage1_day(c) for c in s1_chunks[:14]]
    stage2 = [parse_stage2_day(c) for c in s2_chunks[:21]]

    stage3 = []
    for i in range(14):
        src = stage2[i % len(stage2)]
        stage3.append([
            {
                "name": m["name"],
                "details": m["details"] + " (удержание веса)",
                "ingredients": list(m["ingredients"]),
            }
            for m in src
        ])

    dart = emit_dart([stage1, stage2, stage3])
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(dart, encoding="utf-8")
    print(f"Wrote {OUT}")
    print(f"Stage1: {len(stage1)}, Stage2: {len(stage2)}, Stage3: {len(stage3)}")


if __name__ == "__main__":
    main()
