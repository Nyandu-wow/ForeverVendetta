local _, A = ...
local unpack = unpack or table.unpack

local GOLD = { .82, .68, .38 }
local INK = { .90, .87, .80 }
local MUTED = { .62, .58, .50 }
local panel, category, minimapCheck

local function label(parent, value, x, y, width, font, color)
    local f = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
    f:SetPoint("TOPLEFT", x, -y)
    f:SetWidth(width)
    f:SetJustifyH("LEFT")
    f:SetTextColor(unpack(color or INK))
    f:SetText(value)
    return f
end

local function refresh()
    if not panel or not A.store then return end
    if minimapCheck then
        minimapCheck:SetChecked(A.store.settings.minimapButton ~= false)
    end
end

function A.refreshOptions()
    refresh()
end

function A.buildOptions()
    if panel then
        refresh()
        return
    end
    if type(Settings) ~= "table" or type(Settings.RegisterCanvasLayoutCategory) ~= "function" then
        return
    end

    panel = CreateFrame("Frame", "ForeverVendettaOptions")
    panel:Hide()
    panel.name = "Forever Vendetta"

    label(panel, "Forever Vendetta", 16, 16, 400, "GameFontNormalLarge", GOLD)
    label(panel, "Friends-only enemy notes with visible-unit warnings. No Internet.", 16, 42, 520, "GameFontHighlightSmall", MUTED)

    local open = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    open:SetPoint("TOPLEFT", 16, -72)
    open:SetSize(180, 24)
    open:SetText("Open Forever Vendetta")
    open:SetScript("OnClick", function()
        if A.toggle then A.toggle() end
    end)

    minimapCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    minimapCheck:SetPoint("TOPLEFT", 12, -112)
    minimapCheck:SetSize(26, 26)
    label(minimapCheck, "Show minimap button", 30, 2, 300, "GameFontHighlight", INK)
    label(minimapCheck, "Left-click opens the window. Right-click opens Friends. Drag to move.", 30, 18, 480, "GameFontHighlightSmall", MUTED)
    minimapCheck:SetScript("OnClick", function(self)
        if not A.store then return end
        A.store.settings.minimapButton = self:GetChecked() == true
        if A.refreshMinimap then A.refreshMinimap() end
        if A.refresh then A.refresh() end
    end)

    label(panel, "Slash commands", 16, 168, 300, "GameFontNormal", GOLD)
    label(panel, "/fv opens the blacklist. /fv friends sets up sharing. /fv help lists the rest.", 16, 190, 520, "GameFontHighlightSmall", MUTED)

    panel:SetScript("OnShow", refresh)

    local ok, cat = pcall(Settings.RegisterCanvasLayoutCategory, panel, "Forever Vendetta")
    if ok and cat then
        category = cat
        pcall(Settings.RegisterAddOnCategory, category)
    end
    refresh()
end

function A.openOptions()
    if not category then A.buildOptions() end
    if category and type(Settings) == "table" and Settings.OpenToCategory then
        local id = category.GetID and category:GetID() or category
        pcall(Settings.OpenToCategory, id)
        return
    end
    if A.toggle then A.toggle() end
end
