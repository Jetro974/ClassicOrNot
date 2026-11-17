-------------------------------------------------------------------------------
--  Collections.lua
--  New mounts, pets, toys and appearances, marked in the collections journal
--  (a load-on-demand Blizzard addon: each place waits for it). Mounts, pets
--  and appearances are original when their ID is in the original game's
--  lists (Data/Collections.lua), toys when their item is (Data/Items.lua).
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

-- On the icon's top right corner (the button is its icon; the favourite star
-- and "NEW" sit on the left): the same place for every toy, whatever its
-- name's length.
local function MarkToyButton(button)
    MarkToy(toyMarks, button, true, button.itemID, ns.OnIcon, button)
end

ns.Page({
    key = "toys",
    addon = JOURNAL,
    store = toyMarks,
    hook = function(redrawn) hooksecurefunc("ToySpellButton_UpdateButton", redrawn) end,
    mark = MarkToyButton,
    -- The page as it stands (each button hides itself past the last toy).
    now = function()
        local icons = ToyBox.iconsFrame
        local i = 1
        while icons["spellButton" .. i] do
            local button = icons["spellButton" .. i]
            if button:IsShown() then MarkToyButton(button) end
            i = i + 1
        end
    end,
})

-------------------------------------------------------------------------------
--  Appearances (the wardrobe): a page of models, all redrawn by the items
--  frame's UpdateItems, which keeps each model's appearance on it (read
--  only). The mixin's methods are copied into the frame when it is made: the
--  hook goes on the frame itself.
-------------------------------------------------------------------------------
local MarkLook = ns.Marker(ns.ORIGINAL_APPEARANCES)
local lookMarks = ns.Store()

local function MarkLooks(items)
    -- The same models show weapon illusions, whose IDs are enchant visuals,
    -- not appearances: not marked. No slot is chosen before the first show.
    local location = items.transmogLocation
    local looks = location and not location:IsIllusion()
    for _, model in ipairs(items.Models) do
        local info = model.visualInfo
        -- "Hide this slot" is shown as an appearance with an ID of its own,
        -- never worn by an item: not marked.
        local id = looks and info and not info.isHideVisual and info.visualID
        MarkLook(lookMarks, model, true, id, RowCorner, model)
    end
end

local function Items()
    return WardrobeCollectionFrame.ItemsCollectionFrame
end

ns.Page({
    key = "appearances",
    addon = JOURNAL,
    store = lookMarks,
    hook = function(redrawn) hooksecurefunc(Items(), "UpdateItems", redrawn) end,
    mark = MarkLooks,
    now = function() MarkLooks(Items()) end,
})
