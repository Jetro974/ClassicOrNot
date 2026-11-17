-------------------------------------------------------------------------------
--  Collections.lua
--  The original game's mounts and pets, by mount ID and pet species ID: the
--  entries of Forever's Mount and BattlePetSpecies tables (1.60.1.70938)
--  whose spell is in the spell table of the last Classic Era client before
--  Season of Discovery (1.14.4.51829), which has no journal tables
--  (98 mounts, 13 ranges; 71 pets, 29 ranges).
--  The original game no longer changes, so neither do these lists. Built by
--  Tools/build_data.py from the game's tables (wago.tools).
-------------------------------------------------------------------------------
local _, ns = ...

ns.ORIGINAL_MOUNTS = {
    6,9, 11,15, 17,22, 24,28, 31,32, 34,36, 38,43, 45,46, 50,58, 62,85, 87,111, 116,121, 125,125,
}

ns.ORIGINAL_PETS = {
    39,47, 49,52, 55,59, 64,65, 67,70, 72,72, 74,75, 77,78, 83,83, 85,87, 89,90, 92,95, 106,107,
    111,111, 114,114, 116,122, 124,128, 130,130, 757,758, 1073,1073, 1168,1168, 1563,1563,
    1927,1927, 4172,4172, 4180,4180, 4182,4185, 5004,5004, 5006,5006, 5158,5158,
}
