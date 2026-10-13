"""Run the actual addon with Lua 5.1 and mocked Vanilla frame/chat APIs."""
from pathlib import Path
import sys
from lupa.lua51 import LuaRuntime

root = Path(sys.argv[1])
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
frames = {}
SlashCmdList = {}
local methods = {}
function methods:SetWidth(v) self.width = v end
function methods:SetHeight(v) self.height = v end
function methods:GetWidth() return self.width or 200 end
function methods:GetHeight() return self.height or 20 end
function methods:GetStringWidth() return 100 end
function methods:SetPoint(...) self.point = arg end
function methods:SetText(v) self.textValue = v end
function methods:SetScript(k,v) self.scripts[k] = v end
function methods:Show() self.visible = true end
function methods:Hide() self.visible = false end
function methods:IsVisible() return self.visible end
function methods:GetName() return self.name end
function NewFrame(name)
    local f = {name=name, scripts={}, visible=false}
    setmetatable(f, {__index=function(_, k)
        if methods[k] then return methods[k] end
        if k == "CreateTexture" or k == "CreateFontString" then return function() return NewFrame() end end
        if string.find(k, "^[A-Z]") then return function() end end
        return nil
    end})
    if name then _G[name] = f end
    table.insert(frames, f)
    return f
end
function CreateFrame(_,name) return NewFrame(name) end
UIParent = NewFrame("UIParent")
DEFAULT_CHAT_FRAME = NewFrame()
GameTooltip = NewFrame()
RAID_CLASS_COLORS = {PRIEST={r=1,g=1,b=1}}
function getglobal(name) return _G[name] or NewFrame(name) end
function GetNumRaidMembers() return 0 end
function GetNumPartyMembers() return 1 end
function GetUnitName(unit) if unit == "target" then return "Mercy" else return "Leader" end end
function UnitName(unit) return GetUnitName(unit) end
function UnitClass() return "Priest", "PRIEST" end
function UnitExists() return true end
function UnitIsEnemy() return false end
function UnitIsPlayer() return true end
combat = false
function UnitAffectingCombat() return combat end
function GetTime() return 0 end
function GetNumQuestLogEntries() return 0 end
function UIDropDownMenu_Initialize() end
function UIDropDownMenu_SetWidth() end
function UIDropDownMenu_SetText() end
function UIDropDownMenu_JustifyText() end
function HideDropDownMenu() end
function GetLocale() return "enUS" end
function SendChatMessage(text, channel, _, target) sent = {text,channel,target} end
function SendAddonMessage(_,text,channel,target) sent = {text,channel,target} end
''')
# Compile every shipped Lua file. Execute localization before the addon.
for path in root.glob('*.lua'):
    lua.compile(path.read_text(encoding='utf-8-sig'), name=str(path))
lua.execute((root / 'Mangosbot_Localization.en.lua').read_text(encoding='utf-8-sig'))
lua.execute((root / 'Mangosbot.lua').read_text(encoding='utf-8-sig'))
lua.execute(r'''
function check(condition, message) assert(condition, message) end
OnWhisper("Combat Strategies: holy, offdps, dps assist", "Mercy")
check(botTable.Mercy.role == "heal", "holy healer role")
check(botTable.Mercy.strategy.co[1] == "holy", "prefix trimmed")
OnWhisper("Non Combat Strategies: follow, holy", "Mercy")
check(botTable.Mercy.strategy.nc[1] == "follow", "noncombat prefix")
check(botTable.Mercy.strategy.co[2] == "offdps", "separate engines")
OnWhisper("Reaction Strategies: holy", "Mercy")
OnWhisper("Dead Strategies: holy", "Mercy")
check(botTable.Mercy.strategy.react[1] == "holy", "reaction prefix")
check(botTable.Mercy.strategy.de[1] == "holy", "dead prefix")
OnWhisper("Combat Strategies: holy, protection", "Mercy")
check(botTable.Mercy.role == "tank", "tank precedence")
OnWhisper("Combat Strategies: shadow, offheal", "Mercy")
check(botTable.Mercy.role == "dps", "offhealer remains DPS")
OnWhisper("Combat Strategies: ", "Mercy")
check(table.getn(botTable.Mercy.strategy.co) == 0, "empty clears stale state")
OnWhisper("Strategies: nc, follow", "Mercy")
check(botTable.Mercy.strategy.nc[1] == "follow", "legacy noncombat")
OnWhisper("Strategies: heal", "Mercy")
check(botTable.Mercy.role == "heal", "legacy healer")
OnWhisper("Formation: near", "Mercy")
check(trim2(botTable.Mercy.formation) == "near", "other replies preserved")

-- Exercise the real event handler for both reply packet layouts.
local events
for _, f in ipairs(frames) do if f.scripts.OnEvent then events = f.scripts.OnEvent end end
check(events ~= nil, "event handler registered")
event = "CHAT_MSG_ADDON"
arg1, arg2, arg3, arg4 = "Combat Strategies: holy", "Mercy", nil, nil
events()
check(botTable.Mercy.strategy.co[1] == "holy", "Vanilla reply layout")
arg1, arg2, arg3, arg4 = "BOT", "Combat Strategies: discipline", "WHISPER", "Mercy"
events()
check(botTable.Mercy.strategy.co[1] == "discipline", "modern reply fallback")

-- Combat targets and late replies cannot reopen the automatic panel.
local queries = 0
local queryOriginal = QuerySelectedBot
QuerySelectedBot = function() queries = queries + 1 end
CurrentBot = nil
combat = false
event = "PLAYER_TARGET_CHANGED"
events()
check(queries == 1, "out-of-combat query retained")
SelectedBotPanel:Show()
combat = true
event = "PLAYER_REGEN_DISABLED"
events()
check(not SelectedBotPanel.visible, "combat entry hides automatic panel")
event = "PLAYER_TARGET_CHANGED"
events()
check(queries == 1, "combat targets do not query")
event = "CHAT_MSG_ADDON"
arg1, arg2, arg3, arg4 = "Combat Strategies: holy", "Mercy", nil, nil
events()
check(not SelectedBotPanel.visible, "late reply stays hidden")
check(botTable.Mercy.strategy.co[1] == "holy", "late reply still updates cached state")
CurrentBot = "Mercy"
events()
check(SelectedBotPanel.visible, "explicit roster selection works in combat")
event = "PLAYER_TARGET_CHANGED"
events()
check(CurrentBot == "Mercy" and SelectedBotPanel.visible, "combat targets preserve manual selection")
event = "PLAYER_REGEN_DISABLED"
events()
check(SelectedBotPanel.visible, "combat entry preserves manual panel")
CurrentBot = nil
combat = false
event = "CHAT_MSG_ADDON"
events()
check(SelectedBotPanel.visible, "automatic panel still works out of combat")
QuerySelectedBot = queryOriginal

-- Execute real button dispatch; preserve numeric command sequence order.
wait = function(_, fn, a, b) fn(a,b) end
CurrentBot = "Mercy"
ToolBarButtonOnClick(SelectedBotPanel.toolbar.CLASS_PRIEST.buttons.healer_only, false)
check(string.find(sent[1], "co +holy,-offdps,-offheal,?", 1, true) == 1, "healer-only first command")
check(string.find(sent[1], "react +holy,-offdps,-offheal,?", 1, true) ~= nil, "all four engines")
local co = string.find(sent[1], "co +", 1, true)
local nc = string.find(sent[1], "nc +", 1, true)
local de = string.find(sent[1], "de +", 1, true)
local react = string.find(sent[1], "react +", 1, true)
check(co < nc and nc < de and de < react, "ordered role commands")
check(sent[2] == "WHISPER" and sent[3] == "Mercy", "selected bot routing")
ToolBarButtonOnClick(SelectedBotPanel.toolbar.CLASS_PRIEST.buttons.healer_dps, false)
check(string.find(sent[1], "+holy,+offdps,-offheal", 1, true) ~= nil, "healer with DPS")
ToolBarButtonOnClick(SelectedBotPanel.toolbar.inventory.buttons.repair, false)
check(sent[1] == "repair", "repair dispatch")
ToolBarButtonOnClick(SelectedBotPanel.toolbar.attack_type.buttons.tank_assist, false)
check(string.find(sent[1], "-dps assist,+tank assist", 1, true) ~= nil, "mutually exclusive tank assist")
ToolBarButtonOnClick(SelectedBotPanel.toolbar.attack_type.buttons.dps_assist, false)
check(string.find(sent[1], "-tank assist,+dps assist", 1, true) ~= nil, "mutually exclusive DPS assist")

-- Exercise real roster rendering above its old ten-bot cap and then shrink it.
function RenderRoster(count)
    local names = {}
    for i=1,count do table.insert(names, "+Bot"..i.." Priest") end
    event, arg1 = "CHAT_MSG_SYSTEM", "Bot roster: "..table.concat(names, ", ")
    events()
    local visible = 0
    for _, item in pairs(BotRoster.items) do if item.visible then visible = visible + 1 end end
    check(visible == count, "all roster entries displayed: "..count)
    for _,item in pairs(BotRoster.items) do
        if item.visible then
            check(-item.point[5] + item:GetHeight() <= -BotRoster.toolbar.quickbar.point[5], "toolbar below bots")
        end
    end
end
RenderRoster(20)
RenderRoster(11)
RenderRoster(3)
''')
print('PASS: Lua 5.1 syntax, strategy replies, both chat layouts, combat panel guards, role controls, ordered dispatch, repair/assist and 20/11/3-bot roster rendering')
