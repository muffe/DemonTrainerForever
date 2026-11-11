local _, ns = ...

-- Shared look of the addon's windows: flat charcoal panels, subtle borders, white text, warlock purple accent.

local WHITE = "Interface\\Buttons\\WHITE8X8"

local T = {
    background = { 0.08, 0.08, 0.085, 1 },
    border = { 1, 1, 1, 0.1 },
    accent = { 0.58, 0.51, 0.79, 1 },
    panel = { 1, 1, 1, 0.035 },
    highlight = { 1, 1, 1, 0.06 },
    divider = { 1, 1, 1, 0.08 },
    muted = { 0.6, 0.6, 0.6, 1 },
}
ns.Theme = T

-- string.upper only knows ASCII letters.
function ns.Upper(text)
    return (text:upper():gsub("ä", "Ä"):gsub("ö", "Ö"):gsub("ü", "Ü"))
end

function ns.SetBackdrop(frame, background, border)
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(unpack(background))
    frame:SetBackdropBorderColor(unpack(border))
end

function ns.AddHighlight(button)
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(unpack(T.highlight))
end

-- Horizontal line across the window, offset from its top (y < 0) or bottom (y > 0).
function ns.AddDivider(frame, y)
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(unpack(T.divider))
    line:SetHeight(1)
    local side = y < 0 and "TOP" or "BOTTOM"
    line:SetPoint(side .. "LEFT", 10, y)
    line:SetPoint(side .. "RIGHT", -10, y)
end

local function createCloseButton(frame)
    local close = CreateFrame("Button", nil, frame)
    close:SetSize(24, 24)
    close:SetPoint("TOPRIGHT", -6, -6)
    local lines = {}
    for _, angle in ipairs({ math.pi / 4, -math.pi / 4 }) do
        local line = close:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(0.6, 0.6, 0.6)
        line:SetSize(14, 2)
        line:SetPoint("CENTER")
        line:SetRotation(angle)
        table.insert(lines, line)
    end
    local function tint(value)
        for _, line in ipairs(lines) do line:SetColorTexture(value, value, value) end
    end
    close:SetScript("OnEnter", function() tint(1) end)
    close:SetScript("OnLeave", function() tint(0.6) end)
    close:SetScript("OnClick", function() frame:Hide() end)
    return close
end

function ns.CreateWindow(name, parent)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    frame:Hide()
    ns.SetBackdrop(frame, T.background, T.border)
    -- the backdrop alone lets frames behind it shine through
    local fill = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)
    fill:SetColorTexture(unpack(T.background))
    frame:EnableMouse(true)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOPLEFT", 16, -14)
    frame.title:SetPoint("RIGHT", -36, 0)
    frame.title:SetJustifyH("LEFT")
    frame.title:SetWordWrap(false)
    frame.close = createCloseButton(frame)
    return frame
end

local BUTTON_BORDER = { 1, 1, 1, 0.25 }

function ns.CreateButton(parent, text)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    ns.SetBackdrop(button, { 0, 0, 0, 0.3 }, BUTTON_BORDER)
    button:SetNormalFontObject(GameFontHighlight)
    button:SetText(text)
    button:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(1, 1, 1, 0.6) end)
    button:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(BUTTON_BORDER)) end)
    return button
end

-- Thin chevron that points right when collapsed and down when expanded.
function ns.CreateChevron(parent)
    local chevron = CreateFrame("Frame", nil, parent)
    chevron:SetSize(12, 12)
    chevron.lines = {}
    for i = 1, 2 do
        local line = chevron:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(unpack(T.muted))
        line:SetSize(7, 1.5)
        chevron.lines[i] = line
    end
    function chevron:SetExpanded(expanded)
        local a, b = self.lines[1], self.lines[2]
        a:ClearAllPoints()
        b:ClearAllPoints()
        if expanded then
            a:SetPoint("CENTER", -2, 0)
            a:SetRotation(-math.pi / 4)
            b:SetPoint("CENTER", 2, 0)
            b:SetRotation(math.pi / 4)
        else
            a:SetPoint("CENTER", 0, 2)
            a:SetRotation(-math.pi / 4)
            b:SetPoint("CENTER", 0, -2)
            b:SetRotation(math.pi / 4)
        end
    end
    return chevron
end

-- Scroll frame with a slim scroll bar that only shows when the content doesn't fit.
-- Lay out the content in scroll.content, then call scroll:SetContentHeight.
function ns.CreateScroll(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    scroll.content = content
    scroll:SetScript("OnSizeChanged", function(_, width) content:SetWidth(width) end)

    local bar = CreateFrame("Slider", nil, parent)
    bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 5, 0)
    bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 5, 0)
    bar:SetWidth(4)
    bar:SetOrientation("VERTICAL")
    bar:SetMinMaxValues(0, 0)
    bar:SetValue(0)
    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(1, 1, 1, 0.05)
    local thumb = bar:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(unpack(T.border))
    thumb:SetSize(4, 40)
    bar:SetThumbTexture(thumb)
    bar:SetScript("OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta) bar:SetValue(bar:GetValue() - delta * 40) end)

    function scroll:SetContentHeight(height)
        content:SetWidth(self:GetWidth())
        content:SetHeight(math.max(height, 1))
        local range = math.max(0, height - self:GetHeight())
        bar:SetMinMaxValues(0, range)
        bar:SetShown(range > 0)
        bar:SetValue(math.min(bar:GetValue(), range))
    end

    return scroll
end
