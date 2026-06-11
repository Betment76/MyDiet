#!/usr/bin/env python3
"""Audit gourmet recipe stage/category vs meal plan."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
recipes = json.loads((ROOT / "tools/gourmet_recipes.json").read_text(encoding="utf-8"))
meal = (ROOT / "lib/data/gourmet/gourmet_meal_data.dart").read_text(encoding="utf-8")

prep_dinners = re.findall(r"PrepMeal\(name: 'Ужин', details: '([^']+)'", meal)
by_title = {r["title"]: r for r in recipes}
titles = list(by_title.keys())

print("=== Ужины подготовительного этапа ===")
for d in prep_dinners[:14]:
    match = next(
        (t for t in titles if d.replace("«", "").replace("»", "").lower() in t.replace("«", "").replace("»", "").lower()
         or t.replace("«", "").replace("»", "").lower() in d.replace("«", "").replace("»", "").lower()),
        None,
    )
    if match:
        r = by_title[match]
        print(f"  {d} -> stage={r['stage']}, {r['category']}")
    else:
        print(f"  НЕТ РЕЦЕПТА: {d}")

salads_in_main = [
    r["title"]
    for r in recipes
    if r["stage"] == 0
    and r["category"] == "stage1"
    and (
        r["title"].lower().startswith("салат ")
        or "салат «" in r["title"].lower()
        or "салатик" in r["title"].lower()
    )
    and "подушке" not in r["title"].lower()
    and "гарниром" not in r["title"].lower()
]
print(f"\nСалаты в stage1 (должно быть 0): {len(salads_in_main)}")
for t in salads_in_main:
    print(f"  - {t}")

wrong_stage = [r for r in recipes if (r["stage"] == 1 and r["category"] != "stage2")
               or (r["stage"] == 0 and r["category"] not in ("stage1", "salads_stage1"))]
print(f"\nНеверная категория для этапа: {len(wrong_stage)}")
