local dir = arg[1] or (arg[0]:match("^(.*)/tests/[^/]*$") or ".")
local frames, timers = {}, {}
local function obj(kind)
  local o = { _kind = kind, _shown = kind ~= "Frame_hidden", _scripts = {}, _events = {} }
  return setmetatable(o, { __index = function(t, k)
    return function(self, ...)
      local a = {...}
      if k == "SetText" then self._text = a[1]
      elseif k == "GetText" then return self._text
      elseif k == "SetShown" then self._shown = a[1] and true or false; if a[1] and self._scripts.OnShow then self._scripts.OnShow(self) end
      elseif k == "Show" then local was=self._shown; self._shown = true; if not was and self._scripts.OnShow then self._scripts.OnShow(self) end
      elseif k == "Hide" then local was=self._shown; self._shown = false; if was and self._scripts.OnHide then self._scripts.OnHide(self) end
      elseif k == "IsShown" or k == "IsVisible" then return self._shown
      elseif k == "GetFrameLevel" then return 1
      elseif k == "GetWidth" or k == "GetHeight" then return 300
      elseif k == "GetValue" then return 0
      elseif k == "GetFrameStrata" then return "MEDIUM"
      elseif k == "SetScript" then self._scripts[a[1]] = a[2]
      elseif k == "RegisterEvent" then self._events[a[1]] = true
      elseif k == "UnregisterEvent" then self._events[a[1]] = nil
      elseif k == "CreateTexture" or k == "CreateFontString" then return obj(k)
      elseif k == "SetTextColor" then self._color = a
      elseif k == "GetName" then return self._name
      elseif k == "GetPoint" then return "CENTER", nil, "CENTER", 0, 0
      elseif k == "SetHeight" then self._h = a[1]
      elseif k == "SetTexture" then self._tex = a[1]
      end
    end
  end })
end
function CreateFrame(kind, name, parent, template)
  local f = obj(kind); f._name = name; f.Title = obj("FontString")
  table.insert(frames, f); if name then _G[name] = f end
  return f
end
local function fire(event, ...)
  for _, f in ipairs(frames) do if f._events[event] and f._scripts.OnEvent then f._scripts.OnEvent(f, event, ...) end end
end
local function runTimers()
  while #timers > 0 do local t = timers; timers = {}; for _, fn in ipairs(t) do fn() end end
end
C_Timer = { After = function(_, fn) table.insert(timers, fn) end }
Enum = { SpellBookSpellBank = { Pet = 1 } }
local petSpells = {}
local playerSpells = { [688] = true, [697] = true, [712] = true, [713] = true } -- no Felhunter yet
C_SpellBook = { IsSpellInSpellBook = function(id, bank) assert(bank == 1); return petSpells[id] == true end,
  IsSpellKnown = function(id) return playerSpells[id] == true end }
local bags = {}
C_Item = { GetItemCount = function(id) return bags[id] or 0 end, GetItemNameByID = function(id) return "Item"..id end, RequestLoadItemDataByID = function() end }
C_Spell = { GetSpellName = function(id) return "Spell"..id end, GetSpellSubtext = function(id) return "Rang ?" end,
  GetSpellTexture = function(id) return id end, RequestLoadSpellData = function() end }
C_CurrencyInfo = { GetCoinTextureString = function(c) return string.format("%dg%ds%dc", c/10000, (c%10000)/100, c%100) end }
local level, pet = 30, nil
function UnitLevel() return level end
function UnitClass() return "Hexenmeister", "WARLOCK" end
function UnitExists(u) return u == "pet" and pet ~= nil end
function UnitGUID(u) return pet end
function GetLocale() return "deDE" end
function GetMoney() return 30000 end
function strsplit(sep, s) local r = {}; for p in (s..sep):gmatch("(.-)"..sep) do r[#r+1] = p end; return unpack(r) end
local printed = {}
function print(s) table.insert(printed, s); io.write("PRINT: ", s, "\n") end
local function color(r,g,b) return { r=r,g=g,b=b, GetRGB=function(self) return self.r,self.g,self.b end } end
GREEN_FONT_COLOR, GRAY_FONT_COLOR, NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR, RED_FONT_COLOR =
  color(0,1,0), color(.5,.5,.5), color(1,.8,0), color(1,1,1), color(1,0,0)
UIParent = obj("Frame"); UISpecialFrames = {}; GameTooltip = obj("Tooltip"); GameTooltip_Hide = function() end
GameFontNormal, GameFontHighlightSmall = {}, {}
SlashCmdList = {}
tinsert = table.insert
SOUNDKIT = {}; function PlaySound() end
local linked
function HandleModifiedItemClick(link) linked = link end
C_Item.GetItemInfo = function(id) return "Item"..id, "[Item"..id.."]" end
GameFontDisable, GameFontHighlight, GameFontHighlightLarge, GameFontNormalSmall = {}, {}, {}, {}
function UnitName() return "Kurgul" end
C_Item.GetItemIconByID = function(id) return id end
function IsModifiedClick() return false end

-- merchant stubs
local merchantItems, bought, merchantClosed = {}, {}, false
MerchantFrame = obj("Frame")
function GetMerchantNumItems() return #merchantItems end
function GetMerchantItemID(i) return merchantItems[i] end
function BuyMerchantItem(i, n) table.insert(bought, { merchantItems[i], n }) end
local pickedUp
function PickupMerchantItem(i) pickedUp = merchantItems[i] end
function CloseMerchant() merchantClosed = true end


-- LibDataBroker / LibDBIcon stubs
local launcher, iconDb, iconShown = nil, nil, nil
local libs = {
  ["LibDataBroker-1.1"] = { NewDataObject = function(_, name, obj) launcher = obj; return obj end },
  ["LibDBIcon-1.0"] = {
    Register = function(_, name, obj, db) iconDb = db; iconShown = not db.hide end,
    Hide = function() iconShown = false end,
    Show = function() iconShown = true end,
  },
}
function LibStub(name) return assert(libs[name], name) end
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
local tooltipLines = {}
local fakeTooltip = {
  AddLine = function(_, text) table.insert(tooltipLines, text) end,
  AddDoubleLine = function(_, left, right) table.insert(tooltipLines, left .. " = " .. right) end,
}

local ns = {}
for _, file in ipairs({ "Locale.lua", "Data.lua", "Core.lua", "Widgets.lua", "UI.lua", "Merchant.lua", "Minimap.lua" }) do
  assert(loadfile(dir .. "/" .. file))("DemonTrainerForever", ns)
end

-- data sanity
assert(#ns.grimoires == 59 + 11, "entries: " .. #ns.grimoires)
for i = 2, #ns.grimoires do assert(ns.grimoires[i-1].level <= ns.grimoires[i].level) end

fire("ADDON_LOADED", "DemonTrainerForever")
fire("PLAYER_ENTERING_WORLD", true, false)
runTimers()
assert(#printed == 0, "no notice expected while nothing is scanned")

-- summon imp that knows Firebolt r4 (lvl28), Blood Pact r3 (lvl26), Phase Shift, Fire Shield r2
pet = "Pet-0-1-1-1-416-0000"
petSpells = { [7801] = true, [7805] = true, [4511] = true, [8316] = true }
fire("UNIT_PET", "player"); runTimers()
local db = DemonTrainerForeverDB
assert(db.scanned.Imp and not db.scanned.Voidwalker)
for _, k in ipairs({ "Imp:16302", "Imp:16316", "Imp:16317", "Imp:16321", "Imp:16322", "Imp:16323", "Imp:16331", "Imp:16326", "Imp:16327" }) do
  assert(db.learned[k], "should be learned: " .. k)
end
assert(not db.learned["Imp:16318"])

-- enslaved demon must not count as a scan
pet = "Creature-0-1-1-1-1234-0000"; db.lastSummon = "Felhunter"
fire("UNIT_PET", "player"); runTimers()
assert(not db.scanned.Felhunter)

-- a summoned demon with a "Creature" GUID still counts by its npc id
pet = "Creature-0-1-1-1-1860-0000"; petSpells = {}
fire("UNIT_PET", "player"); runTimers()
assert(db.scanned.Voidwalker)
db.scanned.Voidwalker = nil

-- summon succubus via spell; npc id unknown -> falls back to last summon
pet = "Pet-0-1-1-1-999999-0000"; petSpells = { [6360] = true }
fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 712); runTimers()
assert(db.scanned.Succubus and db.learned["Succubus:16375"] and not db.learned["Incubus:16375"])
db.hidden.Incubus = true
bags[16357] = 1 -- Consume Shadows r1 in bags

SlashCmdList.DEMONTRAINERFOREVER("")
local function dump()
  for _, f in ipairs(frames) do
    if f._kind == "Button" and rawget(f, "left") and f._shown then
      io.write(string.format("%-3s %-40s %s\n", f._h == 26 and "##" or "", f.left._text or "", f.right._text or ""))
    end
  end
end
dump()
print("--- level up to 32")
level = 32
fire("PLAYER_LEVEL_UP", 32); runTimers()
fire("PLAYER_ENTERING_WORLD", true, false); runTimers()

-- minimap button
assert(launcher and iconShown and iconDb == DemonTrainerForeverDB.minimap)
launcher.OnTooltipShow(fakeTooltip)
assert(tooltipLines[2] == "Jetzt verfügbar = 3 (1g60s0c)", tooltipLines[2])
-- nothing open at the current level: show the next level instead of an empty "available now"
local learnedBefore = {}
for k, v in pairs(db.learned) do learnedBefore[k] = v end
for _, entry in ipairs(ns.grimoires) do
  if entry.level <= 32 then db.learned[entry.key] = true end
end
tooltipLines = {}
launcher.OnTooltipShow(fakeTooltip)
assert(tooltipLines[2] == "Nächste Grimoires = Stufe 34", tooltipLines[2])
local function headerShown(text)
  for _, f in ipairs(frames) do
    if f._kind == "Button" and rawget(f, "section") and f._shown and f.left._text == text then return true end
  end
end
ns.UpdateWindow()
assert(not headerShown("JETZT VERFÜGBAR"), "empty 'available now' section must be hidden")
db.learned = learnedBefore
SlashCmdList.DEMONTRAINERFOREVER(" Minimap ")
assert(iconShown == false and DemonTrainerForeverDB.minimap.hide == true)
SlashCmdList.DEMONTRAINERFOREVER("minimap")
assert(iconShown == true and not DemonTrainerForeverDB.minimap.hide)
-- demons the warlock can't summon yet
assert(ns:HasDemon("Voidwalker") and not ns:HasDemon("Felhunter"))
playerSpells[691] = true
assert(ns:HasDemon("Felhunter"))

-- level sections more than 6 levels away start collapsed (player is 32)
ns.UpdateWindow()
local function headerExpanded(text)
  for _, f in ipairs(frames) do
    if f._kind == "Button" and rawget(f, "section") and f._shown and f.left._text == text then return f.expanded end
  end
end
assert(headerExpanded("STUFE 38") == true)
assert(headerExpanded("STUFE 40") == false)

-- shift-click on a grimoire row links it in chat
for _, f in ipairs(frames) do
  if f._kind == "Button" and f._shown and rawget(f, "item") then f._scripts.OnClick(f); break end
end
assert(linked and linked:match("^%[Item%d+%]$"), tostring(linked))
local window = DemonTrainerForeverFrame
local wasShown = window:IsShown()
launcher.OnClick()
assert(window:IsShown() ~= wasShown)

-- a merchant without grimoires keeps the normal merchant frame
merchantItems = { 159 }
fire("MERCHANT_SHOW"); runTimers()
assert(not DemonTrainerForeverMerchant)

-- at the demon trainer the grimoire window covers it (player is 32)
db.hidden.Incubus = nil
db.scanned.Incubus = true
for _, entry in ipairs(ns.grimoires) do table.insert(merchantItems, entry.itemId) end
local function merchantRows()
  local list = {}
  for _, f in ipairs(frames) do
    if f._kind == "Button" and f._shown and rawget(f, "entry") then table.insert(list, f) end
  end
  return list
end
local function shownKeys()
  local keys = {}
  for _, row in ipairs(merchantRows()) do keys[#keys + 1] = row.entry.key end
  table.sort(keys)
  return table.concat(keys, " ")
end
fire("MERCHANT_SHOW"); runTimers()
local merchantWindow = DemonTrainerForeverMerchant
assert(merchantWindow:IsShown())
-- Imp knows everything up to 32. Only the highest rank per ability is offered: Lash of Pain r2 (16368), not r1.
-- Soothing Kiss r1 (16375) is learned by the Succubus only.
assert(shownKeys() == "Incubus:16368 Incubus:16375 Incubus:16379 Incubus:16380 Succubus:16368 Succubus:16379 Succubus:16380", shownKeys())

-- like at the merchant frame, left-click picks a grimoire up and right-click buys it from the right merchant slot
local seduction
for _, row in ipairs(merchantRows()) do if row.entry.key == "Succubus:16379" then seduction = row end end
seduction._scripts.OnClick(seduction, "LeftButton")
assert(pickedUp == 16379 and #bought == 0)
seduction._scripts.OnClick(seduction, "RightButton")
assert(#bought == 1 and bought[1][1] == 16379 and bought[1][2] == 1)

-- one Seduction grimoire in the bags covers only one of the two demons
bags[16379] = 1
fire("BAG_UPDATE_DELAYED"); runTimers()
assert(shownKeys() == "Incubus:16368 Incubus:16375 Incubus:16379 Incubus:16380 Succubus:16368 Succubus:16380", shownKeys())
bags[16379] = 2
fire("BAG_UPDATE_DELAYED"); runTimers()
assert(not shownKeys():find("16379"), shownKeys())

-- the merchant button uncovers the normal merchant frame without ending the visit
for _, f in ipairs(frames) do
  if f._kind == "Button" and f._text == "Händler" then f._scripts.OnClick(f) end
end
assert(not merchantWindow:IsShown() and not merchantClosed)

-- closing the window ends the visit
fire("MERCHANT_SHOW"); runTimers()
assert(merchantWindow:IsShown())
merchantWindow:Hide()
assert(merchantClosed)

-- a later merchant without grimoires stays open
merchantClosed = false
fire("MERCHANT_SHOW"); runTimers()
merchantItems = { 159 }
fire("MERCHANT_SHOW"); runTimers()
assert(not merchantWindow:IsShown() and not merchantClosed)
print("OK")
