-- util/class.lua
local function buildClass(name, parent, body)
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

_G.class = function(name, ...)
    local args = {...}
    local parent = nil
    local body = nil

    if #args == 1 and type(args[1]) == "table" then
        body = args[1]
    elseif #args == 3 and args[1] == "extends" then
        dbg.info("extends!!!")
        local parentName = args[2]
        parent = _G[parentName]
        if not parent then
            if _G.dbg then _G.dbg("Parent class not found: " .. tostring(parentName)) end
            return
        end
        body = args[3]
    elseif #args == 0 and type(name) == "string" then
        return function(next)
            if type(next) == "string" and next == "extends" then
                return function(parentName)
                    local parentClass = _G[parentName]
                    if not parentClass then
                        if _G.dbg then _G.dbg("Parent class not found: " .. tostring(parentName)) end
                        return
                    end
                    return function(classBody)
                        return buildClass(name, parentClass, classBody)
                    end
                end
            elseif type(next) == "table" then
                return buildClass(name, nil, next)
            else
                if _G.dbg then _G.dbg("Invalid class definition for " .. tostring(name)) end
            end
        end
    else
        if _G.dbg then _G.dbg("Invalid class definition for " .. tostring(name)) end
        return
    end

    return buildClass(name, parent, body)
end