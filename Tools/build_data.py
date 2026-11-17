"""Builds the data files of Classic or Not from the game's own tables.

Usage (from the project folder):
    python -I Tools/build_data.py

Downloads the tables it needs from wago.tools (kept in Tools/.cache, not in
git) and writes:
    ClassicOrNot/Data/Items.lua        every item of the original game
    ClassicOrNot/Data/Collections.lua  the original game's mounts, pets and
                                       appearances

"Original game" = the last Classic Era client before Season of Discovery,
1.14.4.51829 (the same base as the recipe list). It has no mount, pet or toy
tables, so a Forever mount or pet is original when its spell is in that
client's spell table, and a toy when its item is in that client's item table.
An appearance (the wardrobe's look, its ItemAppearance ID) is original when an
item of that client wears it (its ItemModifiedAppearance table).
The original game no longer changes, so a new Forever build only matters for
the mount and pet tables (new entries are marked anyway, being absent).

Quests.lua and Recipes.lua come from Mark Non-Classic Quests and Recipes
(EllesmereUI PR 3412, same author); their headers say how they were built.
"""
import csv
import os
import sys
import urllib.request

ORIGINAL = "1.14.4.51829"
FOREVER = "1.60.1.70938"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, "Tools", ".cache")
DATA = os.path.join(ROOT, "ClassicOrNot", "Data")


def table(name, build):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, f"{name}_{build}.csv")
    if not os.path.exists(path):
        url = f"https://wago.tools/db2/{name}/csv?build={build}"
        with urllib.request.urlopen(url, timeout=120) as r:
            body = r.read()
        if body.startswith(b"{"):
            sys.exit(f"{name} {build}: {body[:200]!r}")
        with open(path, "wb") as f:
            f.write(body)
    with open(path, encoding="utf-8") as f:
        return list(csv.DictReader(f))


def ranges(ids):
    out = []
    for x in sorted(set(ids)):
        if out and x == out[-1][1] + 1:
            out[-1][1] = x
        else:
            out.append([x, x])
    return out


def lua_list(name, rs):
    lines, line = [], "   "
    for a, b in rs:
        cell = f" {a},{b},"
        if len(line) + len(cell) > 100:
            lines.append(line)
            line = "   "
        line += cell
    lines.append(line)
    return f"ns.{name} = {{\n" + "\n".join(lines) + "\n}\n"


HEADER = """-------------------------------------------------------------------------------
--  {file}
{text}
--  The original game no longer changes, so neither do these lists. Built by
--  Tools/build_data.py from the game's tables (wago.tools).
-------------------------------------------------------------------------------
local _, ns = ...

"""


def write(file, text, body):
    path = os.path.join(DATA, file)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(HEADER.format(file=file, text=text) + body)
    print("wrote", path)


def main():
    items = [int(r["ID"]) for r in table("Item", ORIGINAL)]
    spells = {int(r["ID"]) for r in table("SpellName", ORIGINAL)}
    mounts = [int(r["ID"]) for r in table("Mount", FOREVER) if int(r["SourceSpellID"]) in spells]
    pets = [int(r["ID"]) for r in table("BattlePetSpecies", FOREVER) if int(r["SummonSpellID"]) in spells]
    looks = [int(r["ItemAppearanceID"]) for r in table("ItemModifiedAppearance", ORIGINAL)]

    ri, rm, rp, rl = ranges(items), ranges(mounts), ranges(pets), ranges(looks)
    write("Items.lua",
          f"--  Every item of the original game, from the Item table of the last Classic\n"
          f"--  Era client before Season of Discovery ({ORIGINAL}), as sorted first,\n"
          f"--  last ID pairs ({len(set(items))} items, {len(ri)} ranges). Toys, mount and pet\n"
          f"--  items and recipes are items too.",
          lua_list("ORIGINAL_ITEMS", ri))
    write("Collections.lua",
          f"--  The original game's mounts and pets, by mount ID and pet species ID: the\n"
          f"--  entries of Forever's Mount and BattlePetSpecies tables ({FOREVER})\n"
          f"--  whose spell is in the spell table of the last Classic Era client before\n"
          f"--  Season of Discovery ({ORIGINAL}), which has no journal tables\n"
          f"--  ({len(mounts)} mounts, {len(rm)} ranges; {len(pets)} pets, {len(rp)} ranges).\n"
          f"--  Then its appearances, by ItemAppearance ID (the wardrobe's visualID):\n"
          f"--  those its items wear in that client's ItemModifiedAppearance table\n"
          f"--  ({len(set(looks))} appearances, {len(rl)} ranges).",
          lua_list("ORIGINAL_MOUNTS", rm) + "\n" + lua_list("ORIGINAL_PETS", rp)
          + "\n" + lua_list("ORIGINAL_APPEARANCES", rl))


main()
