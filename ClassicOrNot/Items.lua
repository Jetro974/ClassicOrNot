-------------------------------------------------------------------------------
--  Items.lua
--  A line on the tooltip of every item that is not from the original game
--  (Data/Items.lua): gear, recipes, mount and pet items, toys; and the mark
--  on new items at merchants. Hooks are set the first time their place is
--  on (hooks cannot be removed) and return at once while it is off.
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

-------------------------------------------------------------------------------
--  Merchants: the mark on new items, in the merchant's list, the buyback
--  list and the last item sold. Both lists are redrawn by a global function
--  of their own, which keeps nothing of the item on the button: the item is
--  read from the merchant, as Blizzard reads it.
-------------------------------------------------------------------------------
local MarkItem = ns.Marker(ORIGINAL_ITEMS)
local merchantMarks = ns.Store()
-- Top right of the item's icon.
local Corner = ns.Anchor("TOPRIGHT", "TOPRIGHT", 3, 3)

local function ItemOfLink(link)
    return link and C_Item.GetItemInfoInstant(link)
end

local function MarkMerchant()
    local buyback = MerchantFrame.selectedTab ~= 1
    for i = 1, buyback and BUYBACK_ITEMS_PER_PAGE or MERCHANT_ITEMS_PER_PAGE do
        local button = _G["MerchantItem" .. i .. "ItemButton"]
        local id
        if buyback then
            if i <= GetNumBuybackItems() then id = ItemOfLink(GetBuybackItemLink(i)) end
        else
            local index = (MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE + i
            if index <= GetMerchantNumItems() then id = GetMerchantItemID(index) end
        end
        MarkItem(merchantMarks, button, true, id, Corner, button)
    end
    local last = GetNumBuybackItems()
    local lastButton = MerchantBuyBackItemItemButton
    MarkItem(merchantMarks, lastButton, not buyback, last > 0 and ItemOfLink(GetBuybackItemLink(last)) or nil, Corner, lastButton)
end

ns.Page({
    key = "merchant",
    store = merchantMarks,
    hook = function(redrawn)
        hooksecurefunc("MerchantFrame_UpdateMerchantInfo", redrawn)
        hooksecurefunc("MerchantFrame_UpdateBuybackInfo", redrawn)
    end,
    mark = MarkMerchant,
    now = function()
        if MerchantFrame:IsShown() then MarkMerchant() end
    end,
})
