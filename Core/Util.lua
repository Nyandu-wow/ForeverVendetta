local _, A = ...
A.PREFIX = "FVendetta1"
A.MAX_REPORTS, A.MAX_FRIENDS = 200, 20
A.modes = { AVENGE = true, AVOID = true, WATCH = true }

-- Secret values throw on boolean tests, comparison, concatenation, and arithmetic.
-- issecretvalue itself is safe. type() is not consulted until the value is readable.
function A.plain(v, kind)
    if issecretvalue and issecretvalue(v) then return false end
    if canaccessvalue and not canaccessvalue(v) then return false end
    return type(v) == kind
end

function A.call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if ok then return a, b end
end

local function utf8ok(s)
    local i, n = 1, #s
    while i <= n do
        local c = s:byte(i)
        local len = 1
        if c >= 0xC2 and c <= 0xDF then len = 2
        elseif c >= 0xE0 and c <= 0xEF then len = 3
        elseif c >= 0xF0 and c <= 0xF4 then len = 4
        elseif c >= 0x80 then return false end
        if i + len - 1 > n then return false end
        for j = 1, len - 1 do
            local cc = s:byte(i + j)
            if not cc or cc < 0x80 or cc > 0xBF then return false end
        end
        i = i + len
    end
    return true
end

-- Bound bytes on the wire; reject oversized or split UTF-8 rather than cutting a character.
function A.text(v, max)
    if not A.plain(v, "string") then return nil end
    v = v:gsub("[%c|]", " "):gsub("%s+", " "):match("^%s*(.-)%s*$")
    if #v > max or not utf8ok(v) then return nil end
    return v
end

function A.clock()
    local t = A.call(GetTime)
    if A.plain(t, "number") then return t end
end

function A.count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

function A.print(msg)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffff7055Vendetta|r: " .. msg) end
end

function A.flag(fn, ...)
    local value = A.call(fn, ...)
    return A.plain(value, "boolean") and value == true
end
