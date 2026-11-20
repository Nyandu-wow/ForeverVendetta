local _, A = ...
local unpack = unpack or table.unpack
local UI = A.UI

local banner
local killerOffer

function A.showBanner(title, detail, preview, mode, face, muteName)
    if not banner then
        banner = CreateFrame("Frame", nil, UIParent)
        banner:SetSize(620, 86)
        banner:SetPoint("TOP", 0, -70)
        UI.fit(banner, 620, 86)
        banner:SetFrameStrata("HIGH")
        banner:EnableMouse(true)
        local plate = banner:CreateTexture(nil, "BACKGROUND")
        plate:SetAllPoints()
        plate:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock")
        if plate.SetHorizTile then plate:SetHorizTile(true) end
        if plate.SetVertTile then plate:SetVertTile(true) end
        UI.rect(banner, 0, 0, 620, 86, { .04, .04, .045, .55 })
        local metal = "Interface\\FrameGeneral\\UIFrameMetalHorizontal"
        local top = banner:CreateTexture(nil, "ARTWORK")
        top:SetTexture(metal)
        top:SetPoint("TOPLEFT")
        top:SetPoint("TOPRIGHT")
        top:SetHeight(10)
        if top.SetTexCoord then top:SetTexCoord(0, 1, 0.263671875, 0.357421875) end
        local bottom = banner:CreateTexture(nil, "ARTWORK")
        bottom:SetTexture(metal)
        bottom:SetPoint("BOTTOMLEFT")
        bottom:SetPoint("BOTTOMRIGHT")
        bottom:SetHeight(10)
        if bottom.SetTexCoord then bottom:SetTexCoord(0, 1, 0.001953125, 0.259765625) end
        banner.accent = UI.rect(banner, 0, 0, 4, 86, UI.GOLD, "ARTWORK")
        banner.classIcon = banner:CreateTexture(nil, "OVERLAY")
        banner.classIcon:SetSize(28, 28)
        banner.classIcon:SetPoint("LEFT", 16, 4)
        banner.classIcon:Hide()
        banner.raceIcon = banner:CreateTexture(nil, "OVERLAY")
        banner.raceIcon:SetSize(28, 28)
        banner.raceIcon:SetPoint("LEFT", banner.classIcon, "RIGHT", 4, 0)
        banner.raceIcon:Hide()
        banner.heading = UI.text(banner, "", 18, 8, 480, "GameFontNormalSmall", UI.MUTED)
        banner.title = UI.text(banner, "", 18, 26, 480, "GameFontNormalLarge", UI.GOLD)
        banner.detail = UI.text(banner, "", 18, 52, 480, "GameFontHighlightSmall", UI.WHITE)
        banner.mute = UI.button(banner, "Mute", 520, 30, 80, function()
            local who = banner.muteName
            if not who or not A.ignoreEnemy then return end
            local ok, err = A.ignoreEnemy(who)
            if ok then
                A.print("Muted alerts for " .. who .. " (reports stay).")
                banner:Hide()
                if A.changed then A.changed() end
            elseif err then
                A.print(err)
            end
        end, "quiet")
        UI.tip(banner.mute, "Mute alerts", "Stop warnings for this enemy on your client only. Reports stay.")
        banner.remaining = 0
        banner:Hide()
        banner:SetScript("OnUpdate", function(self, dt)
            self.remaining = (self.remaining or 0) - (dt or 0)
            self:SetAlpha(math.min(1, math.max(0, self.remaining / .6)))
            if self.remaining <= 0 then self:Hide() end
        end)
    end
    local color = { 1, .82, .35 }
    for _, s in ipairs(UI.STANCES) do
        if s.id == mode then color = s.color break end
    end
    banner.accent:SetColorTexture(color[1], color[2], color[3], 1)
    banner.title:SetTextColor(unpack(color))
    UI.paintFace(banner.classIcon, banner.raceIcon, face)
    local shown = (banner.classIcon:IsShown() or banner.raceIcon:IsShown()) and true or false
    local x = shown and 80 or 18
    banner.heading:ClearAllPoints()
    banner.heading:SetPoint("TOPLEFT", x, -8)
    banner.title:ClearAllPoints()
    banner.title:SetPoint("TOPLEFT", x, -26)
    banner.detail:ClearAllPoints()
    banner.detail:SetPoint("TOPLEFT", x, -52)
    banner.heading:SetText(preview and "Preview" or "Blacklisted enemy")
    banner.title:SetText(title)
    banner.detail:SetText(detail)
    banner.muteName = (not preview and A.plain(muteName, "string") and muteName ~= "") and muteName or nil
    if banner.mute then banner.mute:SetShown(banner.muteName ~= nil) end
    banner.remaining = 6
    banner:SetAlpha(1)
    banner:Show()
end

function A.hideKillerOffer()
    if killerOffer then killerOffer:Hide() end
end

function A.showKillerOffer(pending)
    if not pending then return end
    local ctx = A._win or {}
    if not killerOffer then
        killerOffer = CreateFrame("Frame", nil, UIParent)
        killerOffer:SetSize(420, 110)
        killerOffer:SetPoint("TOP", 0, -170)
        UI.fit(killerOffer, 420, 110)
        killerOffer:SetFrameStrata("DIALOG")
        killerOffer:EnableMouse(true)
        local plate = killerOffer:CreateTexture(nil, "BACKGROUND")
        plate:SetAllPoints()
        plate:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock")
        UI.rect(killerOffer, 0, 0, 420, 110, { .04, .04, .045, .72 })
        UI.rect(killerOffer, 0, 0, 4, 110, { .72, .18, .12, 1 }, "ARTWORK")
        killerOffer.heading = UI.text(killerOffer, "Remember this kill?", 16, 10, 380, "GameFontNormal", UI.GOLD)
        killerOffer.body = UI.text(killerOffer, "", 16, 34, 380, "GameFontHighlight", UI.WHITE)
        killerOffer.note = UI.text(killerOffer, "From your death recap. Not shared until you add them.", 16, 56, 380, "GameFontHighlightSmall", UI.MUTED)
        killerOffer.add = UI.button(killerOffer, "Add as Avenge", 16, 78, 150, function()
            local ok, err = A.acceptKillerOffer("AVENGE")
            if ok then
                A.print("Added to your blacklist.")
            elseif err then
                A.print(err)
            end
        end, "primary")
        killerOffer.skip = UI.button(killerOffer, "Not now", 176, 78, 100, function()
            A.dismissKillerOffer()
        end)
        killerOffer.open = UI.button(killerOffer, "Open /fv", 286, 78, 110, function()
            local p = A.pendingKiller
            if not ctx.panel and ctx.build then ctx.build() end
            ctx.panel:Show()
            ctx.switch(p and p.place == "battleground" and "battlegrounds" or "world")
            if p and ctx.ui.name then
                ctx.ui.name:SetText(p.name)
                ctx.ui.note:SetText("Killed me")
                ctx.mode = "AVENGE"
                ctx.selected, ctx.selectedRealm = p.name:lower(), p.realm
            end
            A.dismissKillerOffer()
            A.refresh()
        end)
    end
    local where = A.pvpPlaceLabel and A.pvpPlaceLabel(pending.place) or pending.place
    killerOffer.body:SetText(pending.name .. " · " .. where)
    killerOffer:Show()
end