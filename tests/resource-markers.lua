local now, roster, sent = 10, { "Alon", "Mercy" }, {}
function GetTime() return now end
function GetNumRaidMembers() return 0 end
function GetNumPartyMembers() return table.getn(roster) end
function UnitName(unit) if unit == "player" then return "Alin" end return roster[tonumber(string.sub(unit, 6))] end
function UnitIsUnit() return false end
function UnitIsConnected() return true end
function SendAddonMessage(...) table.insert(sent, arg) end
function CreateFrame()
  local f = { shown = false }
  function f:RegisterEvent() end
  function f:SetScript() end
  function f:Hide() self.shown = false end
  function f:Show() self.shown = true end
  function f:SetWidth() end
  function f:SetHeight() end
  function f:SetFrameLevel() end
  function f:CreateTexture()
    return { SetAllPoints = function() end, SetTexture = function(self, value) self.value = value end }
  end
  function f:ClearAllPoints() end
  function f:SetPoint(a,b,c,x,y) self.x, self.y = x,y end
  return f
end
local selectedZone, playerX, playerY = 38, 0.5, 0.5
function GetPlayerMapPosition() return playerX, playerY end
function GetRealZoneText() return "Loch Modan" end
Minimap = { GetZoom = function() return 0 end, GetWidth = function() return 140 end,
  GetHeight = function() return 140 end, GetFrameLevel = function() return 1 end }
pfQuestCompat = {}
pfMap = { minimap_sizes = { [38] = {1000,1000} }, minimap_zoom = {[1]={[0]=300}},
  minimap_indoor = function() return 1 end, GetMapIDByName = function() return 38 end,
  GetMapID = function() return selectedZone end }
BotResourceIconsDB, SlashCmdList = {}, {}
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
dofile(arg[1] or "ResourceMarkers.lua")
local M = MangosbotResources
local function wanted(name, token) M.wanted[name] = token end
local function receive(body, sender, prefix) M.Receive(prefix or "RESBOT",body,"GUILD",sender or "Alin") end
local row = "17370383791809394007,1731,O,51.000,50.000"
local herb = "17370383791809394008,1617,H,50.000,51.000"
M.Poll(); assert(table.getn(sent)==1 and sent[1][1]=="RESBOT" and sent[1][3]=="PARTY")
wanted("Alon","1")
receive("S:1:1:Alon:38:1:2:"..row)
assert(not M.snapshots.Alon, "partial snapshot must not appear")
receive("S:1:1:Alon:38:2:2:"..herb)
assert(table.getn(M.VisibleNodes(38))==2)
wanted("Mercy","1"); receive("S:1:1:Mercy:38:1:1:"..row)
assert(table.getn(M.VisibleNodes(38))==2, "deduplicate the same GUID across bots")
M.Draw(); assert(M.pins[1].shown and M.pins[2].shown)
local foundEast = false
for _, pin in ipairs(M.pins) do if pin.x > 0 and pin.y == 0 then foundEast=true end end
assert(foundEast, "ore east of player must draw to the right")
selectedZone=12; M.Draw(); assert(not M.pins[1].shown, "other world-map selection must hide pins")
selectedZone=38; playerX=0; playerY=0; M.Draw()
assert(not M.pins[1].shown, "unsupported instance coordinates must hide pins")
playerX=0.5; playerY=0.5
M.pending={}; wanted("Alon","3")
receive("S:1:3:Alon:38:2:2:"..herb)
assert(M.snapshots.Alon.rows[1].guid=="17370383791809394007", "partial replacement preserves previous snapshot")
receive("S:1:3:Alon:38:1:2:"..row)
assert(table.getn(M.snapshots.Alon.rows)==2, "out of order pages assembled atomically")
BotResourceIconsDB.resourceMarkers="ore"; assert(table.getn(M.VisibleNodes(38))==1)
BotResourceIconsDB.resourceMarkers="herbs"; assert(table.getn(M.VisibleNodes(38))==1)
BotResourceIconsDB.resourceMarkers="both"
local original = M.snapshots.Alon
for _, body in ipairs({ "S:1:2:Alon:38:1:1:"..row,
  "S:1:1:Stranger:38:1:1:"..row, "S:1:1:Alon:38:17:17:"..row,
  "S:1:1:Alon:38:1:1:1,1731,O,nan,50.000", "S:1:1:Alon:38:1:1:1,1731,O,101.000,50.000",
  "S:1:1:Alon:38:1:1:"..row..";"..row }) do
  wanted("Alon","1"); M.pending={}; receive(body); assert(M.snapshots.Alon==original, body)
end
wanted("Alon","1"); receive("S:1:1:Alon:38:1:1:","Stranger"); assert(M.snapshots.Alon==original)
receive("S:1:1:Alon:38:1:1:","Alin","BOT"); assert(M.snapshots.Alon==original)
M.pending={}; receive("S:1:1:Alon:38:1:1:")
assert(table.getn(M.snapshots.Alon.rows)==0, "empty snapshot clears depleted nodes")
roster={"Alon"}; assert(table.getn(M.VisibleNodes(38))==0, "departed bot loses its markers")
roster={"Alon","Mercy"}; now=23; assert(table.getn(M.VisibleNodes(38))==0, "stale data expires")
BotResourceIconsDB.resourceMarkers="off"; M.Poll(); assert(not next(M.snapshots) and not next(M.wanted))
BotResourceIconsDB.resourceMarkers="both"; pfMap=nil; M.Poll(); assert(not next(M.wanted), "no requests without rendering support")
BotResourceIconsDB.resourceMarkers = {}; assert(M.Mode()=="both", "invalid saved setting uses safe default")
print("PASS: Lua 5.0 resource protocol, roster, TTL, depletion, filters, rendering and map-view isolation")
