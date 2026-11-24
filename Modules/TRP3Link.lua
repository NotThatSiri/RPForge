-- RP Forge: working alongside Total RP 3.
--
-- Only one addon can share your profile. When Total RP 3 is running, RP Forge asks once:
--   * Keep Total RP 3 for my profile  -> Total RP 3 edits and shares it; RP Forge shows it on Home.
--   * Move my profiles to RP Forge     -> copy every Total RP 3 profile into RP Forge, turn Total RP 3
--                                        (and its add-ons) off, reload. Its saved data isn't touched.
--   * Decide later                     -> ask again at the next login.
-- The answer is saved (settings.trp3Choice = "trp3" or "rpforge") and can be changed in Settings.
local _, RPF = ...
local UI = RPF.UI
local Profiles = RPF.Profiles

local Link = RPF.NewModule("TRP3Link")
RPF.TRP3Link = Link

local TRP3_FOLDER = "totalRP3"
local IsLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
local askedThisSession = false
local window

function Link.TRP3Running()
    return IsLoaded(TRP3_FOLDER) and TRP3_API ~= nil and TRP3_API.profile ~= nil
end

function Link.Choice()
    return RPF.db.settings.trp3Choice
end

-- True when Home should show the Total RP 3 profile instead of an RP Forge one.
function Link.UsingTRP3()
    return Link.TRP3Running() and Link.Choice() == "trp3"
end

-- Turning a Total RP 3 profile into RP Forge fields -----------------------------------------

-- Total RP 3 text can hold formatting tags like {h1} or {col:ff0000}; keep only the words.
local function Plain(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("{link%*[^*]*%*([^}]*)}", "%1"):gsub("%b{}", "")
    text = strtrim(text)
    return text ~= "" and text or nil
end

function Link.ConvertProfile(trp)
    local player = type(trp) == "table" and trp.player or {}
    local ch = player.characteristics or {}
    local c = player.character or {}
    local about = player.about or {}
    local f = {
        firstName = ch.FN, lastName = ch.LN, title = ch.TI, fullTitle = ch.FT,
        race = ch.RA, class = ch.CL, age = ch.AG, eyes = ch.EC, height = ch.HE,
        home = ch.RE, birthplace = ch.BP, currently = c.CU, oocNote = c.CO,
    }
    local kinds = TRP3_API and TRP3_API.MiscInfoType
    if kinds and TRP3_API.GetMiscInfoTypeFromData then
        for _, misc in pairs(ch.MI or {}) do
            local kind = TRP3_API.GetMiscInfoTypeFromData(misc)
            if kind ~= nil then
                if kind == kinds.Motto then f.motto = misc.VA
                elseif kind == kinds.House then f.house = misc.VA
                elseif kind == kinds.Nickname then f.nickname = misc.VA
                elseif kind == kinds.Pronouns then f.pronouns = misc.VA end
            end
        end
    end
    local enums = AddOn_TotalRP3 and AddOn_TotalRP3.Enums
    local inCharacter = enums and enums.ROLEPLAY_STATUS and enums.ROLEPLAY_STATUS.IN_CHARACTER or 1
    local walkUp = enums and enums.WALKUP and enums.WALKUP.YES
    if c.RP == inCharacter then
        f.status = (walkUp ~= nil and c.WU == walkUp) and "lfrp" or "ic"
    else
        f.status = "ooc"
    end
    if about.TE == 1 then
        f.appearance = Plain(about.T1 and about.T1.TX)
    elseif about.TE == 3 then
        f.appearance = Plain(about.T3 and about.T3.PH and about.T3.PH.TX)
        f.history = Plain(about.T3 and about.T3.HI and about.T3.HI.TX)
    elseif about.TE == 2 then
        local parts = {}
        for _, block in ipairs(about.T2 or {}) do
            local text = Plain(block.TX)
            if text then parts[#parts + 1] = text end
        end
        f.appearance = #parts > 0 and table.concat(parts, "\n\n") or nil
    end
    -- Keep only real text, within RP Forge's limits.
    local clean = {}
    for key, value in pairs(f) do
        if type(value) == "string" and strtrim(value) ~= "" then
            local limit = Profiles.FIELDS[key]
            if limit and #value > limit then value = value:sub(1, limit) end
            clean[key] = value
        end
    end
    return clean
end

-- The Total RP 3 profile you're using now, as RP Forge fields (for Home in "keep" mode).
function Link.CurrentTRP3Fields()
    if not Link.TRP3Running() or not TRP3_API.profile.getPlayerCurrentProfile then return nil end
    local ok, profile = pcall(TRP3_API.profile.getPlayerCurrentProfile)
    if not ok or type(profile) ~= "table" then return nil end
    return Link.ConvertProfile(profile)
end

function Link.OpenTRP3()
    if TRP3_API and TRP3_API.navigation and TRP3_API.navigation.openMainFrame then
        RPF.SafeCall("open Total RP 3", TRP3_API.navigation.openMainFrame)
    end
end

-- Moving to RP Forge ------------------------------------------------------------------------

-- Copy every Total RP 3 profile. A profile copied before is updated rather than copied twice.
-- Returns how many were copied.
function Link.ImportAll()
    local all = (TRP3_API.profile.getProfiles and TRP3_API.profile.getProfiles()) or TRP3_Profiles or {}
    local currentID = TRP3_API.profile.getPlayerCurrentProfileID and TRP3_API.profile.getPlayerCurrentProfileID()
    local byOrigin = {}
    for _, profile in ipairs(Profiles.List()) do
        if profile.fromTRP3 then byOrigin[profile.fromTRP3] = profile end
    end
    local count, active = 0, nil
    for id, trp in pairs(all) do
        if type(trp) == "table" then
            local profile = byOrigin[id] or Profiles.Create(trp.profileName or "Total RP 3 profile")
            profile.fields = Link.ConvertProfile(trp)
            profile.fromTRP3 = id
            profile.updatedAt = time()
            count = count + 1
            if id == currentID then active = profile.id end
        end
    end
    if active then RPF.char.activeProfile = active end
    return count
end

-- Turn off Total RP 3 and every addon that needs it (Extended and friends), for all characters.
local function TurnOffTRP3()
    local numAddOns = (C_AddOns and C_AddOns.GetNumAddOns or GetNumAddOns)()
    local getInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
    local getDeps = (C_AddOns and C_AddOns.GetAddOnDependencies) or GetAddOnDependencies
    local disable = (C_AddOns and C_AddOns.DisableAddOn) or DisableAddOn
    for i = 1, numAddOns do
        local name = getInfo(i)
        local needsTRP3 = name == TRP3_FOLDER
        for _, dependency in ipairs({ getDeps(i) }) do
            if dependency == TRP3_FOLDER then needsTRP3 = true end
        end
        if needsTRP3 then disable(name) end
    end
end

StaticPopupDialogs.RPFORGE_MOVE_TO_RPFORGE = {
    text = "%s\n\nThe game reloads. Total RP 3's saved data is kept, so you can turn it back on any time.",
    button1 = "Move and reload",
    button2 = CANCEL or "Cancel",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnAccept = function(_, data)
        if data.copy then Link.ImportAll() end
        RPF.db.settings.trp3Choice = "rpforge"
        TurnOffTRP3()
        ReloadUI()
    end,
}

local function MoveToRPForge(copy)
    local all = (TRP3_API.profile.getProfiles and TRP3_API.profile.getProfiles()) or {}
    local count = 0
    for _ in pairs(all) do count = count + 1 end
    local question
    if copy then
        question = "Copy " .. (count == 1 and "your Total RP 3 profile" or ("your " .. count .. " Total RP 3 profiles"))
            .. " into RP Forge and turn Total RP 3 off?"
    else
        question = "Turn Total RP 3 off again? Your RP Forge profiles stay as they are."
    end
    StaticPopup_Show("RPFORGE_MOVE_TO_RPFORGE", question, nil, { copy = copy })
end

local function KeepTRP3()
    RPF.db.settings.trp3Choice = "trp3"
    RPF.Send("PROFILE_CHANGED", RPF.char.activeProfile) -- Home switches to the Total RP 3 profile
end

-- The question window ----------------------------------------------------------------------------

local function Choice(parent, title, body, onClick, primary)
    local card = CreateFrame("Button", nil, parent, UI.BACKDROP_TEMPLATE)
    card:SetHeight(84)
    card.title = UI.Text(card, title, 14, primary and "accent" or "text")
    card.title:SetPoint("TOPLEFT", 14, -12)
    card.body = UI.Text(card, body, 11, "muted")
    card.body:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -6)
    card.body:SetPoint("RIGHT", card, "RIGHT", -14, 0)
    card.body:SetSpacing(2)
    function card:Refresh()
        UI.Backdrop(self, self:IsMouseOver() and "panelAlt" or "panel", self:IsMouseOver() and "accent" or "border")
    end
    card:SetScript("OnEnter", function(self) self:Refresh() end)
    card:SetScript("OnLeave", function(self) self:Refresh() end)
    card:SetScript("OnClick", function()
        window:Hide()
        onClick()
    end)
    card:Refresh()
    return card
end

local function Build(turnedOnAgain)
    if window then window:Hide() end
    window = CreateFrame("Frame", "RPForgeTRP3Choice", UIParent, UI.BACKDROP_TEMPLATE)
    window:SetSize(560, 360)
    window:SetPoint("CENTER", 0, 60)
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    UI.Backdrop(window, "window", "border")

    local title = UI.Text(window, turnedOnAgain and "Total RP 3 is turned on again" or "Total RP 3 is installed", 18, "accent")
    title:SetPoint("TOPLEFT", 22, -20)
    local intro = UI.Text(window, turnedOnAgain
        and "You moved your profiles to RP Forge, but Total RP 3 is running again, so it is sharing your profile instead of RP Forge. Only one of them can do that."
        or "Total RP 3 and RP Forge can both share your roleplay profile with other players, but only one of them at a time. What would you like to do?", 12, "text")
    intro:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    intro:SetPoint("RIGHT", window, "RIGHT", -22, 0)
    intro:SetSpacing(3)

    local keep = Choice(window, "Keep Total RP 3 for my profile",
        "Total RP 3 keeps editing and sharing your profile; nothing changes in it. RP Forge shows that profile on its Home page and adds its own parts.",
        KeepTRP3, not turnedOnAgain)
    keep:SetPoint("TOPLEFT", 22, -106)
    keep:SetPoint("RIGHT", window, "RIGHT", -22, 0)

    local move = Choice(window,
        turnedOnAgain and "Turn Total RP 3 off again" or "Move my profiles to RP Forge",
        turnedOnAgain and "RP Forge shares your profile again. The game reloads; Total RP 3's saved data is kept."
            or "Your Total RP 3 profiles are copied into RP Forge, then Total RP 3 is turned off and the game reloads. Its saved data is kept, so you can turn it back on any time.",
        function() MoveToRPForge(not turnedOnAgain) end, turnedOnAgain)
    move:SetPoint("TOPLEFT", keep, "BOTTOMLEFT", 0, -10)
    move:SetPoint("RIGHT", window, "RIGHT", -22, 0)

    local later = UI.Button(window, "Decide later", 120, 26)
    later:SetPoint("BOTTOMRIGHT", -22, 18)
    later:SetScript("OnClick", function() window:Hide() end)
    local hint = UI.Text(window, "You can change this later in Settings > General.", 10, "muted")
    hint:SetPoint("BOTTOMLEFT", 22, 25)
    window:Show()
end

-- Ask the question now (also used by "Choose again" in Settings).
function Link.Ask()
    if not Link.TRP3Running() then
        RPF.Print("Total RP 3 isn't running, so RP Forge shares your profile.")
        return
    end
    askedThisSession = true
    Build(Link.Choice() == "rpforge")
end

function Link:OnLogin()
    if not Link.TRP3Running() or Link.Choice() == "trp3" then return end
    -- Wait for the loading screen and any fight to be over before asking.
    local function TryAsk()
        if askedThisSession then return end
        if InCombatLockdown() then
            C_Timer.After(10, TryAsk)
            return
        end
        Link.Ask()
    end
    C_Timer.After(6, TryAsk)
end

function Link.Describe()
    if not Link.TRP3Running() then return "Total RP 3 isn't running." end
    local choice = Link.Choice()
    if choice == "trp3" then return "Total RP 3 edits and shares your profile. RP Forge shows it on Home." end
    if choice == "rpforge" then return "You moved to RP Forge, but Total RP 3 is running again." end
    return "Not chosen yet: Total RP 3 is sharing your profile for now."
end
