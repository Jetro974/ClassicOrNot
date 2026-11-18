-------------------------------------------------------------------------------
--  Purchases.lua
--  What the account's characters buy with Merchant's Favor (the commission
--  merchants' plans and rewards): kept for the whole account
--  (ClassicOrNotDB.bought), shown on the item's tooltip ("Already bought by")
--  and as a check on the merchant's list.
--
--  A purchase counts once the item reaches the bags within a few seconds of
--  the click: a click the merchant refuses (not enough Favor, bags full) is
--  not one, and an item that comes later (mail, loot) is not mistaken for it.
--  Purchases made before the addon was installed, or with the option off,
--  are not known.
-------------------------------------------------------------------------------
local _, ns = ...
local L = ns.L

local FAVOR = 3402         -- Merchant's Favor (CurrencyTypes)
local WAIT = 5            -- seconds for a bought item to reach the bags
local me                  -- this character's GUID
local pending = {}        -- item ID -> { count before the click, time of the click }
local events = CreateFrame("Frame")

-- Bags, bank, reagent bank and warband bank: moving the item between them
-- is not a purchase.
local function Count(id)
    return C_Item.GetItemCount(id, true, false, true, true)
end

-- Whether the merchant's item at index costs Merchant's Favor (its cost
-- links to the currency).
local function CostsFavor(index)
    for i = 1, GetMerchantItemCostInfo(index) or 0 do
        local _, _, link = GetMerchantItemCostItem(index, i)
        if link and tonumber(link:match("currency:(%d+)")) == FAVOR then return true end
    end
    return false
end

-- ClassicOrNotDB.bought[itemID] = { [GUID] = true };
-- ClassicOrNotDB.chars[GUID] = { name = first name, class = class file }.
local function Store(key)
    local t = ClassicOrNotDB[key]
    if not t then
        t = {}
        ClassicOrNotDB[key] = t
    end
    return t
end

-- "Name, Name", by name, each in its class colour.
local function ByName(a, b) return a.name < b.name end
local function Buyers(who)
    local chars, list = Store("chars"), {}
    for guid in pairs(who) do
        if chars[guid] and chars[guid].name then list[#list + 1] = chars[guid] end
    end
    table.sort(list, ByName)
    for i, char in ipairs(list) do
        local color = C_ClassColor.GetClassColor(char.class)
        list[i] = color and color:WrapTextInColorCode(char.name) or char.name
    end
    return table.concat(list, ", ")
end

local MarkBought -- the merchant's list, below

-------------------------------------------------------------------------------
--  Recording
-------------------------------------------------------------------------------
local tooltipPlace = ns.Place({ key = "purchases" })

local function OnBuy(index)
    if not tooltipPlace.state or not me or not CostsFavor(index) then return end
    local id = GetMerchantItemID(index)
    if type(id) ~= "number" or issecretvalue(id) then return end
    -- Each click starts again from what the bags hold now.
    pending[id] = { Count(id), GetTime() }
    events:RegisterEvent("BAG_UPDATE_DELAYED")
end

local function OnBags()
    local bought, now = Store("bought"), GetTime()
    for id, click in pairs(pending) do
        if Count(id) > click[1] then
            bought[id] = bought[id] or {}
            bought[id][me] = true
            pending[id] = nil
            if MerchantFrame:IsShown() then MarkBought() end
        elseif now - click[2] > WAIT then
            -- Refused, or never in the bags: forgotten.
            pending[id] = nil
        end
    end
    if not next(pending) then events:UnregisterEvent("BAG_UPDATE_DELAYED") end
end

events:SetScript("OnEvent", function(_, event)
    if event == "BAG_UPDATE_DELAYED" then
        OnBags()
    else
        -- A new visit: clicks the last merchant refused are forgotten.
        wipe(pending)
        events:UnregisterEvent("BAG_UPDATE_DELAYED")
    end
end)

-------------------------------------------------------------------------------
--  Tooltip
-------------------------------------------------------------------------------
local function OnTooltip(tip, data)
    if not tooltipPlace.state or (tip ~= GameTooltip and tip ~= ItemRefTooltip) then return end
    local id = data and data.id
    if type(id) ~= "number" or issecretvalue(id) then return end
    local who = ClassicOrNotDB.bought and ClassicOrNotDB.bought[id]
    local names = who and Buyers(who)
    if names and names ~= "" then
        tip:AddLine(format(L.BOUGHT_BY, names), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    end
end

local hooked = false
tooltipPlace.on = function()
    if not hooked then
        hooked = true
        hooksecurefunc("BuyMerchantItem", OnBuy)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltip)
    end
    -- This character, as the tooltips name it.
    local guid, name = UnitGUID("player"), UnitName("player")
    if guid and name and not issecretvalue(guid) and not issecretvalue(name) then
        me = guid
        Store("chars")[guid] = { name = name, class = select(2, UnitClass("player")) }
    end
    events:RegisterEvent("MERCHANT_SHOW")
end
tooltipPlace.off = function()
    events:UnregisterAllEvents()
    wipe(pending)
end

-------------------------------------------------------------------------------
--  The merchant's list: a check at the bottom left of an item the account
--  has bought.
-------------------------------------------------------------------------------
local checks = ns.Store()

local function Check(button, show)
    local check = checks[button]
    if show and not check then
        check = CreateFrame("Frame", nil, button)
        check:SetSize(16, 16)
        check:SetPoint("BOTTOMLEFT", -3, -3)
        check:SetFrameLevel(button:GetFrameLevel() + 10)
        local t = check:CreateTexture(nil, "OVERLAY")
        t:SetAllPoints()
        t:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        checks[button] = check
    end
    if check then check:SetShown(show) end
end

function MarkBought()
    local bought = ClassicOrNotDB.bought or {}
    local merchant = MerchantFrame.selectedTab == 1
    for i = 1, math.max(MERCHANT_ITEMS_PER_PAGE, BUYBACK_ITEMS_PER_PAGE) do
        local button = _G["MerchantItem" .. i .. "ItemButton"]
        local id
        if merchant and i <= MERCHANT_ITEMS_PER_PAGE then
            local index = (MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE + i
            if index <= GetMerchantNumItems() then id = GetMerchantItemID(index) end
            if issecretvalue(id) then id = nil end
        end
        Check(button, id ~= nil and bought[id] ~= nil and next(bought[id]) ~= nil)
    end
end

ns.Page({
    key = "purchases",
    store = checks,
    hook = function(redrawn)
        hooksecurefunc("MerchantFrame_UpdateMerchantInfo", redrawn)
        hooksecurefunc("MerchantFrame_UpdateBuybackInfo", redrawn)
    end,
    mark = MarkBought,
    now = function()
        if MerchantFrame:IsShown() then MarkBought() end
    end,
})
