-- WoW 1.12 / Lua 5.0. Resource data comes from the controlled bots, not chat.
if MangosbotResources then return end -- Avoid duplicate polling if both packages are enabled.
MangosbotResources = { snapshots = {}, pending = {}, pins = {}, wanted = {} }
local M = MangosbotResources
local token, nextPoll, nextDraw = math.mod(math.floor(GetTime() * 1000), 1000000000) + 1, 0, 0
local signature = ""
local textures = { O = "Interface\\Icons\\INV_Ore_Copper_01", H = "Interface\\Icons\\INV_Misc_Herb_01" }

local function Split(text, delimiter)
  local result, start = {}, 1
  while true do
    local first, last = string.find(text, delimiter, start, true)
    if not first then table.insert(result, string.sub(text, start)); return result end
    table.insert(result, string.sub(text, start, first - 1)); start = last + 1
  end
end
local function Integer(text, maximum)
  if not text or not string.find(text, "^%d+$") or string.len(text) > 10 then return nil end
  local value = tonumber(text)
  if not value or value > maximum then return nil end
  return value
end
local function Coordinate(text)
  if not text or not string.find(text, "^%d+%.%d%d%d$") or string.len(text) > 7 then return nil end
  local value = tonumber(text)
  if value and value <= 100 then return value end
end
function M.Mode()
  local mode = BotResourceIconsDB and BotResourceIconsDB.resourceMarkers
  if mode == "both" or mode == "ore" or mode == "herbs" or mode == "off" then return mode end
  return "both"
end
function M.Clear()
  M.snapshots, M.pending, M.wanted = {}, {}, {}
  for _, pin in ipairs(M.pins) do pin:Hide() end
end
function M.Roster()
  local roster, names = {}, {}
  local raid = GetNumRaidMembers() > 0
  for i = 1, (raid and GetNumRaidMembers() or GetNumPartyMembers()) do
    local unit = (raid and "raid" or "party") .. i
    local name = UnitName(unit)
    if name and name ~= "Unknown" and not UnitIsUnit(unit, "player") and UnitIsConnected(unit) then
      roster[name] = true; table.insert(names, name)
    end
  end
  table.sort(names)
  return roster, table.concat(names, ",")
end
function M.Receive(prefix, body, channel, sender)
  -- Native direct AddOn packets identify the recipient as their sender.
  if prefix ~= "RESBOT" or sender ~= UnitName("player") or channel ~= "GUILD" or
      M.Mode() == "off" or type(body) ~= "string" or string.len(body) > 240 then return end
  local f = Split(body, ":")
  if table.getn(f) ~= 8 or f[1] ~= "S" or f[2] ~= "1" then return end
  local part, total, zone = Integer(f[6], 16), Integer(f[7], 16), Integer(f[5], 4294967295)
  local roster = M.Roster()
  if not part or not total or part < 1 or total < 1 or part > total or not zone or
      not roster[f[4]] or M.wanted[f[4]] ~= f[3] then return end
  local p = M.pending[f[4]]
  if not p then p = { token = f[3], zone = zone, total = total, parts = {} }; M.pending[f[4]] = p end
  if p.token ~= f[3] or p.zone ~= zone or p.total ~= total then return end
  if p.parts[part] and p.parts[part] ~= f[8] then M.pending[f[4]] = nil; return end
  p.parts[part] = f[8]
  local rows, seen = {}, {}
  for i = 1, total do if p.parts[i] == nil then return end end
  for i = 1, total do
    if p.parts[i] ~= "" then
      local page = Split(p.parts[i], ";")
      if table.getn(page) > 2 then M.pending[f[4]] = nil; return end
      for _, raw in ipairs(page) do
        local row = Split(raw, ",")
        local entry, x, y = Integer(row[2], 4294967295), Coordinate(row[4]), Coordinate(row[5])
        -- GUIDs stay strings: their 64 bits do not fit a Lua number exactly.
        if table.getn(row) ~= 5 or not string.find(row[1], "^%d+$") or string.len(row[1]) > 20 or
            seen[row[1]] or not entry or entry == 0 or not textures[row[3]] or not x or not y then
          M.pending[f[4]] = nil; return
        end
        seen[row[1]] = true
        table.insert(rows, { guid = row[1], entry = entry, kind = row[3], x = x, y = y })
      end
    end
  end
  M.snapshots[f[4]] = { zone = zone, rows = rows, expires = GetTime() + 12 }
  M.pending[f[4]], M.wanted[f[4]] = nil, nil
end
function M.Available()
  return pfMap and pfMap.minimap_sizes and pfMap.minimap_zoom and pfMap.minimap_indoor and
    pfMap.GetMapIDByName and Minimap and pfQuestCompat
end
function M.Poll()
  if M.Mode() == "off" or not M.Available() then M.Clear(); return end
  local roster, current = M.Roster()
  if current ~= signature then M.Clear(); signature = current end
  if current == "" then return end
  token = math.mod(token, 4294967294) + 1
  local text = tostring(token)
  M.pending, M.wanted = {}, {}
  for name in pairs(roster) do M.wanted[name] = text end
  SendAddonMessage("RESBOT", "R:1:" .. text .. ":" .. M.Mode(), GetNumRaidMembers() > 0 and "RAID" or "PARTY")
end
function M.VisibleNodes(zone)
  local result, seen = {}, {}
  local roster = M.Roster()
  for name, snapshot in pairs(M.snapshots) do
    if not roster[name] or snapshot.expires <= GetTime() then M.snapshots[name] = nil
    elseif snapshot.zone == zone then
      for _, row in ipairs(snapshot.rows) do
        if not seen[row.guid] and (M.Mode() == "both" or M.Mode() == "ore" and row.kind == "O" or
            M.Mode() == "herbs" and row.kind == "H") then
          seen[row.guid] = true; table.insert(result, row)
        end
      end
    end
  end
  return result
end
function M.Draw()
  for _, pin in ipairs(M.pins) do pin:Hide() end
  if M.Mode() == "off" or not M.Available() then return end
  local x, y = GetPlayerMapPosition("player")
  if not x or not y or x == 0 and y == 0 then return end -- Unsupported instance coordinates.
  local zone = pfMap:GetMapIDByName(GetRealZoneText())
  -- The map API uses the map currently selected by the player. Do not move
  -- that selection or draw with coordinates from another world-map view.
  if not pfMap.GetMapID or pfMap:GetMapID() ~= zone then return end
  local size = zone and pfMap.minimap_sizes[zone]
  local zoom = pfMap.minimap_zoom[pfMap.minimap_indoor()]
  local radius = zoom and zoom[Minimap:GetZoom()]
  if not size or not radius or size[1] <= 0 or size[2] <= 0 then return end
  local count = 0
  for _, row in ipairs(M.VisibleNodes(zone)) do
    local dx = (row.x / 100 - x) * size[1] / radius * Minimap:GetWidth()
    local dy = (y - row.y / 100) * size[2] / radius * Minimap:GetHeight()
    if pfQuestCompat.rotateMinimap then
      if not pfQuestCompat.GetPlayerFacing then return end
      local facing = pfQuestCompat.GetPlayerFacing()
      dx, dy = dx * math.cos(facing) + dy * math.sin(facing), -dx * math.sin(facing) + dy * math.cos(facing)
    end
    if math.sqrt(dx*dx + dy*dy) + 8 < math.min(Minimap:GetWidth(), Minimap:GetHeight()) / 2 then
      count = count + 1
      if not M.pins[count] then
        local pin = CreateFrame("Frame", nil, Minimap)
        pin:SetWidth(14); pin:SetHeight(14); pin:SetFrameLevel(Minimap:GetFrameLevel() + 5)
        pin.texture = pin:CreateTexture(nil, "ARTWORK"); pin.texture:SetAllPoints(pin)
        -- Non-interactive frames preserve minimap clicks and cannot trigger gathering.
        M.pins[count] = pin
      end
      local pin = M.pins[count]
      pin.texture:SetTexture(textures[row.kind]); pin:ClearAllPoints()
      pin:SetPoint("CENTER", Minimap, "CENTER", dx, dy); pin:Show()
    end
  end
end
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
frame:RegisterEvent("RAID_ROSTER_UPDATE")
frame:SetScript("OnEvent", function()
  if event == "CHAT_MSG_ADDON" then M.Receive(arg1, arg2, arg3, arg4)
  else M.Clear(); nextPoll = GetTime() + 0.2 end
end)
frame:SetScript("OnUpdate", function()
  local now = GetTime()
  if now >= nextPoll then nextPoll = now + 5.5; M.Poll() end
  if now >= nextDraw then nextDraw = now + 0.1; M.Draw() end
end)
SLASH_MANGOSBOTRESOURCES1 = "/botresources"
SlashCmdList.MANGOSBOTRESOURCES = function(text)
  text = string.lower(text or "")
  if text == "off" or text == "both" or text == "ore" or text == "herbs" then
    BotResourceIconsDB = BotResourceIconsDB or {}; BotResourceIconsDB.resourceMarkers = text
    M.Clear(); nextPoll = GetTime() + 0.2
  end
  DEFAULT_CHAT_FRAME:AddMessage("Bot resource icons: " .. M.Mode() .. ". /botresources both|ore|herbs|off (requires matching server and pfQuest).")
end
