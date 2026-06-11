#!/usr/bin/env python3
"""Extract gourmet recipes + images from FB2 into Flutter assets."""
import base64
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FB2 = ROOT / "docs" / "Dieta-dlya-gurmanov-Plan-pitaniya.fb2"
IMG_DIR = ROOT / "assets" / "gourmet" / "recipes"
META_JSON = ROOT / "tools" / "gourmet_recipes.json"
OUT_DART = ROOT / "lib" / "data" / "gourmet" / "gourmet_recipes_data.dart"


def clean_text(s: str) -> str:
    s = re.sub(r"<[^>]+>", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def dart_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


def extract_images(text: str) -> dict[str, str]:
    """Extract binary blobs → save jpg, return id → asset path."""
    IMG_DIR.mkdir(parents=True, exist_ok=True)
    mapping = {}
    for m in re.finditer(
        r'<binary id="([^"]+)" content-type="([^"]+)">([^<]+(?:\s[^<]+)*)</binary>',
        text,
        re.S,
    ):
        img_id, _, b64 = m.group(1), m.group(2), m.group(3)
        b64 = re.sub(r"\s+", "", b64)
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
        mapping[f"#{img_id}"] = f"assets/gourmet/recipes/{safe}"
        mapping[img_id] = f"assets/gourmet/recipes/{safe}"
    return mapping


def parse_recipe_block(block: str, images: dict[str, str]) -> dict | None:
    title_m = re.search(r"<subtitle><strong>([^<]+)</strong></subtitle>", block)
    if not title_m:
        return None
    title = clean_text(title_m.group(1))
    if not title or title.startswith("ЭТО ИНТЕРЕСНО"):
        return None

    img_m = re.search(r'<image l:href="#([^"]+)"', block)
    image_asset = None
    if img_m:
        ref = img_m.group(1)
        image_asset = images.get(ref) or images.get(f"#{ref}")

    ingredients = []
    steps = []
    skip_words = (
        "подъем", "гуляем", "тренировк", "методик", "день на",
        "рецепты салатов", "это интересно", "p.s.", "на обед",
        "на ужин", "завтрак", "итого:",
    )
    for p in re.findall(r"<p>(.*?)</p>", block, re.S):
        raw = p.strip()
        if not raw:
            continue
        if "<cite>" in raw:
            continue

        plain = clean_text(re.sub(r"</?emphasis>", "", raw))

        if re.search(r"^\s*•", plain) or (
            "–" in plain[:50] and len(plain) < 120
            and not plain.lower().startswith("итого")
        ):
            if not plain.lower().startswith("итого"):
                ingredients.append(plain.lstrip("• ").strip())
            continue

        if "<strong>Итого" in raw or "<strong>ИТОГО" in raw:
            break

        low = plain.lower()
        if any(w in low for w in skip_words):
            continue
        if len(plain) < 12:
            continue
        if re.match(r"^[679]\.", plain):
            continue
        steps.append(plain)

    if not ingredients and not steps:
        return None

    return {
        "title": title,
        "image": image_asset,
        "ingredients": ingredients[:20],
        "steps": steps[:12],
    }


def stage_for_pos(pos: int, s2: int, s3: int | None) -> int:
    if pos < s2:
        return 0
    if s3 and pos >= s3:
        return 2
    return 1


def is_prep_salad_title(title: str) -> bool:
    """Salad recipes for stage 1 — by title, not only FB2 appendix position."""
    t = title.lower().strip()
    if "на подушке из листьев салата" in t:
        return False
    if "гарниром из листового салата" in t:
        return False
    if t.startswith("салат ") or "салат «" in t:
        return True
    if "салатик" in t:
        return True
    salad_markers = (
        "греческий салат",
        "кранч-салат",
        "красивый салат",
        "легкий весенний салат",
        "легкий салат",
        "орехово-яблочный салат",
        "остренький салат",
        "острый салат",
        "острый творожный салат",
        "шопский салат",
    )
    return any(m in t for m in salad_markers)


def category_for_recipe(stage: int, pos: int, salad_sec: int, s2: int, title: str) -> str:
    if stage == 0 and (
        (salad_sec != -1 and salad_sec <= pos < s2)
        or is_prep_salad_title(title)
    ):
        return "salads_stage1"
    if stage == 0:
        return "stage1"
    if stage == 1:
        return "stage2"
    return "stage3"


def main():
    text = FB2.read_text(encoding="utf-8")
    images = extract_images(text)
    print(f"Extracted {len(images)} images")

    s1 = text.find("1\u00a0этап. Подготовка")
    s2 = text.find("2\u00a0этап. Стабильное")
    salad_sec = text.find("Рецепты салатов для первого этапа")

    # Split by subtitles
    parts = re.split(r"(?=<subtitle><strong>)", text)
    recipes_by_title: dict[str, dict] = {}

    for part in parts:
        if "<subtitle><strong>" not in part:
            continue
        pos = text.find(part[:80])
        recipe = parse_recipe_block(part, images)
        if not recipe:
            continue

        stage = stage_for_pos(pos, s2, None)
        category = category_for_recipe(stage, pos, salad_sec, s2, recipe["title"])

        key = recipe["title"].lower()
        existing = recipes_by_title.get(key)
        # Prefer: image > salads_stage1 for prep salads > other
        def score(r: dict) -> tuple:
            cat_bonus = 1 if r.get("category") == "salads_stage1" else 0
            if is_prep_salad_title(r["title"]) and stage == 0:
                cat_bonus = 2 if r.get("category") == "salads_stage1" else 0
            return (1 if r.get("image") else 0, cat_bonus, len(r.get("ingredients", [])))

        if existing is None or score(recipe) > score(existing):
            recipe["category"] = category
            recipe["stage"] = stage
            recipes_by_title[key] = recipe

    recipes = sorted(recipes_by_title.values(), key=lambda r: r["title"])
    print(f"Parsed {len(recipes)} unique recipes")

    categories = [
        ("stage1", "Подготовительный — основные блюда", 0),
        ("salads_stage1", "Подготовительный — салаты", 0),
        ("stage2", "Основной — блюда", 1),
    ]

    META_JSON.write_text(json.dumps(recipes, ensure_ascii=False, indent=2), encoding="utf-8")

    lines = [
        "// AUTO-GENERATED from docs/Dieta-dlya-gurmanov-Plan-pitaniya.fb2",
        "// ignore_for_file: lines_longer_than_80_chars",
        "",
        "class GourmetRecipe {",
        "  final String id;",
        "  final String title;",
        "  final String categoryId;",
        "  final int stageIndex;",
        "  final String? imageAsset;",
        "  final List<String> ingredients;",
        "  final List<String> steps;",
        "",
        "  const GourmetRecipe({",
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
        "class GourmetRecipeCategory {",
        "  final String id;",
        "  final String title;",
        "  final int stageIndex;",
        "",
        "  const GourmetRecipeCategory({",
        "    required this.id,",
        "    required this.title,",
        "    required this.stageIndex,",
        "  });",
        "}",
        "",
        "class GourmetRecipesData {",
        "  GourmetRecipesData._();",
        "",
        "  static const categories = [",
    ]
    for cid, ctitle, sidx in categories:
        lines.append(
            f"    GourmetRecipeCategory(id: '{cid}', title: '{dart_escape(ctitle)}', stageIndex: {sidx}),"
        )
    lines.append("  ];")
    lines.append("")
    lines.append("  static const recipes = [")

    for i, r in enumerate(recipes):
        ings = ", ".join(f"'{dart_escape(x)}'" for x in r["ingredients"])
        steps = ", ".join(f"'{dart_escape(x)}'" for x in r["steps"])
        img = f"'{r['image']}'" if r.get("image") else "null"
        rid = f"r{i}"
        lines.append(
            f"    GourmetRecipe(id: '{rid}', title: '{dart_escape(r['title'])}', "
            f"categoryId: '{r['category']}', stageIndex: {r['stage']}, "
            f"imageAsset: {img}, ingredients: [{ings}], steps: [{steps}]),"
        )

    lines.append("  ];")
    lines.append("")
    lines.append("  static List<GourmetRecipe> forCategory(String categoryId) =>")
    lines.append("      recipes.where((r) => r.categoryId == categoryId).toList();")
    lines.append("")
    lines.append("  static GourmetRecipe? byId(String id) {")
    lines.append("    for (final r in recipes) {")
    lines.append("      if (r.id == id) return r;")
    lines.append("    }")
    lines.append("    return null;")
    lines.append("  }")
    lines.append("}")

    OUT_DART.parent.mkdir(parents=True, exist_ok=True)
    OUT_DART.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_DART}")


if __name__ == "__main__":
    main()
