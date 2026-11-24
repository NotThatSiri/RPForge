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
