-- RP Forge: picking the Home banner's background. A scrolling grid of previews, one per race picture.
local _, RPF = ...
local UI = RPF.UI
local Profiles = RPF.Profiles
local Backgrounds = UI.Backgrounds

local COLUMNS = 3
local GAP = 14
local THUMB_HEIGHT = 90
local LABEL_HEIGHT = 26

local page

-- One preview card: a strip of the picture, and the name under it.
local function Card(parent, width, choice)
    local card = CreateFrame("Button", nil, parent, UI.BACKDROP_TEMPLATE)
    card:SetSize(width, THUMB_HEIGHT + LABEL_HEIGHT)
    card.choice = choice

    local thumb = CreateFrame("Frame", nil, card)
    thumb:SetPoint("TOPLEFT", 2, -2)
    thumb:SetPoint("TOPRIGHT", -2, -2)
    thumb:SetHeight(THUMB_HEIGHT - 2)
    if thumb.SetClipsChildren then thumb:SetClipsChildren(true) end
    local art = Backgrounds.CreateArt(thumb)
    thumb:SetScript("OnSizeChanged", function() Backgrounds.Fit(art, thumb) end)
    Backgrounds.Apply(art, choice.file)
    Backgrounds.Fit(art, thumb)

    card.label = UI.Text(card, choice.name, 11, "text", "CENTER")
    card.label:SetPoint("BOTTOMLEFT", 4, 6)
    card.label:SetPoint("BOTTOMRIGHT", -4, 6)
    card.label:SetWordWrap(false)

    function card:Refresh()
        local selected = page.selected == self.choice.key
        local hover = self:IsMouseOver()
        UI.Backdrop(self, selected and "selected" or "panel", selected and "accent" or (hover and "muted" or "border"))
        UI.SetTextColor(self.label, selected and "accent" or "text")
    end
    card:SetScript("OnEnter", function(self) self:Refresh() end)
    card:SetScript("OnLeave", function(self) self:Refresh() end)
    card:SetScript("OnClick", function(self)
        Profiles.SetLook("background", self.choice.key)
    end)
    return card
end

local function RefreshCards()
    page.selected = Profiles.GetLook("background")
    for _, card in ipairs(page.cards) do card:Refresh() end
end

UI.RegisterPage({
    key = "backgrounds",
    title = "Banner background",
    hidden = true, -- opened with "Change background" on Home
    build = function(frame)
        page = frame
        page.cards = {}

        local heading = UI.Text(frame, "Banner background", 20, "accent")
        heading:SetPoint("TOPLEFT", 28, -24)
        local hint = UI.Text(frame, "Pictures from the game itself. Your choice is saved with this profile.", 11, "muted")
        hint:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -6)
        local done = UI.Button(frame, "Done", 90, 26, "primary")
        done:SetPoint("TOPRIGHT", -28, -24)
        done:SetScript("OnClick", function() UI.ShowPage("home") end)
        UI.Divider(frame, -78, 28)

        local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 28, -92)
        scroll:SetPoint("BOTTOMRIGHT", -44, 16)
        local content = CreateFrame("Frame", nil, scroll)
        scroll:SetScrollChild(content)
        UI.SkinScrollBar(scroll)

        local width = (frame:GetWidth() > 0 and frame:GetWidth() or 788) - 28 - 44
        content:SetWidth(width)
        local cardWidth = math.floor((width - GAP * (COLUMNS - 1)) / COLUMNS)

        local own = Backgrounds.PlayerRace()
        local choices = { { key = nil, file = own, name = "Your own race (" .. Backgrounds.RaceName(own) .. ")" } }
        for _, race in ipairs(Backgrounds.Races()) do
            choices[#choices + 1] = { key = race.file, file = race.file, name = race.name }
        end
        for i, choice in ipairs(choices) do
            local card = Card(content, cardWidth, choice)
            local column, row = (i - 1) % COLUMNS, math.floor((i - 1) / COLUMNS)
            card:SetPoint("TOPLEFT", column * (cardWidth + GAP), -row * (THUMB_HEIGHT + LABEL_HEIGHT + GAP))
            page.cards[i] = card
        end
        local rows = math.ceil(#choices / COLUMNS)
        content:SetHeight(rows * (THUMB_HEIGHT + LABEL_HEIGHT + GAP))
    end,
    onShow = RefreshCards,
})

RPF.Listen("PROFILE_CHANGED", function()
    if page and page:IsVisible() then RefreshCards() end
end)
