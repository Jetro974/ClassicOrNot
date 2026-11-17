-------------------------------------------------------------------------------
--  Items.lua
--  A line on the tooltip of every item that is not from the original game
--  (Data/Items.lua): gear, recipes, mount and pet items, toys. The tooltip
--  hook is set the first time the place is on (hooks cannot be removed) and
--  returns at once while it is off.
-------------------------------------------------------------------------------
local _, ns = ...

local ORIGINAL_ITEMS = ns.ORIGINAL_ITEMS
local line -- the tooltip's text, built once

local tooltip = ns.Place({ key = "tooltip" })

local function OnTooltip(tip, data)
    if not tooltip.state or (tip ~= GameTooltip and tip ~= ItemRefTooltip) then return end
    if not ns.IsNew(ORIGINAL_ITEMS, data and data.id) then return end
    if not line then
        line = CreateAtlasMarkup(ns.ATLAS, 18, 10, 0, 0,
            math.floor(ns.R * 255), math.floor(ns.G * 255), math.floor(ns.B * 255)) .. " " .. ns.L.NEW_ITEM
    end
    tip:AddLine(line, ns.R, ns.G, ns.B)
end

local hooked = false
tooltip.on = function()
    if hooked then return end
    hooked = true
    -- Toy box tooltips are toys, not items; both carry the item's ID.
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltip)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Toy, OnTooltip)
end
tooltip.off = function() end
