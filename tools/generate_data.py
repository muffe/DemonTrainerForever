#!/usr/bin/env python3
"""Generate Data.lua from the WoW Forever client data on wago.tools.

Usage: python3 tools/generate_data.py [build]
Without a build, the latest WoW Forever build (product "wowf") is used.
"""
import csv
import io
import json
import re
import sys
import urllib.request
from pathlib import Path

PRODUCT = "wowf"
LEARN_SPELL_EFFECTS = {"36", "57"}
# Pet skill lines; Succubus and Incubus share one ("Sayaad").
SKILL_LINES = {"188": "Imp", "204": "Voidwalker", "205": "Sayaad", "189": "Felhunter"}
FAMILY_ORDER = ["Imp", "Voidwalker", "Sayaad", "Felhunter"]
OUT = Path(__file__).resolve().parent.parent / "Data.lua"


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "DemonTrainer-data-generator"})
    with urllib.request.urlopen(request) as response:
        return response.read().decode("utf-8")


def table(name, build):
    text = fetch(f"https://wago.tools/db2/{name}/csv?build={build}")
    return list(csv.DictReader(io.StringIO(text)))


def latest_build():
    builds = json.loads(fetch("https://wago.tools/api/builds"))
    return builds[PRODUCT][0]["version"]


def main():
    build = sys.argv[1] if len(sys.argv) > 1 else latest_build()
    print(f"Using build {build}", file=sys.stderr)

    pet_spells = {}
    for row in table("SkillLineAbility", build):
        family = SKILL_LINES.get(row["SkillLine"])
        if family:
            pet_spells[row["Spell"]] = family

    names = {row["ID"]: row["Name_lang"] for row in table("SpellName", build)}

    taught_by_spell = {}
    for row in table("SpellEffect", build):
        if row["Effect"] in LEARN_SPELL_EFFECTS and row["EffectTriggerSpell"] in pet_spells:
            taught_by_spell[row["SpellID"]] = row["EffectTriggerSpell"]

    use_spell_by_effect = {row["ID"]: row["SpellID"] for row in table("ItemEffect", build)}
    taught_by_item = {}
    for row in table("ItemXItemEffect", build):
        taught = taught_by_spell.get(use_spell_by_effect.get(row["ItemEffectID"]))
        if taught:
            taught_by_item[row["ItemID"]] = taught

    grimoires = []
    for row in table("ItemSparse", build):
        taught = taught_by_item.get(row["ID"])
        if not taught:
            continue
        ability = re.sub(r"[^A-Za-z]", "", names[taught].title())
        grimoires.append((int(row["RequiredLevel"]), int(row["ID"]), int(taught),
                          int(row["BuyPrice"]), pet_spells[taught], ability))

    if not grimoires:
        sys.exit("No grimoires found, the table layout probably changed.")

    grimoires.sort(key=lambda g: (g[0], FAMILY_ORDER.index(g[4]), g[1]))
    lines = "\n".join(f'    {{ {g[0]}, {g[1]}, {g[2]}, {g[3]}, "{g[4]}", "{g[5]}" }},' for g in grimoires)
    template = OUT.read_text(encoding="utf-8")
    pattern = re.compile(r"(-- @generated build ).*?\n(local RAW = \{\n).*?(\n\})", re.S)
    if not pattern.search(template):
        sys.exit("Could not find the generated block in Data.lua.")
    OUT.write_text(pattern.sub(lambda m: f"{m.group(1)}{build}\n{m.group(2)}{lines}{m.group(3)}", template, count=1),
                   encoding="utf-8")
    print(f"Wrote {len(grimoires)} grimoires to {OUT}", file=sys.stderr)


if __name__ == "__main__":
    main()
