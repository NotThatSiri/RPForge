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
local GROUP_SECONDS = 120 -- messages from the same person within this time share one header
local PORTRAIT = 46        -- the round portrait area at the left of a message
local EVENTS = {
    CHAT_MSG_SAY = "SAY", CHAT_MSG_YELL = "YELL", CHAT_MSG_EMOTE = "EMOTE", CHAT_MSG_TEXT_EMOTE = "TEXT_EMOTE",
}
local CIRCLE_MASK = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
local RING = "Interface\\Minimap\\MiniMap-TrackingBorder"
local CLASS_CIRCLES = "Interface\\TargetingFrame\\UI-Classes-Circles"

local messages = {} -- { at, kind, sender, guid, text, language }
local window, scroll, content
local rows = {}     -- one frame per shown message, in order

-- Colours and text ---------------------------------------------------------------------------------

local function TypeColor(kind)
    local info = ChatTypeInfo and ChatTypeInfo[kind == "TEXT_EMOTE" and "EMOTE" or kind]
    if info and info.r then return info.r, info.g, info.b end
    if kind == "YELL" then return 1, 0.25, 0.25 end
    if kind == "SAY" then return 1, 1, 1 end
    return 1, 0.5, 0.25
end

local function Hex(r, g, b)
    return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

local OOC_COLOR = "|cff8c8c8c"

-- Speech in "quotes" gets the Say colour; ((OOC)) is dimmed. Text keeps any links it already has.
local function Decorate(text, kind)
    local sayHex = Hex(TypeColor("SAY"))
    if kind == "EMOTE" or kind == "TEXT_EMOTE" then
        text = text:gsub('(".-")', sayHex .. "%1|r")
        text = text:gsub("(\226\128\156.-\226\128\157)", sayHex .. "%1|r") -- “curly quotes”
    end
    text = text:gsub("(%(%(.-%)%))", OOC_COLOR .. "%1|r")
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
    return c and (Hex(c.r, c.g, c.b) .. plain .. "|r") or plain, fields
end

local function Header(msg)
    local name = SpeakerName(msg)
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
    if unit then
        SetPortraitTexture(row.portrait, unit)
        row.portrait:Show()
        row.icon:Hide()
        return
    end
    row.portrait:Hide()
    row.icon:Show()
    if fields and fields.IC and fields.IC ~= "" then
        UI.SetIcon(row.icon, tonumber(fields.IC) or fields.IC)
        row.icon:SetTexCoord(0, 1, 0, 1)
        return
    end
    local class = ClassOf(msg.guid)
    local coords = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if coords then
        row.icon:SetTexture(CLASS_CIRCLES)
        row.icon:SetTexCoord(unpack(coords))
    else
        UI.SetIcon(row.icon, nil)
        row.icon:SetTexCoord(0, 1, 0, 1)
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
        -- The round picture sits inside the game's own round border (the minimap button ring).
        row.portrait = holder:CreateTexture(nil, "ARTWORK")
        row.portrait:SetSize(30, 30)
        row.portrait:SetPoint("TOPLEFT", 10, -7)
        row.icon = holder:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(30, 30)
        row.icon:SetPoint("TOPLEFT", 10, -7)
        if row.icon.SetMask then row.icon:SetMask(CIRCLE_MASK) end
        local ring = holder:CreateTexture(nil, "OVERLAY")
        ring:SetTexture(RING)
        ring:SetSize(PORTRAIT * 1.71, PORTRAIT * 1.71)
        ring:SetPoint("TOPLEFT", 0, 0)
        row.header = UI.Text(row, "", 12, "text")
        row.header:SetPoint("TOPLEFT", PORTRAIT + 6, -4)
        row.header:SetWordWrap(false)
        row.time = UI.Text(row, "", 10, "muted", "RIGHT")
        row.time:SetPoint("TOPRIGHT", -4, -5)
        row.header:SetPoint("RIGHT", row.time, "LEFT", -8, 0)
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
    return previous and previous.guid == msg.guid and previous.kind ~= "TEXT_EMOTE" and msg.kind ~= "TEXT_EMOTE"
        and (msg.at - previous.at) <= GROUP_SECONDS
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
    UI.Divider(window, -25, 1)

    scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -32)
    scroll:SetPoint("BOTTOMRIGHT", -26, 12)
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
