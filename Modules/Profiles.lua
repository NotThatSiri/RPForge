-- RP Forge: roleplay profiles.
--
-- Profiles belong to the account (RPForgeDB.profiles), so any character can use any profile.
-- Each character remembers which one it uses (RPForgeCharDB.activeProfile).
-- Every change goes through this file and sends "PROFILE_CHANGED", so sharing can react to it later.
local _, RPF = ...

local Profiles = {}
RPF.Profiles = Profiles

-- The fields of a profile, with the most letters each may hold.
Profiles.FIELDS = {
    -- Identity
    firstName = 64, lastName = 64, title = 48, fullTitle = 128, nickname = 64, pronouns = 32,
    race = 48, class = 48, age = 32, height = 32, eyes = 48, birthplace = 64, home = 64, house = 64,
    -- Status
    status = 8, currently = 256, oocNote = 256, motto = 160,
    -- About
    appearance = 5000, history = 5000,
}

Profiles.STATUS = {
    { "ic", "In character" },
    { "lfrp", "Looking for RP" },
    { "ooc", "Out of character" },
}

local function Store()
    return RPF.db.profiles
end

local function NewID()
    local id
    repeat
        id = string.format("p%d%04d", time(), math.random(0, 9999))
    until not Store()[id]
    return id
end

local function Changed(id)
    RPF.Send("PROFILE_CHANGED", id)
end

-- All profiles, sorted by name.
function Profiles.List()
    local list = {}
    for _, profile in pairs(Store()) do list[#list + 1] = profile end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    return list
end

function Profiles.Get(id)
    return id and Store()[id] or nil
end

function Profiles.GetActive()
    return Profiles.Get(RPF.char.activeProfile)
end

function Profiles.SetActive(id)
    if not Store()[id] then return false end
    RPF.char.activeProfile = id
    Changed(id)
    return true
end

local function UniqueName(name)
    name = strtrim(name or "")
    if name == "" then name = "New profile" end
    local taken = {}
    for _, profile in pairs(Store()) do taken[profile.name:lower()] = true end
    if not taken[name:lower()] then return name end
    local n = 2
    while taken[(name .. " " .. n):lower()] do n = n + 1 end
    return name .. " " .. n
end

-- Make a new profile, empty or as a copy of another one. Returns it.
function Profiles.Create(name, copyFromID)
    local id = NewID()
    local fields = {}
    local source = Profiles.Get(copyFromID)
    if source then
        for key, value in pairs(source.fields) do fields[key] = value end
    else
        -- New profiles start out of character: nobody is shown as IC until they choose it.
        fields.status = "ooc"
    end
    local look
    if source and source.look then
        look = {}
        for key, value in pairs(source.look) do look[key] = value end
    end
    local profile = { id = id, name = UniqueName(name), createdAt = time(), fields = fields, look = look }
    if source and source.persona then profile.persona = CopyTable(source.persona) end
    Store()[id] = profile
    return profile
end

-- Persona: how your character comes across.
--   icon         profile icon (an icon file ID or an icon name)
--   nameColor    "rrggbb", or nil for the default colour
--   impressions  up to 5 first impressions: { icon, title, text }
--   traits       up to 10 trait sliders: { left, right, value = 0..20 } (10 is the middle)
--   music        theme tune: a music file ID, or nil
Profiles.MAX_IMPRESSIONS = 5
Profiles.MAX_TRAITS = 10
Profiles.TRAIT_MAX = 20

function Profiles.GetPersona(profile)
    profile = profile or Profiles.GetActive()
    if not profile then return { impressions = {}, traits = {} } end
    local persona = profile.persona or {}
    persona.impressions = persona.impressions or {}
    persona.traits = persona.traits or {}
    profile.persona = persona
    return persona
end

-- Call after changing the active profile's persona.
function Profiles.PersonaChanged()
    local profile = Profiles.GetActive()
    if profile then
        profile.updatedAt = time()
        Changed(profile.id)
    end
end

function Profiles.Rename(id, name)
    local profile = Profiles.Get(id)
    if not profile then return false end
    name = strtrim(name or "")
    if name == "" or name:lower() == profile.name:lower() then return false end
    profile.name = UniqueName(name)
    Changed(id)
    return true
end

-- Delete a profile. The last one can't be deleted. Characters using it move to another profile.
function Profiles.Delete(id)
    if not Profiles.Get(id) then return false end
    local count = 0
    for _ in pairs(Store()) do count = count + 1 end
    if count <= 1 then return false end
    Store()[id] = nil
    if RPF.char.activeProfile == id then
        RPF.char.activeProfile = Profiles.List()[1].id
        Changed(RPF.char.activeProfile)
    end
    return true
end

-- Change one field of the active profile.
function Profiles.SetField(key, value)
    local profile = Profiles.GetActive()
    local limit = Profiles.FIELDS[key]
    if not profile or not limit then return false end
    value = tostring(value or "")
    if #value > limit then value = value:sub(1, limit) end
    if value == "" then value = nil end
    if profile.fields[key] == value then return true end
    profile.fields[key] = value
    profile.updatedAt = time()
    Changed(profile.id)
    return true
end

-- How a profile looks (for example the Home banner background). Kept apart from the text fields.
function Profiles.GetLook(key, profile)
    profile = profile or Profiles.GetActive()
    return profile and profile.look and profile.look[key] or nil
end

function Profiles.SetLook(key, value)
    local profile = Profiles.GetActive()
    if not profile then return false end
    profile.look = profile.look or {}
    profile.look[key] = value
    Changed(profile.id)
    return true
end

function Profiles.GetField(key, profile)
    profile = profile or Profiles.GetActive()
    return profile and profile.fields[key] or nil
end

-- "Lady Elira Dawnsong" style name for a profile; the character's own name when the name is empty.
function Profiles.FullName(profile)
    profile = profile or Profiles.GetActive()
    local f = profile and profile.fields or {}
    local name = strtrim(((f.firstName or "") .. " " .. (f.lastName or "")))
    if name == "" then name = UnitName("player") or "" end
    if f.title and f.title ~= "" then name = f.title .. " " .. name end
    return name
end

-- Make sure there is at least one profile and that this character uses one.
-- Done at login: the character's name isn't always known while saved data loads.
RPF.OnEvent("PLAYER_LOGIN", function()
    RPF.db.profiles = RPF.db.profiles or {}
    if not next(Store()) then
        local first = Profiles.Create(UnitName("player"))
        RPF.char.activeProfile = first.id
    end
    if not Profiles.GetActive() then
        RPF.char.activeProfile = Profiles.List()[1].id
    end
    -- "Epithet" became "Full title" during 0.2.0: move anything typed there.
    for _, profile in pairs(Store()) do
        if profile.fields.epithet then
            profile.fields.fullTitle = profile.fields.fullTitle or profile.fields.epithet
            profile.fields.epithet = nil
        end
    end
end)
