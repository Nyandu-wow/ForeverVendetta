local addonName, A = ...
local frame = CreateFrame("Frame")
local scanTime, syncTime = 0, 0

function A.testAlert()
    A.alert("Example Enemy", { { owner = "Your friend", report = { mode = "AVOID", note = "Camped me three times in Stranglethorn" } } }, true)
end

local function help()
    A.print("/fv opens the window. World, Battlegrounds, Friends, and Alerts are the tabs.")
    A.print("Minimap button: left-click opens, right-click friends. /fv minimap on/off")
    A.print("/fv options opens the AddOns options page.")
    A.print("/fv add Full Name; reason  |  /fv target reason  |  /fv remove Full Name")
    A.print("/fv ignore Full Name  |  /fv unignore Full Name")
    A.print("/fv trust Friend Fullname  |  /fv untrust Friend Fullname  |  /fv sync")
    A.print("/fv sound on/off  |  /fv sound raid  |  /fv banner on/off")
    A.print("/fv world on/off  |  /fv battlegrounds on/off  |  /fv arenas on/off")
    A.print("/fv cooldown 60  |  /fv test  |  /fv status")
end

local function command(text)
    if not A.ready then A.print("Player identity not ready. Try after entering the world."); return end
    if not A.plain(text, "string") then text = "" end
    local cmd, rest = text:match("^%s*(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()
    if cmd == "" then A.toggle()
    elseif cmd == "friends" then A.toggleFriends()
    elseif cmd == "help" then help()
    elseif cmd == "test" then A.testAlert()
    elseif cmd == "sync" then A.sync(); A.print("Asking trusted friends for their latest reports. Both of you need to be online.")
    elseif cmd == "status" then
        local s = A.store.settings or {}
        local function onoff(v) return v and "on" or "off" end
        local muted = 0
        if type(A.store.ignored) == "table" then
            for _ in pairs(A.store.ignored) do muted = muted + 1 end
        end
        local place = A.pvpPlace and A.pvpPlace() or "world"
        local placeLabel = A.pvpPlaceLabel and A.pvpPlaceLabel(place) or place
        local messaging = "clear"
        if A.flag(C_ChatInfo and C_ChatInfo.InChatMessagingLockdown) then
            messaging = "combat lockdown"
        elseif A.flag(C_ChatInfo and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted) then
            messaging = "restricted"
        end
        local sightings = A.sightingCount and A.sightingCount() or 0
        A.print("Version " .. ((A.addonVersion and A.addonVersion()) or A.VERSION or "?"))
        A.print(#A.entries() .. " reports; " .. A.count(A.store.friends) .. " friends; "
            .. A.pendingCount() .. " queued; " .. muted .. " muted; " .. sightings .. " sightings.")
        A.print("Place: " .. placeLabel .. ". Messaging: " .. messaging .. ".")
        A.print("Alerts: world " .. onoff(s.world) .. "; battlegrounds " .. onoff(s.battlegrounds)
            .. "; arenas " .. onoff(s.instances) .. ".")
        A.print(A.syncStatus and A.syncStatus() or (A.lastSendError or "Direct friend sync; no server."))
        A.print("Enable enemy nameplates for detection.")
    elseif cmd == "trust" then
        local ok, err = A.trust(rest); A.print(ok and "Friend trusted. They must trust you too." or err)
        if ok then A.sync() end
    elseif cmd == "untrust" then
        local ok = A.untrust(rest)
        A.print(ok and "Friend removed; their received reports are hidden." or "Enter the friend's full character name.")
    elseif cmd == "ignore" then
        local ok, err = A.ignoreEnemy(rest)
        A.print(ok and "Alerts muted for that enemy (reports stay)." or err)
    elseif cmd == "unignore" then
        local ok, err = A.unignoreEnemy(rest)
        A.print(ok and "Alerts unmuted." or err)
    elseif cmd == "add" or cmd == "target" or cmd == "remove" then
        local ok, err
        if cmd == "target" then ok, err = A.targetReport(rest)
        elseif cmd == "remove" then ok, err = A.report(rest, "", "AVENGE", true)
        else
            local name, note = rest:match("^(.-);%s*(.*)$")
            ok, err = A.report(name or rest, note or "")
        end
        A.print(ok and "Your report saved and queued for sharing." or err)
    elseif cmd == "sound" then
        if rest == "on" or rest == "off" then
            A.store.settings.sound = rest == "on"; A.changed(); A.print("sound: " .. rest)
        else
            local choice = A.soundById(rest:lower())
            if not choice then
                local names = {}
                for _, sound in ipairs(A.ALERT_SOUNDS) do names[#names + 1] = sound.id end
                A.print("Sounds: " .. table.concat(names, ", "))
                return
            end
            A.store.settings.alertSound = choice.id
            A.playSound()
            A.changed()
            A.print("Warning sound: " .. choice.label)
        end
    elseif cmd == "options" or cmd == "config" then
        if A.openOptions then A.openOptions() else A.toggle() end
    elseif cmd == "minimap" then
        if rest ~= "on" and rest ~= "off" then help(); return end
        A.store.settings.minimapButton = rest == "on"
        A.changed()
        A.print("minimap button: " .. rest)
    elseif cmd == "arenas" or cmd == "instances" then
        if rest ~= "on" and rest ~= "off" then help(); return end
        A.store.settings.instances = rest == "on"; A.changed(); A.print("arenas: " .. rest)
    elseif cmd == "banner" or cmd == "world" or cmd == "battlegrounds" then
        if rest ~= "on" and rest ~= "off" then help(); return end
        A.store.settings[cmd] = rest == "on"; A.changed(); A.print(cmd .. ": " .. rest)
    elseif cmd == "cooldown" then
        local n = tonumber(rest)
        if not n or n < 10 or n > 600 then A.print("Choose 10 to 600 seconds."); return end
        A.store.settings.cooldown = math.floor(n); A.changed(); A.print("Alert cooldown: " .. math.floor(n) .. " seconds.")
    else help() end
end

SLASH_FOREVERVENDETTA1 = "/fv"
SlashCmdList.FOREVERVENDETTA = command

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= addonName then return end
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            local ok, result = pcall(C_ChatInfo.RegisterAddonMessagePrefix, A.PREFIX)
            if not ok or result == false then A.print("Addon messaging unavailable; local blacklist still works.") end
        end
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        if not A.ready and A.init() then A.print("Ready. /fv opens your blacklist; /fv friends sets up sharing.") end
        if A.ready then
            if A.buildMinimap then A.buildMinimap() end
            if A.buildOptions then A.buildOptions() end
            if A.hookTooltips then A.hookTooltips() end
            if A.buildTargetButton then A.buildTargetButton() end
            if A.hookUnitMenus then A.hookUnitMenus() end
            -- One bootstrap sync for LOGIN+PEW; periodic sync still runs every 120s.
            if not A._bootstrapSync then
                A._bootstrapSync = true
                A.sync()
            end
        end
    elseif event == "CHAT_MSG_ADDON" then A.receive(...)
    elseif event == "NAME_PLATE_UNIT_ADDED" then A.detect(...)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        if A.clearPlateBadge then A.clearPlateBadge(...) end
    elseif event == "PLAYER_TARGET_CHANGED" then
        A.detect("target")
        if A.refreshTargetButton then A.refreshTargetButton() end
        if A.scanAttackerFocus then A.scanAttackerFocus() end
    elseif event == "PLAYER_FOCUS_CHANGED" then A.detect("focus")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then A.detect("mouseover")
    elseif event == "PLAYER_DEAD" then if A.onPlayerDead then A.onPlayerDead() end
    elseif event == "PARTY_KILL" then if A.onPartyKill then A.onPartyKill(...) end
    elseif event == "GROUP_ROSTER_UPDATE" then if A.ready then A.sync() end end
end)

frame:SetScript("OnUpdate", function(_, dt)
    if not A.ready then return end
    A.pump(dt)
    scanTime, syncTime = scanTime + dt, syncTime + dt
    if syncTime >= 120 then syncTime = 0; A.sync() end
    if scanTime < 1 then return end
    scanTime = 0
    -- One pass over visible units (badges + alerts). Avoid double plate match work.
    A.detect("target"); A.detect("focus"); A.detect("mouseover")
    if A.scanAttackerFocus then A.scanAttackerFocus() end
    if A.refreshTargetButton then A.refreshTargetButton() end
    local plates = A.call(C_NamePlate and C_NamePlate.GetNamePlates)
    if type(plates) == "table" then
        for _, plate in ipairs(plates) do
            local unit = plate and (plate.namePlateUnitToken or plate.unitToken)
            if A.plain(unit, "string") then A.detect(unit) end
        end
    end
end)

for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "CHAT_MSG_ADDON",
    "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED",
    "UPDATE_MOUSEOVER_UNIT", "PLAYER_DEAD", "PARTY_KILL", "GROUP_ROSTER_UPDATE" }) do
    pcall(frame.RegisterEvent, frame, event)
end
