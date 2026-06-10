-- util/class.lua
_G.class = function(name, ...)
    local args = {...}
    local parent = nil
    local body = nil

    if #args == 1 and type(args[1]) == "table" then
        body = args[1]
    elseif #args == 3 and args[1] == "extends" then
        local parentName = args[2]
        parent = _G[parentName]
        if not parent then
            if _G.dbg then _G.dbg("Parent class not found: " .. tostring(parentName)) end
            return
        end
        body = args[3]
    else
        if type(name) == "string" and #args == 0 then
            return function(classBody)
                return class(name, classBody)
            end
        end
        if _G.dbg then _G.dbg("Invalid class definition for " .. tostring(name)) end
        return
    end

    if type(body) ~= "table" then
        if _G.dbg then _G.dbg("Invalid class body for " .. tostring(name)) end
        return
    end

    local klass = {}
    klass.__index = klass
    klass._name = name

    if parent then
        setmetatable(klass, { __index = parent })
        klass._super = parent
    end

    _G[name] = klass

    if body.constructor then
        klass.constructor = body.constructor
    end
    function klass.new(...)
        local instance = setmetatable({}, klass)
        instance._super = klass._super
        if klass.constructor then
            klass.constructor(instance, ...)
        end
        return instance
    end

    local staticInit = nil
    for k, v in pairs(body) do
        if k ~= "constructor" and k ~= "__staticinit" then
            klass[k] = v
        elseif k == "__staticinit" then
            staticInit = v
        end
    end

    if staticInit then
        staticInit(klass)
    end

    return klass
end