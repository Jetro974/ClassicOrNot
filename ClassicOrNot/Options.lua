-------------------------------------------------------------------------------
--  Options.lua
--  One page of switches, one per place. With EllesmereUI installed the page is
--  an EllesmereUI plugin (its own section in the EllesmereUI panel,
--  PLUGINS_API.md); without it, a page in the game's options (Options >
--  AddOns). /classicornot and the addon compartment open whichever it is.
-------------------------------------------------------------------------------
local ADDON, ns = ...
local L = ns.L

-- Each section: its title, its title in capitals (EllesmereUI's headers),
-- then its places, paired on EllesmereUI's two-column rows. A place's label
-- is L[key], its tooltip L[key .. "_TIP"].
local SECTIONS = {
    { L.QUESTS, L.QUESTS_UP, "givers", "log", "tracker" },
    { L.RECIPES, L.RECIPES_UP, "window", "trainer" },
    { L.ITEMS, L.ITEMS_UP, "tooltip", "toys", "mounts", "pets" },
}

-- A section's places shown here (the tracker's only with the tracker).
local function Places(section)
    local keys = {}
    for i = 3, #section do
        if section[i] ~= "tracker" or ns.HasTracker() then keys[#keys + 1] = section[i] end
    end
    return keys
end

-------------------------------------------------------------------------------
--  EllesmereUI plugin page: two places per row, as EllesmereUI's own pages
-------------------------------------------------------------------------------
local BLANK = { type = "label", text = "" }

local function Toggle(key)
    if not key then return BLANK end
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
            _, h = W:DualRow(parent, y, Toggle(keys[i]), Toggle(keys[i + 1])); y = y - h
        end
    end
    return math.abs(y)
end

-------------------------------------------------------------------------------
--  Game options page
-------------------------------------------------------------------------------
local category

local function BuildSettingsPage()
    local layout
    category, layout = Settings.RegisterVerticalLayoutCategory(L.NAME)
    for _, section in ipairs(SECTIONS) do
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(section[1]))
        for _, key in ipairs(Places(section)) do
            local setting = Settings.RegisterProxySetting(category, ADDON .. "_" .. key, Settings.VarType.Boolean,
                L[key], ns.DEFAULTS[key] and Settings.Default.True or Settings.Default.False,
                function() return ns.Get(key) end,
                function(value) ns.Set(key, value) end)
            Settings.CreateCheckbox(category, setting, L[key .. "_TIP"])
        end
    end
    Settings.RegisterAddOnCategory(category)
end

-------------------------------------------------------------------------------
--  At login (Core.lua)
-------------------------------------------------------------------------------
local plugin = false

function ns.BuildOptions()
    local EUI = EllesmereUI
    if EUI and EUI.RegisterPlugin then
        plugin = EUI.RegisterPlugin(ADDON, {
            label = L.NAME,
            modules = { {
                key = "General",
                title = L.SUBTITLE,
                description = L.DESCRIPTION,
                pages = { L.GENERAL },
                buildPage = BuildPluginPage,
            } },
        })
    end
    if not plugin then BuildSettingsPage() end
end

function ns.OpenOptions()
    if plugin then
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
