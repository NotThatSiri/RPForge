-- RP Forge: sharing profiles with other roleplay addons (Total RP 3, MyRolePlay, XRP...).
--
-- Uses the Mary Sue Protocol through LibMSP (in Libs), the format those addons share.
-- Only one addon per player may answer MSP requests. At login:
--   * another roleplay addon is running (e.g. Total RP 3)  -> it sends your profile; RP Forge stays quiet
--   * none is running                                      -> RP Forge sends your active profile
-- When RP Forge sends, it also adds roleplay names, titles and status to player tooltips, and remembers
-- the profiles it hears so they can be shown later.
local _, RPF = ...
local UI = RPF.UI
local Profiles = RPF.Profiles

local Sharing = RPF.NewModule("Sharing")
RPF.Sharing = Sharing

-- Folder names of roleplay addons that answer MSP themselves.
local OTHER_ADDONS = {
    { folder = "totalRP3", name = "Total RP 3" },
    { folder = "MyRolePlay", name = "MyRolePlay" },
    { folder = "xrp", name = "XRP" },
    { folder = "KinshipRP", name = "Kinship" },
}

-- Our status -> MSP character status (FC): 1 out of character, 2 in character, 3 looking for contact.
local STATUS_TO_FC = { ooc = "1", ic = "2", lfrp = "3" }
local FC_TEXT = {
    ["1"] = { "Out of character", "muted" },
    ["2"] = { "In character", "good" },
    ["3"] = { "Looking for RP", "accent" },
    ["4"] = { "Storyteller", "accent" },
}

-- Our profile field -> MSP field.
local FIELD_MAP = {
    title = "PX", fullTitle = "NT", nickname = "NI", house = "NH", pronouns = "PN",
    race = "RA", class = "RC", age = "AG", height = "AH", eyes = "AE",
    birthplace = "HB", home = "HH", motto = "MO", currently = "CU", oocNote = "CO",
    appearance = "DE", history = "HI",
}

Sharing.mode = "off" -- "own" (RP Forge sends), "other" (another addon sends) or "off"
Sharing.otherAddon = nil

local IsLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded

-- Values the game marks as secret (some unit tokens in this client) can't be used by addons.
local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value) == true
end

local function MergedName(unit)
    if IsSecret(unit) or not unit then return nil end
    local okName, name, realm = pcall(UnitFullName, unit)
    if not okName or IsSecret(name) or not name then return nil end
    -- On surname clients (WoW Forever) Chomp refuses names that aren't "Given Surname" yet, for example
    -- while the game is still loading someone's name. Fall back to the plain name instead of an error.
    if AddOn_Chomp and AddOn_Chomp.NameMergedRealm then
        local ok, merged = pcall(AddOn_Chomp.NameMergedRealm, name, realm)
        if ok then return merged end
    end
    return (realm and realm ~= "") and (name .. "-" .. realm) or name
end

-- Sending ---------------------------------------------------------------------------------

-- Every MSP field RP Forge sends, so fields left empty are cleared too.
local SENT_FIELDS = { "NA", "PX", "NT", "NI", "NH", "PN", "RA", "RC", "AG", "AH", "AE", "HB", "HH", "MO",
    "CU", "CO", "DE", "HI", "FC", "IC", "MU", "PE", "PS" }

-- A profile as MSP fields (the same table other players receive).
function Sharing.BuildFields(profile)
    profile = profile or Profiles.GetActive()
    local f = profile and profile.fields or {}
    local my = {}
    local name = strtrim((f.firstName or "") .. " " .. (f.lastName or ""))
    my.NA = name ~= "" and name or UnitName("player")
    for ours, theirs in pairs(FIELD_MAP) do
        local value = f[ours]
        my[theirs] = (value and value ~= "") and value or nil
    end
    my.FC = STATUS_TO_FC[f.status] or "1"

    -- Persona, in the forms Total RP 3 reads: name colour inside the name, the icon as a file ID,
    -- first impressions as glances (PE) and traits as [trait ...] lines (PS).
    local persona = Profiles.GetPersona(profile)
    if persona.nameColor then my.NA = "|cff" .. persona.nameColor .. my.NA .. "|r" end
    my.IC = persona.icon and tostring(UI.IconTexture(persona.icon)) or nil
    my.MU = persona.music and tostring(persona.music) or nil
    local glances = {}
    for slot = 1, Profiles.MAX_IMPRESSIONS do
        local impression = persona.impressions[slot]
        if impression and ((impression.title or "") ~= "" or (impression.text or "") ~= "") then
            glances[#glances + 1] = UI.IconMarkup(impression.icon) .. "\n#" .. (impression.title or "") .. "\n\n" .. (impression.text or "")
        end
    end
    my.PE = #glances > 0 and table.concat(glances, "\n\n---\n\n") or nil
    local traits = {}
    for _, trait in ipairs(persona.traits) do
        local left, right = strtrim(trait.left or ""), strtrim(trait.right or "")
        if left ~= "" and right ~= "" then
            traits[#traits + 1] = string.format('[trait value="%.2f" left-name=%q left-icon="%d" left-color="d9a441" right-name=%q right-icon="%d" right-color="6fa8dc"]',
                (trait.value or Profiles.TRAIT_MAX / 2) / Profiles.TRAIT_MAX,
                left:gsub('[%]="]', ""), UI.DEFAULT_ICON, right:gsub('[%]="]', ""), UI.DEFAULT_ICON)
        end
    end
    my.PS = #traits > 0 and table.concat(traits, "\n") or nil
    return my
end

-- Put the active profile into LibMSP's table and tell it to update.
local function Publish()
    if Sharing.mode ~= "own" or not msp then return end
    local fields = Sharing.BuildFields()
    for _, key in ipairs(SENT_FIELDS) do msp.my[key] = fields[key] end
    msp.my.VA = "RPForge/" .. RPF.VERSION
    RPF.SafeCall("msp update", msp.Update, msp)
end

-- Several edits in a row (typing) are sent as one update.
local publishPending = false
local function PublishSoon()
    if publishPending then return end
    publishPending = true
    C_Timer.After(2, function()
        publishPending = false
        Publish()
    end)
end

-- Receiving -------------------------------------------------------------------------------

-- The fields kept for each person, so their profile can be shown later (the People page).
local KEPT_FIELDS = { "NA", "PX", "NT", "NI", "NH", "PN", "RA", "RC", "AG", "AH", "AE", "AW", "HB", "HH",
    "MO", "CU", "CO", "DE", "HI", "FC", "IC", "MU", "PE", "PS", "VA" }
local MAX_PEOPLE = 500

-- Forget the people seen longest ago once there are too many.
local function Prune()
    local list = {}
    for name, person in pairs(RPF.db.people) do list[#list + 1] = { name = name, seen = person.seen or 0 } end
    if #list <= MAX_PEOPLE then return end
    table.sort(list, function(a, b) return a.seen > b.seen end)
    for i = MAX_PEOPLE + 1, #list do RPF.db.people[list[i].name] = nil end
end

-- LibMSP only takes full names: on a client with surnames, "Kiri" alone (no surname) is an error. Such a
-- name is treated as one we know nothing about.
local function CanLookUp(name)
    if not msp or type(name) ~= "string" or name == "" or RPF.IsSecret(name) then return false end
    if AddOn_Chomp and AddOn_Chomp.NameMergedRealm then
        return (pcall(AddOn_Chomp.NameMergedRealm, name))
    end
    return true
end

-- What LibMSP knows about this person, or nil.
local function MspChar(name)
    if not CanLookUp(name) then return nil end
    local ok, char = pcall(function() return msp.char[name] end)
    return ok and char or nil
end

-- Keep a record of each profile heard.
local function Remember(name)
    local char = MspChar(name)
    local field = char and char.field
    if not field or not field.NA or field.NA == "" then return end
    RPF.db.people = RPF.db.people or {}
    local person = RPF.db.people[name] or {}
    person.fields = person.fields or {}
    for _, key in ipairs(KEPT_FIELDS) do
        if field[key] ~= nil then person.fields[key] = field[key] end
    end
    local isNew = person.seen == nil
    person.seen = time()
    RPF.db.people[name] = person
    if isNew then Prune() end
    RPF.Send("PERSON_UPDATED", name)
end

-- Ask someone for their whole profile (used when opening it). LibMSP limits how often.
function Sharing.RequestProfile(name)
    if CanLookUp(name) and name ~= MergedName("player") then
        RPF.SafeCall("request profile", msp.Request, msp, name, KEPT_FIELDS)
    end
end

-- Ask someone for their name card only (the tooltip fields). LibMSP limits how often.
function Sharing.RequestTooltip(name)
    if CanLookUp(name) and name ~= MergedName("player") then
        RPF.SafeCall("request tooltip", msp.Request, msp, name)
    end
end

-- Someone's profile fields: what we just heard, or what was kept from before.
function Sharing.GetProfile(name)
    if name == MergedName("player") then return Sharing.BuildFields() end
    local char = MspChar(name)
    local live = char and char.field
    if live and live.NA and live.NA ~= "" then return live end
    local person = RPF.db.people and RPF.db.people[name]
    return person and person.fields or nil
end

Sharing.MergedName = MergedName

-- Tooltips ---------------------------------------------------------------------------------

local function Fields(name)
    if name == MergedName("player") and msp then return msp.my end
    local char = MspChar(name)
    return char and char.field or nil
end

local function AddLines(tooltip, unit)
    local name = MergedName(unit)
    if not name then return end
    if name ~= MergedName("player") and CanLookUp(name) then msp:Request(name) end -- asks for the tooltip fields; LibMSP limits how often
    local field = Fields(name)
    if not field or not field.NA or field.NA == "" then return end

    local nameLine = (field.PX and field.PX ~= "" and (field.PX .. " ") or "") .. field.NA
    tooltip:AddLine(nameLine, 1, 0.86, 0.56)
    if field.NT and field.NT ~= "" then
        tooltip:AddLine("< " .. field.NT .. " >", 0.8, 0.76, 0.68, true)
    end
    local status = FC_TEXT[field.FC or ""]
    if status then
        local c = UI.THEMES.forge.colors[status[2]] or UI.THEMES.forge.colors.text
        tooltip:AddLine(status[1], c[1], c[2], c[3])
    end
    if field.CU and field.CU ~= "" then
        tooltip:AddLine("Currently: " .. field.CU, 0.9, 0.9, 0.9, true)
    end
    tooltip:Show()
end

-- The unit a tooltip shows. The game may hand it over as a secret value; then use the unit under the
-- mouse, which is what the tooltip shows in that case.
local function TooltipUnit(tooltip)
    local _, unit = tooltip:GetUnit()
    if IsSecret(unit) or unit == nil then
        unit = UnitExists("mouseover") and "mouseover" or nil
    end
    return unit
end

local function OnTooltipUnit(tooltip)
    if Sharing.mode ~= "own" or tooltip ~= GameTooltip then return end
    local unit = TooltipUnit(tooltip)
    if unit and UnitIsPlayer(unit) then RPF.SafeCall("tooltip", AddLines, tooltip, unit) end
end

local function HookTooltips()
    if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipUnit)
    else
        GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipUnit)
    end
end

-- When an answer arrives while that player's tooltip is still open, show it straight away.
local function OnReceived(name)
    RPF.SafeCall("remember", Remember, name)
    if not GameTooltip:IsShown() then return end
    local unit = TooltipUnit(GameTooltip)
    if unit and MergedName(unit) == name then GameTooltip:SetUnit(unit) end
end

-- Start ------------------------------------------------------------------------------------

function Sharing:OnLogin()
    if not msp then
        RPF.LogError("sharing", "LibMSP did not load")
        return
    end
    -- Remember the profiles that arrive, whichever addon asked for them.
    table.insert(msp.callback.received, OnReceived)
    for _, other in ipairs(OTHER_ADDONS) do
        if IsLoaded(other.folder) then
            Sharing.mode, Sharing.otherAddon = "other", other.name
            return
        end
    end
    if msp_RPAddOn and msp_RPAddOn ~= "RP Forge" then
        Sharing.mode, Sharing.otherAddon = "other", tostring(msp_RPAddOn)
        return
    end
    if not RPF.db.settings.network then return end
    msp_RPAddOn = "RP Forge"
    Sharing.mode = "own"
    HookTooltips()
    Publish()
end

RPF.Listen("PROFILE_CHANGED", PublishSoon)

-- A line for the bug report and /rpf sharing.
function Sharing.Describe()
    if Sharing.mode == "own" then return "RP Forge sends your profile" end
    if Sharing.mode == "other" then return (Sharing.otherAddon or "another addon") .. " sends your profile" end
    return "profile sharing is off (player messages are turned off)"
end

RPF.AddCommand("sharing", "Show which addon shares your profile with other players", function()
    RPF.Print(Sharing.Describe() .. ".")
end)
