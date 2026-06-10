local up = nil
local level = 2
while true do
    local info = debug.getinfo(level, "f")
    if not info then break end
    local func = info.func
    local i = 1
    while true do
        local name, value = debug.getupvalue(func, i)
        if not name then break end
        if name == "up" then
            up = value
            break
        end
        i = i + 1
    end
    if up then break end
    level = level + 1
end
if up then
    _G.UP = up
    return "UP saved"
else
    return "UP not found"
end