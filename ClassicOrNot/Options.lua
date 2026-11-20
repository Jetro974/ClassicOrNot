-------------------------------------------------------------------------------
--  Options.lua
--  One page of switches, by section, in the game's options (Options >
--  AddOns), opened by /classicornot and the addon compartment.
--
--  The addon is one of the "... or Not" family. With another of them
--  installed, the game's options get a single entry, "Or Not", holding a
--  page for each; alone, the page is the addon's own entry.
-------------------------------------------------------------------------------
local ADDON, ns = ...
local L = ns.L

-- The family's shared table: each of its addons counts itself here when it
-- loads, and the pages are built at login, when the count is final.
local SUITE = "Or Not"
OrNotFamily = OrNotFamily or { count = 0, built = 0 }
OrNotFamily[ADDON] = true
OrNotFamily.count = OrNotFamily.count + 1

-- Each section: its title, then its rows. A row's label is L[key], its
-- tooltip L[key .. "_TIP"].
local SECTIONS = {
    { L.QUESTS, "givers", "log" },
    { L.PROFESSIONS, "window", "trainer" },
    { L.ITEMS, "tooltip", "merchant" },
    { L.COLLECTIONS, "missing", "mounts", "pets", "appearances", "toys" },
}

-- A collection with a filter has one menu for its two places, the mark
-- (key) and the filter (FILTER_OF[key]): mark and filter, mark, filter or
-- none.
local FILTER_OF = { mounts = "mountsFilter", pets = "petsFilter", appearances = "appearancesFilter" }
local SHOWS = { "both", "mark", "filter", "none" }

local function ShowOf(mark, filter)
    if mark then return filter and "both" or "mark" end
    return filter and "filter" or "none"
end

local function GetShow(key)
    return ShowOf(ns.Get(key), ns.Get(FILTER_OF[key]))
end

local function SetShow(key, show)
    ClassicOrNotDB[key] = show == "both" or show == "mark"
    ClassicOrNotDB[FILTER_OF[key]] = show == "both" or show == "filter"
    ns.ApplyAll()
end

local function ShowOptions()
    local container = Settings.CreateControlTextContainer()
    for _, show in ipairs(SHOWS) do container:Add(show, L["SHOW_" .. show]) end
    return container:GetData()
end

local category

local function AddSection(layout, section)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(section[1]))
    for i = 2, #section do
        local key = section[i]
        if FILTER_OF[key] then
            local setting = Settings.RegisterProxySetting(category, ADDON .. "_" .. key, Settings.VarType.String,
                L[key], ShowOf(ns.DEFAULTS[key], ns.DEFAULTS[FILTER_OF[key]]),
                function() return GetShow(key) end,
                function(show) SetShow(key, show) end)
            Settings.CreateDropdown(category, setting, ShowOptions, L[key .. "_TIP"])
        else
            local setting = Settings.RegisterProxySetting(category, ADDON .. "_" .. key, Settings.VarType.Boolean,
                L[key], ns.DEFAULTS[key] and Settings.Default.True or Settings.Default.False,
                function() return ns.Get(key) end,
                function(value) ns.Set(key, value) end)
            Settings.CreateCheckbox(category, setting, L[key .. "_TIP"])
        end
    end
end

-- At login (Core.lua), before the places apply.
function ns.BuildOptions()
    local family, layout = OrNotFamily, nil
    local grouped = family.count > 1
    if grouped then
        if not family.category then
            family.category, family.layout = Settings.RegisterVerticalLayoutCategory(SUITE)
        end
        category, layout = Settings.RegisterVerticalLayoutSubcategory(family.category, L.NAME)
    else
        category, layout = Settings.RegisterVerticalLayoutCategory(L.NAME)
    end
    for _, section in ipairs(SECTIONS) do AddSection(layout, section) end
    if grouped then
        -- The entry's own page: a line for each addon, with a button to its page.
        family.layout:AddInitializer(CreateSettingsButtonInitializer(L.NAME, L.OPEN, ns.OpenOptions,
            C_AddOns.GetAddOnMetadata(ADDON, "Notes"), false))
        -- Registered once every page is in: the game reads an entry's pages
        -- when the entry is registered.
        family.built = family.built + 1
        if family.built == family.count then Settings.RegisterAddOnCategory(family.category) end
    else
        Settings.RegisterAddOnCategory(category)
    end
end

function ns.OpenOptions()
    Settings.OpenToCategory(category:GetID())
end

SLASH_CLASSICORNOT1 = "/classicornot"
SlashCmdList.CLASSICORNOT = ns.OpenOptions

-- The addon compartment (the TOC's AddonCompartmentFunc).
function ClassicOrNot_OnAddonCompartmentClick()
    ns.OpenOptions()
end
