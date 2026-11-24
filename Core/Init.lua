-- RP Forge: core namespace, version numbers, events and modules.
local ADDON_NAME, RPF = ...
_G.RPForge = RPF

RPF.NAME = "RP Forge"
RPF.ADDON = ADDON_NAME

local GetMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata

-- The addon version is read from RPForge.toc, so the TOC is the only place it is set.
RPF.VERSION = (GetMetadata and GetMetadata(ADDON_NAME, "Version")) or "0.0.0"
-- Saved data layout. Raise it with a new step in Core\Data.lua when the layout changes.
RPF.SCHEMA_VERSION = 1
-- Player-to-player message format. Raise it when older versions can no longer read our messages.
RPF.PROTOCOL_VERSION = 1

-- Secret values ---------------------------------------------------------------
-- This client hides some unit details from addons (for example who a nameplate belongs to) as "secret"
-- values. Addons may not compare or test them, so every unit lookup goes through these helpers, which
-- return nil instead of a secret.

function RPF.IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value) == true
end

-- UnitGUID(unit), or nil when hidden.
function RPF.UnitGUID(unit)
    local guid = UnitGUID(unit)
    if RPF.IsSecret(guid) then return nil end
    return guid
end

-- The unit's name ("Name-Realm" for other realms), or nil when hidden or not a player.
function RPF.PlayerName(unit)
    local exists = UnitExists(unit)
    if RPF.IsSecret(exists) or not exists then return nil end
    local isPlayer = UnitIsPlayer(unit)
    if RPF.IsSecret(isPlayer) or not isPlayer then return nil end
    local name = GetUnitName(unit, true)
    if RPF.IsSecret(name) then return nil end
    return name
end

-- Game events ---------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
local gameHandlers = {}

-- Listen to a game event. Errors in one handler never stop the others.
function RPF.OnEvent(event, handler)
    local list = gameHandlers[event]
    if not list then
        list = {}
        gameHandlers[event] = list
        eventFrame:RegisterEvent(event)
    end
    list[#list + 1] = handler
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    for _, handler in ipairs(gameHandlers[event]) do
        RPF.SafeCall(event, handler, ...)
    end
end)

-- Our own messages between parts of the addon --------------------------------

local listeners = {}

function RPF.Listen(message, handler)
    listeners[message] = listeners[message] or {}
    table.insert(listeners[message], handler)
end

function RPF.Send(message, ...)
    for _, handler in ipairs(listeners[message] or {}) do
        RPF.SafeCall(message, handler, ...)
    end
end

-- Modules --------------------------------------------------------------------

local modules, moduleOrder = {}, {}

-- Each feature is a module. Its OnLogin runs once saved data is ready and the player is in the world.
function RPF.NewModule(name)
    assert(not modules[name], "RP Forge module registered twice: " .. tostring(name))
    local module = { name = name }
    modules[name] = module
    moduleOrder[#moduleOrder + 1] = module
    return module
end

function RPF.GetModule(name)
    return modules[name]
end

RPF.OnEvent("PLAYER_LOGIN", function()
    for _, module in ipairs(moduleOrder) do
        if module.OnLogin then
            RPF.SafeCall("module " .. module.name, module.OnLogin, module)
        end
    end
    RPF.Send("READY")
end)
