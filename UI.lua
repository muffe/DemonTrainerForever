local _, ns = ...
local L = ns.L
local T = ns.Theme

local WIDTH, HEIGHT = 360, 520
local HEADER_HEIGHT, ITEM_HEIGHT, ITEM_GAP, SECTION_GAP = 26, 22, 1, 8
-- Level sections further away than this start collapsed.
local EXPANDED_LEVELS = 6

local frame, scroll
local familyButtons = {}
local rows = {}

local function isCollapsed(section)
    local value = ns.db.collapsed[section.key]
    if value ~= nil then return value end
    if section.level then return section.level > ns:PlayerLevel() + EXPANDED_LEVELS end
    return section.key == "learned"
end

-- Sections: available now, one per upcoming level, learned.
local function buildSections()
    local level = ns:PlayerLevel()
    local now = { key = "now", title = L.NOW, color = T.accent, items = {} }
    local learned = { key = "learned", title = L.LEARNED, color = T.muted, items = {} }
    local sections, byLevel = {}, {}
    for _, entry in ipairs(ns.grimoires) do
        if not ns.db.hidden[entry.family] then
            local status = ns:Status(entry)
            local section
            if status == "learned" then
                section = learned
            elseif entry.level <= level then
                section = now
            else
                section = byLevel[entry.level]
                if not section then
                    section = {
                        key = "L" .. entry.level,
                        level = entry.level,
                        title = L.LEVEL:format(entry.level),
                        color = entry.level <= level + 2 and { 1, 1, 1, 1 } or T.muted,
                        items = {},
                    }
                    byLevel[entry.level] = section
                    table.insert(sections, section)
                end
            end
            table.insert(section.items, { entry = entry, status = status })
        end
    end
    if #now.items > 0 then table.insert(sections, 1, now) end
    if #learned.items > 0 then table.insert(sections, learned) end
    return sections
end

-- Count and cost of what still has to be bought at the trainer.
local function summary(section)
    if section.key == "learned" then return tostring(#section.items), 0 end
    local count, cost = 0, 0
    for _, item in ipairs(section.items) do
        if item.status == "open" then
            count = count + 1
            cost = cost + item.entry.cost
        end
    end
    if count == 0 then return "–", 0 end
    return count .. "  ·  " .. ns.Coins(cost), cost
end

local render

local function onRowClick(row)
    if row.item then
        local link = select(2, C_Item.GetItemInfo(row.item.entry.itemId))
        if link then HandleModifiedItemClick(link) end
        return
    end
    ns.db.collapsed[row.section.key] = not isCollapsed(row.section)
    render()
end

local function onRowEnter(row)
    if not row.item then return end
    local entry, status = row.item.entry, row.item.status
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(entry.itemId)
    GameTooltip:AddLine(L.FAMILY[entry.family], HIGHLIGHT_FONT_COLOR:GetRGB())
    if status == "unknown" then
        local hint = ns:HasDemon(entry.family) and L.UNKNOWN or L.NO_DEMON
        GameTooltip:AddLine(hint, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    end
    GameTooltip:Show()
end

local function acquireRow(index)
    local row = rows[index]
    if row then return row end
    row = CreateFrame("Button", nil, scroll.content)
    row.background = row:CreateTexture(nil, "BACKGROUND")
    row.background:SetAllPoints()
    row.background:SetColorTexture(unpack(T.panel))
    row.chevron = ns.CreateChevron(row)
    row.chevron:SetPoint("LEFT", 2, 0)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("LEFT", 8, 0)
    row.icon:SetSize(16, 16)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.right:SetPoint("RIGHT", -8, 0)
    row.right:SetJustifyH("RIGHT")
    row.left = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.left:SetJustifyH("LEFT")
    row.left:SetWordWrap(false)
    ns.AddHighlight(row)
    row:SetScript("OnClick", onRowClick)
    row:SetScript("OnEnter", onRowEnter)
    row:SetScript("OnLeave", GameTooltip_Hide)
    rows[index] = row
    return row
end

local function placeRow(row, y, height, anchor)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", scroll.content, "TOPLEFT", 0, -y)
    row:SetPoint("RIGHT", scroll.content, "RIGHT")
    row:SetHeight(height)
    row.left:ClearAllPoints()
    row.left:SetPoint("LEFT", anchor, "RIGHT", 6, 0)
    row.left:SetPoint("RIGHT", row.right, "LEFT", -8, 0)
    row:Show()
end

local function showHeader(row, section)
    row.section, row.item = section, nil
    row.expanded = not isCollapsed(section)
    row.background:Hide()
    row.icon:Hide()
    row.chevron:Show()
    row.chevron:SetExpanded(row.expanded)
    row.left:SetFontObject(GameFontNormalSmall)
    row.left:SetText(ns.Upper(section.title))
    row.left:SetTextColor(unpack(section.color))
    local text, cost = summary(section)
    row.right:SetText(text)
    if GetMoney() < cost then
        row.right:SetTextColor(RED_FONT_COLOR:GetRGB())
    else
        row.right:SetTextColor(unpack(T.muted))
    end
end

local function showItem(row, item)
    local entry, status = item.entry, item.status
    local muted = status == "learned" or status == "unknown"
    row.section, row.item = nil, item
    row.background:Show()
    row.chevron:Hide()
    row.icon:Show()
    row.icon:SetTexture(ns:FamilyIcon(entry.family))
    row.icon:SetDesaturated(muted)
    row.left:SetFontObject(GameFontHighlight)
    row.left:SetText(ns:DisplayName(entry))
    if muted then
        row.left:SetTextColor(unpack(T.muted))
    else
        row.left:SetTextColor(1, 1, 1)
    end
    if status == "learned" then
        row.right:SetText("")
    elseif status == "bags" then
        row.right:SetText(L.IN_BAGS)
        row.right:SetTextColor(unpack(T.accent))
    else
        row.right:SetText(ns.Coins(entry.cost))
        if muted then
            row.right:SetTextColor(unpack(T.muted))
        elseif GetMoney() < entry.cost then
            row.right:SetTextColor(RED_FONT_COLOR:GetRGB())
        else
            row.right:SetTextColor(1, 1, 1)
        end
    end
end

render = function()
    local y, count = 0, 0
    for index, section in ipairs(buildSections()) do
        if index > 1 then y = y + SECTION_GAP end
        count = count + 1
        local row = acquireRow(count)
        placeRow(row, y, HEADER_HEIGHT, row.chevron)
        showHeader(row, section)
        y = y + HEADER_HEIGHT
        if not isCollapsed(section) then
            for _, item in ipairs(section.items) do
                count = count + 1
                row = acquireRow(count)
                placeRow(row, y, ITEM_HEIGHT, row.icon)
                showItem(row, item)
                y = y + ITEM_HEIGHT + ITEM_GAP
            end
        end
    end
    for i = count + 1, #rows do rows[i]:Hide() end
    scroll:SetContentHeight(y)
end

local function updateFamilyButtons()
    for family, button in pairs(familyButtons) do
        local hidden = ns.db.hidden[family] == true
        button.icon:SetDesaturated(hidden)
        button:SetAlpha(hidden and 0.35 or 1)
        button:SetBackdropBorderColor(unpack(hidden and T.border or T.accent))
        button.unknown:SetShown(not ns.db.scanned[family] and ns:HasDemon(family))
    end
end

local function createFamilyButton(family, index)
    local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
    button:SetSize(32, 32)
    button:SetPoint("TOPLEFT", frame, "TOPLEFT", 16 + (index - 1) * 40, -46)
    ns.SetBackdrop(button, { 0, 0, 0, 0.3 }, T.border)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 2, -2)
    button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon:SetTexture(ns:FamilyIcon(family))
    button.unknown = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.unknown:SetPoint("BOTTOMRIGHT", -2, 3)
    button.unknown:SetText("?")
    ns.AddHighlight(button)
    button:SetScript("OnClick", function()
        ns.db.hidden[family] = not ns.db.hidden[family] or nil
        ns.UpdateWindow()
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.FAMILY[family])
        local status = ns.db.scanned[family] and L.SCANNED or ns:HasDemon(family) and L.UNKNOWN or L.NO_DEMON
        GameTooltip:AddLine(status, 1, 1, 1, true)
        GameTooltip:AddLine(ns.db.hidden[family] and L.CLICK_SHOW or L.CLICK_HIDE, GRAY_FONT_COLOR:GetRGB())
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    familyButtons[family] = button
end

local function createFrame()
    frame = ns.CreateWindow("DemonTrainerForeverFrame", UIParent)
    frame:SetSize(WIDTH, HEIGHT)
    local point = ns.db.point
    if point then
        frame:SetPoint(point[1], UIParent, point[2], point[3], point[4])
    else
        frame:SetPoint("CENTER")
    end
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, relativePoint, x, y = self:GetPoint()
        ns.db.point = { p, relativePoint, x, y }
    end)
    frame:SetScript("OnShow", function()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
        ns.UpdateWindow()
    end)
    frame:SetScript("OnHide", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE) end)
    frame.title:SetText(L.TITLE)
    tinsert(UISpecialFrames, frame:GetName())

    for index, family in ipairs(ns.FAMILIES) do
        createFamilyButton(family, index)
    end
    ns.AddDivider(frame, -90)

    scroll = ns.CreateScroll(frame)
    scroll:SetPoint("TOPLEFT", 12, -98)
    scroll:SetPoint("BOTTOMRIGHT", -20, 12)
end

function ns.UpdateWindow()
    if not frame or not frame:IsShown() then return end
    updateFamilyButtons()
    render()
end

function ns.ToggleWindow()
    if not frame then createFrame() end
    frame:SetShown(not frame:IsShown())
end
