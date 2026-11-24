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

local viewer -- the built viewer page
local viewing -- whose profile is shown (an MSP name such as "Kiri Stormcrest")

local function RenderProfile()
    if not viewer or not viewing then return end
    local field = Sharing.GetProfile(viewing) or {}
    local person = RPF.db.people and RPF.db.people[viewing]

    viewer.icon:SetIcon(Has(field.IC) and (tonumber(field.IC) or field.IC) or nil)
    viewer.name:SetText(Has(field.NA) and ((Has(field.PX) and (field.PX .. " ") or "") .. field.NA) or viewing)
    viewer.title:SetText(Has(field.NT) and ("< " .. field.NT .. " >") or "")
    local status = STATUS[field.FC or ""]
    local race = Has(field.RA) and field.RA or ""
    local class = Has(field.RC) and field.RC or ""
    viewer.sub:SetText(strtrim(race .. " " .. class) .. (status and ("   " .. UI.ColorCode(status[2]) .. status[1] .. "|r") or ""))
    local seen = (viewing == Sharing.MergedName("player")) and "Your own profile" or
        ("Character: " .. viewing .. (person and person.seen and ("   Last seen " .. Ago(person.seen)) or ""))
    viewer.seen:SetText(seen)
    viewer.playTune:SetShown(tonumber(field.MU) ~= nil)
    viewer.playTune.file = tonumber(field.MU)
    viewer.playTune.label:SetText(UI.IsTunePlaying(viewer.playTune.file) and "Stop theme" or "Play theme")

    -- Rebuild the scrolling body.
    if viewer.body then viewer.body:Hide(); viewer.body:SetParent(nil) end
    local body = CreateFrame("Frame", nil, viewer.scroll)
    local width = viewer.scroll:GetWidth()
    body:SetWidth(width > 0 and width or 680)
    viewer.scroll:SetScrollChild(body)
    viewer.body = body
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
        local barLeft, barWidth = 140, body:GetWidth() - 290
        for _, trait in ipairs(traits) do
            local left = UI.Text(body, Plain(trait.left), 11, "text", "RIGHT")
            left:SetPoint("TOPLEFT", 0, -y)
            left:SetWidth(barLeft - 12)
            local track = body:CreateTexture(nil, "ARTWORK")
            track:SetTexture(UI.WHITE)
            local b = UI.Color("border")
            track:SetVertexColor(b[1], b[2], b[3], 1)
            track:SetSize(barWidth, 4)
            track:SetPoint("TOPLEFT", barLeft, -y - 5)
            local mark = body:CreateTexture(nil, "OVERLAY")
            mark:SetTexture(UI.WHITE)
            local a = UI.Color("accent")
            mark:SetVertexColor(a[1], a[2], a[3], 1)
            mark:SetSize(8, 14)
            -- value is how far towards the right-hand trait (0 = fully left).
            mark:SetPoint("CENTER", track, "LEFT", barWidth * math.max(0, math.min(1, trait.value)), 0)
            local right = UI.Text(body, Plain(trait.right), 11, "text")
            right:SetPoint("TOPLEFT", barLeft + barWidth + 12, -y)
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

UI.RegisterPage({
    key = "person",
    title = "Profile",
    hidden = true, -- opened from People, /rpf view, or a player's name
    build = function(frame)
        viewer = frame
        viewer.icon = UI.IconButton(frame, 52)
        viewer.icon:SetPoint("TOPLEFT", 28, -24)
        viewer.icon:EnableMouse(false)
        viewer.back = UI.Button(frame, "Back", 80, 26)
        viewer.back:SetPoint("TOPRIGHT", -28, -24)
        viewer.back:SetScript("OnClick", function() UI.ShowPage(UI.previousPage ~= "person" and UI.previousPage or "people") end)
        viewer.playTune = UI.Button(frame, "Play theme", 110, 26)
        viewer.playTune:SetPoint("RIGHT", viewer.back, "LEFT", -8, 0)
        viewer.playTune:SetScript("OnClick", function(self)
            if UI.IsTunePlaying(self.file) then UI.StopTune() else UI.PlayTune(self.file) end
            self.label:SetText(UI.IsTunePlaying(self.file) and "Stop theme" or "Play theme")
        end)
        viewer.name = UI.Text(frame, "", 20, "accent")
        viewer.name:SetPoint("TOPLEFT", viewer.icon, "TOPRIGHT", 14, -2)
        viewer.name:SetPoint("RIGHT", viewer.playTune, "LEFT", -12, 0)
        viewer.name:SetWordWrap(false)
        viewer.title = UI.Text(frame, "", 12, "muted")
        viewer.title:SetPoint("TOPLEFT", viewer.name, "BOTTOMLEFT", 0, -4)
        viewer.sub = UI.Text(frame, "", 12, "text")
        viewer.sub:SetPoint("TOPLEFT", viewer.title, "BOTTOMLEFT", 0, -6)
        viewer.seen = UI.Text(frame, "", 10, "muted")
        viewer.seen:SetPoint("TOPLEFT", 28, -92)
        UI.Divider(frame, -110, 28)
        viewer.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        viewer.scroll:SetPoint("TOPLEFT", 28, -122)
        viewer.scroll:SetPoint("BOTTOMRIGHT", -44, 16)
        UI.SkinScrollBar(viewer.scroll)
    end,
    onShow = RenderProfile,
})

-- Open someone's profile by their character name. Asks them for it if it isn't here yet.
function UI.ViewProfile(name)
    if not name or name == "" then return end
    viewing = name
    Sharing.RequestProfile(name)
    UI.OpenWindow("person")
end

RPF.Listen("PERSON_UPDATED", function(name)
    if name == viewing and viewer and viewer:IsVisible() then RenderProfile() end
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
