-------------------------------------------------------------------------------
--  Purchases.lua
--  What the account's characters buy from merchants for something other than
--  gold alone (Merchant's Favor at the commission merchants, Darkmoon
--  tickets, tokens): kept for the whole account (ClassicOrNotDB.bought), shown
--  on the item's tooltip ("Already bought by") and as a check on the
--  merchant's list.
--
--  A purchase counts once the item reaches the bags: a click the merchant
--  refuses (not enough currency, bags full) is not one. Purchases made before
--  the addon was installed are not known.
-------------------------------------------------------------------------------
local _, ns = ...
local L = ns.L

local me                  -- this character's GUID
local pending = {}        -- item ID -> its count (bags and bank) before the click
local events = CreateFrame("Frame")

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
        if chars[guid] then list[#list + 1] = chars[guid] end
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
    if not tooltipPlace.state or not me then return end
    -- Gold alone: not followed.
    if (GetMerchantItemCostInfo(index) or 0) == 0 then return end
    local id = GetMerchantItemID(index)
    if type(id) ~= "number" then return end
    if pending[id] == nil then pending[id] = C_Item.GetItemCount(id, true) end
    events:RegisterEvent("BAG_UPDATE_DELAYED")
end

local function OnBags()
    local bought = Store("bought")
    for id, before in pairs(pending) do
        if C_Item.GetItemCount(id, true) > before then
            bought[id] = bought[id] or {}
            bought[id][me] = true
            pending[id] = nil
            if MerchantFrame:IsShown() then MarkBought() end
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
    if who and next(who) then
        tip:AddLine(format(L.BOUGHT_BY, Buyers(who)), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
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
