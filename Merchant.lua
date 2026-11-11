local _, ns = ...
local L = ns.L
local T = ns.Theme

-- At a merchant that sells grimoires this window covers the merchant frame. It lists the grimoires
-- the player can buy now that a demon still needs. The merchant button uncovers the normal merchant frame.

local HEADER, FOOTER = 44, 48
local CARD_HEIGHT, GAP = 52, 6
-- also covers the tabs below the merchant frame
local TABS_HEIGHT = 32
local STRATA_ABOVE = { BACKGROUND = "LOW", LOW = "MEDIUM", MEDIUM = "HIGH", HIGH = "DIALOG", DIALOG = "FULLSCREEN" }

local frame, scroll, empty, total
local cards = {}
local slots = {} -- itemId -> merchant slot
local showingMerchant = false

local function scanMerchant()
    slots = {}
    for i = 1, GetMerchantNumItems() do
        local itemId = GetMerchantItemID(i)
        if itemId and ns.byItem[itemId] then slots[itemId] = i end
    end
    return next(slots) ~= nil
end

-- The highest rank of each ability up to the player's level, if the demon still needs it.
-- Lower ranks are skipped because the pet learns the higher rank directly.
local function toBuy()
    local level = ns:PlayerLevel()
    local best = {}
    for _, abilities in pairs(ns.chains) do
        for _, chain in pairs(abilities) do
            local top
            for _, entry in ipairs(chain) do
                if entry.level <= level then top = entry end
            end
            if top then best[top] = true end
        end
    end
    local list = {}
    for _, entry in ipairs(ns.grimoires) do
        if best[entry] and slots[entry.itemId] and not ns.db.hidden[entry.family] and ns:Status(entry) == "open" then
            table.insert(list, entry)
        end
    end
    return list
end

-- Like at the merchant frame: right-click buys, left-click picks the grimoire up.
local function onCardClick(card, button)
    if IsModifiedClick() then
        local link = select(2, C_Item.GetItemInfo(card.entry.itemId))
        if link then HandleModifiedItemClick(link) end
    elseif button == "RightButton" then
        BuyMerchantItem(slots[card.entry.itemId], 1)
        -- until the bags update, so a double click doesn't buy twice
        card:Disable()
        card:SetAlpha(0.4)
    else
        PickupMerchantItem(slots[card.entry.itemId])
    end
end

local function onCardDrag(card)
    PickupMerchantItem(slots[card.entry.itemId])
end

local function onCardEnter(card)
    card:SetBackdropBorderColor(1, 1, 1, 0.3)
    GameTooltip:SetOwner(card, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(card.entry.itemId)
    GameTooltip:AddLine(L.FAMILY[card.entry.family], HIGHLIGHT_FONT_COLOR:GetRGB())
    GameTooltip:Show()
end

local function onCardLeave(card)
    card:SetBackdropBorderColor(unpack(T.border))
    GameTooltip:Hide()
end

local function acquireCard(index)
    local card = cards[index]
    if card then return card end
    card = CreateFrame("Button", nil, scroll.content, "BackdropTemplate")
    ns.SetBackdrop(card, T.panel, T.border)
    card:SetHeight(CARD_HEIGHT)
    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetPoint("LEFT", 8, 0)
    card.icon:SetSize(36, 36)
    card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    card.family = card:CreateTexture(nil, "ARTWORK")
    card.family:SetPoint("BOTTOMRIGHT", -6, 6)
    card.family:SetSize(16, 16)
    card.family:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    card.name = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    card.name:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 8, 0)
    card.name:SetPoint("RIGHT", -6, 0)
    card.name:SetJustifyH("LEFT")
    card.name:SetWordWrap(false)
    card.rank = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.rank:SetPoint("LEFT", card.icon, "RIGHT", 8, 0)
    card.rank:SetTextColor(unpack(T.muted))
    card.cost = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.cost:SetPoint("BOTTOMLEFT", card.icon, "BOTTOMRIGHT", 8, 0)
    ns.AddHighlight(card)
    card:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    card:RegisterForDrag("LeftButton")
    card:SetScript("OnClick", onCardClick)
    card:SetScript("OnDragStart", onCardDrag)
    card:SetScript("OnEnter", onCardEnter)
    card:SetScript("OnLeave", onCardLeave)
    cards[index] = card
    return card
end

local function render()
    local list, cost = toBuy(), 0
    local width = (scroll:GetWidth() - GAP) / 2
    for index, entry in ipairs(list) do
        local card = acquireCard(index)
        local column, line = (index - 1) % 2, math.floor((index - 1) / 2)
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", scroll.content, "TOPLEFT", column * (width + GAP), -line * (CARD_HEIGHT + GAP))
        card:SetWidth(width)
        card.entry = entry
        card:Enable()
        card:SetAlpha(1)
        card.icon:SetTexture(C_Item.GetItemIconByID(entry.itemId))
        card.family:SetTexture(ns:FamilyIcon(entry.family))
        local name, rank = ns:SpellText(entry)
        card.name:SetText(name)
        card.rank:SetText(rank or "")
        card.cost:SetText(ns.Coins(entry.cost))
        if GetMoney() < entry.cost then
            card.cost:SetTextColor(RED_FONT_COLOR:GetRGB())
        else
            card.cost:SetTextColor(1, 1, 1)
        end
        card:Show()
        cost = cost + entry.cost
    end
    for i = #list + 1, #cards do cards[i]:Hide() end
    scroll:SetContentHeight(math.ceil(#list / 2) * (CARD_HEIGHT + GAP) - GAP)
    empty:SetShown(#list == 0)
    total:SetText(#list > 0 and L.TOTAL:format(ns.Coins(cost)) or "")
    if GetMoney() < cost then
        total:SetTextColor(RED_FONT_COLOR:GetRGB())
    else
        total:SetTextColor(1, 1, 1)
    end
end

local function createFrame()
    frame = ns.CreateWindow("DemonTrainerForeverMerchant", MerchantFrame)
    frame:SetPoint("TOPLEFT")
    frame:SetPoint("BOTTOMRIGHT", 0, -TABS_HEIGHT)
    frame:SetScript("OnHide", function()
        -- the close button ends the visit, like closing the merchant frame does
        if MerchantFrame:IsShown() and not showingMerchant then CloseMerchant() end
    end)
    ns.AddDivider(frame, -HEADER)
    ns.AddDivider(frame, FOOTER)

    scroll = ns.CreateScroll(frame)
    scroll:SetPoint("TOPLEFT", 12, -(HEADER + 10))
    scroll:SetPoint("BOTTOMRIGHT", -20, FOOTER + 10)

    empty = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    empty:SetPoint("TOP", scroll, "TOP", 0, -24)
    empty:SetTextColor(unpack(T.muted))
    empty:SetText(L.NOTHING_TO_BUY)

    total = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    total:SetPoint("BOTTOMLEFT", 16, 18)

    local merchant = ns.CreateButton(frame, L.MERCHANT)
    merchant:SetSize(110, 26)
    merchant:SetPoint("BOTTOMRIGHT", -12, 11)
    merchant:SetScript("OnClick", function()
        showingMerchant = true
        frame:Hide()
    end)
end

function ns.MerchantShow()
    showingMerchant = not scanMerchant()
    if showingMerchant then
        if frame then frame:Hide() end
        return
    end
    if not frame then createFrame() end
    -- above the merchant frame, so none of its text shows through
    frame:SetFrameStrata(STRATA_ABOVE[MerchantFrame:GetFrameStrata()] or "HIGH")
    frame.title:SetText(UnitName("npc") or L.TITLE)
    frame:Show()
    render()
end

function ns.UpdateMerchant()
    if frame and frame:IsVisible() then render() end
end
