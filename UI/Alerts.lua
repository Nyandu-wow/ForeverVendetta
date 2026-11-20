local _, A = ...
local UI = A.UI

function A.buildAlertsUI(ctx)
    local ui = ctx.ui
    local p = ctx.pages.alerts
    ui.checks = {}

    local left = UI.box(p, 16, 112, 360, 336)
    UI.text(left, "Sound and banner", 12, 8, 330, "GameFontNormal", UI.GOLD)
    for _, spec in ipairs({
        { "sound", "Play a warning sound", 28, "Uses the Master channel for the sound on the right." },
        { "banner", "Show an on-screen warning", 52, "Six-second banner with the reason." },
    }) do
        local c = CreateFrame("CheckButton", nil, left, "UICheckButtonTemplate")
        c:SetPoint("TOPLEFT", 10, -spec[3])
        c:SetSize(24, 24)
        UI.text(c, spec[2], 28, 4, 300, "GameFontHighlight", UI.INK)
        UI.tip(c, spec[2], spec[4])
        c:SetScript("OnClick", function(self)
            A.store.settings[spec[1]] = self:GetChecked() == true
            A.changed()
        end)
        ui.checks[spec[1]] = c
    end

    UI.text(left, "Where it can warn", 12, 92, 330, "GameFontNormal", UI.GOLD)
    for _, spec in ipairs({
        { "world", "Warn in open world", 112, "Open-world PvP. On by default." },
        { "battlegrounds", "Warn in battlegrounds", 136, "Separate from world PvP. Off by default." },
        { "instances", "Warn in arenas", 160, "Off by default." },
    }) do
        local c = CreateFrame("CheckButton", nil, left, "UICheckButtonTemplate")
        c:SetPoint("TOPLEFT", 10, -spec[3])
        c:SetSize(24, 24)
        UI.text(c, spec[2], 28, 4, 300, "GameFontHighlight", UI.INK)
        UI.tip(c, spec[2], spec[4])
        c:SetScript("OnClick", function(self)
            A.store.settings[spec[1]] = self:GetChecked() == true
            A.changed()
        end)
        ui.checks[spec[1]] = c
    end

    UI.text(left, "Window", 12, 200, 330, "GameFontNormal", UI.GOLD)
    do
        local c = CreateFrame("CheckButton", nil, left, "UICheckButtonTemplate")
        c:SetPoint("TOPLEFT", 10, -220)
        c:SetSize(24, 24)
        UI.text(c, "Show minimap button", 28, 4, 300, "GameFontHighlight", UI.INK)
        UI.tip(c, "Show minimap button", "Left-click opens Vendetta; right-click opens Friends.")
        c:SetScript("OnClick", function(self)
            A.store.settings.minimapButton = self:GetChecked() == true
            A.changed()
            if A.refreshMinimap then A.refreshMinimap() end
        end)
        ui.checks.minimapButton = c
    end
    UI.text(left, "Detection: nameplates, target, focus, mouseover.", 12, 268, 330, "GameFontHighlightSmall", UI.INK_MUTED)
    UI.text(left, "Chat shows name + stance; the reason stays on the banner.", 12, 288, 330, "GameFontHighlightSmall", UI.INK_MUTED)
    UI.text(left, "Per-enemy mute: select them on World/BG, then Mute alerts.", 12, 308, 330, "GameFontHighlightSmall", UI.INK_MUTED)

    local right = UI.box(p, 388, 112, 316, 336)
    UI.text(right, "Warning sound", 12, 8, 280, "GameFontNormal", UI.GOLD)
    UI.text(right, "Built-in game sounds on the Master channel.", 12, 26, 290, "GameFontHighlightSmall", UI.INK_MUTED)
    ui.soundButtons = {}
    for i, sound in ipairs(A.ALERT_SOUNDS) do
        local col = (i - 1) % 4
        local row = math.floor((i - 1) / 4)
        local b = UI.button(right, sound.label, 12 + col * 74, 48 + row * 26, 70, function()
            A.store.settings.alertSound = sound.id
            A.playSound()
            A.changed()
        end)
        b.caption = sound.label
        b.soundId = sound.id
        b.mark = UI.rect(b, 6, 20, 58, 2, UI.GOLD, "OVERLAY")
        b.mark:Hide()
        ui.soundButtons[sound.id] = b
    end

    UI.text(right, "Repeat the same enemy", 12, 110, 180, "GameFontNormal", UI.GOLD)
    ui.cooldownLabel = UI.text(right, "", 198, 110, 100, "GameFontNormal", UI.GOLD)
    local slider = CreateFrame("Slider", nil, right, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 16, -134)
    slider:SetSize(270, 16)
    slider:SetMinMaxValues(10, 600)
    slider:SetValueStep(10)
    slider:SetObeyStepOnDrag(true)
    if type(slider.Text) == "table" and slider.Text.SetText then slider.Text:SetText("") end
    if type(slider.Low) == "table" and slider.Low.SetText then slider.Low:SetText("10s") end
    if type(slider.High) == "table" and slider.High.SetText then slider.High:SetText("10m") end
    slider:SetScript("OnValueChanged", function(_, value)
        local v = math.max(10, math.min(600, math.floor(value + .5)))
        if A.store.settings.cooldown ~= v then
            A.store.settings.cooldown = v
            A.changed()
        end
    end)
    ui.cooldown = slider

    UI.text(right, "Extras", 12, 168, 100, "GameFontNormal", UI.GOLD)
    for _, spec in ipairs({
        { "deathOffer", "Offer to add killer after I die", 188, "After a player kill, offer to blacklist them. Never for PvE mobs." },
        { "targetButton", "FV button on target frame", 210, "Shortcut to open a report for your current enemy target." },
        { "partyAnnounce", "Share alert with party/raid", 232, "Not friends-only. Prints name + stance to your current group. Reason stays private. Off by default." },
        { "nameplateBadge", "Nameplate V for listed enemies", 254, "Small V mark on enemy nameplates you have listed. Grey when muted." },
        { "tooltips", "Vendetta on enemy tooltips", 276, "Show stance and reason on listed enemy tooltips." },
    }) do
        local c = CreateFrame("CheckButton", nil, right, "UICheckButtonTemplate")
        c:SetPoint("TOPLEFT", 10, -spec[3])
        c:SetSize(20, 20)
        UI.text(c, spec[2], 24, 2, 275, "GameFontHighlightSmall", UI.INK)
        UI.tip(c, spec[2], spec[4])
        c:SetScript("OnClick", function(self)
            A.store.settings[spec[1]] = self:GetChecked() == true
            A.changed()
            if spec[1] == "targetButton" and A.refreshTargetButton then A.refreshTargetButton() end
            if spec[1] == "nameplateBadge" and A.scanPlateBadges then A.scanPlateBadges() end
        end)
        ui.checks[spec[1]] = c
    end
    UI.button(right, "Preview alert", 12, 304, 290, function()
        A.testAlert()
        ctx.feedback("Test alert played using your current settings.")
    end, "primary")
end