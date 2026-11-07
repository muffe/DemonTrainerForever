local addonName, ns = ...
local L = ns.L

local ICON = "Interface\\Icons\\INV_Misc_Book_06"

-- Lowest level above the given one at which a shown demon has a grimoire to buy.
local function nextLevel(level)
    for _, entry in ipairs(ns.grimoires) do
        if entry.level > level and not ns.db.hidden[entry.family] and ns:Status(entry) == "open" then
            return entry.level
        end
    end
end

local function addTooltip(tooltip)
    tooltip:AddLine(L.TITLE)
    local level = ns:PlayerLevel()
    local count, cost = ns:OpenSummary(level)
    local nextAt = nextLevel(level)
    if count > 0 then
        tooltip:AddDoubleLine(L.NOW, string.format("%d (%s)", count, ns.Coins(cost)), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1, 1, 1)
    elseif nextAt then
        tooltip:AddDoubleLine(L.NEXT, L.LEVEL:format(nextAt), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1, 1, 1)
    end
    tooltip:AddLine(L.MINIMAP_HINT, GRAY_FONT_COLOR:GetRGB())
end

function ns.SetupMinimap()
    local launcher = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
        type = "launcher",
        text = L.TITLE,
        icon = ICON,
        OnClick = function() ns.ToggleWindow() end,
        OnTooltipShow = addTooltip,
    })
    ns.db.minimap = ns.db.minimap or {}
    LibStub("LibDBIcon-1.0"):Register(addonName, launcher, ns.db.minimap)
end

function ns.ToggleMinimapButton()
    local icon = LibStub("LibDBIcon-1.0")
    ns.db.minimap.hide = not ns.db.minimap.hide
    if ns.db.minimap.hide then
        icon:Hide(addonName)
        ns.Print(L.MINIMAP_HIDDEN)
    else
        icon:Show(addonName)
    end
end
