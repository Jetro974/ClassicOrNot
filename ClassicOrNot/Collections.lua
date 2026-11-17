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

-- Beside the icon, level with its top edge (the button is its icon, its frame
-- 3 wider each side): above the name, which is centred on the icon. The same
-- place for every toy, whatever its name's length.
local BesideIcon = ns.Anchor("TOPLEFT", "TOPRIGHT", 4, 3)
local function MarkToyButton(button)
    MarkToy(toyMarks, button, true, button.itemID, BesideIcon, button)
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

-------------------------------------------------------------------------------
--  Filters (Core.lua, ns.Filter). Mount, pet and appearance rows only show,
--  summon and preview, nothing protected. The toy box gets none: its buttons
--  use toys, a protected action.
-------------------------------------------------------------------------------
-- A journal list without the rows keep refuses, as one new data provider
-- (rows taken out one by one would lay the list out again for each).
local function DropRows(box, keep, field)
    local rows = {}
    for _, elementData in box:GetDataProvider():EnumerateEntireRange() do
        if keep(elementData[field]) then rows[#rows + 1] = elementData end
    end
    box:SetDataProvider(CreateDataProvider(rows), ScrollBoxConstants.RetainScrollPosition)
end

-- Both journals rebuild their whole list in one global function, by name.
ns.Filter({
    key = "mountsFilter",
    addon = JOURNAL,
    original = ns.ORIGINAL_MOUNTS,
    view = "mountsView",
    menu = function(add)
        Menu.ModifyMenu("MENU_MOUNT_COLLECTION_FILTER", function(_, root) add(root) end)
    end,
    hook = function(after) hooksecurefunc("MountJournal_UpdateMountList", after) end,
    drop = function(keep) DropRows(MountJournal.ScrollBox, keep, "mountID") end,
    refresh = function()
        if MountJournal:IsVisible() then MountJournal_UpdateMountList() end
    end,
})

ns.Filter({
    key = "petsFilter",
    addon = JOURNAL,
    original = ns.ORIGINAL_PETS,
    view = "petsView",
    menu = function(add)
        Menu.ModifyMenu("MENU_PET_COLLECTION_FILTER", function(_, root) add(root) end)
    end,
    hook = function(after) hooksecurefunc("PetJournal_UpdatePetList", after) end,
    drop = function(keep) DropRows(PetJournal.ScrollBox, keep, "speciesID") end,
    refresh = function()
        if PetJournal:IsVisible() then PetJournal_UpdatePetList() end
    end,
})

-- The appearances: FilterVisuals builds the list the pages show, before it
-- is sorted and paged. Forever's appearance Filter menu has no tag: the hook
-- goes on the method that fills it.
ns.Filter({
    key = "appearancesFilter",
    addon = JOURNAL,
    original = ns.ORIGINAL_APPEARANCES,
    view = "appearancesView",
    menu = function(add)
        hooksecurefunc(WardrobeCollectionFrame, "InitItemsFilterButtonSetupMenu", function(_, _, root) add(root) end)
    end,
    hook = function(after) hooksecurefunc(Items(), "FilterVisuals", after) end,
    drop = function(keep, items)
        -- Illusions are not appearances (see MarkLooks).
        local location = items.transmogLocation
        if not location or location:IsIllusion() then return end
        local list, kept = items.filteredVisualsList, 0
        for i = 1, #list do
            if keep(list[i].visualID) then
                kept = kept + 1
                list[kept] = list[i]
            end
        end
        for i = #list, kept + 1, -1 do list[i] = nil end
    end,
    refresh = function()
        local items = Items()
        if items:IsVisible() then
            items:RefreshVisualsList()
            items:UpdateItems()
        end
    end,
})
