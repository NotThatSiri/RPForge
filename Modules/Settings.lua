-- RP Forge: Settings > General.
local _, RPF = ...
local UI = RPF.UI

UI.RegisterSettingsPage({
    key = "general",
    title = "General",
    order = 10,
    build = function(page)
        local network = UI.Toggle(page, "Player messages",
            "Lets RP Forge talk to other RP Forge players: update notices and \"Who's around?\". Needs a /reload when turned back on.",
            function() return RPF.db.settings.network end,
            function(on)
                RPF.db.settings.network = on
                if not on and LeaveChannelByName and RPF.Comm.ChannelID() then
                    LeaveChannelByName(RPF.Comm.CHANNEL_NAME)
                end
            end)
        network:SetPoint("TOPLEFT", 0, -4)
        network:SetPoint("RIGHT", page, "RIGHT", 0, 0)

        local typing = UI.Toggle(page, "Typing indicator",
            "Shows \"Kiri is typing...\" when RP Forge users near you or in your group are writing: in the RP chat, "
                .. "or in a small bar under the chat while it's closed. Lets them see when you type too (RP chat, say, "
                .. "emote, party and raid).",
            function() return RPF.db.settings.typingIndicator ~= false end,
            function(on) RPF.db.settings.typingIndicator = on end)
        typing:SetPoint("TOPLEFT", network, "BOTTOMLEFT", 0, -16)
        typing:SetPoint("RIGHT", page, "RIGHT", 0, 0)

        local debug = UI.Toggle(page, "Debug messages",
            "Prints extra details and errors in chat. Useful when something isn't working.",
            function() return RPF.db.settings.debug end,
            function(on) RPF.db.settings.debug = on end)
        debug:SetPoint("TOPLEFT", typing, "BOTTOMLEFT", 0, -16)
        debug:SetPoint("RIGHT", page, "RIGHT", 0, 0)

        local trpLabel = UI.Text(page, "TOTAL RP 3", 10, "muted")
        trpLabel:SetPoint("TOPLEFT", debug, "BOTTOMLEFT", 0, -26)
        page.trpState = UI.Text(page, "", 12, "text")
        page.trpState:SetPoint("TOPLEFT", trpLabel, "BOTTOMLEFT", 0, -6)
        page.trpState:SetPoint("RIGHT", page, "RIGHT", -150, 0)
        page.trpState:SetJustifyH("LEFT")
        local again = UI.Button(page, "Choose again", 130, 26)
        again:SetPoint("LEFT", page.trpState, "RIGHT", 14, 0)
        again:SetScript("OnClick", function() if RPF.TRP3Link then RPF.TRP3Link.Ask() end end)
        page.trpAgain = again

        local windowLabel = UI.Text(page, "WINDOW", 10, "muted")
        windowLabel:SetPoint("TOPLEFT", page.trpState, "BOTTOMLEFT", 0, -26)
        local reset = UI.Button(page, "Move to the middle", 170, 26)
        reset:SetPoint("TOPLEFT", windowLabel, "BOTTOMLEFT", 0, -8)
        reset:SetScript("OnClick", function() UI.ResetWindowPosition() end)
        local resetHint = UI.Text(page, "Puts this window back in the middle of the screen (/rpf reset).", 11, "muted")
        resetHint:SetPoint("LEFT", reset, "RIGHT", 14, 0)
    end,
    onShow = function(page)
        local link = RPF.TRP3Link
        page.trpState:SetText(link and link.Describe() or "")
        page.trpAgain:SetEnabled(link ~= nil and link.TRP3Running())
    end,
})
