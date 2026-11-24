-- RP Forge: the Home and About pages.
local _, RPF = ...
local UI = RPF.UI

local GITHUB_URL = "https://github.com/NotThatSiri/RPForge"

-- Home: your character's banner, your status, and RP Forge's own card. More cards arrive with later updates.
local Profiles = RPF.Profiles
local Backgrounds = UI.Backgrounds
local home -- the built Home page

-- Text on the banner sits on a dark picture, so it uses light colours in every theme.
local BANNER_TEXT = { 0.96, 0.93, 0.86 }
local BANNER_MUTED = { 0.80, 0.76, 0.68 }
local BANNER_NAME = { 1.00, 0.86, 0.56 }

local function BannerText(parent, size, color)
    local fs = UI.Text(parent, "", size, "text")
    fs:SetTextColor(color[1], color[2], color[3], 1)
    fs:SetShadowColor(0, 0, 0, 0.95)
    fs:SetShadowOffset(1, -1)
    fs:SetWordWrap(false)
    return fs
end

local function Shade(texture)
    texture:SetTexture(UI.WHITE)
    local done = false
    if texture.SetGradient and CreateColor then
        done = pcall(texture.SetGradient, texture, "HORIZONTAL", CreateColor(0, 0, 0, 0.85), CreateColor(0, 0, 0, 0.15))
    end
    if not done and texture.SetGradientAlpha then
        done = pcall(texture.SetGradientAlpha, texture, "HORIZONTAL", 0, 0, 0, 0.85, 0, 0, 0, 0.15)
    end
    if not done then texture:SetVertexColor(0, 0, 0, 0.5) end
end

local function ChosenBackground(profile)
    return Profiles.GetLook("background", profile) or Backgrounds.PlayerRace()
end

local function RefreshHome()
    if not home then return end
    local profile = Profiles.GetActive()
    -- With "Keep Total RP 3" chosen, the banner shows the Total RP 3 profile instead.
    local usingTRP3 = RPF.TRP3Link and RPF.TRP3Link.UsingTRP3()
    local f = (usingTRP3 and RPF.TRP3Link.CurrentTRP3Fields()) or (profile and profile.fields) or {}

    home.name:SetText(Profiles.FullName({ fields = f }))
    local persona = (usingTRP3 and RPF.TRP3Link.CurrentTRP3Persona()) or Profiles.GetPersona(profile)
    local color = persona.nameColor
    if type(color) == "string" and #color == 6 then
        home.name:SetTextColor(tonumber(color:sub(1, 2), 16) / 255, tonumber(color:sub(3, 4), 16) / 255, tonumber(color:sub(5, 6), 16) / 255, 1)
    else
        home.name:SetTextColor(BANNER_NAME[1], BANNER_NAME[2], BANNER_NAME[3], 1)
    end
    local shown = 0
    for slot = 1, Profiles.MAX_IMPRESSIONS do
        local impression = persona.impressions[slot]
        if impression and ((impression.title or "") ~= "" or (impression.text or "") ~= "") then
            shown = shown + 1
            local b = home.impressions[shown]
            b:SetIcon(impression.icon)
            b.impression = impression
            b:Show()
        end
    end
    for i = shown + 1, #home.impressions do home.impressions[i]:Hide() end
    home.impressionsLabel:SetShown(shown > 0)
    for _, b in ipairs(home.statusRow.buttons) do b:SetEnabled(not usingTRP3) end
    home.fullTitle:SetText((f.fullTitle and f.fullTitle ~= "") and ("< " .. f.fullTitle .. " >") or "")
    local race = (f.race and f.race ~= "") and f.race or UnitRace("player")
    local class = (f.class and f.class ~= "") and f.class or UnitClass("player")
    home.raceClass:SetText(strtrim((race or "") .. " " .. (class or "")))
    local guild = GetGuildInfo("player")
    home.guild:SetText(guild and ("<" .. guild .. ">") or "")

    -- Portrait shape (Settings > Appearance): a round portrait in a theme-coloured ring, or a square
    -- head-and-shoulders view of your character (the game's 3D model, zoomed on the face).
    local square = RPF.db.settings.portraitShape == "square"
    home.circle:SetShown(not square)
    home.square:SetShown(square)
    if square then
        home.model:SetUnit("player")
        if home.model.SetPortraitZoom then home.model:SetPortraitZoom(1) end
    else
        SetPortraitTexture(home.portrait, "player")
    end
    if not Backgrounds.Apply(home.art, ChosenBackground(profile)) then
        Backgrounds.Apply(home.art, Backgrounds.PlayerRace())
    end
    Backgrounds.Fit(home.art, home.banner)

    home.statusRow:SetValue(f.status or "ooc")
    if f.currently and f.currently ~= "" then
        home.currently:SetText((f.currently:gsub("\n", " ")))
        UI.SetTextColor(home.currently, "text")
    else
        home.currently:SetText("Say what your character is doing right now...")
        UI.SetTextColor(home.currently, "muted")
    end
end

local function CountPlayers()
    local peers = RPF.GetModule("VersionCheck") and RPF.GetModule("VersionCheck").peers or {}
    local count = 0
    for _, info in pairs(peers) do
        if GetTime() - info.seen < 600 then count = count + 1 end
    end
    return count
end

UI.RegisterPage({
    key = "home",
    title = "Home",
    section = "RP Forge",
    sectionOrder = 1,
    order = 1,
    build = function(page)
        home = page

        -- Banner ---------------------------------------------------------------------------
        local banner = CreateFrame("Frame", nil, page, UI.BACKDROP_TEMPLATE)
        banner:SetPoint("TOPLEFT", 20, -20)
        banner:SetPoint("TOPRIGHT", -20, -20)
        banner:SetHeight(170)
        UI.Backdrop(banner, "panelAlt", "panelAlt")
        if banner.SetClipsChildren then banner:SetClipsChildren(true) end
        home.banner = banner

        home.art = Backgrounds.CreateArt(banner)
        banner:SetScript("OnSizeChanged", function() Backgrounds.Fit(home.art, banner) end)

        local overlay = CreateFrame("Frame", nil, banner, UI.BACKDROP_TEMPLATE)
        overlay:SetAllPoints()
        overlay:SetFrameLevel(home.art:GetFrameLevel() + 2)
        local shade = overlay:CreateTexture(nil, "BACKGROUND")
        shade:SetAllPoints()
        Shade(shade)
        overlay:SetBackdrop({ edgeFile = UI.WHITE, edgeSize = 1 })
        local b = UI.Color("border")
        overlay:SetBackdropBorderColor(b[1], b[2], b[3], 1)

        -- Portrait in a square frame with a thin border in the theme's accent colour.
        local portraitFrame = CreateFrame("Frame", nil, overlay)
        portraitFrame:SetSize(104, 104)
        portraitFrame:SetPoint("LEFT", 26, 0)
        local a = UI.Color("accent")

        -- Circle: the game's round portrait inside the game's own round border (the minimap button
        -- ring), the same frame the RP chat uses. The ring's art sits in the top-left of its texture,
        -- so it is sized and offset from the portrait by fixed ratios.
        home.circle = CreateFrame("Frame", nil, portraitFrame)
        home.circle:SetAllPoints()
        local size = 84
        home.portrait = home.circle:CreateTexture(nil, "ARTWORK")
        home.portrait:SetSize(size, size)
        home.portrait:SetPoint("CENTER", 0, 0)
        local ring = home.circle:CreateTexture(nil, "OVERLAY")
        ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        ring:SetSize(size * 2.622, size * 2.622)
        ring:SetPoint("TOPLEFT", home.portrait, "TOPLEFT", -size / 3, size * 0.233)

        -- Square: the character's 3D model zoomed on the face, in a thin accent border.
        home.square = CreateFrame("Frame", nil, portraitFrame, UI.BACKDROP_TEMPLATE)
        home.square:SetAllPoints()
        UI.Backdrop(home.square, "window", "accent")
        home.model = CreateFrame("PlayerModel", nil, home.square)
        home.model:SetPoint("TOPLEFT", 2, -2)
        home.model:SetPoint("BOTTOMRIGHT", -2, 2)

        home.name = BannerText(overlay, 24, BANNER_NAME)
        home.name:SetPoint("TOPLEFT", portraitFrame, "TOPRIGHT", 20, -14)
        home.fullTitle = BannerText(overlay, 13, BANNER_MUTED)
        home.fullTitle:SetPoint("TOPLEFT", home.name, "BOTTOMLEFT", 0, -6)
        home.raceClass = BannerText(overlay, 13, BANNER_TEXT)
        home.raceClass:SetPoint("TOPLEFT", home.fullTitle, "BOTTOMLEFT", 0, -10)
        home.guild = BannerText(overlay, 12, BANNER_MUTED)
        home.guild:SetPoint("TOPLEFT", home.raceClass, "BOTTOMLEFT", 0, -6)
        for _, fs in ipairs({ home.name, home.fullTitle, home.raceClass, home.guild }) do
            fs:SetPoint("RIGHT", overlay, "RIGHT", -170, 0)
        end

        local background = UI.Button(overlay, "Change background", 140, 26)
        background:SetPoint("TOPRIGHT", -14, -14)
        background:SetScript("OnClick", function() UI.ShowPage("backgrounds") end)
        UI.Tooltip(background, "Banner background", "Pick one of the game's pictures for this profile's banner.")

        -- Status ----------------------------------------------------------------------------
        local statusLabel = UI.Text(page, "STATUS", 10, "muted")
        statusLabel:SetPoint("TOPLEFT", banner, "BOTTOMLEFT", 0, -16)
        home.statusRow = UI.Segmented(page, Profiles.STATUS, 140, function(value)
            Profiles.SetField("status", value)
        end)
        home.statusRow:SetPoint("TOPLEFT", statusLabel, "BOTTOMLEFT", 0, -6)

        -- First impressions: icons on the right; hover one to read it.
        home.impressions = {}
        for i = Profiles.MAX_IMPRESSIONS, 1, -1 do
            local b = UI.IconButton(page, 34)
            if i == Profiles.MAX_IMPRESSIONS then
                b:SetPoint("TOPRIGHT", banner, "BOTTOMRIGHT", 0, -31)
            else
                b:SetPoint("RIGHT", home.impressions[i + 1], "LEFT", -6, 0)
            end
            b:SetScript("OnEnter", function(self)
                UI.Backdrop(self, "panelAlt", "accent")
                local impression = self.impression
                if not impression then return end
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                GameTooltip:AddLine(impression.title ~= "" and impression.title or "First impression", 1, 0.82, 0.45)
                if impression.text and impression.text ~= "" then GameTooltip:AddLine(impression.text, 0.9, 0.9, 0.9, true) end
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function(self)
                UI.Backdrop(self, "panelAlt", "border")
                GameTooltip:Hide()
            end)
            b:SetScript("OnClick", function()
                if RPF.TRP3Link and RPF.TRP3Link.UsingTRP3() then RPF.TRP3Link.OpenTRP3() else UI.OpenProfile("persona") end
            end)
            home.impressions[i] = b
        end
        home.impressionsLabel = UI.Text(page, "FIRST IMPRESSIONS", 10, "muted")
        home.impressionsLabel:SetPoint("TOPRIGHT", banner, "BOTTOMRIGHT", 0, -16)

        local currentlyLabel = UI.Text(page, "CURRENTLY", 10, "muted")
        currentlyLabel:SetPoint("TOPLEFT", home.statusRow, "BOTTOMLEFT", 0, -14)
        local currentlyButton = CreateFrame("Button", nil, page)
        currentlyButton:SetPoint("TOPLEFT", currentlyLabel, "BOTTOMLEFT", 0, -4)
        currentlyButton:SetPoint("RIGHT", page, "RIGHT", -20, 0)
        currentlyButton:SetHeight(20)
        home.currently = UI.Text(currentlyButton, "", 12, "text")
        home.currently:SetAllPoints()
        home.currently:SetWordWrap(false)
        currentlyButton:SetScript("OnClick", function()
            if RPF.TRP3Link and RPF.TRP3Link.UsingTRP3() then RPF.TRP3Link.OpenTRP3() else UI.OpenProfile("status") end
        end)
        UI.Tooltip(currentlyButton, "Currently", "Click to change it on your profile.")

        -- RP Forge card ------------------------------------------------------------------------
        local card = UI.Panel(page, "panel", "border")
        card:SetPoint("TOPLEFT", currentlyButton, "BOTTOMLEFT", 0, -20)
        card:SetPoint("RIGHT", page, "RIGHT", -20, 0)
        card:SetHeight(86)
        local versionLabel = UI.Text(card, "RP FORGE", 10, "muted")
        versionLabel:SetPoint("TOPLEFT", 16, -14)
        page.version = UI.Text(card, "", 15, "text")
        page.version:SetPoint("TOPLEFT", versionLabel, "BOTTOMLEFT", 0, -6)
        local playersLabel = UI.Text(card, "RP FORGE PLAYERS HEARD", 10, "muted")
        playersLabel:SetPoint("TOPLEFT", 260, -14)
        page.players = UI.Text(card, "", 15, "text")
        page.players:SetPoint("TOPLEFT", playersLabel, "BOTTOMLEFT", 0, -6)
        local who = UI.Button(card, "Who's around?", 130, 26)
        who:SetPoint("RIGHT", -14, 0)
        local chat = UI.Button(card, "RP chat", 100, 26, "primary")
        chat:SetPoint("RIGHT", who, "LEFT", -8, 0)
        chat:SetScript("OnClick", function() if RPF.RPChat then RPF.RPChat.Toggle() end end)
        UI.Tooltip(chat, "RP chat", "A window with only Say, Emote and Yell from people nearby. Also /rpf chat, or set a key in Key Bindings > AddOns.")
        UI.Tooltip(who, "Who's around?", "Asks your guild, your group and the RP Forge channel who uses RP Forge. The answers also appear in chat.")
        who:SetScript("OnClick", function()
            SlashCmdList.RPFORGE("who")
            C_Timer.After(6.5, function()
                if page:IsVisible() then page.players:SetText(tostring(CountPlayers())) end
            end)
        end)
    end,
    onShow = function(page)
        RefreshHome()
        local newer = RPF.db.newestSeen
        if newer and RPF.IsNewerVersion(newer.version, RPF.VERSION) then
            page.version:SetText(RPF.VERSION .. UI.ColorCode("warn") .. "   (" .. newer.version .. " is out)|r")
        else
            page.version:SetText(RPF.VERSION)
        end
        page.players:SetText(tostring(CountPlayers()))
    end,
})

local function RefreshIfShown()
    if home and home:IsVisible() then RefreshHome() end
end
RPF.Listen("PROFILE_CHANGED", RefreshIfShown)
RPF.OnEvent("PLAYER_GUILD_UPDATE", RefreshIfShown)
RPF.OnEvent("UNIT_PORTRAIT_UPDATE", function(unit)
    if unit == "player" then RefreshIfShown() end
end)

UI.RegisterPage({
    key = "about",
    title = "About",
    section = "RP Forge",
    sectionOrder = 1,
    order = 99,
    build = function(page)
        local heading = UI.Text(page, "About RP Forge", 20, "accent")
        heading:SetPoint("TOPLEFT", 28, -26)

        local lines = {
            "Made by NotThatSiri.",
            "Licensed under the Apache License 2.0. You may use, change and share it; keep the copyright notice and say what you changed.",
            "Found a bug? Click Report a bug: it gathers everything the report needs. Ideas are welcome on GitHub too.",
        }
        local anchor = heading
        for _, line in ipairs(lines) do
            local text = UI.Text(page, line, 12, "text")
            text:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, anchor == heading and -14 or -10)
            text:SetPoint("RIGHT", page, "RIGHT", -28, 0)
            anchor = text
        end

        local linkLabel = UI.Text(page, "GITHUB (click, then Ctrl+C to copy)", 10, "muted")
        linkLabel:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -22)
        local link = UI.EditBox(page, 380, 26)
        link:SetPoint("TOPLEFT", linkLabel, "BOTTOMLEFT", 0, -6)
        link:SetText(GITHUB_URL)
        link:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        -- Keep the link intact if someone types into it.
        link:SetScript("OnTextChanged", function(self, userInput)
            if userInput then self:SetText(GITHUB_URL); self:HighlightText() end
        end)

        local report = UI.Button(page, "Report a bug", 140, 26, "primary")
        report:SetPoint("TOPLEFT", link, "BOTTOMLEFT", 0, -22)
        report:SetScript("OnClick", function() RPF.OpenBugReport() end)
        page.errorCount = UI.Text(page, "", 11, "muted")
        page.errorCount:SetPoint("LEFT", report, "RIGHT", 14, 0)
    end,
    onShow = function(page)
        local count = #RPF.GetErrors()
        page.errorCount:SetText(count == 0 and "No errors logged." or (count .. " error(s) logged; they go into the report."))
    end,
})
