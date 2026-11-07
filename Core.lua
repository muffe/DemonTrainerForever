local addonName, ns = ...
local L = ns.L

local PET_BANK = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet

local function petKnows(spellId)
    if PET_BANK and C_SpellBook and C_SpellBook.IsSpellInSpellBook then
        return C_SpellBook.IsSpellInSpellBook(spellId, PET_BANK, false)
    end
    return IsSpellKnown(spellId, true)
end

local function itemCount(itemId)
    if C_Item and C_Item.GetItemCount then return C_Item.GetItemCount(itemId) end
    return GetItemCount(itemId)
end

function ns.Coins(copper)
    return C_CurrencyInfo.GetCoinTextureString(copper)
end

function ns.Print(message)
    print("|cff9482c9Demon Trainer Forever:|r " .. message)
end

-- Runs fn once after delay, no matter how often it is requested in between.
local pending = {}
local function debounce(name, delay, fn)
    if pending[name] then return end
    pending[name] = true
    C_Timer.After(delay, function()
        pending[name] = nil
        fn()
    end)
end

-- UnitLevel can lag behind PLAYER_LEVEL_UP for a moment.
local levelOverride = 0
function ns:PlayerLevel()
    return math.max(UnitLevel("player"), levelOverride)
end

function ns:FamilyIcon(family)
    local spellId = ns.SUMMON_SPELLS[family]
    if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(spellId) end
    return GetSpellTexture(spellId)
end

local getSpellName = C_Spell and C_Spell.GetSpellName or GetSpellInfo
local getSpellSubtext = C_Spell and C_Spell.GetSpellSubtext or GetSpellSubtext

function ns:DisplayName(entry)
    local name, subtext = getSpellName(entry.spellId), getSpellSubtext(entry.spellId)
    if name then
        return (subtext and subtext ~= "") and string.format("%s (%s)", name, subtext) or name
    end
    return C_Item.GetItemNameByID(entry.itemId) or ("#" .. entry.itemId)
end

-- "learned": the pet knows it. "bags": bought but not used yet.
-- "unknown": this demon was never summoned with the addon running. "open": still has to be bought.
function ns:Status(entry)
    if self.db.learned[entry.key] then return "learned" end
    if itemCount(entry.itemId) > 0 then return "bags" end
    if not self.db.scanned[entry.family] then return "unknown" end
    return "open"
end

-- Open grimoires up to the given level that still require a trainer visit.
function ns:OpenSummary(level)
    local count, cost = 0, 0
    for _, entry in ipairs(ns.grimoires) do
        if entry.level <= level and not self.db.hidden[entry.family] and self:Status(entry) == "open" then
            count = count + 1
            cost = cost + entry.cost
        end
    end
    return count, cost
end

local function currentFamily()
    if not UnitExists("pet") then return nil end
    local guid = UnitGUID("pet")
    if not guid then return nil end
    local unitType, _, _, _, _, npcId = strsplit("-", guid)
    -- enslaved demons are "Creature" units and never learn grimoires
    if unitType ~= "Pet" then return nil end
    return ns.PET_NPC_IDS[tonumber(npcId)] or ns.db.lastSummon
end

-- The pet spellbook only reports the highest rank of an ability, so every lower rank counts as learned too.
function ns:Scan()
    local family = currentFamily()
    if not family then return end
    local changed = not self.db.scanned[family]
    self.db.scanned[family] = true
    for _, chain in pairs(ns.chains[family]) do
        for i = #chain, 1, -1 do
            if petKnows(chain[i].spellId) then
                for j = 1, i do
                    if not self.db.learned[chain[j].key] then
                        self.db.learned[chain[j].key] = true
                        changed = true
                    end
                end
                break
            end
        end
    end
    if changed then self:Refresh() end
end

function ns:Refresh()
    if ns.UpdateWindow then ns.UpdateWindow() end
end

local function requestData()
    for _, entry in ipairs(ns.grimoires) do
        if C_Spell and C_Spell.RequestLoadSpellData then C_Spell.RequestLoadSpellData(entry.spellId) end
        C_Item.RequestLoadItemDataByID(entry.itemId)
    end
end

local function noticeLogin()
    local count, cost = ns:OpenSummary(ns:PlayerLevel())
    if count > 0 then ns.Print(L.NOTICE_LOGIN:format(count, ns.Coins(cost)) .. " |cff808080/grim|r") end
end

local function noticeLevel(level)
    local new = 0
    for _, entry in ipairs(ns.grimoires) do
        if entry.level == level and not ns.db.hidden[entry.family] then new = new + 1 end
    end
    if new == 0 then return end
    local count, cost = ns:OpenSummary(level)
    ns.Print(L.NOTICE_LEVEL:format(new, count, ns.Coins(cost)) .. " |cff808080/grim|r")
end

local function scheduleScan()
    debounce("scan", 0.3, function() ns:Scan() end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= addonName then return end
        self:UnregisterEvent("ADDON_LOADED")
        if select(2, UnitClass("player")) ~= "WARLOCK" then return end
        local db = DemonTrainerForeverDB or {}
        DemonTrainerForeverDB = db
        db.learned = db.learned or {}
        db.scanned = db.scanned or {}
        db.hidden = db.hidden or {}
        db.collapsed = db.collapsed or {}
        ns.db = db
        ns.SetupMinimap()
        for _, name in ipairs({
            "PLAYER_ENTERING_WORLD", "UNIT_PET", "PET_BAR_UPDATE", "SPELLS_CHANGED",
            "UNIT_SPELLCAST_SUCCEEDED", "PLAYER_LEVEL_UP", "BAG_UPDATE_DELAYED", "PLAYER_MONEY",
            "SPELL_DATA_LOAD_RESULT", "ITEM_DATA_LOAD_RESULT",
        }) do
            self:RegisterEvent(name)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isLogin = ...
        scheduleScan()
        if isLogin then
            requestData()
            C_Timer.After(5, noticeLogin)
        end
    elseif event == "UNIT_PET" then
        if ... == "player" then scheduleScan() end
    elseif event == "PET_BAR_UPDATE" or event == "SPELLS_CHANGED" then
        scheduleScan()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellId = ...
        local family = unit == "player" and ns.SUMMON_TO_FAMILY[spellId]
        if family then
            ns.db.lastSummon = family
            scheduleScan()
        end
    elseif event == "PLAYER_LEVEL_UP" then
        local level = ...
        levelOverride = level
        ns:Refresh()
        noticeLevel(level)
    else
        debounce("refresh", 0.2, function() ns:Refresh() end)
    end
end)

function DemonTrainerForever_Toggle()
    if not ns.db then
        ns.Print(L.NOT_WARLOCK)
        return
    end
    ns.ToggleWindow()
end

SLASH_DEMONTRAINERFOREVER1 = "/grim"
SLASH_DEMONTRAINERFOREVER2 = "/demontrainer"
SlashCmdList.DEMONTRAINERFOREVER = function(message)
    if ns.db and strtrim(message or ""):lower() == "minimap" then
        ns.ToggleMinimapButton()
    else
        DemonTrainerForever_Toggle()
    end
end
