#!/usr/bin/env python3
"""Extract gourmet meal plans from FB2 into Dart source."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FB2 = ROOT / "docs" / "Dieta-dlya-gurmanov-Plan-pitaniya.fb2"
OUT = ROOT / "lib" / "data" / "gourmet" / "gourmet_meal_data.dart"

MEAL_NAMES = ["Завтрак", "Перекус", "Обед", "Полдник", "Ужин", "Перед сном"]

# Rough ingredient mapping from dish keywords
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
    "рукол": "Рукола",
    "капуст": "Капуста",
    "морков": "Морковь",
    "сельдер": "Сельдерей",
    "шпинат": "Шпинат",
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
    "мясо": "Говядина",
    "оливков": "Оливковое масло",
    "сыр": "Сыр",
    "хлебц": "Отруби",
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


def extract_stage_region(text: str, stage_num: int) -> str:
    start_mark = f"{stage_num}\xa0этап"
    idx = text.find(start_mark)
    if idx == -1:
        raise ValueError(f"Stage {stage_num} not found")
    if stage_num == 1:
        end = text.find("2\xa0этап")
    elif stage_num == 2:
        # end before large recipe appendix
        m = re.search(r"<p>Рецепты салатов для первого этапа</p>", text[idx + 5000 :])
        if m:
            end = idx + 5000 + m.start()
        else:
            m2 = re.search(r"<p>3\s*этап", text[idx + 5000 :])
            end = idx + 5000 + m2.start() if m2 else len(text)
    else:
        end = len(text)
    return text[idx:end]


def split_days(region: str) -> list[str]:
    parts = re.split(r"(?=<title>\s*<p>День \d+</p>\s*</title>)", region)
    days = [p for p in parts if "<p>День " in p[:200]]
    return days


def parse_stage1_day(chunk: str, day_num: int) -> list[dict]:
    subs = re.findall(r"<subtitle><strong>([^<]+)</strong></subtitle>", chunk)
    subs = [s.strip() for s in subs if s.strip()]
    meals = []

    # Breakfast block
    bf_match = re.search(r"9\.00.*?Завтрак[^<]*</strong></p>(.*?)(?:<p><strong>В течение|<p><strong>Вечером|<p><strong>9\.00|<section>)", chunk, re.S)
    bf_details = ""
    if bf_match:
        bf_text = re.sub(r"<[^>]+>", " ", bf_match.group(1))
        bf_text = re.sub(r"\s+", " ", bf_text).strip()
        tea = subs[0] if subs else "Зелёный чай"
        bf_details = f"{tea}. " + (bf_text[:120] + "…" if len(bf_text) > 120 else bf_text)
    else:
        bf_details = subs[0] if subs else "Классический завтрак методики"

    meals.append({"name": "Завтрак", "details": bf_details[:200], "ingredients": guess_ingredients(bf_details)})

    meals.append({
        "name": "Перекус",
        "details": "3–4 яблока, отруби, чай и кофе без ограничений",
        "ingredients": ["Яблоки", "Отруби"],
    })

    dinner = subs[1] if len(subs) > 1 else "Овощной салат"
    meals.append({
        "name": "Ужин",
        "details": dinner,
        "ingredients": guess_ingredients(dinner),
    })

    meals.append({
        "name": "Перед сном",
        "details": "2 яичных белка (желтки не нужны)",
        "ingredients": ["Яйца"],
    })
    return meals


def parse_stage2_day(chunk: str, day_num: int) -> list[dict]:
    subs = re.findall(r"<subtitle><strong>([^<]+)</strong></subtitle>", chunk)
    subs = [s.strip() for s in subs if s.strip()]
    meals = []

    breakfast = subs[0] if subs else "Завтрак"
    meals.append({
        "name": "Завтрак",
        "details": breakfast,
        "ingredients": guess_ingredients(breakfast),
    })

    # Lunch: dishes between breakfast and snack/dinner
    lunch_dishes = subs[1:3] if len(subs) >= 3 else (subs[1:2] if len(subs) > 1 else ["Обед"])
    meals.append({
        "name": "Обед",
        "details": " + ".join(lunch_dishes),
        "ingredients": guess_ingredients(" ".join(lunch_dishes)),
    })

    meals.append({
        "name": "Полдник",
        "details": "Отруби и фрукты (груша, яблоко или цитрусовые)",
        "ingredients": ["Отруби", "Яблоки"],
    })

    dinner = subs[3] if len(subs) > 3 else (subs[-2] if len(subs) > 2 else "Овощной салат")
    meals.append({
        "name": "Ужин",
        "details": dinner,
        "ingredients": guess_ingredients(dinner),
    })

    bedtime = subs[-1] if subs else "Яичные белки или омлет"
    if "омлет" in bedtime.lower() or "белок" in bedtime.lower() or len(subs) >= 5:
        bt = subs[-1]
    else:
        bt = "2 яичных белка"
    meals.append({
        "name": "Перед сном",
        "details": bt,
        "ingredients": ["Яйца"],
    })
    return meals


def dart_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


def emit_dart(all_stages: list[list[list[dict]]]) -> str:
    lines = [
        "// AUTO-GENERATED from docs/Dieta-dlya-gurmanov-Plan-pitaniya.fb2",
        "// ignore_for_file: lines_longer_than_80_chars",
        "",
        "import 'package:my_diet/data/prep_plan_data.dart';",
        "",
        "const List<List<PrepDay>> gourmetStagePlans = [",
    ]
    stage_names = ["gourmetPrepPlan", "gourmetMainPlan", "gourmetConsolidationPlan"]
    for si, stage in enumerate(all_stages):
        lines.append(f"  {stage_names[si]},")
    lines.append("];")
    lines.append("")

    for si, (stage, name) in enumerate(zip(all_stages, stage_names)):
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
    s1_region = extract_stage_region(text, 1)
    s2_region = extract_stage_region(text, 2)
    s1_days = split_days(s1_region)
    s2_days = split_days(s2_region)

    stage1 = [parse_stage1_day(d, i + 1) for i, d in enumerate(s1_days[:14])]
    stage2 = [parse_stage2_day(d, i + 1) for i, d in enumerate(s2_days[:21])]

    # Stage 3: 14-day maintenance rotation (lighter, based on stage 2 patterns)
    stage3 = []
    for i in range(14):
        src = stage2[i % len(stage2)]
        day = []
        for m in src:
            day.append({
                "name": m["name"],
                "details": m["details"] + " (удержание веса)",
                "ingredients": list(m["ingredients"]),
            })
        stage3.append(day)

    dart = emit_dart([stage1, stage2, stage3])
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(dart, encoding="utf-8")
    print(f"Wrote {OUT}")
    print(f"Stage1: {len(stage1)} days, Stage2: {len(stage2)} days, Stage3: {len(stage3)} days")


if __name__ == "__main__":
    main()
