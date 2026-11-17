-------------------------------------------------------------------------------
--  Collections.lua
--  New mounts, pets and toys, marked in the collections journal (a
--  load-on-demand Blizzard addon: each place waits for it). Mounts and pets
--  are original when their ID is in the original game's lists
--  (Data/Collections.lua), toys when their item is (Data/Items.lua).
-------------------------------------------------------------------------------
local _, ns = ...

local JOURNAL = "Blizzard_Collections"
-- Top right of a journal row: the row's icons sit on its left and bottom.
local RowCorner = ns.Anchor("TOPRIGHT", "TOPRIGHT", -4, -4)

-------------------------------------------------------------------------------
--  Mount journal: the row's element data holds the mount's ID.
-------------------------------------------------------------------------------
local MarkMount = ns.Marker(ns.ORIGINAL_MOUNTS)
local mountMarks = ns.Store()

ns.List({
    key = "mounts",
    addon = JOURNAL,
    box = function() return MountJournal.ScrollBox end,
    store = mountMarks,
    mark = function(button, elementData)
        MarkMount(mountMarks, button, true, elementData.mountID, RowCorner, button)
    end,
})

-------------------------------------------------------------------------------
--  Pet journal: Blizzard keeps the row's species ID on it when it fills it
--  (read only).
-------------------------------------------------------------------------------
local MarkPet = ns.Marker(ns.ORIGINAL_PETS)
local petMarks = ns.Store()

ns.List({
    key = "pets",
    addon = JOURNAL,
    box = function() return PetJournal.ScrollBox end,
    store = petMarks,
    mark = function(button)
        MarkPet(petMarks, button, true, button.speciesID, RowCorner, button)
    end,
})

-------------------------------------------------------------------------------
--  Toy box: a page of buttons, each redrawn by ToySpellButton_UpdateButton,
--  which keeps the toy's item ID on the button. Read only: the buttons use
--  that ID to use the toy.
-------------------------------------------------------------------------------
local MarkToy = ns.Marker(ns.ORIGINAL_ITEMS)
local toyMarks = ns.Store()
local OnToyIcon = ns.Anchor("TOPRIGHT", "TOPRIGHT", 4, 3)

local toys = ns.Place({ key = "toys", addon = JOURNAL })
local function MarkToyButton(button)
    MarkToy(toyMarks, button, true, button.itemID, OnToyIcon, button)
end

local hooked = false
toys.on = function()
    if not hooked then
        hooked = true
        hooksecurefunc("ToySpellButton_UpdateButton", function(button)
            if toys.state then MarkToyButton(button) end
        end)
    end
    -- The page as it stands (each button hides itself past the last toy).
    local icons = ToyBox.iconsFrame
    local i = 1
    while icons["spellButton" .. i] do
        local button = icons["spellButton" .. i]
        if button:IsShown() then MarkToyButton(button) end
        i = i + 1
    end
end
toys.off = function() ns.HideAll(toyMarks) end
