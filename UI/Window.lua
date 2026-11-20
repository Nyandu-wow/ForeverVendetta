local _, A = ...
local unpack = unpack or table.unpack
local UI = A.UI

local ctx = {
    panel = nil,
    pages = {},
    nav = {},
    ui = {},
    rows = {},
    friendRows = {},
    filters = {},
    stanceButtons = {},
    historyBlocks = {},
    attackerButtons = {},
    view = "world",
    page = 1,
    friendPage = 1,
    filter = "ALL",
    mode = "AVENGE",
    selected = nil,
    selectedRealm = nil,
    filling = nil,
    armedFriend = nil,
    armedWithdraw = nil,
}
A._win = ctx

function A.listPlace()
    return A.tabPlace(ctx.view)
end

local function onList()
    return ctx.view == "world" or ctx.view == "battlegrounds"
end

-- One charcoal ledger inside the normal WoW frame.
ctx.feedback = function(msg, bad)
    if ctx.ui.feedback then
        ctx.ui.feedback:SetTextColor(unpack(bad and UI.STANCES[1].color or UI.GOLD))
        ctx.ui.feedback:SetText(msg)
    end
end

ctx.switch = function(to)
    ctx.feedback("")
    ctx.view = to
    ctx.armedFriend, ctx.armedWithdraw = nil, nil
    local showList = to == "world" or to == "battlegrounds"
    for id, p in pairs(ctx.pages) do
        if id == "enemies" then p:SetShown(ctx.panel:IsShown() and showList)
        else p:SetShown(ctx.panel:IsShown() and id == ctx.view) end
    end
    A.refresh()
end

-- Group presentation only. Each author's stored report remains independent.
local function groups()
    local list, lookup = {}, {}
    local place = A.listPlace()
    for _, entry in ipairs(A.entries(place)) do
        local enemyKey = A.splitSlot(entry.key)
        local key = A.enemyName(entry.key)
        local g = lookup[key]
        if not g then
            g = { key = key, enemyKey = enemyKey, name = entry.report.name, reports = {}, modes = {}, place = place }
            lookup[key] = g
            list[#list + 1] = g
        end
        g.reports[#g.reports + 1] = entry
        g.modes[entry.report.mode] = true
    end
    local function seenTs(g)
        local enemyKey = g.enemyKey
        if not enemyKey and g.reports and g.reports[1] then enemyKey = A.splitSlot(g.reports[1].key) end
        if not enemyKey or not A.sightingFor then return 0 end
        local seen = A.sightingFor(enemyKey, g.place or place)
        return seen and (tonumber(seen.ts) or 0) or 0
    end
    table.sort(list, function(a, b)
        local sa, sb = seenTs(a), seenTs(b)
        if sa ~= sb then return sa > sb end
        return a.key < b.key
    end)
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
    for _, s in ipairs(UI.STANCES) do
        if s.id == id then return s end
    end
    return UI.STANCES[1]
end

local function scoreText(g)
    if not (A.scoreFor and g) then return "" end
    local enemyKey = g.enemyKey
    if not enemyKey and g.reports and g.reports[1] then enemyKey = A.splitSlot(g.reports[1].key) end
    if not enemyKey then return "" end
    local score = A.scoreFor(enemyKey, g.place or A.listPlace())
    if score.deaths == 0 and score.kills == 0 then return "" end
    return " · D" .. score.deaths .. "/K" .. score.kills
end

local function reportSummary(g)
    local n = #g.reports
    local own = ownReport(g)
    local score = scoreText(g)
    local base
    if n == 1 then
        local entry = g.reports[1]
        if entry.owner == A.me.key then base = "1 report · yours" .. score
        else base = "1 report · " .. UI.shorten(A.personName(entry.owner), 14) .. score end
    elseif own then
        base = n .. " reports · yours + friends" .. score
    else
        base = n .. " reports · friends" .. score
    end
    local enemyKey = g.enemyKey
    if not enemyKey and g.reports and g.reports[1] then enemyKey = A.splitSlot(g.reports[1].key) end
    local seen = enemyKey and A.sightingFor and A.sightingFor(enemyKey, g.place or A.listPlace())
    local short = A.formatSeenShort and A.formatSeenShort(seen) or ""
    if short ~= "" then base = base .. " · " .. short end
    if A.isIgnored and enemyKey and A.isIgnored(enemyKey) then base = base .. " · muted" end
    return base
end

local function ensureHistoryBlock(index)
    local block = ctx.historyBlocks[index]
    if block then return block end
    block = CreateFrame("Frame", nil, ctx.ui.historyChild)
    block:SetSize(280, 50)
    block.bg = UI.rect(block, 0, 0, 280, 50, UI.ROW)
    block.stripe = UI.rect(block, 0, 0, 3, 50, UI.STANCES[1].color, "ARTWORK")
    block.who = UI.text(block, "", 10, 5, 260, "GameFontNormalSmall", UI.GOLD)
    block.body = UI.text(block, "", 10, 22, 260, "GameFontHighlightSmall", UI.INK)
    block.who:SetWordWrap(false)
    block.body:SetWordWrap(true)
    ctx.historyBlocks[index] = block
    return block
end

local function newReport()
    ctx.selected, ctx.selectedRealm, ctx.armedWithdraw = nil, nil, nil
    ctx.filling = true
    ctx.ui.name:SetText("")
    ctx.ui.note:SetText("")
    ctx.filling = false
    ctx.mode = "AVENGE"
    ctx.ui.historyScroll:SetVerticalScroll(0)
    ctx.feedback("")
    A.refresh()
    ctx.ui.name:SetFocus()
end

selectEnemy = function(g)
    ctx.selected, ctx.armedWithdraw = g.key, nil
    local own = ownReport(g)
    ctx.selectedRealm = own and own.realm or A.realm()
    ctx.filling = true
    ctx.ui.name:SetText(g.name)
    -- Never silently copy another author's reason into your report.
    ctx.ui.note:SetText(own and own.note or "")
    ctx.filling = false
    ctx.mode = own and own.mode or "AVENGE"
    ctx.ui.historyScroll:SetVerticalScroll(0)
    ctx.feedback(own and "Editing your report. Your friends' reports stay separate." or "Read your friends' reports below, then add your own if you wish.")
    A.refresh()
end

local function showInList()
    ctx.filter = "ALL"
    ctx.ui.search:SetText("")
    local list = groups()
    for i, enemy in ipairs(list) do
        if enemy.key == ctx.selected then
            ctx.page = math.ceil(i / UI.ROWS)
            break
        end
    end
    A.refresh()
end

local function saveReport()
    local who = A.sender(ctx.ui.name:GetText())
    if not who or not who.name:find("%s") then
        ctx.feedback("Enter a first name and surname, or use Add target.", true)
        ctx.ui.name:SetFocus()
        return
    end
    local ok, err = A.report(who.name, ctx.ui.note:GetText(), ctx.mode, false, ctx.selectedRealm, A.listPlace())
    if not ok then
        ctx.feedback(err or "Could not save that report.", true)
        return
    end
    ctx.selected, ctx.selectedRealm = who.name:lower(), ctx.selectedRealm or who.realm
    ctx.armedWithdraw = nil
    ctx.ui.name:SetText(who.name)
    ctx.ui.name:ClearFocus()
    ctx.ui.note:ClearFocus()
    ctx.feedback("Saved on this character.")
    showInList()
end

function A.prepareEnemyDraft(who, note, draftMode, place)
    if not who then return false, "No enemy identity." end
    if not ctx.panel then ctx.build() end
    local tab = A.normalizePlace(place or A.listPlace()) == "battleground" and "battlegrounds" or "world"
    ctx.panel:Show()
    ctx.switch(tab)
    if A.rememberFace and A.flag(UnitExists, "target") then A.rememberFace("target", who.key) end
    local _, lookup = groups()
    if lookup[who.name:lower()] then
        selectEnemy(lookup[who.name:lower()])
    else
        newReport()
        ctx.filling = true
        ctx.ui.name:SetText(who.name)
        ctx.filling = false
        ctx.selectedRealm = who.realm
        ctx.selected = who.name:lower()
    end
    if A.plain(note, "string") and note ~= "" then
        ctx.filling = true
        ctx.ui.note:SetText(note)
        ctx.filling = false
    end
    if A.plain(draftMode, "string") and A.modes[draftMode] then
        ctx.mode = draftMode
    end
    ctx.ui.note:SetFocus()
    A.refresh()
    return true
end

local function useTarget()
    if not A.flag(UnitIsPlayer, "target") or not A.flag(UnitIsEnemy, "player", "target") then
        ctx.feedback("Select an enemy player in the game, then click Add target.", true)
        return
    end
    local who = A.unitName("target")
    if not who then
        ctx.feedback("That name is unavailable. Try outside combat or enter it yourself.", true)
        return
    end
    A.prepareEnemyDraft(who, nil, nil, A.listPlace())
end

refreshEditor = function(lookup)
    local g = ctx.selected and lookup[ctx.selected]
    local own = ownReport(g)
    local chosen = stanceInfo(ctx.mode)
    ctx.ui.editorTitle:SetText(g and UI.shorten(g.name, 28) or "Add your report")
    UI.paintFace(ctx.ui.editorClass, ctx.ui.editorRace, g and A.faceFor and A.faceFor(g.key))
    if g then ctx.ui.name:Disable() else ctx.ui.name:Enable() end
    ctx.ui.save:SetText(own and "Save changes" or "Save report")
    ctx.ui.withdraw:SetEnabled(own ~= nil)
    ctx.ui.withdraw:SetText(ctx.armedWithdraw and "Confirm removal" or "Withdraw")
    if ctx.ui.mute then
        local enemyKey = g and (g.enemyKey or (g.reports[1] and A.splitSlot(g.reports[1].key)))
        local muted = enemyKey and A.isIgnored and A.isIgnored(enemyKey)
        ctx.ui.mute:SetEnabled(g ~= nil)
        ctx.ui.mute:SetText(muted and "Unmute" or "Mute alerts")
    end
    for _, s in ipairs(UI.STANCES) do
        local on = ctx.mode == s.id
        ctx.stanceButtons[s.id]:SetText((on and UI.hexColor(s.color) or "") .. s.label .. (on and "|r" or ""))
        ctx.stanceButtons[s.id].mark:SetShown(on)
        if on then ctx.stanceButtons[s.id].mark:SetColorTexture(s.color[1], s.color[2], s.color[3], 1) end
    end
    ctx.ui.stanceHint:SetText(chosen.hint)
    ctx.ui.stanceHint:SetTextColor(unpack(chosen.color))

    ctx.ui.historyTitle:SetText(g and (#g.reports .. (#g.reports == 1 and " report on this enemy" or " reports on this enemy")) or "Reports from trusted friends")
    local y = 0
    if g and #g.reports > 0 then
        ctx.ui.historyEmpty:Hide()
        for i, entry in ipairs(g.reports) do
            local block = ensureHistoryBlock(i)
            local r = entry.report
            local s = stanceInfo(r.mode)
            local who = entry.owner == A.me.key and "You" or A.personName(entry.owner)
            local role = entry.owner == A.me.key and "yours" or "friend"
            block.who:SetText(UI.shorten(who .. " · " .. s.label .. " · " .. role, 42))
            block.body:SetText(r.note ~= "" and r.note or "No reason provided.")
            block.stripe:SetColorTexture(s.color[1], s.color[2], s.color[3], 1)
            block:ClearAllPoints()
            block:SetPoint("TOPLEFT", 0, -y)
            block:Show()
            y = y + 54
        end
        for i = #g.reports + 1, #ctx.historyBlocks do ctx.historyBlocks[i]:Hide() end
    else
        for _, block in ipairs(ctx.historyBlocks) do block:Hide() end
        ctx.ui.historyEmpty:Show()
        ctx.ui.historyEmpty:SetText(g and "No active reports on this enemy." or "Select an enemy to read every report.\n\nYour reason stays separate from your friends' reasons.")
    end
    ctx.ui.historyChild:SetHeight(math.max(110, y > 0 and y or 110))
end

ctx.syncNote = function()
    if A.syncStatus then return A.syncStatus() end
    local pending = A.pendingCount()
    if A.plain(A.lastSendError, "string") and A.lastSendError ~= "" then return A.lastSendError end
    if pending > 0 then
        return pending .. (pending == 1 and " whisper queued. " or " whispers queued. ")
            .. "Both characters need to be online."
    end
    return "Sync health: whispers catch up when both characters are online."
end

local function groupEnemyKey(g)
    if not g then return nil end
    if g.enemyKey then return g.enemyKey end
    if g.reports and g.reports[1] then return A.splitSlot(g.reports[1].key) end
    return nil
end

local function groupPassesFilter(g)
    if ctx.filter == "ALL" then return true end
    if ctx.filter == "AVENGE" or ctx.filter == "AVOID" or ctx.filter == "WATCH" then
        return g.modes[ctx.filter] == true
    end
    local enemyKey = groupEnemyKey(g)
    if ctx.filter == "UI.MUTED" then
        return enemyKey and A.isIgnored and A.isIgnored(enemyKey) or false
    end
    if ctx.filter == "SEEN" then
        if not enemyKey or not A.sightingFor then return false end
        local seen = A.sightingFor(enemyKey, g.place or A.listPlace())
        return seen ~= nil and (tonumber(seen.ts) or 0) > 0
    end
    return true
end

function A.refresh()
    if not ctx.panel or not ctx.panel:IsShown() then return end
    if A.scanFaces then A.scanFaces() end
    local all, lookup = groups()
    local filtered, query = {}, ctx.ui.search:GetText():lower()
    for _, g in ipairs(all) do
        local haystack = g.name
        for _, e in ipairs(g.reports) do
            haystack = haystack .. " " .. e.report.note .. " " .. A.personName(e.owner)
        end
        if groupPassesFilter(g) and haystack:lower():find(query, 1, true) then
            filtered[#filtered + 1] = g
        end
    end
    local count = math.max(1, math.ceil(#filtered / UI.ROWS))
    ctx.page = math.max(1, math.min(ctx.page, count))
    if ctx.view == "friends" then
        local friendsN = A.count(A.store.friends)
        ctx.ui.heading:SetText("Trusted friends")
        ctx.ui.summary:SetText(friendsN .. (friendsN == 1 and " character. " or " characters. ") .. "Both sides add each other.")
    elseif ctx.view == "alerts" then
        ctx.ui.heading:SetText("Warnings")
        ctx.ui.summary:SetText("Nameplates, target, focus, and mouseover.")
    elseif ctx.view == "battlegrounds" then
        ctx.ui.heading:SetText("Battlegrounds")
        ctx.ui.summary:SetText(#all .. (#all == 1 and " BG enemy" or " BG enemies") .. " · local D/K")
    else
        ctx.ui.heading:SetText("World PvP")
        ctx.ui.summary:SetText(#all .. (#all == 1 and " world enemy" or " world enemies") .. " · local D/K")
    end
    local manyPages = #filtered > UI.ROWS
    ctx.ui.pagination:SetText(manyPages and ("Page " .. ctx.page .. " of " .. count) or "")
    ctx.ui.pagination:SetShown(manyPages)
    ctx.ui.prev:SetShown(manyPages)
    ctx.ui.next:SetShown(manyPages)
    ctx.ui.prev:SetEnabled(ctx.page > 1)
    ctx.ui.next:SetEnabled(ctx.page < count)
    if ctx.ui.addEnemy then ctx.ui.addEnemy:SetShown(onList()) end
    if ctx.ui.addTarget then ctx.ui.addTarget:SetShown(onList()) end
    ctx.refreshAttackers()
    ctx.ui.clearSearch:SetEnabled(query ~= "")
    for id, b in pairs(ctx.filters) do
        b.mark:SetShown(id == ctx.filter)
        b:SetText((id == ctx.filter and "|cffffd159" or "") .. b.caption .. (id == ctx.filter and "|r" or ""))
    end
    local selectionVisible = false
    for i, row in ipairs(ctx.rows) do
        local g = filtered[(ctx.page - 1) * UI.ROWS + i]
        row.group = g
        row:SetShown(g ~= nil)
        if g then
            if ctx.selected == g.key then selectionVisible = true end
            row.name:SetText(UI.shorten(g.name, 24))
            UI.paintFace(row.classIcon, row.raceIcon, A.faceFor and A.faceFor(g.key))
            local mixed = A.count(g.modes) > 1
            local s = stanceInfo(g.modes.AVOID and "AVOID" or (g.modes.AVENGE and "AVENGE" or "WATCH"))
            row.tag:SetText(mixed and "Mixed" or s.label)
            local color = mixed and UI.MUTED or s.color
            row.tag:SetTextColor(unpack(color))
            row.stripe:SetColorTexture(color[1], color[2], color[3], 1)
            row.detail:SetText(reportSummary(g))
            row.name:SetTextColor(unpack(UI.INK))
            row.detail:SetTextColor(unpack(UI.INK_MUTED))
            row.bg:SetColorTexture(unpack(ctx.selected == g.key and UI.ROW_ON or UI.ROW))
        end
    end
    ctx.ui.empty:SetShown(#filtered == 0)
    ctx.ui.emptyTitle:SetText(#all == 0 and "No enemies yet" or "No enemies match")
    local friendsN = A.count(A.store.friends)
    if #all == 0 then
        if friendsN == 0 then
            ctx.ui.emptyBody:SetText("First: open Friends and exchange /fv trust with each other.\nThen Add target, or type a full name.")
        else
            ctx.ui.emptyBody:SetText("Add target, or type a full name.")
        end
    elseif ctx.filter == "UI.MUTED" then
        ctx.ui.emptyBody:SetText("No muted enemies. Mute from the editor or the warning banner.")
    elseif ctx.filter == "SEEN" then
        ctx.ui.emptyBody:SetText("No sightings yet. Seen fills when a listed enemy is visible (saved locally).")
    else
        ctx.ui.emptyBody:SetText("Clear the search, or set the ctx.filter to All.")
    end
    if ctx.ui.emptyFriends then
        ctx.ui.emptyFriends:SetShown(#all == 0 and friendsN == 0 and onList())
    end
    ctx.ui.reveal:SetShown(lookup[ctx.selected] ~= nil and not selectionVisible)
    refreshEditor(lookup)
    for id, b in pairs(ctx.nav) do
        local on = ctx.view == id
        if type(b.mark) == "table" then b.mark:SetShown(on) end
        if b.classic and b.bg and b.bg.SetTexture then
            b.bg:SetTexture(on and "Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab" or "Interface\\PaperDollInfoFrame\\UI-Character-InActiveTab")
        elseif b.bg then
            b.bg:SetColorTexture(unpack(on and UI.ROW_ON or UI.BUTTON_FACE.quiet))
        end
        b:SetText(b.caption)
    end
    local friends = {}
    for _, peer in pairs(A.store.friends) do friends[#friends + 1] = peer end
    table.sort(friends, function(a, b) return a.name < b.name end)
    local maxFriends = math.max(1, math.ceil(#friends / 7))
    ctx.friendPage = math.max(1, math.min(ctx.friendPage, maxFriends))
    local manyFriends = #friends > 7
    ctx.ui.friendPagination:SetText(manyFriends and ("Page " .. ctx.friendPage .. " of " .. maxFriends) or "")
    ctx.ui.friendPagination:SetShown(manyFriends)
    ctx.ui.friendPrev:SetShown(manyFriends)
    ctx.ui.friendNext:SetShown(manyFriends)
    ctx.ui.sync:SetEnabled(#friends > 0)
    ctx.ui.friendPrev:SetEnabled(ctx.friendPage > 1)
    ctx.ui.friendNext:SetEnabled(ctx.friendPage < maxFriends)
    ctx.ui.friendEmpty:SetShown(#friends == 0)
    for i, row in ipairs(ctx.friendRows) do
        local peer = friends[(ctx.friendPage - 1) * 7 + i]
        row.peer = peer
        row:SetShown(peer ~= nil)
        if peer then
            local n = 0
            for _, r in pairs(A.store.reports[peer.key] or {}) do
                if not r.deleted then n = n + 1 end
            end
            row.name:SetText(UI.shorten(peer.name, 28))
            row.name:SetTextColor(unpack(UI.INK))
            local status = A.friendStatus and A.friendStatus(peer)
            if not status then
                local received = A.store.lastReceived and A.store.lastReceived[peer.key]
                local stamp = received and A.call(date, "%d %b %H:%M", received)
                status = n .. (n == 1 and " active report" or " active reports")
                if stamp then status = status .. " · Last report " .. stamp end
            end
            row.detail:SetText(UI.shorten(status, 48))
            local heard = A.store.lastHeard and A.store.lastHeard[peer.key]
            row.detail:SetTextColor(unpack(heard and UI.GOLD or UI.INK_MUTED))
            row.remove:SetText(ctx.armedFriend == peer.key and "Confirm remove" or "Remove")
        end
    end
    for key, c in pairs(ctx.ui.checks) do c:SetChecked(A.store.settings[key] == true) end
    if A.refreshMinimap then A.refreshMinimap() end
    if ctx.ui.soundButtons then
        local current = A.soundById(A.store.settings.alertSound)
        current = current and current.id
        for id, b in pairs(ctx.ui.soundButtons) do
            local on = id == current
            if type(b.mark) == "table" then b.mark:SetShown(on) end
            b:SetText((on and UI.hexColor(UI.GOLD) or "") .. b.caption .. (on and "|r" or ""))
        end
    end
    ctx.ui.cooldownLabel:SetText(A.store.settings.cooldown .. " seconds")
    if ctx.ui.cooldown:GetValue() ~= A.store.settings.cooldown then ctx.ui.cooldown:SetValue(A.store.settings.cooldown) end
    if ctx.view == "alerts" then
        local places = {}
        if A.store.settings.world ~= false then places[#places + 1] = "World" end
        if A.store.settings.battlegrounds then places[#places + 1] = "BG" end
        if A.store.settings.instances then places[#places + 1] = "Arenas" end
        ctx.ui.footer:SetText((#places > 0 and table.concat(places, " · ") or "No alert places") .. " · " .. A.store.settings.cooldown .. "s cooldown")
    elseif ctx.view == "friends" then
        local note = ctx.syncNote()
        ctx.ui.footer:SetText(note)
        if ctx.ui.syncHealth then ctx.ui.syncHealth:SetText(note) end
        if ctx.ui.syncNote then ctx.ui.syncNote:SetText(note) end
        if ctx.ui.trustCmd and A.me and A.plain(A.me.name, "string") then
            ctx.ui.trustCmd:SetText("/fv trust " .. A.me.name)
        end
        if ctx.ui.gameFriendButtons and A.gameFriends then
            local picks = A.gameFriends()
            for i, b in ipairs(ctx.ui.gameFriendButtons) do
                local who = picks[i]
                if who then
                    b.friendName = who.name
                    b:SetText(UI.shorten(who.name, 28))
                    b:Show()
                else
                    b.friendName = nil
                    b:Hide()
                end
            end
            if ctx.ui.gameFriendEmpty then ctx.ui.gameFriendEmpty:SetShown(#picks == 0) end
        end
    else
        ctx.ui.footer:SetText("")
    end
    if ctx.ui.syncNote then ctx.ui.syncNote:SetText(ctx.syncNote()) end
end

ctx.refreshAttackers = function()
    if not ctx.ui.attackerLabel then return end
    local place = A.listPlace()
    local recent = A.recentAttackers and A.recentAttackers(place) or {}
    local unlisted = {}
    for i = 1, #recent do
        local row = recent[i]
        local slot = A.slotKey(row.key, row.place)
        local mine = A.store.reports[A.me.key] and A.store.reports[A.me.key][slot]
        if not (type(mine) == "table" and not mine.deleted) then
            unlisted[#unlisted + 1] = row
        end
    end
    local showAttackers = onList() and #unlisted > 0
    ctx.ui.attackerLabel:SetShown(showAttackers)
    for i = 1, #ctx.attackerButtons do
        local b = ctx.attackerButtons[i]
        local row = unlisted[i]
        b:SetShown(showAttackers and row ~= nil)
        if row then
            b.row = row
            b:SetText(UI.shorten(row.name, 12))
        end
    end
    -- Keep history clear of the attacker strip; use the leftover editor height when free.
    if ctx.ui.historyTitle and ctx.ui.historyScroll then
        ctx.ui.historyTitle:ClearAllPoints()
        ctx.ui.historyScroll:ClearAllPoints()
        if showAttackers then
            ctx.ui.historyTitle:SetPoint("TOPLEFT", 12, -258)
            ctx.ui.historyScroll:SetPoint("TOPLEFT", 12, -274)
            ctx.ui.historyScroll:SetSize(284, 56)
        else
            ctx.ui.historyTitle:SetPoint("TOPLEFT", 12, -218)
            ctx.ui.historyScroll:SetPoint("TOPLEFT", 12, -234)
            ctx.ui.historyScroll:SetSize(284, 102)
        end
    end
end

local function buildEnemies()
    local p = ctx.pages.enemies
    local list = UI.box(p, 16, 112, 360, 336)
    ctx.ui.search = UI.edit(list, 10, 10, 210, 96)
    UI.tip(ctx.ui.search, "Search blacklist", "Find an enemy, a reporting friend, or words in a reason.")
    ctx.ui.search:SetScript("OnTextChanged", function() ctx.page = 1; A.refresh() end)
    UI.placeholder(ctx.ui.search, "Search names or reasons...")
    ctx.ui.clearSearch = UI.button(list, "Clear search", 210, 10, 106, function() ctx.ui.search:SetText("") end)
    ctx.ui.search:SetWidth(192)
    for i, item in ipairs({ { "ALL", "All" }, { "AVENGE", "Avenge" }, { "AVOID", "Avoid" }, { "WATCH", "Watch" } }) do
        local id, caption = item[1], item[2]
        local b = UI.button(list, caption, 10 + (i - 1) * 78, 44, 74, function()
            ctx.filter = id
            ctx.page = 1
            A.refresh()
        end)
        b.caption = caption
        b.mark = UI.rect(b, 4, 22, 66, 2, { 1, .75, .22, 1 }, "OVERLAY")
        ctx.filters[id] = b
    end
    for i, item in ipairs({
        { "UI.MUTED", "Muted", "Only enemies you muted locally. Reports stay." },
        { "SEEN", "Seen", "Enemies you have sighted on this character (saved locally until you wipe SavedVariables)." },
    }) do
        local id, caption, tipText = item[1], item[2], item[3]
        local b = UI.button(list, caption, 10 + (i - 1) * 78, 70, 74, function()
            ctx.filter = id
            ctx.page = 1
            A.refresh()
        end)
        b.caption = caption
        b.mark = UI.rect(b, 4, 22, 66, 2, { 1, .75, .22, 1 }, "OVERLAY")
        UI.tip(b, caption, tipText)
        ctx.filters[id] = b
    end
    for i = 1, UI.ROWS do
        local row = CreateFrame("Button", nil, list)
        row:SetPoint("TOPLEFT", 10, -100 - (i - 1) * 34)
        row:SetSize(340, 32)
        row.bg = UI.rect(row, 0, 0, 340, 32, UI.ROW)
        row.stripe = UI.rect(row, 0, 0, 3, 32, { .72, .18, .12, 1 }, "ARTWORK")
        row.classIcon = row:CreateTexture(nil, "ARTWORK")
        row.classIcon:SetSize(18, 18)
        row.classIcon:SetPoint("TOPLEFT", 8, -8)
        row.classIcon:Hide()
        row.raceIcon = row:CreateTexture(nil, "ARTWORK")
        row.raceIcon:SetSize(18, 18)
        row.raceIcon:SetPoint("LEFT", row.classIcon, "RIGHT", 2, 0)
        row.raceIcon:Hide()
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.name = UI.text(row, "", 48, 3, 190, "GameFontHighlight", UI.INK)
        row.detail = UI.text(row, "", 48, 18, 190, "GameFontHighlightSmall", UI.INK_MUTED)
        row.tag = UI.text(row, "", 248, 10, 84, "GameFontNormalSmall")
        row.name:SetWordWrap(false)
        row.detail:SetWordWrap(false)
        row.tag:SetWordWrap(false)
        row:SetScript("OnEnter", function(self)
            if not self.group or not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.group.name, unpack(UI.GOLD))
            GameTooltip:AddLine("Click to read every report and edit your own.", .9, .9, .9, true)
            local enemyKey = self.group.enemyKey
            if not enemyKey and self.group.reports and self.group.reports[1] then
                enemyKey = A.splitSlot(self.group.reports[1].key)
            end
            local seen = enemyKey and A.sightingFor and A.sightingFor(enemyKey, self.group.place or A.listPlace())
            local when = A.formatSeenWhen and A.formatSeenWhen(seen)
            if when then
                local line = "Last seen " .. when
                if seen.zone ~= "" then line = line .. " · " .. seen.zone end
                GameTooltip:AddLine(line, .72, .68, .58, true)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            if GameTooltip then GameTooltip:Hide() end
        end)
        row:SetScript("OnClick", function(self)
            if self.group then selectEnemy(self.group) end
        end)
        ctx.rows[i] = row
    end
    ctx.ui.empty = CreateFrame("Frame", nil, list)
    ctx.ui.empty:SetPoint("TOPLEFT", 18, -148)
    ctx.ui.empty:SetSize(290, 140)
    ctx.ui.emptyTitle = UI.text(ctx.ui.empty, "", 0, 0, 280, "GameFontNormalLarge", UI.GOLD)
    ctx.ui.emptyBody = UI.text(ctx.ui.empty, "", 0, 32, 280, "GameFontHighlight", UI.INK_MUTED)
    ctx.ui.emptyFriends = UI.button(ctx.ui.empty, "Open Friends", 0, 78, 140, function()
        ctx.switch("friends")
    end, "primary")
    ctx.ui.emptyFriends:Hide()
    ctx.ui.prev = UI.button(list, "Previous", 8, 316, 72, function() ctx.page = ctx.page - 1; A.refresh() end)
    ctx.ui.pagination = UI.text(list, "", 84, 322, 70, "GameFontHighlightSmall", UI.INK_MUTED)
    ctx.ui.reveal = UI.button(list, "Show in list", 152, 316, 100, showInList)
    ctx.ui.next = UI.button(list, "Next", 256, 316, 64, function() ctx.page = ctx.page + 1; A.refresh() end)

    local e = UI.box(p, 388, 112, 316, 336)
    ctx.ui.editorClass = e:CreateTexture(nil, "ARTWORK")
    ctx.ui.editorClass:SetSize(20, 20)
    ctx.ui.editorClass:SetPoint("TOPLEFT", 12, -8)
    ctx.ui.editorClass:Hide()
    ctx.ui.editorRace = e:CreateTexture(nil, "ARTWORK")
    ctx.ui.editorRace:SetSize(20, 20)
    ctx.ui.editorRace:SetPoint("LEFT", ctx.ui.editorClass, "RIGHT", 3, 0)
    ctx.ui.editorRace:Hide()
    ctx.ui.editorTitle = UI.text(e, "Add your report", 58, 10, 270, "GameFontNormal", UI.GOLD)
    ctx.ui.editorTitle:SetWordWrap(false)
    UI.text(e, "Enemy full name", 12, 30, 300, "GameFontHighlightSmall", UI.INK_MUTED)
    ctx.ui.name = UI.edit(e, 12, 44, 290, 64)
    ctx.ui.name:SetScript("OnTextChanged", function(_, user)
        if user and not ctx.filling then
            ctx.selected, ctx.selectedRealm, ctx.armedWithdraw = nil, nil, nil
            A.refresh()
        end
    end)
    ctx.ui.name:SetScript("OnEnterPressed", function() ctx.ui.note:SetFocus() end)
    ctx.ui.name:SetScript("OnTabPressed", function() ctx.ui.note:SetFocus() end)
    UI.placeholder(ctx.ui.name, "First name and surname")
    for i, s in ipairs(UI.STANCES) do
        local b = UI.button(e, s.label, 12 + (i - 1) * 102, 78, 96, function()
            ctx.mode = s.id
            A.refresh()
        end)
        b.mark = UI.rect(b, 5, 22, 86, 2, s.color, "OVERLAY")
        UI.tip(b, s.label, s.hint)
        ctx.stanceButtons[s.id] = b
    end
    ctx.ui.stanceHint = UI.text(e, UI.STANCES[1].hint, 12, 106, 300, "GameFontHighlightSmall", UI.STANCES[1].color)
    UI.text(e, "Reason (optional)", 12, 124, 300, "GameFontHighlightSmall", UI.INK_MUTED)
    local noteScroll = CreateFrame("ScrollFrame", nil, e)
    noteScroll:SetPoint("TOPLEFT", 12, -138)
    noteScroll:SetSize(290, 40)
    UI.rect(noteScroll, 0, 0, 290, 40, { .05, .05, .06, 1 })
    ctx.ui.note = UI.edit(noteScroll, 0, 0, 290, 96, true)
    noteScroll:SetScrollChild(ctx.ui.note)
    ctx.ui.note:SetScript("OnTabPressed", function() ctx.ui.name:SetFocus() end)
    ctx.ui.note:SetScript("OnCursorChanged", function(_, _, y, _, height)
        local current = noteScroll:GetVerticalScroll()
        if not A.plain(current, "number") then current = 0 end
        local bottom = -y + height
        if -y < current then noteScroll:SetVerticalScroll(-y)
        elseif bottom > current + 40 then noteScroll:SetVerticalScroll(bottom - 40) end
    end)
    ctx.ui.save = UI.button(e, "Save report", 12, 186, 100, saveReport, "primary")
    ctx.ui.withdraw = UI.button(e, "Withdraw", 118, 186, 90, function()
        local _, lookup = groups()
        local own = ownReport(ctx.selected and lookup[ctx.selected])
        if not own then return end
        if ctx.armedWithdraw ~= ctx.selected then
            ctx.armedWithdraw = ctx.selected
            ctx.feedback("Click Confirm removal to withdraw only your report.")
            A.refresh()
            return
        end
        local ok, err = A.report(own.name, own.note, own.mode, true, own.realm, own.place or A.listPlace())
        ctx.armedWithdraw = nil
        ctx.feedback(ok and "Your report was withdrawn. Your friends' reports stay." or err, not ok)
        if ok then ctx.ui.note:SetText("") end
        A.refresh()
    end, "danger")
    UI.tip(ctx.ui.withdraw, "Withdraw your report", "Only your current character's report is removed. Friends' reports remain. Click twice to confirm.")
    ctx.ui.mute = UI.button(e, "Mute alerts", 214, 186, 100, function()
        local _, lookup = groups()
        local g = ctx.selected and lookup[ctx.selected]
        if not g then
            ctx.feedback("Select an enemy first.", true)
            return
        end
        local enemyKey = g.enemyKey or (g.reports[1] and A.splitSlot(g.reports[1].key))
        if not enemyKey then return end
        if A.isIgnored(enemyKey) then
            local ok, err = A.unignoreEnemy(g.name)
            ctx.feedback(ok and "Alerts unmuted for " .. g.name .. "." or err, not ok)
        else
            local ok, err = A.ignoreEnemy(g.name)
            ctx.feedback(ok and "Alerts muted for " .. g.name .. " (reports stay)." or err, not ok)
        end
        A.refresh()
    end)
    UI.tip(ctx.ui.mute, "Mute alerts", "Stops sound/banner/party announce for this enemy. Reports stay. Local only — not shared.")
    ctx.ui.attackerLabel = UI.text(e, "Recent attackers", 12, 212, 300, "GameFontNormalSmall", UI.GOLD)
    ctx.ui.attackerLabel:Hide()
    for i = 1, 3 do
        local b = UI.button(e, "", 12 + (i - 1) * 100, 228, 96, function(self)
            local row = self.row
            if not row then return end
            A.prepareEnemyDraft({
                name = row.name,
                realm = row.realm,
                key = row.key,
            }, row.why == "Death recap" and "Killed me" or row.why, "AVENGE", row.place)
        end)
        b:Hide()
        ctx.attackerButtons[i] = b
    end
    ctx.ui.historyTitle = UI.text(e, "Reports from trusted friends", 12, 218, 300, "GameFontNormalSmall", UI.GOLD)
    local scroll = CreateFrame("ScrollFrame", nil, e, "UIPanelScrollFrameTemplate")
    ctx.ui.historyScroll = scroll
    scroll:SetPoint("TOPLEFT", 12, -234)
    scroll:SetSize(284, 90)
    ctx.ui.historyChild = CreateFrame("Frame", nil, scroll)
    ctx.ui.historyChild:SetSize(284, 80)
    scroll:SetScrollChild(ctx.ui.historyChild)
    ctx.ui.historyEmpty = UI.text(ctx.ui.historyChild, "", 0, 0, 270, "GameFontHighlightSmall", UI.INK_MUTED)
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

function A.close()
    if not ctx.panel then return end
    ctx.panel:Hide()
    for _, p in pairs(ctx.pages) do p:Hide() end
end

local function wireClose(close)
    if type(close) ~= "table" then return end
    if close.SetFrameLevel then
        local level = 1
        if ctx.panel and type(ctx.panel.GetFrameLevel) == "function" then
            local got = ctx.panel:GetFrameLevel()
            if type(got) == "number" then level = got end
        end
        close:SetFrameLevel(level + 20)
    end
    if close.EnableMouse then close:EnableMouse(true) end
    if close.Show then close:Show() end
    if close.SetScript then
        close:SetScript("OnClick", function() A.close() end)
    end
end

ctx.build = function()
    ctx.panel = CreateFrame("Frame", "ForeverVendettaWindow", UIParent, "BasicFrameTemplateWithInset")
    ctx.panel:SetSize(UI.W, UI.H)
    ctx.panel:SetPoint("CENTER")
    UI.fit(ctx.panel, UI.W, UI.H)
    local ver = (A.addonVersion and A.addonVersion()) or A.VERSION or ""
    if ctx.panel.TitleText then
        ctx.panel.TitleText:SetText(ver ~= "" and ("Forever Vendetta  ·  " .. ver) or "Forever Vendetta")
    end
    ctx.panel:SetMovable(true)
    ctx.panel:EnableMouse(true)
    ctx.panel:SetToplevel(true)
    if ctx.panel.SetClampedToScreen then ctx.panel:SetClampedToScreen(true) end

    -- Keep the title drag off the close button. Covering that X is what makes the window feel stuck.
    local drag = CreateFrame("Frame", nil, ctx.panel)
    drag:SetPoint("TOPLEFT", 8, -2)
    drag:SetPoint("TOPRIGHT", -36, -2)
    drag:SetHeight(24)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() ctx.panel:StartMoving() end)
    drag:SetScript("OnDragStop", function() ctx.panel:StopMovingOrSizing() end)

    local close = ctx.panel.CloseButton
    if type(close) ~= "table" then
        close = CreateFrame("Button", nil, ctx.panel, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", 2, 2)
        ctx.panel.CloseButton = close
    end
    wireClose(close)

    if UISpecialFrames then table.insert(UISpecialFrames, "ForeverVendettaWindow") end
    -- Forever may not always route Escape through UISpecialFrames; close ourselves too.
    if ctx.panel.EnableKeyboard then ctx.panel:EnableKeyboard(true) end
    ctx.panel:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            A.close()
            if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
        elseif self.SetPropagateKeyboardInput then
            self:SetPropagateKeyboardInput(true)
        end
    end)

    dressMetal(ctx.panel)
    local host = type(ctx.panel.Inset) == "table" and ctx.panel.Inset or ctx.panel
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

    ctx.ui.heading = UI.text(ctx.panel, "Enemy blacklist", 20, 34, 280, "GameFontNormal", UI.GOLD)
    ctx.ui.summary = UI.text(ctx.panel, "", 20, 54, 420, "GameFontHighlightSmall", UI.INK_MUTED)
    ctx.ui.addEnemy = UI.button(ctx.panel, "Add enemy", 468, 34, 112, function()
        if not onList() then ctx.switch("world") end
        newReport()
    end, "primary")
    ctx.ui.addTarget = UI.button(ctx.panel, "Add target", 588, 34, 112, useTarget, "primary")

    ctx.pages.enemies = CreateFrame("Frame", nil, ctx.panel)
    ctx.pages.enemies:SetPoint("TOPLEFT", 0, -30)
    ctx.pages.enemies:SetSize(UI.W, UI.H - 30)
    if ctx.pages.enemies.EnableMouse then ctx.pages.enemies:EnableMouse(false) end
    ctx.pages.enemies:Hide()

    for i, item in ipairs({
        { "world", "World" },
        { "battlegrounds", "Battlegrounds" },
        { "friends", "Friends" },
        { "alerts", "Alerts" },
    }) do
        local id, caption = item[1], item[2]
        local p
        if id == "friends" or id == "alerts" then
            p = CreateFrame("Frame", id == "friends" and "ForeverVendettaFriends" or nil, ctx.panel)
            p:SetPoint("TOPLEFT", 0, -30)
            p:SetSize(UI.W, UI.H - 30)
            if p.EnableMouse then p:EnableMouse(false) end
            p:Hide()
            ctx.pages[id] = p
        end
        local b = CreateFrame("Button", nil, ctx.panel)
        b:SetPoint("TOPLEFT", 18 + (i - 1) * 100, -72)
        b:SetSize(96, 32)
        b.caption = caption
        b.classic = true
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints()
        b.bg:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InActiveTab")
        local label = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("CENTER", 0, 2)
        b:SetFontString(label)
        b:SetText(caption)
        b:SetScript("OnClick", function() ctx.switch(id) end)
        ctx.nav[id] = b
    end

    UI.rect(ctx.panel, 376, 112, 1, 336, { .45, .34, .18, .45 }, "ARTWORK")

    buildEnemies()
    A.buildFriendsUI(ctx)
    A.buildAlertsUI(ctx)
    ctx.ui.feedback = UI.text(ctx.panel, "", 20, 458, 340, "GameFontHighlightSmall", UI.GOLD)
    ctx.ui.footer = UI.text(ctx.panel, "", 360, 458, 280, "GameFontHighlightSmall", UI.INK_MUTED)
    ctx.ui.version = UI.text(ctx.panel, ver ~= "" and ("v" .. ver) or "", 650, 458, 50, "GameFontHighlightSmall", UI.INK_MUTED)
    ctx.panel:SetScript("OnHide", function()
        for _, p in pairs(ctx.pages) do p:Hide() end
        ctx.armedFriend, ctx.armedWithdraw = nil, nil
    end)
    -- Re-assert close after children so nothing ends up above the X.
    wireClose(ctx.panel.CloseButton)
    ctx.panel:Hide()
end

function A.toggle()
    if not ctx.panel then ctx.build() end
    if ctx.panel:IsShown() then
        A.close()
    else
        ctx.panel:Show()
        ctx.switch(ctx.view)
    end
end

function A.toggleFriends()
    if not ctx.panel then ctx.build() end
    if ctx.panel:IsShown() and ctx.view == "friends" then
        A.close()
    else
        ctx.panel:Show()
        ctx.switch("friends")
    end
end

