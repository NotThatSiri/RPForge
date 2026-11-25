-- RP Forge: the Appearance page (theme, minimap button and portrait shape).
local _, RPF = ...
local UI = RPF.UI

-- A card that previews a theme in its own colours, whatever theme is active.
local function ThemeCard(parent, key)
    local theme = UI.THEMES[key]
    local c = theme.colors
    local card = CreateFrame("Button", nil, parent, UI.BACKDROP_TEMPLATE)
    card:SetSize(220, 150)
    card:SetBackdrop({ bgFile = UI.WHITE, edgeFile = UI.WHITE, edgeSize = 2 })
    card:SetBackdropColor(c.window[1], c.window[2], c.window[3], 1)

    -- Miniature window: a side menu strip and a card in the theme's colours.
    local side = card:CreateTexture(nil, "ARTWORK")
    side:SetTexture(UI.WHITE)
    side:SetVertexColor(c.panel[1], c.panel[2], c.panel[3], 1)
    side:SetPoint("TOPLEFT", 2, -2)
    side:SetPoint("BOTTOMLEFT", 2, 2)
    side:SetWidth(46)
    local mark = card:CreateTexture(nil, "OVERLAY")
    mark:SetTexture(UI.WHITE)
    mark:SetVertexColor(c.accent[1], c.accent[2], c.accent[3], 1)
    mark:SetSize(3, 14)
    mark:SetPoint("TOPLEFT", 2, -18)
    local inner = card:CreateTexture(nil, "ARTWORK")
    inner:SetTexture(UI.WHITE)
    inner:SetVertexColor(c.panel[1], c.panel[2], c.panel[3], 1)
    inner:SetPoint("TOPLEFT", 60, -14)
    inner:SetPoint("TOPRIGHT", -12, -14)
    inner:SetHeight(38)

    local name = card:CreateFontString(nil, "OVERLAY")
    name:SetFont(UI.FONT, 15, "")
    name:SetTextColor(c.accent[1], c.accent[2], c.accent[3], 1)
    name:SetPoint("TOPLEFT", inner, "TOPLEFT", 8, -6)
    name:SetText(theme.name)
    local sample = card:CreateFontString(nil, "OVERLAY")
    sample:SetFont(UI.FONT, 10, "")
    sample:SetTextColor(c.text[1], c.text[2], c.text[3], 1)
    sample:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
    sample:SetText("Aa  Sample text")

    local description = card:CreateFontString(nil, "OVERLAY")
    description:SetFont(UI.FONT, 10, "")
    description:SetTextColor(c.muted[1], c.muted[2], c.muted[3], 1)
    description:SetPoint("TOPLEFT", inner, "BOTTOMLEFT", 0, -10)
    description:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    description:SetJustifyH("LEFT")
    description:SetText(theme.description)

    function card:Refresh()
        local active = UI.themeKey == key
        local edge = active and c.accent or (self:IsMouseOver() and c.muted or c.border)
        self:SetBackdropBorderColor(edge[1], edge[2], edge[3], 1)
    end
    card:SetScript("OnEnter", function(self) self:Refresh() end)
    card:SetScript("OnLeave", function(self) self:Refresh() end)
    card:SetScript("OnClick", function() UI.SetTheme(key) end)
    card:Refresh()
    return card
end

UI.RegisterSettingsPage({
    key = "appearance",
    title = "Appearance",
    order = 20,
    build = function(page)
        local intro = UI.Text(page, "Choose how RP Forge looks. Click a theme to use it straight away.", 12, "text")
        intro:SetPoint("TOPLEFT", 0, -4)

        local x = 0
        for _, key in ipairs(UI.THEME_ORDER) do
            local card = ThemeCard(page, key)
            card:SetPoint("TOPLEFT", x, -34)
            x = x + 236
        end

        local minimapLabel = UI.Text(page, "MINIMAP BUTTON", 10, "muted")
        minimapLabel:SetPoint("TOPLEFT", 0, -212)
        page.minimap = UI.Button(page, "", 170, 26)
        page.minimap:SetPoint("TOPLEFT", minimapLabel, "BOTTOMLEFT", 0, -8)
        page.minimap:SetScript("OnClick", function()
            RPF.SetMinimapButtonShown(not RPF.db.settings.minimap.shown)
            page.minimap.label:SetText(RPF.db.settings.minimap.shown and "Shown (click to hide)" or "Hidden (click to show)")
        end)
        local hint = UI.Text(page, "Drag the anvil around the minimap to move it. /rpf minimap also shows or hides it.", 11, "muted")
        hint:SetPoint("LEFT", page.minimap, "RIGHT", 14, 0)

        local shapeLabel = UI.Text(page, "PORTRAIT SHAPE  (your portrait on Home)", 10, "muted")
        shapeLabel:SetPoint("TOPLEFT", 0, -282)
        page.portraitShape = UI.Segmented(page, { { "circle", "Circle" }, { "square", "Square" } }, 130, function(value)
            RPF.db.settings.portraitShape = value
        end)
        page.portraitShape:SetPoint("TOPLEFT", shapeLabel, "BOTTOMLEFT", 0, -8)
        local shapeHint = UI.Text(page, "Circle: a round portrait in a ring.   Square: a portrait filling a square frame.", 11, "muted")
        shapeHint:SetPoint("LEFT", page.portraitShape, "RIGHT", 14, 0)

    end,
    onShow = function(page)
        page.portraitShape:SetValue(RPF.db.settings.portraitShape == "square" and "square" or "circle")
        page.minimap.label:SetText(RPF.db.settings.minimap.shown and "Shown (click to hide)" or "Hidden (click to show)")
    end,
})
