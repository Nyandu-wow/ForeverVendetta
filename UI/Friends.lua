local _, A = ...
local UI = A.UI

function A.buildFriendsUI(ctx)
    local p = ctx.pages.friends
    local ui = ctx.ui
    local list = UI.box(p, 16, 112, 360, 336)
    UI.text(list, "These characters exchange reports with you.", 12, 8, 330, "GameFontHighlightSmall", UI.INK_MUTED)
    for i = 1, 7 do
        local row = CreateFrame("Frame", nil, list)
        row:SetPoint("TOPLEFT", 10, -32 - (i - 1) * 36)
        row:SetSize(340, 32)
        UI.rect(row, 0, 0, 340, 32, UI.ROW)
        row.name = UI.text(row, "", 8, 2, 210, "GameFontHighlight", UI.INK)
        row.detail = UI.text(row, "", 8, 16, 210, "GameFontHighlightSmall", UI.INK_MUTED)
        row.name:SetWordWrap(false)
        row.detail:SetWordWrap(false)
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            if self.peer and GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.peer.name)
                local line = A.friendStatus and A.friendStatus(self.peer)
                if line then GameTooltip:AddLine(line, 1, 1, 1, true) end
                GameTooltip:AddLine("Sharing works only after they also add your full name.", .7, .7, .7, true)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        row.remove = UI.button(row, "Remove", 268, 5, 64, function()
            if not row.peer then return end
            if ctx.armedFriend ~= row.peer.key then
                ctx.armedFriend = row.peer.key
                ctx.feedback("Click Confirm remove to stop sharing and hide this friend's reports.")
                A.refresh()
                return
            end
            local name = row.peer.name
            A.untrust(name)
            ctx.armedFriend = nil
            A.refresh()
            ctx.feedback(name .. " removed from trusted friends.")
        end, "danger")
        ctx.friendRows[i] = row
    end
    ui.friendEmpty = UI.text(list, "No trusted friends yet.\nAdd their First Last name on the right,\nthen paste your /fv trust line to them.", 16, 48, 320, "GameFontHighlight", UI.INK_MUTED)
    ui.syncHealth = UI.text(list, "", 12, 292, 330, "GameFontHighlightSmall", UI.GOLD)
    ui.friendPrev = UI.button(list, "Previous", 8, 316, 72, function() ctx.friendPage = ctx.friendPage - 1; A.refresh() end)
    ui.friendPagination = UI.text(list, "", 88, 322, 140, "GameFontHighlightSmall", UI.INK_MUTED)
    ui.friendNext = UI.button(list, "Next", 236, 316, 80, function() ctx.friendPage = ctx.friendPage + 1; A.refresh() end)

    local setup = UI.box(p, 388, 112, 316, 336)
    UI.text(setup, "Add a trusted friend", 12, 8, 300, "GameFontNormal", UI.GOLD)
    ui.friendName = UI.edit(setup, 12, 32, 290, 112)
    UI.placeholder(ui.friendName, "First name and surname")
    local function addFriend()
        local who = A.sender(ui.friendName:GetText())
        if not who or not who.name:find("%s") then
            ctx.feedback("Enter your friend's first name and surname.", true)
            return
        end
        local ok, err = A.trust(ui.friendName:GetText())
        ctx.feedback(ok and "Friend added. They must add your character too." or err, not ok)
        if ok then
            ui.friendName:SetText("")
            ui.friendName:ClearFocus()
            A.sync()
            if ui.syncNote then ui.syncNote:SetText(ctx.syncNote()) end
        end
    end
    UI.button(setup, "Add trusted friend", 12, 66, 290, addFriend, "primary")
    ui.friendName:SetScript("OnEnterPressed", addFriend)
    UI.text(setup, "From your friends list (fills the name only):", 12, 94, 290, "GameFontHighlightSmall", UI.INK_MUTED)
    -- Scrollable picker: up to 12 First Last names; ~4 visible without scrolling.
    local GAME_FRIEND_SLOTS = 12
    local ROW_H = 22
    local scroll = CreateFrame("ScrollFrame", nil, setup, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -112)
    scroll:SetSize(268, 96)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(268, GAME_FRIEND_SLOTS * ROW_H)
    scroll:SetScrollChild(child)
    ui.gameFriendScroll = scroll
    ui.gameFriendChild = child
    ui.gameFriendButtons = {}
    for i = 1, GAME_FRIEND_SLOTS do
        local b = UI.button(child, "", 0, (i - 1) * ROW_H, 268, function(self)
            if not self.friendName then return end
            ui.friendName:SetText(self.friendName)
            ui.friendName:SetFocus()
            ctx.feedback("Name filled. Click Add trusted friend — they must still add you.")
        end)
        b:SetHeight(ROW_H - 2)
        b:Hide()
        ui.gameFriendButtons[i] = b
    end
    ui.gameFriendEmpty = UI.text(setup, "No readable First Last names on your friends list.", 12, 140, 290, "GameFontHighlightSmall", UI.INK_MUTED)
    ui.gameFriendEmpty:Hide()
    UI.text(setup, "They must add you too. Paste this to them:", 12, 214, 290, "GameFontHighlightSmall", UI.INK_MUTED)
    ui.trustCmd = UI.edit(setup, 12, 232, 290, 96)
    ui.trustCmd:SetText("/fv trust " .. (A.me and A.me.name or ""))
    UI.tip(ui.trustCmd, "Trust command", "Click, Ctrl+C, and send this to your friend. They run it so sharing becomes mutual.")
    ui.trustCmd:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    ui.trustCmd:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    ui.trustCmd:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    ui.trustCmd:SetScript("OnTextChanged", function(self)
        local want = "/fv trust " .. (A.me and A.me.name or "")
        if self:GetText() ~= want then self:SetText(want) end
    end)
    ui.sync = UI.button(setup, "Sync with friends", 12, 268, 290, function()
        A.sync()
        local note = ctx.syncNote()
        ctx.feedback(note, A.plain(A.lastSendError, "string") and A.lastSendError ~= "")
        if ui.syncNote then ui.syncNote:SetText(note) end
        A.refresh()
    end)
    UI.tip(ui.sync, "Sync with friends", "Queues hello whispers. Delivery needs both characters online. Status updates below and on the left.")
    ui.syncNote = UI.text(setup, "", 12, 296, 290, "GameFontHighlightSmall", UI.INK_MUTED)
end