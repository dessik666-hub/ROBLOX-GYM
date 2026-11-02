"""Exports src/shared/Strings.lua to localization/NeonGym.csv for Roblox.

Upload the CSV in Creator Hub -> your experience -> Localization -> Upload CSV.
Automatic translation then fills every other language from the English Source.
Usage: python tools/export_localization.py
"""
import csv
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
LUA = (ROOT / "src/shared/Strings.lua").read_text(encoding="utf-8")


def table(name):
    body = LUA.split(f"Strings.{name} = {{", 1)[1].split("\n}", 1)[0]
    return dict(re.findall(r'\["(.*?)"\] = "(.*)",', body))


en, ru = table("en"), table("ru")

# Texts on signs and boards in the world. They have no key: Roblox matches them
# by their English text and translates them automatically.
WORLD = [
    ("GYM →", "ТРЕНАЖЁРНЫЙ ЗАЛ →"),
    ("← PODIUM", "← ПОДИУМ"),
    ("CARDIO", "КАРДИО"),
    ("STRENGTH", "СИЛОВАЯ ЗОНА"),
    ("TITAN", "ТИТАН"),
    ("VIP · SOON", "VIP · СКОРО"),
    ("🏆 TOP BY STRENGTH", "🏆 ТОП ПО СИЛЕ"),
    ("🌟 ON STAGE NOW", "🌟 СЕЙЧАС НА ПОДИУМЕ"),
]

out = ROOT / "localization/NeonGym.csv"
out.parent.mkdir(exist_ok=True)
with out.open("w", encoding="utf-8", newline="") as f:
    w = csv.writer(f)
    w.writerow(["Key", "Source", "Context", "Example", "ru"])
    for key, source in en.items():
        w.writerow([key, source, "", "", ru.get(key, "")])
    for source, translated in WORLD:
        w.writerow(["", source, "", "", translated])
print(f"{len(en)} keys + {len(WORLD)} world texts -> {out.relative_to(ROOT)}")
