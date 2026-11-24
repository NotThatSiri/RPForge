-- RP Forge: small building blocks for windows. Pages build their content from these.
local _, RPF = ...
local UI = RPF.UI

-- A flat background with a 1px border.
function UI.Backdrop(frame, bgKey, borderKey)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    frame:SetBackdrop({ bgFile = UI.WHITE, edgeFile = UI.WHITE, edgeSize = 1 })
    local bg, border = UI.Color(bgKey or "panel"), UI.Color(borderKey or "border")
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

function UI.Panel(parent, bgKey, borderKey)
    local panel = CreateFrame("Frame", nil, parent, UI.BACKDROP_TEMPLATE)
    UI.Backdrop(panel, bgKey, borderKey)
    return panel
end

-- Text with a soft shadow and no outline. size in points; colorKey from UI.colors.
function UI.Text(parent, text, size, colorKey, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(UI.FONT, size or 12, "")
    local s = UI.shadow
    fs:SetShadowColor(s[1], s[2], s[3], s[4])
    fs:SetShadowOffset(1, -1)
    local c = UI.Color(colorKey or "text")
    fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetText(text or "")
    return fs
end

function UI.SetTextColor(fs, colorKey)
    local c = UI.Color(colorKey)
    fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
end

-- A thin horizontal line across the parent at y (from the top).
function UI.Divider(parent, y, inset)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture(UI.WHITE)
    local c = UI.Color("border")
    line:SetVertexColor(c[1], c[2], c[3], 1)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", inset or 0, y)
    line:SetPoint("TOPRIGHT", -(inset or 0), y)
    return line
end

-- Buttons. style: nil (normal) or "primary" (gold edge and text).
function UI.Button(parent, text, width, height, style)
    local b = CreateFrame("Button", nil, parent, UI.BACKDROP_TEMPLATE)
    b:SetSize(width or 110, height or 26)
    b.style = style
    b.label = UI.Text(b, text, 11, style == "primary" and "accent" or "text", "CENTER")
    b.label:SetPoint("CENTER", 0, 0)

    function b:Refresh()
        local hover = self:IsMouseOver() and self:IsEnabled()
        UI.Backdrop(self, hover and "panelAlt" or "panel", (self.style == "primary" or hover) and "accent" or "border")
        if self:IsEnabled() then
            UI.SetTextColor(self.label, self.style == "primary" and "accent" or "text")
        else
            UI.SetTextColor(self.label, "muted")
        end
    end

    b:SetScript("OnEnter", function(self) self:Refresh() end)
    b:SetScript("OnLeave", function(self) self:Refresh() end)
    b:SetScript("OnEnable", function(self) self:Refresh() end)
    b:SetScript("OnDisable", function(self) self:Refresh() end)
    b:Refresh()
    return b
end

-- A one-line text box. onCommit(text) runs on Enter or when it loses focus.
function UI.EditBox(parent, width, height, onCommit)
    local e = CreateFrame("EditBox", nil, parent, UI.BACKDROP_TEMPLATE)
    e:SetSize(width or 200, height or 24)
    e:SetAutoFocus(false)
    e:SetFont(UI.FONT, 11, "")
    e:SetTextInsets(7, 7, 0, 0)
    local c = UI.Color("text")
    e:SetTextColor(c[1], c[2], c[3], 1)
    UI.Backdrop(e, "panelAlt", "border")
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEditFocusGained", function(self) UI.Backdrop(self, "panelAlt", "accent") end)
    e:SetScript("OnEditFocusLost", function(self)
        UI.Backdrop(self, "panelAlt", "border")
        if onCommit then RPF.SafeCall("edit box", onCommit, self:GetText()) end
    end)
    return e
end

-- An on/off setting: a box that is filled when on, a label, and a hint underneath.
-- getter() returns the current value; setter(value) saves the new one.
function UI.Toggle(parent, label, hint, getter, setter)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(hint and 40 or 22)
    row.box = CreateFrame("Frame", nil, row, UI.BACKDROP_TEMPLATE)
    row.box:SetSize(18, 18)
    row.box:SetPoint("TOPLEFT", 0, -2)
    row.fill = row.box:CreateTexture(nil, "ARTWORK")
    row.fill:SetTexture(UI.WHITE)
    row.fill:SetPoint("TOPLEFT", 4, -4)
    row.fill:SetPoint("BOTTOMRIGHT", -4, 4)
    local a = UI.Color("accent")
    row.fill:SetVertexColor(a[1], a[2], a[3], 1)
    row.label = UI.Text(row, label, 12, "text")
    row.label:SetPoint("LEFT", row.box, "RIGHT", 10, 0)
    if hint then
        row.hint = UI.Text(row, hint, 10, "muted")
        row.hint:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -4)
        row.hint:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    end

    function row:Refresh()
        local on = getter() and true or false
        row.fill:SetShown(on)
        UI.Backdrop(row.box, "panelAlt", (on or self:IsMouseOver()) and "accent" or "border")
    end
    row:SetScript("OnEnter", function(self) self:Refresh() end)
    row:SetScript("OnLeave", function(self) self:Refresh() end)
    row:SetScript("OnClick", function(self)
        RPF.SafeCall("toggle " .. label, setter, not getter())
        self:Refresh()
    end)
    row:Refresh()
    return row
end

-- A label with a one-line text box under it. Saves as you type: onChange(text) runs on every edit.
-- field:SetValue(text) fills it without calling onChange.
function UI.Field(parent, label, width, maxLetters, onChange)
    local field = CreateFrame("Frame", nil, parent)
    field:SetSize(width or 220, 44)
    field.label = UI.Text(field, label, 10, "muted")
    field.label:SetPoint("TOPLEFT", 0, 0)
    field.box = UI.EditBox(field, width or 220, 24)
    field.box:SetPoint("TOPLEFT", field.label, "BOTTOMLEFT", 0, -4)
    field.box:SetPoint("RIGHT", field, "RIGHT", 0, 0)
    if maxLetters then field.box:SetMaxLetters(maxLetters) end
    field.box:SetScript("OnTextChanged", function(self, userInput)
        if userInput and onChange then RPF.SafeCall("field " .. label, onChange, self:GetText()) end
    end)
    function field:SetValue(text)
        self.box:SetText(text or "")
        self.box:SetCursorPosition(0)
    end
    return field
end

-- A label with a scrolling, multi-line text box under it. Saves as you type, like UI.Field.
function UI.TextArea(parent, label, height, maxLetters, onChange)
    local area = CreateFrame("Frame", nil, parent)
    area:SetHeight((height or 120) + 18)
    area.label = UI.Text(area, label, 10, "muted")
    area.label:SetPoint("TOPLEFT", 0, 0)
    local box = UI.Panel(area, "panelAlt", "border")
    box:SetPoint("TOPLEFT", area.label, "BOTTOMLEFT", 0, -4)
    box:SetPoint("BOTTOMRIGHT", 0, 0)
    local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 7, -6)
    scroll:SetPoint("BOTTOMRIGHT", -26, 6)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFont(UI.FONT, 11, "")
    local c = UI.Color("text")
    edit:SetTextColor(c[1], c[2], c[3], 1)
    if maxLetters then edit:SetMaxLetters(maxLetters) end
    edit:SetWidth(200)
    scroll:SetScrollChild(edit)
    UI.SkinScrollBar(scroll)
    scroll:SetScript("OnSizeChanged", function(_, w) edit:SetWidth(math.max(50, w)) end)
    -- Clicking anywhere in the box starts typing.
    box:EnableMouse(true)
    box:SetScript("OnMouseDown", function() edit:SetFocus() end)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEditFocusGained", function() UI.Backdrop(box, "panelAlt", "accent") end)
    edit:SetScript("OnEditFocusLost", function() UI.Backdrop(box, "panelAlt", "border") end)
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput and onChange then RPF.SafeCall("text " .. label, onChange, self:GetText()) end
    end)
    -- Keep the typing position in view.
    edit:SetScript("OnCursorChanged", function(_, _, y, _, cursorHeight)
        local top = scroll:GetVerticalScroll()
        local bottom = top + scroll:GetHeight()
        y = -y
        if y < top then
            scroll:SetVerticalScroll(y)
        elseif y + cursorHeight > bottom then
            scroll:SetVerticalScroll(y + cursorHeight - scroll:GetHeight())
        end
    end)
    area.edit = edit
    function area:SetValue(text)
        edit:SetText(text or "")
        edit:SetCursorPosition(0)
        scroll:SetVerticalScroll(0)
    end
    return area
end

-- A row of buttons where exactly one is chosen. choices = { { value, label }, ... }.
-- onPick(value) runs when the player picks one; row:SetValue(value) shows a choice without calling it.
function UI.Segmented(parent, choices, width, onPick)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize((width or 110) * #choices + 6 * (#choices - 1), 26)
    row.buttons = {}
    for i, choice in ipairs(choices) do
        local b = UI.Button(row, choice[2], width or 110, 26)
        b:SetPoint("LEFT", (i - 1) * ((width or 110) + 6), 0)
        b.value = choice[1]
        b:SetScript("OnClick", function(self)
            row:SetValue(self.value)
            if onPick then RPF.SafeCall("choice", onPick, self.value) end
        end)
        row.buttons[i] = b
    end
    function row:SetValue(value)
        for _, b in ipairs(self.buttons) do
            b.style = (b.value == value) and "primary" or nil
            b:Refresh()
        end
    end
    return row
end

-- Restyle a UIPanelScrollFrameTemplate scrollbar: a thin bar in the theme's colours, no arrow buttons,
-- and hidden while there is nothing to scroll.
function UI.SkinScrollBar(scroll)
    local bar = scroll.ScrollBar or (scroll:GetName() and _G[scroll:GetName() .. "ScrollBar"])
    if not bar then return end
    for _, child in ipairs({ bar:GetChildren() }) do
        if child:IsObjectType("Button") then
            child:Hide()
            child:SetAlpha(0)
            child:EnableMouse(false)
        end
    end
    for _, region in ipairs({ bar:GetRegions() }) do
        if region:IsObjectType("Texture") and region ~= bar:GetThumbTexture() then region:SetAlpha(0) end
    end
    bar:ClearAllPoints()
    bar:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 18, 0)
    bar:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 18, 0)
    bar:SetWidth(6)

    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetTexture(UI.WHITE)
    track:SetAllPoints()
    local b = UI.Color("border")
    track:SetVertexColor(b[1], b[2], b[3], 0.35)

    local thumb = bar:GetThumbTexture()
    if thumb then
        thumb:SetTexture(UI.WHITE)
        thumb:SetSize(6, 36)
        local m = UI.Color("muted")
        thumb:SetVertexColor(m[1], m[2], m[3], 0.9)
    end

    local function UpdateShown()
        local range = scroll:GetVerticalScrollRange() or 0
        bar:SetShown(range > 1)
    end
    scroll:HookScript("OnScrollRangeChanged", UpdateShown)
    UpdateShown()
end

-- A small pop-up menu under `owner`. items = { { text, onClick, disabled = bool, checked = bool }, "-" (a line), ... }
-- Closes when an item is picked, when clicking anywhere else, or with Escape.
local menu, catcher
function UI.ShowMenu(owner, items)
    if not menu then
        catcher = CreateFrame("Button", nil, UIParent)
        catcher:SetAllPoints(UIParent)
        catcher:SetFrameStrata("FULLSCREEN_DIALOG")
        catcher:RegisterForClicks("AnyUp")
        catcher:SetScript("OnClick", function() UI.HideMenu() end)
        catcher:Hide()
        menu = CreateFrame("Frame", "RPForgeMenu", UIParent, UI.BACKDROP_TEMPLATE)
        menu:SetFrameStrata("FULLSCREEN_DIALOG")
        menu:SetFrameLevel(catcher:GetFrameLevel() + 10)
        menu:EnableMouse(true)
        menu.rows = {}
        menu:Hide()
        tinsert(UISpecialFrames, "RPForgeMenu")
        menu:SetScript("OnHide", function() catcher:Hide() end)
    end
    UI.Backdrop(menu, "panel", "border")
    for _, row in ipairs(menu.rows) do row:Hide() end

    local y, width = -4, math.max(owner:GetWidth(), 180)
    for i, item in ipairs(items) do
        local row = menu.rows[i]
        if not row then
            row = CreateFrame("Button", nil, menu, UI.BACKDROP_TEMPLATE)
            row.label = UI.Text(row, "", 12, "text")
            row.label:SetPoint("LEFT", 12, 0)
            row.line = row:CreateTexture(nil, "ARTWORK")
            row.line:SetTexture(UI.WHITE)
            row.line:SetHeight(1)
            row.line:SetPoint("LEFT", 8, 0)
            row.line:SetPoint("RIGHT", -8, 0)
            row:SetScript("OnEnter", function(self) if self.item and not self.item.disabled then UI.Backdrop(self, "panelAlt", "panelAlt") end end)
            row:SetScript("OnLeave", function(self) self:SetBackdrop(nil) end)
            row:SetScript("OnClick", function(self)
                local picked = self.item
                if not picked or picked.disabled then return end
                UI.HideMenu()
                if picked[2] then RPF.SafeCall("menu " .. tostring(picked[1]), picked[2]) end
            end)
            menu.rows[i] = row
        end
        row:SetBackdrop(nil)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 1, y)
        row:SetPoint("TOPRIGHT", -1, y)
        if item == "-" then
            row.item = nil
            row:SetHeight(9)
            row.label:SetText("")
            local c = UI.Color("border")
            row.line:SetVertexColor(c[1], c[2], c[3], 1)
            row.line:Show()
            y = y - 9
        else
            row.item = item
            row:SetHeight(24)
            row.line:Hide()
            row.label:SetText((item.checked and "> " or "") .. item[1])
            UI.SetTextColor(row.label, item.disabled and "muted" or (item.checked and "accent" or "text"))
            y = y - 24
        end
        row:Show()
    end
    menu:SetSize(width, -y + 4)
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
    catcher:Show()
    menu:Show()
    menu:Raise()
end

function UI.HideMenu()
    if menu then menu:Hide() end
end

-- Icons are stored as the game's icon file ID (a number) or an icon name ("INV_Misc_Book_09").
-- These turn either form into something a texture or a text icon can show.
UI.DEFAULT_ICON = 134400 -- the question mark

-- Other addons can send icons as LibRPMedia "icon IDs": numbers with extra bits on top that say whether
-- it's a file or an atlas, too large to give the game directly. LibRPMedia decodes those.
local function Media()
    return LibStub and LibStub:GetLibrary("LibRPMedia-1.2", true)
end

-- Turn any icon value into (source, isAtlas): a file ID or path for SetTexture, or an atlas name.
function UI.ResolveIcon(icon)
    if type(icon) == "string" and tonumber(icon) then icon = tonumber(icon) end
    if icon == nil or icon == "" then return UI.DEFAULT_ICON, false end
    local media = Media()
    if media and media.ResolveIcon then
        local ok, source, kind = pcall(media.ResolveIcon, media, icon)
        if ok and source and not (source == UI.DEFAULT_ICON and type(icon) == "string" and icon:find("[\\/]")) then
            return source, kind == media.IconType.Atlas
        end
    end
    if type(icon) == "number" then
        -- Without LibRPMedia: keep only the file part of the number, so it always fits.
        return (icon >= 0 and icon <= 0x03ffffff) and icon or UI.DEFAULT_ICON, false
    end
    if icon:find("[\\/]") then return icon, false end
    return "Interface\\Icons\\" .. icon, false
end

-- A file icon (for SetTexture). Atlas icons fall back to the question mark here; use UI.SetIcon instead.
function UI.IconTexture(icon)
    local source, isAtlas = UI.ResolveIcon(icon)
    return isAtlas and UI.DEFAULT_ICON or source
end

-- Show an icon on a texture, file or atlas.
function UI.SetIcon(texture, icon)
    local source, isAtlas = UI.ResolveIcon(icon)
    if isAtlas then texture:SetAtlas(source) else texture:SetTexture(source) end
end

function UI.IconMarkup(icon, size)
    size = size or 32
    local source, isAtlas = UI.ResolveIcon(icon)
    if isAtlas then return string.format("|A:%s:%d:%d|a", source, size, size) end
    return string.format("|T%s:%d:%d|t", tostring(source), size, size)
end

-- A square button showing an icon, with a thin border.
function UI.IconButton(parent, size, onClick)
    local b = CreateFrame("Button", nil, parent, UI.BACKDROP_TEMPLATE)
    b:SetSize(size, size)
    UI.Backdrop(b, "panelAlt", "border")
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", 2, -2)
    b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    function b:SetIcon(icon)
        self.value = icon
        UI.SetIcon(self.icon, icon)
    end
    b:SetScript("OnEnter", function(self) UI.Backdrop(self, "panelAlt", "accent") end)
    b:SetScript("OnLeave", function(self) UI.Backdrop(self, "panelAlt", "border") end)
    if onClick then b:SetScript("OnClick", onClick) end
    b:SetIcon(nil)
    return b
end

-- A thin slider in the theme's colours. onChange(value) runs as it moves (whole numbers).
function UI.Slider(parent, minValue, maxValue, onChange)
    local s = CreateFrame("Slider", nil, parent, UI.BACKDROP_TEMPLATE)
    s:SetOrientation("HORIZONTAL")
    s:SetHeight(16)
    s:SetMinMaxValues(minValue, maxValue)
    s:SetValueStep(1)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    s:EnableMouse(true)
    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetTexture(UI.WHITE)
    track:SetHeight(4)
    track:SetPoint("LEFT", 0, 0)
    track:SetPoint("RIGHT", 0, 0)
    local b = UI.Color("border")
    track:SetVertexColor(b[1], b[2], b[3], 1)
    local mid = s:CreateTexture(nil, "BORDER")
    mid:SetTexture(UI.WHITE)
    mid:SetSize(1, 10)
    mid:SetPoint("CENTER")
    local m = UI.Color("muted")
    mid:SetVertexColor(m[1], m[2], m[3], 0.8)
    local thumb = s:CreateTexture(nil, "ARTWORK")
    thumb:SetTexture(UI.WHITE)
    thumb:SetSize(10, 16)
    local a = UI.Color("accent")
    thumb:SetVertexColor(a[1], a[2], a[3], 1)
    s:SetThumbTexture(thumb)
    s.quiet = false
    s:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        if not self.quiet and onChange then RPF.SafeCall("slider", onChange, value) end
    end)
    -- Set a value without calling onChange.
    function s:SetQuietly(value)
        self.quiet = true
        self:SetValue(value)
        self.quiet = false
    end
    return s
end

-- Trait pips, like a tabletop sheet: five flat pips on each side of the middle, filled from the middle towards the
-- side the character leans to. value runs 0..20 (0 = fully left, 10 = balanced, 20 = fully right);
-- each dot is 2 steps. With onPick, the dots can be clicked: clicking the outermost filled dot again
-- goes back to balanced. dots:SetValue(value) shows a value.
UI.TRAIT_DOT_SIZE, UI.TRAIT_DOT_GAP, UI.TRAIT_DOT_MIDDLE = 14, 4, 16
UI.TRAIT_DOTS_WIDTH = 10 * (UI.TRAIT_DOT_SIZE + UI.TRAIT_DOT_GAP) - UI.TRAIT_DOT_GAP + UI.TRAIT_DOT_MIDDLE

function UI.TraitDots(parent, onPick)
    local SIZE, GAP, MIDDLE = UI.TRAIT_DOT_SIZE, UI.TRAIT_DOT_GAP, UI.TRAIT_DOT_MIDDLE
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(UI.TRAIT_DOTS_WIDTH, SIZE + 4)
    frame.dots = {}
    local center = UI.TRAIT_DOTS_WIDTH / 2
    for _, side in ipairs({ -1, 1 }) do
        for i = 1, 5 do -- i counts outwards from the middle
            local dot = CreateFrame("Button", nil, frame)
            dot:SetSize(SIZE + GAP, SIZE + 4)
            dot:SetPoint("CENTER", frame, "LEFT", center + side * (MIDDLE / 2 + (i - 1) * (SIZE + GAP) + SIZE / 2), 0)
            dot.tex = dot:CreateTexture(nil, "ARTWORK")
            dot.tex:SetTexture(UI.WHITE) -- a flat pip, tinted in SetValue
            dot.tex:SetSize(SIZE, 5)
            dot.tex:SetPoint("CENTER")
            dot.side, dot.strength = side, i
            if onPick then
                dot:SetScript("OnClick", function(self)
                    local target = 10 + self.side * self.strength * 2
                    if frame.value == target then target = 10 end
                    frame:SetValue(target)
                    RPF.SafeCall("trait dots", onPick, target)
                end)
                dot:SetScript("OnEnter", function(self) self.tex:SetAlpha(1) end)
                dot:SetScript("OnLeave", function() frame:SetValue(frame.value) end)
            else
                dot:EnableMouse(false)
            end
            frame.dots[#frame.dots + 1] = dot
        end
    end
    function frame:SetValue(value)
        self.value = math.max(0, math.min(20, math.floor((tonumber(value) or 10) + 0.5)))
        local lean = (self.value - 10) / 2 -- negative leans left, positive right
        local strength = math.min(5, math.floor(math.abs(lean) + 0.5))
        local filledSide = lean < 0 and -1 or 1
        local a = UI.Color("accent")
        for _, dot in ipairs(self.dots) do
            local filled = strength >= dot.strength and dot.side == filledSide
            dot.tex:SetVertexColor(a[1], a[2], a[3], 1)
            dot.tex:SetAlpha(filled and 1 or 0.18)
        end
    end
    frame:SetValue(10)
    return frame
end

-- A simple tooltip for any frame.
function UI.Tooltip(frame, title, body)
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(title, 1, 0.82, 0.45)
        if body then GameTooltip:AddLine(body, 0.9, 0.9, 0.9, true) end
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end
