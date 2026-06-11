import os
import re

mixed_word = re.compile(
    r"[а-яёА-ЯЁ]+[a-zA-Z][а-яёА-ЯЁ]*|[a-zA-Z]+[а-яёА-ЯЁ][a-zA-Zа-яёА-ЯЁ]*"
)
string_re = re.compile(r"'([^'\\]|\\.)*'")

allow = {
    "L-карнитин",
    "L",
    "RuStore",
    "com.mydiet.mysoft",
    "AppMetrica",
    "T-Банк",
}

for root, _, files in os.walk("lib"):
    for name in files:
        if not name.endswith(".dart"):
            continue
        path = os.path.join(root, name)
        with open(path, encoding="utf-8") as fh:
            for i, line in enumerate(fh, 1):
                if "import " in line or line.strip().startswith("//"):
                    continue
                for m in string_re.finditer(line):
                    s = m.group(0)[1:-1]
                    if len(s) < 3:
                        continue
                    for word in re.findall(r"[\w«»/\-–—]+", s, re.UNICODE):
                        if word in allow:
                            continue
                        if not mixed_word.search(word):
                            continue
                        print(f"{path}:{i}: {word!r}")
