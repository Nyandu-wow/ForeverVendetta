local _, A = ...

local ICON = "Interface\\Icons\\Ability_DualWield"
-- Extra pixels past the Minimap frame edge. Forever's stock chrome sits outside that frame.
local EDGE = 10
local button

local shapes = {
    ROUND = { true, true, true, true },
    SQUARE = { false, false, false, false },
    ["CORNER-TOPLEFT"] = { false, false, false, true },
    ["CORNER-TOPRIGHT"] = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"] = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
    ["SIDE-LEFT"] = { false, true, false, true },
    ["SIDE-RIGHT"] = { true, false, true, false },
    ["SIDE-TOP"] = { false, false, true, true },
    ["SIDE-BOTTOM"] = { true, true, false, false },
    ["TRICORNER-TOPLEFT"] = { false, true, true, true },
    ["TRICORNER-TOPRIGHT"] = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

local function angle()
    local s = A.store and A.store.settings
    return (s and tonumber(s.minimapAngle)) or 220
end

local function place(btn)
    if not btn or type(Minimap) ~= "table" then return end
    local deg = angle()
    local rad = math.rad(deg)
    local x, y = math.cos(rad), math.sin(rad)
    local q = 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end
    local shapeName = (GetMinimapShape and GetMinimapShape()) or "ROUND"
    if issecretvalue and issecretvalue(shapeName) then shapeName = "ROUND" end
    local shape = shapes[shapeName] or shapes.ROUND
    local w = (Minimap:GetWidth() / 2) + EDGE
    local h = (Minimap:GetHeight() / 2) + EDGE
    if shape[q] then
        x, y = x * w, y * h
    else
        local dw = math.sqrt(2 * (w ^ 2)) - 10
        local dh = math.sqrt(2 * (h ^ 2)) - 10
        x = math.max(-w, math.min(x * dw, w))
        y = math.max(-h, math.min(y * dh, h))
    end
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function tooltip(btn)
    if not GameTooltip then return end
    GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
    GameTooltip:SetText("Forever Vendetta", .82, .68, .38)
    GameTooltip:AddLine("Left-click: open the blacklist", .9, .87, .8, true)
    GameTooltip:AddLine("Right-click: trusted friends", .9, .87, .8, true)
    GameTooltip:AddLine("Drag to move around the minimap", .62, .58, .5, true)
    GameTooltip:Show()
end

function A.refreshMinimap()
    if not button then return end
    local show = not A.store or A.store.settings.minimapButton ~= false
    if show then
        place(button)
        button:Show()
    else
        button:Hide()
    end
end

function A.buildMinimap()
    if button then
        A.refreshMinimap()
        return
    end
    if type(Minimap) ~= "table" then return end

    button = CreateFrame("Button", "ForeverVendettaMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    if button.SetFixedFrameStrata then button:SetFixedFrameStrata(true) end
    button:SetFrameLevel(8)
    if button.SetFixedFrameLevel then button:SetFixedFrameLevel(true) end
    button:SetMovable(true)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetTexture(ICON)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexCoord(.08, .92, .08, .92)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT")

    button:SetScript("OnEnter", function(self) tooltip(self) end)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    button:SetScript("OnClick", function(_, mouse)
        if mouse == "RightButton" then
            A.toggleFriends()
        else
            A.toggle()
        end
    end)
    button:SetScript("OnDragStart", function(self)
        self.dragging = true
        if GameTooltip then GameTooltip:Hide() end
    end)
    button:SetScript("OnDragStop", function(self)
        self.dragging = false
    end)
    button:SetScript("OnUpdate", function(self)
        if not self.dragging or type(Minimap) ~= "table" then return end
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        if not A.plain(mx, "number") or not A.plain(cx, "number") or not A.plain(scale, "number") or scale == 0 then
            return
        end
        cx, cy = cx / scale, cy / scale
        local deg = math.deg(math.atan2(cy - my, cx - mx))
        if A.store and A.store.settings then
            A.store.settings.minimapAngle = deg
        end
        place(self)
    end)

    A.refreshMinimap()
end

function ForeverVendetta_OnAddonCompartmentClick()
    if A.toggle then A.toggle() end
end

function ForeverVendetta_OnAddonCompartmentEnter(_, menuButton)
    if not GameTooltip or not menuButton then return end
    GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
    GameTooltip:SetText("Forever Vendetta", .82, .68, .38)
    GameTooltip:AddLine("Open the friends-only enemy blacklist.", .9, .87, .8, true)
    GameTooltip:Show()
end

function ForeverVendetta_OnAddonCompartmentLeave()
    if GameTooltip then GameTooltip:Hide() end
end

if type(AddonCompartmentFrame) == "table" and AddonCompartmentFrame.RegisterAddon then
    pcall(AddonCompartmentFrame.RegisterAddon, AddonCompartmentFrame, {
        text = "Forever Vendetta",
        icon = ICON,
        notCheckable = true,
        func = function()
            if A.toggle then A.toggle() end
        end,
    })
end
