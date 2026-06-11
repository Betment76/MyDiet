"""Generate lib/data/victory/victory_meal_data.dart from docs/Pobeda-nad-vesom.fb2.

Правила этапов — victory_stage_data.dart (контейнеры).
В днях — только продукты и нормы. Не выдумывать меню по дням.
"""
from pathlib import Path

PREP_DAY_COUNT = 14
MAIN_DAY_COUNT = 28
CONSOLIDATION_DAY_COUNT = 28

PREP_MEALS = [
    ("Ходьба", "60 мин; L-карнитин — 1500 мг до и после", []),
    ("Завтрак", "Кефир — 200 мл; кедровые орехи — горсть; отруби", ["Кефир", "Кедровые орехи", "Отруби"]),
    ("Фрукты", "Яблоки — 2–4 шт. или грейпфрут — 2 шт. до 18:00", ["Яблоки"]),
    ("Овощи", "Сырые овощи с 18:00 (кроме моркови, свёклы)", []),
    (
        "Ужин",
        "Салат — масло 1 ст. л., творог 0% — 2 ст. л.; вино — 100–150 мл",
        ["Творог", "Оливковое масло"],
    ),
    ("Перед сном", "Яичный белок — 2 шт.", ["Яйца"]),
]

MAIN_MEALS = [
    ("Ходьба", "40–70 мин; L-карнитин — 1500 мг до и после", []),
    ("Завтрак", "Изолят протеина + отруби (по расчёту белка)", ["Протеин", "Отруби"]),
    (
        "Обед",
        "Белок по недельной схеме: творог / рыба / мясо (см. контейнер)",
        ["Творог", "Рыба", "Курица"],
    ),
    ("Фрукты", "До 400 г до 18:00", ["Яблоки"]),
    ("Дополнительно", "Миндаль — 8 шт.; отруби; кефир — 1 ст.", ["Миндаль", "Отруби", "Кефир"]),
    (
        "Ужин",
        "Салат + белок по правилам 2-го этапа (см. контейнер)",
        [],
    ),
]

CONSOLIDATION_MEALS = [
    ("Шаги", "От 10 000 шагов в день", []),
    (
        "Питание",
        "Разнообразно; без однообразия; правила сочетания — в контейнере",
        [],
    ),
    ("Вода", "1,5–2 л по желанию", []),
    ("Активность", "Ходьба; без обязательных тренировок к концу этапа", []),
]


def _day_block(day: int, meals: list) -> str:
    lines = [f"  PrepDay(day: {day}, meals: ["]
    for name, details, ingredients in meals:
        ing = ", ".join(f"'{x}'" for x in ingredients)
        ing_part = f", ingredients: [{ing}]" if ing else ", ingredients: []"
        esc = details.replace("'", "\\'")
        lines.append(
            f"    PrepMeal(name: '{name}', details: '{esc}'{ing_part}),"
        )
    lines.append("  ])")
    return "\n".join(lines)


def _plan(count: int, meals: list) -> list[str]:
    return [_day_block(d, meals) for d in range(1, count + 1)]


out = f"""// AUTO-GENERATED from docs/Pobeda-nad-vesom.fb2
// Правила — victory_stage_data.dart; здесь только продукты и нормы.
// ignore_for_file: lines_longer_than_80_chars

import 'package:my_diet/data/prep_plan_data.dart';

const List<List<PrepDay>> victoryStagePlans = [
  victoryPrepPlan,
  victoryMainPlan,
  victoryConsolidationPlan,
];

const List<PrepDay> victoryPrepPlan = [
{',\n'.join(_plan(PREP_DAY_COUNT, PREP_MEALS))},
];

const List<PrepDay> victoryMainPlan = [
{',\n'.join(_plan(MAIN_DAY_COUNT, MAIN_MEALS))},
];

const List<PrepDay> victoryConsolidationPlan = [
{',\n'.join(_plan(CONSOLIDATION_DAY_COUNT, CONSOLIDATION_MEALS))},
];
"""

root = Path(__file__).resolve().parents[1]
path = root / "lib/data/victory/victory_meal_data.dart"
path.write_text(out, encoding="utf-8")
print(f"Written {path}")
