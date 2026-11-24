-- RP Forge: the Profile page. Your profiles on the left; the chosen one's details on the right.
local _, RPF = ...
local UI = RPF.UI
local Profiles = RPF.Profiles

local LIST_WIDTH = 190
local MAX_ROWS = 12

-- Popups ---------------------------------------------------------------------------------

local function PopupEditBox(popup)
    return popup.editBox or popup.EditBox or (popup.GetEditBox and popup:GetEditBox())
end

StaticPopupDialogs.RPFORGE_PROFILE_NAME = {
    text = "%s",
    button1 = OKAY or "OK",
    button2 = CANCEL or "Cancel",
    hasEditBox = true,
    maxLetters = 40,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnShow = function(self, data)
        local box = PopupEditBox(self)
        box:SetText(data and data.initial or "")
        box:HighlightText()
        box:SetFocus()
    end,
    OnAccept = function(self, data)
        data.callback(PopupEditBox(self):GetText())
    end,
    EditBoxOnEnterPressed = function(self, data)
        data.callback(self:GetText())
        self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
}

StaticPopupDialogs.RPFORGE_PROFILE_DELETE = {
    text = "Delete the profile \"%s\"? This can't be undone.",
    button1 = DELETE or "Delete",
    button2 = CANCEL or "Cancel",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = true,
    OnAccept = function(_, data) data.callback() end,
}

local function AskName(prompt, initial, callback)
    StaticPopup_Show("RPFORGE_PROFILE_NAME", prompt, nil, { initial = initial, callback = callback })
end

-- The page -------------------------------------------------------------------------------

local page -- the built page frame, so PROFILE_CHANGED can update it

local IDENTITY_LEFT = {
    { "firstName", "FIRST NAME" }, { "lastName", "LAST NAME" },
    { "title", "TITLE  (before the name, e.g. Lady)" }, { "epithet", "EPITHET  (after the name, e.g. the Wanderer)" },
    { "nickname", "NICKNAME" }, { "pronouns", "PRONOUNS" },
}
local IDENTITY_RIGHT = {
    { "race", "RACE" }, { "class", "CLASS" }, { "age", "AGE" }, { "height", "HEIGHT" },
    { "eyes", "EYES" }, { "birthplace", "BIRTHPLACE" }, { "home", "HOME" }, { "house", "HOUSE" },
}

local function RefreshList()
    local active = RPF.char.activeProfile
    local list = Profiles.List()
    for i, row in ipairs(page.rows) do
        local profile = list[i]
        if profile and i <= MAX_ROWS then
            row.profileID = profile.id
            row.label:SetText(profile.name)
            row.selected = profile.id == active
            row:Refresh()
            row:Show()
        else
            row:Hide()
        end
    end
    page.delete:SetEnabled(#list > 1)
end

local function RefreshHeader()
    local profile = Profiles.GetActive()
    local name = Profiles.FullName(profile)
    local epithet = Profiles.GetField("epithet", profile)
    page.fullName:SetText(name .. ((epithet and epithet ~= "") and (", " .. epithet) or ""))
    page.using:SetText("Profile: " .. (profile and profile.name or "?"))
end

-- Put the active profile's values into every box. Only when the profile changes, never while typing.
local function FillFields()
    local profile = Profiles.GetActive()
    page.loadedProfile = profile and profile.id
    for key, control in pairs(page.controls) do
        control:SetValue(Profiles.GetField(key, profile))
    end
    page.statusRow:SetValue(Profiles.GetField("status", profile) or "ooc")
end

local function ShowTab(key)
    for name, frame in pairs(page.tabs) do frame:SetShown(name == key) end
    for _, b in ipairs(page.tabButtons) do
        b.style = (b.tabKey == key) and "primary" or nil
        b:Refresh()
    end
    page.currentTab = key
end

local function Setter(key)
    return function(text)
        Profiles.SetField(key, text)
    end
end

local function BuildIdentity(frame, width)
    local colWidth = math.floor((width - 16) / 2)
    for column, fields in ipairs({ IDENTITY_LEFT, IDENTITY_RIGHT }) do
        for i, spec in ipairs(fields) do
            local field = UI.Field(frame, spec[2], colWidth, Profiles.FIELDS[spec[1]], Setter(spec[1]))
            field:SetPoint("TOPLEFT", (column - 1) * (colWidth + 16), -(i - 1) * 50)
            page.controls[spec[1]] = field
        end
    end
    local hint = UI.Text(frame, "Leave the name empty to use your character's name.", 10, "muted")
    hint:SetPoint("TOPLEFT", 0, -(#IDENTITY_LEFT * 50 + 4))
end

local function BuildStatus(frame)
    local label = UI.Text(frame, "STATUS", 10, "muted")
    label:SetPoint("TOPLEFT", 0, 0)
    page.statusRow = UI.Segmented(frame, Profiles.STATUS, 140, function(value)
        Profiles.SetField("status", value)
    end)
    page.statusRow:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)

    local currently = UI.TextArea(frame, "CURRENTLY  (what your character is doing right now)", 64, Profiles.FIELDS.currently, Setter("currently"))
    currently:SetPoint("TOPLEFT", 0, -62)
    currently:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    page.controls.currently = currently

    local ooc = UI.TextArea(frame, "OOC NOTE  (anything other players should know, out of character)", 64, Profiles.FIELDS.oocNote, Setter("oocNote"))
    ooc:SetPoint("TOPLEFT", currently, "BOTTOMLEFT", 0, -14)
    ooc:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    page.controls.oocNote = ooc

    local motto = UI.Field(frame, "MOTTO", 300, Profiles.FIELDS.motto, Setter("motto"))
    motto:SetPoint("TOPLEFT", ooc, "BOTTOMLEFT", 0, -14)
    motto:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    page.controls.motto = motto
end

local function BuildAbout(frame)
    local appearance = UI.TextArea(frame, "APPEARANCE  (what others see when they look at your character)", 170, Profiles.FIELDS.appearance, Setter("appearance"))
    appearance:SetPoint("TOPLEFT", 0, 0)
    appearance:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    page.controls.appearance = appearance

    local history = UI.TextArea(frame, "HISTORY  (your character's story so far)", 170, Profiles.FIELDS.history, Setter("history"))
    history:SetPoint("TOPLEFT", appearance, "BOTTOMLEFT", 0, -14)
    history:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    page.controls.history = history
end

local function ListRow(parent)
    local row = CreateFrame("Button", nil, parent, UI.BACKDROP_TEMPLATE)
    row:SetHeight(26)
    row.label = UI.Text(row, "", 12, "text")
    row.label:SetPoint("LEFT", 10, 0)
    row.label:SetPoint("RIGHT", -8, 0)
    row.label:SetWordWrap(false)
    function row:Refresh()
        local hover = self:IsMouseOver()
        UI.Backdrop(self, self.selected and "selected" or (hover and "panelAlt" or "panel"), self.selected and "accent" or (hover and "border" or "panel"))
        UI.SetTextColor(self.label, self.selected and "accent" or "text")
    end
    row:SetScript("OnEnter", function(self) self:Refresh() end)
    row:SetScript("OnLeave", function(self) self:Refresh() end)
    row:SetScript("OnClick", function(self) Profiles.SetActive(self.profileID) end)
    return row
end

UI.RegisterPage({
    key = "profile",
    title = "Profile",
    section = "Character",
    sectionOrder = 2,
    order = 10,
    build = function(frame)
        page = frame
        page.controls = {}

        -- Left: the list of profiles.
        local listLabel = UI.Text(frame, "YOUR PROFILES", 10, "muted")
        listLabel:SetPoint("TOPLEFT", 20, -24)
        page.rows = {}
        for i = 1, MAX_ROWS do
            local row = ListRow(frame)
            row:SetPoint("TOPLEFT", 20, -44 - (i - 1) * 28)
            row:SetWidth(LIST_WIDTH)
            page.rows[i] = row
        end

        local buttonWidth = math.floor((LIST_WIDTH - 6) / 2)
        local function ListButton(label, column, line, onClick)
            local b = UI.Button(frame, label, buttonWidth, 24)
            b:SetPoint("BOTTOMLEFT", 20 + (column - 1) * (buttonWidth + 6), 20 + (2 - line) * 30)
            b:SetScript("OnClick", onClick)
            return b
        end
        ListButton("New", 1, 1, function()
            AskName("Name the new profile:", "", function(name)
                Profiles.SetActive(Profiles.Create(name).id)
            end)
        end)
        ListButton("Copy", 2, 1, function()
            local active = Profiles.GetActive()
            AskName("Name the copy:", active.name .. " copy", function(name)
                Profiles.SetActive(Profiles.Create(name, active.id).id)
            end)
        end)
        ListButton("Rename", 1, 2, function()
            local active = Profiles.GetActive()
            AskName("Rename the profile:", active.name, function(name) Profiles.Rename(active.id, name) end)
        end)
        page.delete = ListButton("Delete", 2, 2, function()
            local active = Profiles.GetActive()
            StaticPopup_Show("RPFORGE_PROFILE_DELETE", active.name, nil, { callback = function() Profiles.Delete(active.id) end })
        end)
        UI.Tooltip(page.delete, "Delete", "Deletes the profile you're using. You always keep at least one.")

        local line = frame:CreateTexture(nil, "ARTWORK")
        line:SetTexture(UI.WHITE)
        local c = UI.Color("border")
        line:SetVertexColor(c[1], c[2], c[3], 1)
        line:SetWidth(1)
        line:SetPoint("TOPLEFT", LIST_WIDTH + 36, -20)
        line:SetPoint("BOTTOMLEFT", LIST_WIDTH + 36, 20)

        -- Right: the chosen profile.
        local left = LIST_WIDTH + 56
        page.fullName = UI.Text(frame, "", 20, "accent")
        page.fullName:SetPoint("TOPLEFT", left, -20)
        page.fullName:SetPoint("RIGHT", frame, "RIGHT", -24, 0)
        page.fullName:SetWordWrap(false)
        page.using = UI.Text(frame, "", 11, "muted")
        page.using:SetPoint("TOPLEFT", page.fullName, "BOTTOMLEFT", 0, -4)

        page.tabButtons, page.tabs = {}, {}
        local tabX = left
        for _, spec in ipairs({ { "identity", "Identity" }, { "status", "Status" }, { "about", "About" } }) do
            local b = UI.Button(frame, spec[2], 110, 26)
            b.tabKey = spec[1]
            b:SetPoint("TOPLEFT", tabX, -74)
            b:SetScript("OnClick", function() ShowTab(spec[1]) end)
            page.tabButtons[#page.tabButtons + 1] = b
            tabX = tabX + 116

            local tab = CreateFrame("Frame", nil, frame)
            tab:SetPoint("TOPLEFT", left, -116)
            tab:SetPoint("BOTTOMRIGHT", -24, 20)
            page.tabs[spec[1]] = tab
        end
        local width = (frame:GetWidth() > 0 and frame:GetWidth() or 788) - left - 24
        BuildIdentity(page.tabs.identity, width)
        BuildStatus(page.tabs.status)
        BuildAbout(page.tabs.about)
        ShowTab("identity")
    end,
    onShow = function()
        RefreshList()
        RefreshHeader()
        FillFields()
    end,
})

-- Keep the page up to date: the list and name always; the boxes only when another profile is chosen,
-- so typing is never interrupted.
RPF.Listen("PROFILE_CHANGED", function()
    if not page or not page:IsVisible() then return end
    RefreshList()
    RefreshHeader()
    if page.loadedProfile ~= RPF.char.activeProfile then FillFields() end
end)
-- (A new theme rebuilds the window; build() then replaces `page` with the new frame.)
