-------------------------------------------------------------------------------
--  BookPins.lua
--  The library books still to find (Data/Books.lua, Books.lua), shown on the
--  world map and the minimap; a click pins the spot. Off by default.
--
--  World map: a data provider (the map's own way to take an addon's data)
--  that draws buttons of ours on the map's canvas, scaled and placed as the
--  map places its own pins. Minimap: buttons of ours on the minimap, placed
--  from the player's position, redrawn while a book to find is in the zone.
-------------------------------------------------------------------------------
local _, ns = ...
local L = ns.L

local EVENTS = { "QUEST_TURNED_IN", "BAG_UPDATE_DELAYED" }

-- The books to find for the player's faction, now.
local function ToFind()
    local side = UnitFactionGroup("player")
    local list = {}
    for _, book in ipairs(ns.BOOKS) do
        if (not book[3] or book[3] == side) and ns.BookState(book) == "find" then
            list[#list + 1] = book
        end
    end
    return list
end

-------------------------------------------------------------------------------
--  Pins: the book's icon in a circle; pin.book and pin.spot (the index of its
--  map in the book's row).
-------------------------------------------------------------------------------
local function ShowTip(pin)
    local book, s = pin.book, pin.spot
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    GameTooltip:SetText(C_Item.GetItemNameByID(book[1]) or L.BOOKS)
    GameTooltip:AddLine(format("%s %.1f, %.1f", ns.BookZone(book[s]), book[s + 1], book[s + 2]), HIGHLIGHT_FONT_COLOR:GetRGB())
    GameTooltip:AddLine(L.BOOKS_PIN, GREEN_FONT_COLOR:GetRGB())
    GameTooltip:Show()
end

local function PinSpot(pin)
    local book, s = pin.book, pin.spot
    ns.PinSpot(book[s], book[s + 1], book[s + 2])
end

local function NewPin(parent, size)
    local pin = CreateFrame("Button", nil, parent)
    pin:SetSize(size, size)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetAllPoints()
    local mask = pin:CreateMaskTexture()
    mask:SetAllPoints(pin.icon)
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    pin.icon:AddMaskTexture(mask)
    pin:SetScript("OnEnter", ShowTip)
    pin:SetScript("OnLeave", GameTooltip_Hide)
    pin:SetScript("OnClick", PinSpot)
    return pin
end

-- pins[n], made on parent if needed, set to a book's spot.
local function UsePin(pins, n, parent, size, book, s)
    local pin = pins[n] or NewPin(parent, size)
    pins[n] = pin
    pin.book, pin.spot = book, s
    pin.icon:SetTexture(C_Item.GetItemIconByID(book[1]))
    return pin
end

local function HideFrom(pins, first)
    for i = first, #pins do pins[i]:Hide() end
end

-------------------------------------------------------------------------------
--  World map
-------------------------------------------------------------------------------
-- The maps that hold a map: itself, its continent, and so on up.
local holders = {}
local function Holds(mapID, spotMap)
    local set = holders[spotMap]
    if not set then
        set = {}
        local m = spotMap
        while m and m > 0 and not set[m] do
            set[m] = true
            local info = C_Map.GetMapInfo(m)
            m = info and info.parentMapID
        end
        holders[spotMap] = set
    end
    return set[mapID]
end

-- A spot's place on mapID (0 to 1), if mapID shows it.
local function OnMap(mapID, spotMap, x, y)
    if spotMap == mapID then return x / 100, y / 100 end
    if not Holds(mapID, spotMap) then return end
    local continent, world = C_Map.GetWorldPosFromMapPos(spotMap, CreateVector2D(x / 100, y / 100))
    if not continent then return end
    local _, pos = C_Map.GetMapPosFromWorldPos(continent, world, mapID)
    if pos then return pos:GetXY() end
end

local worldPins = {}
local provider = CreateFromMixins(MapCanvasDataProviderMixin)

-- As MapCanvasPinMixin:ApplyCurrentScale and the map's ApplyPinPosition do
-- for a pin with scaling limits 1 to 1.2.
local function PlaceAll(map)
    local canvas = map:GetCanvas()
    local scale = map:GetGlobalPinScale() * Lerp(1, 1.2, Saturate(map:GetCanvasZoomPercent())) / map:GetCanvasScale()
    for _, pin in ipairs(worldPins) do
        if pin:IsShown() then
            pin:SetScale(scale)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", canvas, "TOPLEFT", canvas:GetWidth() * pin.x / scale, -canvas:GetHeight() * pin.y / scale)
        end
    end
end

function provider:OnAdded(map)
    MapCanvasDataProviderMixin.OnAdded(self, map)
    for _, event in ipairs(EVENTS) do self:RegisterEvent(event) end
end

function provider:OnEvent()
    if self:GetMap():IsShown() then self:RefreshAllData() end
end

function provider:RemoveAllData()
    HideFrom(worldPins, 1)
end

function provider:RefreshAllData()
    local map = self:GetMap()
    local mapID = map:GetMapID()
    local n = 0
    if mapID then
        local canvas = map:GetCanvas()
        local level = map:GetPinFrameLevelsManager():GetValidFrameLevel("PIN_FRAME_LEVEL_AREA_POI")
        for _, book in ipairs(ToFind()) do
            for s = 4, #book, 3 do
                local x, y = OnMap(mapID, book[s], book[s + 1], book[s + 2])
                if x then
                    n = n + 1
                    local pin = UsePin(worldPins, n, canvas, 20, book, s)
                    pin.x, pin.y = x, y
                    pin:SetFrameLevel(level)
                    pin:Show()
                end
            end
        end
    end
    HideFrom(worldPins, n + 1)
    PlaceAll(map)
end

function provider:OnCanvasScaleChanged()
    PlaceAll(self:GetMap())
end

ns.Place({
    key = "booksMap",
    addon = "Blizzard_WorldMap",
    on = function() WorldMapFrame:AddDataProvider(provider) end,
    off = function() WorldMapFrame:RemoveDataProvider(provider) end,
})

-------------------------------------------------------------------------------
--  Minimap
-------------------------------------------------------------------------------
-- The minimap's diameter in yards at each zoom level (as HereBeDragons-Pins
-- measures it).
local INDOOR = { 300, 240, 180, 120, 80, 50 }
local OUTDOOR = { 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 }

local miniPins = {}
local count = 0                    -- pins in use, the books to find in the zone
local zone, width, height          -- the player's map and its size in yards
local ticker

local function DrawMinimap()
    local pos = C_Map.GetPlayerMapPosition(zone, "player")
    local px, py
    if pos then px, py = pos:GetXY() end
    if not px or issecretvalue(px) or issecretvalue(py) then return HideFrom(miniPins, 1) end
    local diameter = (IsIndoors() and INDOOR or OUTDOOR)[Minimap:GetZoom() + 1]
    if not diameter then return HideFrom(miniPins, 1) end
    local radius = Minimap:GetWidth() / 2
    local perYard = radius / (diameter / 2)
    local facing = C_CVar.GetCVarBool("rotateMinimap") and GetPlayerFacing()
    if facing and issecretvalue(facing) then facing = nil end
    local cos, sin = 1, 0
    if facing then cos, sin = math.cos(facing), math.sin(facing) end
    for i = 1, count do
        local pin = miniPins[i]
        -- Yards east and north of the player, turned with the minimap.
        local east = (pin.x - px) * width
        local north = (py - pin.y) * height
        local x, y = east * cos + north * sin, north * cos - east * sin
        x, y = x * perYard, y * perYard
        if x * x + y * y > (radius - 6) * (radius - 6) then
            pin:Hide()
        else
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", Minimap, "CENTER", x, y)
            pin:Show()
        end
    end
end

-- The zone's books to find, at login, a zone change or a book found.
local function SetupMinimap()
    count = 0
    zone = C_Map.GetBestMapForUnit("player")
    if zone then width, height = C_Map.GetMapWorldSize(zone) end
    if zone and width and width > 0 then
        for _, book in ipairs(ToFind()) do
            for s = 4, #book, 3 do
                if book[s] == zone then
                    count = count + 1
                    local pin = UsePin(miniPins, count, Minimap, 14, book, s)
                    pin.x, pin.y = book[s + 1] / 100, book[s + 2] / 100
                    pin:SetFrameLevel(Minimap:GetFrameLevel() + 5)
                end
            end
        end
    end
    HideFrom(miniPins, count + 1)
    -- Redrawn as the player moves, only while there is a book to show.
    if count > 0 then
        if not ticker then ticker = C_Timer.NewTicker(0.1, DrawMinimap) end
        DrawMinimap()
    elseif ticker then
        ticker:Cancel()
        ticker = nil
    end
end

local zoneEvents = CreateFrame("Frame")
zoneEvents:SetScript("OnEvent", SetupMinimap)
local ZONE_EVENTS = { "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", unpack(EVENTS) }

ns.Place({
    key = "booksMap",
    on = function()
        for _, event in ipairs(ZONE_EVENTS) do zoneEvents:RegisterEvent(event) end
        SetupMinimap()
    end,
    off = function()
        zoneEvents:UnregisterAllEvents()
        if ticker then
            ticker:Cancel()
            ticker = nil
        end
        count = 0
        HideFrom(miniPins, 1)
    end,
})
