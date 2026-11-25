-- RP Forge: the Whispers window.
--
-- With "Whispers window" on (Settings > Chat), whispers you get and send are kept here, one tab per
-- person, in place of the RP chat. Click a tab to read and answer; right-click it to clear or close it.
-- New whispers put a dot on the RP button by the game's chat and a count in the RP chat's title.
-- /w Name and /r in either box open the right tab. Whispers are kept per character, so they survive a
-- reload. The messages look like the RP chat's (RPChat.lua draws them).
local _, RPF = ...
local UI = RPF.UI
local Chat = RPF.RPChat

local Whispers = {}
RPF.Whispers = Whispers

local MAX_PER_PERSON = 100 -- messages kept for each person
local MAX_PEOPLE = 20      -- conversations kept (the ones used last)
local TAB_MAX_WIDTH = 140
local MORE_WIDTH = 74

local window, view
local current -- key of the conversation shown

local function Store() return RPF.char and RPF.char.whispers end
local function Short(name) return Ambiguate and Ambiguate(name or "", "none") or (name or "") end
local function Key(name) return Short(name):lower() end

-- Conversations in tab order: the order they started in.
function Whispers.List()
    local list = {}
    for key, c in pairs(Store() or {}) do
        c.key = key
        list[#list + 1] = c
    end
    table.sort(list, function(a, b)
        if (a.started or 0) ~= (b.started or 0) then return (a.started or 0) < (b.started or 0) end
        return a.key < b.key
    end)
    return list
end

-- The conversation with this person, made when create is set. Returns it and its key.
local function Conversation(name, create)
    local store = Store()
    if not store or type(name) ~= "string" or RPF.IsSecret(name) or name == "" then return end
    local key = Key(name)
    if not store[key] and create then
        store[key] = { name = Short(name), target = name, msgs = {}, unread = 0, started = time(), last = time() }
        local list = Whispers.List()
        if #list > MAX_PEOPLE then
            table.sort(list, function(a, b) return (a.last or 0) > (b.last or 0) end)
            for i = MAX_PEOPLE + 1, #list do store[list[i].key] = nil end
        end
    end
    return store[key], key
end

function Whispers.Unread()
    local count = 0
    for _, c in pairs(Store() or {}) do count = count + (c.unread or 0) end
    return count
end

-- Tabs -------------------------------------------------------------------------------------------

local function PaintTab(tab)
    local selected = tab.key == current
    UI.Backdrop(tab, (selected or tab:IsMouseOver()) and "panelAlt" or "panel", selected and "accent" or "border")
    UI.SetTextColor(tab.label, selected and "accent" or "text")
end

local function TabLabel(c)
    local unread = (c.unread or 0) > 0 and (UI.ColorCode("accent") .. " (" .. c.unread .. ")|r") or ""
    return c.name .. unread
end

-- Right-click on a tab (or the title's Clear): clear or close one conversation.
local function ConversationMenu(owner, key)
    UI.ShowMenu(owner, {
        { "Clear this conversation", function() Whispers.ClearConversation(key) end, disabled = key == nil },
        { "Close this conversation", function() Whispers.CloseConversation(key) end, disabled = key == nil },
        "-",
        { "Clear all whispers", function() Whispers.ClearAll() end },
    })
end

local function Tab(i)
    local tab = window.tabs[i]
    if tab then return tab end
    tab = CreateFrame("Button", nil, window.tabBar, UI.BACKDROP_TEMPLATE)
    tab:SetHeight(22)
    tab:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    tab.label = UI.Text(tab, "", 11, "text", "CENTER")
    tab.label:SetPoint("LEFT", 8, 0)
    tab.label:SetPoint("RIGHT", -8, 0)
    tab.label:SetWordWrap(false)
    tab:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            ConversationMenu(self, self.key)
        else
            Whispers.Select(self.key)
            window.box:SetFocus()
        end
    end)
    tab:SetScript("OnEnter", function(self)
        PaintTab(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(self.fullName)
        GameTooltip:AddLine("Right-click to clear or close.", 0.9, 0.9, 0.9)
        GameTooltip:Show()
    end)
    tab:SetScript("OnLeave", function(self)
        PaintTab(self)
        GameTooltip:Hide()
    end)
    window.tabs[i] = tab
    return tab
end

local function TextWidth(fontString)
    return fontString.GetUnboundedStringWidth and fontString:GetUnboundedStringWidth() or fontString:GetStringWidth()
end

-- Tabs left to right as far as they fit; the rest are under "More" at the right.
function Whispers.UpdateTabs()
    if not window then return end
    for _, tab in ipairs(window.tabs) do tab:Hide() end
    local list = Whispers.List()
    local room = window.tabBar:GetWidth()
    local widths, total = {}, 0
    for i, c in ipairs(list) do
        local tab = Tab(i)
        tab.key, tab.fullName = c.key, c.name
        tab.label:SetText(TabLabel(c))
        widths[i] = math.min(TAB_MAX_WIDTH, TextWidth(tab.label) + 18)
        total = total + widths[i] + 4
    end
    if total > room then room = room - MORE_WIDTH end
    local x, hidden = 0, {}
    for i, c in ipairs(list) do
        local tab = window.tabs[i]
        if #hidden == 0 and x + widths[i] <= room then
            tab:ClearAllPoints()
            tab:SetPoint("LEFT", x, 0)
            tab:SetWidth(widths[i])
            PaintTab(tab)
            tab:Show()
            x = x + widths[i] + 4
        else
            hidden[#hidden + 1] = c
        end
    end
    local more = window.more
    more.hidden = hidden
    if #hidden > 0 then
        local unread = 0
        for _, c in ipairs(hidden) do unread = unread + (c.unread or 0) end
        more.label:SetText("More (" .. #hidden .. ")")
        more.style = unread > 0 and "primary" or nil
        more:Refresh()
        more:Show()
    else
        more:Hide()
    end
end

-- Showing a conversation --------------------------------------------------------------------------------

local function ShowConversation()
    if not window then return end
    local store = Store() or {}
    local c = current and store[current]
    if not c then current = nil end
    Chat.ShowMessages(view, c and c.msgs or {})
    window.empty:SetShown(c == nil)
    if c then c.unread = 0 end
    window.to:SetText(c and ("To " .. c.name .. ":") or "To:")
    Whispers.UpdateTabs()
    Chat.UpdateUnread()
end

function Whispers.Select(key)
    current = key
    ShowConversation()
end

-- The conversation to show when the window opens: one with something new, else the one shown before,
-- else the last one used.
local function Pick()
    local store = Store() or {}
    local best
    for key, c in pairs(store) do
        if (c.unread or 0) > 0 and (not best or (c.last or 0) > (store[best].last or 0)) then best = key end
    end
    if best then return best end
    if current and store[current] then return current end
    for key, c in pairs(store) do
        if not best or (c.last or 0) > (store[best].last or 0) then best = key end
    end
    return best
end

-- Sending -------------------------------------------------------------------------------------------

function Whispers.Send(to, text)
    text = RPF.Accents.Apply(text or "", "WHISPER")
    for _, part in ipairs(Chat.SplitPost(text)) do
        SendChatMessage(part, "WHISPER", nil, to)
    end
end

local function NoOneYet() RPF.Print("no one has whispered you yet.") end

local function SendFromBox(box)
    local text = box:GetText() or ""
    local command, target, rest = Chat.ParseCommand(text, true)
    if command == "WHISPER" or command == "REPLY" then
        local to = command == "REPLY" and Chat.ReplyTarget() or target
        if not to then return NoOneYet() end
        Whispers.Open(to, "")
        if strtrim(rest or "") ~= "" then Whispers.Send(to, rest) end
        return
    end
    if strtrim(text) == "" then return end
    local c = current and (Store() or {})[current]
    if not c then
        RPF.Print("type /w and a name to choose who to whisper.")
        return
    end
    Whispers.Send(c.target or c.name, text)
    box:SetText("")
end

-- The window -----------------------------------------------------------------------------------------

local function SavePosition()
    local point, _, relativePoint, x, y = window:GetPoint(1)
    RPF.db.whisperWindow = { point = point, relativePoint = relativePoint, x = x, y = y, w = window:GetWidth(), h = window:GetHeight() }
end

local function Build()
    window = CreateFrame("Frame", "RPForgeWhisperWindow", UIParent, UI.BACKDROP_TEMPLATE)
    local saved = RPF.db.whisperWindow or {}
    window:SetSize(saved.w or 400, saved.h or 340)
    if saved.point then
        window:SetPoint(saved.point, UIParent, saved.relativePoint or saved.point, saved.x or 0, saved.y or 0)
    else
        window:SetPoint("BOTTOMLEFT", 520, 260)
    end
    window:SetFrameStrata("MEDIUM")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:SetResizable(true)
    if window.SetResizeBounds then window:SetResizeBounds(300, 240, 1000, 900) elseif window.SetMinResize then window:SetMinResize(300, 240) end
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
    local name = UI.Text(title, "Whispers", 12, "accent")
    name:SetPoint("LEFT", 10, 0)
    local close = CreateFrame("Button", nil, title)
    close:SetSize(24, 24)
    close:SetPoint("RIGHT", 0, 0)
    close.label = UI.Text(close, "X", 13, "muted", "CENTER")
    close.label:SetPoint("CENTER")
    close:SetScript("OnEnter", function(self) UI.SetTextColor(self.label, "bad") end)
    close:SetScript("OnLeave", function(self) UI.SetTextColor(self.label, "muted") end)
    close:SetScript("OnClick", function() Whispers.Hide() end)
    local clear = CreateFrame("Button", nil, title)
    clear:SetHeight(24)
    clear:SetPoint("RIGHT", close, "LEFT", -6, 0)
    clear.label = UI.Text(clear, "Clear", 11, "muted", "RIGHT")
    clear.label:SetPoint("RIGHT", 0, 0)
    clear:SetWidth(clear.label:GetStringWidth() + 4)
    clear:SetScript("OnEnter", function(self) UI.SetTextColor(self.label, "accent") end)
    clear:SetScript("OnLeave", function(self) UI.SetTextColor(self.label, "muted") end)
    clear:SetScript("OnClick", function(self) ConversationMenu(self, current) end)
    UI.Divider(window, -25, 1)

    window.tabBar = CreateFrame("Frame", nil, window)
    window.tabBar:SetPoint("TOPLEFT", 10, -31)
    window.tabBar:SetPoint("TOPRIGHT", -10, -31)
    window.tabBar:SetHeight(22)
    window.tabs = {}
    window.more = UI.Button(window.tabBar, "More", MORE_WIDTH - 4, 22)
    window.more:SetPoint("RIGHT", 0, 0)
    window.more:SetScript("OnClick", function(self)
        local items = {}
        for _, c in ipairs(self.hidden or {}) do
            local key = c.key
            items[#items + 1] = { TabLabel(c), function() Whispers.Select(key) end, checked = key == current }
        end
        UI.ShowMenu(self, items)
    end)
    window.more:Hide()

    -- The typing box at the bottom, in the whisper colour: "To Kiri Stormcrest: ..."
    local input = UI.Panel(window, "panelAlt", "border")
    input:SetPoint("BOTTOMLEFT", 8, 18)
    input:SetPoint("BOTTOMRIGHT", -8, 18)
    input:SetHeight(28)
    local r, g, b = Chat.TypeColor("WHISPER")
    window.to = UI.Text(input, "To:", 12, "text")
    window.to:SetPoint("LEFT", 8, 0)
    window.to:SetTextColor(r, g, b, 1)
    local box = CreateFrame("EditBox", nil, input)
    box:SetAutoFocus(false)
    box:SetFont(UI.FONT, 12, "")
    box:SetTextColor(r, g, b, 1)
    box:SetPoint("LEFT", window.to, "RIGHT", 5, 0)
    box:SetPoint("RIGHT", -8, 0)
    box:SetHeight(20)
    box:SetMaxLetters(4000)
    window.box = box
    local placeholder = UI.Text(input, "Whisper. /w Name for someone else, /r to answer.", 11, "muted")
    placeholder:SetPoint("LEFT", box, "LEFT", 1, 0)
    placeholder:SetPoint("RIGHT", input, "RIGHT", -8, 0)
    placeholder:SetJustifyH("LEFT")
    placeholder:SetWordWrap(false)
    input:EnableMouse(true)
    input:SetScript("OnMouseDown", function() box:SetFocus() end)
    local function Border()
        input:SetBackdropBorderColor(r, g, b, box:HasFocus() and 1 or 0.45)
    end
    Border()

    local suggest = Chat.AttachSuggestions(box, input, function(person) Whispers.Open(person, "") end)
    box:SetScript("OnEditFocusGained", Border)
    box:SetScript("OnEditFocusLost", function()
        Border()
        suggest.FocusLost()
    end)
    box:SetScript("OnEscapePressed", function(self)
        if suggest:IsShown() then
            suggest:Hide()
            return
        end
        self:ClearFocus()
    end)
    box:SetScript("OnEnterPressed", function(self)
        if suggest:IsShown() then
            suggest.Take()
            return
        end
        SendFromBox(self)
    end)
    box:SetScript("OnTextChanged", function(self, userInput)
        local text = self:GetText() or ""
        if userInput then
            -- "/w Name " or "/r " switches to that person's tab.
            local command, target, rest = Chat.ParseCommand(text, false)
            if command == "WHISPER" or command == "REPLY" then
                local to = command == "REPLY" and Chat.ReplyTarget() or target
                if to then
                    Whispers.Open(to, rest)
                else
                    NoOneYet()
                    self:SetText(rest)
                end
                return
            end
            -- Your accent shows as you type, as in the RP chat.
            local changed, cursor = RPF.Accents.ApplyTyping(text, self:GetCursorPosition(), "WHISPER")
            if changed then
                self:SetText(changed)
                self:SetCursorPosition(cursor)
                return
            end
        end
        placeholder:SetShown(text == "")
        suggest.Update()
    end)

    window.empty = UI.Text(window, "No whispers yet.\nType /w and a name below to start one.", 12, "muted", "CENTER")
    window.empty:SetPoint("CENTER", 0, 10)

    view = Chat.NewView(window, true)
    view.scroll:SetPoint("TOPLEFT", 10, -60)
    view.scroll:SetPoint("BOTTOMRIGHT", input, "TOPRIGHT", -18, 8)

    local grip = CreateFrame("Button", nil, window)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() window:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() window:StopMovingOrSizing(); SavePosition(); Chat.LayoutView(view, true) end)
    window:SetScript("OnSizeChanged", function()
        Chat.LayoutView(view, false)
        Whispers.UpdateTabs()
    end)
end

-- Opening and closing ------------------------------------------------------------------------------

function Whispers.Show()
    if not RPF.db.settings.chatWhispers then return end
    if window and window.themeKey ~= UI.themeKey then
        window:Hide()
        window = nil
    end
    if not window then Build() end
    window:Show()
    RPF.db.settings.whispersOpen = true
    current = Pick()
    ShowConversation()
end

function Whispers.Hide()
    if window then window:Hide() end
    RPF.db.settings.whispersOpen = false
end

function Whispers.Toggle()
    if window and window:IsShown() then Whispers.Hide() else Whispers.Show() end
end

-- Open on this person (a new tab if needed), with text in the box, ready to type.
function Whispers.Open(name, text)
    if not RPF.db.settings.chatWhispers then return end
    local _, key = Conversation(name, true)
    if not key then return end
    Whispers.Show()
    if not window then return end
    Whispers.Select(key)
    window.box:SetText(text or "")
    window.box:SetFocus()
    window.box:SetCursorPosition(#(text or ""))
end

-- Messages ----------------------------------------------------------------------------------------

-- A whisper you got or sent (kind WHISPER or WHISPER_INFORM); other is the other person.
function Whispers.Add(msg, other)
    local c, key = Conversation(other, true)
    if not c then return end
    c.target = other
    local previous = c.msgs[#c.msgs]
    c.msgs[#c.msgs + 1] = msg
    while #c.msgs > MAX_PER_PERSON do table.remove(c.msgs, 1) end
    c.last = msg.at
    local shown = window ~= nil and window:IsShown()
    if msg.kind == "WHISPER_INFORM" then
        c.unread = 0 -- you answered, so you've read it
    elseif not (shown and current == key) then
        c.unread = (c.unread or 0) + 1
    end
    if shown then
        if current == key then
            window.empty:Hide()
            Chat.AddMessage(view, msg, previous)
        elseif current == nil then
            Whispers.Select(key)
        end
        Whispers.UpdateTabs()
    end
    Chat.UpdateUnread()
end

function Whispers.ClearConversation(key)
    local c = key and (Store() or {})[key]
    if not c then return end
    wipe(c.msgs)
    c.unread = 0
    if window and window:IsShown() then ShowConversation() end
    Chat.UpdateUnread()
end

function Whispers.CloseConversation(key)
    local store = Store()
    if not store or not key or not store[key] then return end
    store[key] = nil
    if current == key then current = Pick() end
    if window and window:IsShown() then ShowConversation() end
    Chat.UpdateUnread()
end

function Whispers.ClearAll()
    local store = Store()
    if not store then return end
    wipe(store)
    current = nil
    if window and window:IsShown() then ShowConversation() end
    Chat.UpdateUnread()
end

-- Names arrived or the layout changed.
function Whispers.Refresh()
    if not window or not window:IsShown() then return end
    Chat.RefreshView(view)
    Whispers.UpdateTabs()
end

RPF.Listen("DATA_READY", function()
    RPF.char.whispers = RPF.char.whispers or {}
    C_Timer.After(1.5, function()
        if RPF.db.settings.whispersOpen and RPF.db.settings.chatWhispers then Whispers.Show() end
        Chat.UpdateUnread()
    end)
end)

RPF.Listen("THEME_CHANGED", function()
    if not window then return end
    local wasShown = window:IsShown()
    window:Hide()
    window = nil
    if wasShown then Whispers.Show() end
end)

RPF.AddCommand("whispers", "Open or close the Whispers window", function() Whispers.Toggle() end)
