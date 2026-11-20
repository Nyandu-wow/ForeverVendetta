local _, A = ...
local unpack = unpack or table.unpack

local W, H, ROWS = 720, 480, 6
local GOLD = { .82, .68, .38 }
local INK, INK_MUTED, WHITE = { .90, .87, .80 }, { .62, .58, .50 }, { .92, .90, .86 }
local MUTED = INK_MUTED
local STONE = { .07, .07, .08, 1 }
local ROW = { .13, .12, .11, 1 }
local ROW_ON = { .26, .15, .13, 1 }
local BURGUNDY = { .62, .22, .18 }
local CLASS_TEX = "Interface\\TargetingFrame\\UI-Classes-Circles"
local RACE_TEX = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races"
-- Forever Vanilla classes only — no Death Knight (same honesty as race icons).
local CLASS_COORDS = {
    WARRIOR = { 0, .25, 0, .25 }, MAGE = { .25, .49609375, 0, .25 },
    ROGUE = { .49609375, .7421875, 0, .25 }, DRUID = { .7421875, .98828125, 0, .25 },
    HUNTER = { 0, .25, .25, .5 }, SHAMAN = { .25, .49609375, .25, .5 },
    PRIEST = { .49609375, .7421875, .25, .5 }, WARLOCK = { .7421875, .98828125, .25, .5 },
    PALADIN = { 0, .25, .5, .75 },
}
-- Forever ships the post-Vanilla race atlas (GlueXML RACE_ICON_TCOORDS).
-- Wrong coords made Tauren paint as Draenei ({.5,.625,0,.25} is DRAENEI_MALE).
-- Only the eight Forever races — never Draenei / Blood Elf even if the sheet has them.
local RACE_COORDS = {
    HUMAN_MALE = { 0, .125, 0, .25 }, DWARF_MALE = { .125, .25, 0, .25 },
    GNOME_MALE = { .25, .375, 0, .25 }, NIGHTELF_MALE = { .375, .5, 0, .25 },
    TAUREN_MALE = { 0, .125, .25, .5 }, SCOURGE_MALE = { .125, .25, .25, .5 },
    TROLL_MALE = { .25, .375, .25, .5 }, ORC_MALE = { .375, .5, .25, .5 },
    HUMAN_FEMALE = { 0, .125, .5, .75 }, DWARF_FEMALE = { .125, .25, .5, .75 },
    GNOME_FEMALE = { .25, .375, .5, .75 }, NIGHTELF_FEMALE = { .375, .5, .5, .75 },
    TAUREN_FEMALE = { 0, .125, .75, 1 }, SCOURGE_FEMALE = { .125, .25, .75, 1 },
    TROLL_FEMALE = { .25, .375, .75, 1 }, ORC_FEMALE = { .375, .5, .75, 1 },
}

local STANCES = {
    { id = "AVENGE", label = "Avenge", color = { 1, .40, .32 }, hint = "You want another fight with this player." },
    { id = "AVOID", label = "Avoid", color = { 1, .73, .30 }, hint = "Warn your friends to give this player space." },
    { id = "WATCH", label = "Watch", color = { .36, .77, .94 }, hint = "Keep an eye on this player." },
}

local BUTTON_FACE = {
    quiet = { .16, .15, .14, 1 },
    primary = { .22, .17, .11, 1 },
    danger = { .28, .12, .11, 1 },
}
local BUTTON_INK = {
    quiet = INK,
    primary = GOLD,
    danger = { .92, .74, .68 },
}

local function paintFace(classTex, raceTex, face)
    face = face or {}
    local classCoords = CLASS_COORDS[face.class]
    if classTex then
        if classCoords and classTex.SetTexture then
            classTex:SetTexture(CLASS_TEX)
            classTex:SetTexCoord(classCoords[1], classCoords[2], classCoords[3], classCoords[4])
            classTex:Show()
        elseif classTex.Hide then
            classTex:Hide()
        end
    end
    local sex = face.sex == 3 and "FEMALE" or "MALE"
    local raceCoords = face.race and RACE_COORDS[face.race .. "_" .. sex]
    if raceTex then
        if raceCoords and raceTex.SetTexture then
            raceTex:SetTexture(RACE_TEX)
            raceTex:SetTexCoord(raceCoords[1], raceCoords[2], raceCoords[3], raceCoords[4])
            raceTex:Show()
        elseif raceTex.Hide then
            raceTex:Hide()
        end
    end
end

local function hexColor(color)
    return string.format("|cff%02x%02x%02x",
        math.floor((color[1] or 1) * 255 + .5),
        math.floor((color[2] or 1) * 255 + .5),
        math.floor((color[3] or 1) * 255 + .5))
end

local function text(parent, value, x, y, width, font, color)
    local f = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    f:SetPoint("TOPLEFT", x, -y)
    f:SetWidth(width)
    f:SetJustifyH("LEFT")
    f:SetJustifyV("TOP")
    f:SetTextColor(unpack(color or INK))
    f:SetText(value)
    return f
end

local function rect(parent, x, y, w, h, color, layer)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetPoint("TOPLEFT", x, -y)
    t:SetSize(w, h)
    t:SetColorTexture(unpack(color))
    return t
end

local function box(parent, x, y, w, h)
    local f = CreateFrame("Frame", nil, parent)
    f:SetPoint("TOPLEFT", x, -y)
    f:SetSize(w, h)
    return f
end

local function button(parent, value, x, y, w, callback, role)
    role = role or "quiet"
    local b = CreateFrame("Button", nil, parent)
    b:SetPoint("TOPLEFT", x, -y)
    b:SetSize(w, 22)
    b.role = role
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.bg:SetColorTexture(unpack(BUTTON_FACE[role]))
    b.edge = b:CreateTexture(nil, "BORDER")
    b.edge:SetPoint("BOTTOMLEFT", 0, 0)
    b.edge:SetPoint("BOTTOMRIGHT", 0, 0)
    b.edge:SetHeight(1)
    b.edge:SetColorTexture(unpack(role == "danger" and BURGUNDY or { .38, .32, .22, .8 }))
    local label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER", 0, 1)
    b:SetFontString(label)
    b:SetText(value)
    label:SetTextColor(unpack(BUTTON_INK[role]))
    b:SetScript("OnClick", callback)
    b:SetScript("OnEnable", function(self) self:SetAlpha(1) end)
    b:SetScript("OnDisable", function(self) self:SetAlpha(.45) end)
    return b
end

local function tip(frame, title, body)
    frame:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, unpack(GOLD))
        GameTooltip:AddLine(body, .9, .9, .9, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
end

local function edit(parent, x, y, w, max, multi)
    local h = multi and 48 or 26
    local e = CreateFrame("EditBox", nil, parent)
    e:SetPoint("TOPLEFT", x, -y)
    e:SetSize(w, h)
    e:SetFontObject("GameFontHighlight")
    e:SetTextInsets(8, 8, 4, 4)
    e:SetAutoFocus(false)
    e:SetMaxBytes(max)
    e:SetMultiLine(multi == true)
    e:SetTextColor(unpack(INK))
    rect(e, 0, 0, w, h, { .05, .05, .06, 1 })
    local line = rect(e, 0, h - 1, w, 1, { .38, .32, .22, .85 })
    e:SetScript("OnEditFocusGained", function() line:SetColorTexture(unpack(GOLD)) end)
    e:SetScript("OnEditFocusLost", function() line:SetColorTexture(.38, .32, .22, .85) end)
    e:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        A.close()
    end)
    e:SetText("")
    return e
end

local function shorten(value, limit)
    if not A.plain(value, "string") then return "" end
    if #value <= limit then return value end
    return value:sub(1, limit - 3) .. "..."
end

local function placeholder(e, value)
    local hint = text(e, value, 8, 6, 285, "GameFontDisable", INK_MUTED)
    local previous = e:GetScript("OnTextChanged")
    e:SetScript("OnTextChanged", function(self, user)
        hint:SetShown(self:GetText() == "")
        if previous then previous(self, user) end
    end)
end

local function fit(frame, w, h)
    frame:SetClampedToScreen(true)
    local scale = 1
    local height = A.call(UIParent and UIParent.GetHeight, UIParent)
    local width = A.call(UIParent and UIParent.GetWidth, UIParent)
    if A.plain(height, "number") and height > 160 then scale = math.min(scale, (height - 40) / h) end
    if A.plain(width, "number") and width > 160 then scale = math.min(scale, (width - 40) / w) end
    frame:SetScale(scale)
end

A.UI = {
    W = W,
    H = H,
    ROWS = ROWS,
    GOLD = GOLD,
    INK = INK,
    INK_MUTED = INK_MUTED,
    WHITE = WHITE,
    MUTED = MUTED,
    STONE = STONE,
    ROW = ROW,
    ROW_ON = ROW_ON,
    BURGUNDY = BURGUNDY,
    STANCES = STANCES,
    BUTTON_FACE = BUTTON_FACE,
    paintFace = paintFace,
    hexColor = hexColor,
    text = text,
    rect = rect,
    box = box,
    button = button,
    tip = tip,
    edit = edit,
    shorten = shorten,
    placeholder = placeholder,
    fit = fit,
}