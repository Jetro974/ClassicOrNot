-------------------------------------------------------------------------------
--  Books.lua
--  A Library books tab in the collections journal, laid out like the toy box:
--  Forever's library books (Data/Books.lua), 18 to a page, to hand in (in the
--  bags or the bank), to find, or handed in (their quest done), with the toy
--  box's count, search box and Filter menu. A click on a book pins its spot
--  on the map.
--
--  Forever's journal has its tabs down its right side. Ours is a frame of our
--  own under the last of them, and its page a frame of ours over the
--  journal's content: Blizzard's page stays shown beneath it and its tabs
--  keep working. Two writes, both undone when our page hides: the journal's
--  title, and its selected tab drawn unselected while ours is.
-------------------------------------------------------------------------------
local _, ns = ...
local L = ns.L

local JOURNAL = "Blizzard_Collections"
local ICON = "Interface\\Icons\\INV_Misc_Book_09"
local PER_PAGE = 18
local STATES = { "bags", "find", "done" }
-- The Filter menu's boxes, one per state.
local SHOWN = { bags = "booksBags", find = "booksFind", done = "booksDone" }
local EVENTS = { "QUEST_TURNED_IN", "BAG_UPDATE_DELAYED", "PLAYERBANKSLOTS_CHANGED" }

local tab, page, front, count, search, paging
local buttons = {}
local shown = {}           -- the books the filters and search keep, in order
local states = {}          -- book -> state, at the last refresh
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

-- Shared with BookPins.lua.
ns.BookZone, ns.BookState = ZoneName, StateOf

-- The game's map pin on a spot (uiMapID, x and y in percent).
function ns.PinSpot(map, x, y)
    if not C_Map.CanSetUserWaypointOnMap(map) then return end
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x / 100, y / 100))
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

local RANK = { bags = 1, find = 2, done = 3 }
local function ByStateThenPlace(a, b)
    local ra, rb = RANK[states[a]], RANK[states[b]]
    if ra ~= rb then return ra < rb end
    local za, zb = ZoneName(a[4]), ZoneName(b[4])
    if za ~= zb then return za < zb end
    return a[1] < b[1]
end

-- The search box's text in a book's name or zone (plain text, any case).
local function Matches(book, text)
    if text == "" then return true end
    local name = C_Item.GetItemNameByID(book[1]) or ""
    return name:lower():find(text, 1, true) or ZoneName(book[4]):lower():find(text, 1, true)
end

-------------------------------------------------------------------------------
--  Buttons: the toy box's look (CollectionsSpellButtonTemplate's textures),
--  on plain buttons of our own (that template is secure).
-------------------------------------------------------------------------------
local function Pin(button)
    local book = button.book
    local map, x, y = book[4], book[5], book[6]
    -- A book found in two places: the spot in the player's zone, if any.
    if book[7] and C_Map.GetBestMapForUnit("player") == book[7] then
        map, x, y = book[7], book[8], book[9]
    end
    ns.PinSpot(map, x, y)
end

local function ShowTip(button)
    local book = button.book
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(book[1])
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["BOOKS_" .. states[book]], HIGHLIGHT_FONT_COLOR:GetRGB())
    for s = 4, #book, 3 do
        GameTooltip:AddLine(format("%s %.1f, %.1f", ZoneName(book[s]), book[s + 1], book[s + 2]), HIGHLIGHT_FONT_COLOR:GetRGB())
    end
    GameTooltip:AddLine(L.BOOKS_PIN, GREEN_FONT_COLOR:GetRGB())
    GameTooltip:Show()
end

local function Texture(button, layer, sub, width, height, y)
    local t = button:CreateTexture(nil, layer, nil, sub)
    t:SetSize(width, height)
    t:SetPoint("CENTER", 0, y)
    return t
end

local function NewButton(parent, i)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(50, 50)
    if i == 1 then
        b:SetPoint("TOPLEFT", 40, -53)
    elseif i % 3 == 1 then
        b:SetPoint("TOPLEFT", buttons[i - 3], "BOTTOMLEFT", 0, -16)
    else
        b:SetPoint("TOPLEFT", buttons[i - 1], "TOPLEFT", 208, 0)
    end
    b.icon = Texture(b, "ARTWORK", 0, 42, 42, 1)
    b.icon:SetTexCoord(0.04347826, 0.95652173, 0.04347826, 0.95652173)
    b.iconUncollected = Texture(b, "ARTWORK", 0, 42, 41, 2)
    b.iconUncollected:SetTexCoord(0.063, 0.938, 0.063, 0.917)
    b.iconUncollected:SetAlpha(0.18)
    b.iconUncollected:SetDesaturated(true)
    b.innerGlow = Texture(b, "ARTWORK", 0, 50, 50, 2)
    b.innerGlow:SetAtlas("collections-itemborder-uncollected-innerglow", true)
    b.innerGlow:SetAlpha(0.18)
    b.frameCollected = Texture(b, "OVERLAY", 1, 56, 56, 0)
    b.frameCollected:SetAtlas("collections-itemborder-collected")
    b.frameUncollected = Texture(b, "OVERLAY", 1, 50, 50, 2)
    b.frameUncollected:SetAtlas("collections-itemborder-uncollected")
    -- To hand in: the quest giver's yellow "?" (a quest to hand in), where a
    -- toy shows its favourite star.
    b.handIn = b:CreateTexture(nil, "OVERLAY", nil, 2)
    b.handIn:SetTexture("Interface\\GossipFrame\\ActiveQuestIcon")
    b.handIn:SetSize(20, 20)
    b.handIn:SetPoint("TOPLEFT", -6, 7)
    b.name = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    b.name:SetSize(135, 0)
    b.name:SetMaxLines(3)
    b.name:SetJustifyH("LEFT")
    b.name:SetPoint("LEFT", b, "RIGHT", 9, 3)
    b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    b:GetPushedTexture():SetSize(42, 42)
    b:GetPushedTexture():ClearAllPoints()
    b:GetPushedTexture():SetPoint("CENTER", 0, 1)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:GetHighlightTexture():SetSize(48, 48)
    b:GetHighlightTexture():ClearAllPoints()
    b:GetHighlightTexture():SetPoint("CENTER", 0, 2)
    b:SetScript("OnClick", Pin)
    b:SetScript("OnEnter", ShowTip)
    b:SetScript("OnLeave", GameTooltip_Hide)
    return b
end

-- As the toy box draws a toy it has (gold name) or lacks (faded, brown name);
-- a book to hand in is drawn had, with a white name and the turn-in mark.
local function DrawButton(b, book)
    b.book = book
    if not book then return b:Hide() end
    local state = states[book]
    local had = state ~= "find"
    local texture = C_Item.GetItemIconByID(book[1])
    b.icon:SetTexture(texture)
    b.iconUncollected:SetTexture(texture)
    b.icon:SetShown(had)
    b.frameCollected:SetShown(had)
    b.iconUncollected:SetShown(not had)
    b.frameUncollected:SetShown(not had)
    b.innerGlow:SetShown(not had)
    b.handIn:SetShown(state == "bags")
    b.name:SetText(C_Item.GetItemNameByID(book[1]) or "")
    if state == "find" then
        b.name:SetTextColor(0.33, 0.27, 0.20, 1)
        b.name:SetShadowColor(0, 0, 0, 0.33)
    else
        if state == "bags" then
            b.name:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
        else
            b.name:SetTextColor(1, 0.82, 0, 1)
        end
        b.name:SetShadowColor(0, 0, 0, 1)
    end
    b:Show()
end

local function DrawPage()
    local first = (paging:GetCurrentPage() - 1) * PER_PAGE
    for i = 1, PER_PAGE do
        local b = buttons[i]
        DrawButton(b, shown[first + i])
        -- A tooltip open on a button now showing another book.
        if GameTooltip:GetOwner() == b then
            if b.book then ShowTip(b) else GameTooltip:Hide() end
        end
    end
end

local function Refresh()
    local side = UnitFactionGroup("player")
    local text = search:GetText():lower()
    wipe(shown)
    handedIn, total = 0, 0
    for _, book in ipairs(ns.BOOKS) do
        if not book[3] or book[3] == side then
            local state = StateOf(book)
            states[book] = state
            total = total + 1
            if state == "done" then handedIn = handedIn + 1 end
            if ns.Get(SHOWN[state]) and Matches(book, text) then shown[#shown + 1] = book end
        end
    end
    table.sort(shown, ByStateThenPlace)
    count.Count:SetFormattedText("%d/%d", handedIn, total)
    paging:SetMaxPages(math.ceil(#shown / PER_PAGE))
    DrawPage()
end

-- Item names come from the server the first time, once each (one that never
-- comes must not hold back the others).
local asked = {}
local function LoadNames()
    for _, book in ipairs(ns.BOOKS) do
        if not asked[book[1]] and not C_Item.GetItemNameByID(book[1]) then
            asked[book[1]] = true
            Item:CreateFromItemID(book[1]):ContinueOnItemLoad(function()
                if page:IsShown() then Refresh() end
            end)
        end
    end
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

-- The toy box's Filter menu: one box per state, kept in ClassicOrNotDB.
local function SetupFilter(dropdown)
    -- The toy box's fixed width (the template sizes it to its text).
    dropdown.resizeToText = false
    dropdown:SetWidth(90)
    local labels = { done = COLLECTED, bags = L.BOOKS_bags, find = NOT_COLLECTED }
    local function isShown(state) return ns.Get(SHOWN[state]) end
    local function toggle(state) ClassicOrNotDB[SHOWN[state]] = not ns.Get(SHOWN[state]) end
    dropdown:SetupMenu(function(_, root)
        for _, state in ipairs({ "done", "bags", "find" }) do
            root:CreateCheckbox(labels[state], isShown, toggle, state)
        end
    end)
    dropdown:SetUpdateCallback(Refresh)
    dropdown:SetIsDefaultCallback(function()
        return isShown("done") and isShown("bags") and isShown("find")
    end)
    -- The reset button calls only this, not the update callback.
    dropdown:SetDefaultCallback(function()
        for _, key in pairs(SHOWN) do ClassicOrNotDB[key] = nil end
        Refresh()
    end)
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

    -- Everything else above the covers.
    front = CreateFrame("Frame", nil, page)
    front:SetAllPoints()
    front:SetFrameLevel(page:GetFrameLevel() + 5)

    -- As the toy box, at the same places.
    count = CreateFrame("Frame", nil, front, "CollectionsCountTemplate")
    count:ClearAllPoints()
    count:SetPoint("TOPLEFT", 70, -35)
    count.Label:SetText(L.BOOKS_COUNT)
    count:EnableMouse(true)
    count:SetScript("OnEnter", ShowRewards)
    count:SetScript("OnLeave", GameTooltip_Hide)

    search = CreateFrame("EditBox", nil, front, "SearchBoxTemplate")
    search:SetSize(115, 20)
    search:SetMaxLetters(40)
    search:SetPoint("TOPRIGHT", -107, -35)
    search:HookScript("OnTextChanged", function()
        if page:IsShown() then
            -- Back to page 1 without the page turn (sound, drawing the old list).
            paging.currentPage = 1
            paging:Update()
            Refresh()
        end
    end)

    local filter = CreateFrame("DropdownButton", nil, front, "WowStyle1FilterDropdownTemplate")
    filter:SetPoint("TOPRIGHT", -12, -35)
    SetupFilter(filter)

    local icons = CreateFrame("Frame", nil, front, "CollectionsBackgroundTemplate")
    icons:EnableMouseWheel(true)
    icons:SetScript("OnMouseWheel", function(_, delta) paging:OnMouseWheel(delta) end)
    for i = 1, PER_PAGE do buttons[i] = NewButton(icons, i) end

    paging = CreateFrame("Frame", nil, front, "CollectionsPagingFrameTemplate")
    paging:SetPoint("BOTTOM", 21, 43)
    -- The paging frame calls its parent's OnPageChanged.
    front.OnPageChanged = function()
        PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
        DrawPage()
    end

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

-- When Blizzard sets a tab, when the journal closes, and when the setting is
-- turned off: Blizzard's selected tab and title come back (the journal's
-- OnShow redraws neither).
local function HidePage()
    if not (page and page:IsShown()) then return end
    page:Hide()
    tab:SetChecked(false)
    events:UnregisterAllEvents()
    local selected = CollectionsJournal_GetTab(CollectionsJournal)
    local current = CollectionsJournal.TabContainer.Tabs[selected]
    if current then current:SetChecked(true) end
    CollectionsJournal:SetTitle(CollectionsJournal:GetPageTitleText(selected))
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
