-- RP Forge: colours and fonts. Every window uses these, so the look is changed in one place.
local _, RPF = ...

local UI = {}
RPF.UI = UI

-- Colours are { r, g, b, a }.
UI.colors = {
    window   = { 0.055, 0.055, 0.065, 0.97 }, -- window background
    panel    = { 0.085, 0.085, 0.095, 1 },    -- cards and side navigation
    panelAlt = { 0.115, 0.115, 0.125, 1 },    -- inputs, rows, hover
    border   = { 0.21, 0.215, 0.24, 1 },
    text     = { 0.93, 0.91, 0.86, 1 },
    muted    = { 0.62, 0.60, 0.57, 1 },
    accent   = { 0.86, 0.66, 0.31, 1 },       -- gold: titles, selected items, primary buttons
    selected = { 0.17, 0.15, 0.11, 1 },       -- background of the selected navigation item
    good     = { 0.42, 0.82, 0.45, 1 },
    warn     = { 1.00, 0.67, 0.33, 1 },
    bad      = { 0.95, 0.38, 0.35, 1 },
}

UI.FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
UI.WHITE = "Interface\\Buttons\\WHITE8X8"
UI.BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

function UI.Color(key)
    return UI.colors[key] or UI.colors.text
end

-- "|cffRRGGBB" for inline colouring of chat or text.
function UI.ColorCode(key)
    local c = UI.Color(key)
    return string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
end
