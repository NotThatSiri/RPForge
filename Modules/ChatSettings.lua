-- RP Forge: Settings > Chat (the RP chat window, the typing indicator and the button on the game's chat).
local _, RPF = ...
local UI = RPF.UI

local function ChatModule() return RPF.GetModule("RPChat") end

UI.RegisterSettingsPage({
    key = "chat",
    title = "Chat",
    order = 15,
    build = function(page)
        local layoutLabel = UI.Text(page, "RP CHAT LAYOUT", 10, "muted")
        layoutLabel:SetPoint("TOPLEFT", 0, -4)
        page.chatStyle = UI.Segmented(page, { { "game", "Game style" }, { "story", "Story style" } }, 130, function(value)
            RPF.db.settings.chatStyle = value
            if RPF.RPChat then RPF.RPChat.Refresh() end
        end)
        page.chatStyle:SetPoint("TOPLEFT", layoutLabel, "BOTTOMLEFT", 0, -8)
        local layoutHint = UI.Text(page, 'Game: Kiri says: Well met.     Story: Kiri: "Well met."', 11, "muted")
        layoutHint:SetPoint("LEFT", page.chatStyle, "RIGHT", 14, 0)

        local typing = UI.Toggle(page, "Typing indicator",
            "Shows \"Kiri is typing...\" when RP Forge users near you or in your group are writing: in the RP chat, "
                .. "or in a small bar under the chat while it's closed. Lets them see when you type too (RP chat, say, "
                .. "emote, party and raid; never whispers).",
            function() return RPF.db.settings.typingIndicator ~= false end,
            function(on) RPF.db.settings.typingIndicator = on end)
        typing:SetPoint("TOPLEFT", page.chatStyle, "BOTTOMLEFT", 0, -22)
        typing:SetPoint("RIGHT", page, "RIGHT", 0, 0)

        local group = UI.Toggle(page, "Party and raid in RP chat",
            "The RP chat window also shows what your party and raid write, and you can write to them from it with "
                .. "/p and /ra.",
            function() return RPF.db.settings.chatGroup == true end,
            function(on)
                RPF.db.settings.chatGroup = on
                local chat = ChatModule()
                if chat and chat.UpdateMode then chat.UpdateMode() end
            end)
        group:SetPoint("TOPLEFT", typing, "BOTTOMLEFT", 0, -16)
        group:SetPoint("RIGHT", page, "RIGHT", 0, 0)

        local whispers = UI.Toggle(page, "Whispers in RP chat",
            "The RP chat window also shows whispers you get and send, and you can whisper from it with /w Name "
                .. "and answer with /r.",
            function() return RPF.db.settings.chatWhispers == true end,
            function(on)
                RPF.db.settings.chatWhispers = on
                local chat = ChatModule()
                if chat and chat.UpdateMode then chat.UpdateMode() end
            end)
        whispers:SetPoint("TOPLEFT", group, "BOTTOMLEFT", 0, -16)
        whispers:SetPoint("RIGHT", page, "RIGHT", 0, 0)

        local button = UI.Toggle(page, "RP button on the chat",
            "A small \"RP\" button above the General chat tab that opens and closes the RP chat.",
            function() return RPF.db.settings.chatButton ~= false end,
            function(on)
                RPF.db.settings.chatButton = on
                local chat = ChatModule()
                if chat and chat.UpdateChatButton then chat.UpdateChatButton() end
            end)
        button:SetPoint("TOPLEFT", whispers, "BOTTOMLEFT", 0, -16)
        button:SetPoint("RIGHT", page, "RIGHT", 0, 0)

        local commandsLabel = UI.Text(page, "COMMANDS IN THE RP CHAT BOX", 10, "muted")
        commandsLabel:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -26)
        local commands = UI.Text(page,
            "/s say    /e emote    /y yell\n"
                .. "/p party    /ra raid    (with party and raid on)\n"
                .. "/w Name whisper    /r answer the last whisper    (with whispers on)\n"
                .. "The box stays on what you picked until you switch again.", 11, "text")
        commands:SetPoint("TOPLEFT", commandsLabel, "BOTTOMLEFT", 0, -6)
        commands:SetPoint("RIGHT", page, "RIGHT", 0, 0)
        commands:SetJustifyH("LEFT")
        commands:SetSpacing(4)
    end,
    onShow = function(page)
        page.chatStyle:SetValue(RPF.db.settings.chatStyle == "story" and "story" or "game")
    end,
})
