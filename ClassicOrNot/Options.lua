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
-- then its places. A place's label is L[key], its tooltip L[key .. "_TIP"].
local SECTIONS = {
    { L.QUESTS, L.QUESTS_UP, "givers", "log", "tracker" },
    { L.RECIPES, L.RECIPES_UP, "window", "trainer" },
    { L.ITEMS, L.ITEMS_UP, "tooltip" },
    { L.COLLECTIONS, L.COLLECTIONS_UP, "mounts", "pets", "toys" },
}

local function Shown(key)
    return key ~= "tracker" or ns.HasTracker()
end

local function Each(onSection, onPlace)
    for _, section in ipairs(SECTIONS) do
        onSection(section)
        for i = 3, #section do
            if Shown(section[i]) then onPlace(section[i]) end
        end
    end
end

-------------------------------------------------------------------------------
--  EllesmereUI plugin page
-------------------------------------------------------------------------------
local function BuildPluginPage(_, parent, y)
    local W = EllesmereUI.Widgets
    local _, h
    Each(function(section)
        _, h = W:SectionHeader(parent, section[2], y); y = y - h
    end, function(key)
        _, h = W:Toggle(parent, L[key], y,
            function() return ns.Get(key) end,
            function(value) ns.Set(key, value) end,
            L[key .. "_TIP"]); y = y - h
    end)
    return math.abs(y)
end

-------------------------------------------------------------------------------
--  Game options page
-------------------------------------------------------------------------------
local category

local function BuildSettingsPage()
    local layout
    category, layout = Settings.RegisterVerticalLayoutCategory(L.NAME)
    Each(function(section)
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(section[1]))
    end, function(key)
        local setting = Settings.RegisterProxySetting(category, ADDON .. "_" .. key, Settings.VarType.Boolean,
            L[key], ns.DEFAULTS[key] and Settings.Default.True or Settings.Default.False,
            function() return ns.Get(key) end,
            function(value) ns.Set(key, value) end)
        Settings.CreateCheckbox(category, setting, L[key .. "_TIP"])
    end)
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
