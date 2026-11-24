-- RP Forge: messages between players.
--
-- Uses the game's hidden addon messages. Every message is
--     <protocol>\t<kind>\t<payload>
-- where <kind> names what it is (V = version). Features register a handler per kind.
-- Messages are queued and sent at a steady pace so the game never throttles us.
--
-- Reach: guild, party/raid, whispers, and a hidden chat channel that every RP Forge user joins,
-- so players outside your guild and group can be reached too.
local _, RPF = ...

local Comm = {}
RPF.Comm = Comm

Comm.PREFIX = "RPForge"
Comm.CHANNEL_NAME = "RPForgeNet"

local MAX_LENGTH = 250
local BURST, REFILL_PER_SECOND = 6, 1

local handlers = {}
local queue = {}
local tokens = BURST
local ticker

local SendAddon = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
local RegisterPrefix = (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix

-- Names ------------------------------------------------------------------------

local function PlayerName()
    local name, realm = UnitFullName("player")
    if realm and realm ~= "" then return name .. "-" .. realm end
    return name
end

-- A sender in a short, comparable form (no realm when it is our own realm).
function Comm.ShortName(sender)
    if Ambiguate then return Ambiguate(sender or "", "none") end
    return (tostring(sender or ""):gsub("%-.*$", ""))
end

function Comm.IsSelf(sender)
    local short = Comm.ShortName(sender)
    return short == UnitName("player") or sender == PlayerName()
end

-- The hidden channel -------------------------------------------------------------

function Comm.ChannelID()
    local id = GetChannelName(Comm.CHANNEL_NAME)
    return (id and id > 0) and id or nil
end

local function HideChannelFromChat()
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local frame = _G["ChatFrame" .. i]
        if frame and ChatFrame_RemoveChannel then ChatFrame_RemoveChannel(frame, Comm.CHANNEL_NAME) end
    end
end

-- Joined a little after login so the game's own channels (General, Trade...) keep their numbers.
local function JoinChannel(attempt)
    if not RPF.db.settings.network then return end
    if Comm.ChannelID() then
        HideChannelFromChat()
        RPF.Send("CHANNEL_READY")
        return
    end
    if JoinTemporaryChannel then JoinTemporaryChannel(Comm.CHANNEL_NAME) end
    C_Timer.After(2, function()
        if Comm.ChannelID() then
            HideChannelFromChat()
            RPF.Send("CHANNEL_READY")
        elseif attempt < 5 then
            C_Timer.After(10, function() JoinChannel(attempt + 1) end)
        else
            RPF.Debug("could not join the RP Forge channel.")
        end
    end)
end

-- Sending ------------------------------------------------------------------------

local function Flush()
    while #queue > 0 and tokens >= 1 do
        local item = table.remove(queue, 1)
        local target = item.target
        local ok = true
        if item.channel == "CHANNEL" then
            target = Comm.ChannelID()
            ok = target ~= nil
        end
        if ok then
            tokens = tokens - 1
            RPF.SafeCall("send " .. item.channel, SendAddon, Comm.PREFIX, item.text, item.channel, target)
        end
    end
    if #queue == 0 and tokens >= BURST and ticker then
        ticker:Cancel()
        ticker = nil
    end
end

local function EnsureTicker()
    if ticker then return end
    ticker = C_Timer.NewTicker(1 / REFILL_PER_SECOND, function()
        tokens = math.min(BURST, tokens + 1)
        Flush()
    end)
end

-- Send a message. channel: "GUILD", "PARTY", "RAID", "WHISPER" (with target) or "CHANNEL".
function Comm.Send(kind, payload, channel, target)
    if not RPF.db.settings.network then return false end
    local text = RPF.PROTOCOL_VERSION .. "\t" .. kind .. "\t" .. tostring(payload or "")
    if #text > MAX_LENGTH then
        RPF.LogError("comm", "message too long (" .. #text .. "): " .. kind)
        return false
    end
    if channel == "GUILD" and not IsInGuild() then return false end
    if (channel == "PARTY" or channel == "RAID") and not IsInGroup() then return false end
    if channel == "CHANNEL" and not Comm.ChannelID() then return false end
    queue[#queue + 1] = { text = text, channel = channel, target = target }
    Flush()
    EnsureTicker()
    return true
end

-- The group channel that fits right now, or nil when not grouped.
-- (Classic has no instance groups, so only raid and party.)
function Comm.GroupChannel()
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
    return nil
end

-- Send to every place other RP Forge users might hear it.
function Comm.Broadcast(kind, payload)
    Comm.Send(kind, payload, "GUILD")
    local group = Comm.GroupChannel()
    if group then Comm.Send(kind, payload, group) end
    Comm.Send(kind, payload, "CHANNEL")
end

-- Receiving ------------------------------------------------------------------------

-- handler(payload, sender, channel, protocol)
function Comm.On(kind, handler)
    handlers[kind] = handler
end

RPF.OnEvent("CHAT_MSG_ADDON", function(prefix, text, channel, sender)
    if prefix ~= Comm.PREFIX or Comm.IsSelf(sender) then return end
    local protocol, kind, payload = tostring(text):match("^(%d+)\t([^\t]+)\t(.*)$")
    if not protocol then return end
    protocol = tonumber(protocol)
    local handler = handlers[kind]
    if handler then
        handler(payload, sender, channel, protocol)
    end
end)

RPF.Listen("DATA_READY", function()
    if RegisterPrefix then RegisterPrefix(Comm.PREFIX) end
end)

RPF.OnEvent("PLAYER_ENTERING_WORLD", function(isLogin, isReload)
    if isLogin or isReload then
        C_Timer.After(10, function() JoinChannel(1) end)
    end
end)
