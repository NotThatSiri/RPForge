-- RP Forge: viewing profiles, and the People page (everyone whose profile RP Forge has heard).
-- Profiles arrive in the shared MSP format (see Modules\Sharing.lua), so they can come from RP Forge,
-- Total RP 3, MyRolePlay, XRP or other roleplay addons.
local _, RPF = ...
local UI = RPF.UI
local Sharing = RPF.Sharing

-- Reading MSP fields ------------------------------------------------------------------------

local STATUS = {
    ["1"] = { "Out of character", "muted" },
    ["2"] = { "In character", "good" },
    ["3"] = { "Looking for RP", "accent" },
    ["4"] = { "Storyteller", "accent" },
}

-- Total RP 3's built-in traits arrive as a number; these are their pairs, in Total RP 3's order.
local BUILTIN_TRAITS = {
    { "Chaotic", "Lawful" }, { "Chaste", "Lustful" }, { "Forgiving", "Vindictive" }, { "Altruistic", "Selfish" },
    { "Truthful", "Deceitful" }, { "Gentle", "Brutal" }, { "Superstitious", "Rational" }, { "Renegade", "Paragon" },
    { "Cautious", "Impulsive" }, { "Ascetic", "Bon vivant" }, { "Valorous", "Spineless" },
}

local function Has(value) return type(value) == "string" and strtrim(value) ~= "" end

-- Remove colour codes, for searching and sorting.
local function Plain(text)
    return (tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

-- First impressions (glances): "|T<icon>:32:32|t\n#Title\n\nText" blocks separated by "\n\n---\n\n".
local function ParseGlances(value)
    local glances = {}
    if not Has(value) then return glances end
    local rest = value .. "\n\n---\n\n"
    for block in rest:gmatch("(.-)\n\n%-%-%-\n\n") do
        local icon = block:match("|T([^:|]+)")
        local title = block:match("#+%s*([^\n]*)")
        local text = block:gsub("|T[^|]*|t", ""):gsub("#+[^\n]*", "")
        text = strtrim(text)
        if Has(title) or Has(text) then
            glances[#glances + 1] = { icon = tonumber(icon) or icon, title = title or "", text = text }
        end
    end
    return glances
end

-- Traits: [trait value="0.65" left-name="Brave" right-name="Cautious"] or [trait value="0.5" id="3"].
local function ParseTraits(value)
    local traits = {}
    if not Has(value) then return traits end
    for block in value:gmatch("%[trait [^%]]-%]") do
        local attributes = {}
        for key, v in block:gmatch('([%w_-]+)="([^"]*)"') do attributes[key] = v end
        local left, right = attributes["left-name"], attributes["right-name"]
        local builtin = BUILTIN_TRAITS[tonumber(attributes.id or "") or 0]
        if builtin then left, right = builtin[1], builtin[2] end
        if Has(left) and Has(right) then
            traits[#traits + 1] = { left = left, right = right, value = tonumber(attributes.value) or 0.5 }
        end
    end
    return traits
end

local function Ago(seconds)
    seconds = time() - (seconds or time())
    if seconds < 60 then return "just now" end
    if seconds < 3600 then return math.floor(seconds / 60) .. " min ago" end
    if seconds < 86400 then return math.floor(seconds / 3600) .. " h ago" end
    return math.floor(seconds / 86400) .. " days ago"
end

-- The profile viewer -------------------------------------------------------------------------------
-- One layout shows every profile: other people's (the "person" page) and your own (the Profile page).

-- Draw a profile (MSP fields) into the layout v; seenText is the small line under the header.
local function RenderInto(v, field, seenText, fallbackName)
    field = field or {}

    v.icon:SetIcon(Has(field.IC) and (tonumber(field.IC) or field.IC) or nil)
    v.name:SetText(Has(field.NA) and ((Has(field.PX) and (field.PX .. " ") or "") .. field.NA) or fallbackName or "")
    v.title:SetText(Has(field.NT) and ("< " .. field.NT .. " >") or "")
    local status = STATUS[field.FC or ""]
    local race = Has(field.RA) and field.RA or ""
    local class = Has(field.RC) and field.RC or ""
    v.sub:SetText(strtrim(race .. " " .. class) .. (status and ("   " .. UI.ColorCode(status[2]) .. status[1] .. "|r") or ""))
    v.seen:SetText(seenText or "")
    v.playTune:SetShown(tonumber(field.MU) ~= nil)
    v.playTune.file = tonumber(field.MU)
    v.playTune.label:SetText(UI.IsTunePlaying(v.playTune.file) and "Stop theme" or "Play theme")

    -- Rebuild the scrolling body.
    if v.body then v.body:Hide(); v.body:SetParent(nil) end
    local body = CreateFrame("Frame", nil, v.scroll)
    local width = v.scroll:GetWidth()
    body:SetWidth(width > 0 and width or 680)
    v.scroll:SetScrollChild(body)
    v.body = body
    local y = 0

    local function Heading(text)
        local h = UI.Text(body, text, 10, "muted")
        h:SetPoint("TOPLEFT", 0, -y)
        y = y + 18
    end
    local function Paragraph(text, colorKey)
        local p = UI.Text(body, Plain(text), 12, colorKey or "text")
        p:SetPoint("TOPLEFT", 0, -y)
        p:SetWidth(body:GetWidth() - 10)
        p:SetSpacing(3)
        y = y + p:GetStringHeight() + 18
    end

    if Has(field.CU) then Heading("CURRENTLY"); Paragraph(field.CU) end
    if Has(field.CO) then Heading("OUT OF CHARACTER"); Paragraph(field.CO, "muted") end

    local details = {}
    for _, spec in ipairs({ { "NI", "Nickname" }, { "PN", "Pronouns" }, { "AG", "Age" }, { "AH", "Height" },
        { "AW", "Build" }, { "AE", "Eyes" }, { "HB", "Birthplace" }, { "HH", "Home" }, { "NH", "House" }, { "MO", "Motto" } }) do
        if Has(field[spec[1]]) then details[#details + 1] = { spec[2], field[spec[1]] } end
    end
    if #details > 0 then
        Heading("DETAILS")
        local half = math.floor(body:GetWidth() / 2)
        for i, detail in ipairs(details) do
            local column, row = (i - 1) % 2, math.floor((i - 1) / 2)
            local label = UI.Text(body, detail[1], 11, "muted")
            label:SetPoint("TOPLEFT", column * half, -(y + row * 22))
            local value = UI.Text(body, Plain(detail[2]), 12, "text")
            value:SetPoint("TOPLEFT", column * half + 90, -(y + row * 22))
            value:SetWidth(half - 100)
            value:SetWordWrap(false)
        end
        y = y + math.ceil(#details / 2) * 22 + 12
    end

    local glances = ParseGlances(field.PE)
    if #glances > 0 then
        Heading("FIRST IMPRESSIONS")
        for _, glance in ipairs(glances) do
            local icon = UI.IconButton(body, 32)
            icon:SetIcon(glance.icon)
            icon:EnableMouse(false)
            icon:SetPoint("TOPLEFT", 0, -y)
            local title = UI.Text(body, Plain(glance.title), 12, "text")
            title:SetPoint("TOPLEFT", 42, -y - 1)
            local text = UI.Text(body, Plain(glance.text), 11, "muted")
            text:SetPoint("TOPLEFT", 42, -y - 18)
            text:SetWidth(body:GetWidth() - 52)
            y = y + math.max(40, 22 + text:GetStringHeight()) + 6
        end
        y = y + 6
    end

    local traits = ParseTraits(field.PS)
    if #traits > 0 then
        Heading("TRAITS")
        -- Dots, like a tabletop sheet: five per side, filled from the middle towards the side the
        -- character leans to. value is how far towards the right-hand trait (0 = fully left, 0.5 = balanced).
        local labelWidth = 150
        for _, trait in ipairs(traits) do
            local value = math.max(0, math.min(1, trait.value)) * 20 -- 0 = fully left, 10 = balanced
            local strength = math.floor(math.abs(value - 10) / 2 + 0.5)
            local left = UI.Text(body, Plain(trait.left), 12, value < 10 and strength > 0 and "accent" or "text", "RIGHT")
            left:SetPoint("TOPLEFT", 0, -y)
            left:SetWidth(labelWidth)
            local dots = UI.TraitDots(body)
            dots:SetPoint("TOPLEFT", labelWidth + 12, -y + 1)
            dots:SetValue(value)
            local right = UI.Text(body, Plain(trait.right), 12, value > 10 and strength > 0 and "accent" or "text")
            right:SetPoint("LEFT", dots, "RIGHT", 12, 0)
            y = y + 24
        end
        y = y + 8
    end

    if Has(field.DE) then Heading("APPEARANCE"); Paragraph(field.DE) end
    if Has(field.HI) then Heading("HISTORY"); Paragraph(field.HI) end
    if y == 0 then
        Paragraph("Waiting for this profile... It appears here as soon as it arrives.", "muted")
    end
    body:SetHeight(y + 20)
end

-- Build the viewer layout on a page. addButtons(v) adds buttons at the top right and returns the
-- leftmost one, so the name and Play theme sit to its left.
local function CreateViewer(frame, addButtons)
    local v = { frame = frame }
    v.icon = UI.IconButton(frame, 52)
    v.icon:SetPoint("TOPLEFT", 28, -24)
    v.icon:EnableMouse(false)
    local leftmost = addButtons(v)
    v.playTune = UI.Button(frame, "Play theme", 110, 26)
    v.playTune:SetPoint("RIGHT", leftmost, "LEFT", -8, 0)
    v.playTune:SetScript("OnClick", function(self)
        if UI.IsTunePlaying(self.file) then UI.StopTune() else UI.PlayTune(self.file) end
        self.label:SetText(UI.IsTunePlaying(self.file) and "Stop theme" or "Play theme")
    end)
    v.name = UI.Text(frame, "", 20, "accent")
    v.name:SetPoint("TOPLEFT", v.icon, "TOPRIGHT", 14, -2)
    v.name:SetPoint("RIGHT", v.playTune, "LEFT", -12, 0)
    v.name:SetWordWrap(false)
    v.title = UI.Text(frame, "", 12, "muted")
    v.title:SetPoint("TOPLEFT", v.name, "BOTTOMLEFT", 0, -4)
    v.sub = UI.Text(frame, "", 12, "text")
    v.sub:SetPoint("TOPLEFT", v.title, "BOTTOMLEFT", 0, -6)
    v.seen = UI.Text(frame, "", 10, "muted")
    v.seen:SetPoint("TOPLEFT", 28, -92)
    UI.Divider(frame, -110, 28)
    v.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    v.scroll:SetPoint("TOPLEFT", 28, -122)
    v.scroll:SetPoint("BOTTOMRIGHT", -44, 16)
    UI.SkinScrollBar(v.scroll)
    return v
end

-- Someone else's profile ------------------------------------------------------------------------------

local viewer -- the "person" page's viewer
local viewing -- whose profile is shown (an MSP name such as "Kiri Stormcrest")

local function RenderProfile()
    if not viewer or not viewing then return end
    if viewing == Sharing.MergedName("player") then
        RenderInto(viewer, Sharing.GetProfile(viewing), "Your own profile, as others see it", viewing)
        return
    end
    local person = RPF.db.people and RPF.db.people[viewing]
    RenderInto(viewer, Sharing.GetProfile(viewing),
        "Character: " .. viewing .. (person and person.seen and ("   Last seen " .. Ago(person.seen)) or ""), viewing)
end

UI.RegisterPage({
    key = "person",
    title = "Profile",
    hidden = true, -- opened from People, /rpf view, or a player's name
    build = function(frame)
        viewer = CreateViewer(frame, function(v)
            v.back = UI.Button(frame, "Back", 80, 26)
            v.back:SetPoint("TOPRIGHT", -28, -24)
            v.back:SetScript("OnClick", function() UI.ShowPage(UI.previousPage ~= "person" and UI.previousPage or "people") end)
            return v.back
        end)
    end,
    onShow = RenderProfile,
})

-- Open someone's profile by their character name. Asks them for it if it isn't here yet.
-- Your own name opens your Profile page instead.
function UI.ViewProfile(name)
    if not name or name == "" then return end
    if name == Sharing.MergedName("player") then
        UI.OpenWindow("myprofile")
        return
    end
    viewing = name
    Sharing.RequestProfile(name)
    UI.OpenWindow("person")
end

RPF.Listen("PERSON_UPDATED", function(name)
    if name == viewing and viewer and viewer.frame:IsVisible() then RenderProfile() end
end)

RPF.AddCommand("view", "View your target's roleplay profile (or your own)", function(rest)
    local name = strtrim(rest or "")
    if name == "" then
        if UnitIsPlayer("target") then
            name = Sharing.MergedName("target")
        else
            name = Sharing.MergedName("player")
        end
    end
    UI.ViewProfile(name)
end)

-- Your own profile ------------------------------------------------------------------------------------

local mine -- the Profile page's viewer

-- Your profile as others see it: the Total RP 3 one with "Keep Total RP 3", otherwise RP Forge's.
local function MyFields()
    local link = RPF.TRP3Link
    if link and link.UsingTRP3() then
        local fields, persona = link.CurrentTRP3Fields(), link.CurrentTRP3Persona()
        if fields then return Sharing.BuildFields({ fields = fields, persona = persona }) end
    end
    return Sharing.BuildFields()
end

local function RenderMine()
    if not mine then return end
    local usingTRP3 = RPF.TRP3Link and RPF.TRP3Link.UsingTRP3()
    local active = RPF.Profiles.GetActive()
    RenderInto(mine, MyFields(), usingTRP3 and "Your Total RP 3 profile, as others see it" or "Your profile, as others see it",
        Sharing.MergedName("player"))
    mine.edit.label:SetText(usingTRP3 and "Edit in Total RP 3" or "Edit profile")
    mine.switcher.label:SetText("Profile: " .. (active and active.name or "?"))
    mine.switcher:SetShown(not usingTRP3)
end

UI.RegisterPage({
    key = "myprofile",
    title = "Profile",
    section = "Character",
    sectionOrder = 2,
    order = 10,
    build = function(frame)
        mine = CreateViewer(frame, function(v)
            v.switcher = UI.Button(frame, "", 190, 26)
            v.switcher:SetPoint("TOPRIGHT", -28, -24)
            v.switcher.label:ClearAllPoints()
            v.switcher.label:SetPoint("LEFT", 10, 0)
            v.switcher.label:SetPoint("RIGHT", -24, 0)
            v.switcher.label:SetJustifyH("LEFT")
            v.switcher.label:SetWordWrap(false)
            local arrow = UI.Text(v.switcher, "v", 11, "muted", "CENTER")
            arrow:SetPoint("RIGHT", -10, 0)
            v.switcher:SetScript("OnClick", function(self) UI.ShowProfileMenu(self) end)
            UI.Tooltip(v.switcher, "Your profiles", "Switch to another profile, or make, copy, rename or delete one.")
            v.edit = UI.Button(frame, "Edit profile", 130, 26, "primary")
            v.edit:SetPoint("RIGHT", v.switcher, "LEFT", -8, 0)
            v.edit:SetScript("OnClick", function()
                if RPF.TRP3Link and RPF.TRP3Link.UsingTRP3() then RPF.TRP3Link.OpenTRP3() else UI.OpenProfile() end
            end)
            return v.edit
        end)
    end,
    onShow = RenderMine,
})

RPF.Listen("PROFILE_CHANGED", function()
    if mine and mine.frame:IsVisible() then RenderMine() end
end)

-- The People page ------------------------------------------------------------------------------------

local ROWS = 11
local ROW_HEIGHT = 40
local people -- the built page
local list = {}
local page = 1

local function Gather(search)
    wipe(list)
    local words = {}
    for word in strlower(search or ""):gmatch("%S+") do words[#words + 1] = word end
    for name, person in pairs(RPF.db.people or {}) do
        local field = person.fields or {}
        local haystack = strlower(name .. " " .. Plain(field.NA) .. " " .. Plain(field.NT) .. " " .. Plain(field.RA) .. " " .. Plain(field.RC))
        local ok = true
        for _, word in ipairs(words) do
            if not haystack:find(word, 1, true) then ok = false break end
        end
        if ok then list[#list + 1] = { name = name, person = person } end
    end
    table.sort(list, function(a, b) return (a.person.seen or 0) > (b.person.seen or 0) end)
end

local function ShowPeoplePage(n)
    local pages = math.max(1, math.ceil(#list / ROWS))
    page = math.max(1, math.min(pages, n))
    for i, row in ipairs(people.rows) do
        local entry = list[(page - 1) * ROWS + i]
        row.entry = entry
        row:SetShown(entry ~= nil)
        if entry then
            local field = entry.person.fields or {}
            row.icon:SetIcon(Has(field.IC) and (tonumber(field.IC) or field.IC) or nil)
            row.name:SetText(Has(field.NA) and field.NA or entry.name)
            local status = STATUS[field.FC or ""]
            local detail = strtrim(Plain(field.RA) .. " " .. Plain(field.RC))
            if Has(field.NT) then detail = (detail ~= "" and (detail .. "  |  ") or "") .. Plain(field.NT) end
            row.detail:SetText(detail)
            row.status:SetText(status and (UI.ColorCode(status[2]) .. status[1] .. "|r") or "")
            row.seen:SetText(Ago(entry.person.seen))
        end
    end
    local total = 0
    for _ in pairs(RPF.db.people or {}) do total = total + 1 end
    people.count:SetText(#list == 0 and (total == 0 and "" or "Nobody matches.") or
        (#list .. (#list == 1 and " person" or " people") .. (pages > 1 and ("   Page " .. page .. " of " .. pages) or "")))
    people.empty:SetShown(total == 0)
    people.prev:SetShown(pages > 1)
    people.next:SetShown(pages > 1)
    people.prev:SetEnabled(page > 1)
    people.next:SetEnabled(page < pages)
end

UI.RegisterPage({
    key = "people",
    title = "People",
    section = "Character",
    sectionOrder = 2,
    order = 20,
    build = function(frame)
        people = frame
        local heading = UI.Text(frame, "People", 20, "accent")
        heading:SetPoint("TOPLEFT", 28, -24)
        local hint = UI.Text(frame, "Everyone whose roleplay profile RP Forge has heard, most recent first. Click someone to open their profile.", 11, "muted")
        hint:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -6)

        people.search = UI.EditBox(frame, 260, 26)
        people.search:SetPoint("TOPRIGHT", -28, -24)
        local searchHint = UI.Text(people.search, "Search names, titles, races...", 11, "muted")
        searchHint:SetPoint("LEFT", 8, 0)
        people.search:SetScript("OnTextChanged", function(self)
            searchHint:SetShown(self:GetText() == "")
            Gather(self:GetText())
            ShowPeoplePage(1)
        end)
        UI.Divider(frame, -78, 28)

        people.rows = {}
        for i = 1, ROWS do
            local row = CreateFrame("Button", nil, frame, UI.BACKDROP_TEMPLATE)
            row:SetHeight(ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 28, -90 - (i - 1) * (ROW_HEIGHT + 4))
            row:SetPoint("RIGHT", frame, "RIGHT", -28, 0)
            UI.Backdrop(row, "panel", "border")
            row.icon = UI.IconButton(row, 32)
            row.icon:SetPoint("LEFT", 4, 0)
            row.icon:EnableMouse(false)
            row.name = UI.Text(row, "", 13, "text")
            row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 10, -1)
            row.name:SetPoint("RIGHT", row, "RIGHT", -230, 0)
            row.name:SetWordWrap(false)
            row.detail = UI.Text(row, "", 10, "muted")
            row.detail:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
            row.detail:SetPoint("RIGHT", row, "RIGHT", -230, 0)
            row.detail:SetWordWrap(false)
            row.status = UI.Text(row, "", 11, "text", "RIGHT")
            row.status:SetPoint("RIGHT", -110, 0)
            row.seen = UI.Text(row, "", 10, "muted", "RIGHT")
            row.seen:SetPoint("RIGHT", -12, 0)
            row:SetScript("OnEnter", function(self) UI.Backdrop(self, "panelAlt", "accent") end)
            row:SetScript("OnLeave", function(self) UI.Backdrop(self, "panel", "border") end)
            row:SetScript("OnClick", function(self) if self.entry then UI.ViewProfile(self.entry.name) end end)
            people.rows[i] = row
        end

        people.empty = UI.Text(frame, "Nobody yet. Profiles appear here as you meet roleplayers (point at them, or open their profile with /rpf view while targeting them).", 12, "muted")
        people.empty:SetPoint("TOPLEFT", 28, -96)
        people.empty:SetPoint("RIGHT", frame, "RIGHT", -28, 0)

        people.prev = UI.Button(frame, "<", 36, 26)
        people.prev:SetPoint("BOTTOMLEFT", 28, 16)
        people.prev:SetScript("OnClick", function() ShowPeoplePage(page - 1) end)
        people.next = UI.Button(frame, ">", 36, 26)
        people.next:SetPoint("LEFT", people.prev, "RIGHT", 6, 0)
        people.next:SetScript("OnClick", function() ShowPeoplePage(page + 1) end)
        people.count = UI.Text(frame, "", 11, "muted")
        people.count:SetPoint("BOTTOMRIGHT", -28, 22)
        frame:EnableMouseWheel(true)
        frame:SetScript("OnMouseWheel", function(_, delta) ShowPeoplePage(page - delta) end)
    end,
    onShow = function()
        Gather(people.search:GetText())
        ShowPeoplePage(page)
    end,
})

RPF.Listen("PERSON_UPDATED", function()
    if people and people:IsVisible() then
        Gather(people.search:GetText())
        ShowPeoplePage(page)
    end
end)
