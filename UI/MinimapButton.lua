-- RP Forge: the anvil button on the minimap.
-- Left-click opens or closes the window, right-click opens Appearance. Drag it around the minimap edge.
local _, RPF = ...
local UI = RPF.UI

local ICON = "Interface\\Icons\\Trade_BlackSmithing"
local button

local function UpdatePosition()
    local angle = math.rad(RPF.db.settings.minimap.angle or 210)
    local radius = (Minimap:GetWidth() / 2) + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function DragUpdate()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    RPF.db.settings.minimap.angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx)) % 360
    UpdatePosition()
end

local function Build()
    button = CreateFrame("Button", "RPForgeMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(20, 20)
    background:SetPoint("TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON)
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function(_, mouse)
        if mouse == "RightButton" then
            UI.OpenSettings("appearance")
        else
            UI.ToggleWindow()
        end
    end)
    button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", DragUpdate) end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("RP Forge " .. RPF.VERSION, 1, 0.82, 0.45)
        GameTooltip:AddLine("Left-click: open or close", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Right-click: Appearance", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Drag: move around the minimap", 0.9, 0.9, 0.9)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    UpdatePosition()
end

function RPF.SetMinimapButtonShown(shown)
    RPF.db.settings.minimap.shown = shown and true or false
    if shown and not button then Build() end
    if button then button:SetShown(shown) end
end

RPF.OnEvent("PLAYER_LOGIN", function()
    if RPF.db.settings.minimap.shown then Build() end
end)

RPF.AddCommand("minimap", "Show or hide the minimap button", function()
    RPF.SetMinimapButtonShown(not RPF.db.settings.minimap.shown)
    RPF.Print("minimap button " .. (RPF.db.settings.minimap.shown and "shown." or "hidden."))
end)
