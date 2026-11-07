local _, ns = ...
local L = ns.L

local WIDTH, HEIGHT = 340, 480
local CONTENT_WIDTH = WIDTH - 46
local HEADER_HEIGHT, ITEM_HEIGHT, SECTION_GAP = 22, 18, 6
-- Level sections further away than this start collapsed.
local EXPANDED_LEVELS = 6

local frame, content
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
    local now = { key = "now", title = L.NOW, color = GREEN_FONT_COLOR, items = {} }
    local learned = { key = "learned", title = L.LEARNED, color = GRAY_FONT_COLOR, items = {} }
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
                        color = entry.level <= level + 2 and NORMAL_FONT_COLOR or GRAY_FONT_COLOR,
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
    row = CreateFrame("Button", nil, content)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.right:SetPoint("RIGHT", -2, 0)
    row.right:SetJustifyH("RIGHT")
    row.left = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.left:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.left:SetPoint("RIGHT", row.right, "LEFT", -8, 0)
    row.left:SetJustifyH("LEFT")
    row.left:SetWordWrap(false)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row:SetScript("OnClick", onRowClick)
    row:SetScript("OnEnter", onRowEnter)
    row:SetScript("OnLeave", GameTooltip_Hide)
    rows[index] = row
    return row
end

local function placeRow(row, y, height, indent, iconSize)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
    row:SetPoint("RIGHT", content, "RIGHT")
    row:SetHeight(height)
    row.icon:ClearAllPoints()
    row.icon:SetPoint("LEFT", indent, 0)
    row.icon:SetSize(iconSize, iconSize)
    row:Show()
end

local function showHeader(row, section)
    row.section, row.item = section, nil
    row.icon:SetTexture(isCollapsed(section) and "Interface\\Buttons\\UI-PlusButton-Up"
        or "Interface\\Buttons\\UI-MinusButton-Up")
    row.icon:SetDesaturated(false)
    row.left:SetFontObject(GameFontNormal)
    row.left:SetText(section.title)
    row.left:SetTextColor(section.color:GetRGB())
    local text, cost = summary(section)
    row.right:SetText(text)
    row.right:SetTextColor((GetMoney() < cost and RED_FONT_COLOR or HIGHLIGHT_FONT_COLOR):GetRGB())
end

local function showItem(row, item)
    local entry, status = item.entry, item.status
    local muted = status == "learned" or status == "unknown"
    row.section, row.item = nil, item
    row.icon:SetTexture(ns:FamilyIcon(entry.family))
    row.icon:SetDesaturated(muted)
    row.left:SetFontObject(GameFontHighlightSmall)
    row.left:SetText(ns:DisplayName(entry))
    row.left:SetTextColor((muted and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR):GetRGB())
    if status == "learned" then
        row.right:SetText("")
    elseif status == "bags" then
        row.right:SetText(L.IN_BAGS)
        row.right:SetTextColor(GREEN_FONT_COLOR:GetRGB())
    else
        row.right:SetText(ns.Coins(entry.cost))
        local color = HIGHLIGHT_FONT_COLOR
        if muted then
            color = GRAY_FONT_COLOR
        elseif GetMoney() < entry.cost then
            color = RED_FONT_COLOR
        end
        row.right:SetTextColor(color:GetRGB())
    end
end

render = function()
    local y, count = 0, 0
    for index, section in ipairs(buildSections()) do
        if index > 1 then y = y + SECTION_GAP end
        count = count + 1
        local row = acquireRow(count)
        placeRow(row, y, HEADER_HEIGHT, 2, 14)
        showHeader(row, section)
        y = y + HEADER_HEIGHT
        if not isCollapsed(section) then
            for _, item in ipairs(section.items) do
                count = count + 1
                row = acquireRow(count)
                placeRow(row, y, ITEM_HEIGHT, 20, 16)
                showItem(row, item)
                y = y + ITEM_HEIGHT
            end
        end
    end
    for i = count + 1, #rows do rows[i]:Hide() end
    content:SetHeight(math.max(y, 1))
end

local function updateFamilyButtons()
    for family, button in pairs(familyButtons) do
        local hidden = ns.db.hidden[family] == true
        button.icon:SetDesaturated(hidden)
        button:SetAlpha(hidden and 0.4 or 1)
        button.unknown:SetShown(not ns.db.scanned[family] and ns:HasDemon(family))
    end
end

local function createFamilyButton(family, index)
    local button = CreateFrame("Button", nil, frame)
    button:SetSize(28, 28)
    button:SetPoint("TOPLEFT", frame, "TOPLEFT", 18 + (index - 1) * 34, -32)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexture(ns:FamilyIcon(family))
    button.unknown = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.unknown:SetPoint("BOTTOMRIGHT", -1, 2)
    button.unknown:SetText("?")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
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
    frame = CreateFrame("Frame", "DemonTrainerForeverFrame", UIParent, "UIPanelDialogTemplate")
    frame:Hide()
    frame:SetSize(WIDTH, HEIGHT)
    local point = ns.db.point
    if point then
        frame:SetPoint(point[1], UIParent, point[2], point[3], point[4])
    else
        frame:SetPoint("CENTER")
    end
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
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
    frame.Title:SetText(L.TITLE)
    tinsert(UISpecialFrames, frame:GetName())

    for index, family in ipairs(ns.FAMILIES) do
        createFamilyButton(family, index)
    end

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -70)
    scroll:SetPoint("BOTTOMRIGHT", -32, 14)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(CONTENT_WIDTH, 1)
    scroll:SetScrollChild(content)
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
