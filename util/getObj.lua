_G.getUP = function()
    for level = 2, 10 do
        local info = debug.getinfo(level, "f")
        if not info then break end
        local func = info.func
        local i = 1
        while true do
            local name, value = debug.getupvalue(func, i)
            if not name then break end
            if name == "up" then return value end
            i = i + 1
        end
    end
    return nil
end