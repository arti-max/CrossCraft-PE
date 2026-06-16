-- util/Font.lua

_G.BitmapFont = {}
BitmapFont.__index = BitmapFont

function BitmapFont:new(imagePath)
    local img = love.graphics.newImage(imagePath)
    img:setFilter("nearest", "nearest")
    local imgData = love.image.newImageData(imagePath)
    
    local charWidths = {}
    for i = 0, 255 do
        local col = i % 16
        local row = math.floor(i / 16)
        local charWidth = 7
        local found = false
        while charWidth >= 0 and not found do
            local x = col * 8 + charWidth
            for y = 0, 7 do
                local py = row * 8 + y
                local _, _, _, a = imgData:getPixel(x, py)
                if a > 128/255 then
                    found = true
                    break
                end
            end
            if not found then
                charWidth = charWidth - 1
            end
        end
        if i == 32 then
            charWidth = 3   -- пробел
        else
            charWidth = charWidth + 1
        end
        charWidths[i] = charWidth
    end
    
    local self = setmetatable({
        image = img,
        imageData = imgData,
        charWidths = charWidths,
        CHAR_SPACING = 1
    }, BitmapFont)
    return self
end

function BitmapFont:getHeight()
    return 8
end

function BitmapFont:draw(text, x, y, color)
    local r, g, b = love.math.colorFromBytes(
        bit.band(bit.rshift(color, 16), 0xFF),
        bit.band(bit.rshift(color, 8), 0xFF),
        bit.band(color, 0xFF)
    )
    love.graphics.setColor(r, g, b)
    
    local currentX = x
    local i = 1
    while i <= #text do
        local charCode = string.byte(text, i)
        
        if text:sub(i, i) == "&" and i + 1 <= #text then
            local colorChar = text:sub(i+1, i+1):lower()
            local colorChars = "0123456789abcdef"
            local idx = colorChars:find(colorChar, 1, true)
            if idx then
                idx = idx - 1
                local iy = (bit.band(idx, 8) * 8)
                local b_c = (bit.band(idx, 1) * 191) + iy
                local g_c = (bit.band(bit.rshift(idx, 1), 1) * 191) + iy
                local r_c = (bit.band(bit.rshift(idx, 2), 1) * 191) + iy
                r, g, b = love.math.colorFromBytes(r_c, g_c, b_c)
                love.graphics.setColor(r, g, b)
                i = i + 2
            else
                i = i + 1
            end
        else
            charCode = charCode or 0
            local ix = (charCode % 16) * 8
            local iy = math.floor(charCode / 16) * 8
            
            local u0 = ix / 128
            local v0 = iy / 128
            local u1 = (ix + 7.99) / 128
            local v1 = (iy + 7.99) / 128
            
            local quad = love.graphics.newQuad(ix, iy, 8, 8, 128, 128)
            love.graphics.draw(self.image, quad, currentX, y)
            
            currentX = currentX + self.charWidths[charCode] + self.CHAR_SPACING
            i = i + 1
        end
    end
end

function BitmapFont:drawShadow(text, x, y, color)
    local darkColor = bit.band(color, 0xFCFCFC) / 4
    self:draw(text, x + 1, y + 1, darkColor)
    self:draw(text, x, y, color)
end

function BitmapFont:drawCentered(text, x, y, color)
    local textWidth = self:width(text)
    self:drawShadow(text, x - textWidth / 2, y, color)
end

function BitmapFont:width(text)
    local len = 0
    local i = 1
    while i <= #text do
        if text:sub(i, i) == "&" and i + 1 <= #text then
            i = i + 2
        else
            local charCode = string.byte(text, i) or 0
            len = len + self.charWidths[charCode]
            if i < #text then
                len = len + self.CHAR_SPACING
            end
            i = i + 1
        end
    end
    return len
end