-------------------------------------------------------------------------------
--  Books.lua
--  Forever's library books: each is an item, handed in through a quest of its
--  own (to Garion Wendell in Stormwind or Owen Thadd in Undercity).
--    item   the 40 items whose description ends "addition to any library's
--           collection" in Forever's ItemSparse table (1.60.1.70938,
--           wago.tools); "The Liminal and the Arcane" (220347) is left out:
--           the guides say it is not in the game.
--    quest  the quest the item is the objective of (Wowhead Classic, item
--           pages), each one present in Forever's QuestV2 table (1.60.1.70959).
--    side   nil for both factions; the six books of one faction only as
--           warcraft.wiki.gg's Garion Wendell and Owen Thadd lists say.
--    where  uiMapID, x, y (percent of the zone map), then a second spot for a
--           book found in two places: Method's library book guide, and
--           Warcraft Tavern's for Ataeric, the Luddite's Guide and the
--           Conjurer's Codex.
-------------------------------------------------------------------------------
local _, ns = ...

local A, H = "Alliance", "Horde"

-- { item, quest, side, uiMapID, x, y [, uiMapID, x, y] }
ns.BOOKS = {
    { 203755, 79092, A, 1429, 65.4, 70.1 },  -- Archmage Theocritus' Research Journal (Elwynn Forest)
    { 209845, 78142, nil, 1436, 45.4, 70.5 }, -- Bewitchments and Glamours (Westfall)
    { 208860, 79093, A, 1436, 52.7, 53.8, 1432, 35.6, 48.9 }, -- Rumi of Gnomeregan (Westfall or Loch Modan)
    { 209849, 78147, nil, 1431, 16.7, 28.5 }, -- Crimes Against Anatomy (Duskwood)
    { 209850, 78148, nil, 1432, 77.5, 14.1 }, -- Runes of the Sorcerer-Kings (Loch Modan)
    { 209848, 78146, nil, 1437, 33.6, 47.9 }, -- Goaz Scrolls (Wetlands)
    { 203754, 79091, A, 1455, 75.7, 10.5 },  -- Archmage Antonidas (Ironforge)
    { 208185, 79095, H, 1420, 59.4, 52.3 },  -- The Apothecary's Metaphysical Primer (Tirisfal Glades)
    { 209844, 78127, nil, 1421, 63.5, 63.1 }, -- The Dalaran Digest, Vol. 23 (Silverpine Forest)
    { 210177, 79096, H, 1421, 43.4, 41.2 },  -- Ataeric: On Arcane Curiosities (Silverpine Forest)
    { 209847, 78145, nil, 1413, 56.3, 8.8 },  -- Arcanic Systems Manual (The Barrens)
    { 208800, 79097, nil, 1413, 62.7, 36.3 }, -- Baxtan: On Destructive Magics (The Barrens)
    { 209846, 78143, nil, 1413, 46.0, 36.5 }, -- Secrets of the Dreamers (The Barrens)
    { 209843, 78124, nil, 1439, 59.6, 22.2 }, -- Nar'thalas Almanac, Vol. 74 (Darkshore)
    { 209851, 78149, nil, 1442, 74.4, 85.7 }, -- Fury of the Land (Stonetalon Mountains)
    { 207972, 79094, H, 1454, 38.6, 78.4 },  -- The Lessons of Ta'zo (Orgrimmar)
    { 213165, 79535, nil, 1434, 41.3, 50.9 }, -- Basilisks (Stranglethorn Vale)
    { 215683, 79947, nil, 1441, 34.4, 40.0 }, -- Geomancy: The Stone-Cold Truth (Thousand Needles)
    { 215815, 79948, nil, 1416, 48.4, 57.5 }, -- Defensive Magics 101 (Alterac Mountains)
    { 215822, 79952, nil, 1445, 57.1, 20.8 }, -- RwlRwlRwlRwl! (Dustwallow Marsh)
    { 215816, 79949, nil, 1417, 73.6, 65.2 }, -- A Web of Lies (Arathi Highlands)
    { 215817, 79950, nil, 1443, 55.1, 26.2 }, -- Demons and You (Desolace)
    { 215820, 79951, nil, 1418, 56.7, 39.7 }, -- Mummies (Badlands)
    { 215824, 79953, nil, 1435, 61.0, 22.0 }, -- A Luddite's Guide to Caring for Your Demonic Pet (Swamp of Sorrows)
    { 220345, 81947, nil, 1435, 70.2, 51.9 }, -- Sanguine Sorcery (Swamp of Sorrows)
    { 220350, 81954, nil, 1425, 35.8, 72.5 }, -- Venomous Journeys (The Hinterlands)
    { 220349, 81953, nil, 1428, 31.1, 30.1 }, -- Stonewrought Design (Burning Steppes)
    { 220352, 81955, nil, 1427, 38.1, 49.8 }, -- A Mind of Metal (Searing Gorge)
    { 220348, 81952, nil, 1447, 20.4, 62.3 }, -- Everyday Etiquette (Azshara)
    { 220346, 81949, nil, 1446, 72.6, 47.5 }, -- Legends of the Tidesages (Tanaris)
    { 220353, 81956, nil, 1419, 55.3, 32.2 }, -- Conjurer's Codex (Blasted Lands)
    { 228141, 84402, nil, 1422, 69.18, 72.27 }, -- Necromancy 101 (Western Plaguelands)
    { 228132, 84395, nil, 1422, 38.26, 54.62 }, -- Undead Potatoes (Western Plaguelands)
    { 228135, 84398, nil, 1423, 71.8, 48.2 }, -- A Study of the Light (Eastern Plaguelands)
    { 228138, 84400, nil, 1423, 47.3, 42.3 }, -- The Knight and the Lady (Eastern Plaguelands)
    { 228140, 84401, nil, 1423, 26.6, 14.5 }, -- Scourge (Eastern Plaguelands)
    { 228134, 84397, nil, 1448, 65.1, 3.2 },  -- Northern Kalimdor (Felwood)
    { 228136, 84399, nil, 1452, 60.4, 37.4 }, -- Ka-Boom! (Winterspring)
    { 228133, 84396, nil, 1428, 31.1, 30.1 }, -- Magma or Lava? (Burning Steppes)
}

-- Books handed in that earn a reward (Warcraft Tavern's guide).
ns.BOOK_REWARDS = { 10, 20, 25, 35 }
