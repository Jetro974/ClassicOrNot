-------------------------------------------------------------------------------
--  BookNotes.lua
--  Library books outside the tab: a line on a book's tooltip (to hand in,
--  already handed in, or for the other faction), and a chat line when a book
--  comes into the bags (one to hand in, or one already handed in).
-------------------------------------------------------------------------------
local _, ns = ...
local L = ns.L

local byItem = {}
for _, book in ipairs(ns.BOOKS) do byItem[book[1]] = book end

local notes = ns.Place({ key = "booksNotes" })

-------------------------------------------------------------------------------
--  Tooltip
-------------------------------------------------------------------------------
local function OnTooltip(tip, data)
    if not notes.state or (tip ~= GameTooltip and tip ~= ItemRefTooltip) then return end
    local id = data and data.id
    if type(id) ~= "number" or issecretvalue(id) or not byItem[id] then return end
    local book = byItem[id]
    if book[3] and book[3] ~= UnitFactionGroup("player") then
        tip:AddLine(L.BOOK_OTHER, GRAY_FONT_COLOR:GetRGB())
    elseif ns.BookState(book) == "done" then
        tip:AddLine(L.BOOK_DONE, GRAY_FONT_COLOR:GetRGB())
    else
        tip:AddLine(L.BOOK_TODO, GREEN_FONT_COLOR:GetRGB())
    end
end

-------------------------------------------------------------------------------
--  Chat: the books in the bags, kept to tell a new one at the next bag update.
-------------------------------------------------------------------------------
local inBags = {}

local function Say(text)
    print("|cff4da6ff" .. L.NAME .. "|r: " .. text)
end

local function Scan(quiet)
    local side = UnitFactionGroup("player")
    local found, done, total = {}, 0, 0
    for _, book in ipairs(ns.BOOKS) do
        if not book[3] or book[3] == side then
            total = total + 1
            local handedIn = C_QuestLog.IsQuestFlaggedCompleted(book[2])
            -- The bank too: a book taken out of it is not news.
            local has = C_Item.GetItemCount(book[1], true) > 0
            if handedIn or has then done = done + 1 end
            if has and not inBags[book[1]] and not quiet then
                found[#found + 1] = { book = book, handedIn = handedIn }
            end
            inBags[book[1]] = has or nil
        end
    end
    for _, new in ipairs(found) do
        local id = new.book[1]
        local link = select(2, C_Item.GetItemInfo(id)) or C_Item.GetItemNameByID(id) or tostring(id)
        if new.handedIn then
            Say(format(L.BOOK_AGAIN, link))
        else
            Say(format(L.BOOK_FOUND, link, L["LIBRARIAN_" .. (side or "Alliance")], done, total))
        end
    end
end

local events = CreateFrame("Frame")
events:SetScript("OnEvent", function() Scan(false) end)

local hooked = false
notes.on = function()
    if not hooked then
        hooked = true
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltip)
    end
    -- What the bags hold now is not news.
    wipe(inBags)
    Scan(true)
    events:RegisterEvent("BAG_UPDATE_DELAYED")
end
notes.off = function()
    events:UnregisterAllEvents()
end
