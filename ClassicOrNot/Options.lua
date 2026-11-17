-------------------------------------------------------------------------------
--  Options.lua
--  One page of switches, by section, in the game's options (Options >
--  AddOns). With EllesmereUI installed, the player can also have the page in
--  the EllesmereUI panel, as a plugin (its own section, PLUGINS_API.md);
--  /classicornot and the addon compartment then open that one.
-------------------------------------------------------------------------------
local ADDON, ns = ...
local L = ns.L

-- Each section: its title, its title in capitals (EllesmereUI's headers),
-- then its rows, paired on EllesmereUI's two-column rows (false leaves the
-- second half of a row empty). A row's label is L[key], its tooltip
-- L[key .. "_TIP"].
local SECTIONS = {
    { L.QUESTS, L.QUESTS_UP, "givers", "log", "tracker" },
    { L.PROFESSIONS, L.PROFESSIONS_UP, "window", "trainer" },
    { L.ITEMS, L.ITEMS_UP, "tooltip" },
    { L.COLLECTIONS, L.COLLECTIONS_UP, "missing", false, "mounts", "pets", "appearances", "toys" },
}
-- The game's page alone: where the page shows.
local PANEL = { "EllesmereUI", "", "eui" }

local function HasPlugins()
    return EllesmereUI ~= nil and EllesmereUI.RegisterPlugin ~= nil
end

-- A collection with a filter has one menu for its two places, the mark
-- (key) and the filter (FILTER_OF[key]): mark and filter, mark, filter or
-- none.
local FILTER_OF = { mounts = "mountsFilter", pets = "petsFilter", appearances = "appearancesFilter" }
local SHOWS = { "both", "mark", "filter", "none" }
local SHOW_LABELS = {}
for _, show in ipairs(SHOWS) do SHOW_LABELS[show] = L["SHOW_" .. show] end

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

-- A section's rows shown here (the tracker's only with the tracker).
local function Places(section)
    local keys = {}
    for i = 3, #section do
        if section[i] ~= "tracker" or ns.HasTracker() then keys[#keys + 1] = section[i] end
    end
    return keys
end

-------------------------------------------------------------------------------
--  EllesmereUI plugin page: two rows side by side, as EllesmereUI's own pages
-------------------------------------------------------------------------------
local BLANK = { type = "label", text = "" }

local function Cell(key)
    if not key then return BLANK end
    if FILTER_OF[key] then
        return {
            type = "dropdown", text = L[key], tooltip = L[key .. "_TIP"],
            values = SHOW_LABELS, order = SHOWS,
            getValue = function() return GetShow(key) end,
            setValue = function(show) SetShow(key, show) end,
        }
    end
    return {
        type = "toggle", text = L[key], tooltip = L[key .. "_TIP"],
        getValue = function() return ns.Get(key) end,
        setValue = function(value) ns.Set(key, value) end,
    }
end

local function BuildPluginPage(_, parent, y)
    local W = EllesmereUI.Widgets
    local _, h
    for _, section in ipairs(SECTIONS) do
        _, h = W:SectionHeader(parent, section[2], y); y = y - h
        local keys = Places(section)
        for i = 1, #keys, 2 do
            _, h = W:DualRow(parent, y, Cell(keys[i]), Cell(keys[i + 1])); y = y - h
        end
    end
    return math.abs(y)
end

-- The setting adds the plugin at once (EllesmereUI takes plugins at any
-- time). EllesmereUI cannot remove one: turned off, the section stays until
-- the next reload (offered), and /classicornot opens the game's page again.
local registered = false
ns.Place({
    key = "eui",
    on = function()
        if registered or not HasPlugins() then return end
        registered = EllesmereUI.RegisterPlugin(ADDON, {
            label = L.NAME,
            modules = { {
                key = "General",
                title = L.SUBTITLE,
                description = L.DESCRIPTION,
                pages = { L.GENERAL },
                buildPage = BuildPluginPage,
            } },
        })
    end,
    off = function() if registered then ns.AskReload() end end,
})

-------------------------------------------------------------------------------
--  Game options page (always there)
-------------------------------------------------------------------------------
local category

local function ShowOptions()
    local container = Settings.CreateControlTextContainer()
    for _, show in ipairs(SHOWS) do container:Add(show, SHOW_LABELS[show]) end
    return container:GetData()
end

local function AddSection(layout, section)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(section[1]))
    for _, key in ipairs(Places(section)) do
        if FILTER_OF[key] then
            local setting = Settings.RegisterProxySetting(category, ADDON .. "_" .. key, Settings.VarType.String,
                L[key], ShowOf(ns.DEFAULTS[key], ns.DEFAULTS[FILTER_OF[key]]),
                function() return GetShow(key) end,
                function(show) SetShow(key, show) end)
            Settings.CreateDropdown(category, setting, ShowOptions, L[key .. "_TIP"])
        elseif key then
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
    local layout
    category, layout = Settings.RegisterVerticalLayoutCategory(L.NAME)
    for _, section in ipairs(SECTIONS) do AddSection(layout, section) end
    if HasPlugins() then AddSection(layout, PANEL) end
    Settings.RegisterAddOnCategory(category)
end

function ns.OpenOptions()
    if registered and ns.Get("eui") then
        EllesmereUI.OpenPlugin(ADDON)
    else
        Settings.OpenToCategory(category:GetID())
    end
end

SLASH_CLASSICORNOT1 = "/classicornot"
SlashCmdList.CLASSICORNOT = ns.OpenOptions

-- The addon compartment (the TOC's AddonCompartmentFunc).
function ClassicOrNot_OnAddonCompartmentClick()
    ns.OpenOptions()
end
