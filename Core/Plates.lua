local _, A = ...

-- Lightweight nameplate mark for listed enemies. Visible units only — no CLEU radar.

local function plateFrame(unit)
    if type(C_NamePlate) ~= "table" then return nil end
    if type(C_NamePlate.GetNamePlateForUnit) == "function" then
        return A.call(C_NamePlate.GetNamePlateForUnit, unit)
    end
    local plates = A.call(C_NamePlate.GetNamePlates)
    if type(plates) ~= "table" then return nil end
    for _, plate in ipairs(plates) do
        if type(plate) == "table" then
            local token = plate.namePlateUnitToken or plate.unitToken
            if token == unit then return plate end
        end
    end
end

local function ensureBadge(plate)
    if type(plate) ~= "table" then return nil end
    local host = plate.UnitFrame or plate
    if type(host) ~= "table" or type(host.CreateTexture) ~= "function" then return nil end
    local badge = plate.ForeverVendettaBadge
    if type(badge) == "table" then return badge end
    badge = host:CreateTexture(nil, "OVERLAY")
    badge:SetSize(14, 14)
    badge:SetPoint("LEFT", host, "LEFT", 2, 0)
    badge:SetColorTexture(.85, .2, .12, .95)
    badge:Hide()
    plate.ForeverVendettaBadge = badge
    local mark = host:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mark:SetPoint("CENTER", badge, "CENTER", 0, 0)
    mark:SetText("V")
    mark:SetTextColor(1, .9, .75)
    mark:Hide()
    plate.ForeverVendettaMark = mark
    return badge
end

function A.refreshPlateBadge(unit, who, listed)
    if not A.ready or A.store.settings.nameplateBadge == false then return end
    if not A.plain(unit, "string") then return end
    local plate = plateFrame(unit)
    if not plate then return end
    local badge = ensureBadge(plate)
    if not badge then return end
    local mark = plate.ForeverVendettaMark
    local show = listed == true
    if show and who and A.isIgnored and A.isIgnored(who.key) then
        badge:SetColorTexture(.45, .45, .48, .85)
    elseif show then
        badge:SetColorTexture(.85, .2, .12, .95)
    end
    badge:SetShown(show)
    if mark then mark:SetShown(show) end
end

function A.clearPlateBadge(unit)
    if not A.plain(unit, "string") then return end
    local plate = plateFrame(unit)
    if not plate then return end
    if plate.ForeverVendettaBadge then plate.ForeverVendettaBadge:Hide() end
    if plate.ForeverVendettaMark then plate.ForeverVendettaMark:Hide() end
end

-- One plate walk: detect already refreshes badges (even when alerts are place-gated off).
function A.scanPlateBadges()
    if not A.ready or A.store.settings.nameplateBadge == false then return end
    local plates = type(C_NamePlate) == "table" and A.call(C_NamePlate.GetNamePlates)
    if type(plates) ~= "table" then return end
    for _, plate in ipairs(plates) do
        if type(plate) == "table" then
            local unit = plate.namePlateUnitToken or plate.unitToken
            if A.plain(unit, "string") and A.detect then A.detect(unit) end
        end
    end
end
