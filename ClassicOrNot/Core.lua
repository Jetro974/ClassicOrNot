-------------------------------------------------------------------------------
--  Core.lua
--  What every part shares: the settings, the original-game test, the mark (a
--  small blue infinity on a frame of our own), and the switch that turns each
--  place on and off.
--
--  Nothing of Blizzard's is written: marks are frames of ours, kept in weak
--  tables keyed by the row they sit on, and Blizzard's lists are only read.
-------------------------------------------------------------------------------
local ADDON, ns = ...

ns.ATLAS = "perks-infinity"
ns.R, ns.G, ns.B = 0.30, 0.65, 1.00

-------------------------------------------------------------------------------
--  Settings: ClassicOrNotDB[key] (account-wide); an unset key reads its
--  default. Every place is on: marking is all this addon does.
-------------------------------------------------------------------------------
ns.DEFAULTS = {
    givers = true, log = true, tracker = true, -- quests
    window = true, trainer = true,      -- recipes
    tooltip = true,                     -- items
    mounts = true, pets = true, toys = true, -- collections
}

function ns.Get(key)
    local value = ClassicOrNotDB and ClassicOrNotDB[key]
    if value == nil then return ns.DEFAULTS[key] end
    return value
end

function ns.Set(key, value)
    ClassicOrNotDB[key] = value
    ns.ApplyAll()
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
    mark:SetPoint("LEFT", fs, "TOPLEFT", fs:GetWrappedWidth() + 3, -fs:GetLineHeight() / 2)
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
