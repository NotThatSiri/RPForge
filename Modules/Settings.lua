-- RP Forge: the General settings page. Appearance has its own page in the same Settings section.
local _, RPF = ...
local UI = RPF.UI

UI.RegisterPage({
    key = "general",
    title = "General",
    section = "Settings",
    sectionOrder = 90,
    order = 10,
    build = function(page)
        local heading = UI.Text(page, "General", 20, "accent")
        heading:SetPoint("TOPLEFT", 28, -26)

        local network = UI.Toggle(page, "Player messages",
            "Lets RP Forge talk to other RP Forge players: update notices and \"Who's around?\". Needs a /reload when turned back on.",
            function() return RPF.db.settings.network end,
            function(on)
                RPF.db.settings.network = on
                if not on and LeaveChannelByName and RPF.Comm.ChannelID() then
                    LeaveChannelByName(RPF.Comm.CHANNEL_NAME)
                end
            end)
        network:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -22)
        network:SetPoint("RIGHT", page, "RIGHT", -28, 0)

        local debug = UI.Toggle(page, "Debug messages",
            "Prints extra details and errors in chat. Useful when something isn't working.",
            function() return RPF.db.settings.debug end,
            function(on) RPF.db.settings.debug = on end)
        debug:SetPoint("TOPLEFT", network, "BOTTOMLEFT", 0, -16)
        debug:SetPoint("RIGHT", page, "RIGHT", -28, 0)

        local windowLabel = UI.Text(page, "WINDOW", 10, "muted")
        windowLabel:SetPoint("TOPLEFT", debug, "BOTTOMLEFT", 0, -26)
        local reset = UI.Button(page, "Move to the middle", 170, 26)
        reset:SetPoint("TOPLEFT", windowLabel, "BOTTOMLEFT", 0, -8)
        reset:SetScript("OnClick", function() UI.ResetWindowPosition() end)
        local resetHint = UI.Text(page, "Puts this window back in the middle of the screen (/rpf reset).", 11, "muted")
        resetHint:SetPoint("LEFT", reset, "RIGHT", 14, 0)
    end,
})
