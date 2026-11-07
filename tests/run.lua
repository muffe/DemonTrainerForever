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
      elseif k == "Hide" then self._shown = false
      elseif k == "IsShown" then return self._shown
      elseif k == "SetScript" then self._scripts[a[1]] = a[2]
      elseif k == "RegisterEvent" then self._events[a[1]] = true
      elseif k == "UnregisterEvent" then self._events[a[1]] = nil
      elseif k == "CreateTexture" or k == "CreateFontString" then return obj(k)
      elseif k == "SetTextColor" then self._color = a
      elseif k == "GetName" then return self._name
      elseif k == "GetPoint" then return "CENTER", nil, "CENTER", 0, 0
      elseif k == "SetHeight" then self._h = a[1]
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
C_SpellBook = { IsSpellInSpellBook = function(id, bank) assert(bank == 1); return petSpells[id] == true end }
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
for _, file in ipairs({ "Locale.lua", "Data.lua", "Core.lua", "UI.lua", "Minimap.lua" }) do
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
      io.write(string.format("%-3s %-40s %s\n", f._h == 22 and "##" or "", f.left._text or "", f.right._text or ""))
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
SlashCmdList.DEMONTRAINERFOREVER(" Minimap ")
assert(iconShown == false and DemonTrainerForeverDB.minimap.hide == true)
SlashCmdList.DEMONTRAINERFOREVER("minimap")
assert(iconShown == true and not DemonTrainerForeverDB.minimap.hide)
local window = DemonTrainerForeverFrame
local wasShown = window:IsShown()
launcher.OnClick()
assert(window:IsShown() ~= wasShown)
print("OK")
