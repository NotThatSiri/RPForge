-- RP Forge: saved data and its upgrades.
--
-- RPForgeDB     is shared by every character on the account (settings, content packs).
-- RPForgeCharDB belongs to one character (profile, sheet, quests in progress).
--
-- Each has a schema number. When the data layout changes, raise RPF.SCHEMA_VERSION and add a step to
-- UPGRADES below that turns version N-1 data into version N. Steps run in order, once, on login.
local ADDON_NAME, RPF = ...

local ACCOUNT_DEFAULTS = {
    settings = {
        debug = false,
        network = true, -- player messages: version check, /rpf who, and later profiles
        theme = "parchment", -- parchment, forge or arcane (UI\Theme.lua)
        minimap = { shown = true, angle = 210 },
    },
    profiles = {}, -- roleplay profiles, shared by all characters (Modules\Profiles.lua)
    people = {},   -- profiles heard from other players (Modules\Sharing.lua)
}

local CHARACTER_DEFAULTS = {}

-- UPGRADES[n] = { account = function(db) ... end, character = function(char) ... end }
-- Version 1 is the first layout, so there is nothing to upgrade yet.
local UPGRADES = {}

-- Fill in anything missing from defaults without touching values the player already has.
local function ApplyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            ApplyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local function Upgrade(data, kind)
    local from = tonumber(data.schema) or 0
    if from > RPF.SCHEMA_VERSION then
        -- Saved by a newer RP Forge. Leave it alone rather than damage it.
        RPF.LogError("data", kind .. " data is from a newer RP Forge (schema " .. from .. ")")
        return false
    end
    for version = from + 1, RPF.SCHEMA_VERSION do
        local step = UPGRADES[version] and UPGRADES[version][kind]
        if step then
            local ok = RPF.SafeCall("upgrade " .. kind .. " to " .. version, step, data)
            if not ok then return false end
        end
        data.schema = version
    end
    return true
end

RPF.OnEvent("ADDON_LOADED", function(name)
    if name ~= ADDON_NAME then return end

    if type(RPForgeDB) ~= "table" then RPForgeDB = {} end
    if type(RPForgeCharDB) ~= "table" then RPForgeCharDB = {} end

    Upgrade(RPForgeDB, "account")
    Upgrade(RPForgeCharDB, "character")
    ApplyDefaults(RPForgeDB, ACCOUNT_DEFAULTS)
    ApplyDefaults(RPForgeCharDB, CHARACTER_DEFAULTS)

    RPF.db = RPForgeDB
    RPF.char = RPForgeCharDB

    RPF.RestoreErrors(RPF.db.errors)
    RPF.db.errors = RPF.GetErrors()

    local previous = RPF.db.lastVersion
    RPF.db.lastVersion = RPF.VERSION
    if previous and previous ~= RPF.VERSION then
        RPF.Send("UPDATED", previous, RPF.VERSION)
    end

    RPF.Send("DATA_READY")
end)

RPF.Listen("UPDATED", function(previous, current)
    RPF.Print("updated from " .. previous .. " to " .. current .. ".")
end)
