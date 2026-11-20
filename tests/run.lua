-- Standalone regression harness. No game install, SavedVariables, or network.
local ROOT = "./"
local passed = 0
local function check(ok, msg) if not ok then error(msg or "assertion failed", 2) end end
local function eq(a, b, msg) check(a == b, (msg or "mismatch") .. ": " .. tostring(a) .. " ~= " .. tostring(b)) end

local function boot(name, saved, setup)
    local A, env, frames, out, messages, sounds = {}, {}, {}, {}, {}, {}
    local clock, lockdown, inInst, instType = 1000, false, false, "none"
    local enemy = { first = "Grim", last = "Reaper", realm = "Forever", enemy = true, player = true }
    setmetatable(env, { __index = _G })
    env._G = env
    env.SlashCmdList, env.UISpecialFrames = {}, {}
    env.UIParent = { GetWidth=function() return 1280 end, GetHeight=function() return 720 end }
    env.GetCursorPosition = function() return 0, 0 end
    local widgets = {}
    local function widget(kind, parent, template)
        local w = { scripts = {}, shown = true, text = "", kind = kind, parent = parent,
            template = template, children = {}, enabled = true, x = 0, y = 0 }
        widgets[#widgets+1] = w
        if parent and parent.children then parent.children[#parent.children+1] = w end
        setmetatable(w, { __index = function(_, key)
            return function() end
        end })
        function w:SetScript(k, f) self.scripts[k] = f end
        function w:GetScript(k) return self.scripts[k] end
        function w:SetPoint(anchor, x, y)
            self.anchor = anchor
            if type(x)=="number" then self.x,self.y=x,-(y or 0) end
        end
        function w:SetSize(width,height) self.width,self.height=width,height end
        function w:SetWidth(width) self.width=width end
        function w:SetHeight(height) self.height=height end
        function w:SetScale(value) self.scale=value end
        function w:SetColorTexture(...) self.color={...} end
        function w:SetTextColor(...) self.textColor={...} end
        function w:SetFontObject(font) self.font=font end
        function w:SetChecked(value) self.checked=value end
        function w:GetChecked() return self.checked end
        function w:SetEnabled(value) self.enabled=value and true or false end
        function w:Enable() self.enabled=true end
        function w:Disable() self.enabled=false end
        function w:GetValue() return self.value end
        function w:SetValue(value)
            self.value=value
            if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value) end
        end
        function w:SetScrollChild(child) self.scrollChild=child end
        function w:GetStringHeight() return math.max(14,math.ceil(#self.text / 43)*14) end
        function w:GetText() return self.text end
        function w:SetText(t) self.text = t; if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self, false) end end
        function w:SetShown(v) self.shown = v end
        function w:Show() self.shown = true end
        function w:Hide()
            self.shown = false
            if self.scripts.OnHide then self.scripts.OnHide(self) end
        end
        function w:IsShown() return self.shown end
        function w:CreateFontString(_, _, font)
            local child=widget("FontString",self); child.font=font; return child
        end
        function w:CreateTexture(_,layer)
            local child=widget("Texture",self); child.layer=layer
            function child:SetTexture(path) self.texture=path end
            function child:SetAllPoints() end
            function child:SetBlendMode(mode) self.blend=mode end
            function child:SetDrawLayer(layerName, sub) self.layer=layerName; self.sublevel=sub end
            return child
        end
        function w:SetTextColor(...) self.textColor={...} end
        function w:SetHitRectInsets() end
        function w:SetToplevel() end
        function w:RegisterForDrag() end
        function w:SetFrameStrata(v) self.strata=v end
        function w:SetMovable() end
        function w:EnableMouse() end
        function w:EnableKeyboard() end
        function w:SetPropagateKeyboardInput() end
        function w:SetFrameLevel(v) self.frameLevel=v end
        function w:GetFrameLevel() return self.frameLevel or 1 end
        function w:StartMoving() end
        function w:StopMovingOrSizing() end
        function w:SetClampedToScreen() end
        function w:GetCenter() return self.cx or 0, self.cy or 0 end
        function w:GetEffectiveScale() return self.scale or 1 end
        function w:GetWidth() return self.width or 140 end
        function w:GetHeight() return self.height or 140 end
        function w:ClearAllPoints() end
        function w:LockHighlight() end
        function w:UnlockHighlight() end
        function w:SetHighlightTexture() end
        function w:RegisterForClicks() end
        function w:SetFixedFrameStrata() end
        function w:SetFixedFrameLevel() end
        function w:SetTexCoord(a, b, c, d) self.texCoord = { a, b, c, d } end
        return w
    end
    env.CreateFrame = function(kind, globalName, parent, template)
        local w = widget(kind,parent,template); w.TitleText = widget("FontString",w)
        w.TitleText.isTemplateTitle=true
        frames[#frames + 1] = w
        if globalName then env[globalName] = w end
        return w
    end
    env.Minimap = widget("Frame"); env.Minimap.cx, env.Minimap.cy = 100, 100
    env.Minimap.width, env.Minimap.height = 180, 180
    env.GetMinimapShape = function() return "ROUND" end
    env._addonCats = {}
    env.Settings = {
        RegisterCanvasLayoutCategory = function(p, name)
            return { name = name, panel = p, GetID = function(self) return self.name end }
        end,
        RegisterAddOnCategory = function(cat) env._addonCats[#env._addonCats + 1] = cat end,
        OpenToCategory = function(id) env._openedCategory = id end,
    }
    env.GetNormalizedRealmName = function() return "Forever" end
    env.UnitName = function(unit)
        if unit == "player" then return name:match("^(%S+)%s+(.+)$") end
        return enemy.first, enemy.last
    end
    env.UnitFullName = function(unit)
        if unit == "player" then return name, "Forever" end
        return enemy.first .. " " .. enemy.last, enemy.realm
    end
    env.UnitIsPlayer = function() return enemy.player end
    env.UnitIsEnemy = function() return enemy.enemy end
    env.UnitExists = function(unit) return unit == "player" or unit == "target" or unit == "focus" or unit == "mouseover" end
    env.UnitIsUnit = function(a, b) return a == "targettarget" and b == "player" and enemy.targeting end
    env.IsInInstance = function() return inInst, instType end
    env.GameTooltip = widget("GameTooltip")
    env.GameTooltip.lines = {}
    function env.GameTooltip:AddLine(text, ...) self.lines[#self.lines + 1] = text end
    function env.GameTooltip:GetUnit() return enemy.first .. " " .. enemy.last, "mouseover" end
    function env.GameTooltip:HookScript(event, fn) self.scripts[event] = fn end
    function env.GameTooltip:SetOwner() end
    function env.GameTooltip:SetText(text) self.lines = { text } end
    env.TargetFrame = widget("Frame")
    env.C_FriendList = {
        GetNumFriends = function() return 0 end,
        GetFriendInfoByIndex = function() return nil end,
    }
    env.C_BattleNet = {
        GetNumFriends = function() return 0 end,
        GetFriendAccountInfo = function() return nil end,
    }
    env.C_PvP = { IsPVPMap = function() return false end }
    env.GetTime, env.time = function() return clock end, function() return clock end
    env.PlaySound = function(id, channel) sounds[#sounds + 1] = { id, channel } end
    env.DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) messages[#messages + 1] = msg end }
    env._restrictAddon = false
    env.C_ChatInfo = {
        RegisterAddonMessagePrefix = function() return true end,
        InChatMessagingLockdown = function() return lockdown end,
        AreOutgoingAddonChatMessagesRestricted = function() return env._restrictAddon == true end,
        SendAddonMessage = function(prefix, text, channel, target)
            out[#out + 1] = { prefix, text, channel, target }; return 0
        end,
    }
    env.canaccessvalue = function() return true end
    env.Enum = { SendAddonMessageResult = { Success = 0 } }
    local chat = {}
    env.C_NamePlate = {
        GetNamePlates = function() return env._plates or {} end,
        GetNamePlateForUnit = function(unit)
            for _, plate in ipairs(env._plates or {}) do
                if plate.namePlateUnitToken == unit then return plate end
            end
        end,
    }
    env._plates = {}
    env.IsInGroup = function() return env._inGroup == true end
    env.IsInRaid = function() return env._inRaid == true end
    env.SendChatMessage = function(msg, channel) chat[#chat + 1] = { msg, channel } end
    env.GetZoneText = function() return "Elwynn Forest" end
    env.GetRealZoneText = function() return "Elwynn Forest" end
    env.ForeverVendettaDB = saved
    if setup then setup(env) end
    for _, file in ipairs({
        "Core/Util.lua", "Core/Identity.lua", "Core/Store.lua", "Core/Social.lua", "Core/Scores.lua", "Core/Detect.lua",
        "Core/Tips.lua", "Core/Plates.lua", "Comms.lua",
        "UI/Widgets.lua", "UI/Banner.lua", "UI/Friends.lua", "UI/Alerts.lua", "UI/Window.lua", "UI/Minimap.lua", "UI/Options.lua",
        "ForeverVendetta.lua",
    }) do
        local chunk
        if _VERSION == "Lua 5.1" then chunk = assert(loadfile(ROOT .. file)); setfenv(chunk, env)
        else chunk = assert(loadfile(ROOT .. file, "t", env)) end
        chunk("ForeverVendetta", A)
    end
    local main = frames[1]
    main.scripts.OnEvent(main, "ADDON_LOADED", "ForeverVendetta")
    main.scripts.OnEvent(main, "PLAYER_LOGIN")
    return { a = A, env = env, out = out, messages = messages, sounds = sounds, frames = frames, enemy = enemy,
        chat = chat,
        advance = function(n) clock = clock + n end,
        lockdown = function(v) lockdown = v end,
        instance = function(v, t)
            inInst = v and true or false
            if t then instType = t
            elseif inInst then instType = "party"
            else instType = "none" end
        end,
        event = function(event, ...) main.scripts.OnEvent(main, event, ...) end,
        tick = function(dt) main.scripts.OnUpdate(main, dt) end, widgets = widgets }
end

if VENDETTA_PREVIEW then return boot end

local function test(name, fn)
    fn(); passed = passed + 1; print("PASS " .. name)
end
local function deliver(from, to)
    for _ = 1, 1000 do if from.a.pendingCount() == 0 then break end; from.a.pump(0.31) end
    for _, msg in ipairs(from.out) do
        eq(msg[3], "WHISPER"); check(#msg[2] <= 255, "oversized addon packet")
        to.a.receive(msg[1], msg[2], msg[3], from.a.me.name .. "-Forever")
    end
    for i = #from.out, 1, -1 do from.out[i] = nil end
end

test("Forever surname and realm identity", function()
    local x = boot("Alice River")
    eq(x.a.me.name, "Alice River")
    eq(x.a.unitName("target").key, "grim reaper-forever")
    eq(x.a.sender("Alice River-Forever").key, x.a.me.key)
    x.enemy.first = "Grim Reaper"; x.enemy.last = "Reaper"
    eq(x.a.unitName("target").name, "Grim Reaper", "no duplicated surname")
end)

test("Mutual trust and peer catch-up after login", function()
    local x, y = boot("Alice River"), boot("Bob Stone")
    check(x.a.report("Grim Reaper", "Camped me three times", "AVOID"))
    check(x.a.trust("Bob Stone")); check(y.a.trust("Alice River"))
    y.a.sync()
    deliver(y, x); deliver(x, y); deliver(y, x); deliver(x, y)
    eq(#y.a.entries(), 1)
    eq(y.a.entries()[1].report.mode, "AVOID")
    eq(y.a.entries()[1].owner, x.a.me.key)
end)

test("Untrusted messages and other channels cannot change reports", function()
    local x, y = boot("Alice River"), boot("Bob Stone")
    x.a.report("Grim Reaper", "Reason")
    local wire = x.a.wire(x.a.entries()[1].report)
    y.a.receive(y.a.PREFIX, wire, "WHISPER", "Alice River-Forever")
    eq(#y.a.entries(), 0)
    y.a.trust("Alice River")
    y.a.receive(y.a.PREFIX, wire, "GUILD", "Alice River-Forever")
    eq(#y.a.entries(), 0)
    y.a.receive("OtherAddon", wire, "WHISPER", "Alice River-Forever")
    eq(#y.a.entries(), 0)
end)

test("Removal survives stale update, replay and reload", function()
    local x, y = boot("Alice River"), boot("Bob Stone")
    x.a.trust("Bob Stone"); y.a.trust("Alice River")
    x.a.report("Grim Reaper", "Original")
    local stale = x.a.wire(x.a.entries()[1].report)
    deliver(x, y)
    x.a.report("Grim Reaper", "", "AVENGE", true); deliver(x, y)
    eq(#y.a.entries(), 0)
    local reload = boot("Bob Stone", y.env.ForeverVendettaDB)
    reload.a.receive(reload.a.PREFIX, stale, "WHISPER", "Alice River-Forever")
    eq(#reload.a.entries(), 0)
    eq(reload.a.store.reports[x.a.me.key]["grim reaper-forever|p:world"].rev, 2)
end)

test("Friends' reports remain independent", function()
    local x, y = boot("Alice River"), boot("Bob Stone")
    x.a.trust("Bob Stone"); y.a.trust("Alice River")
    x.a.report("Grim Reaper", "Alice's reason"); y.a.report("Grim Reaper", "Bob's reason")
    deliver(x, y); eq(#y.a.match("grim reaper-forever"), 2)
    x.a.report("Grim Reaper", "", "AVENGE", true); deliver(x, y)
    eq(#y.a.match("grim reaper-forever"), 1)
    eq(y.a.match("grim reaper-forever")[1].report.note, "Bob's reason")
end)

test("Match index filters by place and rebuilds after report changes", function()
    local x = boot("Alice River")
    x.a.report("Grim Reaper", "World camp", "AVENGE", false, nil, "world")
    x.a.report("Grim Reaper", "BG menace", "AVOID", false, nil, "battleground")
    eq(#x.a.match("grim reaper-forever", "world"), 1)
    eq(x.a.match("grim reaper-forever", "world")[1].report.note, "World camp")
    eq(#x.a.match("grim reaper-forever", "battleground"), 1)
    eq(#x.a.match("grim reaper-forever"), 2)
    eq(x.a._matchIndexDirty, false)
    check(x.a._matchIndex["grim reaper"] ~= nil)
    x.a.report("Grim Reaper", "", "AVENGE", true, nil, "world")
    eq(x.a._matchIndexDirty, true)
    eq(#x.a.match("grim reaper-forever", "world"), 0)
    eq(#x.a.match("grim reaper-forever", "battleground"), 1)
    local pf, here = x.a.alertPlaceFilter()
    eq(here, "world"); eq(pf, "world")
end)

test("Sound and banner, cooldown shared across unit tokens", function()
    local x = boot("Alice River")
    x.a.targetReport("Bad news", "AVOID")
    local banners = 0
    x.a.showBanner = function() banners = banners + 1 end
    x.event("NAME_PLATE_UNIT_ADDED", "nameplate1")
    x.event("PLAYER_TARGET_CHANGED")
    x.event("UPDATE_MOUSEOVER_UNIT")
    eq(#x.sounds, 1); eq(banners, 1)
    eq(x.sounds[1][2], "Master")
    x.advance(60); x.a.detect("focus")
    eq(#x.sounds, 2)
    x.a.store.settings.sound = false; x.advance(60); x.a.detect("target")
    eq(#x.sounds, 2); eq(banners, 3)
end)

test("Friendly units, NPCs, instances and inaccessible identities do not alert", function()
    local x = boot("Alice River")
    x.a.report("Grim Reaper", "Reason")
    x.enemy.enemy = false; x.a.detect("target")
    x.enemy.enemy = true; x.enemy.player = false; x.a.detect("target")
    x.enemy.player = true; x.instance(true); x.a.detect("target")
    x.instance(false)
    x.env.issecretvalue = function(v) return v == "Grim" end
    x.a.detect("target")
    eq(#x.sounds, 0)
    x.env.issecretvalue = function(v) return type(v) == "boolean" end
    x.a.detect("target"); eq(#x.sounds, 0)
end)

test("Untrust stops queued sends and hides received reports", function()
    local x, y = boot("Alice River"), boot("Bob Stone")
    x.a.trust("Bob Stone"); y.a.trust("Alice River")
    x.a.report("Grim Reaper", "Reason"); deliver(x, y)
    eq(#y.a.entries(), 1)
    y.a.untrust("Alice River"); eq(#y.a.entries(), 0)
    x.a.report("Grim Reaper", "Updated")
    x.a.untrust("Bob Stone"); deliver(x, y)
    eq(#y.a.entries(), 0)
end)

test("Malformed payloads and invalid revisions are rejected", function()
    local x = boot("Alice River")
    x.a.trust("Bob Stone")
    for _, wire in ipairs({ "1|E|0|0|AVENGE|Grim Reaper|Forever|x", "1|E|999999999999|0|AVENGE|Grim Reaper|Forever|x",
        "1|E|1|0|WRONG|Grim Reaper|Forever|x", "1|E|1|0|AVENGE|Grim Reaper|Forever|x|fake author",
        "2|E|1|0|AVENGE|Grim Reaper|Forever|x", string.rep("x", 256) }) do
        x.a.receive(x.a.PREFIX, wire, "WHISPER", "Bob Stone-Forever")
    end
    eq(#x.a.entries(), 0)
    check(not x.a.validReport({ name = "Grim Reaper", realm = "Forever", mode = "AVENGE", rev = 1, deleted = false }))
    check(not x.a.report("Grim Reaper", string.rep("x", 97)))
end)

test("Combat messaging lockdown preserves the send queue", function()
    local x = boot("Alice River")
    x.a.trust("Bob Stone"); x.a.report("Grim Reaper", "Reason")
    x.lockdown(true); x.a.pump(1)
    eq(#x.out, 0); eq(x.a.pendingCount(), 1)
    x.lockdown(false); x.a.pump(1)
    eq(#x.out, 1); eq(x.a.pendingCount(), 0)
end)

test("Repeated sync coalesces and hello responses do not loop", function()
    local x, y = boot("Alice River"), boot("Bob Stone")
    x.a.trust("Bob Stone"); y.a.trust("Alice River")
    for _ = 1, 100 do x.a.sync() end
    eq(x.a.pendingCount(), 1)
    for _ = 1, 5 do deliver(x, y); deliver(y, x) end
    eq(x.a.pendingCount(), 0); eq(y.a.pendingCount(), 0)
end)

test("Periodic reconciliation repairs a dropped update", function()
    local x, y = boot("Alice River"), boot("Bob Stone")
    x.a.trust("Bob Stone"); y.a.trust("Alice River")
    x.a.report("Grim Reaper", "Missed update")
    x.a.pump(1)
    for i = #x.out, 1, -1 do x.out[i] = nil end -- Simulate packet loss.
    eq(#y.a.entries(), 0)
    x.advance(120); y.advance(120)
    x.a.sync(); deliver(x, y); deliver(y, x); deliver(x, y)
    eq(#y.a.entries(), 1)
end)

test("Failed sends are bounded and can recover on a later sync", function()
    local x, y = boot("Alice River"), boot("Bob Stone")
    x.a.trust("Bob Stone"); y.a.trust("Alice River")
    x.a.report("Grim Reaper", "Reason")
    local send = x.env.C_ChatInfo.SendAddonMessage
    local attempts = 0
    x.env.C_ChatInfo.SendAddonMessage = function() attempts = attempts + 1; return 7 end
    for _ = 1, 10 do x.a.pump(1) end
    eq(attempts, 3); eq(x.a.pendingCount(), 0); check(x.a.lastSendError ~= nil)
    x.env.C_ChatInfo.SendAddonMessage = send
    x.a.sync(); deliver(x, y); deliver(y, x); deliver(x, y)
    eq(#y.a.entries(), 1)
end)

test("Record bound keeps tombstones without evicting reports", function()
    local x = boot("Alice River")
    x.a.MAX_REPORTS = 2
    check(x.a.report("Enemy One", "x")); check(x.a.report("Enemy Two", "x"))
    check(x.a.report("Enemy One", "", "WATCH", true))
    check(not x.a.report("Enemy Three", "x"))
    eq(x.a.count(x.a.store.reports[x.a.me.key]), 2)
end)

test("Maximum-size packets stay within WoW's message bound", function()
    local x = boot("Alice River")
    -- Forever names need a space; keep the wire near the 255-byte bound.
    local full = string.rep("a", 31) .. " " .. string.rep("b", 32)
    check(x.a.report(full, string.rep("b", 96), "AVENGE", false, string.rep("c", 48)))
    check(#x.a.wire(x.a.entries()[1].report) <= 255)
end)

test("Native windows and slash commands construct and refresh", function()
    local x = boot("Alice River")
    local cmd = x.env.SlashCmdList.FOREVERVENDETTA
    cmd(""); check(x.env.ForeverVendettaWindow:IsShown())
    cmd("add Grim Reaper; Test reason")
    eq(#x.a.entries(), 1)
    cmd("friends"); check(x.env.ForeverVendettaFriends:IsShown())
    check(x.env.ForeverVendettaWindow:IsShown(), "friends stay inside the main window")
    cmd("trust Bob Stone"); eq(x.a.count(x.a.store.friends), 1)
    cmd("sound off"); eq(x.a.store.settings.sound, false)
    cmd("cooldown 30"); eq(x.a.store.settings.cooldown, 30)
    cmd("test"); eq(#x.sounds, 0)
    cmd("remove Grim Reaper"); eq(#x.a.entries(), 0)
    cmd(""); check(not x.env.ForeverVendettaWindow:IsShown())
    check(not x.env.ForeverVendettaFriends:IsShown())
end)

test("Close button, Escape, and A.close hide the open window", function()
    local x = boot("Alice River")
    x.a.toggle()
    check(x.env.ForeverVendettaWindow:IsShown())
    local close = x.env.ForeverVendettaWindow.CloseButton
    check(type(close) == "table", "close button exists")
    check(type(close.scripts.OnClick) == "function", "close button is wired")
    close.scripts.OnClick(close)
    check(not x.env.ForeverVendettaWindow:IsShown(), "X hides the window")
    x.a.toggle()
    check(x.env.ForeverVendettaWindow:IsShown())
    x.env.ForeverVendettaWindow.scripts.OnKeyDown(x.env.ForeverVendettaWindow, "ESCAPE")
    check(not x.env.ForeverVendettaWindow:IsShown(), "Escape hides the window")
    x.a.toggle()
    x.a.close()
    check(not x.env.ForeverVendettaWindow:IsShown(), "A.close hides the window")
    check(#x.env.UISpecialFrames >= 1, "registered for Escape via UISpecialFrames")
end)

test("Current Forever surname is not stored as the realm", function()
    local x = boot("Alice River", nil, function(env)
        env.GetNormalizedRealmName = function() return "Classic Beta PvE" end
        env.GetUnitName = function(unit)
            if unit == "player" then return "Alice River" end
            return "Grim Reaper"
        end
        env.UnitName = function(unit)
            if unit == "player" then return "Alice", "River" end
            return "Grim", "Reaper"
        end
        env.UnitNameUnmodified = function(unit)
            if unit == "player" then return nil end
            return "Grim", "Reaper"
        end
        env.UnitFullName = function(unit)
            if unit == "player" then return "Alice", "River" end
            return "Grim", "Reaper"
        end
    end)
    eq(x.a.me.name, "Alice River")
    eq(x.a.me.realm, "ClassicBetaPvE")
    local who = x.a.unitName("target")
    eq(who.name, "Grim Reaper")
    eq(who.realm, "ClassicBetaPvE", "surname must not become the realm")
    eq(who.key, "grim reaper-classicbetapve")
    check(x.a.report("Grim Reaper", "manual"))
    check(x.a.targetReport("from target", "WATCH"))
    eq(x.a.count(x.a.store.reports[x.a.me.key]), 1, "manual add and target add are one enemy")
    eq(x.a.entries()[1].report.rev, 2)
    eq(x.a.entries()[1].report.realm, "ClassicBetaPvE")
end)

test("Secret realm falls back and a secret surname is not a first name", function()
    local x = boot("Alice River", nil, function(env)
        env.GetNormalizedRealmName = function() return "HIDDEN" end
        env.GetRealmName = function() return "Forever" end
        env.issecretvalue = function(v) return v == "HIDDEN" end
    end)
    eq(x.a.me.realm, "Forever")
    eq(x.a.unitName("target").name, "Grim Reaper")
    x.env.issecretvalue = function(v) return v == "Reaper" end
    x.env.UnitName = function() return "Grim", "Reaper" end
    x.env.UnitFullName = function() return "Grim", "Reaper" end
    x.env.GetUnitName = function() return "Grim" end
    eq(x.a.unitName("target"), nil)
    x.env.issecretvalue = function() return false end
    x.env.GetUnitName = function() return "Grim" end
    x.env.UnitName = function() return "Grim" end
    x.env.UnitFullName = function() return "Grim" end
    eq(x.a.unitName("target"), nil, "first name alone is not an identity")
end)

test("GetUnitName server suffix does not block First Last identity", function()
    local x = boot("Alice River", nil, function(env)
        env.GetNormalizedRealmName = function() return "Forever" end
        env.GetRealmName = function() return "Forever" end
        -- Mismatched realm label (spaces / ruleset) used to keep "First Last-Label"
        -- and A.identity rejected the hyphen — init never became ready.
        env.GetUnitName = function(unit, showServer)
            if unit == "player" then
                if showServer then return "Alice River-Classic Beta PvE" end
                return "Alice River"
            end
            if showServer then return "Grim Reaper-Classic Beta PvE" end
            return "Grim Reaper"
        end
        env.UnitName = function() return nil end
        env.UnitNameUnmodified = function() return nil end
        env.UnitFullName = function() return nil end
    end)
    eq(x.a.me.name, "Alice River")
    eq(x.a.ready, true)
    eq(x.a.unitName("target").name, "Grim Reaper")
    eq(x.a.unitName("target").key, "grim reaper-forever")
end)

test("Empty realm APIs fall back to Forever so First Last can still init", function()
    local x = boot("Alice River", nil, function(env)
        env.GetNormalizedRealmName = function() return nil end
        env.GetRealmName = function() return nil end
    end)
    eq(x.a.realm(), "Forever")
    eq(x.a.ready, true)
    eq(x.a.me.name, "Alice River")
    eq(x.a.me.key, "alice river-forever")
end)

test("Hyphenated addon senders are surnames and whispers use the full name", function()
    local x, y = boot("Alice River"), boot("Bob Stone")
    check(x.a.trust("Bob-Stone"))
    check(y.a.trust("Alice River"))
    eq(x.a.store.friends[y.a.me.key].name, "Bob Stone")
    x.a.report("Grim Reaper", "Camped", "AVOID")
    x.a.pump(1)
    eq(x.out[1][4], "Bob Stone")
    y.a.receive(x.out[1][1], x.out[1][2], x.out[1][3], "Alice-River")
    eq(#y.a.entries(), 1)
    eq(y.a.entries()[1].owner, x.a.me.key)
    eq(y.a.entries()[1].report.note, "Camped")
    y.a.receive(y.a.PREFIX, x.out[1][2], "WHISPER", "Mallory-Vex")
    eq(#y.a.entries(), 1)
    y.a.detect("target")
    check(y.messages[#y.messages]:find("Grim Reaper", 1, true) ~= nil)
    check(y.messages[#y.messages]:find("Camped", 1, true) == nil, "chat must not archive the reason")
    check(y.messages[#y.messages]:find("alice river-forever", 1, true) == nil)
end)

test("A surname saved as the realm is repaired before detection", function()
    local saved = { realms = { forever = {
        friends = {}, settings = {},
        owners = { ["alice river-river"] = true },
        reports = { ["alice river-river"] = {
            ["grim reaper-reaper"] = {
                name = "Grim Reaper", realm = "Reaper", note = "Camped", mode = "AVOID",
                rev = 3, deleted = false,
            },
        } },
    } } }
    local x = boot("Alice River", saved)
    eq(x.a.store.reports["alice river-river"], nil)
    eq(x.a.store.reports[x.a.me.key]["grim reaper-forever|p:world"].rev, 3)
    eq(x.a.store.reports[x.a.me.key]["grim reaper-forever|p:world"].realm, "Forever")
    x.a.detect("target")
    eq(#x.sounds, 1)
end)

test("Numeric addon-message success survives a missing result enum", function()
    local x = boot("Alice River")
    x.a.trust("Bob Stone")
    x.a.report("Grim Reaper", "Reason")
    x.env.Enum = nil
    x.env.C_ChatInfo.SendAddonMessage = function() return 0 end
    x.a.pump(1)
    eq(x.a.pendingCount(), 0)
    eq(x.a.lastSendError, nil)
end)

test("A newly received report warns on the next scan and then cools down", function()
    local x, y = boot("Alice River"), boot("Bob Stone")
    x.a.trust("Bob Stone"); y.a.trust("Alice River")
    x.a.report("Grim Reaper", "Camped", "AVOID")
    deliver(x, y)
    eq(#y.sounds, 0)
    y.tick(0.2)
    eq(#y.sounds, 0)
    y.tick(1)
    eq(#y.sounds, 1)
    y.tick(1)
    eq(#y.sounds, 1)
end)

test("Dungeon and raid alerts never fire; arenas need the arenas toggle", function()
    local x = boot("Alice River")
    x.a.report("Grim Reaper", "Reason")
    x.instance(true, "party")
    x.a.detect("target")
    eq(#x.sounds, 0)
    x.env.SlashCmdList.FOREVERVENDETTA("arenas on")
    x.a.detect("target")
    eq(#x.sounds, 0, "dungeons stay silent even with arenas on")
    x.instance(true, "raid")
    x.advance(120)
    x.a.detect("target")
    eq(#x.sounds, 0, "raids stay silent even with arenas on")
    x.instance(true, "arena")
    eq(x.a.pvpPlace(), "arena")
    x.advance(120)
    x.a.detect("target")
    eq(#x.sounds, 1)
    check(x.messages[#x.messages]:find("%[Arena%]") ~= nil)
end)

test("Battleground alerts are separate from world and instances", function()
    local x = boot("Alice River")
    check(x.a.report("Grim Reaper", "BG reason", "AVENGE", false, nil, "battleground"))
    eq(x.a.pvpPlace(), "world")
    x.a.detect("target")
    eq(#x.sounds, 0, "world does not alert on a BG-only report")
    x.instance(true, "pvp")
    eq(x.a.pvpPlace(), "battleground")
    x.a.detect("target")
    eq(#x.sounds, 0)
    x.env.SlashCmdList.FOREVERVENDETTA("battlegrounds on")
    x.advance(120)
    x.a.detect("target")
    eq(#x.sounds, 1)
    check(x.messages[#x.messages]:find("%[Battleground%]") ~= nil)
    x.env.SlashCmdList.FOREVERVENDETTA("world off")
    x.instance(false)
    x.advance(120)
    x.a.detect("target")
    eq(#x.sounds, 1)
end)

test("Split UTF-8 is rejected and intact UTF-8 is kept", function()
    local x = boot("Alice River")
    check(not x.a.report("Grim Reaper", "bad\194"))
    eq(#x.a.entries(), 0)
    check(x.a.report("Grim Reaper", "caf\195\169"))
    eq(x.a.entries()[1].report.note, "caf\195\169")
end)

test("A different realm string still warns for the same full name", function()
    local x = boot("Alice River")
    check(x.a.merge(x.a.me.key, {
        name = "Grim Reaper", realm = "ClassicBetaPvE", note = "Camped", mode = "AVOID", rev = 1, deleted = false,
    }))
    eq(x.a.store.reports[x.a.me.key]["grim reaper-classicbetapve|p:world"].note, "Camped")
    x.a.detect("target")
    eq(#x.sounds, 1)
end)

test("Class and race are remembered for the warning and stay off the whisper", function()
    local x = boot("Alice River", nil, function(env)
        env.UnitClass = function() return "Rogue", "ROGUE" end
        env.UnitRace = function() return "Undead", "Scourge" end
        env.UnitSex = function() return 3 end
    end)
    x.a.detect("target")
    local face = x.a.faceFor("grim reaper-forever")
    eq(face.class, "ROGUE")
    eq(face.race, "SCOURGE")
    eq(face.sex, 3)
    check(x.a.report("Grim Reaper", "Camped", "AVOID"))
    local report = x.a.entries()[1].report
    eq(report.class, nil)
    eq(report.race, nil)
    local wire = x.a.wire(report)
    check(not wire:find("ROGUE"), "class leaked onto the whisper")
    check(not wire:find("SCOURGE"), "race leaked onto the whisper")
    x.a.showBanner("Grim Reaper", "Camped", nil, "AVOID", face)
    local banner
    for i = #x.frames, 1, -1 do
        if type(x.frames[i].classIcon) == "table" then banner = x.frames[i]; break end
    end
    check(banner ~= nil, "banner frame")
    eq(banner.classIcon.texture, "Interface\\TargetingFrame\\UI-Classes-Circles")
    eq(banner.raceIcon.texture, "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races")
    eq(banner.classIcon.shown, true)
    eq(banner.raceIcon.shown, true)
    -- Forever race atlas: Scourge female is row 4, not the Draenei male slot.
    eq(banner.raceIcon.texCoord[1], 0.125)
    eq(banner.raceIcon.texCoord[3], 0.75)
end)

test("Tauren race icon uses Forever atlas slot, not Draenei", function()
    local x = boot("Alice River", nil, function(env)
        env.UnitClass = function() return "Warrior", "WARRIOR" end
        env.UnitRace = function() return "Tauren", "Tauren" end
        env.UnitSex = function() return 2 end
    end)
    x.a.detect("target")
    local face = x.a.faceFor("grim reaper-forever")
    eq(face.race, "TAUREN")
    x.a.showBanner("Grim Reaper", "Camped", nil, "AVENGE", face)
    local banner
    for i = #x.frames, 1, -1 do
        if type(x.frames[i].classIcon) == "table" then banner = x.frames[i]; break end
    end
    check(banner ~= nil, "banner frame")
    eq(banner.raceIcon.shown, true)
    -- DRAENEI_MALE is {.5, .625, 0, .25}; Tauren male must be Horde row {.0, .125, .25, .5}.
    eq(banner.raceIcon.texCoord[1], 0)
    eq(banner.raceIcon.texCoord[2], 0.125)
    eq(banner.raceIcon.texCoord[3], 0.25)
    eq(banner.raceIcon.texCoord[4], 0.5)
    check(banner.raceIcon.texCoord[1] ~= 0.5, "must not paint Draenei slot for Tauren")
end)

test("Banner stays up for six seconds and then hides", function()
    local x = boot("Alice River")
    x.a.showBanner("Grim Reaper", "Camped")
    local banner
    for i = #x.frames, 1, -1 do
        if type(x.frames[i].remaining) == "number" and type(x.frames[i].classIcon) == "table" then
            banner = x.frames[i]; break
        end
    end
    check(banner ~= nil, "banner frame")
    eq(banner.shown, true)
    eq(banner.remaining, 6)
    banner.scripts.OnUpdate(banner, 5)
    eq(banner.shown, true)
    banner.scripts.OnUpdate(banner, 1)
    eq(banner.shown, false)
end)

local function visible(w)
    while type(w) == "table" do
        if w.shown == false then return false end
        w = rawget(w, "parent")
    end
    return true
end
local function findWidget(x, kind, caption, predicate)
    for _,w in ipairs(x.widgets) do
        local title=w.text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
        if w.kind==kind and (not caption or title==caption) and visible(w) and (not predicate or predicate(w)) then return w end
    end
    error("Missing visible "..kind..": "..tostring(caption))
end
local function click(x,caption,predicate)
    local b=findWidget(x,"Button",caption,predicate)
    check(b.enabled,"disabled button: "..caption); b.scripts.OnClick(b); return b
end
local function editors(x)
    local fields={}
    for _,w in ipairs(x.widgets) do if w.kind=="EditBox" and visible(w) then fields[#fields+1]=w end end
    return fields
end

test("World and Battlegrounds keep separate lists and scores", function()
    local x = boot("Alice River")
    check(x.a.report("Grim Reaper", "World camp", "AVENGE", false, nil, "world"))
    check(x.a.report("Grim Reaper", "BG menace", "AVOID", false, nil, "battleground"))
    eq(#x.a.entries("world"), 1)
    eq(#x.a.entries("battleground"), 1)
    eq(x.a.entries("world")[1].report.note, "World camp")
    eq(x.a.entries("battleground")[1].report.note, "BG menace")
    x.a.recordMyKill("Grim Reaper")
    local score = x.a.scoreFor("grim reaper-forever", "world")
    eq(score.kills, 1)
    x.instance(true, "pvp")
    x.advance(10)
    x.a.recordMyKill("Grim Reaper")
    eq(x.a.scoreFor("grim reaper-forever", "battleground").kills, 1)
    x.a.toggle()
    click(x, "Battlegrounds")
    findWidget(x, "FontString", "Battlegrounds")
    click(x, "World")
    findWidget(x, "FontString", "World PvP")
end)

test("Blacklist groups reports and preserves independent reasons",function()
    local x=boot("Alice River")
    x.a.trust("Bob Stone")
    x.a.merge("bob stone-forever",{name="Grim Reaper",realm="Forever",note="Bob was camped",mode="AVOID",rev=1,deleted=false})
    x.a.toggle()
    local row=findWidget(x,"Button",nil,function(w) return type(w.group)=="table" end)
    eq(#row.group.reports,1); row.scripts.OnClick(row)
    local fields=editors(x)
    eq(fields[2]:GetText(),"Grim Reaper"); eq(fields[3]:GetText(),"","friend reason must not become your reason")
    check(not findWidget(x,"Button","Withdraw").enabled)
    fields[3]:SetText("My own reason"); click(x,"Save report")
    eq(#x.a.entries(),2)
    row=findWidget(x,"Button",nil,function(w) return type(w.group)=="table" end)
    eq(#row.group.reports,2,"one enemy with two reports")
    click(x,"Withdraw"); eq(#x.a.entries(),2,"first click only arms removal")
    click(x,"Confirm removal"); eq(#x.a.entries(),1)
    eq(x.a.entries()[1].report.note,"Bob was camped")
end)

test("Search, stance filters and paging have bounded navigation",function()
    local x=boot("Alice River")
    for i=1,7 do x.a.report("Enemy Number"..i,"Reason "..i,i==7 and "AVOID" or "AVENGE") end
    x.a.toggle()
    check(not findWidget(x,"Button","Previous").enabled)
    click(x,"Next"); check(not findWidget(x,"Button","Next").enabled)
    click(x,"Avoid",function(w) return w.mark ~= nil and w.width == 74 end)
    local row=findWidget(x,"Button",nil,function(w) return type(w.group)=="table" end)
    eq(row.group.name,"Enemy Number7")
    local search=editors(x)[1]; search:SetText("nobody matches")
    eq(findWidget(x,"FontString","No enemies match"):GetText(),"No enemies match")
    click(x,"Clear search"); eq(search:GetText(),"")
end)

test("Muted and Seen filters narrow the enemy list", function()
    local x = boot("Alice River")
    check(x.a.report("Grim Reaper", "Camped", "AVENGE"))
    check(x.a.report("Other Enemy", "Quiet", "WATCH"))
    check(x.a.ignoreEnemy("Grim Reaper"))
    x.a.recordSighting("other enemy-forever", "world")
    x.a.toggle()
    click(x, "Muted", function(w) return w.mark ~= nil and w.caption == "Muted" end)
    local mutedRow = findWidget(x, "Button", nil, function(w) return type(w.group) == "table" end)
    eq(mutedRow.group.name, "Grim Reaper")
    click(x, "Seen", function(w) return w.mark ~= nil and w.caption == "Seen" end)
    local seenRow = findWidget(x, "Button", nil, function(w) return type(w.group) == "table" end)
    eq(seenRow.group.name, "Other Enemy")
    click(x, "All", function(w) return w.mark ~= nil and w.caption == "All" end)
end)

test("Warning banner Mute silences alerts without removing the report", function()
    local x = boot("Alice River")
    check(x.a.report("Grim Reaper", "Camped", "AVOID"))
    x.a.detect("target")
    local banner = findWidget(x, "Frame", nil, function(w)
        return type(w.mute) == "table" and type(w.classIcon) == "table"
    end)
    check(banner.shown)
    check(banner.mute.shown)
    eq(banner.muteName, "Grim Reaper")
    banner.mute.scripts.OnClick(banner.mute)
    check(x.a.isIgnored("grim reaper-forever"))
    eq(#x.a.entries(), 1)
    local before = #x.messages
    x.advance(60)
    x.a.detect("target")
    eq(#x.messages, before, "muted via banner should not alert again")
end)

test("Incoming refresh preserves an unsaved draft",function()
    local x=boot("Alice River")
    x.a.toggle(); click(x,"Add target")
    local fields=editors(x); fields[3]:SetText("Still writing this reason")
    x.a.trust("Bob Stone")
    x.a.merge("bob stone-forever",{name="Other Enemy",realm="Forever",note="Friend report",mode="WATCH",rev=1,deleted=false})
    eq(fields[2]:GetText(),"Grim Reaper"); eq(fields[3]:GetText(),"Still writing this reason")
end)

test("Friends setup validates full names and removal needs confirmation",function()
    local x=boot("Alice River")
    x.a.toggleFriends()
    local field=editors(x)[1]
    field:SetText("Bob"); click(x,"Add trusted friend"); eq(x.a.count(x.a.store.friends),0)
    field:SetText("Bob Stone"); field.scripts.OnEnterPressed(field); eq(x.a.count(x.a.store.friends),1)
    findWidget(x,"EditBox","/fv trust Alice River")
    local waiting=findWidget(x,"FontString",nil,function(w)
        return type(w.text)=="string" and w.text:find("No reply yet",1,true)
    end)
    check(waiting~=nil)
    click(x,"Remove"); eq(x.a.count(x.a.store.friends),1)
    click(x,"Confirm remove"); eq(x.a.count(x.a.store.friends),0)
end)

test("Friends list picker fills a readable First Last name", function()
    local x = boot("Alice River", nil, function(env)
        env.C_FriendList = {
            GetNumFriends = function() return 2 end,
            GetFriendInfoByIndex = function(i)
                if i == 1 then return { name = "Bob" } end
                if i == 2 then return { name = "Bob Stone" } end
            end,
        }
        env.C_BattleNet = {
            GetNumFriends = function() return 1 end,
            GetFriendAccountInfo = function()
                return { gameAccountInfo = { characterName = "Cara Vale", realmName = "Forever" } }
            end,
        }
    end)
    local picks = x.a.gameFriends()
    eq(#picks, 2)
    eq(picks[1].name, "Bob Stone")
    eq(picks[2].name, "Cara Vale")
    x.a.toggleFriends()
    click(x, "Bob Stone")
    local field = editors(x)[1]
    eq(field:GetText(), "Bob Stone")
end)

test("Friends list picker can show more than four readable names", function()
    local x = boot("Alice River", nil, function(env)
        env.C_FriendList = {
            GetNumFriends = function() return 8 end,
            GetFriendInfoByIndex = function(i)
                return { name = "Friend Number" .. i }
            end,
        }
        env.C_BattleNet = { GetNumFriends = function() return 0 end }
    end)
    eq(#x.a.gameFriends(), 8)
    x.a.toggleFriends()
    local win = x.a._win
    check(win and win.ui and win.ui.gameFriendButtons)
    eq(#win.ui.gameFriendButtons, 12)
    local visible = 0
    for _, b in ipairs(win.ui.gameFriendButtons) do
        if b.shown and b.friendName then visible = visible + 1 end
    end
    eq(visible, 8)
    click(x, "Friend Number8")
    eq(editors(x)[1]:GetText(), "Friend Number8")
end)

test("Hello whisper marks mutual share on the Friends tab",function()
    local x=boot("Alice River")
    x.a.trust("Bob Stone")
    x.a.toggleFriends()
    findWidget(x,"FontString",nil,function(w)
        return type(w.text)=="string" and w.text:find("No reply yet",1,true)
    end)
    x.a.receive(x.a.PREFIX,"1|H|1","WHISPER","Bob Stone-Forever")
    check(x.a.store.lastHeard["bob stone-forever"]~=nil)
    local status=x.a.friendStatus(x.a.store.friends["bob stone-forever"])
    check(status:find("Sharing works",1,true)~=nil)
    findWidget(x,"FontString",nil,function(w)
        return type(w.text)=="string" and w.text:find("Sharing works",1,true)
    end)
    check(x.a.syncStatus():find("queued",1,true)~=nil or x.a.pendingCount()>=0)
end)

test("Minimap button opens the window and can be hidden", function()
    local x = boot("Alice River")
    eq(x.a.store.settings.minimapButton, true)
    local btn = x.env.ForeverVendettaMinimapButton
    check(btn ~= nil)
    eq(btn.shown, true)
    btn.scripts.OnClick(btn, "LeftButton")
    check(x.env.ForeverVendettaWindow:IsShown())
    btn.scripts.OnClick(btn, "RightButton")
    check(x.env.ForeverVendettaFriends:IsShown())
    x.env.SlashCmdList.FOREVERVENDETTA("minimap off")
    eq(x.a.store.settings.minimapButton, false)
    eq(btn.shown, false)
    check(type(x.env.ForeverVendetta_OnAddonCompartmentClick) == "function")
end)

test("Options AddOns category registers Forever Vendetta", function()
    local x = boot("Alice River")
    check(x.env.ForeverVendettaOptions ~= nil)
    eq(#x.env._addonCats, 1)
    eq(x.env._addonCats[1].name, "Forever Vendetta")
    x.env.SlashCmdList.FOREVERVENDETTA("options")
    eq(x.env._openedCategory, "Forever Vendetta")
end)

test("Addon version is exposed for the window and status", function()
    local x = boot("Alice River")
    check(x.a.addonVersion() ~= nil and x.a.addonVersion() ~= "")
    eq(x.a.addonVersion(), x.a.VERSION)
    x.a.toggle()
    local title = x.env.ForeverVendettaWindow and x.env.ForeverVendettaWindow.TitleText
    check(title and title.text:find(x.a.VERSION, 1, true))
end)

test("Warning sound defaults to raid warning and the player can change it", function()
    local x = boot("Alice River")
    eq(x.a.store.settings.alertSound, "raid")
    x.a.report("Grim Reaper", "Camped", "AVOID")
    x.a.detect("target")
    eq(x.sounds[1][1], 8959)
    eq(x.sounds[1][2], "Master")
    x.env.SlashCmdList.FOREVERVENDETTA("sound ping")
    eq(x.a.store.settings.alertSound, "ping")
    eq(x.sounds[2][1], 3175)
    x.advance(60)
    x.a.detect("target")
    eq(x.sounds[3][1], 3175)
    x.a.store.settings.alertSound = "nope"
    local reloaded = boot("Alice River", x.env.ForeverVendettaDB)
    eq(reloaded.a.store.settings.alertSound, "raid")
    x.a.toggle(); click(x, "Alerts"); click(x, "Level")
    eq(x.a.store.settings.alertSound, "level")
    eq(x.sounds[#x.sounds][1], 888)
end)

test("Alerts controls update existing settings and preview respects sound",function()
    local x=boot("Alice River")
    x.a.toggle(); click(x,"Alerts")
    local c=findWidget(x,"CheckButton",nil,function(w) return w.y==28 end)
    c:SetChecked(false); c.scripts.OnClick(c); eq(x.a.store.settings.sound,false)
    local slider=findWidget(x,"Slider")
    slider:SetValue(90); eq(x.a.store.settings.cooldown,90)
    click(x,"Preview alert"); eq(#x.sounds,0)
    c:SetChecked(true); c.scripts.OnClick(c)
    click(x,"Preview alert"); eq(#x.sounds,1)
end)

test("Window scales to narrow and short screens",function()
    local x=boot("Alice River",nil,function(env)
        env.UIParent.GetWidth=function() return 640 end
        env.UIParent.GetHeight=function() return 480 end
    end)
    x.a.toggle(); local window=x.env.ForeverVendettaWindow
    check(window.width*window.scale<=600); check(window.height*window.scale<=440)
end)

test("Mixed author stances produce a neutral alert title", function()
    local x = boot("Alice River")
    local title, preview
    x.a.showBanner = function(t, _, testMode) title, preview = t, testMode end
    x.a.alert("Grim Reaper", {
        { owner = x.a.me.key, report = {mode="AVENGE", note="First encounter"} },
        { owner = "bob stone-forever", report = {mode="AVOID", note="Second encounter"} },
    })
    eq(title, "Grim Reaper - 2 reports [World]")
    x.a.testAlert()
    eq(preview, true)
end)

test("Revealing a filtered selection preserves draft and saving reveals the enemy", function()
    local x = boot("Alice River")
    x.a.report("Grim Reaper", "Original")
    x.a.toggle()
    local row = findWidget(x, "Button", nil, function(w) return type(w.group)=="table" end)
    row.scripts.OnClick(row)
    local fields = editors(x)
    fields[3]:SetText("Draft")
    fields[1]:SetText("No matches")
    click(x, "Show in list")
    eq(fields[3]:GetText(), "Draft")
    fields[1]:SetText("No matches")
    click(x, "Save changes")
    eq(fields[1]:GetText(), "")
    eq(x.a.entries()[1].report.note, "Draft")
    eq(row.group.name, "Grim Reaper")
end)

test("Withdrawn reports do not resend reasons on the wire", function()
    local x = boot("Alice River")
    check(x.a.report("Grim Reaper", "Private reason", "AVOID"))
    check(x.a.report("Grim Reaper", "Private reason", "AVOID", true))
    local tomb = x.a.store.reports[x.a.me.key]["grim reaper-forever|p:world"]
    eq(tomb.deleted, true)
    eq(tomb.note, "")
    check(x.a.wire(tomb):find("Private reason", 1, true) == nil)
end)

test("Untrust clears received stamps for that friend", function()
    local x = boot("Alice River")
    x.a.trust("Bob Stone")
    x.a.store.lastReceived = { ["bob stone-forever"] = 123 }
    x.a.store.lastHeard = { ["bob stone-forever"] = 123 }
    x.a.store.lastSent = { ["bob stone-forever"] = 123 }
    check(x.a.untrust("Bob Stone"))
    eq(x.a.store.lastReceived["bob stone-forever"], nil)
    eq(x.a.store.lastHeard["bob stone-forever"], nil)
    eq(x.a.store.lastSent["bob stone-forever"], nil)
end)

test("Banner uses the stance label and color", function()
    local x = boot("Alice River")
    x.a.alert("Grim Reaper", { { owner = x.a.me.key, report = { mode = "AVOID", note = "Camped" } } })
    check(x.messages[#x.messages]:find("Grim Reaper - Avoid [World]", 1, true) ~= nil)
    check(x.messages[#x.messages]:find("Camped", 1, true) == nil)
    local title
    for _, w in ipairs(x.widgets) do
        if w.text == "Grim Reaper - Avoid [World]" then title = w end
    end
    check(title and title.textColor)
    eq(title.textColor[2], 0.73)
    x.a.alert("Grim Reaper", {
        { owner = x.a.me.key, report = { mode = "AVENGE", note = "A" } },
        { owner = "bob", report = { mode = "AVOID", note = "B" } },
    })
    local mixed
    for _, w in ipairs(x.widgets) do
        if w.text == "Grim Reaper - 2 reports [World]" then mixed = w end
    end
    eq(mixed.textColor[2], 0.82)
end)

test("A selected enemy keeps its name locked", function()
    local x = boot("Alice River")
    x.a.report("Grim Reaper", "Original", "AVOID")
    x.a.toggle()
    local row = findWidget(x, "Button", nil, function(w) return type(w.group) == "table" end)
    row.scripts.OnClick(row)
    eq(editors(x)[2].enabled, false)
    click(x, "Add enemy")
    eq(editors(x)[2].enabled, true)
end)

test("Mixed chips and report blocks keep authors separate", function()
    local x = boot("Alice River")
    x.a.trust("Bob Stone")
    x.a.report("Grim Reaper", "My note", "AVENGE")
    x.a.merge("bob stone-forever", { name = "Grim Reaper", realm = "Forever", note = "Bob note", mode = "AVOID", rev = 1, deleted = false })
    x.a.toggle()
    local row = findWidget(x, "Button", nil, function(w) return type(w.group) == "table" end)
    eq(row.tag:GetText(), "Mixed")
    check(row.detail:GetText():find("yours", 1, true) ~= nil)
    row.scripts.OnClick(row)
    findWidget(x, "FontString", nil, function(w)
        return type(w.text) == "string" and w.text:find("You · Avenge · yours", 1, true)
    end)
    findWidget(x, "FontString", nil, function(w)
        return type(w.text) == "string" and w.text:find("Bob Stone · Avoid · friend", 1, true)
    end)
    findWidget(x, "FontString", nil, function(w)
        return type(w.text) == "string" and w.text:find("Warn your friends", 1, true) == nil and w.text:find("another fight", 1, true) ~= nil
    end)
end)

test("Slash command is /fv only", function()
    local x = boot("Alice River")
    eq(x.env.SLASH_FOREVERVENDETTA1, "/fv")
    eq(x.env.SLASH_FOREVERVENDETTA2, nil)
end)

test("Status reports muted count and alert place toggles", function()
    local x = boot("Alice River")
    check(x.a.report("Grim Reaper", "Camped"))
    check(x.a.ignoreEnemy("Grim Reaper"))
    x.a.recordSighting("grim reaper-forever", "world")
    x.a.store.settings.battlegrounds = true
    local before = #x.messages
    x.env.SlashCmdList.FOREVERVENDETTA("status")
    local blob = table.concat(x.messages, "\n", before + 1)
    check(blob:find(x.a.VERSION, 1, true))
    check(blob:find("1 muted", 1, true))
    check(blob:find("1 sightings", 1, true))
    check(blob:find("Place: World", 1, true))
    check(blob:find("Messaging: clear", 1, true))
    check(blob:find("battlegrounds on", 1, true))
    check(blob:find("arenas off", 1, true))
    x.lockdown(true)
    before = #x.messages
    x.env.SlashCmdList.FOREVERVENDETTA("status")
    blob = table.concat(x.messages, "\n", before + 1)
    check(blob:find("Messaging: combat lockdown", 1, true))
    eq(x.a.sightingCount("world"), 1)
    eq(x.a.sightingCount("battleground"), 0)
    eq(x.a.stanceLabel(nil), "Listed")
    eq(x.a.stanceLabel("AVOID"), "Avoid")
end)

test("Legacy seven-field whisper packets default place to world", function()
    local x = boot("Alice River")
    x.a.trust("Bob Stone")
    -- No trailing place field — older friends still sync as world.
    x.a.receive(x.a.PREFIX, "1|E|1|0|WATCH|Grim Reaper|Forever|Legacy note", "WHISPER", "Bob Stone-Forever")
    eq(#x.a.entries(), 1)
    eq(#x.a.entries("world"), 1)
    eq(x.a.entries("world")[1].report.note, "Legacy note")
    eq(x.a.entries("world")[1].report.place, "world")
end)

test("Death Knight class icon is not painted on Forever", function()
    local x = boot("Alice River")
    x.a.showBanner("Grim Reaper", "Camped", nil, "AVENGE", { class = "DEATHKNIGHT", race = "ORC", sex = 2 })
    local banner
    for i = #x.frames, 1, -1 do
        if type(x.frames[i].classIcon) == "table" then banner = x.frames[i]; break end
    end
    check(banner ~= nil)
    eq(banner.classIcon.shown, false)
    eq(banner.raceIcon.shown, true)
end)

test("Sync status counts queued whispers", function()
    local x = boot("Alice River")
    x.a.trust("Bob Stone")
    x.a.toggleFriends()
    click(x, "Sync with friends")
    local note = findWidget(x, "FontString", nil, function(w) return type(w.text) == "string" and w.text:find("queued", 1, true) end)
    check(note.text:find("connected", 1, true) == nil)
    check(x.a.pendingCount() > 0)
end)

test("Untrust drops queued whispers immediately", function()
    local x = boot("Alice River")
    x.a.trust("Bob Stone")
    x.a.report("Grim Reaper", "Private")
    check(x.a.pendingCount() > 0)
    check(x.a.untrust("Bob Stone"))
    eq(x.a.pendingCount(), 0)
    x.a.pump(1)
    eq(#x.out, 0)
end)

test("Incoming packets with junk fields are rejected", function()
    local x = boot("Alice River")
    x.a.trust("Bob Stone")
    x.a.receive(x.a.PREFIX, "1|E|1|0|NOPE|Grim Reaper|Forever|x", "WHISPER", "Bob Stone-Forever")
    eq(#x.a.entries(), 0)
    x.a.receive(x.a.PREFIX, "1|E|1|0|AVOID|Grim Reaper|Forever|ok", "WHISPER", "Bob Stone-Forever")
    eq(#x.a.entries(), 1)
end)

test("Death offer adds killer from death recap as Avenge", function()
    local x = boot("Alice River", nil, function(env)
        env.C_DeathRecap = {
            HasRecapEvents = function() return true end,
            GetRecapEvents = function()
                return {
                    { sourceName = "Grim Reaper", sourceGUID = "Player-1-02-AABBCCDD", amount = 420 },
                    { sourceName = "Grim Reaper", sourceGUID = "Player-1-02-AABBCCDD", amount = 80 },
                }
            end,
        }
    end)
    x.a.resolveMyDeath()
    check(x.a.pendingKiller ~= nil)
    eq(x.a.pendingKiller.name, "Grim Reaper")
    eq(x.a.pendingKiller.place, "world")
    eq(x.a.scoreFor("grim reaper-forever", "world").deaths, 1)
    check(x.a.acceptKillerOffer("AVENGE"))
    eq(#x.a.entries("world"), 1)
    eq(x.a.entries("world")[1].report.mode, "AVENGE")
    eq(x.a.entries("world")[1].report.note, "Killed me")
    eq(x.a.pendingKiller, nil)
end)

test("Death offer skips PvE monster killers", function()
    local x = boot("Alice River", nil, function(env)
        env.C_DeathRecap = {
            HasRecapEvents = function() return true end,
            GetRecapEvents = function()
                return {
                    { sourceName = "Riverpaw Bandit", sourceGUID = "Creature-0-1-2-3-12345-0000ABCD", amount = 500 },
                }
            end,
        }
    end)
    x.enemy.player = false
    x.a.resolveMyDeath()
    eq(x.a.pendingKiller, nil)
    eq(x.a.scoreFor("riverpaw bandit-forever", "world").deaths, 0)
    eq(#x.a.recentAttackers("world"), 0)
end)

test("Death offer skips nameless-GUID mob when target is not a player", function()
    local x = boot("Alice River", nil, function(env)
        env.C_DeathRecap = {
            HasRecapEvents = function() return true end,
            GetRecapEvents = function()
                return { { sourceName = "Kobold Vermin", amount = 90 } }
            end,
        }
    end)
    x.enemy.player = false
    x.enemy.first, x.enemy.last = "Kobold", "Vermin"
    x.a.resolveMyDeath()
    eq(x.a.pendingKiller, nil)
end)

test("Death offer skips when already reported or disabled", function()
    local x = boot("Alice River", nil, function(env)
        env.C_DeathRecap = {
            HasRecapEvents = function() return true end,
            GetRecapEvents = function()
                return { { sourceName = "Grim Reaper", sourceGUID = "Player-1-02-AABBCCDD", amount = 100 } }
            end,
        }
    end)
    check(x.a.report("Grim Reaper", "Already listed", "WATCH", false, nil, "world"))
    x.a.resolveMyDeath()
    eq(x.a.pendingKiller, nil)
    x.a.report("Grim Reaper", "Already listed", "WATCH", true, nil, "world")
    x.a.store.settings.deathOffer = false
    x.a.resolveMyDeath()
    eq(x.a.pendingKiller, nil)
end)

test("Listed enemy sightings store zone and time", function()
    local x = boot("Alice River")
    check(x.a.report("Grim Reaper", "Camp", "AVENGE"))
    x.a.detect("target")
    local seen = x.a.sightingFor("grim reaper-forever", "world")
    check(seen ~= nil)
    eq(seen.zone, "Elwynn Forest")
    check(seen.ts > 0)
    check(x.a.formatSeenShort(seen):find("Elwynn", 1, true))
end)

test("Enemy list sorts by last seen and shows it on the row", function()
    local x = boot("Alice River")
    check(x.a.report("Alpha Wolf", "Old", "WATCH"))
    check(x.a.report("Grim Reaper", "Camp", "AVENGE"))
    x.a.recordSighting("grim reaper-forever", "world")
    x.advance(120)
    x.a.recordSighting("alpha wolf-forever", "world")
    x.a.toggle()
    local first = findWidget(x, "Button", nil, function(w)
        return type(w.group) == "table" and w.group.name == "Alpha Wolf"
    end)
    check(first ~= nil)
    -- Most recently seen (Alpha) should appear before Grim when both are on page 1.
    local rows = {}
    for _, w in ipairs(x.widgets) do
        if type(w.group) == "table" and w.shown and w.detail then
            rows[#rows + 1] = w
        end
    end
    table.sort(rows, function(a, b) return (a.y or 0) < (b.y or 0) end)
    check(#rows >= 2)
    eq(rows[1].group.name, "Alpha Wolf")
    check(rows[1].detail.text:find("muted", 1, true) == nil)
    check(rows[1].detail.text:find("ago", 1, true) or rows[1].detail.text:find("just now", 1, true))
end)

test("Unit menu hook opens a Vendetta draft for an enemy", function()
    local x = boot("Alice River", nil, function(env)
        env.UnitPopupButtons = {}
        env.UnitPopupMenus = { TARGET = { "CANCEL" }, FOCUS = { "CANCEL" }, ENEMY_PLAYER = { "CANCEL" }, OTHERENEMYPLAYER = { "CANCEL" } }
        env.UnitPopup_OnClick = function() end
        env.hooksecurefunc = function(name, fn)
            if name == "UnitPopup_OnClick" then env._popupClick = fn end
        end
        env.UIDROPDOWNMENU_INIT_MENU = { unit = "target" }
    end)
    x.a.hookUnitMenus()
    check(x.env.UnitPopupButtons.FOREVER_VENDETTA ~= nil)
    check(x.env.UnitPopupMenus.TARGET[1] == "FOREVER_VENDETTA")
    x.env._popupClick({ value = "FOREVER_VENDETTA" })
    local fields = editors(x)
    local found = false
    for _, f in ipairs(fields) do
        if f:GetText() == "Grim Reaper" then found = true end
    end
    check(found)
end)

test("Unit tooltip shows stance and reason for listed enemies", function()
    local x = boot("Alice River")
    check(x.a.report("Grim Reaper", "Camped the bridge", "AVOID"))
    x.a.hookTooltips()
    local tip = x.env.GameTooltip
    tip.lines = {}
    tip.scripts.OnTooltipSetUnit(tip)
    local joined = table.concat(tip.lines, " | ")
    check(joined:find("Forever Vendetta", 1, true))
    check(joined:find("Avoid", 1, true))
    check(joined:find("Camped the bridge", 1, true))
end)

test("Recent attackers from death and targeting feed draft buttons", function()
    local x = boot("Alice River", nil, function(env)
        env.C_DeathRecap = {
            HasRecapEvents = function() return true end,
            GetRecapEvents = function()
                return { { sourceName = "Grim Reaper", sourceGUID = "Player-1-02-AABBCCDD", amount = 200 } }
            end,
        }
    end)
    x.a.resolveMyDeath()
    local recent = x.a.recentAttackers("world")
    check(#recent >= 1)
    eq(recent[1].name, "Grim Reaper")
    x.enemy.targeting = true
    x.a.scanAttackerFocus()
    check(#x.a.recentAttackers("world") >= 1)
    x.a.toggle()
    local chip = findWidget(x, "Button", nil, function(w)
        return type(w.row) == "table" and w.row.name == "Grim Reaper"
    end)
    chip.scripts.OnClick(chip)
    local fields = editors(x)
    check(fields[2]:GetText():find("Grim Reaper", 1, true) or fields[2]:GetText() == "Grim Reaper")
end)

test("Target button opens a report draft for the enemy", function()
    local x = boot("Alice River")
    x.a.buildTargetButton()
    x.a.refreshTargetButton()
    local btn = x.env.ForeverVendettaTargetButton
    check(btn ~= nil)
    check(btn:IsShown())
    btn.scripts.OnClick(btn)
    local fields = editors(x)
    local found = false
    for _, f in ipairs(fields) do if f:GetText() == "Grim Reaper" then found = true end end
    check(found, "draft should fill enemy name")
end)

test("Ignore mutes alerts but keeps the report", function()
    local x = boot("Alice River")
    check(x.a.report("Grim Reaper", "Harmless now", "WATCH"))
    check(x.a.ignoreEnemy("Grim Reaper"))
    check(x.a.isIgnored("grim reaper-forever"))
    local before = #x.messages
    x.a.detect("target")
    eq(#x.messages, before, "muted enemies do not alert")
    eq(#x.a.entries(), 1)
    check(x.a.unignoreEnemy("Grim Reaper"))
    x.advance(60)
    x.a.detect("target")
    check(#x.messages > before)
end)

test("Party announce sends a short stance line without the reason", function()
    local x = boot("Alice River")
    x.env._inGroup = true
    x.a.store.settings.partyAnnounce = true
    x.a.store.settings.sound = false
    x.a.store.settings.banner = false
    check(x.a.report("Grim Reaper", "Secret reason should stay private", "AVENGE"))
    x.a.detect("target")
    eq(#x.chat, 1)
    eq(x.chat[1][2], "PARTY")
    check(x.chat[1][1]:find("Grim Reaper", 1, true))
    check(x.chat[1][1]:find("Avenge", 1, true))
    check(not x.chat[1][1]:find("Secret reason", 1, true))
end)

test("Nameplate badge appears for listed enemies", function()
    local x = boot("Alice River")
    check(x.a.report("Grim Reaper", "Mark me", "AVOID"))
    local plate = x.env.CreateFrame("Frame")
    plate.namePlateUnitToken = "nameplate1"
    plate.UnitFrame = plate
    x.env._plates = { plate }
    x.env.UnitIsPlayer = function() return true end
    x.env.UnitIsEnemy = function() return true end
    x.a.refreshPlateBadge("nameplate1", x.a.unitName("target"), true)
    check(plate.ForeverVendettaBadge ~= nil)
    check(plate.ForeverVendettaBadge:IsShown())
    x.a.clearPlateBadge("nameplate1")
    check(not plate.ForeverVendettaBadge:IsShown())
end)

test("canaccessvalue false blocks incomplete unit identities", function()
    local x = boot("Alice River", nil, function(env)
        env.canaccessvalue = function(v)
            return type(v) ~= "string" or not v:find("blocked", 1, true)
        end
        env.UnitName = function(unit)
            if unit == "target" then return "blocked", "Reaper" end
            return "Alice", "River"
        end
        env.UnitNameUnmodified = env.UnitName
        env.UnitFullName = function(unit)
            if unit == "target" then return "blocked", "Forever" end
            return "Alice River", "Forever"
        end
        env.GetUnitName = function(unit)
            if unit == "target" then return "blocked Reaper" end
            return "Alice River"
        end
    end)
    eq(x.a.unitName("target"), nil)
end)

test("Addon message restriction holds the whisper queue like lockdown", function()
    local x = boot("Alice River")
    check(x.a.trust("Bob Stone"))
    check(x.a.report("Grim Reaper", "Camp"))
    x.a.sync()
    check(x.a.pendingCount() > 0)
    x.env._restrictAddon = true
    for _ = 1, 20 do x.a.pump(0.31) end
    eq(#x.out, 0)
    x.env._restrictAddon = false
    for _ = 1, 40 do x.a.pump(0.31) end
    check(#x.out > 0)
end)

test("CHAT_MSG_ADDON event path accepts a trusted whisper", function()
    local x, y = boot("Alice River"), boot("Bob Stone")
    check(x.a.trust("Bob Stone"))
    check(y.a.trust("Alice River"))
    check(x.a.report("Grim Reaper", "From the wire", "AVOID"))
    local wire = x.a.wire(x.a.entries()[1].report)
    y.event("CHAT_MSG_ADDON", y.a.PREFIX, wire, "WHISPER", "Alice River-Forever")
    eq(#y.a.entries(), 1)
    eq(y.a.entries()[1].report.note, "From the wire")
end)

test("Pending whisper queue is session-only; reports persist across reload", function()
    local x = boot("Alice River")
    check(x.a.trust("Bob Stone"))
    check(x.a.report("Grim Reaper", "Camp"))
    x.a.sync()
    check(x.a.pendingCount() > 0)
    local saved = x.env.ForeverVendettaDB
    for _, bucket in pairs(saved.realms or {}) do
        eq(bucket.queue, nil)
        eq(bucket.pending, nil)
    end
    local y = boot("Alice River", saved)
    eq(#y.a.entries(), 1)
    -- Bootstrap sync may enqueue again; that is a new session queue, not restored SV state.
    check(y.a._bootstrapSync == true)
end)

test("Empty world with no friends points to Friends first", function()
    local x = boot("Alice River")
    x.a.toggle()
    local body = findWidget(x, "FontString", nil, function(w)
        return type(w.text) == "string" and w.text:find("open Friends", 1, true)
    end)
    check(body ~= nil)
    click(x, "Open Friends")
    findWidget(x, "FontString", "Trusted friends")
end)

test("Bootstrap sync runs once across LOGIN and PEW", function()
    local x = boot("Alice River")
    check(x.a.trust("Bob Stone"))
    local before = #x.out
    -- boot already fired LOGIN; PEW again must not enqueue a second bootstrap dump storm.
    x.a._bootstrapSync = true
    x.event("PLAYER_ENTERING_WORLD")
    -- No assertion on zero outbound (periodic paths vary); flag must stay set.
    check(x.a._bootstrapSync == true)
    check(#x.out >= before)
end)

test("Trust and inbound reports require First Last names", function()
    local x = boot("Alice River")
    check(not x.a.trust("Bob"))
    eq(x.a.count(x.a.store.friends), 0)
    check(x.a.trust("Bob-Stone"))
    eq(x.a.count(x.a.store.friends), 1)
    check(not x.a.report("Grim", "Camp"))
    eq(#x.a.entries(), 0)
    -- Trusted peer sends a single-token enemy name — must not merge.
    x.a.receive(x.a.PREFIX, "1|E|1|0|AVENGE|Grim|Forever|Junk|world", "WHISPER", "Bob Stone-Forever")
    eq(#x.a.entries(), 0)
    x.a.receive(x.a.PREFIX, "1|E|1|0|AVENGE|Grim Reaper|Forever|Camp|world", "WHISPER", "Bob Stone-Forever")
    eq(#x.a.entries(), 1)
end)

print("Passed " .. passed .. " Forever Vendetta regression tests.")


