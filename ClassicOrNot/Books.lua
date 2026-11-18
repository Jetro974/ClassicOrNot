-------------------------------------------------------------------------------
--  Books.lua
--  A Library books tab in the collections journal: Forever's library books
--  (Data/Books.lua), those to hand in (in the bags or the bank), those still
--  to find, those handed in (their quest done). A click on a book pins its
--  spot on the map.
--
--  Forever's journal has its tabs down its right side. Ours is a frame of our
--  own under the last of them, and its page a frame of ours over the
--  journal's content: Blizzard's page stays shown beneath it and its tabs
--  keep working. Two writes, both undone by Blizzard's next tab change: the
--  journal's title, and its selected tab drawn unselected while ours is.
-------------------------------------------------------------------------------
local _, ns = ...
local L = ns.L

local JOURNAL = "Blizzard_Collections"
local ICON = "Interface\\Icons\\INV_Misc_Book_09"
local ROW, HEADER = 34, 26
local STATES = { "bags", "find", "done" }
local COLORS = { bags = GREEN_FONT_COLOR, find = NORMAL_FONT_COLOR, done = GRAY_FONT_COLOR }
local EVENTS = { "QUEST_TURNED_IN", "BAG_UPDATE_DELAYED", "PLAYERBANKSLOTS_CHANGED" }

local tab, page, scroll, bar
local handedIn, total = 0, 0
local events = CreateFrame("Frame")

-------------------------------------------------------------------------------
--  Books
-------------------------------------------------------------------------------
local zones = {}
local function ZoneName(map)
    if not zones[map] then
        local info = C_Map.GetMapInfo(map)
        zones[map] = info and info.name or ""
    end
    return zones[map]
end

local function StateOf(book)
    if C_QuestLog.IsQuestFlaggedCompleted(book[2]) then return "done" end
    if C_Item.GetItemCount(book[1], true) > 0 then return "bags" end
    return "find"
end

local function ByPlace(a, b)
    local za, zb = ZoneName(a[4]), ZoneName(b[4])
    if za ~= zb then return za < zb end
    return a[1] < b[1]
end

-- A book's spots: "Zone 56.3, 8.8", and its second one if it has one.
local function PlaceText(book)
    local text = format("%s %.1f, %.1f", ZoneName(book[4]), book[5], book[6])
    if book[7] then
        text = format("%s / %s %.1f, %.1f", text, ZoneName(book[7]), book[8], book[9])
    end
    return text
end

local function Refresh()
    local side = UnitFactionGroup("player")
    local groups = { bags = {}, find = {}, done = {} }
    total = 0
    for _, book in ipairs(ns.BOOKS) do
        if not book[3] or book[3] == side then
            total = total + 1
            local list = groups[StateOf(book)]
            list[#list + 1] = book
        end
    end
    local rows = {}
    for _, state in ipairs(STATES) do
        local list = groups[state]
        if #list > 0 then
            table.sort(list, ByPlace)
            rows[#rows + 1] = { header = L["BOOKS_" .. state], count = #list }
            for _, book in ipairs(list) do rows[#rows + 1] = { book = book, state = state } end
        end
    end
    handedIn = #groups.done
    bar:SetMinMaxValues(0, total)
    bar:SetValue(handedIn)
    bar.text:SetFormattedText("%d/%d", handedIn, total)
    scroll:SetDataProvider(CreateDataProvider(rows), ScrollBoxConstants.RetainScrollPosition)
end

-- Item names come from the server the first time: one refresh once all are in.
local waiting = 0
local function LoadNames()
    for _, book in ipairs(ns.BOOKS) do
        if not C_Item.GetItemNameByID(book[1]) then
            waiting = waiting + 1
            Item:CreateFromItemID(book[1]):ContinueOnItemLoad(function()
                waiting = waiting - 1
                if waiting == 0 and page:IsShown() then Refresh() end
            end)
        end
    end
end

-------------------------------------------------------------------------------
--  Rows
-------------------------------------------------------------------------------
-- The spot in the player's zone, else the first one.
local function Pin(row)
    local book = row.book
    local map, x, y = book[4], book[5], book[6]
    if book[7] and C_Map.GetBestMapForUnit("player") == book[7] then
        map, x, y = book[7], book[8], book[9]
    end
    if not C_Map.CanSetUserWaypointOnMap(map) then return end
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x / 100, y / 100))
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

local function ShowTip(row)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(row.book[1])
    GameTooltip:AddLine(L.BOOKS_PIN, GREEN_FONT_COLOR:GetRGB())
    GameTooltip:Show()
end

local function BuildRow(row)
    row.Icon = row:CreateTexture(nil, "ARTWORK")
    row.Icon:SetSize(28, 28)
    row.Icon:SetPoint("LEFT", 6, 0)
    row.Name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.Name:SetPoint("TOPLEFT", row.Icon, "TOPRIGHT", 8, -1)
    row.Name:SetPoint("RIGHT", -8, 0)
    row.Name:SetJustifyH("LEFT")
    row.Place = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.Place:SetPoint("BOTTOMLEFT", row.Icon, "BOTTOMRIGHT", 8, 1)
    row.Place:SetPoint("RIGHT", -8, 0)
    row.Place:SetJustifyH("LEFT")
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row:SetScript("OnClick", Pin)
    row:SetScript("OnEnter", ShowTip)
    row:SetScript("OnLeave", GameTooltip_Hide)
end

local function InitRow(row, data)
    if not row.Icon then BuildRow(row) end
    local book = data.book
    row.book = book
    row.Icon:SetTexture(C_Item.GetItemIconByID(book[1]))
    row.Icon:SetDesaturated(data.state == "find")
    row.Name:SetText(C_Item.GetItemNameByID(book[1]) or "")
    row.Name:SetTextColor(COLORS[data.state]:GetRGB())
    row.Place:SetText(PlaceText(book))
end

local function InitHeader(frame, data)
    if not frame.Text then
        frame.Text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalMed2")
        frame.Text:SetPoint("BOTTOMLEFT", 8, 4)
    end
    frame.Text:SetFormattedText("%s (%d)", data.header, data.count)
end

-------------------------------------------------------------------------------
--  The page
-------------------------------------------------------------------------------
-- A frame of the page, drawn with the journal's own background (a copy,
-- clipped to the frame) and taking the mouse from what lies beneath.
local function Cover(left, top, corner, right, bottom)
    local clip = CreateFrame("Frame", nil, page)
    clip:SetPoint("TOPLEFT", left, top)
    clip:SetPoint("BOTTOMRIGHT", page, corner, right, bottom)
    clip:SetClipsChildren(true)
    clip:EnableMouse(true)
    local fill = CreateFrame("Frame", nil, clip)
    local bg = fill:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    -- PortraitFrameTemplate's tiled rock texture.
    local src = CollectionsJournal.Bg
    if src and src:IsObjectType("Texture") then
        fill:SetAllPoints(src)
        bg:SetTexture(src:GetTexture(), "REPEAT", "REPEAT")
        bg:SetHorizTile(true)
        bg:SetVertTile(true)
    else
        fill:SetAllPoints(clip)
        bg:SetColorTexture(0.05, 0.05, 0.05)
    end
    return clip
end

local function ShowRewards(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText(L.BOOKS_REWARDS)
    for _, n in ipairs(ns.BOOK_REWARDS) do
        local color = handedIn >= n and GREEN_FONT_COLOR or HIGHLIGHT_FONT_COLOR
        GameTooltip:AddLine(format(L.BOOKS_REWARD, n), color:GetRGB())
    end
    GameTooltip:AddLine(L.BOOKS_HANDIN, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    GameTooltip:Show()
end

local function BuildPage()
    page = CreateFrame("Frame", nil, CollectionsJournal)
    page:SetAllPoints()
    -- Above every page of Blizzard's, which stays shown beneath.
    page:SetFrameLevel(CollectionsJournal:GetFrameLevel() + 200)
    page:Hide()

    -- The header band, right of the portrait, then the body; the title bar
    -- and its close button stay Blizzard's.
    Cover(58, -23, "TOPRIGHT", -3, -58)
    Cover(3, -58, "BOTTOMRIGHT", -3, 3)

    bar = CreateFrame("StatusBar", nil, page, "CollectionsProgressBarTemplate")
    bar:ClearAllPoints()
    bar:SetPoint("TOP", page, "TOP", 0, -39)
    bar:SetFrameLevel(page:GetFrameLevel() + 5)
    bar:EnableMouse(true)
    bar:SetScript("OnEnter", ShowRewards)
    bar:SetScript("OnLeave", GameTooltip_Hide)

    local inset = CreateFrame("Frame", nil, page, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", 4, -60)
    inset:SetPoint("BOTTOMRIGHT", -6, 5)
    inset:SetFrameLevel(page:GetFrameLevel() + 5)

    scroll = CreateFrame("Frame", nil, inset, "WowScrollBoxList")
    scroll:SetPoint("TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", -24, 4)
    local scrollBar = CreateFrame("EventFrame", nil, inset, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 8, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 8, 0)
    local view = CreateScrollBoxListLinearView()
    view:SetElementExtentCalculator(function(_, data) return data.header and HEADER or ROW end)
    view:SetElementFactory(function(factory, data)
        if data.header then factory("Frame", InitHeader) else factory("Button", InitRow) end
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(scroll, scrollBar, view)

    events:SetScript("OnEvent", function() Refresh() end)
end

local function ShowPage()
    if not page then BuildPage() end
    local current = CollectionsJournal.TabContainer.Tabs[CollectionsJournal_GetTab(CollectionsJournal)]
    if current then current:SetChecked(false) end
    tab:SetChecked(true)
    CollectionsJournal:SetTitle(L.BOOKS)
    page:Show()
    for _, event in ipairs(EVENTS) do events:RegisterEvent(event) end
    LoadNames()
    Refresh()
end

-- When Blizzard sets a tab, and when the journal closes.
local function HidePage()
    if not (page and page:IsShown()) then return end
    page:Hide()
    tab:SetChecked(false)
    events:UnregisterAllEvents()
end

-------------------------------------------------------------------------------
--  The tab
-------------------------------------------------------------------------------
local function BuildTab()
    tab = CreateFrame("Frame", nil, CollectionsJournal, "LargeSideTabButtonTemplate")
    tab.Icon:SetTexture(ICON)
    tab.tooltipText = L.BOOKS
    tab:SetFillToInterior(true)
    tab:SetChecked(false)
    tab:SetCustomOnMouseUpHandler(function(_, button, upInside)
        if button == "LeftButton" and upInside then ShowPage() end
    end)
end

-- Under the last of Blizzard's shown tabs (the journal shows them at its
-- OnShow, before it tells us).
local function PlaceTab()
    local tabs = CollectionsJournal.TabContainer
    local last
    for _, t in ipairs(tabs.Tabs) do
        if t:IsShown() then last = t end
    end
    tab:ClearAllPoints()
    if last then
        tab:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -2)
    else
        tab:SetPoint("TOPLEFT", tabs, "TOPLEFT", 0, -60)
    end
end

local owner = {}
ns.Place({
    key = "books",
    addon = JOURNAL,
    on = function()
        if not tab then BuildTab() end
        EventRegistry:RegisterCallback("CollectionsJournal.OnShow", PlaceTab, owner)
        EventRegistry:RegisterCallback("CollectionsJournal.TabSet", HidePage, owner)
        EventRegistry:RegisterCallback("CollectionsJournal.OnHide", HidePage, owner)
        PlaceTab()
        tab:Show()
    end,
    off = function()
        EventRegistry:UnregisterCallback("CollectionsJournal.OnShow", owner)
        EventRegistry:UnregisterCallback("CollectionsJournal.TabSet", owner)
        EventRegistry:UnregisterCallback("CollectionsJournal.OnHide", owner)
        HidePage()
        tab:Hide()
    end,
})
