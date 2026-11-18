-- Offline checks of the lists and the original-game test.
-- Usage: lua5.1 Tests/test_data.lua   (from the project folder)
local ns = {}
local function load(file)
    local chunk = assert(loadfile("ClassicOrNot/" .. file))
    chunk("ClassicOrNot", ns)
end

-- Core.lua needs a few game globals at load time.
ScrollBoxListMixin = { Event = { OnInitializedFrame = "OnInitializedFrame" } }
CreateFrame = function()
    return { RegisterEvent = function() end, SetScript = function() end }
end
issecretvalue = function() return false end

load("Core.lua")
for _, file in ipairs({ "Quests", "Recipes", "Items", "Collections" }) do
    load("Data/" .. file .. ".lua")
end

local failures = 0
local function check(ok, what)
    if not ok then
        failures = failures + 1
        print("FAIL: " .. what)
    end
end

-- Every list: pairs, sorted, first <= last, no overlap.
for _, name in ipairs({ "ORIGINAL_QUESTS", "ORIGINAL_RECIPES", "ORIGINAL_ITEMS", "ORIGINAL_MOUNTS", "ORIGINAL_PETS", "ORIGINAL_APPEARANCES" }) do
    local list = ns[name]
    check(type(list) == "table" and #list > 0 and #list % 2 == 0, name .. " is a list of pairs")
    for i = 1, #list, 2 do
        check(list[i] <= list[i + 1], name .. " pair " .. i .. " is first <= last")
        if i > 1 then check(list[i] > list[i - 1] + 1, name .. " pair " .. i .. " is after the previous one") end
    end
end

-- Known answers (Tools/build_data.py, wago.tools tables).
local cases = {
    { "ORIGINAL_QUESTS", 1, false }, { "ORIGINAL_QUESTS", 3, true },
    { "ORIGINAL_MOUNTS", 6, false }, { "ORIGINAL_MOUNTS", 125, false }, -- Brown Horse, Riding Turtle
    { "ORIGINAL_MOUNTS", 311, true }, { "ORIGINAL_MOUNTS", 2952, true }, -- Venomhide Ravasaur, a Galestrider
    { "ORIGINAL_PETS", 39, false }, { "ORIGINAL_PETS", 5158, false }, -- Mechanical Squirrel, Eagle Owl
    { "ORIGINAL_PETS", 162, true }, { "ORIGINAL_PETS", 5159, true }, -- Sinister Squashling, the new Panda
    { "ORIGINAL_ITEMS", 17716, false }, { "ORIGINAL_ITEMS", 18660, false }, -- Snowmaster 9000, World Enlarger
    { "ORIGINAL_ITEMS", 269900, true }, { "ORIGINAL_ITEMS", 288185, true }, -- Centaur Banner, Adventurer's Tent
    { "ORIGINAL_APPEARANCES", 57187, false }, { "ORIGINAL_APPEARANCES", 68530, false }, -- items 2101, Thunderfury 19019
    { "ORIGINAL_APPEARANCES", 8829, true }, -- item 34085, not in the original game
}
for _, c in ipairs(cases) do
    check(ns.IsNew(ns[c[1]], c[2]) == c[3], c[1] .. " " .. c[2] .. (c[3] and " is new" or " is original"))
end
-- Library books: one item and one quest each, 36 for each faction.
load("Data/Books.lua")
local items, quests, sides = {}, {}, { Alliance = 0, Horde = 0 }
for i, book in ipairs(ns.BOOKS) do
    check(not items[book[1]], "book " .. i .. " has an item of its own")
    check(not quests[book[2]], "book " .. i .. " has a quest of its own")
    items[book[1]], quests[book[2]] = true, true
    check(book[3] == nil or sides[book[3]] ~= nil, "book " .. i .. " is for both factions or one")
    for side in pairs(sides) do
        if book[3] == nil or book[3] == side then sides[side] = sides[side] + 1 end
    end
    for s = 4, #book, 3 do
        check(type(book[s]) == "number" and book[s + 1] > 0 and book[s + 1] < 100 and book[s + 2] > 0 and book[s + 2] < 100,
            "book " .. i .. " has a map and coordinates")
    end
    check(#book == 6 or #book == 9, "book " .. i .. " has one or two spots")
end
check(#ns.BOOKS == 39, "39 books")
check(sides.Alliance == 36 and sides.Horde == 36, "36 books for each faction")

check(not ns.IsNew(ns.ORIGINAL_ITEMS, nil), "no ID is not new")
check(not ns.IsNew(ns.ORIGINAL_ITEMS, 0), "ID 0 is not new")

if failures > 0 then
    print(failures .. " failure(s)")
    os.exit(1)
end
print("test_data: OK")
