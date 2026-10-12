local Mangosbot_EventFrame = CreateFrame("Frame")
Mangosbot_EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
Mangosbot_EventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_WHISPER")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_ADDON")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
Mangosbot_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
Mangosbot_EventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
Mangosbot_EventFrame:RegisterEvent("QUEST_LOG_UPDATE")
Mangosbot_EventFrame:RegisterEvent("UPDATE")
Mangosbot_EventFrame:Hide()

local VERSION=0

function print(s)
    if (s ~= nil) then DEFAULT_CHAT_FRAME:AddMessage(s); else DEFAULT_CHAT_FRAME:AddMessage("nil"); end
end

local ToolBars = {}
local GroupToolBars = {}
local CommandSeparator = "\\\\"
local DropDownMenu = {}
function SendBotCommand(text, chat, lang, channel)
    if (chat == "PARTY" and partySize() == 0) then return end
    if (chat == "PARTY") then 
        if (GetNumRaidMembers() > 0) then chat = "RAID" end
        SendAddonMessage("", text, chat, channel)
    else
        SendChatMessage(text, chat, lang, channel)
    end
end
function SendBotAddonCommand(text, chat, lang, channel)
    if (chat == "PARTY" and partySize() == 0) then return end
    if (chat == "PARTY" and GetNumRaidMembers() > 0) then chat = "RAID" end

    -- Vanilla-era ChatThrottleLib does not support addon WHISPER messages.
    -- PARTY/RAID addon messages are genuinely silent; retain normal whispers
    -- for selected-bot controls that need to address one bot directly.
    if (chat == "PARTY" or chat == "RAID") then
        SendAddonMessage("BOT", "#a "..text, chat, channel)
    else
        SendBotCommand("#a "..text, chat, lang, channel)
    end
end

function CreateToolBar(frame, y, name, buttons, x, spacing, register)
    if (x == nil) then x = 5 end
    if (spacing == nil) then spacing = 5 end
    if (register == nil) then register = true end

    if (frame.toolbar == nil) then
        frame.toolbar = {}
    end

    local tb = CreateFrame("Frame", "Toolbar" .. name, frame)
    tb:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
    tb:SetWidth(frame:GetWidth() - x - 5)
    tb:SetHeight(22)
    tb:SetBackdropColor(0,0,0,1.0)
    tb:SetBackdrop({
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = false, tileSize = 16, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    tb:SetBackdropBorderColor(0,0,0,1.0)

    tb.buttons = {}
    for key, button in pairs(buttons) do
        local btn = CreateFrame("Button", "Toolbar" .. name .. key, tb)
        btn:SetPoint("TOPLEFT", tb, "TOPLEFT", button["index"] * (22 + spacing), 0)
        btn:SetWidth(20)
        btn:SetHeight(20)
        btn:SetBackdrop({
            edgeFile="Interface/ChatFrame/ChatFrameBackground",
            tile = false, tileSize = 16, edgeSize = 2,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        btn:SetBackdropBorderColor(0, 0, 0, 0.0)
        btn:EnableMouse(true)
        btn:RegisterForClicks("LeftButtonDown")
        btn["tooltip"] = button["tooltip"]
        btn:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT", 0, -frame:GetHeight() - 40)
          GameTooltip:SetText(btn["tooltip"])
          GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
          GameTooltip:Hide()
        end)
        btn["command"] = button["command"]
        btn["emote"] = button["emote"]
        btn["group"] = button["group"]
        btn["handler"] = button["handler"]
        btn["ToolBarButtonOnClick"] = ToolBarButtonOnClick;
        btn:SetScript("OnClick", function()
            btn["ToolBarButtonOnClick"](btn, true)
        end)

        local image = CreateFrame("Frame", "Toolbar" .. name .. key .. "Image", btn)
        image:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
        image:SetWidth(16)
        image:SetHeight(16)
        image.texture = image:CreateTexture(nil, "BACKGROUND")
        local filename = "Interface\\Addons\\Mangosbot\\Images\\" .. button["icon"] .. ".tga"
        image.texture:SetTexture(filename)
        image.texture:SetAllPoints()
        btn.image = image

        tb.buttons[key] = btn
    end

    frame.toolbar[name] = tb
    if (register) then
        ToolBars[name] = buttons
    end
    return buttons
end

function ClickToolBarButton(toolbar, button)
    local btn = ToolBars[toolbar][button];
    ToolBarButtonOnClick(btn, false)
end

function ClickGroupToolBarButton(toolbar, button)
    local btn = GroupToolBars[toolbar][button];
    ToolBarButtonOnClick(btn, false)
end

function OnKeyBindingDown(button)
    local name = GetUnitName("target")
    local self = GetUnitName("player")
    if (CurrentBot == nil and (name == nil or not UnitExists("target") or UnitIsEnemy("target", "player") or not UnitIsPlayer("target") or name == self)) then
        ClickGroupToolBarButton("group_movement", button)
    else
        ClickToolBarButton("movement", button)
    end
end

function ToolBarButtonOnClick(btn, visual)
    if (btn["handler"] ~= nil) then
        btn["handler"]()
        return
    end

    if (visual) then
      btn:SetBackdropBorderColor(0.8, 0.2, 0.2, 1.0)
    end

    if (btn["emote"] ~= nil) then
        DoEmote(btn["emote"])
    end

    if (btn["group"]) then
        local delay = 0
        local first = true
        local combined = ""
        for key, command in orderedPairs(btn["command"]) do
            combined = combined..command..CommandSeparator
        end
        combined = string.sub(combined, 1, string.len(combined) - 2)
        wait(0, function(combined) SendBotCommand(combined, "PARTY") end, combined)
        if (btn["tooltip"] ~= nil) then
            wait(delay + 1, function(command) SendBotCommand(command, "PARTY") end, btn["tooltip"])
        end
    else
        local bot = GetUnitName("target")
        if (bot == nil) then bot = CurrentBot end
        local combined = ""
        for key, command in orderedPairs(btn["command"]) do
            combined = combined..command..CommandSeparator
        end
        combined = string.sub(combined, 1, string.len(combined) - 2)
        wait(0, function(combined, bot) SendBotCommand(combined, "WHISPER", nil, bot) end, combined, bot)
    end
end

function ToggleButton(frame, toolbar, button, toggle, mixed)
    local btn = frame.toolbar[toolbar].buttons[button]
    if (toggle and mixed) then
        btn:SetBackdropBorderColor(0.2, 0.4, 0.2, 1.0)
    elseif (toggle) then
        btn:SetBackdropBorderColor(0.2, 1.0, 0.2, 1.0)
    else
        btn:SetBackdropBorderColor(0, 0, 0, 0.0)
    end
end

-- Party quest status ---------------------------------------------------------
-- Playerbots do not run client addons, so ordinary quest-sharing addons cannot
-- see their quest logs. Capture the replies from a manual PlayerBots quest
-- query and build a compact status table for the player's tracked quests.
local BotQuestStatus = {}
local QuestStatusLastQuery = 0
local QuestStatusMaxRows = 6

local function QuestStatusKey(title)
    if not title then return "" end
    title = string.gsub(title, "|c%x%x%x%x%x%x%x%x", "")
    title = string.gsub(title, "|r", "")
    title = string.gsub(title, "^%s+", "")
    title = string.gsub(title, "%s+$", "")
    return string.lower(title)
end

local function ExtractQuestTitle(message)
    local _, _, title = string.find(message or "", "|h%[([^%]]+)%]|h")
    return title
end

local function GetPartyBotNames()
    local names = {}
    for i = 1, partySize() do
        local name = partyName(i)
        local unit = "party" .. i
        if GetNumRaidMembers() > 0 then unit = "raid" .. i end
        if name and botTable[name] and botTable[name]["online"] and UnitIsConnected(unit) then
            table.insert(names, name)
        end
    end
    table.sort(names)
    return names
end

local function GetTrackedQuestTitles()
    local tracked = {}
    local fallback = {}
    local entries = GetNumQuestLogEntries()

    for i = 1, entries do
        local title, level, tag, isHeader = GetQuestLogTitle(i)
        if title and not isHeader then
            table.insert(fallback, title)
            if IsQuestWatched and IsQuestWatched(i) then
                table.insert(tracked, title)
            end
        end
    end

    -- Some 1.12 quest-log replacements do not expose watched state.
    if tablelength(tracked) == 0 then return fallback end
    return tracked
end

local function JoinQuestNames(names)
    if tablelength(names) == 0 then return "None" end
    table.sort(names)
    return table.concat(names, ", ")
end

local function ShortQuestTitle(title, maxLength)
    if string.len(title) <= maxLength then return title end
    return string.sub(title, 1, maxLength - 3) .. "..."
end

function RefreshPartyQuestStatus()
    if not BotRoster or not BotRoster.questStatusPanel then return end

    local panel = BotRoster.questStatusPanel
    local botNames = GetPartyBotNames()
    local quests = GetTrackedQuestTitles()
    local total = tablelength(botNames)

    panel.header:SetText("Have   Core*  Tracked quest")

    for i = 1, QuestStatusMaxRows do
        local row = panel.rows[i]
        local title = quests[i]

        if title and total > 0 then
            local key = QuestStatusKey(title)
            local have = 0
            local complete = 0
            local waiting = 0
            local completedNames = {}
            local incompleteNames = {}
            local missingNames = {}
            local waitingNames = {}

            for _, name in pairs(botNames) do
                local snapshot = BotQuestStatus[name]
                if not snapshot or snapshot.pending then
                    waiting = waiting + 1
                    table.insert(waitingNames, name)
                else
                    local quest = snapshot.quests[key]
                    if quest then
                        have = have + 1
                        if quest.status == "complete" then
                            complete = complete + 1
                            table.insert(completedNames, name)
                        else
                            table.insert(incompleteNames, name)
                        end
                    else
                        table.insert(missingNames, name)
                    end
                end
            end

            local haveText = tostring(have) .. "/" .. tostring(total)
            local doneText = tostring(complete) .. "/" .. tostring(total)
            if waiting > 0 then
                haveText = "..."
                doneText = "..."
            end

            row.text:SetText(haveText .. "     " .. doneText .. "     " .. ShortQuestTitle(title, 19))
            if waiting > 0 then
                row.text:SetTextColor(0.65, 0.65, 0.65, 1)
            elseif complete == total then
                row.text:SetTextColor(0.2, 1.0, 0.2, 1)
            elseif have < total then
                row.text:SetTextColor(1.0, 0.35, 0.2, 1)
            else
                row.text:SetTextColor(1.0, 0.82, 0.0, 1)
            end

            row.tooltipText = title ..
                "\n|cff20ff20Complete:|r " .. JoinQuestNames(completedNames) ..
                "\n|cffffff00In progress:|r " .. JoinQuestNames(incompleteNames) ..
                "\n|cffff5030Not accepted:|r " .. JoinQuestNames(missingNames) ..
                "\n|cffaaaaaa*Core is PlayerBots' stored completion flag. It may be wrong until the quest giver checks the turn-in.|r"
            if waiting > 0 then
                row.tooltipText = row.tooltipText ..
                    "\n|cffaaaaaaWaiting for:|r " .. JoinQuestNames(waitingNames)
            end
            row:Show()
        else
            row:Hide()
        end
    end

    if tablelength(quests) == 0 then
        panel.header:SetText("No tracked quests")
    elseif total == 0 then
        panel.header:SetText("No PlayerBots in the party")
    elseif tablelength(quests) > QuestStatusMaxRows then
        panel.header:SetText("Have   Core*  Tracked quest (first 6)")
    end
end

function QueryPartyQuestStatus(force)
    if not BotRoster or not BotRoster:IsVisible() or partySize() == 0 then return end

    local names = GetPartyBotNames()
    if tablelength(names) == 0 then
        BotQuestStatus = {}
        RefreshPartyQuestStatus()
        return
    end

    local now = GetTime()
    if not force and now - QuestStatusLastQuery < 2 then return end
    QuestStatusLastQuery = now

    BotQuestStatus = {}
    for _, name in pairs(names) do
        BotQuestStatus[name] = { phase = nil, quests = {}, pending = true }
    end

    RefreshPartyQuestStatus()
    -- This is deliberately manual and visible. Silent PARTY addon traffic is
    -- heard by every bot and can make bots process one another's replies.
    SendChatMessage("quests all", "PARTY")
end

function HandlePartyQuestStatusMessage(message, sender)
    if not sender then return end

    local cleanSender = string.gsub(sender, "%-.*$", "")
    local snapshot = BotQuestStatus[cleanSender]
    if not snapshot then
        for name, candidate in pairs(BotQuestStatus) do
            if string.lower(name) == string.lower(cleanSender) then
                cleanSender = name
                snapshot = candidate
                break
            end
        end
    end
    if not snapshot then return end

    if string.find(message, "--- Incompleted quests ---", 1, true) == 1 then
        snapshot.phase = "incomplete"
    elseif string.find(message, "--- Completed quests ---", 1, true) == 1 then
        snapshot.phase = "complete"
    elseif string.find(message, "--- Summary ---", 1, true) == 1 then
        snapshot.phase = "summary"
    elseif string.find(message, "Total:", 1, true) == 1 then
        snapshot.pending = false
        snapshot.phase = nil
    elseif snapshot.phase == "incomplete" or snapshot.phase == "complete" then
        local title = ExtractQuestTitle(message)
        if title then
            snapshot.quests[QuestStatusKey(title)] = {
                title = title,
                status = snapshot.phase
            }
        end
    end

    RefreshPartyQuestStatus()
end

-- Run one deliberate loot action. Automatic post-combat scans and repeated
-- hidden group commands caused excessive chatter in this PlayerBots build.
function LootNearbyCorpsesForParty()
    if tablelength(GetPartyBotNames()) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("MangosBot: no online PlayerBots are in the party.")
        return
    end
    SendChatMessage("do loot", "PARTY")
end

function CreateQuestStatusPanel(frame)
    local panel = CreateFrame("Frame", "MangosBotQuestStatusPanel", frame)
    panel:SetWidth(176)
    panel:SetHeight(88)

    panel.header = panel:CreateFontString(nil, "OVERLAY")
    panel.header:SetPoint("TOPLEFT", panel, "TOPLEFT", 2, 0)
    panel.header:SetWidth(172)
    panel.header:SetHeight(12)
    panel.header:SetFont("Fonts/FRIZQT__.TTF", 9, "OUTLINE")
    panel.header:SetJustifyH("LEFT")
    panel.header:SetText("Have   Core*  Tracked quest")

    panel.rows = {}
    for i = 1, QuestStatusMaxRows do
        local row = CreateFrame("Button", "MangosBotQuestStatusRow" .. i, panel)
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -12 - ((i - 1) * 12))
        row:SetWidth(176)
        row:SetHeight(12)
        row:EnableMouse(true)

        row.text = row:CreateFontString(nil, "OVERLAY")
        row.text:SetAllPoints(row)
        row.text:SetFont("Fonts/FRIZQT__.TTF", 9, "OUTLINE")
        row.text:SetJustifyH("LEFT")

        row:SetScript("OnEnter", function()
            if this.tooltipText then
                GameTooltip:SetOwner(this, "ANCHOR_LEFT")
                GameTooltip:SetText(this.tooltipText)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row:Hide()
        panel.rows[i] = row
    end

    return panel
end

function CreateQuestActionBar(frame)
    local bar = CreateFrame("Frame", "MangosBotQuestActionBar", frame)
    bar:SetWidth(176)
    bar:SetHeight(70)

    local function CreateQuestButton(name, label, command, tooltip, x, width, handler)
        local btn = CreateFrame("Button", "MangosBotQuest" .. name .. "Button", bar)
        btn:SetPoint("TOPLEFT", bar, "TOPLEFT", x, 0)
        btn:SetWidth(width)
        btn:SetHeight(20)
        btn:SetBackdrop({
            bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            tile = true, tileSize = 16, edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        btn:SetBackdropBorderColor(0.65, 0.65, 0.65, 1.0)
        btn:EnableMouse(true)
        btn:RegisterForClicks("LeftButtonDown")

        btn.text = btn:CreateFontString(nil, "OVERLAY")
        btn.text:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.text:SetFont("Fonts/FRIZQT__.TTF", 10, "OUTLINE")
        btn.text:SetText(label)

        btn:SetScript("OnClick", function()
            if handler then
                handler()
                return
            end
            -- Quest commands must be sent as ordinary party chat, exactly as
            -- if the player had entered "/p <command>" in the chat box.
            if tablelength(GetPartyBotNames()) == 0 then
                DEFAULT_CHAT_FRAME:AddMessage("MangosBot: no online PlayerBots are in the party.")
                return
            end
            SendChatMessage(command, "PARTY")
        end)
        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(btn, "ANCHOR_TOP")
            GameTooltip:SetText(tooltip)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        return btn
    end

    bar.quests = CreateQuestButton("List", "Quests", nil, "Manually refresh every party bot's quests (/p quests all)", 0, 50, function() QueryPartyQuestStatus(true) end)
    bar.accept = CreateQuestButton("Accept", "Accept", "do accept all quests", "Accept available quests from your selected NPC (/p do accept all quests)", 54, 50)
    bar.turnin = CreateQuestButton("TurnIn", "Turn In", "do talk to quest giver", "Hand in completed quests to your selected NPC (/p do talk to quest giver)", 108, 62)
    bar.useObject = CreateQuestButton("UseObject", "Use Object", "u go", "Use the nearest game object (/p u go)", 0, 54)
    bar.useObject:ClearAllPoints()
    bar.useObject:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, -24)
    bar.sell = CreateQuestButton("Sell", "Sell Junk", "s vendor", "Sell items classified for a nearby vendor (/p s vendor)", 59, 58)
    bar.sell:ClearAllPoints()
    bar.sell:SetPoint("TOPLEFT", bar, "TOPLEFT", 59, -24)
    bar.equip = CreateQuestButton("Equip", "Equip", "do equip upgrades", "Equip each bot's available upgrades (/p do equip upgrades)", 122, 48)
    bar.equip:ClearAllPoints()
    bar.equip:SetPoint("TOPLEFT", bar, "TOPLEFT", 122, -24)
    bar.loot = CreateQuestButton("Loot", "Loot Nearby Corpses", nil, "Run one manual loot action for the party (/p do loot)", 0, 170, LootNearbyCorpsesForParty)
    bar.loot:ClearAllPoints()
    bar.loot:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, -48)

    return bar
end

function EnablePositionSaving(frame, frameName)
    frame:SetScript("OnMouseDown", function() this:StartMoving() end)
	frame:SetScript("OnMouseUp", function()
            local button = arg1
            local self = frame
            self:StopMovingOrSizing()

            if (frameopts == nil) then
                frameopts = {}
            end
            if (frameopts[frameName] == nil) then
                frameopts[frameName] = {}
            end

            local opts = frameopts[frameName]
            local from, _, to, x, y = self:GetPoint()

            opts.anchorFrom = from
            opts.anchorTo = to

            if self.is_expanded then
                if opts.anchorFrom == "TOPLEFT" or opts.anchorFrom == "LEFT" or opts.anchorFrom == "BOTTOMLEFT" then
                    opts.offsetx = x
                elseif opts.anchorFrom == "TOP" or opts.anchorFrom == "CENTER" or opts.anchorFrom == "BOTTOM" then
                    opts.offsetx = x - 151/2
                elseif opts.anchorFrom == "TOPRIGHT" or opts.anchorFrom == "RIGHT" or opts.anchorFrom == "BOTTOMRIGHT" then
                    opts.offsetx = x - 151
                end
            else
                opts.offsetx = x
            end
            opts.offsety = y
        end)

	do
		-------------------------------------------------------------------------------
		-- Restore the panel's position on the screen.
		-------------------------------------------------------------------------------
		local function Reset_Position()
            local self = frame
            if (frameopts == nil) then
                frameopts = {}
            end
            if (frameopts[frameName] == nil) then
                frameopts[frameName] = {}
            end
			local opts = frameopts[frameName]
			local FixedOffsetX = opts.offsetx

			self:ClearAllPoints()

			if opts.anchorTo == nil then
                self:SetPoint("CENTER", UIParent, "CENTER")
			else
				self:SetPoint(opts.anchorFrom, UIParent, opts.anchorTo, opts.offsetx, opts.offsety)
			end
		end

		frame:SetScript("OnShow", Reset_Position)
	end	-- do-block
end

function ResizeBotPanel(frame, width, height)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame.header:SetWidth(frame:GetWidth())
    frame.header.text:SetWidth(frame.header:GetWidth())
    for toolbarName,toolbar in pairs(ToolBars) do
        frame.toolbar[toolbarName]:SetWidth(frame:GetWidth() - 10)
    end
end

function CreateBotRosterItem(frame, i)
        local item = CreateFrame("Frame", "BotRoster_Item" .. i, frame)
        item:SetPoint("TOPLEFT", frame, "TOPLEFT", i * 100, 0)
        item:SetWidth(112)
        item:SetHeight(40)
        item:SetBackdropColor(0,0,0,1)
        item:SetBackdrop({
            bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
            edgeFile="Interface/ChatFrame/ChatFrameBackground",
            tile = true, tileSize = 16, edgeSize = 2,
            insets = { left = 2, right = 2, top = 2, bottom = 0 }
        })
        item:SetBackdropBorderColor(0.8,0.8,0.8,1)

        item.text = item:CreateFontString("BotRoster_ItemHeader" .. i)
        item.text:SetPoint("TOPLEFT", item, "TOPLEFT", 20, 1)
        item.text:SetWidth(item:GetWidth())
        item.text:SetHeight(22)
        item.text:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
        item.text:SetJustifyH("LEFT")
        item.text:SetText("Click!")

        local cls = CreateFrame("Button", "BotRoster_ItemHeader" .. i .. "Image", item)
        cls:SetPoint("TOPLEFT", item, "TOPLEFT", 3, -3)
        cls:SetWidth(16)
        cls:SetHeight(16)
        cls:EnableMouse(true)
        cls:RegisterForClicks("LeftButtonDown")
        cls.texture = cls:CreateTexture(nil, "BACKGROUND")
        cls.texture:SetTexture("Interface\\Addons\\Mangosbot\\Images\\role_dps.tga")
        cls.texture:SetAllPoints()
        cls:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(item, "ANCHOR_TOPLEFT", 0, -item:GetHeight() - 40)
          GameTooltip:SetText("Bot Control Panel")
          GameTooltip:Show()
        end)
        cls:SetScript("OnLeave", function(self)
          GameTooltip:Hide()
        end)
        item.cls = cls

        CreateToolBar(item, -18, "quickbar"..i, {
            ["login"] = {
                icon = "login",
                command = {[0] = ""},
                strategy = "",
                tooltip = "Bring bot online",
                index = 0
            },
            ["logout"] = {
                icon = "logout",
                command = {[0] = ""},
                tooltip = "Logout bot",
                strategy = "",
                index = 0
            },
            ["invite"] = {
                icon = "invite",
                command = {[0] = ""},
                tooltip = "Invite to your group",
                strategy = "",
                index = 1
            },
            ["leave"] = {
                icon = "leave",
                command = {[0] = ""},
                tooltip = "Remove from group",
                strategy = "",
                index = 1
            },
            ["whisper"] = {
                icon = "whisper",
                command = {[0] = ""},
                tooltip = "Start whisper chat",
                strategy = "",
                index = 2
            },
            ["summon"] = {
                icon = "summon",
                command = {[0] = ""},
                tooltip = "Summon at meeting stone",
                strategy = "",
                index = 3
            },
            ["menu"] = {
                icon = "menu",
                command = {[0] = ""},
                tooltip = "More...",
                strategy = "",
                index = 4
            }			
        }, 20, 0, false)
        local tb = item.toolbar["quickbar"..i]
        tb:SetBackdropBorderColor(0,0,0,0.0)
        tb.buttons["login"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 0, 0)
        tb.buttons["logout"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 0, 0)
        tb.buttons["invite"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 16, 0)
        tb.buttons["leave"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 16, 0)
        tb.buttons["whisper"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 48, 0)
        tb.buttons["summon"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 32, 0)
        tb.buttons["menu"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 64, 0)

        item:Hide()
        frame.items[i] = item
        return item
end

function CreateBotRoster()
    local frame = CreateFrame("Frame", "BotRoster", UIParent)
    frame:Hide()
    frame:SetWidth(186)
    frame:SetHeight(175)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdropColor(0, 0, 0, 1.0)
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    frame:RegisterForDrag("LeftButton")

    EnablePositionSaving(frame, "BotRoster")

    frame.items = {}
    frame.ShowRequest = false

    CreateToolBar(frame, 0, "quickbar", {
        ["login_all"] = {
            icon = "login",
            command = {[0] = ""},
            strategy = "",
            tooltip = "Bring all bots online",
            index = 0
        },
        ["logout_all"] = {
            icon = "logout",
            command = {[0] = ""},
            tooltip = "Logout all bots",
            strategy = "",
            index = 1
        },
        ["invite_all"] = {
            icon = "invite",
            command = {[0] = ""},
            tooltip = "Invite all bots to your group",
            strategy = "",
            index = 2
        },
        ["leave_all"] = {
            icon = "leave",
            command = {[0] = ""},
            tooltip = "Remove all bots from group",
            strategy = "",
            index = 3
        }
    }, 5, 0, false)
    frame.toolbar["quickbar"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_movement"] = CreateMovementToolBar(frame, 0, "group_movement", true, 5, 0, false)
    frame.toolbar["group_movement"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_formation"] = CreateFormationToolBar(frame, 0, "group_formation", true, 5, 0, false)
    frame.toolbar["group_formation"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_savemana"] = CreateSaveManaToolBar(frame, 0, "group_savemana", true, 5, 0, false)
    frame.toolbar["group_savemana"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_generic"] = CreateGenericNonCombatToolBar(frame, 0, "group_generic", true, 5, 0, false)
    frame.toolbar["group_generic"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_generic_combat"] = CreateGenericCombatToolBar(frame, 0, "group_generic_combat", true, 5, 0, false)
    frame.toolbar["group_generic_combat"]:SetBackdropBorderColor(0,0,0,0.0)

    frame.questActionBar = CreateQuestActionBar(frame)
    frame.questActionBar:Hide()

    frame.questStatusPanel = CreateQuestStatusPanel(frame)
    frame.questStatusPanel:Hide()

    return frame
end

function CreateRtiToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["rti_skull"] = {
            icon = "rti_skull",
            command = {[0] = "rti skull"},
            rti = "skull",
            tooltip = "Attack skull mark",
            index = 0,
            group = group
        },
        ["rti_cross"] = {
            icon = "rti_cross",
            command = {[0] = "rti cross"},
            rti = "cross",
            tooltip = "Attack cross mark",
            index = 1,
            group = group
        },
        ["rti_circle"] = {
            icon = "rti_circle",
            command = {[0] = "rti circle"},
            rti = "circle",
            tooltip = "Attack circle mark",
            index = 2,
            group = group
        },
        ["rti_star"] = {
            icon = "rti_star",
            command = {[0] = "rti star"},
            rti = "star",
            tooltip = "Attack star mark",
            index = 3,
            group = group
        },
        ["rti_square"] = {
            icon = "rti_square",
            command = {[0] = "rti square"},
            rti = "square",
            tooltip = "Attack square mark",
            index = 4,
            group = group
        },
        ["rti_triangle"] = {
            icon = "rti_triangle",
            command = {[0] = "rti triangle"},
            rti = "triangle",
            tooltip = "Attack triangle mark",
            index = 5,
            group = group
        },
        ["rti_diamond"] = {
            icon = "rti_diamond",
            command = {[0] = "rti diamond"},
            rti = "diamond",
            tooltip = "Attack diamond mark",
            index = 6,
            group = group
        },
        ["rti_moon"] = {
            icon = "rti_moon",
            command = {[0] = "rti moon"},
            rti = "moon",
            tooltip = "Attack moon mark",
            index = 7,
            group = group
        }
    }, x, spacing, register)
end

function CreateRtiCcToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["rti_skull"] = {
            icon = "cc_skull",
            command = {[0] = "rti cc skull"},
            rti_cc = "skull",
            tooltip = "CC skull mark",
            index = 0,
            group = group
        },
        ["rti_cross"] = {
            icon = "cc_cross",
            command = {[0] = "rti cc cross"},
            rti_cc = "cross",
            tooltip = "CC cross mark",
            index = 1,
            group = group
        },
        ["rti_circle"] = {
            icon = "cc_circle",
            command = {[0] = "rti cc circle"},
            rti_cc = "circle",
            tooltip = "CC circle mark",
            index = 2,
            group = group
        },
        ["rti_star"] = {
            icon = "cc_star",
            command = {[0] = "rti cc star"},
            rti_cc = "star",
            tooltip = "CC star mark",
            index = 3,
            group = group
        },
        ["rti_square"] = {
            icon = "cc_square",
            command = {[0] = "rti cc square"},
            rti_cc = "square",
            tooltip = "CC square mark",
            index = 4,
            group = group
        },
        ["rti_triangle"] = {
            icon = "cc_triangle",
            command = {[0] = "rti cc triangle"},
            rti_cc = "triangle",
            tooltip = "CC triangle mark",
            index = 5,
            group = group
        },
        ["rti_diamond"] = {
            icon = "cc_diamond",
            command = {[0] = "rti cc diamond"},
            rti_cc = "diamond",
            tooltip = "CC diamond mark",
            index = 6,
            group = group
        },
        ["rti_moon"] = {
            icon = "cc_moon",
            command = {[0] = "rti cc moon"},
            rti_cc = "moon",
            tooltip = "CC moon mark",
            index = 7,
            group = group
        }
    }, x, spacing, register)
end

function CreateMovementToolBar(frame, y, name, group, x, spacing, register)
    local tb = {
        ["follow_master"] = {
            icon = "follow_master",
            command = {[0] = "#a follow", [1] = "#a nc ?", [2] = "#a co ?"},
            strategy = "follow",
            tooltip = "Follow me",
            index = 0,
            group = group,
            emote = "follow"
        },
        ["stay"] = {
            icon = "stay",
            command = {[0] = "#a stay", [1] = "#a nc ?", [2] = "#a co ?"},
            strategy = "stay",
            tooltip = "Stay in place",
            index = 1,
            group = group,
            emote = "wait"
        }
    }
    local index = 2
    if (not group) then
        tb["runaway"] = {
            icon = "flee",
            command = {[0] = "#a co ~runaway,?"},
            strategy = "runaway",
            tooltip = "Run away from mobs",
            index = index,
            group = group
        }
        index = index + 1
    end

    tb["flee_passive"] = {
        icon = "flee_passive",
        command = {[0] = "#a flee", [1] = "#a nc ?", [2] = "#a co ?"},
        strategy = "",
        tooltip = "Ignore everything and follow master",
        index = index,
        group = group,
        emote = "flee"
    }
    index = index + 1

	tb["passive"] = {
		icon = "passive",
		command = {[0] = "nc +passive,?", [1] = "co +passive,?"},
		strategy = "passive",
		tooltip = "Don't rush",
		index = index,
        group = group
	}
    index = index + 1

    if (group) then
        tb["loot"] = {
            icon = "loot",
            command = {[0] = "d add all loot", [1] = "d loot"},
            strategy = "",
            tooltip = "Loot everything",
            index = index,
            group = group
        }
        index = index + 1
        tb["attack"] = {
            icon = "dps",
            command = {[0] = "d attack my target"},
            strategy = "",
            tooltip = "Attack my target",
            index = index,
            group = group
        }
        index = index + 1
        tb["pull"] = {
            icon = "tank_assist",
            command = {[0] = "#a @dps flee", [1] = "#a @heal flee", [2] = "#a @tank d attack my target"},
            strategy = "",
            tooltip = "Pull",
            index = index,
            group = group
        }
        index = index + 1
        tb["summon"] = {
            icon = "summon",
            command = {[0] = "summon"},
            strategy = "",
            tooltip = "Summon at meeting stone",
            index = index,
            group = group
        }
        index = index + 1
    end

    return CreateToolBar(frame, -y, name, tb, x, spacing, register)
end

function CreateFormationToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["near"] = {
            icon = "formation_near",
            command = {[0] = "formation near"},
            formation = "near",
            tooltip = "Half-circle",
            index = 0,
            group = group
        },
        ["melee"] = {
            icon = "formation_melee",
            command = {[0] = "formation melee"},
            formation = "melee",
            tooltip = "Similar to pets",
            index = 1,
            group = group
        },
        ["arrow"] = {
            icon = "formation_arrow",
            command = {[0] = "formation arrow"},
            formation = "arrow",
            tooltip = "Tank first, dps/healer last",
            index = 2,
            group = group
        },
        ["far"] = {
            icon = "formation_far",
            command = {[0] = "formation far"},
            formation = "far",
            tooltip = "Maintain a distance",
            index = 3,
            group = group
        },
        ["chaos"] = {
            icon = "formation_chaos",
            command = {[0] = "formation chaos"},
            formation = "chaos",
            tooltip = "Move freely",
            index = 4,
            group = group
        }
    }, x, spacing, register)
end

function CreateStanceToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["near"] = {
            icon = "stance_near",
            command = {[0] = "stance near"},
            stance = "near",
            tooltip = "Default stance",
            index = 0,
            group = group
        },
        ["tank"] = {
            icon = "stance_tank",
            command = {[0] = "stance tank"},
            stance = "tank",
            tooltip = "Off-tank stance",
            index = 1,
            group = group
        },
        ["turnback"] = {
            icon = "stance_turnback",
            command = {[0] = "stance turnback"},
            stance = "turnback",
            tooltip = "Tank the enemy away from party",
            index = 2,
            group = group
        },
        ["behind"] = {
            icon = "stance_behind",
            command = {[0] = "stance behind"},
            stance = "behind",
            tooltip = "Attack from behind (melee)",
            index = 3,
            group = group
        }
    }, x, spacing, register)
end

function CreateGenericNonCombatToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["food"] = {
            icon = "food",
            command = {[0] = "nc ~food,?"},
            strategy = "food",
            tooltip = "Use food and drinks",
            index = 0,
            group = group
        },
        ["buff"] = {
            icon = "bdps",
            command = {[0] = "nc ~buff,?"},
            strategy = "buff",
            tooltip = "Buff party members",
            index = 1,
            group = group
        },
        ["loot"] = {
            icon = "loot",
            command = {[0] = "nc ~loot,?"},
            strategy = "loot",
            tooltip = "Enable looting",
            index = 2,
            group = group
        },
        ["gather"] = {
            icon = "gather",
            command = {[0] = "nc ~gather,?"},
            strategy = "gather",
            tooltip = "Gather herbs, ore, etc.",
            index = 3,
            group = group
        }
    }, x, spacing, register)
end

function CreateGenericCombatToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["potions"] = {
            icon = "potions",
            command = {[0] = "co ~potions,?"},
            strategy = "potions",
            tooltip = "Use health and mana potions",
            index = 0,
            group = group
        },
        ["cast_time"] = {
            icon = "cast_time",
            command = {[0] = "co ~cast time,?"},
            strategy = "cast time",
            tooltip = "Do not cast long spells on almost dead targets",
            index = 1,
            group = group
        },
        ["mark_rti"] = {
            icon = "mark_rti",
            command = {[0] = "co ~mark rti,?"},
            strategy = "mark rti",
            tooltip = "Mark current target with raid icon",
            index = 2,
            group = group
        },
        ["ads"] = {
            icon = "ads",
            command = {[0] = "co ~ads,?", [1] = "nc ~ads,?"},
            strategy = "ads",
            tooltip = "Flee if ads might be pulled",
            index = 3,
            group = group
        },
        ["boost"] = {
            icon = "boost",
            command = {[0] = "co ~boost,?"},
            strategy = "boost",
            tooltip = "Boost dps by using cooldowns",
            index = 4,
            group = group
        },
        ["conserve_mana"] = {
            icon = "conserve_mana",
            command = {[0] = "co ~conserve mana,?"},
            strategy = "conserve mana",
            tooltip = "Reduce mana usage at cost of DPS",
            index = 5,
            group = group
        },
        ["cc"] = {
            icon = "cc",
            command = {[0] = "co ~cc,?"},
            strategy = "cc",
            tooltip = "Use crowd control abilities",
            index = 6,
            group = group
        }
    }, x, spacing, register)
end

function CreateSaveManaToolBar(frame, y, name, group, x, spacing, register)
    local buttons = {};
    for i = 1, 5 do
        buttons["savemana"..i] = {
            icon = "savemana"..i,
            command = {[0] = "save mana "..i},
            tooltip = "Save mana level: "..(i>1 and "#"..i or "disabled"),
            index = i - 1,
            group = group,
            savemana = i
        }
    end
    return CreateToolBar(frame, -y, name, buttons, x, spacing, register)
end

function StartChat()
    local editBox = getglobal("ChatFrameEditBox")
    editBox:Show()
    editBox:SetFocus()
    local name = GetUnitName("target")
    if (name == nil) then name = CurrentBot end
    editBox:SetText("/w " .. name .. " ")
end

function CreateSelectedBotPanel()
    local frame = CreateFrame("Frame", "SelectedBotPanel", UIParent)
    frame:Hide()
    frame:SetWidth(170)
    frame:SetHeight(155)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdropColor(0, 0, 0, 1.0)
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropBorderColor(0.5,0.1,0.7,1)
    frame:RegisterForDrag("LeftButton")

    frame.header = CreateFrame("Frame", "SelectedBotPanelHeader", frame)
    frame.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.header:SetWidth(frame:GetWidth())
    frame.header:SetHeight(22)
    frame.header:SetBackdropColor(0.5,0.1,0.7,1)
    frame.header:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 2, right = 2, top = 2, bottom = 0 }
    })
    frame.header:SetBackdropBorderColor(0.5,0.1,0.7,1)

    frame.header.text = frame.header:CreateFontString("SelectedBotPanelHeaderText")
    frame.header.text:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, 0)
    frame.header.text:SetWidth(frame.header:GetWidth())
    frame.header.text:SetHeight(22)
    frame.header.text:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
    frame.header.text:SetJustifyH("LEFT")
    frame.header.text:SetText("Click!")

    frame.header.role = CreateFrame("Frame", "SelectedBotPanelHeaderRole", frame.header)
    frame.header.role:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    frame.header.role:SetWidth(16)
    frame.header.role:SetHeight(16)
    frame.header.role.texture = frame.header.role:CreateTexture(nil, "BACKGROUND")
    frame.header.role.texture:SetTexture("Interface/Addons/Mangosbot/Images/role_dps.tga")
    frame.header.role.texture:SetAllPoints()

    EnablePositionSaving(frame, "SelectedBotPanel")

    local y = 25
    CreateMovementToolBar(frame, y, "movement", false, 5, 5, true)

    y = y + 25
    CreateToolBar(frame, -y, "actions", {
        ["stats"] = {
            icon = "stats",
            command = {[0] = "stats"},
            strategy = "",
            tooltip = "Tell stats (XP, money, etc.)",
            index = 0
        },
        ["whisper"] = {
            icon = "whisper",
            command = {[0] = ""},
            tooltip = "Start whisper chat",
            strategy = "",
            handler = StartChat,
            index = 1
        },
        ["loot"] = {
            icon = "loot",
            command = {[0] = "d add all loot", [1] = "d loot"},
            strategy = "",
            tooltip = "Loot everything",
            index = 2
        },
        ["release"] = {
            icon = "release",
            command = {[0] = "release"},
            strategy = "",
            tooltip = "Release spirit",
            index = 3
        },
        ["revive"] = {
            icon = "revive",
            command = {[0] = "revive", [1] = "d revive from corpse"},
            strategy = "",
            tooltip = "Revive from corpse",
            index = 4
        },
        ["sell"] = {
            icon = "sell",
            command = {[0] = "s *"},
            strategy = "",
            tooltip = "Sell vendor trash",
            index = 5
        },
        ["talk"] = {
            icon = "talk",
            command = {[0] = "talk", [0] = "accept *"},
            strategy = "",
            tooltip = "Talk",
            index = 6
        },
        ["menu"] = {
            icon = "menu",
            command = {[0] = ""},
            strategy = "",
            tooltip = "More...",
            handler = OpenDropDownMenuForCurrentBot,
            index = 7
        }
    })

    y = y + 25
    CreateToolBar(frame, -y, "inventory", {
        ["los"] = {
            icon = "los",
            command = {[0] = "los gos"},
            strategy = "",
            tooltip = "Show nearby game objects",
            index = 0
        },
        ["count"] = {
            icon = "count",
            command = {[0] = "c"},
            strategy = "",
            tooltip = "Show inventory",
            index = 1
        },
        ["bank"] = {
            icon = "bank",
            command = {[0] = "bank"},
            strategy = "",
            tooltip = "Show bank",
            index = 2
        },
        ["spells"] = {
            icon = "spells",
            command = {[0] = "spells +"},
            strategy = "",
            tooltip = "Show crafting",
            index = 3
        },
        ["equip"] = {
            icon = "equip",
            command = {[0] = "e ?"},
            strategy = "",
            tooltip = "Show equipment",
            index = 4
        },
        ["repair"] = {
            icon = "equip",
            command = {[0] = "repair"},
            tooltip = "Repair at an available repair vendor",
            index = 6
        },
        ["mail"] = {
            icon = "mail",
            command = {[0] = "mail ?"},
            strategy = "",
            tooltip = "Show mail",
            index = 5
        }
    })

    y = y + 25
    CreateFormationToolBar(frame, y, "formation", false, 5, 5, true)

    y = y + 25
    CreateStanceToolBar(frame, y, "stance", false, 5, 5, true)

    y = y + 25
    CreateSaveManaToolBar(frame, y, "savemana", false, 5, 5, true)

    y = y + 25
    CreateToolBar(frame, -y, "loot", {
        ["ll_normal"] = {
            icon = "ll_normal",
            command = {[0] = "ll normal"},
            loot = "normal",
            tooltip = "Loot tradeskill items only",
            index = 0
        },
        ["ll_gray"] = {
            icon = "ll_gray",
            command = {[0] = "ll gray"},
            loot = "gray",
            tooltip = "Loot gray items",
            index = 1
        },
        ["ll_disenchant"] = {
            icon = "ll_disenchant",
            command = {[0] = "ll disenchant"},
            loot = "disenchant",
            tooltip = "Loot BoE items for disenchanting",
            index = 2
        },
        ["ll_all"] = {
            icon = "ll_all",
            command = {[0] = "ll all"},
            loot = "all",
            tooltip = "Loot everything",
            index = 3
        },
        ["reveal"] = {
            icon = "stats",
            command = {[0] = "nc ~reveal,?"},
            strategy = "reveal",
            tooltip = "Reveal gathering nodes",
            index = 4
        }
    })

    y = y + 25
    CreateToolBar(frame, -y, "attack_type", {
        ["tank_assist"] = {
            icon = "tank_assist",
            command = {[0] = "nc -dps assist,+tank assist,?", [1] = "co -dps assist,+tank assist,?"},
            strategy = "tank assist",
            tooltip = "Tank assist (disables DPS assist)",
            index = 6
        },
        ["tank_aoe"] = {
            icon = "tank_aoe",
            command = {[0] = "nc +tank aoe,?",[1] = "co +tank aoe,?"},
            strategy = "tank aoe",
            tooltip = "Grab all aggro",
            index = 0
        },
        ["dps_assist"] = {
            icon = "dps_assist",
            command = {[0] = "nc -tank assist,+dps assist,?",[1] = "co -tank assist,+dps assist,?"},
            strategy = "dps assist",
            tooltip = "DPS assist (disables tank assist)",
            index = 1
        },
        ["defense"] = {
            icon = "tank_assist",
            command = {[0] = "nc +defense,?",[1] = "co +defense,?"},
            strategy = "defense",
            tooltip = "Defensive",
            index = 2
        },
        ["grind"] = {
            icon = "grind",
            command = {[0] = "nc +grind,?"},
            strategy = "grind",
            tooltip = "Aggresive mode (grinding)",
            index = 3,
        },
        ["close"] = {
            icon = "close",
            command = {[0] = "co ~close,?"},
            strategy = "close",
            tooltip = "Melee combat",
            index = 4
        },
        ["ranged"] = {
            icon = "ranged",
            command = {[0] = "co ~ranged,?"},
            strategy = "ranged",
            tooltip = "Ranged combat",
            index = 5
        },
        ["threat"] = {
            icon = "threat",
            command = {[0] = "co ~threat,?"},
            strategy = "threat",
            tooltip = "Keep threat level low",
            index = 6
        }
    })

    y = y + 25
    CreateRtiToolBar(frame, y, "rti", false, 5, 5, true)

    y = y + 25
    CreateRtiCcToolBar(frame, y, "rti cc", false, 5, 5, true)

    y = y + 25
    CreateGenericNonCombatToolBar(frame, y, "generic", false, 5, 5, true)

    y = y + 25
    CreateGenericCombatToolBar(frame, y, "generic_combat", false, 5, 5, true)

    y = y + 25
    CreateToolBar(frame, -y, "CLASS_DRUID", {
        ["bear"] = {
            icon = "bear",
            command = {[0] = "co +bear,?"},
            strategy = "bear",
            tooltip = "Use bear form",
            index = 0
        },
        ["cat"] = {
            icon = "cat",
            command = {[0] = "co +cat,?"},
            strategy = "cat",
            tooltip = "Use cat form",
            index = 1
        },
        ["caster"] = {
            icon = "caster",
            command = {[0] = "co +caster,?"},
            strategy = "caster",
            tooltip = "Use caster form",
            index = 2
        },
        ["heal"] = {
            icon = "heal",
            command = {[0] = "co +heal,?"},
            strategy = "heal",
            tooltip = "Healer mode",
            index = 3
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "co ~cure,?", [1] = "nc ~cure,?"},
            strategy = "cure",
            tooltip = "Cure (poison, disease, etc.)",
            index = 4
        },
        ["melee"] = {
            icon = "dps",
            command = {[0] = "co ~melee,?"},
            strategy = "melee",
            tooltip = "Melee",
            index = 5
        }
    })
    CreateToolBar(frame, -y, "CLASS_HUNTER", {
        ["dps"] = {
            icon = "dps",
            command = {[0] = "co +dps,?"},
            strategy = "dps",
            tooltip = "DPS mode",
            index = 0
        },
        ["aoe"] = {
            icon = "aoe",
            command = {[0] = "co ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 1
        },
        ["bspeed"] = {
            icon = "bspeed",
            command = {[0] = "co ~bspeed,?", [1] = "nc ~bspeed,?"},
            strategy = "bspeed",
            tooltip = "Buff movement speed",
            index = 2
        },
        ["bdps"] = {
            icon = "bdps",
            command = {[0] = "co ~bdps,?", [1] = "nc ~bdps,?"},
            strategy = "bdps",
            tooltip = "Buff DPS",
            index = 3
        },
        ["rnature"] = {
            icon = "bmana",
            command = {[0] = "co ~rnature,?", [1] = "nc ~rnature,?"},
            strategy = "rnature",
            tooltip = "Provide nature resistance",
            index = 4
        },
        ["pet"] = {
            icon = "pet",
            command = {[0] = "co ~pet,?", [1] = "nc ~pet,?"},
            strategy = "pet",
            tooltip = "Use pet",
            index = 5
        }
    })
    CreateToolBar(frame, -y, "CLASS_MAGE", {
        ["arcane"] = {
            icon = "arcane",
            command = {[0] = "co +arcane,?"},
            strategy = "arcane",
            tooltip = "Use arcane spells",
            index = 0
        },
        ["fire"] = {
            icon = "fire",
            command = {[0] = "co +fire,?"},
            strategy = "fire",
            tooltip = "Use fire spells",
            index = 1
        },
        ["fire_aoe"] = {
            icon = "fire_aoe",
            command = {[0] = "co ~fire aoe,?"},
            strategy = "fire aoe",
            tooltip = "Use fire AOE abilities",
            index = 2
        },
        ["frost"] = {
            icon = "frost",
            command = {[0] = "co +frost,?"},
            strategy = "frost",
            tooltip = "Use frost spells",
            index = 3
        },
        ["frost_aoe"] = {
            icon = "frost_aoe",
            command = {[0] = "co ~frost aoe,?"},
            strategy = "frost aoe",
            tooltip = "Use frost AOE abilities",
            index = 4
        },
        ["bmana"] = {
            icon = "bmana",
            command = {[0] = "co ~bmana,?", [1] = "nc ~bmana,?"},
            strategy = "bmana",
            tooltip = "Buff mana regen",
            index = 5
        },
        ["bdps"] = {
            icon = "bdps",
            command = {[0] = "co ~bdps,?", [1] = "nc ~bdps,?"},
            strategy = "bdps",
            tooltip = "Buff DPS",
            index = 6
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "co ~cure,?", [1] = "nc ~cure,?"},
            strategy = "cure",
            tooltip = "Cure (poison, disease, etc.)",
            index = 7
        }
    })
    CreateToolBar(frame, -y, "CLASS_PALADIN", {
        ["dps"] = {
            icon = "dps",
            command = {[0] = "co +dps,?"},
            strategy = "dps",
            tooltip = "DPS mode",
            index = 0
        },
        ["tank"] = {
            icon = "tank",
            command = {[0] = "co +tank,?"},
            strategy = "tank",
            tooltip = "Tank mode",
            index = 1
        },
        ["heal"] = {
            icon = "heal",
            command = {[0] = "co +heal,?"},
            strategy = "heal",
            tooltip = "Healer mode",
            index = 2
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "co ~cure,?", [1] = "nc ~cure,?"},
            strategy = "cure",
            tooltip = "Cure (poison, disease, etc.)",
            index = 3
        },
        ["bthreat"] = {
            icon = "bthreat",
            command = {[0] = "nc ~bthreat,?"},
            strategy = "bthreat",
            tooltip = "Increase threat generation",
            index = 4
        }
    })
    CreateToolBar(frame, -y, "CLASS_PRIEST", {
        ["healer_only"] = {
            icon = "heal",
            command = {[0] = "co +holy,-offdps,-offheal,?", [1] = "nc +holy,-offdps,-offheal,?", [2] = "de +holy,-offdps,-offheal,?", [3] = "react +holy,-offdps,-offheal,?"},
            tooltip = "Holy healer only: disable off-DPS and off-healing",
            index = 7
        },
        ["healer_dps"] = {
            icon = "dps",
            command = {[0] = "co +holy,+offdps,-offheal,?", [1] = "nc +holy,+offdps,-offheal,?", [2] = "de +holy,+offdps,-offheal,?", [3] = "react +holy,+offdps,-offheal,?"},
            tooltip = "Holy healer with off-DPS: allow damage while healing",
            index = 8
        },
        ["offheal"] = {
            icon = "heal",
            command = {[0] = "co ~offheal,?", [1] = "nc ~offheal,?"},
            strategy = "offheal",
            tooltip = "Toggle off-healing while in DPS mode",
            index = 9
        },
        ["preheal"] = {
            icon = "heal",
            command = {[0] = "co ~preheal,?"},
            strategy = "preheal",
            tooltip = "Toggle preventive healing",
            index = 10
        },
        ["heal"] = {
            icon = "heal",
            command = {[0] = "co +discipline,?", [1] = "nc +discipline,?", [2] = "de +discipline,?", [3] = "react +discipline,?"},
            strategy = "discipline",
            tooltip = "Discipline healing specialisation",
            index = 0
        },
        ["holy"] = {
            icon = "holy",
            command = {[0] = "co +holy,?", [1] = "nc +holy,?", [2] = "de +holy,?", [3] = "react +holy,?"},
            strategy = "holy",
            tooltip = "Use holy spells",
            index = 1
        },
        ["shadow"] = {
            icon = "shadow",
            command = {[0] = "co +shadow,?", [1] = "nc +shadow,?", [2] = "de +shadow,?", [3] = "react +shadow,?"},
            strategy = "shadow",
            tooltip = "Dps mode: shadow",
            index = 2
        },
        ["shadow_aoe"] = {
            icon = "shadow_aoe",
            command = {[0] = "co ~shadow aoe,?"},
            strategy = "shadow aoe",
            tooltip = "Use shadow AOE abilities",
            index = 3
        },
        ["shadow_debuff"] = {
            icon = "shadow_debuff",
            command = {[0] = "co ~shadow debuff,?"},
            strategy = "shadow debuff",
            tooltip = "Use shadow debuffs",
            index = 4
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "co ~cure,?", [1] = "nc ~cure,?"},
            strategy = "cure",
            tooltip = "Cure (poison, disease, etc.)",
            index = 5
        },
        ["rshadow"] = {
            icon = "rshadow",
            command = {[0] = "co ~rshadow,?", [1] = "nc ~rshadow,?"},
            strategy = "rshadow",
            tooltip = "Provide shadow resistance",
            index = 6
        }
    })
    CreateToolBar(frame, -y, "CLASS_ROGUE", {
        ["dps"] = {
            icon = "dps",
            command = {[0] = "co +dps,?"},
            strategy = "dps",
            tooltip = "DPS mode",
            index = 0
        },
        ["aoe"] = {
            icon = "aoe",
            command = {[0] = "co ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 1
        }
    })
    CreateToolBar(frame, -y, "CLASS_SHAMAN", {
        ["caster"] = {
            icon = "caster",
            command = {[0] = "co +caster,?"},
            strategy = "caster",
            tooltip = "Caster mode",
            index = 0
        },
        ["caster_aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "co ~caster aoe,?"},
            strategy = "caster aoe",
            tooltip = "Use caster AOE abilities",
            index = 1
        },
        ["heal"] = {
            icon = "heal",
            command = {[0] = "co +heal,+threat,?"},
            strategy = "heal",
            tooltip = "Healer mode",
            index = 2
        },
        ["melee"] = {
            icon = "dps",
            command = {[0] = "co +melee,?"},
            strategy = "melee",
            tooltip = "Melee mode",
            index = 3
        },
        ["melee_aoe"] = {
            icon = "aoe",
            command = {[0] = "co ~melee aoe,?"},
            strategy = "melee aoe",
            tooltip = "Use melee AOE abilities",
            index = 4
        },
        ["totems"] = {
            icon = "totems",
            command = {[0] = "co ~totems,?"},
            strategy = "totems",
            tooltip = "Use totems",
            index = 5
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "co ~cure,?", [1] = "nc ~cure,?"},
            strategy = "cure",
            tooltip = "Cure (poison, disease, etc.)",
            index = 6
        }
    })
    CreateToolBar(frame, -y, "CLASS_WARLOCK", {
        ["dps"] = {
            icon = "dps",
            command = {[0] = "co +dps,?"},
            strategy = "dps",
            tooltip = "DPS mode",
            index = 0
        },
        ["dps_debuff"] = {
            icon = "dps_debuff",
            command = {[0] = "co ~dps debuff,?"},
            strategy = "dps debuff",
            tooltip = "Use DPS debuffs",
            index = 1
        },
        ["caster_aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "co ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 2
        },
        ["tank"] = {
            icon = "tank",
            command = {[0] = "co +tank,?"},
            strategy = "tank",
            tooltip = "Summon tanky demons",
            index = 3
        },
        ["pet"] = {
            icon = "pet",
            command = {[0] = "co ~pet,?", [1] = "nc ~pet,?"},
            strategy = "pet",
            tooltip = "Use pet",
            index = 4
        }
    })
    CreateToolBar(frame, -y, "CLASS_WARRIOR", {
        ["dps"] = {
            icon = "dps",
            command = {[0] = "co +dps,?"},
            strategy = "dps",
            tooltip = "DPS mode",
            index = 0
        },
        ["warrior_aoe"] = {
            icon = "warrior_aoe",
            command = {[0] = "co ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 1
        },
        ["tank"] = {
            icon = "tank",
            command = {[0] = "co +tank,?"},
            strategy = "tank",
            tooltip = "Tank mode",
            index = 2
        }
    })
    
    y = y + 25
    CreateToolBar(frame, -y, "CLASS_PALADIN_BUFF", {
        ["bmana"] = {
            icon = "bmana",
            command = {[0] = "co +bmana,?", [1] = "nc +bmana,?"},
            strategy = "bmana",
            tooltip = "Buff mana regen",
            index = 0
        },
        ["bhealth"] = {
            icon = "bhealth",
            command = {[0] = "co +bhealth,?", [1] = "nc +bhealth,?"},
            strategy = "bhealth",
            tooltip = "Buff health regen",
            index = 1
        },
        ["bdps"] = {
            icon = "bdps",
            command = {[0] = "co +bdps,?", [1] = "nc +bdps,?"},
            strategy = "bdps",
            tooltip = "Buff melee DPS",
            index = 2
        },
        ["bstats"] = {
            icon = "holy",
            command = {[0] = "co +bstats,?", [1] = "nc +bstats,?"},
            strategy = "bstats",
            tooltip = "Buff stats",
            index = 3
        }
    })
    CreateToolBar(frame, -y, "CLASS_SHAMAN_BUFF", {
        ["earth"] = {
            icon = "earth",
            command = {[0] = "co +earth,?"},
            strategy = "earth",
            tooltip = "Use earth spells",
            index = 0
        },
        ["fire"] = {
            icon = "fire",
            command = {[0] = "co +fire,?"},
            strategy = "fire",
            tooltip = "Use fire spells",
            index = 1
        },
        ["frost"] = {
            icon = "frost",
            command = {[0] = "co +frost,?"},
            strategy = "frost",
            tooltip = "Use frost spells",
            index = 2
        },
        ["air"] = {
            icon = "air",
            command = {[0] = "co +air,?"},
            strategy = "air",
            tooltip = "Use air spells",
            index = 3
        },
        ["bmana"] = {
            icon = "bmana",
            command = {[0] = "co ~bmana,?", [1] = "nc ~bmana,?"},
            strategy = "bmana",
            tooltip = "Buff mana regen",
            index = 4
        },
        ["bdps"] = {
            icon = "bdps",
            command = {[0] = "co ~bdps,?", [1] = "nc ~bdps,?"},
            strategy = "bdps",
            tooltip = "Buff DPS",
            index = 5
        },
    })
    
    y = y + 25
    CreateToolBar(frame, -y, "CLASS_PALADIN_AURA", {
        ["baoe"] = {
            icon = "aoe",
            command = {[0] = "co +baoe,?", [1] = "nc +baoe,?"},
            strategy = "baoe",
            tooltip = "Retribution aura",
            index = 0
        },
        ["rfire"] = {
            icon = "fire",
            command = {[0] = "co +rfire,?", [1] = "nc +rfire,?"},
            strategy = "rfire",
            tooltip = "Fire resistance aura",
            index = 1
        },
        ["rfrost"] = {
            icon = "frost",
            command = {[0] = "co +rfrost,?", [1] = "nc +rfrost,?"},
            strategy = "rfrost",
            tooltip = "Frost resistance aura",
            index = 2
        },
        ["rshadow"] = {
            icon = "rshadow",
            command = {[0] = "co +rshadow,?", [1] = "nc +rshadow,?"},
            strategy = "rshadow",
            tooltip = "Shadow resistance aura",
            index = 3
        },
        ["barmor"] = {
            icon = "barmor",
            command = {[0] = "co +barmor,?", [1] = "nc +barmor,?"},
            strategy = "barmor",
            tooltip = "Devotion aura",
            index = 4
        }
    })
    

    frame:SetHeight(y + 25)
    return frame
end

function SetFrameColor(frame, class)
    local color = RAID_CLASS_COLORS[class]
    if (color == nil) then
        color = {r = 0.5, g = 0.1, b = 0.7};
    end
    frame:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
    frame.header:SetBackdropColor(color.r, color.g, color.b, 1.0)
    frame.header:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
end

local total = 0
function BotDebugTimer(self, elapsed)
    local elapsed = arg1
    if (elapsed) then
        total = total + elapsed
        if total >= 1 then
            local name = GetUnitName("target")
            if (name) then
                SendBotAddonCommand("debug action", "WHISPER", nil, name)
            end
            total = 0
        end
    end
end

local actionHistory = {}
local MaxDebugLines = 60
function CreateBotDebugPanel()
    local frame = CreateFrame("Frame", "BotDebugPanel", UIParent)
    frame:Hide()
    frame:SetWidth(300)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdropColor(0, 0, 0, 1.0)
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropBorderColor(0.5,0.1,0.7,1)
    frame:RegisterForDrag("LeftButton")

    frame.header = CreateFrame("Frame", "SelectedBotPanelHeader", frame)
    frame.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.header:SetWidth(frame:GetWidth())
    frame.header:SetHeight(22)
    frame.header:SetBackdropColor(0.5,0.1,0.7,1)
    frame.header:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 2, right = 2, top = 2, bottom = 0 }
    })
    frame.header:SetBackdropBorderColor(0.5,0.1,0.7,1)

    frame.header.text = frame.header:CreateFontString("SelectedBotPanelHeaderText")
    frame.header.text:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, 0)
    frame.header.text:SetWidth(frame.header:GetWidth())
    frame.header.text:SetHeight(22)
    frame.header.text:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
    frame.header.text:SetJustifyH("LEFT")
    frame.header.text:SetText("Debug Info")

    local lineSize = 12
    for i = 1,MaxDebugLines do
        local text = frame.header:CreateFontString("SelectedBotPanelHeaderText")
        text:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5 -i * lineSize)
        text:SetWidth(frame:GetWidth())
        text:SetHeight(18)
        text:SetFont("Fonts/FRIZQT__.TTF", 9, "OUTLINE")
        text:SetJustifyH("LEFT")
        text:SetText("Line"..i)
        frame["text"..i] = text

        actionHistory[i] = ""
    end
    frame:SetHeight(MaxDebugLines * lineSize + 30)

    EnablePositionSaving(frame, "BotDebugPanel")

    frame:SetScript("OnUpdate", BotDebugTimer)

    return frame
end

function UpdateBotDebugPanel(message, sender)
    local splitted = splitString2(message, "|")
    local length = tablelength(splitted)
    local filtered = {}
    for i = 1, length do
        local row = splitted[i];
        if (string.find(row, BotDebugFilter)) then
            table.insert(filtered, row)
        end
    end
    
    length = tablelength(filtered)
    BotDebugPanel.header.text:SetText("Debug Info "..length..", Filter: "..BotDebugFilter)
    
    if (length > MaxDebugLines) then length = MaxDebugLines end

    local first = MaxDebugLines - length + 1

    for i = 1, first-1 do
        local line = BotDebugPanel["text"..i]
        local source = BotDebugPanel["text"..(length + i)]
        line:SetText(source:GetText())
    end

    for i = first, MaxDebugLines do
        local idx = i - first + 1
        local name = trim2(filtered[idx])
        local line = BotDebugPanel["text"..i]
        line:SetText(name)
    end
end

function createDropdown(opts)
    local dropdown_name = opts['name'] .. '_dropdown'
    local menu_items = opts['items'] or {}
    local title_text = opts['title'] or ''
    local dropdown_width = 0
    local default_val = opts['defaultVal'] or ''
    local change_func = opts['changeFunc'] or function (dropdown_val) end
    local dropdown = CreateFrame("Frame", dropdown_name, opts['prnt'], "UIDropDownMenuTemplate")

    local dd_title = dropdown:CreateFontString(dropdown, 'OVERLAY', 'GameFontNormal')
    dd_title:SetPoint("TOPLEFT", 20, 10)

    for _, item in pairs(menu_items) do -- Sets the dropdown width to the largest item string width.
        dd_title:SetText(item)
        local text_width = dd_title:GetStringWidth() + 20
        if text_width > dropdown_width then
            dropdown_width = text_width
        end
    end

    dropdown:SetWidth(dropdown_width)
	getglobal(dropdown:GetName().."Text"):SetText(default_val)
    dd_title:SetText(title_text)
	dd_title:Hide()
	dropdown:Hide()

    UIDropDownMenu_Initialize(dropdown, function(self, level, _)
        local info = {}
        for key, val in pairs(menu_items) do
            info.text = val .. "...";
            info.checked = false
            info.menuList= key
            info.hasArrow = false
			info.justifyH = "LEFT"
            info.func = change_func
            UIDropDownMenu_AddButton(info)
        end
    end, "MENU")

    return dropdown
end

local MenuForBot = nil
BotMenuItems = {
	[1] = "Accept quest",
	[2] = "Complete quest",
	[3] = "Choose quest reward [item]",
	[4] = "Fly to",
	[5] = "Bind to innkeeper",
	[6] = "Trainer [spell] learn",
	[7] = "Send me an [item]",
	[8] = "Toggle loot +/-[item]",
	[9] = "Toggle +/-[spell]",
	[10] = "Make me party leader",
}
BotMenuChatTable = {
	[1] = "accept *",
	[2] = "d talk to quest giver",
	[3] = "r ",
	[4] = "taxi ?",
	[5] = "home",
	[6] = "trainer learn",
	[7] = "sendmail ",
	[8] = "ll ",
	[9] = "ss ",
	[10] = "d leader",
}
function CreateDropDownMenu(parent)
	local opts = {
		['name']='more',
		['prnt']=parent,
		['title']='More',
		['items']= BotMenuItems,
		['defaultVal']='', 
		['changeFunc']=function()
			local editBox = getglobal("ChatFrameEditBox")
			local id = this:GetID()
			editBox:Show()
			editBox:SetFocus()
			editBox:SetText("/w " .. MenuForBot .. " " .. BotMenuChatTable[id])
		end
	}
	local menu = createDropdown(opts)
	HideDropDownMenu(1)
	return menu
end

function OpenDropDownMenuForCurrentBot()
    local name = GetUnitName("target")
    if (name == nil) then name = CurrentBot end
	OpenDropDownMenu(name)
end

function OpenDropDownMenu(bot)
	local scale,x,y=BotRoster:GetEffectiveScale(),GetCursorPosition();
	DropDownMenu:SetPoint("CENTER",nil,"BOTTOMLEFT",x/scale,y/scale);
	MenuForBot = bot
	ToggleDropDownMenu(1, nil, DropDownMenu, 'cursor')
end


botTable = {}
SelectedBotPanel = CreateSelectedBotPanel();
BotRoster = CreateBotRoster();
BotDebugPanel = CreateBotDebugPanel();
DropDownMenu = CreateDropDownMenu(BotRoster)
CurrentBot = nil
BotDebugFilter = ""

local function fmod(a,b)
    return a - math.floor(a/b)*b
end

function QueryBotParty()
    wait(0.1, function() SendBotCommand("#a ll ?"..CommandSeparator.."#a formation ?"..CommandSeparator.."#a stance ?"..CommandSeparator.."#a co ?"..CommandSeparator.."#a nc ?"..CommandSeparator.."#a save mana ?", "PARTY") end)
end

function QuerySelectedBot(name)
    wait(0.1, function() SendBotCommand("#a formation ?"..CommandSeparator.."#a stance ?"..CommandSeparator.."#a ll ?"..CommandSeparator.."#a co ?"..CommandSeparator.."#a nc ?"..CommandSeparator.."#a save mana ?"..CommandSeparator.."#a rti ?", "WHISPER", nil, name) end)
end

Mangosbot_EventFrame:SetScript("OnEvent", function(self)
    if (event == "PLAYER_ENTERING_WORLD" or event == "PARTY_MEMBERS_CHANGED" or event == "QUEST_LOG_UPDATE") then
        RefreshPartyQuestStatus()
    end

    if event == "PLAYER_REGEN_DISABLED" and CurrentBot == nil then
        SelectedBotPanel:Hide()
    end

    if (event == "PLAYER_TARGET_CHANGED") then
        -- Combat targeting must not open the control UI or issue bot queries.
        -- A bot deliberately pinned through the roster remains available.
        if UnitAffectingCombat("player") then
            if CurrentBot == nil then SelectedBotPanel:Hide() end
            return
        end
        local name = GetUnitName("target")
        local self = GetUnitName("player")
        if (CurrentBot == nil and (name == nil or not UnitExists("target") or UnitIsEnemy("target", "player") or not UnitIsPlayer("target") or name == self)) then
            SelectedBotPanel:Hide()
        else
            if (CurrentBot ~= name) then CurrentBot = nil end
            QuerySelectedBot(name)
        end
    end

    if (event == "CHAT_MSG_SYSTEM") then
        local message = arg1
        if (OnSystemMessage(message)) then
            if (BotRoster.ShowRequest) then
                BotRoster:Show()
                BotRoster.ShowRequest = false
            end
            for _, item in pairs(BotRoster.items) do
                item:Hide()
            end
            local index = 1
            local x = 5
            local width = 0
            local height = 0
            local y = 5
            local colCount = math.max(2, math.ceil(botCount() / 10))
            local allBots = ""
            local first = true
            local allBotsLoggedIn = true
            local allBotsLoggedOut = true
            local allBotsInParty = true
            local atLeastOneBotInParty = false
            for key,bot in pairs(botTable) do
                local item = BotRoster.items[index]
                if not item then item = CreateBotRosterItem(BotRoster, index) end
                if (first) then first = false
                else allBots = allBots .. "," end
                allBots = allBots .. key

                item.text:SetText(key)
                item.cls["key"] = key
                item.cls:SetScript("OnClick", function()
                    if (CurrentBot == item.cls["key"]) then
                        CurrentBot = nil
                        SelectedBotPanel:Hide()
                    else
                        CurrentBot = item.cls["key"]
                        QuerySelectedBot(CurrentBot)
                    end
                end)

                local filename = "Interface\\Addons\\Mangosbot\\Images\\cls_" .. string.lower(bot["class"]) ..".tga"
                item.cls.texture:SetTexture(filename)

                local color = RAID_CLASS_COLORS[string.upper(bot["class"])]
                item.text:SetTextColor(color.r, color.g, color.b, 1.0)

                item:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", x, -y)

                local loginBtn = item.toolbar["quickbar"..index].buttons["login"]
                loginBtn:Hide()
                local logoutBtn = item.toolbar["quickbar"..index].buttons["logout"]
                logoutBtn:Hide()
                local inviteBtn = item.toolbar["quickbar"..index].buttons["invite"]
                inviteBtn:Show()
                local leaveBtn = item.toolbar["quickbar"..index].buttons["leave"]
                leaveBtn:Hide()
                local whisperBtn = item.toolbar["quickbar"..index].buttons["whisper"]
                whisperBtn:Hide()
                local summonBtn = item.toolbar["quickbar"..index].buttons["summon"]
                summonBtn:Hide()
                local menuBtn = item.toolbar["quickbar"..index].buttons["menu"]
                menuBtn:Hide()
                if (bot["online"]) then
                    item:SetBackdropBorderColor(0.6, 0.6, 0.2, 1.0)
                    logoutBtn:Show()
                    whisperBtn:Show()
                    summonBtn:Show()
                    menuBtn:Show()
                    local inParty = false
                    for i = 1,5 do
                        if (partyName(i) == key) then
                            inviteBtn:Hide()
                            leaveBtn:Show()
                            atLeastOneBotInParty = true
                            inParty = true
                            item:SetBackdropBorderColor(0.2, 0.8, 0.8, 1.0)
                        end
                    end
                    if (not inParty) then allBotsInParty = false end
                    allBotsLoggedOut = false
                else
                    item:SetBackdropBorderColor(0.2,0.2,0.2,1)
                    loginBtn:Show()
                    inviteBtn:Hide()
                    allBotsLoggedIn = false
                end
                loginBtn["key"] = key
                loginBtn:SetScript("OnClick", function()
                    SendBotCommand(".bot add " .. loginBtn["key"], "SAY")
                end)
                logoutBtn["key"] = key
                logoutBtn:SetScript("OnClick", function()
                    local botName = logoutBtn["key"]
                    SendBotCommand(".bot rm " .. botName, "SAY")
                    if botTable[botName] then botTable[botName]["online"] = false end
                    BotQuestStatus[botName] = nil
                    RefreshPartyQuestStatus()
                    wait(1, function() SendBotCommand(".bot list", "SAY") end)
                end)
                inviteBtn["key"] = key
                inviteBtn:SetScript("OnClick", function()
                    local target = inviteBtn["key"]
                    if (VERSION == 0) then
                        InviteByName(target)
                    else
                        InviteUnit(target)
                    end
                end)
                leaveBtn["key"] = key
                leaveBtn:SetScript("OnClick", function()
                    SendBotCommand("leave", "WHISPER", nil, leaveBtn["key"])
                end)
                whisperBtn["key"] = key
                whisperBtn:SetScript("OnClick", function()
                    local editBox = getglobal("ChatFrameEditBox")
                    editBox:Show()
                    editBox:SetFocus()
                    editBox:SetText("/w " .. whisperBtn["key"] .. " ")
                end)
                summonBtn["key"] = key
                summonBtn:SetScript("OnClick", function()
                    SendBotCommand("summon", "WHISPER", nil, summonBtn["key"])
                end)
                menuBtn["key"] = key
                menuBtn:SetScript("OnClick", function()
					OpenDropDownMenu(menuBtn["key"])
                end)


                item:Show()

                index = index + 1
                x = x + (5 + item:GetWidth())
                height = item:GetHeight()
                if (width < x) then width = x end
                if (fmod((index - 1), colCount) == 0) then
                    y = y + (5 + height)
                    x = 5
                end
            end
            if (fmod((index - 1), colCount) ~= 0) then
                y = y + (5 + height)
            end
            
            -- Keep the toolbars below the actual roster rows.
                        
            local tb = BotRoster.toolbar["quickbar"]
            tb:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            local loginAllBtn = tb.buttons["login_all"]
            x = 0
            loginAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (not allBotsLoggedIn) then
                loginAllBtn:Show()
                x = x + 16
            else
                loginAllBtn:Hide()
            end
            loginAllBtn["allBots"] = allBots
            loginAllBtn:SetScript("OnClick", function()
                SendBotCommand(".bot add " .. loginAllBtn["allBots"], "SAY")
            end)

            local logoutAllBtn = tb.buttons["logout_all"]
            logoutAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (not allBotsLoggedOut) then
                logoutAllBtn:Show()
                x = x + 16
            else
                logoutAllBtn:Hide()
            end
            logoutAllBtn["allBots"] = allBots
            logoutAllBtn:SetScript("OnClick", function()
                SendBotCommand(".bot rm " .. logoutAllBtn["allBots"], "SAY")
                for botName, botData in pairs(botTable) do
                    botData["online"] = false
                    BotQuestStatus[botName] = nil
                end
                RefreshPartyQuestStatus()
                wait(1, function() SendBotCommand(".bot list", "SAY") end)
            end)

            local inviteAllBtn = tb.buttons["invite_all"]
            inviteAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (not allBotsInParty) then
                inviteAllBtn:Show()
                x = x + 16
            else
                inviteAllBtn:Hide()
            end
            inviteAllBtn["key"] = key
            inviteAllBtn:SetScript("OnClick", function()
                local timeout = 0.1
                for key,bot in pairs(botTable) do
                    wait(timeout, function(key)
                        InviteByName(key)
                    end, key)
                    timeout = timeout + 0.1
                end
                wait(1, function() SendBotCommand(".bot list", "SAY") end)
            end)

            local leaveAllBtn = tb.buttons["leave_all"]
            leaveAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (atLeastOneBotInParty) then
                leaveAllBtn:Show()
                x = x + 16
            else
                leaveAllBtn:Hide()
            end
            leaveAllBtn["key"] = key
            leaveAllBtn:SetScript("OnClick", function()
                local timeout = 0.1
                for key,bot in pairs(botTable) do
                    wait(timeout, function(key) SendBotCommand("leave", "WHISPER", nil, key) end, key)
                    timeout = timeout + 0.1
                end
            end)
            
            local formationToolBar = BotRoster.toolbar["group_formation"]
            if (atLeastOneBotInParty) then
                formationToolBar:Show()
                y = y + 22
                formationToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                formationToolBar:Hide()
            end

            local movementToolBar = BotRoster.toolbar["group_movement"]
            if (atLeastOneBotInParty) then
                movementToolBar:Show()
                y = y + 22
                movementToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                movementToolBar:Hide()
            end

            local savemanaToolBar = BotRoster.toolbar["group_savemana"]
            if (atLeastOneBotInParty) then
                savemanaToolBar:Show()
                y = y + 22
                savemanaToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                savemanaToolBar:Hide()
            end

            local genericToolBar = BotRoster.toolbar["group_generic"]
            if (atLeastOneBotInParty) then
                genericToolBar:Show()
                y = y + 22
                genericToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                genericToolBar:Hide()
            end

            local genericCombatToolBar = BotRoster.toolbar["group_generic_combat"]
            if (atLeastOneBotInParty) then
                genericCombatToolBar:Show()
                y = y + 22
                genericCombatToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                genericCombatToolBar:Hide()
            end

            local questActionBar = BotRoster.questActionBar
            local questStatusPanel = BotRoster.questStatusPanel
            if (atLeastOneBotInParty) then
                questActionBar:Show()
                y = y + 24
                questActionBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
                -- The action bar has three 20px rows. Leave its full height
                -- before positioning the quest-status table underneath it.
                y = y + 72
                questStatusPanel:Show()
                questStatusPanel:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
                y = y + 88
                RefreshPartyQuestStatus()
            else
                questActionBar:Hide()
                questStatusPanel:Hide()
            end

            UpdateGroupToolBar()
            if (width < 186) then width = 186 end
            BotRoster:SetWidth(width)
            BotRoster:SetHeight(y + 22)
        end
    end

    if (event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_ADDON") then
        --print(event.." 1 "..arg1.." 2 "..arg2.." 3 "..arg3.." 4 "..arg4)
        local message = arg1
        local sender = arg2
        if (event == "CHAT_MSG_ADDON") then
            -- The 1.12 server sends PlayerBot replies as CHAT_MSG_ADDON chat
            -- packets, where arg1 is the message and arg2 is the bot name.
            -- Some newer clients expose the modern prefix/message/channel/
            -- sender layout instead, so accept that form as a fallback too.
            if arg1 == "BOT" and arg4 then
                message = arg2
                sender = arg4
            else
                message = arg1
                sender = arg2
            end
        end

        HandlePartyQuestStatusMessage(message, sender)
        OnWhisper(message, sender)
        
        if (BotDebugPanel:IsVisible()) then
            UpdateBotDebugPanel(message, sender)
        end

        if (BotRoster:IsVisible() or SelectedBotPanel:IsVisible()) then
            if (string.find(message, "Hello") == 1 or string.find(message, "Goodbye") == 1) then
                SendBotCommand(".bot list", "SAY")
                QueryBotParty()
            end
            if (string.find(message, "Following") == 1 or string.find(message, "Staying") == 1 or string.find(message, "Fleeing") == 1) then
                wait(0.1, function() SendBotAddonCommand("nc ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "Formation set to") == 1) then
                wait(0.1, function() SendBotAddonCommand("formation ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "Stance set to") == 1) then
                wait(0.1, function() SendBotAddonCommand("stance ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "Loot strategy set to ") == 1) then
                wait(0.1, function() SendBotAddonCommand("ll ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "rti set to") == 1) then
                wait(0.1, function() SendBotAddonCommand("rti ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "rti cc set to") == 1) then
                wait(0.1, function() SendBotAddonCommand("rti cc ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "save mana") == 1) then
                wait(0.1, function() SendBotAddonCommand("save mana ?", "WHISPER", nil, sender) end)
            end
            UpdateGroupToolBar()
        end

        local bot = botTable[sender]
        if (bot == nil or bot["strategy"] == nil or bot["role"] == nil) then
            SelectedBotPanel:Hide()
            return
        end
        local selected = GetUnitName("target")
        if (CurrentBot ~= nil) then selected = CurrentBot end
        if (sender == selected) then
            -- A reply queued before combat must not reopen an automatic panel.
            if CurrentBot == nil and UnitAffectingCombat("player") then
                SelectedBotPanel:Hide()
                return
            end
            SelectedBotPanel:Show()

            local tmp, class = "Unknown";
            if (GetUnitName("target") ~= nil) then
                tmp,class = UnitClass("target")
            end
            SetFrameColor(SelectedBotPanel, class)

            local filename = "Interface\\Addons\\Mangosbot\\Images\\role_" .. bot["role"] .. ".tga"
            SelectedBotPanel.header.role.texture:SetTexture(filename)
            SelectedBotPanel.header.text:SetText(sender)

            local width = 0
            local height = 0
            for toolbarName,toolbar in pairs(ToolBars) do
                local panelVisible = true
                if (string.find(toolbarName, "CLASS_") == 1) then
                    if (string.find(string.sub(toolbarName, 7), class) == 1) then
                        SelectedBotPanel.toolbar[toolbarName]:Show()
                    else
                        SelectedBotPanel.toolbar[toolbarName]:Hide()
                        panelVisible = false
                    end
                end
                local numButtons = 0
                for buttonName,button in pairs(toolbar) do
                    local toggle = false
                    if (button["strategy"] ~= nil) then
                        for key,strategy in pairs(bot["strategy"]["nc"]) do
                            if (strategy == button["strategy"]) then
                                toggle = true
                                break
                            end
                        end
                        for key,strategy in pairs(bot["strategy"]["co"]) do
                            if (strategy == button["strategy"]) then
                                toggle = true
                                break
                            end
                        end
                    end
                    if (button["formation"] ~= nil and bot["formation"] ~= nil and string.find(bot["formation"], button["formation"]) ~= nil) then
                        toggle = true
                    end
                    if (button["stance"] ~= nil and bot["stance"] ~= nil and string.find(bot["stance"], button["stance"]) ~= nil) then
                        toggle = true
                    end
                    if (button["rti"] ~= nil and bot["rti"] ~= nil and string.find(bot["rti"], button["rti"]) ~= nil) then
                        toggle = true
                    end
                    if (button["rti_cc"] ~= nil and bot["rti_cc"] ~= nil and string.find(bot["rti_cc"], button["rti_cc"]) ~= nil) then
                        toggle = true
                    end
                    if (button["loot"] ~= nil and bot["loot"] ~= nil and string.find(bot["loot"], button["loot"]) ~= nil) then
                        toggle = true
                    end
                    if (button["savemana"] ~= nil and bot["savemana"] ~= nil and string.find(bot["savemana"], button["savemana"]) ~= nil) then
                        toggle = true
                    end
                    ToggleButton(SelectedBotPanel, toolbarName, buttonName, toggle)
                    numButtons = numButtons + 1
                end
                if (panelVisible) then
                    height = height + 1
                    if (width < numButtons) then width = numButtons end
                end
            end
            ResizeBotPanel(SelectedBotPanel, width * 25 + 20, height * 25 + 25)
        end
    end
end)

function UpdateGroupToolBar()
    for toolbarName,toolbar in pairs(GroupToolBars) do
        for buttonName,button in pairs(toolbar) do
            local toggleCount = 0
            for botName,bot in pairs(botTable) do
                local toggle = false
                if (button["strategy"] ~= nil and bot["strategy"] ~= nil) then
                    for key,strategy in pairs(bot["strategy"]["nc"]) do
                        if (strategy == button["strategy"]) then
                            toggle = true
                            break
                        end
                    end
                    for key,strategy in pairs(bot["strategy"]["co"]) do
                        if (strategy == button["strategy"]) then
                            toggle = true
                            break
                        end
                    end
                end
                if (button["formation"] ~= nil and bot["formation"] ~= nil and string.find(bot["formation"], button["formation"]) ~= nil) then
                    toggle = true
                end
                if (button["stance"] ~= nil and bot["stance"] ~= nil and string.find(bot["stance"], button["stance"]) ~= nil) then
                    toggle = true
                end
                if (button["rti"] ~= nil and bot["rti"] ~= nil and string.find(bot["rti"], button["rti"]) ~= nil) then
                    toggle = true
                end
                if (button["rti_cc"] ~= nil and bot["rti_cc"] ~= nil and string.find(bot["rti_cc"], button["rti_cc"]) ~= nil) then
                    toggle = true
                end
                if (button["loot"] ~= nil and bot["loot"] ~= nil and string.find(bot["loot"], button["loot"]) ~= nil) then
                    toggle = true
                end
                if (button["savemana"] ~= nil and bot["savemana"] ~= nil and string.find(bot["savemana"], button["savemana"]) ~= nil) then
                    toggle = true
                end
                
                if (toggle) then 
                    for i = 1,5 do
                        if (partyName(i) == botName) then
                            toggleCount = toggleCount + 1
                        end
                    end
                end
            end
            ToggleButton(BotRoster, toolbarName, buttonName, toggleCount > 0, toggleCount < partySize())
        end
    end
end

function trim2(s)

    local find = string.find
    local sub = string.sub
    function trim8(s)
      local i1,i2 = find(s,'^%s*')
      if i2 >= i1 then s = sub(s,i2+1) end
      local i1,i2 = find(s,'%s*$')
      if i2 >= i1 then s = sub(s,1,i1-1) end
      return s
    end
    return trim8(s)
end

function splitString2( self, inSplitPattern, outResults )
  if not inSplitPattern then
    return
  end
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

function OnWhisper(message, sender)
    if (botTable[sender] == nil) then
        botTable[sender] = {}
    end

    local bot = botTable[sender]
    -- Accept current engine-qualified replies and the original Vanilla form.
    local engine, text
    local prefixes = {
        ["Combat Strategies: "] = "co",
        ["Non Combat Strategies: "] = "nc",
        ["Dead Strategies: "] = "de",
        ["Reaction Strategies: "] = "react",
        ["Strategies: "] = "co"
    }
    for prefix, name in pairs(prefixes) do
        if string.sub(message, 1, string.len(prefix)) == prefix then
            engine = name
            text = string.sub(message, string.len(prefix) + 1)
            break
        end
    end
    if engine then
        local list = {}
        local healer, tank = false, false
        local splitted = splitString2(text, ",")
        for i = 1, tablelength(splitted) do
            local name = trim2(splitted[i])
            if name == "nc" and string.find(message, 'Strategies: ') == 1 then
                engine = "nc"
            elseif name ~= "" then
                table.insert(list, name)
            end
            if name == "heal" or name == "holy" or name == "discipline" or name == "restoration" then healer = true end
            if name == "tank" or name == "bear" or name == "protection" or name == "tank feral" then tank = true end
        end
        if not bot.strategy then bot.strategy = {nc = {}, co = {}, de = {}, react = {}} end
        if engine == "co" then
            if tank then bot.role = "tank"
            elseif healer then bot.role = "heal"
            else bot.role = "dps" end
        end
        bot.strategy[engine] = list
    end
    if (string.find(message, 'Formation: ') == 1) then
        bot['formation'] = string.sub(message, 11)
    end
    if (string.find(message, 'Stance: ') == 1) then
        bot['stance'] = string.sub(message, 11)
    end
    if (string.find(message, 'Mana save level set: ') == 1) then
        bot['savemana'] = string.sub(message, 21)
    end
    if (string.find(message, 'Mana save level: ') == 1) then
        bot['savemana'] = string.sub(message, 17)
    end
    if (string.find(message, 'Loot strategy: ') == 1) then
        bot['loot'] = string.sub(message, 15)
    end
    if (string.find(message, 'rti: ') == 1) then
        bot['rti'] = string.sub(message, 5)
    end
    if (string.find(message, 'rti cc: ') == 1) then
        bot['rti_cc'] = string.sub(message, 5)
    end
end

function OnSystemMessage(message)
    if (string.find(message, 'Bot roster: ') == 1) then
        botTable = {}
        local text = string.sub(message, 13)
        local splitted = splitString2(text, ", ")
        for i = 1, tablelength(splitted) do
            local line = trim2(splitted[i])
            local on = string.sub(line, 1, 1)
            local pos = string.find(line, " ")
            local name = string.sub(line, 2, pos - 1)
            local cls = string.sub(line, pos + 1)

            if (botTable[name] == nil) then
                botTable[name] = {}
            end
            botTable[name]["class"] = cls
            botTable[name]["online"] = (on == "+")
        end
        return true
    end
    return false
end

SLASH_MANGOSBOT1 = '/bot'
function SlashCmdList.MANGOSBOT(msg, editbox) -- 4.
    if (msg == "" or msg == "roster") then
        if (BotRoster:IsVisible()) then
            BotRoster:Hide()
        else
            BotRoster.ShowRequest = true
            SendBotCommand(".bot list", "SAY")
            QueryBotParty()
        end
    end
    if (string.find(msg, "debug")) then
        local cmd = string.sub(msg, 7)
        if (string.len(cmd) == 0 and BotDebugPanel:IsVisible()) then
            BotDebugPanel:Hide()
        else
            BotDebugPanel:Show()
            BotDebugFilter = cmd;
        end
    end
end

local waitTable = {};
local waitFrame = nil;

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function wait(delay, func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("OnUpdate",function ()
      local elapse = 0.1
      local count = tablelength(waitTable);
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9}});
  return true;
end

function partyName(i)
    local p = UnitName("party"..i)
    local r = UnitName("raid"..i)
    if (r == nil) then return p end
    return r
end

function partySize()
    local p = GetNumPartyMembers()
    local r = GetNumRaidMembers()
    if (r == 0) then return p end
    return r
end

function botCount()
  local count = 0
  for _ in pairs(botTable) do count = count + 1 end
  return count
end

--[[
Ordered table iterator, allow to iterate on the natural order of the keys of a
table.

Example:
]]

function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    local key = nil
    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
    else
        -- fetch the next value
        for i = 1,table.getn(t.__orderedIndex) do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

print("MangosBOT Addon is loaded");
