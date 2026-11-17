-------------------------------------------------------------------------------
--  Recipes.lua
--  New recipes, marked in the profession window's recipe list and in a
--  profession trainer's list. A recipe is original when its spell is in the
--  original game's list (Data/Recipes.lua). Recipe items get the item
--  tooltip's line (Items.lua).
-------------------------------------------------------------------------------
local _, ns = ...

local Mark = ns.Marker(ns.ORIGINAL_RECIPES)

-------------------------------------------------------------------------------
--  Profession window: after the recipe's name and its craftable count
-------------------------------------------------------------------------------
local windowMarks = ns.Store()
local function MarkRecipeRow(row, elementData)
    -- The list is a tree: a row's element data is a node holding its data.
    local info = elementData:GetData().recipeInfo
    -- The list also holds categories and dividers: only recipe rows are marked.
    if not info then return ns.Unmark(windowMarks, row) end
    Mark(windowMarks, row, true, info.recipeID, ns.AfterText, row.Count:IsShown() and row.Count or row.Label)
end

local function WindowBox()
    return ProfessionsFrame.CraftingPage.RecipeList.ScrollBox
end

-- On this event (a talent change) Blizzard redraws the rows' craftable counts
-- alone, without initializing them again: the marks follow on the next frame,
-- once the counts are drawn.
local COUNTS_REFRESHED = "ProfessionsRecipeListMixin.Event.RefreshCraftableCount"
local function RemarkWindow()
    WindowBox():ForEachFrame(MarkRecipeRow)
end
local function OnCountsRefreshed()
    RunNextFrame(RemarkWindow)
end

ns.List({
    key = "window",
    addon = "Blizzard_Professions",
    box = WindowBox,
    store = windowMarks,
    mark = MarkRecipeRow,
    onWatch = function(on)
        if on then
            EventRegistry:RegisterCallback(COUNTS_REFRESHED, OnCountsRefreshed, windowMarks)
        else
            EventRegistry:UnregisterCallback(COUNTS_REFRESHED, windowMarks)
        end
    end,
})

-------------------------------------------------------------------------------
--  Profession trainer: on the corner of the service's icon
-------------------------------------------------------------------------------
local trainerMarks = ns.Store()
local function MarkTrainerRow(button, elementData)
    local index = elementData:GetData().skillIndex
    -- Class trainers teach no recipes; categories have no service.
    local info = index and IsTradeskillTrainer() and C_TooltipInfo.GetTrainerService(index)
    if not (info and info.id) then return ns.Unmark(trainerMarks, button) end
    Mark(trainerMarks, button, true, info.id, ns.OnIcon, button.icon)
end

ns.List({
    key = "trainer",
    addon = "Blizzard_TrainerUI",
    box = function() return ClassTrainerFrame.ScrollBox end,
    store = trainerMarks,
    mark = MarkTrainerRow,
})
