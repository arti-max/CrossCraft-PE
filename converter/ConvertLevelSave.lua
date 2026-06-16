-- converter/ConvertLevelSave.lua

local function packU16BE(num)
    local high = math.floor(num / 256)
    local low = num % 256
    return string.char(high, low)
end

local function packU8BE(num)
    local n = math.floor(num % 256)
    return string.char(n)
end


local function unpackU8BE(data, pos)
    local n = string.byte(data, pos)
    return n, pos + 1
end

local function unpackU16BE(data, pos)
    local high = string.byte(data, pos)
    local low = string.byte(data, pos + 1)
    return high * 256 + low, pos + 2
end

local function packString(str)
    local len = #str
    return packU16BE(len) .. str
end

local function unpackString(data, pos)
    local len, newPos = unpackU16BE(data, pos)
    local str = string.sub(data, newPos, newPos + len - 1)
    return str, newPos + len
end

function _G.convertOldLevelData(data)
    if #data < 6 then
        return -1, "Level data too short for old format";
    end

    local pos = 1
    local width, depth, height
    width, pos  = unpackU16BE(data, pos)
    depth, pos  = unpackU16BE(data, pos)
    height, pos = unpackU16BE(data, pos)

    local blocks = string.sub(data, pos)

    local expectedBlockCount = width * depth * height
    if #blocks ~= expectedBlockCount then
        if #blocks > expectedBlockCount then
            blocks = string.sub(blocks, 1, expectedBlockCount)
        else
            blocks = blocks .. string.rep("\0", expectedBlockCount - #blocks)
        end
    end

    local versionByte = packU8BE(2);
    local header = packString("ccpe") .. packU16BE(width) .. packU16BE(depth) .. packU16BE(height) .. versionByte;

    return 1, header .. blocks
end