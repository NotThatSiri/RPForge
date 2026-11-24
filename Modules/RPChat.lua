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
}
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
    if Style() == "game" then
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
        if UnitGUID(unit) == guid then return unit end
    end
    for i = 1, 4 do if UnitGUID("party" .. i) == guid then return "party" .. i end end
    for i = 1, 40 do if UnitGUID("raid" .. i) == guid then return "raid" .. i end end
    if C_NamePlate and C_NamePlate.GetNamePlates then
        for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
            local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
            if unit and UnitGUID(unit) == guid then return unit end
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
    if grouped then
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:AddLine(date("%H:%M", self.msg.at), 0.9, 0.9, 0.9)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
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
local MODES = { { "SAY", "Say" }, { "EMOTE", "Emote" }, { "YELL", "Yell" } }
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
    for _, part in ipairs(Chat.SplitPost(text)) do
        SendChatMessage(part, mode)
    end
    box:SetText("")
end

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
    -- The typing area at the bottom: mode buttons, then a box that grows with the text.
    local input = CreateFrame("Frame", nil, window, UI.BACKDROP_TEMPLATE)
    input:SetPoint("BOTTOMLEFT", 8, 18)
    input:SetPoint("BOTTOMRIGHT", -8, 18)
    input:SetHeight(84)
    window.input = input
    window.mode = UI.Segmented(input, MODES, 64, function(value) RPF.db.settings.chatMode = value end)
    window.mode:SetPoint("TOPLEFT", 0, 0)
    window.mode:SetValue(RPF.db.settings.chatMode or "SAY")
    window.parts = UI.Text(input, "", 10, "muted", "RIGHT")
    window.parts:SetPoint("TOPRIGHT", -2, -7)

    local boxFrame = UI.Panel(input, "panelAlt", "border")
    boxFrame:SetPoint("TOPLEFT", 0, -32)
    boxFrame:SetPoint("BOTTOMRIGHT", 0, 0)
    local box = CreateFrame("EditBox", nil, boxFrame)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetFont(UI.FONT, 12, "")
    local tc = UI.Color("text")
    box:SetTextColor(tc[1], tc[2], tc[3], 1)
    box:SetPoint("TOPLEFT", 8, -6)
    box:SetPoint("BOTTOMRIGHT", -8, 6)
    box:SetMaxLetters(4000)
    window.box = box
    local placeholder = UI.Text(boxFrame, "Type here. Enter sends, Shift+Enter makes a new line.", 11, "muted")
    placeholder:SetPoint("TOPLEFT", 9, -7)
    boxFrame:EnableMouse(true)
    boxFrame:SetScript("OnMouseDown", function() box:SetFocus() end)
    box:SetScript("OnEditFocusGained", function() UI.Backdrop(boxFrame, "panelAlt", "accent") end)
    box:SetScript("OnEditFocusLost", function() UI.Backdrop(boxFrame, "panelAlt", "border") end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self)
        if IsShiftKeyDown() then
            self:Insert("\n")
            return
        end
        SendFromBox(self)
    end)
    box:SetScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        placeholder:SetShown(text == "")
        local count = #Chat.SplitPost(text)
        window.parts:SetText(count > 1 and (count .. " posts") or "")
        -- Grow from 2 to 6 lines as you type.
        local lines = math.max(2, math.min(6, math.ceil((self:GetHeight() > 0 and select(2, text:gsub("\n", "")) + 1) or 1)))
        local _, fontHeight = self:GetFont()
        local wanted = 32 + 12 + math.max(lines, math.ceil(((self.measure and self.measure:GetStringHeight()) or 0) / (fontHeight + 2))) * (fontHeight + 2)
        input:SetHeight(math.max(84, math.min(32 + 12 + 6 * (fontHeight + 2), wanted)))
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

    scroll:SetPoint("BOTTOMRIGHT", input, "TOPRIGHT", -18, 8)
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

-- Receiving ----------------------------------------------------------------------------------------------

local lastAsked = {}
local function OnChat(event, text, sender, language, _, _, _, _, _, _, _, _, guid)
    if not RPF.char then return end
    local msg = { at = time(), kind = EVENTS[event], sender = sender, guid = guid, text = text, language = language }
    -- Whom were they speaking to? Only known when the game can see the speaker (you, your target,
    -- mouseover, group or nameplates): then their target is "<unit>target".
    local unit = FindUnit(guid)
    local targetUnit = unit and (unit == "player" and "target" or (unit .. "target"))
    if targetUnit and UnitExists(targetUnit) and UnitGUID(targetUnit) ~= guid then
        msg.target = Sharing.MergedName(targetUnit) or UnitName(targetUnit)
        msg.targetGuid = UnitGUID(targetUnit)
    end
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
RPF.Listen("PROFILE_CHANGED", function() if window and window:IsShown() then Chat.Refresh() end end)

RPF.Listen("DATA_READY", function()
    RPF.char.chatLog = RPF.char.chatLog or {}
    messages = RPF.char.chatLog
end)

function Chat:OnLogin()
    if RPF.db.settings.chatOpen then C_Timer.After(1, Chat.Show) end
end

RPF.Listen("THEME_CHANGED", function()
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
