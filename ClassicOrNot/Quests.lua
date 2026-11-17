-------------------------------------------------------------------------------
--  Quests.lua
--  New quests, marked at quest givers (their gossip and greeting lists, and
--  the quest text before accepting) and in the quest log. A quest is original
--  when its ID is in the original game's list (Data/Quests.lua).
--
--  The gossip list's callback is there only while its place is on. The greeting list, the quest text and the quest log keep
--  the hooks they get the first time their place is on (hooks cannot be
--  removed): each returns at once while its place is off.
-------------------------------------------------------------------------------
local _, ns = ...

local Mark = ns.Marker(ns.ORIGINAL_QUESTS)

-------------------------------------------------------------------------------
--  Quest givers: the gossip list, the greeting list, the quest text
-------------------------------------------------------------------------------
local gossipMarks = ns.Store()
local function MarkGossipButton(button, elementData)
    local kind = elementData and elementData.buttonType
    local id = (kind == GOSSIP_BUTTON_TYPE_AVAILABLE_QUEST or kind == GOSSIP_BUTTON_TYPE_ACTIVE_QUEST)
        and elementData.info and elementData.info.questID
    -- The list holds other frames too (the greeting text is no button): only
    -- quest buttons are marked, and a reused button loses its mark.
    if not id then return ns.Unmark(gossipMarks, button) end
    Mark(gossipMarks, button, true, id, ns.AfterText, button:GetFontString())
end

local greetingMarks = ns.Store()
local function MarkGreeting()
    for button in QuestFrameGreetingPanel.titleButtonPool:EnumerateActive() do
        local id
        if button.isActive == 1 then
            id = GetActiveQuestID(button:GetID())
        else
            id = select(5, GetAvailableQuestInfo(button:GetID()))
        end
        Mark(greetingMarks, button, true, id, ns.AfterText, button:GetFontString())
    end
end

-- host: the frame QuestInfo_Display draws the quest text into.
local detailMarks = ns.Store()
local function MarkDetail(host, isDetail)
    Mark(detailMarks, host, isDetail, isDetail and GetQuestID(), ns.AfterText, QuestInfoTitleHeader)
end

local givers = ns.List({
    key = "givers",
    box = function() return GossipFrame.GreetingPanel.ScrollBox end,
    store = gossipMarks,
    mark = MarkGossipButton,
})

local giversHooked = false
local function WatchGivers(on)
    if not on then
        ns.HideAll(greetingMarks)
        ns.HideAll(detailMarks)
        return
    end
    if not giversHooked then
        giversHooked = true
        -- The greeting rows are filled by the panel's OnShow, and again by a
        -- direct call on QUEST_LOG_UPDATE while it is shown.
        local function OnGreeting() if givers.state then MarkGreeting() end end
        QuestFrameGreetingPanel:HookScript("OnShow", OnGreeting)
        hooksecurefunc("QuestFrameGreetingPanel_OnShow", OnGreeting)
        -- The quest log's details share this display: the mark shows on the
        -- quest giver's text alone.
        hooksecurefunc("QuestInfo_Display", function(template, parent)
            if givers.state then MarkDetail(parent, template == QUEST_TEMPLATE_DETAIL) end
        end)
    end
    if QuestFrameGreetingPanel:IsShown() then MarkGreeting() end
    MarkDetail(QuestDetailScrollChildFrame, QuestFrameDetailPanel:IsShown())
end
givers.onWatch = WatchGivers

-------------------------------------------------------------------------------
--  Quest log: under each quest's track box, the title running up to it and
--  the quest's map icon filling the left margin.
-------------------------------------------------------------------------------
local logMarks = ns.Store()
local UnderBox = ns.Anchor("TOP", "BOTTOM", 0, -2)
local function MarkLog()
    for button in QuestScrollFrame.titleFramePool:EnumerateActive() do
        Mark(logMarks, button, true, button.questID, UnderBox, button.Checkbox)
    end
end

ns.Page({
    key = "log",
    store = logMarks,
    hook = function(redrawn) hooksecurefunc("QuestLogQuests_Update", redrawn) end,
    mark = MarkLog,
    now = MarkLog,
})
