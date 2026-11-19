local _, A = ...
local unpack = unpack or table.unpack
-- One charcoal ledger inside the normal WoW frame.
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
local CLASS_COORDS = {
    WARRIOR = { 0, .25, 0, .25 }, MAGE = { .25, .49609375, 0, .25 },
    ROGUE = { .49609375, .7421875, 0, .25 }, DRUID = { .7421875, .98828125, 0, .25 },
    HUNTER = { 0, .25, .25, .5 }, SHAMAN = { .25, .49609375, .25, .5 },
    PRIEST = { .49609375, .7421875, .25, .5 }, WARLOCK = { .7421875, .98828125, .25, .5 },
    PALADIN = { 0, .25, .5, .75 }, DEATHKNIGHT = { .25, .49609375, .5, .75 },
}
local RACE_COORDS = {
    HUMAN_MALE = { 0, .125, 0, .25 }, DWARF_MALE = { .125, .25, 0, .25 },
    GNOME_MALE = { .25, .375, 0, .25 }, NIGHTELF_MALE = { .375, .5, 0, .25 },
    TAUREN_MALE = { .5, .625, 0, .25 }, SCOURGE_MALE = { .625, .75, 0, .25 },
    TROLL_MALE = { .75, .875, 0, .25 }, ORC_MALE = { .875, 1, 0, .25 },
    HUMAN_FEMALE = { 0, .125, .25, .5 }, DWARF_FEMALE = { .125, .25, .25, .5 },
    GNOME_FEMALE = { .25, .375, .25, .5 }, NIGHTELF_FEMALE = { .375, .5, .25, .5 },
    TAUREN_FEMALE = { .5, .625, .25, .5 }, SCOURGE_FEMALE = { .625, .75, .25, .5 },
    TROLL_FEMALE = { .75, .875, .25, .5 }, ORC_FEMALE = { .875, 1, .25, .5 },
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

local STANCES = {
    { id = "AVENGE", label = "Avenge", color = { 1, .40, .32 }, hint = "You want another fight with this player." },
    { id = "AVOID", label = "Avoid", color = { 1, .73, .30 }, hint = "Warn your friends to give this player space." },
    { id = "WATCH", label = "Watch", color = { .36, .77, .94 }, hint = "Keep an eye on this player." },
}
local panel, banner, pages, nav, ui = nil, nil, {}, {}, {}
local rows, friendRows, filters, stanceButtons, historyBlocks = {}, {}, {}, {}, {}
local view, page, friendPage, filter, mode = "enemies", 1, 1, "ALL", "AVENGE"
local selected, selectedRealm, filling, armedFriend, armedWithdraw
local selectEnemy, refreshEditor

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
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
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

local function feedback(msg, bad)
    if ui.feedback then
        ui.feedback:SetTextColor(unpack(bad and STANCES[1].color or GOLD))
        ui.feedback:SetText(msg)
    end
end

local function switch(to)
    feedback("")
    view = to
    armedFriend, armedWithdraw = nil, nil
    for id, p in pairs(pages) do p:SetShown(panel:IsShown() and id == view) end
    A.refresh()
end

-- Group presentation only. Each author's stored report remains independent.
local function groups()
    local list, lookup = {}, {}
    for _, entry in ipairs(A.entries()) do
        local key = A.enemyName(entry.key)
        local g = lookup[key]
        if not g then
            g = { key = key, name = entry.report.name, reports = {}, modes = {} }
            lookup[key] = g
            list[#list + 1] = g
        end
        g.reports[#g.reports + 1] = entry
        g.modes[entry.report.mode] = true
    end
    table.sort(list, function(a, b) return a.key < b.key end)
    return list, lookup
end

local function ownReport(g)
    if g then
        for _, e in ipairs(g.reports) do
            if e.owner == A.me.key then return e.report end
        end
    end
end

local function stanceInfo(id)
    for _, s in ipairs(STANCES) do
        if s.id == id then return s end
    end
    return STANCES[1]
end

local function reportSummary(g)
    local n = #g.reports
    local own = ownReport(g)
    if n == 1 then
        local entry = g.reports[1]
        if entry.owner == A.me.key then return "1 report · yours" end
        return "1 report · " .. shorten(A.personName(entry.owner), 18)
    end
    if own then return n .. " reports · yours + friends" end
    return n .. " reports · friends"
end

local function ensureHistoryBlock(index)
    local block = historyBlocks[index]
    if block then return block end
    block = CreateFrame("Frame", nil, ui.historyChild)
    block:SetSize(280, 50)
    block.bg = rect(block, 0, 0, 280, 50, ROW)
    block.stripe = rect(block, 0, 0, 3, 50, STANCES[1].color, "ARTWORK")
    block.who = text(block, "", 10, 5, 260, "GameFontNormalSmall", GOLD)
    block.body = text(block, "", 10, 22, 260, "GameFontHighlightSmall", INK)
    block.who:SetWordWrap(false)
    block.body:SetWordWrap(true)
    historyBlocks[index] = block
    return block
end

local function newReport()
    selected, selectedRealm, armedWithdraw = nil, nil, nil
    filling = true
    ui.name:SetText("")
    ui.note:SetText("")
    filling = false
    mode = "AVENGE"
    ui.historyScroll:SetVerticalScroll(0)
    feedback("")
    A.refresh()
    ui.name:SetFocus()
end

selectEnemy = function(g)
    selected, armedWithdraw = g.key, nil
    local own = ownReport(g)
    selectedRealm = own and own.realm or A.realm()
    filling = true
    ui.name:SetText(g.name)
    -- Never silently copy another author's reason into your report.
    ui.note:SetText(own and own.note or "")
    filling = false
    mode = own and own.mode or "AVENGE"
    ui.historyScroll:SetVerticalScroll(0)
    feedback(own and "Editing your report. Your friends' reports stay separate." or "Read your friends' reports below, then add your own if you wish.")
    A.refresh()
end

local function showInList()
    filter = "ALL"
    ui.search:SetText("")
    local list = groups()
    for i, enemy in ipairs(list) do
        if enemy.key == selected then
            page = math.ceil(i / ROWS)
            break
        end
    end
    A.refresh()
end

local function saveReport()
    local who = A.sender(ui.name:GetText())
    if not who or not who.name:find("%s") then
        feedback("Enter a first name and surname, or use Add target.", true)
        ui.name:SetFocus()
        return
    end
    local ok, err = A.report(who.name, ui.note:GetText(), mode, false, selectedRealm)
    if not ok then
        feedback(err or "Could not save that report.", true)
        return
    end
    selected, selectedRealm = who.name:lower(), selectedRealm or who.realm
    armedWithdraw = nil
    ui.name:SetText(who.name)
    ui.name:ClearFocus()
    ui.note:ClearFocus()
    feedback("Saved on this character.")
    showInList()
end

local function useTarget()
    if not A.flag(UnitIsPlayer, "target") or not A.flag(UnitIsEnemy, "player", "target") then
        feedback("Select an enemy player in the game, then click Add target.", true)
        return
    end
    local who = A.unitName("target")
    if not who then
        feedback("That name is unavailable. Try outside combat or enter it yourself.", true)
        return
    end
    if A.rememberFace then A.rememberFace("target", who.key) end
    local _, lookup = groups()
    if lookup[who.name:lower()] then
        selectEnemy(lookup[who.name:lower()])
    else
        newReport()
        filling = true
        ui.name:SetText(who.name)
        filling = false
        selectedRealm = who.realm
    end
    switch("enemies")
    ui.note:SetFocus()

end

refreshEditor = function(lookup)
    local g = selected and lookup[selected]
    local own = ownReport(g)
    local chosen = stanceInfo(mode)
    ui.editorTitle:SetText(g and shorten(g.name, 28) or "Add your report")
    paintFace(ui.editorClass, ui.editorRace, g and A.faceFor and A.faceFor(g.key))
    if g then ui.name:Disable() else ui.name:Enable() end
    ui.save:SetText(own and "Save changes" or "Save report")
    ui.withdraw:SetEnabled(own ~= nil)
    ui.withdraw:SetText(armedWithdraw and "Confirm removal" or "Withdraw mine")
    for _, s in ipairs(STANCES) do
        local on = mode == s.id
        stanceButtons[s.id]:SetText((on and hexColor(s.color) or "") .. s.label .. (on and "|r" or ""))
        stanceButtons[s.id].mark:SetShown(on)
        if on then stanceButtons[s.id].mark:SetColorTexture(s.color[1], s.color[2], s.color[3], 1) end
    end
    ui.stanceHint:SetText(chosen.hint)
    ui.stanceHint:SetTextColor(unpack(chosen.color))

    ui.historyTitle:SetText(g and (#g.reports .. (#g.reports == 1 and " report on this enemy" or " reports on this enemy")) or "Reports from trusted friends")
    local y = 0
    if g and #g.reports > 0 then
        ui.historyEmpty:Hide()
        for i, entry in ipairs(g.reports) do
            local block = ensureHistoryBlock(i)
            local r = entry.report
            local s = stanceInfo(r.mode)
            local who = entry.owner == A.me.key and "You" or A.personName(entry.owner)
            local role = entry.owner == A.me.key and "yours" or "friend"
            block.who:SetText(shorten(who .. " · " .. s.label .. " · " .. role, 42))
            block.body:SetText(r.note ~= "" and r.note or "No reason provided.")
            block.stripe:SetColorTexture(s.color[1], s.color[2], s.color[3], 1)
            block:ClearAllPoints()
            block:SetPoint("TOPLEFT", 0, -y)
            block:Show()
            y = y + 54
        end
        for i = #g.reports + 1, #historyBlocks do historyBlocks[i]:Hide() end
    else
        for _, block in ipairs(historyBlocks) do block:Hide() end
        ui.historyEmpty:Show()
        ui.historyEmpty:SetText(g and "No active reports on this enemy." or "Select an enemy to read every report.\n\nYour reason stays separate from your friends' reasons.")
    end
    ui.historyChild:SetHeight(math.max(110, y > 0 and y or 110))
end

local function syncNote()
    local pending = A.pendingCount()
    if A.plain(A.lastSendError, "string") and A.lastSendError ~= "" then return A.lastSendError end
    if pending > 0 then
        return pending .. (pending == 1 and " message queued. " or " messages queued. ") .. "Both characters need to be online."
    end
    return "Reports catch up when both characters are online. No report yet means no time on that row."
end

function A.refresh()
    if not panel or not panel:IsShown() then return end
    if A.scanFaces then A.scanFaces() end
    local all, lookup = groups()
    local filtered, query = {}, ui.search:GetText():lower()
    for _, g in ipairs(all) do
        local haystack = g.name
        for _, e in ipairs(g.reports) do
            haystack = haystack .. " " .. e.report.note .. " " .. A.personName(e.owner)
        end
        if (filter == "ALL" or g.modes[filter]) and haystack:lower():find(query, 1, true) then
            filtered[#filtered + 1] = g
        end
    end
    local count = math.max(1, math.ceil(#filtered / ROWS))
    page = math.max(1, math.min(page, count))
    if view == "friends" then
        local friendsN = A.count(A.store.friends)
        ui.heading:SetText("Trusted friends")
        ui.summary:SetText(friendsN .. (friendsN == 1 and " character. " or " characters. ") .. "Both sides add each other.")
    elseif view == "alerts" then
        ui.heading:SetText("Warnings")
        ui.summary:SetText("Nameplates, target, focus, and mouseover.")
    else
        ui.heading:SetText("Enemy blacklist")
        ui.summary:SetText(#all .. (#all == 1 and " enemy" or " enemies") .. " · " .. #A.entries() .. " reports")
    end
    local manyPages = #filtered > ROWS
    ui.pagination:SetText(manyPages and ("Page " .. page .. " of " .. count) or "")
    ui.pagination:SetShown(manyPages)
    ui.prev:SetShown(manyPages)
    ui.next:SetShown(manyPages)
    ui.prev:SetEnabled(page > 1)
    ui.next:SetEnabled(page < count)
    if ui.addEnemy then ui.addEnemy:SetShown(view == "enemies") end
    if ui.addTarget then ui.addTarget:SetShown(view == "enemies") end
    ui.clearSearch:SetEnabled(query ~= "")
    for id, b in pairs(filters) do
        b.mark:SetShown(id == filter)
        b:SetText((id == filter and "|cffffd159" or "") .. b.caption .. (id == filter and "|r" or ""))
    end
    local selectionVisible = false
    for i, row in ipairs(rows) do
        local g = filtered[(page - 1) * ROWS + i]
        row.group = g
        row:SetShown(g ~= nil)
        if g then
            if selected == g.key then selectionVisible = true end
            row.name:SetText(shorten(g.name, 24))
            paintFace(row.classIcon, row.raceIcon, A.faceFor and A.faceFor(g.key))
            local mixed = A.count(g.modes) > 1
            local s = stanceInfo(g.modes.AVOID and "AVOID" or (g.modes.AVENGE and "AVENGE" or "WATCH"))
            row.tag:SetText(mixed and "Mixed" or s.label)
            local color = mixed and MUTED or s.color
            row.tag:SetTextColor(unpack(color))
            row.stripe:SetColorTexture(color[1], color[2], color[3], 1)
            row.detail:SetText(reportSummary(g))
            row.name:SetTextColor(unpack(INK))
            row.detail:SetTextColor(unpack(INK_MUTED))
            row.bg:SetColorTexture(unpack(selected == g.key and ROW_ON or ROW))
        end
    end
    ui.empty:SetShown(#filtered == 0)
    ui.emptyTitle:SetText(#all == 0 and "No enemies yet" or "No enemies match")
    ui.emptyBody:SetText(#all == 0 and "Add target, or type a full name." or "Clear the search, or set the filter to All.")
    ui.reveal:SetShown(lookup[selected] ~= nil and not selectionVisible)
    refreshEditor(lookup)
    for id, b in pairs(nav) do
        local on = view == id
        if type(b.mark) == "table" then b.mark:SetShown(on) end
        if b.classic and b.bg and b.bg.SetTexture then
            b.bg:SetTexture(on and "Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab" or "Interface\\PaperDollInfoFrame\\UI-Character-InActiveTab")
        elseif b.bg then
            b.bg:SetColorTexture(unpack(on and ROW_ON or BUTTON_FACE.quiet))
        end
        b:SetText(b.caption)
    end
    local friends = {}
    for _, peer in pairs(A.store.friends) do friends[#friends + 1] = peer end
    table.sort(friends, function(a, b) return a.name < b.name end)
    local maxFriends = math.max(1, math.ceil(#friends / 7))
    friendPage = math.max(1, math.min(friendPage, maxFriends))
    local manyFriends = #friends > 7
    ui.friendPagination:SetText(manyFriends and ("Page " .. friendPage .. " of " .. maxFriends) or "")
    ui.friendPagination:SetShown(manyFriends)
    ui.friendPrev:SetShown(manyFriends)
    ui.friendNext:SetShown(manyFriends)
    ui.sync:SetEnabled(#friends > 0)
    ui.friendPrev:SetEnabled(friendPage > 1)
    ui.friendNext:SetEnabled(friendPage < maxFriends)
    ui.friendEmpty:SetShown(#friends == 0)
    for i, row in ipairs(friendRows) do
        local peer = friends[(friendPage - 1) * 7 + i]
        row.peer = peer
        row:SetShown(peer ~= nil)
        if peer then
            local n = 0
            for _, r in pairs(A.store.reports[peer.key] or {}) do
                if not r.deleted then n = n + 1 end
            end
            row.name:SetText(shorten(peer.name, 28))
            row.name:SetTextColor(unpack(INK))
            local received = A.store.lastReceived and A.store.lastReceived[peer.key]
            local stamp = received and A.call(date, "%d %b %H:%M", received)
            local status = n .. (n == 1 and " active report" or " active reports")
            if stamp then status = status .. " · Last report " .. stamp end
            row.detail:SetText(shorten(status, 42))
            row.detail:SetTextColor(unpack(INK_MUTED))
            row.remove:SetText(armedFriend == peer.key and "Confirm" or "Remove")
        end
    end
    for key, c in pairs(ui.checks) do c:SetChecked(A.store.settings[key] == true) end
    if ui.soundButtons then
        local current = A.soundById(A.store.settings.alertSound)
        current = current and current.id
        for id, b in pairs(ui.soundButtons) do
            local on = id == current
            if type(b.mark) == "table" then b.mark:SetShown(on) end
            b:SetText((on and hexColor(GOLD) or "") .. b.caption .. (on and "|r" or ""))
        end
    end
    ui.cooldownLabel:SetText(A.store.settings.cooldown .. " seconds")
    if ui.cooldown:GetValue() ~= A.store.settings.cooldown then ui.cooldown:SetValue(A.store.settings.cooldown) end
    if view == "alerts" then
        ui.footer:SetText((A.store.settings.instances and "Alerts in all zones" or "Open-world alerts") .. " · " .. A.store.settings.cooldown .. "s cooldown")
    elseif view == "friends" then
        ui.footer:SetText("")
    else
        ui.footer:SetText("")
    end
    if ui.syncNote then ui.syncNote:SetText(syncNote()) end
end

local function buildEnemies()
    local p = pages.enemies
    local list = box(p, 16, 112, 360, 336)
    ui.search = edit(list, 10, 10, 210, 96)
    tip(ui.search, "Search blacklist", "Find an enemy, a reporting friend, or words in a reason.")
    ui.search:SetScript("OnTextChanged", function() page = 1; A.refresh() end)
    placeholder(ui.search, "Search names or reasons...")
    ui.clearSearch = button(list, "Clear search", 210, 10, 106, function() ui.search:SetText("") end)
    ui.search:SetWidth(192)
    for i, item in ipairs({ { "ALL", "All" }, { "AVENGE", "Avenge" }, { "AVOID", "Avoid" }, { "WATCH", "Watch" } }) do
        local id, caption = item[1], item[2]
        local b = button(list, caption, 10 + (i - 1) * 78, 44, 74, function()
            filter = id
            page = 1
            A.refresh()
        end)
        b.caption = caption
        b.mark = rect(b, 4, 22, 66, 2, { 1, .75, .22, 1 }, "OVERLAY")
        filters[id] = b
    end
    for i = 1, ROWS do
        local row = CreateFrame("Button", nil, list)
        row:SetPoint("TOPLEFT", 10, -78 - (i - 1) * 38)
        row:SetSize(340, 34)
        row.bg = rect(row, 0, 0, 340, 34, ROW)
        row.stripe = rect(row, 0, 0, 3, 34, { .72, .18, .12, 1 }, "ARTWORK")
        row.classIcon = row:CreateTexture(nil, "ARTWORK")
        row.classIcon:SetSize(18, 18)
        row.classIcon:SetPoint("TOPLEFT", 8, -8)
        row.classIcon:Hide()
        row.raceIcon = row:CreateTexture(nil, "ARTWORK")
        row.raceIcon:SetSize(18, 18)
        row.raceIcon:SetPoint("LEFT", row.classIcon, "RIGHT", 2, 0)
        row.raceIcon:Hide()
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.name = text(row, "", 48, 3, 190, "GameFontHighlight", INK)
        row.detail = text(row, "", 48, 18, 190, "GameFontHighlightSmall", INK_MUTED)
        row.tag = text(row, "", 248, 10, 84, "GameFontNormalSmall")
        row.name:SetWordWrap(false)
        row.detail:SetWordWrap(false)
        row.tag:SetWordWrap(false)
        row:SetScript("OnEnter", function(self)
            if not self.group or not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.group.name, unpack(GOLD))
            GameTooltip:AddLine("Click to read every report and edit your own.", .9, .9, .9, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            if GameTooltip then GameTooltip:Hide() end
        end)
        row:SetScript("OnClick", function(self)
            if self.group then selectEnemy(self.group) end
        end)
        rows[i] = row
    end
    ui.empty = CreateFrame("Frame", nil, list)
    ui.empty:SetPoint("TOPLEFT", 18, -130)
    ui.empty:SetSize(290, 140)
    ui.emptyTitle = text(ui.empty, "", 0, 0, 280, "GameFontNormalLarge", GOLD)
    ui.emptyBody = text(ui.empty, "", 0, 32, 280, "GameFontHighlight", INK_MUTED)
    ui.prev = button(list, "Previous", 8, 316, 72, function() page = page - 1; A.refresh() end)
    ui.pagination = text(list, "", 84, 322, 70, "GameFontHighlightSmall", INK_MUTED)
    ui.reveal = button(list, "Show in list", 152, 316, 100, showInList)
    ui.next = button(list, "Next", 256, 316, 64, function() page = page + 1; A.refresh() end)

    local e = box(p, 388, 112, 316, 336)
    ui.editorClass = e:CreateTexture(nil, "ARTWORK")
    ui.editorClass:SetSize(20, 20)
    ui.editorClass:SetPoint("TOPLEFT", 12, -8)
    ui.editorClass:Hide()
    ui.editorRace = e:CreateTexture(nil, "ARTWORK")
    ui.editorRace:SetSize(20, 20)
    ui.editorRace:SetPoint("LEFT", ui.editorClass, "RIGHT", 3, 0)
    ui.editorRace:Hide()
    ui.editorTitle = text(e, "Add your report", 58, 10, 270, "GameFontNormal", GOLD)
    ui.editorTitle:SetWordWrap(false)
    text(e, "Enemy full name", 12, 30, 300, "GameFontHighlightSmall", INK_MUTED)
    ui.name = edit(e, 12, 44, 290, 64)
    ui.name:SetScript("OnTextChanged", function(_, user)
        if user and not filling then
            selected, selectedRealm, armedWithdraw = nil, nil, nil
            A.refresh()
        end
    end)
    ui.name:SetScript("OnEnterPressed", function() ui.note:SetFocus() end)
    ui.name:SetScript("OnTabPressed", function() ui.note:SetFocus() end)
    placeholder(ui.name, "First name and surname")
    for i, s in ipairs(STANCES) do
        local b = button(e, s.label, 12 + (i - 1) * 102, 78, 96, function()
            mode = s.id
            A.refresh()
        end)
        b.mark = rect(b, 5, 22, 86, 2, s.color, "OVERLAY")
        tip(b, s.label, s.hint)
        stanceButtons[s.id] = b
    end
    ui.stanceHint = text(e, STANCES[1].hint, 12, 106, 300, "GameFontHighlightSmall", STANCES[1].color)
    text(e, "Reason (optional)", 12, 124, 300, "GameFontHighlightSmall", INK_MUTED)
    local noteScroll = CreateFrame("ScrollFrame", nil, e)
    noteScroll:SetPoint("TOPLEFT", 12, -138)
    noteScroll:SetSize(290, 40)
    rect(noteScroll, 0, 0, 290, 40, { .05, .05, .06, 1 })
    ui.note = edit(noteScroll, 0, 0, 290, 96, true)
    noteScroll:SetScrollChild(ui.note)
    ui.note:SetScript("OnTabPressed", function() ui.name:SetFocus() end)
    ui.note:SetScript("OnCursorChanged", function(_, _, y, _, height)
        local current = noteScroll:GetVerticalScroll()
        if not A.plain(current, "number") then current = 0 end
        local bottom = -y + height
        if -y < current then noteScroll:SetVerticalScroll(-y)
        elseif bottom > current + 40 then noteScroll:SetVerticalScroll(bottom - 40) end
    end)
    ui.save = button(e, "Save report", 12, 186, 146, saveReport, "primary")
    ui.withdraw = button(e, "Withdraw mine", 168, 186, 148, function()
        local _, lookup = groups()
        local own = ownReport(selected and lookup[selected])
        if not own then return end
        if armedWithdraw ~= selected then
            armedWithdraw = selected
            feedback("Click Confirm removal to withdraw only your report.")
            A.refresh()
            return
        end
        local ok, err = A.report(own.name, own.note, own.mode, true, own.realm)
        armedWithdraw = nil
        feedback(ok and "Your report was withdrawn. Your friends' reports stay." or err, not ok)
        if ok then ui.note:SetText("") end
        A.refresh()
    end, "danger")
    tip(ui.withdraw, "Withdraw your report", "Only your current character's report is removed. Friends' reports remain. Click twice to confirm.")
    ui.historyTitle = text(e, "Reports from trusted friends", 12, 218, 300, "GameFontNormalSmall", GOLD)
    local scroll = CreateFrame("ScrollFrame", nil, e, "UIPanelScrollFrameTemplate")
    ui.historyScroll = scroll
    scroll:SetPoint("TOPLEFT", 12, -234)
    scroll:SetSize(284, 100)
    ui.historyChild = CreateFrame("Frame", nil, scroll)
    ui.historyChild:SetSize(284, 90)
    scroll:SetScrollChild(ui.historyChild)
    ui.historyEmpty = text(ui.historyChild, "", 0, 0, 270, "GameFontHighlightSmall", INK_MUTED)
end

local function buildFriends()
    local p = pages.friends
    local list = box(p, 16, 112, 360, 336)
    text(list, "These characters exchange reports with you.", 12, 8, 330, "GameFontHighlightSmall", INK_MUTED)
    for i = 1, 7 do
        local row = CreateFrame("Frame", nil, list)
        row:SetPoint("TOPLEFT", 10, -32 - (i - 1) * 36)
        row:SetSize(340, 32)
        rect(row, 0, 0, 340, 32, ROW)
        row.name = text(row, "", 8, 2, 210, "GameFontHighlight", INK)
        row.detail = text(row, "", 8, 16, 210, "GameFontHighlightSmall", INK_MUTED)
        row.name:SetWordWrap(false)
        row.detail:SetWordWrap(false)
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            if self.peer and GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.peer.name)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        row.remove = button(row, "Remove", 268, 5, 64, function()
            if not row.peer then return end
            if armedFriend ~= row.peer.key then
                armedFriend = row.peer.key
                feedback("Click Confirm to stop sharing and hide this friend's reports.")
                A.refresh()
                return
            end
            local name = row.peer.name
            A.untrust(name)
            armedFriend = nil
            A.refresh()
            feedback(name .. " removed from trusted friends.")
        end, "danger")
        friendRows[i] = row
    end
    ui.friendEmpty = text(list, "No trusted friends yet.\nAdd a full name on the right.", 16, 48, 320, "GameFontHighlight", INK_MUTED)
    ui.friendPrev = button(list, "Previous", 8, 316, 72, function() friendPage = friendPage - 1; A.refresh() end)
    ui.friendPagination = text(list, "", 88, 322, 140, "GameFontHighlightSmall", INK_MUTED)
    ui.friendNext = button(list, "Next", 236, 316, 80, function() friendPage = friendPage + 1; A.refresh() end)

    local setup = box(p, 388, 112, 316, 336)
    text(setup, "Add a trusted friend", 12, 8, 300, "GameFontNormal", GOLD)
    ui.friendName = edit(setup, 12, 32, 290, 112)
    placeholder(ui.friendName, "First name and surname")
    local function addFriend()
        local who = A.sender(ui.friendName:GetText())
        if not who or not who.name:find("%s") then
            feedback("Enter your friend's first name and surname.", true)
            return
        end
        local ok, err = A.trust(ui.friendName:GetText())
        feedback(ok and "Friend added. They must add your character too." or err, not ok)
        if ok then
            ui.friendName:SetText("")
            ui.friendName:ClearFocus()
            A.sync()
            if ui.syncNote then ui.syncNote:SetText(syncNote()) end
        end
    end
    button(setup, "Add trusted friend", 12, 66, 290, addFriend, "primary")
    ui.friendName:SetScript("OnEnterPressed", addFriend)
    text(setup, "They add this character too. Sharing is a whisper, not Battle.net.", 12, 100, 290, "GameFontHighlightSmall", INK_MUTED)
    text(setup, A.me.name, 12, 132, 290, "GameFontNormal", GOLD)
    ui.sync = button(setup, "Sync with friends", 12, 168, 290, function()
        A.sync()
        local note = syncNote()
        feedback(note, A.plain(A.lastSendError, "string") and A.lastSendError ~= "")
        if ui.syncNote then ui.syncNote:SetText(note) end
    end)
    ui.syncNote = text(setup, "", 12, 202, 290, "GameFontHighlightSmall", INK_MUTED)
end

local function buildAlerts()
    local p = pages.alerts
    local settings = box(p, 16, 112, 360, 336)
    text(settings, "Sound and banner", 12, 8, 300, "GameFontNormal", GOLD)
    text(settings, "Where it can see them", 12, 188, 300, "GameFontNormal", GOLD)

    ui.checks = {}
    for i, spec in ipairs({
        { "sound", "Play a warning sound", "The sound chosen on the right, on the Master channel." },
        { "banner", "Show an on-screen warning", "Six-second banner with the enemy and one reason." },
        { "instances", "Also warn inside instances", "Off by default. Client limits still apply." },
    }) do
        local c = CreateFrame("CheckButton", nil, settings, "UICheckButtonTemplate")
        c:SetPoint("TOPLEFT", 10, -81 - (i - 1) * 58)
        c:SetSize(26, 26)
        text(c, spec[2], 30, 2, 270, "GameFontHighlight", INK)
        text(c, spec[3], 30, 18, 270, "GameFontHighlightSmall", INK_MUTED)
        c:SetScript("OnClick", function(self)
            A.store.settings[spec[1]] = self:GetChecked() == true
            A.changed()
        end)
        ui.checks[spec[1]] = c
    end
    local help = box(p, 388, 112, 316, 336)
    text(help, "Chat", 12, 8, 280, "GameFontNormal", GOLD)
    text(help, "Chat always prints the enemy and stance. The reason stays on the banner.", 12, 30, 290, "GameFontHighlightSmall", INK_MUTED)
    text(help, "Warning sound", 12, 68, 200, "GameFontNormal", GOLD)
    ui.soundButtons = {}
    for i, sound in ipairs(A.ALERT_SOUNDS) do
        local col = (i - 1) % 3
        local row = math.floor((i - 1) / 3)
        local b = button(help, sound.label, 12 + col * 98, 90 + row * 28, 92, function()
            A.store.settings.alertSound = sound.id
            A.playSound()
            A.changed()
        end)
        b.caption = sound.label
        b.soundId = sound.id
        b.mark = rect(b, 8, 20, 76, 2, GOLD, "OVERLAY")
        b.mark:Hide()
        ui.soundButtons[sound.id] = b
    end
    text(help, "Repeat the same enemy", 12, 158, 180, "GameFontNormal", GOLD)
    ui.cooldownLabel = text(help, "", 198, 158, 100, "GameFontNormal", GOLD)
    local slider = CreateFrame("Slider", nil, help, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 16, -186)
    slider:SetSize(250, 18)
    slider:SetMinMaxValues(10, 600)
    slider:SetValueStep(10)
    slider:SetObeyStepOnDrag(true)
    slider:SetScript("OnValueChanged", function(_, value)
        local v = math.max(10, math.min(600, math.floor(value + .5)))
        if A.store.settings.cooldown ~= v then
            A.store.settings.cooldown = v
            A.changed()
        end
    end)
    ui.cooldown = slider
    text(help, "10 seconds", 12, 210, 100, "GameFontHighlightSmall", INK_MUTED)
    text(help, "10 minutes", 180, 210, 100, "GameFontHighlightSmall", INK_MUTED)
    text(help, "Nameplates give the earliest warning. Target, focus, and mouseover count too.", 12, 232, 290, "GameFontHighlightSmall", INK_MUTED)
    button(help, "Preview alert", 12, 278, 290, function()
        A.testAlert()
        feedback("Test alert played using your current settings.")
    end, "primary")
end

local function dressMetal(frame)
    local slice = frame.NineSlice
    if type(slice) ~= "table" then return end
    local corners = {
        TopLeftCorner = { 0.525390625, 0.783203125, 0.001953125, 0.259765625 },
        TopRightCorner = { 0.001953125, 0.259765625, 0.263671875, 0.521484375 },
        BottomLeftCorner = { 0.001953125, 0.259765625, 0.001953125, 0.259765625 },
        BottomRightCorner = { 0.263671875, 0.521484375, 0.001953125, 0.259765625 },
    }
    for key, coords in pairs(corners) do
        local tex = slice[key]
        if type(tex) == "table" and tex.SetTexture then
            tex:SetTexture("Interface\\FrameGeneral\\UIFrameMetal")
            if tex.SetTexCoord then tex:SetTexCoord(coords[1], coords[2], coords[3], coords[4]) end
        end
    end
    local edges = {
        TopEdge = { "Interface\\FrameGeneral\\UIFrameMetalHorizontal", 0, 1, 0.263671875, 0.357421875 },
        BottomEdge = { "Interface\\FrameGeneral\\UIFrameMetalHorizontal", 0, 1, 0.001953125, 0.259765625 },
        LeftEdge = { "Interface\\FrameGeneral\\UIFrameMetalVertical", 0.001953125, 0.259765625, 0, 1 },
        RightEdge = { "Interface\\FrameGeneral\\UIFrameMetalVertical", 0.263671875, 0.521484375, 0, 1 },
    }
    for key, spec in pairs(edges) do
        local tex = slice[key]
        if type(tex) == "table" and tex.SetTexture then
            tex:SetTexture(spec[1])
            if tex.SetTexCoord then tex:SetTexCoord(spec[2], spec[3], spec[4], spec[5]) end
            if key == "TopEdge" or key == "BottomEdge" then
                if tex.SetHorizTile then tex:SetHorizTile(true) end
            elseif tex.SetVertTile then
                tex:SetVertTile(true)
            end
        end
    end
end

local function build()
    panel = CreateFrame("Frame", "ForeverVendettaWindow", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(W, H)
    panel:SetPoint("CENTER")
    fit(panel, W, H)
    if panel.TitleText then panel.TitleText:SetText("Forever Vendetta") end
    panel:SetMovable(true)
    panel:EnableMouse(true)
    local drag = CreateFrame("Frame", nil, panel)
    drag:SetPoint("TOPLEFT", 8, -2)
    drag:SetSize(W - 40, 26)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() panel:StartMoving() end)
    drag:SetScript("OnDragStop", function() panel:StopMovingOrSizing() end)
    if UISpecialFrames then table.insert(UISpecialFrames, "ForeverVendettaWindow") end

    dressMetal(panel)
    local host = type(panel.Inset) == "table" and panel.Inset or panel
    local wash = host:CreateTexture(nil, "BACKGROUND")
    wash:SetColorTexture(.05, .045, .04, 1)
    wash:SetPoint("TOPLEFT", 2, -2)
    wash:SetPoint("BOTTOMRIGHT", -2, 2)
    local rock = host:CreateTexture(nil, "BORDER")
    rock:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock")
    rock:SetPoint("TOPLEFT", 4, -4)
    rock:SetPoint("BOTTOMRIGHT", -4, 4)
    if rock.SetHorizTile then rock:SetHorizTile(true) end
    if rock.SetVertTile then rock:SetVertTile(true) end

    ui.heading = text(panel, "Enemy blacklist", 20, 34, 280, "GameFontNormal", GOLD)
    ui.summary = text(panel, "", 20, 54, 420, "GameFontHighlightSmall", INK_MUTED)
    ui.addEnemy = button(panel, "Add enemy", 468, 34, 112, function() switch("enemies"); newReport() end, "primary")
    ui.addTarget = button(panel, "Add target", 588, 34, 112, useTarget, "primary")

    for i, item in ipairs({ { "enemies", "Blacklist" }, { "friends", "Friends" }, { "alerts", "Alerts" } }) do
        local id, caption = item[1], item[2]
        local p = CreateFrame("Frame", id == "friends" and "ForeverVendettaFriends" or nil, panel)
        p:SetPoint("TOPLEFT", 0, 0)
        p:SetSize(W, H)
        p:Hide()
        pages[id] = p
        local b = CreateFrame("Button", nil, panel)
        b:SetPoint("TOPLEFT", 18 + (i - 1) * 128, -72)
        b:SetSize(120, 32)
        b.caption = caption
        b.classic = true
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints()
        b.bg:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InActiveTab")
        local label = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("CENTER", 0, 2)
        b:SetFontString(label)
        b:SetText(caption)
        b:SetScript("OnClick", function() switch(id) end)
        nav[id] = b
    end

    rect(panel, 376, 112, 1, 336, { .45, .34, .18, .45 }, "ARTWORK")

    buildEnemies()
    buildFriends()
    buildAlerts()
    ui.feedback = text(panel, "", 20, 458, 360, "GameFontHighlightSmall", GOLD)
    ui.footer = text(panel, "", 390, 458, 310, "GameFontHighlightSmall", INK_MUTED)
    panel:SetScript("OnHide", function()
        for _, p in pairs(pages) do p:Hide() end
        armedFriend, armedWithdraw = nil, nil
    end)
    panel:Hide()
end

function A.toggle()
    if not panel then build() end
    if panel:IsShown() then
        panel:Hide()
        for _, p in pairs(pages) do p:Hide() end
    else
        panel:Show()
        switch(view)
    end
end

function A.toggleFriends()
    if not panel then build() end
    if panel:IsShown() and view == "friends" then
        panel:Hide()
        for _, p in pairs(pages) do p:Hide() end
    else
        panel:Show()
        switch("friends")
    end
end

function A.showBanner(title, detail, preview, mode, face)
    if not banner then
        banner = CreateFrame("Frame", nil, UIParent)
        banner:SetSize(620, 86)
        banner:SetPoint("TOP", 0, -70)
        fit(banner, 620, 86)
        banner:SetFrameStrata("HIGH")
        banner:EnableMouse(false)
        local plate = banner:CreateTexture(nil, "BACKGROUND")
        plate:SetAllPoints()
        plate:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock")
        if plate.SetHorizTile then plate:SetHorizTile(true) end
        if plate.SetVertTile then plate:SetVertTile(true) end
        rect(banner, 0, 0, 620, 86, { .04, .04, .045, .55 })
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
        banner.accent = rect(banner, 0, 0, 4, 86, GOLD, "ARTWORK")
        banner.classIcon = banner:CreateTexture(nil, "OVERLAY")
        banner.classIcon:SetSize(28, 28)
        banner.classIcon:SetPoint("LEFT", 16, 4)
        banner.classIcon:Hide()
        banner.raceIcon = banner:CreateTexture(nil, "OVERLAY")
        banner.raceIcon:SetSize(28, 28)
        banner.raceIcon:SetPoint("LEFT", banner.classIcon, "RIGHT", 4, 0)
        banner.raceIcon:Hide()
        banner.heading = text(banner, "", 18, 8, 560, "GameFontNormalSmall", MUTED)
        banner.title = text(banner, "", 18, 26, 560, "GameFontNormalLarge", GOLD)
        banner.detail = text(banner, "", 18, 52, 560, "GameFontHighlightSmall", WHITE)
        banner.remaining = 0
        banner:Hide()
        banner:SetScript("OnUpdate", function(self, dt)
            self.remaining = (self.remaining or 0) - (dt or 0)
            self:SetAlpha(math.min(1, math.max(0, self.remaining / .6)))
            if self.remaining <= 0 then self:Hide() end
        end)
    end
    local color = { 1, .82, .35 }
    for _, s in ipairs(STANCES) do
        if s.id == mode then color = s.color break end
    end
    banner.accent:SetColorTexture(color[1], color[2], color[3], 1)
    banner.title:SetTextColor(unpack(color))
    paintFace(banner.classIcon, banner.raceIcon, face)
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
    banner.remaining = 6
    banner:SetAlpha(1)
    banner:Show()
end
