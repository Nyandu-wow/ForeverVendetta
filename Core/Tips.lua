local _, A = ...

local hooked, targetBtn

function A.tooltipLines(who)
    if not A.ready or not who then return nil end
    local placeFilter = A.alertPlaceFilter and select(1, A.alertPlaceFilter()) or nil
    local matches = A.match(who.key, placeFilter)
    if #matches == 0 then return nil end
    local lines = { "Forever Vendetta" }
    local own, friends = nil, 0
    for i = 1, #matches do
        local entry = matches[i]
        if entry.owner == A.me.key then
            own = entry
        else
            friends = friends + 1
        end
    end
    if own then
        local note = own.report.note ~= "" and own.report.note or "No reason"
        lines[#lines + 1] = A.stanceLabel(own.report.mode) .. ": " .. note
    end
    if friends > 0 then
        lines[#lines + 1] = friends == 1 and "1 friend report" or (friends .. " friend reports")
    end
    if not own and #matches > 0 then
        local first = matches[1]
        lines[#lines + 1] = A.stanceLabel(first.report.mode) .. ": " .. (first.report.note ~= "" and first.report.note or "Listed")
            .. " (" .. A.personName(first.owner) .. ")"
    end
    if A.isIgnored and A.isIgnored(who.key) then
        lines[#lines + 1] = "Alerts muted (local)"
    end
    local seen = A.sightingFor and A.sightingFor(who.key, placeFilter or "world")
    local when = A.formatSeenWhen and A.formatSeenWhen(seen)
    if when then
        if seen.zone ~= "" then
            lines[#lines + 1] = "Last seen · " .. seen.zone .. " · " .. when
        else
            lines[#lines + 1] = "Last seen · " .. when
        end
    end
    return lines
end

local function decorateTooltip(tip)
    if not A.ready or not tip or not A.store or A.store.settings.tooltips == false then return end
    local unit
    if tip.GetUnit then
        local ok, a, b = pcall(function() return tip:GetUnit() end)
        if ok then
            -- Classic returns name, unitToken. Some tips return only the unit.
            if A.plain(b, "string") then unit = b
            elseif A.plain(a, "string") and (a == "mouseover" or a == "target" or a == "focus" or a:find("nameplate", 1, true) == 1) then
                unit = a
            elseif A.plain(a, "string") then
                unit = "mouseover"
            end
        end
    end
    if not A.plain(unit, "string") then unit = "mouseover" end
    if not A.flag(UnitExists, unit) then return end
    if not A.flag(UnitIsPlayer, unit) or not A.flag(UnitIsEnemy, "player", unit) then return end
    local who = A.unitName(unit)
    if not who then return end
    local lines = A.tooltipLines(who)
    if not lines then return end
    tip:AddLine(" ")
    for i = 1, #lines do
        if i == 1 then
            tip:AddLine(lines[i], 1, .44, .33)
        else
            tip:AddLine(lines[i], .9, .87, .8, true)
        end
    end
    tip:Show()
end

function A.hookTooltips()
    if hooked then return end
    hooked = true
    if GameTooltip and GameTooltip.HookScript then
        pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetUnit", function(self)
            decorateTooltip(self)
        end)
    end
    if TooltipDataProcessor and Enum and Enum.TooltipDataType and TooltipDataProcessor.AddTooltipPostCall then
        pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Unit, function(tooltip)
            decorateTooltip(tooltip)
        end)
    end
end

function A.openEnemyDraft(who, note, mode, place)
    if not who then return false, "No enemy identity." end
    if A.prepareEnemyDraft then
        return A.prepareEnemyDraft(who, note, mode, place)
    end
    return A.report(who.name, note or "Listed enemy", mode or "AVENGE", false, who.realm, place)
end

function A.refreshTargetButton()
    if not targetBtn then return end
    if A.store.settings.targetButton == false then
        targetBtn:Hide()
        return
    end
    if not A.flag(UnitExists, "target") or not A.flag(UnitIsPlayer, "target") or not A.flag(UnitIsEnemy, "player", "target") then
        targetBtn:Hide()
        return
    end
    local who = A.unitName("target")
    if not who then
        targetBtn:Hide()
        return
    end
    targetBtn.who = who
    local placeFilter = A.alertPlaceFilter and select(1, A.alertPlaceFilter()) or nil
    local matches = A.match(who.key, placeFilter)
    local mine = false
    for i = 1, #matches do
        if matches[i].owner == A.me.key then mine = true break end
    end
    targetBtn:SetText(mine and "FV*" or "FV")
    targetBtn:Show()
end

function A.buildTargetButton()
    if targetBtn or type(CreateFrame) ~= "function" then return end
    local parent = TargetFrame or UIParent
    targetBtn = CreateFrame("Button", "ForeverVendettaTargetButton", parent, "UIPanelButtonTemplate")
    targetBtn:SetSize(36, 22)
    if TargetFrame then
        targetBtn:SetPoint("TOPRIGHT", TargetFrame, "BOTTOMRIGHT", -8, 16)
    else
        targetBtn:SetPoint("CENTER", 0, 120)
    end
    targetBtn:SetText("FV")
    targetBtn:SetFrameStrata("MEDIUM")
    targetBtn:Hide()
    targetBtn:SetScript("OnClick", function(self)
        local who = self.who or A.unitName("target")
        if not who then
            A.print("Target an enemy player first.")
            return
        end
        local place = A.alertPlaceFilter and select(2, A.alertPlaceFilter()) or "world"
        if place ~= "battleground" then place = "world" end
        A.openEnemyDraft(who, "", "AVENGE", place)
        A.print("Opened " .. who.name .. " in Forever Vendetta.")
    end)
    targetBtn:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Forever Vendetta", 1, .44, .33)
        GameTooltip:AddLine("Open a report for this enemy. FV* means you already have one here.", .9, .9, .9, true)
        GameTooltip:Show()
    end)
    targetBtn:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    A.refreshTargetButton()
end

local function draftFromUnit(unit)
    if not A.ready then return end
    if not A.plain(unit, "string") or unit == "" then unit = "target" end
    if not A.flag(UnitExists, unit) or not A.flag(UnitIsPlayer, unit) then
        A.print("Right-click an enemy player.")
        return
    end
    if not A.flag(UnitIsEnemy, "player", unit) then
        A.print("That player is not an enemy.")
        return
    end
    local who = A.unitName(unit)
    if not who then
        A.print("Could not read that player's full name.")
        return
    end
    local place = A.alertPlaceFilter and select(2, A.alertPlaceFilter()) or "world"
    if place ~= "battleground" then place = "world" end
    A.openEnemyDraft(who, "", "AVENGE", place)
    A.print("Opened " .. who.name .. " in Forever Vendetta.")
end

local function menuShowsEnemy(unit)
    if not A.plain(unit, "string") then return false end
    return A.flag(UnitExists, unit) and A.flag(UnitIsPlayer, unit) and A.flag(UnitIsEnemy, "player", unit)
end

-- Classic UnitPopupButtons and modern Menu.ModifyMenu — whichever Forever exposes.
function A.hookUnitMenus()
    if A._unitMenusHooked then return end
    A._unitMenusHooked = true

    if type(UnitPopupButtons) == "table" and type(UnitPopupMenus) == "table" then
        UnitPopupButtons.FOREVER_VENDETTA = { text = "Add to Forever Vendetta", dist = 0 }
        local function inject(menuName)
            local menu = UnitPopupMenus[menuName]
            if type(menu) ~= "table" then return end
            for i = 1, #menu do
                if menu[i] == "FOREVER_VENDETTA" then return end
            end
            local at = #menu
            for i = 1, #menu do
                if menu[i] == "CANCEL" then at = i; break end
            end
            table.insert(menu, at, "FOREVER_VENDETTA")
        end
        for _, name in ipairs({ "TARGET", "FOCUS", "ENEMY_PLAYER", "OTHERENEMYPLAYER" }) do
            inject(name)
        end
        if type(hooksecurefunc) == "function" and type(UnitPopup_OnClick) == "function" then
            hooksecurefunc("UnitPopup_OnClick", function(self)
                local value = self and (self.value or self.arg1)
                if value ~= "FOREVER_VENDETTA" then return end
                local unit = (UIDROPDOWNMENU_INIT_MENU and UIDROPDOWNMENU_INIT_MENU.unit)
                    or (self and self.unit)
                    or "target"
                draftFromUnit(unit)
            end)
        end
    end

    if Menu and type(Menu.ModifyMenu) == "function" then
        local function addEntry(_, rootDescription, contextData)
            local unit = contextData and contextData.unit
            if not menuShowsEnemy(unit) then return end
            if rootDescription.CreateDivider then rootDescription:CreateDivider() end
            rootDescription:CreateButton("Add to Forever Vendetta", function()
                draftFromUnit(unit)
            end)
        end
        for _, tag in ipairs({
            "MENU_UNIT_TARGET", "MENU_UNIT_PLAYER", "MENU_UNIT_FOCUS",
            "MENU_UNIT_ENEMY_PLAYER", "MENU_UNIT_OTHER_ENEMY_PLAYER",
            "MENU_UNIT_PARTY", "MENU_UNIT_RAID_PLAYER",
        }) do
            pcall(Menu.ModifyMenu, tag, addEntry)
        end
    end
end
