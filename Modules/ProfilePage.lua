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
local pendingTab -- the tab to show when the editor opens (from Home's "Currently")

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
    if page.FillPersona then page.FillPersona() end
    if page.FillVoice then page.FillVoice() end
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
    if not Profiles.GetActive() then return end
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

UI.ShowProfileMenu = ShowProfileMenu

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

-- Persona and Traits tabs ----------------------------------------------------------------

local TRAIT_PAIRS = {
    { "Brave", "Cautious" }, { "Kind", "Cruel" }, { "Honest", "Deceitful" }, { "Calm", "Hot-headed" },
    { "Humble", "Proud" }, { "Generous", "Greedy" }, { "Loyal", "Fickle" }, { "Serious", "Playful" },
    { "Lawful", "Chaotic" }, { "Forgiving", "Vindictive" }, { "Optimistic", "Pessimistic" },
    { "Reserved", "Outgoing" }, { "Pious", "Irreverent" }, { "Trusting", "Suspicious" },
}

local function HexToRGB(hex)
    if type(hex) ~= "string" or #hex ~= 6 then return nil end
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

local function PickColor(hex, onChange)
    local r, g, b = HexToRGB(hex)
    r, g, b = r or 1, g or 0.86, b or 0.56
    local function Apply()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        onChange(string.format("%02x%02x%02x", nr * 255, ng * 255, nb * 255))
    end
    local function Cancel() onChange(hex) end
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({ r = r, g = g, b = b, hasOpacity = false, swatchFunc = Apply, cancelFunc = Cancel })
    else
        ColorPickerFrame.func, ColorPickerFrame.cancelFunc, ColorPickerFrame.hasOpacity = Apply, Cancel, false
        ColorPickerFrame.previousValues = { r, g, b }
        ColorPickerFrame:SetColorRGB(r, g, b)
        ShowUIPanel(ColorPickerFrame)
    end
end

local function SetImpression(slot, key, value)
    local persona = Profiles.GetPersona()
    local impression = persona.impressions[slot] or {}
    impression[key] = value
    if (impression.title or "") == "" and (impression.text or "") == "" and impression.icon == nil then
        impression = nil
    end
    persona.impressions[slot] = impression
    Profiles.PersonaChanged()
end

local function FillPersona()
    local persona = Profiles.GetPersona()
    page.iconButton:SetIcon(persona.icon)
    local r, g, b = HexToRGB(persona.nameColor)
    page.colorSwatch.fill:SetVertexColor(r or 1, g or 0.86, b or 0.56, 1)
    page.colorState:SetText(persona.nameColor and ("#" .. persona.nameColor) or "Default")
    if page.tuneName then
        page.tuneName:SetText(persona.music and UI.MusicName(persona.music) or "None chosen")
        page.tunePlay:SetEnabled(persona.music ~= nil)
        page.tunePlay.label:SetText(UI.IsTunePlaying(persona.music) and "Stop" or "Play")
    end
    for slot, row in ipairs(page.impressionRows) do
        local impression = persona.impressions[slot] or {}
        row.icon:SetIcon(impression.icon)
        row.title:SetText(impression.title or "")
        row.text:SetText(impression.text or "")
        row.title:SetCursorPosition(0)
        row.text:SetCursorPosition(0)
    end
end

local function RenderTraits()
    local traits = Profiles.GetPersona().traits
    for i, row in ipairs(page.traitRows) do
        local trait = traits[i]
        row:SetShown(trait ~= nil)
        if trait then
            if not row.left:HasFocus() then row.left:SetText(trait.left or "") end
            if not row.right:HasFocus() then row.right:SetText(trait.right or "") end
            row.dots:SetValue(trait.value or Profiles.TRAIT_MAX / 2)
        end
    end
    page.noTraits:SetShown(#traits == 0)
    page.addTrait:SetEnabled(#traits < Profiles.MAX_TRAITS)
    page.addPair:SetEnabled(#traits < Profiles.MAX_TRAITS)
end

local function AddTrait(left, right)
    local traits = Profiles.GetPersona().traits
    if #traits >= Profiles.MAX_TRAITS then return end
    traits[#traits + 1] = { left = left or "", right = right or "", value = Profiles.TRAIT_MAX / 2 }
    Profiles.PersonaChanged()
    RenderTraits()
end

local function BuildPersona(frame, width)
    page.FillPersona = function() FillPersona(); RenderTraits() end
    local look = UI.Text(frame, "LOOK", 10, "muted")
    look:SetPoint("TOPLEFT", 0, 0)

    page.iconButton = UI.IconButton(frame, 44, function(self)
        UI.PickIcon(Profiles.GetPersona().icon, function(icon)
            Profiles.GetPersona().icon = icon
            Profiles.PersonaChanged()
            self:SetIcon(icon)
        end)
    end)
    page.iconButton:SetPoint("TOPLEFT", look, "BOTTOMLEFT", 0, -8)
    local iconLabel = UI.Text(frame, "Profile icon", 12, "text")
    iconLabel:SetPoint("TOPLEFT", page.iconButton, "TOPRIGHT", 12, -6)
    local iconHint = UI.Text(frame, "Click to choose. Shown with your name in roleplay addons.", 10, "muted")
    iconHint:SetPoint("TOPLEFT", iconLabel, "BOTTOMLEFT", 0, -4)

    page.colorSwatch = CreateFrame("Button", nil, frame, UI.BACKDROP_TEMPLATE)
    page.colorSwatch:SetSize(44, 44)
    page.colorSwatch:SetPoint("TOPLEFT", look, "BOTTOMLEFT", math.floor(width / 2), -8)
    UI.Backdrop(page.colorSwatch, "panelAlt", "border")
    page.colorSwatch.fill = page.colorSwatch:CreateTexture(nil, "ARTWORK")
    page.colorSwatch.fill:SetTexture(UI.WHITE)
    page.colorSwatch.fill:SetPoint("TOPLEFT", 4, -4)
    page.colorSwatch.fill:SetPoint("BOTTOMRIGHT", -4, 4)
    page.colorSwatch:SetScript("OnClick", function()
        PickColor(Profiles.GetPersona().nameColor, function(hex)
            Profiles.GetPersona().nameColor = hex
            Profiles.PersonaChanged()
            FillPersona()
        end)
    end)
    local colorLabel = UI.Text(frame, "Name colour", 12, "text")
    colorLabel:SetPoint("TOPLEFT", page.colorSwatch, "TOPRIGHT", 12, -6)
    page.colorState = UI.Text(frame, "", 10, "muted")
    page.colorState:SetPoint("TOPLEFT", colorLabel, "BOTTOMLEFT", 0, -4)
    local reset = UI.Button(frame, "Default", 80, 22)
    reset:SetPoint("LEFT", colorLabel, "RIGHT", 14, -8)
    reset:SetScript("OnClick", function()
        Profiles.GetPersona().nameColor = nil
        Profiles.PersonaChanged()
        FillPersona()
    end)

    -- Class colour presets: your own class first, then every class this client knows.
    local classes = {}
    local _, ownClass = UnitClass("player")
    if RAID_CLASS_COLORS then
        for token in pairs(RAID_CLASS_COLORS) do
            if token ~= ownClass then classes[#classes + 1] = token end
        end
        table.sort(classes)
        if ownClass and RAID_CLASS_COLORS[ownClass] then table.insert(classes, 1, ownClass) end
    end
    local presetX = 0
    for _, token in ipairs(classes) do
        local c = RAID_CLASS_COLORS[token]
        local hex = string.format("%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
        local swatch = CreateFrame("Button", nil, frame, UI.BACKDROP_TEMPLATE)
        swatch:SetSize(16, 16)
        swatch:SetPoint("TOPLEFT", page.colorState, "BOTTOMLEFT", presetX, -6)
        UI.Backdrop(swatch, "panelAlt", "border")
        local fill = swatch:CreateTexture(nil, "ARTWORK")
        fill:SetTexture(UI.WHITE)
        fill:SetPoint("TOPLEFT", 2, -2)
        fill:SetPoint("BOTTOMRIGHT", -2, 2)
        fill:SetVertexColor(c.r, c.g, c.b, 1)
        local className = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token
        swatch:SetScript("OnEnter", function(self)
            UI.Backdrop(self, "panelAlt", "accent")
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(className .. (token == ownClass and "  (your class)" or ""), c.r, c.g, c.b)
            GameTooltip:Show()
        end)
        swatch:SetScript("OnLeave", function(self)
            UI.Backdrop(self, "panelAlt", "border")
            GameTooltip:Hide()
        end)
        swatch:SetScript("OnClick", function()
            Profiles.GetPersona().nameColor = hex
            Profiles.PersonaChanged()
            FillPersona()
        end)
        presetX = presetX + (token == ownClass and 26 or 20) -- a little gap after your own class
    end

    local impressionsLabel = UI.Text(frame, "FIRST IMPRESSIONS  (what people notice at first sight, up to 5)", 10, "muted")
    impressionsLabel:SetPoint("TOPLEFT", 0, -92)
    local titleHead = UI.Text(frame, "TITLE", 9, "muted")
    titleHead:SetPoint("TOPLEFT", 48, -110)
    local textHead = UI.Text(frame, "WHAT THEY NOTICE", 9, "muted")
    textHead:SetPoint("TOPLEFT", 264, -110)

    page.impressionRows = {}
    for slot = 1, Profiles.MAX_IMPRESSIONS do
        local y = -124 - (slot - 1) * 44
        local row = {}
        row.icon = UI.IconButton(frame, 36, function(self)
            UI.PickIcon(self.value, function(icon)
                self:SetIcon(icon)
                SetImpression(slot, "icon", icon)
            end)
        end)
        row.icon:SetPoint("TOPLEFT", 0, y)
        row.title = UI.EditBox(frame, 208, 30)
        row.title:SetMaxLetters(60)
        row.title:SetPoint("TOPLEFT", 48, y - 3)
        row.title:SetScript("OnTextChanged", function(self, userInput)
            if userInput then SetImpression(slot, "title", self:GetText()) end
        end)
        row.text = UI.EditBox(frame, 200, 30)
        row.text:SetMaxLetters(300)
        row.text:SetPoint("TOPLEFT", 264, y - 3)
        row.text:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        row.text:SetScript("OnTextChanged", function(self, userInput)
            if userInput then SetImpression(slot, "text", self:GetText()) end
        end)
        page.impressionRows[slot] = row
    end
    local hint = UI.Text(frame, "For example: a scar across the cheek, the smell of pipe smoke, a holy symbol worn openly.", 10, "muted")
    hint:SetPoint("TOPLEFT", 0, -124 - Profiles.MAX_IMPRESSIONS * 44 - 2)

    local tuneLabel = UI.Text(frame, "THEME TUNE  (other players can play it from your profile)", 10, "muted")
    tuneLabel:SetPoint("TOPLEFT", 0, -124 - Profiles.MAX_IMPRESSIONS * 44 - 30)
    page.tuneName = UI.Text(frame, "", 12, "text")
    page.tuneName:SetPoint("TOPLEFT", tuneLabel, "BOTTOMLEFT", 0, -12)
    page.tuneName:SetWidth(320)
    page.tuneName:SetWordWrap(false)
    local choose = UI.Button(frame, "Choose...", 100, 26)
    choose:SetPoint("LEFT", page.tuneName, "RIGHT", 10, 0)
    choose:SetScript("OnClick", function()
        UI.PickMusic(Profiles.GetPersona().music, function(file)
            Profiles.GetPersona().music = file
            Profiles.PersonaChanged()
            FillPersona()
        end)
    end)
    page.tunePlay = UI.Button(frame, "Play", 70, 26)
    page.tunePlay:SetPoint("LEFT", choose, "RIGHT", 6, 0)
    page.tunePlay:SetScript("OnClick", function()
        local file = Profiles.GetPersona().music
        if UI.IsTunePlaying(file) then UI.StopTune() else UI.PlayTune(file) end
        FillPersona()
    end)
    local clear = UI.Button(frame, "Clear", 70, 26)
    clear:SetPoint("LEFT", page.tunePlay, "RIGHT", 6, 0)
    clear:SetScript("OnClick", function()
        if UI.IsTunePlaying(Profiles.GetPersona().music) then UI.StopTune() end
        Profiles.GetPersona().music = nil
        Profiles.PersonaChanged()
        FillPersona()
    end)
end

local function BuildTraits(frame, width)
    local label = UI.Text(frame, "TRAITS  (up to 10)  Click the dots towards the side that fits your character; click again to go back to balanced.", 10, "muted")
    label:SetPoint("TOPLEFT", 0, 0)

    page.traitRows = {}
    local nameWidth = 150
    for i = 1, Profiles.MAX_TRAITS do
        local row = CreateFrame("Frame", nil, frame)
        row:SetPoint("TOPLEFT", 0, -22 - (i - 1) * 36)
        row:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        row:SetHeight(30)
        row.left = UI.EditBox(row, nameWidth, 26)
        row.left:SetMaxLetters(30)
        row.left:SetPoint("LEFT", 0, 0)
        row.left:SetScript("OnTextChanged", function(self, userInput)
            local trait = Profiles.GetPersona().traits[i]
            if userInput and trait then trait.left = self:GetText(); Profiles.PersonaChanged() end
        end)
        row.remove = UI.Button(row, "x", 26, 26)
        row.remove:SetPoint("RIGHT", 0, 0)
        UI.Tooltip(row.remove, "Remove this trait")
        row.remove:SetScript("OnClick", function()
            table.remove(Profiles.GetPersona().traits, i)
            Profiles.PersonaChanged()
            RenderTraits()
        end)
        row.right = UI.EditBox(row, nameWidth, 26)
        row.right:SetMaxLetters(30)
        row.right:SetPoint("RIGHT", row.remove, "LEFT", -8, 0)
        row.right:SetJustifyH("RIGHT")
        row.right:SetScript("OnTextChanged", function(self, userInput)
            local trait = Profiles.GetPersona().traits[i]
            if userInput and trait then trait.right = self:GetText(); Profiles.PersonaChanged() end
        end)
        row.dots = UI.TraitDots(row, function(value)
            local trait = Profiles.GetPersona().traits[i]
            if trait then trait.value = value; Profiles.PersonaChanged() end
        end)
        -- In the middle between the two names.
        row.dots:SetPoint("CENTER", row, "CENTER", -17, 0)
        page.traitRows[i] = row
    end

    page.noTraits = UI.Text(frame, "No traits yet. Add your own pair, or pick a common one.", 11, "muted")
    page.noTraits:SetPoint("TOPLEFT", 0, -30)

    page.addTrait = UI.Button(frame, "+ Add trait", 130, 26, "primary")
    page.addTrait:SetPoint("BOTTOMLEFT", 0, 0)
    page.addTrait:SetScript("OnClick", function() AddTrait("", "") end)
    page.addPair = UI.Button(frame, "Add a common pair", 160, 26)
    page.addPair:SetPoint("LEFT", page.addTrait, "RIGHT", 8, 0)
    page.addPair:SetScript("OnClick", function(self)
        local items = {}
        for _, pair in ipairs(TRAIT_PAIRS) do
            local left, right = pair[1], pair[2]
            items[#items + 1] = { left .. "  /  " .. right, function() AddTrait(left, right) end }
        end
        UI.ShowMenu(self, items)
    end)
end

-- Voice tab: accent ---------------------------------------------------------------------------

local Accents = RPF.Accents
local EMOTE_SAMPLE = 'waves. "Hello there, friend! Are you going to the tavern?" *winks* ((afk soon))'

local function FillVoice()
    if not page.accentButton then return end
    local choice = Profiles.GetPersona().accent
    local accent = choice and Accents.BY_KEY[choice.key]
    page.accentButton.label:SetText(accent and accent.name or "No accent")
    page.strength:SetValue(accent and (choice.strength or 1) or 0)
    for _, b in ipairs(page.strength.buttons) do b:SetEnabled(accent ~= nil) end
    -- "Talking to" only matters for accents that call people lad or lass.
    page.talkingTo:SetShown(accent ~= nil and accent.ladLass ~= nil)
    page.talkingTo:SetValue(page.tryWho or "target")
    local who = page.tryWho ~= "target" and page.tryWho or nil
    -- A different accent, strength or "talking to" starts the try-it box again from the sample.
    local voice = accent and (accent.key .. (choice.strength or 1) .. (page.tryWho or "")) or "none"
    if page.tryVoice ~= voice then
        page.tryVoice = voice
        page.trySay:SetText(accent and Accents.Apply(Accents.SAMPLE, "SAY", nil, nil, who) or Accents.SAMPLE)
        page.trySay:SetCursorPosition(0)
    end
    local sample = page.trySay:GetText() or ""
    local say = accent and Accents.Apply(sample, "SAY", nil, nil, who) or sample
    local emote = accent and Accents.Apply(EMOTE_SAMPLE, "EMOTE", nil, nil, who) or EMOTE_SAMPLE
    page.saidText:SetText(UI.ColorCode("muted") .. "Say:|r  " .. say)
    page.emoteText:SetText(UI.ColorCode("muted") .. "Emote:|r  " .. UnitName("player") .. " " .. emote)
end

local function BuildVoice(frame, width)
    page.FillVoice = FillVoice
    local label = UI.Text(frame, "ACCENT", 10, "muted")
    label:SetPoint("TOPLEFT", 0, 0)
    page.accentButton = UI.Button(frame, "No accent", 200, 26)
    page.accentButton:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -8)
    page.accentButton:SetScript("OnClick", function(self) Accents.ShowMenu(self) end)

    local strengthLabel = UI.Text(frame, "STRENGTH", 10, "muted")
    strengthLabel:SetPoint("TOPLEFT", 230, 0)
    page.strength = UI.Segmented(frame, Accents.STRENGTHS, 90, function(value) Accents.SetStrength(value) end)
    page.strength:SetPoint("TOPLEFT", strengthLabel, "BOTTOMLEFT", 0, -8)

    local hint = UI.Text(frame, "Your accent changes what you post from the RP chat window: everything you say or yell, "
        .. "and the words in \"quotes\" when you emote. *Actions* and ((OOC)) stay as you wrote them. "
        .. "Light changes a few words, Strong changes many.", 11, "muted")
    hint:SetPoint("TOPLEFT", page.accentButton, "BOTTOMLEFT", 0, -16)
    hint:SetWidth(width)
    hint:SetJustifyH("LEFT")

    local tryLabel = UI.Text(frame, "TRY IT", 10, "muted")
    tryLabel:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -22)
    page.trySay = UI.EditBox(frame, width, 26)
    page.trySay:SetPoint("TOPLEFT", tryLabel, "BOTTOMLEFT", 0, -8)
    page.trySay:SetMaxLetters(255)
    page.trySay:SetText(Accents.SAMPLE)
    page.trySay:SetCursorPosition(0)
    -- Who you're talking to in Try it: your real target, or a man or woman ("friend" becomes lad or lass).
    page.tryWho = "lad"
    page.talkingTo = UI.Segmented(frame, { { "target", "Your target" }, { "lad", "A man" }, { "lass", "A woman" } }, 96,
        function(value)
            page.tryWho = value
            FillVoice()
        end)
    page.talkingTo:SetPoint("BOTTOMRIGHT", page.trySay, "TOPRIGHT", 0, 4)
    page.talkingTo.label = UI.Text(page.talkingTo, "TALKING TO", 10, "muted", "RIGHT")
    page.talkingTo.label:SetPoint("RIGHT", page.talkingTo, "LEFT", -10, 0)
    page.trySay:HookScript("OnTextChanged", function(self, userInput)
        -- The accent shows as you type, like in the RP chat window.
        if userInput then
            local who = page.tryWho ~= "target" and page.tryWho or nil
            local changed, cursor = Accents.ApplyTyping(self:GetText() or "", self:GetCursorPosition(), "SAY", nil, nil, who)
            if changed then
                self:SetText(changed)
                self:SetCursorPosition(cursor)
                return
            end
        end
        FillVoice()
    end)
    page.saidText = UI.Text(frame, "", 12, "text")
    page.saidText:SetPoint("TOPLEFT", page.trySay, "BOTTOMLEFT", 2, -14)
    page.saidText:SetWidth(width - 4)
    page.saidText:SetJustifyH("LEFT")
    page.emoteText = UI.Text(frame, "", 12, "text")
    page.emoteText:SetPoint("TOPLEFT", page.saidText, "BOTTOMLEFT", 0, -10)
    page.emoteText:SetWidth(width - 4)
    page.emoteText:SetJustifyH("LEFT")
    FillVoice()
end

local MARGIN = 28

UI.RegisterPage({
    key = "profile",
    title = "Profile",
    hidden = true, -- opened with "Edit profile" on Home

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

        local done = UI.Button(frame, "Done", 90, 26, "primary")
        done:SetPoint("RIGHT", page.switcher, "LEFT", -8, 0)
        done:SetScript("OnClick", function() UI.ShowPage("myprofile") end)
        UI.Tooltip(done, "Done", "Back to your profile. Your changes are already saved.")
        page.done = done

        page.fullName = UI.Text(frame, "", 20, "accent")
        page.fullName:SetPoint("TOPLEFT", MARGIN, -24)
        page.fullName:SetPoint("RIGHT", done, "LEFT", -16, 0)
        page.fullName:SetWordWrap(false)
        page.fullTitle = UI.Text(frame, "", 12, "muted")
        page.fullTitle:SetPoint("TOPLEFT", page.fullName, "BOTTOMLEFT", 0, -5)
        page.fullTitle:SetPoint("RIGHT", done, "LEFT", -16, 0)
        page.fullTitle:SetWordWrap(false)

        page.tabButtons, page.tabs = {}, {}
        local tabX = MARGIN
        for _, spec in ipairs({ { "identity", "Identity" }, { "status", "Status" }, { "about", "About" }, { "persona", "Persona" }, { "traits", "Traits" }, { "voice", "Voice" } }) do
            local b = UI.Button(frame, spec[2], 114, 26)
            b.tabKey = spec[1]
            b:SetPoint("TOPLEFT", tabX, -80)
            b:SetScript("OnClick", function() ShowTab(spec[1]) end)
            page.tabButtons[#page.tabButtons + 1] = b
            tabX = tabX + 120

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
        BuildPersona(page.tabs.persona, width)
        BuildTraits(page.tabs.traits, width)
        BuildVoice(page.tabs.voice, width)
        ShowTab("identity")
    end,
    onShow = function()
        RefreshHeader()
        FillFields()
        if pendingTab then
            ShowTab(pendingTab)
            pendingTab = nil
        end
    end,
})

-- Open the profile editor, optionally on a tab ("identity", "status" or "about").
function UI.OpenProfile(tab)
    pendingTab = tab
    if UI.IsWindowShown() and UI.CurrentPage() == "profile" and page then
        -- Already open: onShow won't run again, so switch the tab here.
        if tab then ShowTab(tab) end
        pendingTab = nil
        return
    end
    UI.OpenWindow("profile")
end

RPF.AddCommand("profile", "Edit your roleplay profile", function() UI.OpenProfile() end)

-- Keep the page up to date: the header always; the boxes only when another profile is chosen,
-- so typing is never interrupted.
RPF.Listen("PROFILE_CHANGED", function()
    if not page or not page:IsVisible() then return end
    RefreshHeader()
    if page.loadedProfile ~= RPF.char.activeProfile then FillFields() end
    if page.FillVoice then page.FillVoice() end
end)
-- (A new theme rebuilds the window; build() then replaces `page` with the new frame.)
