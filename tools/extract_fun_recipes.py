#!/usr/bin/env python3
"""Extract «Худеем интересно» recipes + images from FB2."""
import base64
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FB2 = ROOT / "docs" / "Hudeem-interesno-Recepty.fb2"
IMG_DIR = ROOT / "assets" / "fun" / "recipes"
META_JSON = ROOT / "tools" / "fun_recipes.json"
OUT_DART = ROOT / "lib" / "data" / "fun" / "fun_recipes_data.dart"

SKIP_TITLE = (
    "подъем", "гуляем", "тренировк", "методик", "день ", "неделя",
    "этап", "рецепты", "салаты для", "супы для", "горячие", "зачем",
    "чего я", "качеств", "клетчатк", "итак", "несколько слов",
    "про ", "воды", "этапы методики",
    "скамейка запасных", "сахарозамен", "заменител", "сукралоз",
    "аспартам", "ксилит", "стеви", "фруктоз", "сорбит", "цикламат",
    "можно всем", "охладить, но не", "очень сладкий", "медовая трава",
    "скандальная репутация", "сладкий абонемент", "принципы питания",
    "мы можем себе",
)


def clean_text(s: str) -> str:
    s = re.sub(r"<[^>]+>", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def dart_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


def extract_images(text: str) -> dict[str, str]:
    IMG_DIR.mkdir(parents=True, exist_ok=True)
    mapping = {}
    for m in re.finditer(
        r'<binary id="([^"]+)" content-type="([^"]+)">([^<]+(?:\s[^<]+)*)</binary>',
        text,
        re.S,
    ):
        img_id = m.group(1)
        b64 = re.sub(r"\s+", "", m.group(3))
        try:
            data = base64.b64decode(b64)
        except Exception:
            continue
        safe = img_id.lstrip("#").replace("/", "_")
        if not safe.lower().endswith((".jpg", ".jpeg", ".png")):
            safe += ".jpg"
        path = IMG_DIR / safe
        if not path.exists():
            path.write_bytes(data)
        mapping[f"#{img_id}"] = f"assets/fun/recipes/{safe}"
        mapping[img_id] = f"assets/fun/recipes/{safe}"
    return mapping


def parse_recipe_block(block: str, images: dict[str, str]) -> dict | None:
    title_m = re.search(r"<title>\s*<p>([^<]+)</p>\s*</title>", block)
    if not title_m:
        return None
    title = clean_text(title_m.group(1))
    low = title.lower()
    if not title or title.startswith("ЭТО ИНТЕРЕСНО"):
        return None
    if any(w in low for w in SKIP_TITLE):
        return None
    if re.search(r"\d+\.\d+–\d+\.\d+", title):
        return None

    img_m = re.search(r'<image l:href="#([^"]+)"', block)
    image_asset = None
    if img_m:
        ref = img_m.group(1)
        image_asset = images.get(ref) or images.get(f"#{ref}")

    ingredients = []
    steps = []
    for p in re.findall(r"<p>(.*?)</p>", block, re.S):
        raw = p.strip()
        if not raw or "<cite>" in raw:
            continue
        plain = clean_text(re.sub(r"</?emphasis>", "", raw))
        if plain.startswith("●") or (plain.startswith("–") and len(plain) < 120):
            if not plain.lower().startswith("итого"):
                ingredients.append(plain.lstrip("● ").strip())
            continue
        if "<strong>Итого" in raw or "<strong>ИТОГО" in raw:
            break
        if len(plain) < 15:
            continue
        if re.match(r"^[679]\.", plain):
            continue
        if "это интересно" in plain.lower():
            continue
        steps.append(plain)

    if not ingredients and not steps:
        return None
    if len(steps) == 0 and len(ingredients) < 2:
        return None
    # Real recipes list ingredients with ●; skip essay blocks mis-parsed as recipes.
    if not ingredients:
        return None
    if len(ingredients) < 2 and not any("●" in p for p in re.findall(r"<p>(.*?)</p>", block, re.S)):
        return None

    return {
        "title": title,
        "image": image_asset,
        "ingredients": ingredients[:20],
        "steps": steps[:12],
    }


def category_for_pos(pos: int, markers: dict[str, int]) -> tuple[str, int] | None:
    if markers["s2_treats"] <= pos < markers["s2_after_treats"]:
        return "treats_stage2", 1
    if markers["s2_fish"] <= pos < markers["s2_fish_end"]:
        return "fish_stage2", 1
    if markers["s2_meat"] <= pos < markers["s2_fish"]:
        return "meat_stage2", 1
    if markers["s2_soups"] <= pos < markers["s2_meat"]:
        return "soups_stage2", 1
    if markers["s2_salads"] <= pos < markers["s2_soups"]:
        return "salads_stage2", 1
    if markers["s2_start"] <= pos < markers["s2_salads"]:
        return "meals_stage2", 1
    if pos >= markers["s1_salads"] and pos < markers["s2_start"]:
        return "salads_stage1", 0
    if pos < markers["s1_salads"]:
        return "meals_stage1", 0
    return None


def main():
    text = FB2.read_text(encoding="utf-8")
    images = extract_images(text)
    print(f"Extracted {len(images)} images")

    markers = {
        "s1_salads": text.find("Рецепты салатов для первого этапа"),
        "s2_start": text.find("<p>Второй этап</p>", text.find("Рецепты салатов")),
        "s2_salads": text.find("Салаты для второго этапа"),
        "s2_soups": text.find("Супы для второго этапа"),
        "s2_meat": text.find("Горячие мясные блюда для второго этапа"),
        "s2_fish": text.find("Горячие блюда из рыбы и морепродуктов"),
        "s2_fish_end": text.find("Скамейка запасных, или подробнее о сахарозаменителях"),
        "s2_treats": text.find("Мы можем себе это позволить!"),
        "s2_after_treats": text.find("Принципы питания в дни силовых нагрузок"),
    }

    parts = re.split(r"(?=<section>)", text[markers["s1_salads"] :])
    recipes_by_title: dict[str, dict] = {}

    for part in parts:
        if "<title>" not in part:
            continue
        pos = text.find(part[: min(120, len(part))])
        recipe = parse_recipe_block(part, images)
        if not recipe:
            continue
        cat_stage = category_for_pos(pos, markers)
        if cat_stage is None:
            continue
        cat, stage = cat_stage
        key = recipe["title"].lower()
        existing = recipes_by_title.get(key)
        if existing is None or (recipe["image"] and not existing.get("image")):
            recipe["category"] = cat
            recipe["stage"] = stage
            recipes_by_title[key] = recipe

    recipes = sorted(recipes_by_title.values(), key=lambda r: (r["stage"], r["title"]))
    print(f"Parsed {len(recipes)} unique recipes")

    categories = [
        ("meals_stage1", "Подготовительный — блюда дня", 0),
        ("salads_stage1", "Подготовительный — салаты", 0),
        ("meals_stage2", "Основной — меню", 1),
        ("salads_stage2", "Основной — салаты", 1),
        ("soups_stage2", "Основной — супы", 1),
        ("meat_stage2", "Основной — мясные блюда", 1),
        ("fish_stage2", "Основной — рыба и морепродукты", 1),
        ("treats_stage2", "Основной — лакомства", 1),
    ]

    META_JSON.write_text(json.dumps(recipes, ensure_ascii=False, indent=2), encoding="utf-8")

    lines = [
        "// AUTO-GENERATED from docs/Hudeem-interesno-Recepty.fb2",
        "// ignore_for_file: lines_longer_than_80_chars",
        "",
        "class FunRecipe {",
        "  final String id;",
        "  final String title;",
        "  final String categoryId;",
        "  final int stageIndex;",
        "  final String? imageAsset;",
        "  final List<String> ingredients;",
        "  final List<String> steps;",
        "",
        "  const FunRecipe({",
        "    required this.id,",
        "    required this.title,",
        "    required this.categoryId,",
        "    required this.stageIndex,",
        "    this.imageAsset,",
        "    required this.ingredients,",
        "    required this.steps,",
        "  });",
        "}",
        "",
        "class FunRecipeCategory {",
        "  final String id;",
        "  final String title;",
        "  final int stageIndex;",
        "",
        "  const FunRecipeCategory({",
        "    required this.id,",
        "    required this.title,",
        "    required this.stageIndex,",
        "  });",
        "}",
        "",
        "class FunRecipesData {",
        "  FunRecipesData._();",
        "",
        "  static const categories = [",
    ]
    for cid, ctitle, sidx in categories:
        lines.append(
            f"    FunRecipeCategory(id: '{cid}', title: '{dart_escape(ctitle)}', stageIndex: {sidx}),"
        )
    lines.append("  ];")
    lines.append("")
    lines.append("  static const recipes = [")

    for i, r in enumerate(recipes):
        ings = ", ".join(f"'{dart_escape(x)}'" for x in r["ingredients"])
        steps = ", ".join(f"'{dart_escape(x)}'" for x in r["steps"])
        img = f"'{r['image']}'" if r.get("image") else "null"
        lines.append(
            f"    FunRecipe(id: 'r{i}', title: '{dart_escape(r['title'])}', "
            f"categoryId: '{r['category']}', stageIndex: {r['stage']}, "
            f"imageAsset: {img}, ingredients: [{ings}], steps: [{steps}]),"
        )

    lines.extend([
        "  ];",
        "",
        "  static List<FunRecipe> forCategory(String categoryId) =>",
        "      recipes.where((r) => r.categoryId == categoryId).toList();",
        "",
        "  static FunRecipe? byId(String id) {",
        "    for (final r in recipes) {",
        "      if (r.id == id) return r;",
        "    }",
        "    return null;",
        "  }",
        "}",
    ])

    OUT_DART.parent.mkdir(parents=True, exist_ok=True)
    OUT_DART.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_DART}")


if __name__ == "__main__":
    main()
