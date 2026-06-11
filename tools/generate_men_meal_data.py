"""Generate lib/data/men/men_meal_data.dart — ONLY from EPUB text.

docs/Kak-hudeyut-nastoyashchie-muzhchiny.epub
Правила этапа — в men_stage_data.dart (контейнер «Основной»).
В днях — только продукты и нормы.
"""
from pathlib import Path

# --- Краткие нормы для карточек дней ---

PREP_MEALS = [
    ("Питание", "Рис «Басмати» — 1 ст.; курага — 250 г", ["Рис", "Курага"]),
    ("Вода", "1,5–2 л в день", []),
]

MAIN_MEALS = [
    ("Утро", "Вода — 1 ст.; кофе/чай — по желанию, до 100 г", []),
    (
        "Порция 1",
        "Фитомуцил — 1 пак.; протеин — 1 ст. л.; вода — 200 мл",
        ["Фитомуцил", "Протеин"],
    ),
    (
        "Порция 2",
        "Фитомуцил — 1 пак.; протеин — 1 ст. л.; вода — 200 мл",
        ["Фитомуцил", "Протеин"],
    ),
    (
        "Порция 3",
        "Фитомуцил — 1 пак.; протеин — 1 ст. л.; вода — 200 мл (до 18:00)",
        ["Фитомуцил", "Протеин"],
    ),
    (
        "Ужин",
        "Салат — овощи, масло 1 ст. л.; мясо/птица — до 160 г "
        "или рыба — до 180 г; вино — до 100 мл, по желанию",
        [],
    ),
]

EXIT_PHASE1_MEALS = [
    ("Утро", "Вода — 1 ст.; кофе/чай — по желанию, до 100 г", []),
    (
        "Порция 1",
        "Фитомуцил — 1 пак.; протеин — 1 ст. л.; вода — 200 мл",
        ["Фитомуцил", "Протеин"],
    ),
    ("Порция 2", "Салат — как на ужин", []),
    (
        "Порция 3",
        "Фитомуцил — 1 пак.; протеин — 1 ст. л.; вода — 200 мл (до 18:00)",
        ["Фитомуцил", "Протеин"],
    ),
    (
        "Ужин",
        "Салат — овощи, масло 1 ст. л.; мясо/птица — до 160 г "
        "или рыба — до 180 г",
        [],
    ),
]

EXIT_PHASE2_MEALS = [
    ("Утро", "Яйца куриные — 2 шт.", ["Яйца"]),
    (
        "Порция 1",
        "Фитомуцил — 1 пак.; протеин — 1 ст. л.; вода — 200 мл",
        ["Фитомуцил", "Протеин"],
    ),
    (
        "Порция 2",
        "Фитомуцил — 1 пак.; протеин — 1 ст. л.; вода — 200 мл",
        ["Фитомуцил", "Протеин"],
    ),
    (
        "Ужин",
        "Салат — овощи, масло 1 ст. л.; мясо/птица — до 160 г "
        "или рыба — до 180 г",
        [],
    ),
]

MAIN_DAY_COUNT = 28
EXIT_PHASE_DAYS = 14


def _day_block(day: int, meals: list) -> str:
    lines = [f"  PrepDay(day: {day}, meals: ["]
    for name, details, ingredients in meals:
        ing = ", ".join(f"'{x}'" for x in ingredients)
        ing_part = f", ingredients: [{ing}]" if ing else ", ingredients: []"
        lines.append(
            f"    PrepMeal(name: '{name}', "
            f"details: '{details.replace(chr(39), chr(92)+chr(39))}'{ing_part}),"
        )
    lines.append("  ])")
    return "\n".join(lines)


def prep_plan() -> list[str]:
    return [_day_block(d, PREP_MEALS) for d in range(1, 4)]


def main_plan() -> list[str]:
    return [_day_block(d, MAIN_MEALS) for d in range(1, MAIN_DAY_COUNT + 1)]


def exit_plan() -> list[str]:
    days = [_day_block(d, EXIT_PHASE1_MEALS) for d in range(1, EXIT_PHASE_DAYS + 1)]
    days += [
        _day_block(d, EXIT_PHASE2_MEALS)
        for d in range(EXIT_PHASE_DAYS + 1, EXIT_PHASE_DAYS * 2 + 1)
    ]
    return days


out = f"""// AUTO-GENERATED from docs/Kak-hudeyut-nastoyashchie-muzhchiny.epub
// Правила — men_stage_data.dart; здесь только продукты и нормы.
// ignore_for_file: lines_longer_than_80_chars

import 'package:my_diet/data/prep_plan_data.dart';

const List<List<PrepDay>> menStagePlans = [
  menPrepPlan,
  menMainPlan,
  menExitPlan,
];

const List<PrepDay> menPrepPlan = [
{',\n'.join(prep_plan())},
];

const List<PrepDay> menMainPlan = [
{',\n'.join(main_plan())},
];

const List<PrepDay> menExitPlan = [
{',\n'.join(exit_plan())},
];
"""

root = Path(__file__).resolve().parents[1]
path = root / "lib/data/men/men_meal_data.dart"
path.write_text(out, encoding="utf-8")
print(f"Written {path}")
