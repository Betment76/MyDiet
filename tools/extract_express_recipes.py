#!/usr/bin/env python3
"""Extract express diet recipes from FB2 into Flutter assets."""
import base64
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FB2 = ROOT / "docs" / "Minus-razmer-ekspress-dieta.fb2"
IMG_DIR = ROOT / "assets" / "express" / "recipes"
META_JSON = ROOT / "tools" / "express_recipes.json"
OUT_DART = ROOT / "lib" / "data" / "express" / "express_recipes_data.dart"

MENU_START = "15.\xa0Ваше типовое меню"
DAY_TITLE = re.compile(
    r"<title>\s*<p>(День [^<]+|Загрузочный \(разгрузочный\) день[^<]*)</p>\s*</title>"
)
DISH_TITLE_PATTERNS = [
    re.compile(r"<p><emphasis><strong>([^<]+)</strong></emphasis></p>"),
    re.compile(r"<p><strong><emphasis>([^<]+)</emphasis></strong></p>"),
    re.compile(r"<p><strong>([^<]+)</strong></p>"),
    re.compile(r"<p>✓\s*<emphasis>([^<]{4,120})</emphasis></p>"),
]
MEAL_MARKERS = (
    "завтрак",
    "обед",
    "ужин",
    "полдник",
    "перекус",
)
SKIP_TITLES = (
    "кстати",
    "выводы",
    "итого",
    "всего за день",
    "завтрак",
    "обед",
    "ужин",
    "полдник",
)
SKIP_TITLE_PATTERNS = (
    r"^ответ\b",
    r"^относительно\b",
    r"^раньше лосось",
    r"^шпаргалка\b",
    r"^–\s",
    r"^молоко\b",
    r"^яйца –",
    r"^одн[ао]\s",
    r"^половинка\b",
    r"^небольш",
    r"^яблоко средн",
    r"^\d",
)


def clean_text(s: str) -> str:
    s = re.sub(r"<[^>]+>", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def dart_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


def extract_images(text: str) -> dict[str, str]:
    IMG_DIR.mkdir(parents=True, exist_ok=True)
    mapping: dict[str, str] = {}
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
        mapping[f"#{img_id}"] = f"assets/express/recipes/{safe}"
        mapping[img_id] = f"assets/express/recipes/{safe}"
    return mapping


def is_salad_title(title: str) -> bool:
    t = title.lower().strip()
    if "на подушке" in t or "гарниром" in t:
        return False
    if t.startswith("салат") or "салат " in t or "салатик" in t:
        return True
    if "салат из" in t or "теплый салат" in t:
        return True
    return False


def stage_for_day_title(day_title: str) -> int:
    low = day_title.lower()
    if "загрузочный" in low:
        return 2
    m = re.search(r"день\s+(\w+)", low)
    if not m:
        return 1
    word = m.group(1)
    ordinals = {
        "первый": 1,
        "второй": 2,
        "третий": 3,
        "четвертый": 4,
        "четвёртый": 4,
        "пятый": 5,
        "шестой": 6,
        "седьмой": 7,
        "восьмой": 8,
        "девятый": 9,
        "десятый": 10,
    }
    n = ordinals.get(word, 1)
    if n <= 3:
        return 0
    if n <= 8:
        return 1
    return 2


def normalize_title(raw: str) -> str | None:
    title = clean_text(raw)
    if not title or len(title) < 4:
        return None
    low = title.lower()
    if any(low.startswith(s) for s in SKIP_TITLES):
        return None
    if low in MEAL_MARKERS:
        return None
    for pat in SKIP_TITLE_PATTERNS:
        if re.search(pat, low):
            return None
    if title.endswith(".") and "–" in title and len(title) > 60:
        return None
    if len(title) > 90:
        return None
    return title


def looks_like_ingredient(title: str) -> bool:
    if re.search(r"[–—]\s*\d", title):
        return True
    low = title.lower()
    if low.startswith(("соль", "перец", "масло ", "соевый", "сливки", "корень ")):
        return True
    return False


def extract_title_from_block(block: str) -> str | None:
    for pattern in DISH_TITLE_PATTERNS:
        m = pattern.search(block)
        if not m:
            continue
        candidate = normalize_title(m.group(1))
        if candidate and not looks_like_ingredient(candidate):
            return candidate
    return None


def parse_dish_block(block: str, images: dict[str, str]) -> dict | None:
    if "<cite>" in block[:200]:
        return None
    title = extract_title_from_block(block)
    if not title:
        return None

    img_m = re.search(r'<image l:href="#([^"]+)"', block)
    image_asset = None
    if img_m:
        ref = img_m.group(1)
        image_asset = images.get(ref) or images.get(f"#{ref}")

    ingredients: list[str] = []
    steps: list[str] = []
    for p in re.findall(r"<p>(.*?)</p>", block, re.S):
        if "<cite>" in p:
            continue
        plain = clean_text(re.sub(r"</?emphasis>", "", p))
        if not plain:
            continue
        if plain.startswith("✓"):
            ing = plain.lstrip("✓ ").strip()
            if ing and not ing.lower().startswith("итого"):
                ingredients.append(ing)
            continue
        if re.search(r"итого", plain, re.I):
            break
        if "всего за день" in plain.lower():
            break
        if len(plain) < 20:
            continue
        if plain == title:
            continue
        steps.append(plain)

    if len(ingredients) < 1 or not steps:
        return None
    return {
        "title": title,
        "image": image_asset,
        "ingredients": ingredients[:24],
        "steps": steps[:10],
    }


def parse_menu(text: str, images: dict[str, str]) -> list[dict]:
    start = text.find(MENU_START)
    if start == -1:
        raise ValueError("Menu section not found")
    menu = text[start:]
    for end_marker in (
        "<p>Шпаргалка: ключевые моменты диеты</p>",
        "<section>\n   <title>\n    <p>Указатель",
    ):
        end = menu.find(end_marker)
        if end != -1:
            menu = menu[:end]
            break

    parts = DAY_TITLE.split(menu)
    recipes_by_title: dict[str, dict] = {}

    for i in range(1, len(parts), 2):
        day_title = clean_text(parts[i])
        chunk = parts[i + 1] if i + 1 < len(parts) else ""
        stage = stage_for_day_title(day_title)

        sub_parts = re.split(r"(?=<subtitle>)", chunk)
        current = ""
        for part in sub_parts:
            if part.startswith("<subtitle>"):
                if current:
                    _collect_dishes(current, images, stage, recipes_by_title)
                current = part
            else:
                current += part
        if current:
            _collect_dishes(current, images, stage, recipes_by_title)

    return sorted(recipes_by_title.values(), key=lambda r: r["title"])


def _collect_dishes(
    chunk: str,
    images: dict[str, str],
    stage: int,
    recipes_by_title: dict[str, dict],
) -> None:
    if "всего за день" in chunk.lower()[:500] and "✓" not in chunk[:500]:
        return
    blocks = re.split(r"(?=ИТОГО(?:\s+В\s+БЛЮДЕ)?\s*:)", chunk, flags=re.I)
    for block in blocks:
        if "✓" not in block:
            continue
        recipe = parse_dish_block(block, images)
        if not recipe:
            continue
        recipe["stage"] = stage
        key = recipe["title"].lower()
        existing = recipes_by_title.get(key)

        def score(r: dict) -> tuple:
            return (1 if r.get("image") else 0, len(r.get("ingredients", [])))

        if existing is None or score(recipe) > score(existing):
            recipes_by_title[key] = recipe


def main():
    text = FB2.read_text(encoding="utf-8")
    images = extract_images(text)
    print(f"Extracted {len(images)} images")

    recipes = parse_menu(text, images)
    print(f"Parsed {len(recipes)} unique recipes")

    for stage in range(3):
        rs = [r for r in recipes if r["stage"] == stage]
        salads = sum(1 for r in rs if is_salad_title(r["title"]))
        print(f"  stage {stage}: {len(rs)} ({salads} salads)")

    META_JSON.write_text(
        json.dumps(recipes, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    lines = [
        "// AUTO-GENERATED from docs/Minus-razmer-ekspress-dieta.fb2",
        "// ignore_for_file: lines_longer_than_80_chars",
        "",
        "class ExpressRecipe {",
        "  final String id;",
        "  final String title;",
        "  final int stageIndex;",
        "  final String? imageAsset;",
        "  final List<String> ingredients;",
        "  final List<String> steps;",
        "",
        "  const ExpressRecipe({",
        "    required this.id,",
        "    required this.title,",
        "    required this.stageIndex,",
        "    this.imageAsset,",
        "    required this.ingredients,",
        "    required this.steps,",
        "  });",
        "}",
        "",
        "class ExpressRecipesData {",
        "  ExpressRecipesData._();",
        "",
        "  static const recipes = [",
    ]
    for i, r in enumerate(recipes):
        ings = ", ".join(f"'{dart_escape(x)}'" for x in r["ingredients"])
        steps = ", ".join(f"'{dart_escape(x)}'" for x in r["steps"])
        img = f"'{r['image']}'" if r.get("image") else "null"
        lines.append(
            f"    ExpressRecipe(id: 'r{i}', title: '{dart_escape(r['title'])}', "
            f"stageIndex: {r['stage']}, imageAsset: {img}, "
            f"ingredients: [{ings}], steps: [{steps}]),"
        )

    lines.extend(
        [
            "  ];",
            "",
            "  static bool isSalad(ExpressRecipe recipe) =>",
            "      _isSaladTitle(recipe.title);",
            "",
            "  static List<ExpressRecipe> forStageType(",
            "    int stageIndex, {",
            "    required bool salads,",
            "  }) {",
            "    final list = recipes",
            "        .where((r) =>",
            "            r.stageIndex == stageIndex && isSalad(r) == salads)",
            "        .toList()",
            "      ..sort((a, b) => a.title.compareTo(b.title));",
            "    return list;",
            "  }",
            "",
            "  static bool _isSaladTitle(String title) {",
            "    final t = title.toLowerCase().trim();",
            "    if (t.contains('на подушке') || t.contains('гарниром')) {",
            "      return false;",
            "    }",
            "    if (t.startsWith('салат') || t.contains('салат ')) return true;",
            "    if (t.contains('салатик')) return true;",
            "    if (t.contains('салат из') || t.contains('теплый салат')) {",
            "      return true;",
            "    }",
            "    return false;",
            "  }",
            "",
            "  static ExpressRecipe? byId(String id) {",
            "    for (final r in recipes) {",
            "      if (r.id == id) return r;",
            "    }",
            "    return null;",
            "  }",
            "}",
            "",
        ]
    )

    OUT_DART.parent.mkdir(parents=True, exist_ok=True)
    OUT_DART.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT_DART}")


if __name__ == "__main__":
    main()
