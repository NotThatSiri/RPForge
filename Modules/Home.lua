-- RP Forge: the Home and About pages.
local _, RPF = ...
local UI = RPF.UI

local GITHUB_URL = "https://github.com/NotThatSiri/RPForge"

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
        local heading = UI.Text(page, "Welcome to RP Forge", 20, "accent")
        heading:SetPoint("TOPLEFT", 28, -26)

        local intro = UI.Text(page,
            "Roleplay tools for WoW Forever. RP Forge is in early development: this window is the start, and each update adds a new part. " ..
            "Everything you make in RP Forge will be made in game by players, for Horde and Alliance alike.", 12, "text")
        intro:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -14)
        intro:SetPoint("RIGHT", page, "RIGHT", -28, 0)
        intro:SetSpacing(3)

        local card = UI.Panel(page, "panel", "border")
        card:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -22)
        card:SetPoint("RIGHT", page, "RIGHT", -28, 0)
        card:SetHeight(96)

        local versionLabel = UI.Text(card, "VERSION", 10, "muted")
        versionLabel:SetPoint("TOPLEFT", 16, -14)
        page.version = UI.Text(card, "", 15, "text")
        page.version:SetPoint("TOPLEFT", versionLabel, "BOTTOMLEFT", 0, -6)

        local playersLabel = UI.Text(card, "RP FORGE PLAYERS HEARD", 10, "muted")
        playersLabel:SetPoint("TOPLEFT", 260, -14)
        page.players = UI.Text(card, "", 15, "text")
        page.players:SetPoint("TOPLEFT", playersLabel, "BOTTOMLEFT", 0, -6)

        local who = UI.Button(card, "Who's around?", 130, 26, "primary")
        who:SetPoint("BOTTOMRIGHT", -14, 14)
        UI.Tooltip(who, "Who's around?", "Asks your guild, your group and the RP Forge channel who uses RP Forge. The answers also appear in chat.")
        who:SetScript("OnClick", function()
            SlashCmdList.RPFORGE("who")
            C_Timer.After(6.5, function()
                if page:IsVisible() then page.players:SetText(tostring(CountPlayers())) end
            end)
        end)

        local comingNext = UI.Text(page, "Coming next: a bug report button, then your profile and its link with Total RP 3.", 11, "muted")
        comingNext:SetPoint("TOPLEFT", card, "BOTTOMLEFT", 0, -18)
    end,
    onShow = function(page)
        local newer = RPF.db.newestSeen
        if newer and RPF.IsNewerVersion(newer.version, RPF.VERSION) then
            page.version:SetText(RPF.VERSION .. UI.ColorCode("warn") .. "   (" .. newer.version .. " is out)|r")
        else
            page.version:SetText(RPF.VERSION)
        end
        page.players:SetText(tostring(CountPlayers()))
    end,
})

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
            "Found a bug or have an idea? Use the link below. /rpf errors shows anything that went wrong.",
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
    end,
})
