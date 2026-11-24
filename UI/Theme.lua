-- RP Forge: themes, colours and fonts. Every window uses these, so the look is changed in one place.
local _, RPF = ...

local UI = {}
RPF.UI = UI

-- Each theme sets the same colour keys ({ r, g, b, a }) and a text shadow.
--   window    window background          panel     cards and the side menu
--   panelAlt  inputs, rows, hover        border    lines and edges
--   text      main text                  muted     labels and hints
--   accent    titles, selection, primary buttons
--   selected  background of the selected menu item
--   good / warn / bad   status colours
UI.THEMES = {
    parchment = {
        name = "Parchment",
        description = "Warm paper, dark ink and wax-red accents, like a journal.",
        shadow = { 1, 1, 1, 0 },
        colors = {
            window   = { 0.89, 0.83, 0.70, 1 },
            panel    = { 0.94, 0.89, 0.78, 1 },
            panelAlt = { 0.85, 0.78, 0.63, 1 },
            border   = { 0.58, 0.46, 0.31, 1 },
            text     = { 0.21, 0.15, 0.10, 1 },
            muted    = { 0.47, 0.38, 0.27, 1 },
            accent   = { 0.60, 0.15, 0.11, 1 },
            selected = { 0.82, 0.72, 0.55, 1 },
            good     = { 0.18, 0.45, 0.20, 1 },
            warn     = { 0.66, 0.38, 0.05, 1 },
            bad      = { 0.68, 0.14, 0.11, 1 },
        },
    },
    forge = {
        name = "Forge",
        description = "Charcoal and dark iron with an ember glow, like a smithy.",
        shadow = { 0, 0, 0, 0.8 },
        colors = {
            window   = { 0.085, 0.075, 0.07, 1 },
            panel    = { 0.125, 0.105, 0.095, 1 },
            panelAlt = { 0.175, 0.145, 0.125, 1 },
            border   = { 0.33, 0.24, 0.18, 1 },
            text     = { 0.94, 0.90, 0.84, 1 },
            muted    = { 0.67, 0.58, 0.50, 1 },
            accent   = { 0.96, 0.53, 0.21, 1 },
            selected = { 0.25, 0.14, 0.08, 1 },
            good     = { 0.48, 0.82, 0.42, 1 },
            warn     = { 1.00, 0.72, 0.30, 1 },
            bad      = { 0.96, 0.38, 0.32, 1 },
        },
    },
    arcane = {
        name = "Arcane",
        description = "Deep slate blue with a soft teal light, like a mage's study.",
        shadow = { 0, 0, 0, 0.8 },
        colors = {
            window   = { 0.065, 0.085, 0.12, 1 },
            panel    = { 0.095, 0.125, 0.17, 1 },
            panelAlt = { 0.135, 0.17, 0.225, 1 },
            border   = { 0.22, 0.30, 0.40, 1 },
            text     = { 0.88, 0.92, 0.97, 1 },
            muted    = { 0.58, 0.66, 0.75, 1 },
            accent   = { 0.38, 0.82, 0.85, 1 },
            selected = { 0.12, 0.22, 0.28, 1 },
            good     = { 0.45, 0.85, 0.55, 1 },
            warn     = { 1.00, 0.75, 0.40, 1 },
            bad      = { 0.98, 0.45, 0.45, 1 },
        },
    },
}
UI.THEME_ORDER = { "parchment", "forge", "arcane" }
UI.DEFAULT_THEME = "parchment"

-- The active colours. Filled from the chosen theme; widgets read from here.
UI.colors = {}
UI.shadow = { 0, 0, 0, 0.8 }
UI.themeKey = UI.DEFAULT_THEME

UI.FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
UI.WHITE = "Interface\\Buttons\\WHITE8X8"
UI.BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

local function ApplyTheme(key)
    local theme = UI.THEMES[key] or UI.THEMES[UI.DEFAULT_THEME]
    UI.themeKey = UI.THEMES[key] and key or UI.DEFAULT_THEME
    wipe(UI.colors)
    for name, color in pairs(theme.colors) do UI.colors[name] = color end
    UI.shadow = theme.shadow
end
ApplyTheme(UI.DEFAULT_THEME)

-- Change the theme, save it, and let open windows redraw.
function UI.SetTheme(key)
    if not UI.THEMES[key] then return false end
    RPF.db.settings.theme = key
    ApplyTheme(key)
    RPF.Send("THEME_CHANGED", key)
    return true
end

RPF.Listen("DATA_READY", function()
    ApplyTheme(RPF.db.settings.theme)
end)

function UI.Color(key)
    return UI.colors[key] or UI.colors.text
end

-- "|cffRRGGBB" for inline colouring of chat or text.
function UI.ColorCode(key)
    local c = UI.Color(key)
    return string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
end

RPF.AddCommand("theme", "Change the look: /rpf theme parchment, forge or arcane", function(rest)
    local key = (rest or ""):lower()
    if key == "" then
        RPF.Print("theme is " .. UI.THEMES[UI.themeKey].name .. ". Choose parchment, forge or arcane.")
        return
    end
    if UI.SetTheme(key) then
        RPF.Print("theme set to " .. UI.THEMES[key].name .. ".")
    else
        RPF.Print("unknown theme '" .. key .. "'. Choose parchment, forge or arcane.")
    end
end)
