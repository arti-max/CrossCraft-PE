-- util/RemovePrefix.lua

if love.filesystem.__removePrefixHooked then
    dbg.info("RemovePrefix already hooked, skipping")
    return
end
love.filesystem.__removePrefixHooked = true

local sim = {}
do
    local fnames = {"read","write","exists","remove","newFile","newFileData","getInfo","load","getDirectoryItems","createDirectory"}
    for _, fn in ipairs(fnames) do
        sim[fn] = love.filesystem[fn]
    end
end

local orig = {}
local function extractOriginal(wrapped)
    local i = 1
    while true do
        local name, value = debug.getupvalue(wrapped, i)
        if not name then break end
        if type(value) == "function" and value ~= wrapped then return value end
        i = i + 1
    end
end
for _, fname in ipairs({"read","write","exists","remove","newFile","newFileData","getInfo","load"}) do
    local wrapped = sim[fname]
    if wrapped then
        local real = extractOriginal(wrapped)
        if real and real ~= wrapped then orig[fname] = real end
    end
end
local hasOriginals = orig.read ~= nil

local ioRoots = {}
if _G.OLD_SAVE_ROOT then
    ioRoots[1] = _G.OLD_SAVE_ROOT
else
    local fullSave = love.filesystem.getSaveDirectory()
    if fullSave then
        local base = fullSave:match("^(.*)/runner/project_%d+/?$") or fullSave
        ioRoots[1] = base                   -- .../zip
        local parent = base:match("^(.*)/[^/]+$")
        if parent then
            ioRoots[2] = parent             -- .../save
            local grandParent = parent:match("^(.*)/[^/]+$")
            if grandParent then
                ioRoots[3] = grandParent    -- .../files
            end
        end
    end
end

local workingIoRoots = {}
for _, root in ipairs(ioRoots) do
    local test = io.open(root .. "/__iotest__", "w")
    if test then
        test:close()
        os.remove(root .. "/__iotest__")
        workingIoRoots[#workingIoRoots+1] = root
        dbg.info("RemovePrefix: io works in " .. root)
    else
        dbg.info("RemovePrefix: io failed in " .. root)
    end
end

local escapePrefixes = {"../", "../../", "../../../", "../../../../"}

local function trySimRead(path)
    for _, prefix in ipairs(escapePrefixes) do
        local full = prefix .. path
        local data = sim.read(full)
        if data then
            dbg.info("Read via sim + '" .. prefix .. "': " .. path)
            return data
        end
    end
    return nil
end

local function trySimExists(path)
    for _, prefix in ipairs(escapePrefixes) do
        local full = prefix .. path
        if sim.exists(full) then
            dbg.info("Exists via sim + '" .. prefix .. "': " .. path)
            return true
        end
    end
    return false
end

local function tryIoRead(path)
    for _, root in ipairs(workingIoRoots) do
        local full = root .. "/" .. path
        local f = io.open(full, "rb")
        if f then
            local content = f:read("*all")
            f:close()
            dbg.info("ioRead: " .. full)
            return content
        end
    end
    return nil
end

local function tryIoExists(path)
    for _, root in ipairs(workingIoRoots) do
        local full = root .. "/" .. path
        local f = io.open(full, "rb")
        if f then
            f:close()
            dbg.info("ioExists: " .. full)
            return true
        end
    end
    return false
end

love.filesystem.read = function(name, ...)
    if hasOriginals then return orig.read(name, ...) end
    local data = sim.read(name, ...)
    if data then return data end
    data = trySimRead(name)
    if data then return data end
    data = tryIoRead(name)
    if data then return data end
    return nil
end

love.filesystem.exists = function(name)
    if hasOriginals then return orig.exists(name) end
    if sim.exists(name) then return true end
    if trySimExists(name) then return true end
    if tryIoExists(name) then return true end
    return false
end

love.filesystem.write = function(name, data, ...)
    if hasOriginals then return orig.write(name, data, ...) end
    return sim.write(name, data, ...)
end

love.filesystem.remove = function(name)
    if hasOriginals then orig.remove(name) else sim.remove(name) end
    for _, root in ipairs(workingIoRoots) do os.remove(root .. "/" .. name) end
end

love.filesystem.newFile = function(...)
    return hasOriginals and orig.newFile(...) or sim.newFile(...)
end
love.filesystem.newFileData = function(...)
    return hasOriginals and orig.newFileData(...) or sim.newFileData(...)
end

love.filesystem.getInfo = function(name, ...)
    if hasOriginals then return orig.getInfo(name, ...) end
    local info = sim.getInfo(name, ...)
    if info then return info end
    for _, prefix in ipairs(escapePrefixes) do
        info = sim.getInfo(prefix .. name, ...)
        if info then
            dbg.info("getInfo via prefix '" .. prefix .. "'")
            return info
        end
    end
    for _, root in ipairs(workingIoRoots) do
        local full = root .. "/" .. name
        local f = io.open(full, "rb")
        if f then
            local size = f:seek("end")
            f:close()
            return { type = "file", size = size }
        end
    end
    return nil
end

love.filesystem.load = function(...)
    return hasOriginals and orig.load(...) or sim.load(...)
end

if sim.getDirectoryItems then
    love.filesystem.getDirectoryItems = function(name)
        if hasOriginals then return orig.getDirectoryItems(name) end
        return sim.getDirectoryItems(name)
    end
end
if sim.createDirectory then
    love.filesystem.createDirectory = function(name)
        if hasOriginals then return orig.createDirectory(name) end
        return sim.createDirectory(name)
    end
end

_G.restoreLoveFilesystem = function()
    love.filesystem.__removePrefixHooked = nil
    for fname, func in pairs(sim) do love.filesystem[fname] = func end
end

dbg.info("RemovePrefix ready: originals=" .. tostring(hasOriginals) .. ", sim escape prefixes=" .. #escapePrefixes .. ", io roots=" .. #workingIoRoots)