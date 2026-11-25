-- RP Forge: the RP chat window.
--
-- A window of its own that shows only Say, Emote and Yell from people nearby (your normal chat is left
-- alone). Each message shows the speaker's portrait in a round frame, their roleplay name in its colour
-- and the time. Speech inside emotes is coloured like Say, and ((OOC)) text is dimmed.
-- Two layouts (Settings > Appearance): game style ("Kiri says: ...") or story style (Kiri: "...").
-- The last messages are kept per character, so the window survives a reload.
local _, RPF = ...
local UI = RPF.UI
local Sharing = RPF.Sharing

local Chat = RPF.NewModule("RPChat")
RPF.RPChat = Chat

local MAX_MESSAGES = 200
-- Messages in a row from the same person share one header (until someone else speaks, they switch
-- between Say/Emote/Yell, change target, or pause longer than this).
local GROUP_SECONDS = 15 * 60
local PORTRAIT = 46        -- the round portrait area at the left of a message
local EVENTS = {
    CHAT_MSG_SAY = "SAY", CHAT_MSG_YELL = "YELL", CHAT_MSG_EMOTE = "EMOTE", CHAT_MSG_TEXT_EMOTE = "TEXT_EMOTE",
    -- Only with "Party and raid in RP chat" on (Settings > General).
    CHAT_MSG_PARTY = "PARTY", CHAT_MSG_PARTY_LEADER = "PARTY", CHAT_MSG_RAID = "RAID", CHAT_MSG_RAID_LEADER = "RAID",
    CHAT_MSG_RAID_WARNING = "RAID_WARNING",
}
local GROUP_KINDS = { PARTY = " (party)", RAID = " (raid)", RAID_WARNING = " (raid warning)" }
local CIRCLE_MASK = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
local CLASS_CIRCLES = "Interface\\TargetingFrame\\UI-Classes-Circles"

local messages = {} -- { at, kind, sender, guid, text, language }
local window, scroll, content
local rows = {}     -- one frame per shown message, in order

-- Colours and text ---------------------------------------------------------------------------------

local function TypeColor(kind)
    -- Light themes bring their own chat colours so text stays readable.
    local theme = UI.THEMES[UI.themeKey]
    local own = theme and theme.chat and theme.chat[kind == "TEXT_EMOTE" and "EMOTE" or kind]
    if own then return own[1], own[2], own[3] end
    local info = ChatTypeInfo and ChatTypeInfo[kind == "TEXT_EMOTE" and "EMOTE" or kind]
    if info and info.r then return info.r, info.g, info.b end
    if kind == "YELL" then return 1, 0.25, 0.25 end
    if kind == "SAY" then return 1, 1, 1 end
    return 1, 0.5, 0.25
end

local function Hex(r, g, b)
    return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

local function OOCColor() return UI.ColorCode("muted") end

-- On a light theme, very light colours (a white name) are darkened so they can be read.
local function Readable(r, g, b)
    local theme = UI.THEMES[UI.themeKey]
    if theme and theme.light and (0.3 * r + 0.59 * g + 0.11 * b) > 0.7 then
        return r * 0.55, g * 0.55, b * 0.55
    end
    return r, g, b
end

-- Speech in "quotes" gets the Say colour; ((OOC)) is dimmed. Text keeps any links it already has.
local function Decorate(text, kind)
    local sayHex = Hex(TypeColor("SAY"))
    if kind == "EMOTE" or kind == "TEXT_EMOTE" then
        text = text:gsub('(".-")', sayHex .. "%1|r")
        text = text:gsub("(\226\128\156.-\226\128\157)", sayHex .. "%1|r") -- “curly quotes”
    end
    text = text:gsub("(%(%(.-%)%))", OOCColor() .. "%1|r")
    return text
end

local function Style()
    return RPF.db.settings.chatStyle == "story" and "story" or "game"
end

-- The player's class token ("WARRIOR"...) from their GUID, or nil.
local function ClassOf(guid)
    if not guid or not GetPlayerInfoByGUID then return nil end
    local _, class = GetPlayerInfoByGUID(guid)
    return class
end

local function ShortName(name)
    return Ambiguate and Ambiguate(name or "", "none") or (name or "")
end

-- The speaker's roleplay name (with title and colour) or their character name in class colour.
local function SpeakerName(msg)
    local fields
    if msg.guid == UnitGUID("player") then
        fields = Sharing.BuildFields()
    else
        fields = Sharing.GetProfile(msg.sender) or Sharing.GetProfile(ShortName(msg.sender))
    end
    if fields and fields.NA and fields.NA ~= "" then
        local name = fields.NA
        if fields.PX and fields.PX ~= "" then
            -- Put the title inside the name's colour if the name is coloured.
            local colour, rest = name:match("^(|c%x%x%x%x%x%x%x%x)(.*)$")
            name = colour and (colour .. fields.PX .. " " .. rest) or (fields.PX .. " " .. name)
        end
        return name, fields
    end
    local class = ClassOf(msg.guid)
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    local plain = ShortName(msg.sender)
    return c and (Hex(Readable(c.r, c.g, c.b)) .. plain .. "|r") or plain, fields
end

-- Who the speaker had targeted: their roleplay name if known, otherwise their name in class colour.
local function TargetName(msg)
    if not msg.target then return nil end
    local fields = Sharing.GetProfile(msg.target) or Sharing.GetProfile(ShortName(msg.target))
    if fields and fields.NA and fields.NA ~= "" then return fields.NA end
    local class = ClassOf(msg.targetGuid)
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    local plain = ShortName(msg.target)
    return c and (Hex(Readable(c.r, c.g, c.b)) .. plain .. "|r") or plain
end

local function Header(msg)
    local name = SpeakerName(msg)
    local target = TargetName(msg)
    if target then name = name .. UI.ColorCode("muted") .. "  ->  |r" .. target end
    local r, g, b = TypeColor(msg.kind)
    local tail = ""
    if GROUP_KINDS[msg.kind] then
        tail = GROUP_KINDS[msg.kind] .. (Style() == "game" and ":" or "")
    elseif Style() == "game" then
        if msg.kind == "SAY" then tail = " says:" elseif msg.kind == "YELL" then tail = " yells:" end
    elseif msg.kind == "YELL" then
        tail = " (yelling)"
    end
    return name .. Hex(r, g, b) .. tail .. "|r"
end

local function Body(msg)
    local text = msg.text or ""
    if msg.kind == "TEXT_EMOTE" then
        -- "Kiri waves at you." -> "waves at you." under Kiri's name.
        local short = ShortName(msg.sender)
        if short ~= "" and text:sub(1, #short) == short then text = strtrim(text:sub(#short + 1)) end
    end
    if msg.language and msg.language ~= "" and msg.language ~= GetDefaultLanguage("player") then
        text = "[" .. msg.language .. "] " .. text
    end
    if Style() == "story" and (msg.kind == "SAY" or msg.kind == "YELL") then
        text = '"' .. text .. '"'
    end
    return Decorate(text, msg.kind)
end

-- Portraits -------------------------------------------------------------------------------------

-- A unit the game can show right now for this player (target, mouseover, group, nameplates...).
local function FindUnit(guid)
    if not guid then return nil end
    for _, unit in ipairs({ "player", "target", "mouseover", "focus" }) do
        if RPF.UnitGUID(unit) == guid then return unit end
    end
    for i = 1, 4 do if RPF.UnitGUID("party" .. i) == guid then return "party" .. i end end
    for i = 1, 40 do if RPF.UnitGUID("raid" .. i) == guid then return "raid" .. i end end
    if C_NamePlate and C_NamePlate.GetNamePlates then
        for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
            local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
            if unit and not RPF.IsSecret(unit) and RPF.UnitGUID(unit) == guid then return unit end
        end
    end
    return nil
end

-- The game's portrait if we can see them; otherwise their profile icon; otherwise a round class icon.
local function SetPortrait(row, msg, fields)
    local unit = FindUnit(msg.guid)
    -- Only one of the three pictures is shown. The masked (rounded) icon can't take tex coords, so the
    -- class icon, which needs them and is already round, has its own unmasked texture.
    row.portrait:Hide()
    row.icon:Hide()
    row.classIcon:Hide()
    if unit then
        SetPortraitTexture(row.portrait, unit)
        row.portrait:Show()
        return
    end
    if fields and fields.IC and fields.IC ~= "" then
        UI.SetIcon(row.icon, tonumber(fields.IC) or fields.IC)
        row.icon:Show()
        return
    end
    local class = ClassOf(msg.guid)
    local coords = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if coords then
        row.classIcon:SetTexCoord(unpack(coords))
        row.classIcon:Show()
    else
        UI.SetIcon(row.icon, nil)
        row.icon:Show()
    end
end

-- Rows -------------------------------------------------------------------------------------------------

local function NewRow(msg, grouped)
    local row = CreateFrame("Frame", nil, content)
    row.msg, row.grouped = msg, grouped
    if not grouped then
        local holder = CreateFrame("Frame", nil, row)
        holder:SetSize(PORTRAIT, PORTRAIT)
        holder:SetPoint("TOPLEFT", 0, 0)
        -- A thin ring in the theme's accent colour, like the Home portrait: the game's round shape
        -- as a smooth accent disc, a dark disc just inside it, and the round picture on top.
        local DISC = 38
        local a, w = UI.Color("accent"), UI.Color("window")
        local ring = holder:CreateTexture(nil, "BACKGROUND")
        ring:SetTexture(CIRCLE_MASK)
        ring:SetSize(DISC, DISC)
        ring:SetPoint("TOPLEFT", 2, -2)
        ring:SetVertexColor(a[1], a[2], a[3], 1)
        local inner = holder:CreateTexture(nil, "BORDER")
        inner:SetTexture(CIRCLE_MASK)
        inner:SetSize(DISC - 4, DISC - 4)
        inner:SetPoint("CENTER", ring, "CENTER", 0, 0)
        inner:SetVertexColor(w[1], w[2], w[3], 1)
        row.portrait = holder:CreateTexture(nil, "ARTWORK")
        row.portrait:SetSize(DISC - 6, DISC - 6)
        row.portrait:SetPoint("CENTER", ring, "CENTER", 0, 0)
        row.icon = holder:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(DISC - 6, DISC - 6)
        row.icon:SetPoint("CENTER", ring, "CENTER", 0, 0)
        if row.icon.SetMask then row.icon:SetMask(CIRCLE_MASK) end
        row.classIcon = holder:CreateTexture(nil, "ARTWORK")
        row.classIcon:SetSize(DISC - 6, DISC - 6)
        row.classIcon:SetPoint("CENTER", ring, "CENTER", 0, 0)
        row.classIcon:SetTexture(CLASS_CIRCLES)
        row.header = UI.Text(row, "", 12, "text")
        row.header:SetPoint("TOPLEFT", PORTRAIT + 6, -4)
        row.header:SetWordWrap(false)
        row.time = UI.Text(row, "", 10, "muted", "RIGHT")
        row.time:SetPoint("TOPRIGHT", -4, -5)
        row.header:SetPoint("RIGHT", row.time, "LEFT", -8, 0)
    end
    -- Hover shows a faint band (and the time on grouped lines); a click opens the text to copy.
    row:EnableMouse(true)
    row.hover = row:CreateTexture(nil, "BACKGROUND")
    row.hover:SetTexture(UI.WHITE)
    row.hover:SetPoint("TOPLEFT", PORTRAIT + 2, grouped and 1 or 0)
    row.hover:SetPoint("BOTTOMRIGHT", 0, -1)
    local tc = UI.Color("text")
    row.hover:SetVertexColor(tc[1], tc[2], tc[3], 0.06)
    row.hover:Hide()
    row:SetScript("OnEnter", function(self)
        self.hover:Show()
        if self.grouped then
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:AddLine(date("%H:%M", self.msg.at), 0.9, 0.9, 0.9)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        self.hover:Hide()
        GameTooltip:Hide()
    end)
    row:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then Chat.CopyMessage(self.msg) end
    end)
    row.body = UI.Text(row, "", 12, "text")
    row.body:SetSpacing(2)
    row.body:SetPoint("TOPLEFT", PORTRAIT + 6, grouped and 0 or -22)
    return row
end

-- Fill a row's texts (and the portrait the first time).
local function FillRow(row, firstTime)
    local msg = row.msg
    local r, g, b = TypeColor(msg.kind)
    row.body:SetTextColor(r, g, b, 1)
    row.body:SetText(Body(msg))
    if not row.grouped then
        local _, fields = SpeakerName(msg)
        row.header:SetText(Header(msg))
        row.time:SetText(date("%H:%M", msg.at))
        if firstTime then SetPortrait(row, msg, fields) end
    end
end

local function AtBottom()
    return scroll:GetVerticalScroll() >= (scroll:GetVerticalScrollRange() - 4)
end

local function Layout(keepBottom)
    if not window then return end
    local width = math.max(200, scroll:GetWidth() - 4)
    content:SetWidth(width)
    local y = 6
    for i, row in ipairs(rows) do
        if not row.grouped and i > 1 then y = y + 8 end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetWidth(width)
        row.body:SetWidth(width - PORTRAIT - 12)
        local height = row.body:GetStringHeight() + (row.grouped and 2 or 24)
        if not row.grouped then height = math.max(height, PORTRAIT - 4) end
        row:SetHeight(height)
        y = y + height
    end
    content:SetHeight(y + 6)
    if keepBottom then
        C_Timer.After(0, function() if scroll then scroll:SetVerticalScroll(scroll:GetVerticalScrollRange()) end end)
    end
end

local function GroupsWith(previous, msg)
    return previous and previous.guid == msg.guid and previous.kind == msg.kind and msg.kind ~= "TEXT_EMOTE"
        and previous.target == msg.target and (msg.at - previous.at) <= GROUP_SECONDS
end

local function AddRow(msg, previous)
    local row = NewRow(msg, GroupsWith(previous, msg))
    rows[#rows + 1] = row
    FillRow(row, true)
    -- Keep only as many rows as messages.
    while #rows > MAX_MESSAGES do
        local old = table.remove(rows, 1)
        old:Hide()
        old:SetParent(nil)
    end
end

-- Show every stored message again (when the window opens, the style changes, or names arrive).
function Chat.Refresh()
    if not window then return end
    for _, row in ipairs(rows) do FillRow(row, false) end
    Layout(AtBottom())
end

-- Sending -------------------------------------------------------------------------------------------

local MAX_LENGTH = 255
local MODE_LABELS = { SAY = "Say:", EMOTE = "Emote:", YELL = "Yell:" }
local MODE_HINTS = {
    SAY = "Say something. /e to emote, /y to yell. Shift+Enter: new line.",
    EMOTE = "Emote. /s to say, /y to yell. Shift+Enter: new line.",
    YELL = "Yell. /s to say, /e to emote. Shift+Enter: new line.",
}
local PREFIXES = { ["/s "] = "SAY", ["/say "] = "SAY", ["/e "] = "EMOTE", ["/me "] = "EMOTE", ["/emote "] = "EMOTE",
    ["/y "] = "YELL", ["/yell "] = "YELL" }

-- Split text into posts of at most 255 letters, at spaces, each ending in " (1/3)" when there are several.
function Chat.SplitPost(text)
    text = strtrim((text or ""):gsub("[\r\n]+", " "):gsub("%s+", " "))
    if text == "" then return {} end
    if #text <= MAX_LENGTH then return { text } end
    local parts
    for guess = 2, 50 do
        local room = MAX_LENGTH - #(" (" .. guess .. "/" .. guess .. ")")
        parts = {}
        local rest = text
        while #rest > room do
            local cut = rest:sub(1, room):match("^.*()%s") or (room + 1) -- last space that fits
            parts[#parts + 1] = strtrim(rest:sub(1, cut - 1))
            rest = strtrim(rest:sub(cut))
        end
        if rest ~= "" then parts[#parts + 1] = rest end
        if #parts <= guess then break end
    end
    for i, part in ipairs(parts) do parts[i] = part .. " (" .. i .. "/" .. #parts .. ")" end
    return parts
end

-- Send what's in the typing box. Called straight from the Enter key: outside instances the game only
-- lets addons post Say and Yell from a key press, so every part is sent right now, in order.
local MyTypingChanged -- defined with the typing indicator below
local function SendFromBox(box)
    local text = box:GetText() or ""
    local mode = RPF.db.settings.chatMode or "SAY"
    local lower = text:lower()
    for prefix, prefixMode in pairs(PREFIXES) do
        if lower:sub(1, #prefix) == prefix then
            mode, text = prefixMode, text:sub(#prefix + 1)
            break
        end
    end
    text = RPF.Accents.Apply(text, mode)
    for _, part in ipairs(Chat.SplitPost(text)) do
        SendChatMessage(part, mode)
    end
    box:SetText("")
    MyTypingChanged("")
end

-- Typing indicator ------------------------------------------------------------------------------------
--
-- While you write in the RP chat box, RP Forge users near you get an invisible addon whisper ("T" with
-- "1"), repeated every few seconds while you keep typing, and "0" when the box is emptied. Their RP chat
-- shows "Kiri Stormcrest is typing..." above the box. It fades by itself if no update comes.
-- Near you = people you can see (target, mouseover, group, nameplates) or heard in the last 10 minutes,
-- and known to use RP Forge. Settings > General turns it off both ways.
-- The game's own chat box does the same for say and emote, and for party and raid it goes to the group
-- ("1P@<guid>": a letter after the 1 or 0 says where, then the sender's ID). With the RP chat closed, a bar under
-- the chat shows who is typing.

local TYPING_REPEAT = 6    -- seconds between "still typing" messages
local TYPING_TIMEOUT = 12  -- seconds before someone's "is typing" disappears without news
local TYPING_RECENT = 10 * 60
local TYPING_MAX_PEOPLE = 6
local typists = {}         -- typists[shortName] = { name = full sender, at = GetTime() }
local typingTicker
local myTyping = { on = false, sent = 0 }

local function TypingEnabled() return RPF.db.settings.typingIndicator ~= false end

-- Does this player use RP Forge? Heard on our addon channel, or their profile says so.
local function UsesRPForge(name)
    local vc = RPF.GetModule and RPF.GetModule("VersionCheck")
    if vc and vc.peers and vc.peers[ShortName(name)] then return true end
    if typists[ShortName(name)] then return true end
    local fields = Sharing.GetProfile(name)
    return fields and type(fields.VA) == "string" and fields.VA:find("RPForge/", 1, true) ~= nil
end

local function NearbyForgeUsers()
    local out, seen = {}, { [ShortName(UnitName("player") or "")] = true }
    local function Add(name)
        if not name or name == "" or #out >= TYPING_MAX_PEOPLE then return end
        local short = ShortName(name)
        if seen[short] then return end
        seen[short] = true
        if UsesRPForge(name) then out[#out + 1] = name end
    end
    local function AddUnit(unit)
        Add(RPF.PlayerName(unit))
    end
    AddUnit("target")
    AddUnit("mouseover")
    AddUnit("focus")
    for i = 1, 40 do AddUnit("raid" .. i) end
    for i = 1, 4 do AddUnit("party" .. i) end
    local now = time()
    for i = #messages, 1, -1 do
        local m = messages[i]
        if now - (m.at or 0) > TYPING_RECENT then break end
        Add(m.sender)
    end
    for i = 1, 40 do AddUnit("nameplate" .. i) end
    return out
end

-- where: nil for the RP chat window, or "SAY", "EMOTE", "PARTY" or "RAID" from the game's chat box.
local WHERE_CODE = { SAY = "S", EMOTE = "E", PARTY = "P", RAID = "R" }
local WHERE_TEXT = { E = " an emote", P = " in party", R = " in raid" }

local function SendTyping(state, where)
    -- Your character's ID goes along, so your own message coming back (party, raid) is never shown: names
    -- can't be trusted for that on every client.
    local payload = state .. (where and WHERE_CODE[where] or "") .. "@" .. (UnitGUID("player") or "")
    if where == "PARTY" or where == "RAID" then
        RPF.Comm.Send("T", payload, where)
        return
    end
    for _, name in ipairs(NearbyForgeUsers()) do
        RPF.Comm.Send("T", payload, "WHISPER", name)
    end
end

-- Called whenever the text in your box changes because you typed.
MyTypingChanged = function(text)
    if not TypingEnabled() then return end
    local typing = strtrim(text or "") ~= ""
    if typing and (not myTyping.on or GetTime() - myTyping.sent >= TYPING_REPEAT) then
        myTyping.on, myTyping.sent = true, GetTime()
        SendTyping("1")
    elseif not typing and myTyping.on then
        myTyping.on = false
        SendTyping("0")
    end
end

-- The game's chat box: say, emote, party and raid (slash commands being typed don't count).
local GAME_KINDS = {
    SAY = "SAY", EMOTE = "EMOTE", PARTY = "PARTY", PARTY_LEADER = "PARTY",
    RAID = "RAID", RAID_LEADER = "RAID", RAID_WARNING = "RAID",
}
local gameTyping = { where = nil, sent = 0 }

local function GameTypingStopped()
    if gameTyping.where then
        SendTyping("0", gameTyping.where)
        gameTyping.where = nil
    end
end

local function GameTypingChanged(editBox)
    if not TypingEnabled() then return end
    local text = strtrim(editBox:GetText() or "")
    local chatType = editBox:GetAttribute("chatType") or editBox.chatType
    local where = (text ~= "" and text:sub(1, 1) ~= "/") and GAME_KINDS[chatType] or nil
    if gameTyping.where and gameTyping.where ~= where then GameTypingStopped() end
    if where and (gameTyping.where ~= where or GetTime() - gameTyping.sent >= TYPING_REPEAT) then
        gameTyping.where, gameTyping.sent = where, GetTime()
        SendTyping("1", where)
    end
end

local function HookGameChat()
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local box = _G["ChatFrame" .. i .. "EditBox"]
        if box and not box.rpfTyping then
            box.rpfTyping = true
            box:HookScript("OnTextChanged", function(self, userInput)
                if userInput then GameTypingChanged(self) end
            end)
            box:HookScript("OnEditFocusLost", GameTypingStopped)
            box:HookScript("OnHide", GameTypingStopped)
        end
    end
end
HookGameChat()

-- The bar under the game's chat that shows who is typing while the RP chat window is closed. Drag it to
-- move it; the place is remembered.
local bar
local function TypingBar(text)
    if text == "" then
        if bar then bar:Hide() end
        return
    end
    if not bar then
        bar = UI.Panel(UIParent, "panel", "border")
        bar:SetHeight(22)
        bar:SetFrameStrata("MEDIUM")
        bar:SetClampedToScreen(true)
        bar:SetMovable(true)
        bar:EnableMouse(true)
        bar:RegisterForDrag("LeftButton")
        bar.text = UI.Text(bar, "", 11, "text")
        bar.text:SetPoint("LEFT", 8, 0)
        local pos = RPF.db.settings.typingBarPos
        if pos then
            bar:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
        elseif ChatFrame1 then
            bar:SetPoint("TOPLEFT", ChatFrame1, "BOTTOMLEFT", -4, -34)
        else
            bar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 30, 90)
        end
        bar:SetScript("OnDragStart", function(self) self:StartMoving() end)
        bar:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, _, relativePoint, x, y = self:GetPoint()
            RPF.db.settings.typingBarPos = { point, relativePoint, x, y }
        end)
        bar:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("Typing")
            GameTooltip:AddLine("RP Forge users near you or in your group who are writing. Drag to move.", 0.9, 0.9, 0.9, true)
            GameTooltip:Show()
        end)
        bar:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    bar.text:SetText(text)
    bar:SetWidth(bar.text:GetStringWidth() + 16)
    bar:Show()
end

local function TypingName(info)
    local fields = Sharing.GetProfile(info.name) or Sharing.GetProfile(ShortName(info.name))
    if fields and fields.NA and fields.NA ~= "" then return fields.NA end
    return ShortName(info.name)
end

local function ShowTyping()
    local now, names, only = GetTime(), {}, nil
    for short, info in pairs(typists) do
        if now - info.at > TYPING_TIMEOUT then
            typists[short] = nil
        else
            names[#names + 1] = TypingName(info)
            only = info
        end
    end
    table.sort(names)
    local text = ""
    if #names == 1 then
        text = names[1] .. UI.ColorCode("muted") .. " is typing" .. (WHERE_TEXT[only.where or ""] or "") .. "...|r"
    elseif #names == 2 then
        text = names[1] .. UI.ColorCode("muted") .. " and |r" .. names[2] .. UI.ColorCode("muted") .. " are typing...|r"
    elseif #names > 2 then
        text = UI.ColorCode("muted") .. "Several people are typing...|r"
    end
    -- In the RP chat window when it's open, otherwise in the bar under the game's chat.
    local inWindow = window ~= nil and window:IsShown()
    if window and window.typing then window.typing:SetText(inWindow and text or "") end
    TypingBar(inWindow and "" or text)
    if #names == 0 and typingTicker then
        typingTicker:Cancel()
        typingTicker = nil
    end
end

local function SomeoneTyping(sender, on, where)
    local short = ShortName(sender)
    if on then
        typists[short] = { name = sender, at = GetTime(), where = where ~= "" and where or nil }
        if not typingTicker then typingTicker = C_Timer.NewTicker(1, ShowTyping) end
    else
        typists[short] = nil
    end
    ShowTyping()
end

RPF.Comm.On("T", function(payload, sender)
    if not TypingEnabled() then return end
    if type(payload) ~= "string" then return end
    local state, where, guid = payload:match("^([01])(%u?)@?(.*)$")
    if not state then return end
    if guid ~= "" and guid == UnitGUID("player") then return end
    if ShortName(sender) == ShortName(UnitName("player") or "") then return end
    SomeoneTyping(sender, state == "1", where)
end)

-- The window -----------------------------------------------------------------------------------------

local function SavePosition()
    local point, _, relativePoint, x, y = window:GetPoint(1)
    RPF.db.chatWindow = { point = point, relativePoint = relativePoint, x = x, y = y, w = window:GetWidth(), h = window:GetHeight() }
end

local function Build()
    window = CreateFrame("Frame", "RPForgeChatWindow", UIParent, UI.BACKDROP_TEMPLATE)
    local saved = RPF.db.chatWindow or {}
    window:SetSize(saved.w or 460, saved.h or 380)
    if saved.point then
        window:SetPoint(saved.point, UIParent, saved.relativePoint or saved.point, saved.x or 0, saved.y or 0)
    else
        window:SetPoint("BOTTOMLEFT", 40, 260)
    end
    window:SetFrameStrata("MEDIUM")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:SetResizable(true)
    if window.SetResizeBounds then window:SetResizeBounds(320, 220, 1000, 900) elseif window.SetMinResize then window:SetMinResize(320, 220) end
    window:EnableMouse(true)
    UI.Backdrop(window, "window", "border")
    window.themeKey = UI.themeKey

    local title = CreateFrame("Frame", nil, window)
    title:SetPoint("TOPLEFT", 1, -1)
    title:SetPoint("TOPRIGHT", -1, -1)
    title:SetHeight(24)
    title:EnableMouse(true)
    title:RegisterForDrag("LeftButton")
    title:SetScript("OnDragStart", function() window:StartMoving() end)
    title:SetScript("OnDragStop", function() window:StopMovingOrSizing(); SavePosition() end)
    local name = UI.Text(title, "RP chat", 12, "accent")
    name:SetPoint("LEFT", 10, 0)
    local hint = UI.Text(title, "Say, Emote and Yell nearby", 10, "muted")
    hint:SetPoint("LEFT", name, "RIGHT", 10, 0)
    local close = CreateFrame("Button", nil, title)
    close:SetSize(24, 24)
    close:SetPoint("RIGHT", 0, 0)
    close.label = UI.Text(close, "X", 13, "muted", "CENTER")
    close.label:SetPoint("CENTER")
    close:SetScript("OnEnter", function(self) UI.SetTextColor(self.label, "bad") end)
    close:SetScript("OnLeave", function(self) UI.SetTextColor(self.label, "muted") end)
    close:SetScript("OnClick", function() Chat.Hide() end)

    -- Cogwheel: opens Settings > Appearance, where the RP chat layout is chosen.
    local cog = CreateFrame("Button", nil, title)
    cog:SetSize(22, 24)
    cog:SetPoint("RIGHT", close, "LEFT", -2, 0)
    cog.icon = cog:CreateTexture(nil, "ARTWORK")
    cog.icon:SetTexture("Interface\\AddOns\\" .. RPF.ADDON .. "\\Media\\Settings")
    cog.icon:SetSize(14, 14)
    cog.icon:SetPoint("CENTER")
    local function TintCog(key)
        local c = UI.Color(key)
        cog.icon:SetVertexColor(c[1], c[2], c[3], 1)
    end
    TintCog("muted")
    cog:SetScript("OnEnter", function(self)
        TintCog("accent")
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Chat settings", 1, 0.82, 0.45)
        GameTooltip:AddLine("Opens Settings > Appearance (RP chat layout).", 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    cog:SetScript("OnLeave", function() TintCog("muted"); GameTooltip:Hide() end)
    cog:SetScript("OnClick", function() UI.OpenSettings("appearance") end)
    UI.Divider(window, -25, 1)

    scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -32)
    -- The typing area at the bottom: a box that grows with the text. Start with /s, /e or /y to switch
    -- between Say, Emote and Yell, like the game's chat; the box takes that chat colour.
    local input = CreateFrame("Frame", nil, window)
    input:SetPoint("BOTTOMLEFT", 8, 18)
    input:SetPoint("BOTTOMRIGHT", -8, 18)
    input:SetHeight(52)
    window.input = input

    local boxFrame = UI.Panel(input, "panelAlt", "border")
    boxFrame:SetAllPoints()
    local modeLabel = UI.Text(boxFrame, "", 12, "text")
    modeLabel:SetPoint("TOPLEFT", 8, -7)
    -- Above the box on the right: your accent (click to change it), and how many posts a long text makes.
    local accentButton = CreateFrame("Button", nil, input)
    accentButton:SetHeight(16)
    accentButton:SetPoint("BOTTOMRIGHT", input, "TOPRIGHT", 0, 3)
    accentButton.label = UI.Text(accentButton, "", 11, "muted", "RIGHT")
    accentButton.label:SetPoint("RIGHT", 0, 0)
    accentButton:SetScript("OnClick", function(self) RPF.Accents.ShowMenu(self, true) end)
    accentButton:SetScript("OnEnter", function(self)
        UI.SetTextColor(self.label, "accent")
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Accent")
        GameTooltip:AddLine("Changes what you say and yell, and \"quoted\" words in emotes. Click to choose.", 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    accentButton:SetScript("OnLeave", function(self)
        UI.SetTextColor(self.label, "muted")
        GameTooltip:Hide()
    end)
    window.accentButton = accentButton
    window.parts = UI.Text(input, "", 10, "muted", "RIGHT")
    window.parts:SetPoint("RIGHT", accentButton, "LEFT", -10, 0)
    local box = CreateFrame("EditBox", nil, boxFrame)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetFont(UI.FONT, 12, "")
    box:SetPoint("TOPLEFT", modeLabel, "TOPRIGHT", 5, 1)
    box:SetPoint("BOTTOMRIGHT", -8, 6)
    box:SetMaxLetters(4000)
    window.box = box
    local placeholder = UI.Text(boxFrame, "", 11, "muted")
    placeholder:SetPoint("TOPLEFT", box, "TOPLEFT", 1, -1)
    placeholder:SetPoint("RIGHT", boxFrame, "RIGHT", -8, 0)
    placeholder:SetJustifyH("LEFT")
    placeholder:SetWordWrap(false)
    boxFrame:EnableMouse(true)
    boxFrame:SetScript("OnMouseDown", function() box:SetFocus() end)

    -- Colour the label, text and border for the current mode (full border while typing).
    local function ShowMode()
        local mode = RPF.db.settings.chatMode or "SAY"
        if not MODE_LABELS[mode] then mode = "SAY" end
        local r, g, b = TypeColor(mode)
        modeLabel:SetText(MODE_LABELS[mode])
        modeLabel:SetTextColor(r, g, b, 1)
        box:SetTextColor(r, g, b, 1)
        placeholder:SetText(MODE_HINTS[mode])
        boxFrame:SetBackdropBorderColor(r, g, b, box:HasFocus() and 1 or 0.45)
        if window.UpdateCorner then window.UpdateCorner() end
    end
    window.ShowMode = ShowMode
    -- Bottom-right corner: your accent, and how many posts a long text becomes.
    function window.UpdateCorner()
        local text = box:GetText() or ""
        local count = #Chat.SplitPost(RPF.Accents.Apply(text, RPF.db.settings.chatMode or "SAY"))
        local accent, active = RPF.Accents.Describe()
        window.accentButton.label:SetText("Accent: " .. (accent or "none") .. ((accent and not active) and " (off while not IC)" or ""))
        window.accentButton:SetWidth(window.accentButton.label:GetStringWidth() + 4)
        window.parts:SetText(count > 1 and (count .. " posts") or "")
    end
    ShowMode()
    box:SetScript("OnEditFocusGained", ShowMode)
    box:SetScript("OnEditFocusLost", ShowMode)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self)
        if IsShiftKeyDown() then
            self:Insert("\n")
            return
        end
        SendFromBox(self)
    end)
    box:SetScript("OnTextChanged", function(self, userInput)
        local text = self:GetText() or ""
        -- "/e " at the start switches to Emote (and so on); the command itself is removed.
        if userInput and text:sub(1, 1) == "/" then
            local lower = text:lower()
            for prefix, mode in pairs(PREFIXES) do
                if lower:sub(1, #prefix) == prefix then
                    RPF.db.settings.chatMode = mode
                    ShowMode()
                    self:SetText(text:sub(#prefix + 1))
                    return
                end
            end
        end
        -- Your accent shows as you type: each word changes once it's finished.
        if userInput then
            local changed, cursor = RPF.Accents.ApplyTyping(text, self:GetCursorPosition(), RPF.db.settings.chatMode or "SAY")
            if changed then
                self:SetText(changed)
                self:SetCursorPosition(cursor)
                return
            end
        end
        placeholder:SetShown(text == "")
        window.UpdateCorner()
        -- Grow from 2 to 6 lines as you type.
        local lines = math.max(2, math.min(6, math.ceil((self:GetHeight() > 0 and select(2, text:gsub("\n", "")) + 1) or 1)))
        local _, fontHeight = self:GetFont()
        local wanted = 14 + math.max(lines, math.ceil(((self.measure and self.measure:GetStringHeight()) or 0) / (fontHeight + 2))) * (fontHeight + 2)
        input:SetHeight(math.max(52, math.min(14 + 6 * (fontHeight + 2), wanted)))
    end)
    -- A hidden copy of the text to measure how many lines it wraps to.
    box.measure = input:CreateFontString(nil, "ARTWORK")
    box.measure:SetFont(UI.FONT, 12, "")
    box.measure:SetAlpha(0)
    box.measure:SetPoint("TOPLEFT", boxFrame, "TOPLEFT", 8, -6)
    box:HookScript("OnTextChanged", function(self)
        box.measure:SetWidth(math.max(50, boxFrame:GetWidth() - 16))
        box.measure:SetText(self:GetText() or "")
    end)

    window.typing = UI.Text(window, "", 11, "text")
    window.typing:SetPoint("BOTTOMLEFT", input, "TOPLEFT", 2, 5)
    window.typing:SetPoint("RIGHT", window.parts, "LEFT", -10, 0)
    window.typing:SetJustifyH("LEFT")
    window.typing:SetWordWrap(false)
    box:HookScript("OnTextChanged", function(self, userInput)
        if userInput then MyTypingChanged(self:GetText()) end
    end)

    scroll:SetPoint("BOTTOMRIGHT", input, "TOPRIGHT", -18, 22)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(300, 10)
    scroll:SetScrollChild(content)
    UI.SkinScrollBar(scroll)
    scroll:EnableMouseWheel(true)

    local grip = CreateFrame("Button", nil, window)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() window:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() window:StopMovingOrSizing(); SavePosition(); Layout(true) end)
    window:SetScript("OnSizeChanged", function() Layout(false) end)
    if window.SetResizeBounds then window:SetResizeBounds(320, 300, 1000, 900) elseif window.SetMinResize then window:SetMinResize(320, 300) end

    rows = {}
    local previous
    for _, msg in ipairs(messages) do
        AddRow(msg, previous)
        previous = msg
    end
    Layout(true)
end

function Chat.Show()
    if window and window.themeKey ~= UI.themeKey then
        window:Hide()
        window = nil
    end
    if not window then Build() end
    window:Show()
    ShowTyping()
    RPF.db.settings.chatOpen = true
    Chat.Refresh()
    Layout(true)
end

function Chat.Hide()
    if window then window:Hide() end
    RPF.db.settings.chatOpen = false
end

function Chat.Toggle()
    if window and window:IsShown() then Chat.Hide() else Chat.Show() end
end
RPForge_ToggleChat = Chat.Toggle -- for the key binding

-- Copying ------------------------------------------------------------------------------------------------

-- The game can't put text on the clipboard itself, so the text opens selected in a box: Ctrl+C copies it
-- and closes the box.
local copyFrame
function Chat.CopyMessage(msg)
    if not copyFrame then
        copyFrame = UI.Panel(UIParent, "window", "accent")
        copyFrame:SetSize(420, 86)
        copyFrame:SetFrameStrata("DIALOG")
        copyFrame:SetClampedToScreen(true)
        copyFrame:EnableMouse(true)
        local title = UI.Text(copyFrame, "COPY MESSAGE", 10, "muted")
        title:SetPoint("TOPLEFT", 12, -10)
        copyFrame.box = UI.EditBox(copyFrame, 396, 26)
        copyFrame.box:SetPoint("TOPLEFT", 12, -28)
        copyFrame.box:SetMaxLetters(0)
        local hint = UI.Text(copyFrame, "Ctrl+C to copy, Esc to close.", 10, "muted")
        hint:SetPoint("TOPLEFT", copyFrame.box, "BOTTOMLEFT", 0, -7)
        local box = copyFrame.box
        box:SetScript("OnEscapePressed", function() copyFrame:Hide() end)
        box:SetScript("OnEnterPressed", function() copyFrame:Hide() end)
        box:HookScript("OnEditFocusLost", function() copyFrame:Hide() end)
        -- Read only: typing puts the message back.
        box:HookScript("OnTextChanged", function(self, userInput)
            if userInput then
                self:SetText(copyFrame.text or "")
                self:HighlightText()
            end
        end)
        box:SetScript("OnKeyDown", function(self, key)
            if key == "C" and IsControlKeyDown() then C_Timer.After(0, function() copyFrame:Hide() end) end
        end)
    end
    copyFrame.text = msg.text or ""
    copyFrame:ClearAllPoints()
    if window and window:IsShown() then
        copyFrame:SetPoint("CENTER", window, "CENTER", 0, 0)
    else
        copyFrame:SetPoint("CENTER")
    end
    copyFrame:Show()
    copyFrame.box:SetText(copyFrame.text)
    copyFrame.box:SetFocus()
    copyFrame.box:HighlightText()
    copyFrame.box:SetCursorPosition(0)
    copyFrame.box:HighlightText()
end

-- Button on the game's chat ------------------------------------------------------------------------------

-- A small "RP" button above the right end of the main chat window: opens and closes the RP chat.
local chatButton
function Chat.UpdateChatButton()
    local wanted = RPF.db.settings.chatButton ~= false and ChatFrame1 ~= nil
    if not wanted then
        if chatButton then chatButton:Hide() end
        return
    end
    if not chatButton then
        chatButton = UI.Button(UIParent, "RP", 30, 20)
        chatButton:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", 2, 6)
        chatButton:SetFrameStrata("MEDIUM")
        chatButton:SetScript("OnClick", function() Chat.Toggle() end)
        chatButton:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("RP chat")
            GameTooltip:AddLine("Click to open or close the RP chat window.", 0.9, 0.9, 0.9, true)
            GameTooltip:Show()
        end)
        chatButton:HookScript("OnLeave", function() GameTooltip:Hide() end)
    end
    chatButton:Refresh()
    chatButton:Show()
end

-- Receiving ----------------------------------------------------------------------------------------------

local lastAsked = {}
local function OnChat(event, text, sender, language, _, _, _, _, _, _, _, _, guid)
    if not RPF.char then return end
    if GROUP_KINDS[EVENTS[event]] and not RPF.db.settings.chatGroup then return end
    local msg = { at = time(), kind = EVENTS[event], sender = sender, guid = guid, text = text, language = language }
    -- Whom were they speaking to? Only known when the game can see the speaker (you, your target,
    -- mouseover, group or nameplates): then their target is "<unit>target".
    local unit = FindUnit(guid)
    local targetUnit = unit and (unit == "player" and "target" or (unit .. "target"))
    local targetGuid = targetUnit and RPF.UnitGUID(targetUnit)
    if targetGuid and targetGuid ~= guid then
        msg.target = Sharing.MergedName(targetUnit) or RPF.PlayerName(targetUnit)
        msg.targetGuid = targetGuid
    end
    if typists[ShortName(sender)] then SomeoneTyping(sender, false) end
    local previous = messages[#messages]
    messages[#messages + 1] = msg
    while #messages > MAX_MESSAGES do table.remove(messages, 1) end
    -- Ask new speakers for their name card, at most once a minute each.
    if guid ~= UnitGUID("player") and (GetTime() - (lastAsked[sender] or -100)) > 60 then
        lastAsked[sender] = GetTime()
        Sharing.RequestTooltip(sender)
    end
    if window then
        local wasBottom = AtBottom()
        AddRow(msg, previous)
        Layout(wasBottom)
    end
end

for event in pairs(EVENTS) do
    RPF.OnEvent(event, function(...) OnChat(event, ...) end)
end

-- Names arrive after the first message: show them as soon as they do.
local refreshPending = false
RPF.Listen("PERSON_UPDATED", function()
    if not window or not window:IsShown() or refreshPending then return end
    refreshPending = true
    C_Timer.After(0.5, function()
        refreshPending = false
        Chat.Refresh()
    end)
end)
RPF.Listen("PROFILE_CHANGED", function()
    if window and window:IsShown() then
        Chat.Refresh()
        if window.UpdateCorner then window.UpdateCorner() end
    end
end)

RPF.Listen("DATA_READY", function()
    RPF.char.chatLog = RPF.char.chatLog or {}
    messages = RPF.char.chatLog
end)

function Chat:OnLogin()
    if RPF.db.settings.chatOpen then C_Timer.After(1, Chat.Show) end
    Chat.UpdateChatButton()
end

RPF.Listen("THEME_CHANGED", function()
    if chatButton then chatButton:Refresh() end
    if not window then return end
    local wasShown = window:IsShown()
    window:Hide()
    window = nil
    if wasShown then Chat.Show() end
end)

RPF.AddCommand("chat", "Open or close the RP chat window", function() Chat.Toggle() end)

BINDING_HEADER_RPFORGE = "RP Forge"
BINDING_NAME_RPFORGE_TOGGLE_CHAT = "Open or close RP chat"
BINDING_NAME_RPFORGE_TOGGLE_WINDOW = "Open or close RP Forge"
RPForge_ToggleWindow = function() UI.ToggleWindow() end
