-- RP Forge: the Profile page. Your name and a profile switcher at the top; the details in three tabs.
local _, RPF = ...
local UI = RPF.UI
local Profiles = RPF.Profiles

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
    { "firstName", "FIRST NAME  (empty = your character's name)" }, { "lastName", "LAST NAME" },
    { "title", "TITLE  (before the name, e.g. Lady)" }, { "fullTitle", "FULL TITLE  (under your name, e.g. Captain of the Guard)" },
    { "nickname", "NICKNAME" }, { "pronouns", "PRONOUNS" },
}
local IDENTITY_RIGHT = {
    { "race", "RACE" }, { "class", "CLASS" }, { "age", "AGE" }, { "height", "HEIGHT" },
    { "eyes", "EYES" }, { "birthplace", "BIRTHPLACE" }, { "home", "HOME" }, { "house", "HOUSE" },
}

local function RefreshHeader()
    local profile = Profiles.GetActive()
    local name = Profiles.FullName(profile)
    page.fullName:SetText(name)
    local fullTitle = Profiles.GetField("fullTitle", profile)
    page.fullTitle:SetText((fullTitle and fullTitle ~= "") and ("< " .. fullTitle .. " >") or "")
    page.switcher.label:SetText("Profile: " .. (profile and profile.name or "?"))
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

-- The menu behind the "Profile: ..." button: switch profiles, or make, copy, rename and delete them.
local function ShowProfileMenu(owner)
    local active = Profiles.GetActive()
    local list = Profiles.List()
    local items = {}
    for _, profile in ipairs(list) do
        local id = profile.id
        items[#items + 1] = { profile.name, function() Profiles.SetActive(id) end, checked = id == active.id }
    end
    items[#items + 1] = "-"
    items[#items + 1] = { "New profile...", function()
        AskName("Name the new profile:", "", function(name) Profiles.SetActive(Profiles.Create(name).id) end)
    end }
    items[#items + 1] = { "Copy this profile...", function()
        AskName("Name the copy:", active.name .. " copy", function(name)
            Profiles.SetActive(Profiles.Create(name, active.id).id)
        end)
    end }
    items[#items + 1] = { "Rename this profile...", function()
        AskName("Rename the profile:", active.name, function(name) Profiles.Rename(active.id, name) end)
    end }
    items[#items + 1] = { "Delete this profile...", function()
        StaticPopup_Show("RPFORGE_PROFILE_DELETE", active.name, nil, { callback = function() Profiles.Delete(active.id) end })
    end, disabled = #list <= 1 }
    UI.ShowMenu(owner, items)
end

local function BuildIdentity(frame, width)
    local colWidth = math.floor((width - 24) / 2)
    for column, fields in ipairs({ IDENTITY_LEFT, IDENTITY_RIGHT }) do
        for i, spec in ipairs(fields) do
            local field = UI.Field(frame, spec[2], colWidth, Profiles.FIELDS[spec[1]], Setter(spec[1]))
            field:SetPoint("TOPLEFT", (column - 1) * (colWidth + 24), -(i - 1) * 50)
            page.controls[spec[1]] = field
        end
    end
end

local function BuildStatus(frame)
    local label = UI.Text(frame, "STATUS", 10, "muted")
    label:SetPoint("TOPLEFT", 0, 0)
    page.statusRow = UI.Segmented(frame, Profiles.STATUS, 150, function(value)
        Profiles.SetField("status", value)
    end)
    page.statusRow:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)

    local currently = UI.TextArea(frame, "CURRENTLY  (what your character is doing right now)", 72, Profiles.FIELDS.currently, Setter("currently"))
    currently:SetPoint("TOPLEFT", 0, -62)
    currently:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    page.controls.currently = currently

    local ooc = UI.TextArea(frame, "OOC NOTE  (anything other players should know, out of character)", 72, Profiles.FIELDS.oocNote, Setter("oocNote"))
    ooc:SetPoint("TOPLEFT", currently, "BOTTOMLEFT", 0, -16)
    ooc:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    page.controls.oocNote = ooc

    local motto = UI.Field(frame, "MOTTO", 300, Profiles.FIELDS.motto, Setter("motto"))
    motto:SetPoint("TOPLEFT", ooc, "BOTTOMLEFT", 0, -16)
    motto:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    page.controls.motto = motto
end

local function BuildAbout(frame)
    local appearance = UI.TextArea(frame, "APPEARANCE  (what others see when they look at your character)", 180, Profiles.FIELDS.appearance, Setter("appearance"))
    appearance:SetPoint("TOPLEFT", 0, 0)
    appearance:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    page.controls.appearance = appearance

    local history = UI.TextArea(frame, "HISTORY  (your character's story so far)", 180, Profiles.FIELDS.history, Setter("history"))
    history:SetPoint("TOPLEFT", appearance, "BOTTOMLEFT", 0, -16)
    history:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    page.controls.history = history
end

local MARGIN = 28

UI.RegisterPage({
    key = "profile",
    title = "Profile",
    section = "Character",
    sectionOrder = 2,
    order = 10,
    build = function(frame)
        page = frame
        page.controls = {}

        -- Header: your name as others see it, and the profile switcher.
        page.switcher = UI.Button(frame, "", 210, 26)
        page.switcher:SetPoint("TOPRIGHT", -MARGIN, -24)
        page.switcher.label:ClearAllPoints()
        page.switcher.label:SetPoint("LEFT", 10, 0)
        page.switcher.label:SetPoint("RIGHT", -24, 0)
        page.switcher.label:SetJustifyH("LEFT")
        page.switcher.label:SetWordWrap(false)
        local arrow = UI.Text(page.switcher, "v", 11, "muted", "CENTER")
        arrow:SetPoint("RIGHT", -10, 0)
        page.switcher:SetScript("OnClick", function(self) ShowProfileMenu(self) end)
        UI.Tooltip(page.switcher, "Your profiles", "Switch to another profile, or make, copy, rename or delete one.")

        page.fullName = UI.Text(frame, "", 20, "accent")
        page.fullName:SetPoint("TOPLEFT", MARGIN, -24)
        page.fullName:SetPoint("RIGHT", page.switcher, "LEFT", -16, 0)
        page.fullName:SetWordWrap(false)
        page.fullTitle = UI.Text(frame, "", 12, "muted")
        page.fullTitle:SetPoint("TOPLEFT", page.fullName, "BOTTOMLEFT", 0, -5)
        page.fullTitle:SetPoint("RIGHT", page.switcher, "LEFT", -16, 0)
        page.fullTitle:SetWordWrap(false)

        page.tabButtons, page.tabs = {}, {}
        local tabX = MARGIN
        for _, spec in ipairs({ { "identity", "Identity" }, { "status", "Status" }, { "about", "About" } }) do
            local b = UI.Button(frame, spec[2], 120, 26)
            b.tabKey = spec[1]
            b:SetPoint("TOPLEFT", tabX, -80)
            b:SetScript("OnClick", function() ShowTab(spec[1]) end)
            page.tabButtons[#page.tabButtons + 1] = b
            tabX = tabX + 126

            local tab = CreateFrame("Frame", nil, frame)
            tab:SetPoint("TOPLEFT", MARGIN, -126)
            tab:SetPoint("BOTTOMRIGHT", -MARGIN, 20)
            page.tabs[spec[1]] = tab
        end
        UI.Divider(frame, -114, MARGIN)
        local width = (frame:GetWidth() > 0 and frame:GetWidth() or 788) - MARGIN * 2
        BuildIdentity(page.tabs.identity, width)
        BuildStatus(page.tabs.status)
        BuildAbout(page.tabs.about)
        ShowTab("identity")
    end,
    onShow = function()
        RefreshHeader()
        FillFields()
    end,
})

-- Keep the page up to date: the header always; the boxes only when another profile is chosen,
-- so typing is never interrupted.
RPF.Listen("PROFILE_CHANGED", function()
    if not page or not page:IsVisible() then return end
    RefreshHeader()
    if page.loadedProfile ~= RPF.char.activeProfile then FillFields() end
end)
-- (A new theme rebuilds the window; build() then replaces `page` with the new frame.)
