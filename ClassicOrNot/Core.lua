-------------------------------------------------------------------------------
--  Core.lua
--  What every part shares: the settings, the original-game test, the mark (a
--  small blue infinity on a frame of our own), and the switch that turns each
--  place on and off.
--
--  Marks write nothing of Blizzard's: they are frames of ours, kept in weak
--  tables keyed by the row they sit on, and Blizzard's lists are only read.
--  Two exceptions, both the player's own choice: a filter rebuilds the list
--  a journal shows (see ns.Filter), and one box changes a setting of the
--  game's (see "missing" below).
-------------------------------------------------------------------------------
local ADDON, ns = ...

ns.ATLAS = "perks-infinity"
ns.R, ns.G, ns.B = 0.30, 0.65, 1.00

-------------------------------------------------------------------------------
--  Settings: ClassicOrNotDB[key] (account-wide); an unset key reads its
--  default. Every place is on: marking is all this addon does (a filter on
--  only adds its choice to the Filter menu, set to All).
-------------------------------------------------------------------------------
ns.DEFAULTS = {
    givers = true, log = true,          -- quests
    window = true, trainer = true,      -- recipes
    tooltip = true, merchant = true,    -- items
    mounts = true, pets = true, toys = true, appearances = true, -- collections
    books = true,                       -- the Library books tab
    booksBags = true, booksFind = true, booksDone = true, -- its Filter menu
    booksNotes = true,                  -- book tooltip line, loot message
    booksMap = false,                   -- books to find on the maps (asked for)
    mountsFilter = true, petsFilter = true, appearancesFilter = true,
    mountsView = "all", petsView = "all", appearancesView = "all", -- the filters' choices
}

-- One box, "missing", is the game's own setting: Forever's journals list
-- only what the player has, without their Filter button, while this CVar is
-- on. The game keeps it for the whole account, and the journals read it
-- when they load.
local ONLY_COLLECTED = "onlyShowCollectedItemsInJournal"

function ns.Get(key)
    if key == "missing" then return not C_CVar.GetCVarBool(ONLY_COLLECTED) end
    local value = ClassicOrNotDB and ClassicOrNotDB[key]
    if value == nil then return ns.DEFAULTS[key] end
    return value
end

function ns.Set(key, value)
    if key == "missing" then
        C_CVar.SetCVar(ONLY_COLLECTED, value and "0" or "1")
        if C_AddOns.IsAddOnLoaded("Blizzard_Collections") then ns.AskReload() end
        return
    end
    ClassicOrNotDB[key] = value
    ns.ApplyAll()
end

-- For a change the game only takes at a reload.
function ns.AskReload()
    if not StaticPopupDialogs.CLASSICORNOT_RELOAD then
        StaticPopupDialogs.CLASSICORNOT_RELOAD = {
            text = ns.L.RELOAD, button1 = ns.L.RELOAD_NOW, button2 = ns.L.LATER,
            OnAccept = function() ReloadUI() end,
            timeout = 0, whileDead = true, hideOnEscape = true,
            preferredIndex = 3, -- clear of the slots Blizzard's own popups use
        }
    end
    StaticPopup_Show("CLASSICORNOT_RELOAD")
end

-------------------------------------------------------------------------------
--  The original-game test: id is in list, sorted first, last ID pairs.
-------------------------------------------------------------------------------
local function InList(list, id)
    local lo, hi = 1, #list / 2
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        if id < list[mid * 2 - 1] then
            hi = mid - 1
        elseif id > list[mid * 2] then
            lo = mid + 1
        else
            return true
        end
    end
    return false
end
ns.InList = InList

-- An ID the game gave us that is not from the original game. A secret value
-- (combat data on this client) is never compared.
function ns.IsNew(list, id)
    return type(id) == "number" and not issecretvalue(id) and id > 0 and not InList(list, id)
end

-------------------------------------------------------------------------------
--  Marks
-------------------------------------------------------------------------------
function ns.Store()
    return setmetatable({}, { __mode = "k" })
end

local function NewMark(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(18, 10)
    -- Above the row's own child frames (a journal button's drag button).
    f:SetFrameLevel(parent:GetFrameLevel() + 10)
    local t = f:CreateTexture(nil, "OVERLAY")
    t:SetAllPoints()
    t:SetAtlas(ns.ATLAS)
    t:SetVertexColor(ns.R, ns.G, ns.B)
    return f
end

-- Anchors that never change for a given host: placed once, when its mark is
-- made (see ns.Anchor).
local fixed = setmetatable({}, { __mode = "k" })

-- A marker for the IDs missing from original: Mark(store, host, on, id,
-- place, ...) shows host's mark when id is new, else hides it; place(mark,
-- ...) anchors a shown one.
function ns.Marker(original)
    return function(store, host, on, id, place, ...)
        local mark = store[host]
        if on and ns.IsNew(original, id) then
            if not mark then
                mark = NewMark(host)
                store[host] = mark
                place(mark, ...)
            elseif not fixed[place] then
                place(mark, ...)
            end
            mark:Show()
        elseif mark then
            mark:Hide()
        end
    end
end

function ns.Unmark(store, host)
    local mark = store[host]
    if mark then mark:Hide() end
end

function ns.HideAll(store)
    for _, mark in pairs(store) do mark:Hide() end
end

-- Right after the first line of a text (a wrapped text's widest line is
-- usually its first).
function ns.AfterText(mark, fs)
    mark:ClearAllPoints()
    mark:SetPoint("LEFT", fs, "TOPLEFT", fs:GetWrappedWidth() + 5, -fs:GetLineHeight() / 2)
end

-- A fixed anchor on a frame of the host's own (or the host itself):
-- ns.Anchor("TOPRIGHT", "TOPRIGHT", 4, 3)(mark, frame).
function ns.Anchor(point, relativePoint, x, y)
    local function place(mark, frame)
        mark:SetPoint(point, frame, relativePoint, x, y)
    end
    fixed[place] = true
    return place
end

-------------------------------------------------------------------------------
--  Places: each is a setting with on() and off(). One that lives in a
--  load-on-demand Blizzard addon waits for it, then applies.
-------------------------------------------------------------------------------
local places = {}

-- place = { key, addon (nil: always loaded), on, off }
function ns.Place(place)
    place.state = false
    places[#places + 1] = place
    return place
end

function ns.ApplyAll()
    for _, place in ipairs(places) do
        local want = ns.Get(place.key) == true
        if want ~= place.state then
            if place.addon and not place.ready then
                place.ready = select(2, C_AddOns.IsAddOnLoaded(place.addon))
            end
            if place.addon and not place.ready then
                if want and not place.waiting then
                    place.waiting = true
                    -- Called at the addon's ADDON_LOADED: ready from then on.
                    EventUtil.ContinueOnAddOnLoaded(place.addon, function()
                        place.waiting = nil
                        place.ready = true
                        ns.ApplyAll()
                    end)
                end
            else
                place.state = want
                if want then place.on() else place.off() end
            end
        end
    end
end

-- A Blizzard scrolled list: mark(row, elementData) runs on every row it
-- fills while the setting is on; turning it off hides its marks once.
-- spec = { key, addon, box (returns the ScrollBox), store, mark, onWatch }
local INITIALIZED = ScrollBoxListMixin.Event.OnInitializedFrame
function ns.List(spec)
    -- A callback with an owner gets the owner first.
    local function onFrame(_, row, elementData) spec.mark(row, elementData) end
    spec.on = function()
        local box = spec.box()
        box:RegisterCallback(INITIALIZED, onFrame, spec.store)
        box:ForEachFrame(spec.mark)
        if spec.onWatch then spec.onWatch(true) end
    end
    spec.off = function()
        spec.box():UnregisterCallback(INITIALIZED, spec.store)
        ns.HideAll(spec.store)
        if spec.onWatch then spec.onWatch(false) end
    end
    return ns.Place(spec)
end

-- A Blizzard page redrawn by a function of its own. hook(redrawn) hooks that
-- function the first time the setting is on (hooks cannot be removed);
-- redrawn passes its arguments to mark while the setting is on. Turning on
-- also marks the page as it stands (now); turning off hides its marks.
-- spec = { key, addon, store, hook, mark, now }
function ns.Page(spec)
    local hooked = false
    spec.on = function()
        if not hooked then
            hooked = true
            spec.hook(function(...) if spec.state then spec.mark(...) end end)
        end
        spec.now()
    end
    spec.off = function() ns.HideAll(spec.store) end
    return ns.Place(spec)
end

-------------------------------------------------------------------------------
--  Filters: a Blizzard list's Filter menu gets a choice of All, New in
--  Forever or Classic, kept in ClassicOrNotDB[spec.view]. Unlike a mark, a
--  filter rewrites the list Blizzard shows, at the player's request: only in
--  lists whose rows call nothing protected.
-------------------------------------------------------------------------------
local VIEWS = { "all", "new", "classic" }

-- spec = { key, addon, original, view,
--   shown() (optional): whether the list's Filter button is shown; a list
--     filtered without it could not be put back by the player,
--   menu(add): has add(rootDescription) run whenever the Filter menu is built,
--   hook(after): hooks the list's rebuild, after(...) running at its end,
--   drop(keep, ...): takes out of the rebuilt list the IDs keep refuses,
--   refresh(): rebuilds the list if it is shown }
function ns.Filter(spec)
    local hooked = false
    local function keep(id)
        return ns.IsNew(spec.original, id) == (ns.Get(spec.view) == "new")
    end
    local function filtering()
        return spec.state and ns.Get(spec.view) ~= "all" and (not spec.shown or spec.shown())
    end
    local function isChosen(view)
        return ns.Get(spec.view) == view
    end
    local function choose(view)
        ClassicOrNotDB[spec.view] = view
        spec.refresh()
    end
    local function add(root)
        if not spec.state then return end
        root:CreateDivider()
        root:CreateTitle(ns.L.NAME)
        for _, view in ipairs(VIEWS) do
            root:CreateRadio(ns.L["VIEW_" .. view], isChosen, choose, view)
        end
    end
    spec.on = function()
        if not hooked then
            hooked = true
            spec.menu(add)
            spec.hook(function(...) if filtering() then spec.drop(keep, ...) end end)
        end
        if filtering() then spec.refresh() end
    end
    -- The whole list again, if it was filtered (spec.state is false by now).
    spec.off = function()
        if ns.Get(spec.view) ~= "all" then spec.refresh() end
    end
    return ns.Place(spec)
end

-------------------------------------------------------------------------------
--  Start
-------------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" then
        if name ~= ADDON then return end
        self:UnregisterEvent("ADDON_LOADED")
        ClassicOrNotDB = ClassicOrNotDB or {}
    else
        self:UnregisterEvent("PLAYER_LOGIN")
        ns.BuildOptions()
        ns.ApplyAll()
    end
end)
