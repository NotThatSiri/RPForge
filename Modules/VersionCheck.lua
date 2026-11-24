-- RP Forge: tells you when a newer RP Forge is out, and lists who around you uses it.
--
-- Addons can't reach the internet, so a newer version can only be learned from other players.
--   * At login (and when your group grows) your version is announced to guild, group and the
--     RP Forge channel.
--   * Anyone who hears an OLDER version answers that player directly with an invisible addon
--     whisper, so the older copy learns about the update without flooding any channel.
--   * You are told once per session. At later logins you are reminded only if that newer version
--     was heard in the last 3 days, so a tester's build can't nag everyone forever.
--   * /rpf who asks everyone for their version and lists the replies.
--
-- The "V" message must stay readable by every future RP Forge: payload is just the version text.
local _, RPF = ...

local VersionCheck = RPF.NewModule("VersionCheck")
local Comm = RPF.Comm

local REMIND_FOR = 3 * 24 * 60 * 60
local GROUP_ANNOUNCE_GAP = 30
local REPLY_GAP_PER_PLAYER = 300

local toldThisSession = false
local lastGroupAnnounce = 0
local lastReplyTo = {}
local lastGroupSize = 0

-- Players heard this session: peers[name] = { version, protocol, seen, channel }
local peers = {}
VersionCheck.peers = peers

local function Remember(sender, version, protocol, channel)
    peers[Comm.ShortName(sender)] = { version = version, protocol = protocol, seen = GetTime(), channel = channel }
end

local function Tell(version, from)
    toldThisSession = true
    RPF.Print(string.format("|cff66ff66RP Forge %s is out|r (you have %s)%s. Update when you can.",
        version, RPF.VERSION, from and (", seen from " .. from) or ""))
end

-- A version newer than ours was heard: keep the newest, tell the player once per session.
local function NoteNewer(version, sender)
    local saved = RPF.db.newestSeen
    if not saved or RPF.IsNewerVersion(version, saved.version) then
        RPF.db.newestSeen = { version = version, at = time() }
    elseif saved.version == version then
        saved.at = time()
    end
    if not toldThisSession then
        Tell(version, sender and Comm.ShortName(sender))
    end
end

local function AnswerWithVersion(sender)
    local name = Comm.ShortName(sender)
    local now = GetTime()
    if lastReplyTo[name] and now - lastReplyTo[name] < REPLY_GAP_PER_PLAYER then return end
    lastReplyTo[name] = now
    -- A short random wait spreads out answers when many players hear the same message.
    C_Timer.After(1 + math.random() * 3, function()
        Comm.Send("V", RPF.VERSION, "WHISPER", sender)
    end)
end

Comm.On("V", function(version, sender, channel, protocol)
    if not RPF.ParseVersion(version) then return end
    Remember(sender, version, protocol, channel)
    local compare = RPF.CompareVersions(version, RPF.VERSION)
    if compare == 1 then
        NoteNewer(version, sender)
    elseif compare == -1 and channel ~= "WHISPER" then
        -- They are behind: let them know directly.
        AnswerWithVersion(sender)
    end
end)

-- "Q": someone ran /rpf who. Answer with our version by whisper.
Comm.On("Q", function(_, sender)
    lastReplyTo[Comm.ShortName(sender)] = nil
    AnswerWithVersion(sender)
end)

local function Announce()
    Comm.Broadcast("V", RPF.VERSION)
end

function VersionCheck:OnLogin()
    -- Forget the saved newer version once we have caught up with it, or when it is too old to trust.
    local saved = RPF.db.newestSeen
    if saved and (not RPF.IsNewerVersion(saved.version, RPF.VERSION) or time() - (saved.at or 0) > REMIND_FOR) then
        RPF.db.newestSeen = nil
        saved = nil
    end
    C_Timer.After(12, function()
        if saved and not toldThisSession then Tell(saved.version) end
        Comm.Send("V", RPF.VERSION, "GUILD")
        local group = Comm.GroupChannel()
        if group then Comm.Send("V", RPF.VERSION, group) end
    end)
    lastGroupSize = GetNumGroupMembers()
end

-- The channel is joined a little after login; announce there once it is ready.
RPF.Listen("CHANNEL_READY", function()
    Comm.Send("V", RPF.VERSION, "CHANNEL")
end)

RPF.OnEvent("GROUP_ROSTER_UPDATE", function()
    local size = GetNumGroupMembers()
    local grew = size > lastGroupSize
    lastGroupSize = size
    if not grew or not RPF.db then return end
    local now = GetTime()
    if now - lastGroupAnnounce < GROUP_ANNOUNCE_GAP then return end
    lastGroupAnnounce = now
    local group = Comm.GroupChannel()
    if group then
        C_Timer.After(2 + math.random() * 3, function() Comm.Send("V", RPF.VERSION, group) end)
    end
end)

RPF.AddCommand("who", "List RP Forge users around you and their versions", function()
    if not RPF.db.settings.network then
        RPF.Print("player messages are turned off.")
        return
    end
    RPF.Print("asking guild, group and the RP Forge channel...")
    Comm.Broadcast("Q", "")
    C_Timer.After(6, function()
        local names = {}
        for name, info in pairs(peers) do
            if GetTime() - info.seen < 600 then names[#names + 1] = name end
        end
        table.sort(names)
        if #names == 0 then
            RPF.Print("no other RP Forge users answered.")
            return
        end
        RPF.Print(#names .. " RP Forge user(s):")
        for _, name in ipairs(names) do
            local info = peers[name]
            local compare = RPF.CompareVersions(info.version, RPF.VERSION)
            local colour = compare == 1 and "|cff66ff66" or (compare == -1 and "|cffffaa55" or "|cffffffff")
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s  %s%s|r", name, colour, info.version))
        end
    end)
end)

RPF.AddCommand("network", "Turn player messages on or off (version check, /rpf who)", function()
    RPF.db.settings.network = not RPF.db.settings.network
    if RPF.db.settings.network then
        RPF.Print("player messages on. They start after a /reload.")
    else
        if LeaveChannelByName and Comm.ChannelID() then LeaveChannelByName(Comm.CHANNEL_NAME) end
        RPF.Print("player messages off.")
    end
end)
