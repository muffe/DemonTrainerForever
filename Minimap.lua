local addonName, ns = ...
local L = ns.L

local ICON = "Interface\\Icons\\INV_Misc_Book_06"

local function addTooltip(tooltip)
    tooltip:AddLine(L.TITLE)
    local count, cost = ns:OpenSummary(ns:PlayerLevel())
    local open = count > 0 and string.format("%d (%s)", count, ns.Coins(cost)) or "–"
    tooltip:AddDoubleLine(L.NOW, open, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1, 1, 1)
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
