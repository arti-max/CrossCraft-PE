-- menu/MainMenu.lua

_G.mouseState = { current = false, previous = false }

function _G.updateMouse()
    _G.mouseState.previous = _G.mouseState.current
    _G.mouseState.current = love.mouse.isDown(1)
end

function _G.isMouseDown()
    return _G.mouseState.current
end

function _G.isMouseJustPressed()
    return _G.mouseState.current and not _G.mouseState.previous
end

function _G.isMouseJustReleased()
    return not _G.mouseState.current and _G.mouseState.previous
end

local isMobile = (love.system.getOS() == "Android" or love.system.getOS() == "iOS")

local initW, initH = love.graphics.getDimensions()
if isMobile then
    love.window.setMode(initW, initH, {fullscreen = true, fullscreentype = "desktop", depth = 24})
else
    love.window.setMode(initW, initH, {depth = 24, resizable = true})
end

local fileSavesRoot = nil
if UP and UP.fileSaves and UP.fileSaves.resolve then
    fileSavesRoot = UP.fileSaves.resolve("")
end

if fileSavesRoot then
    local info = love.filesystem.getInfo(fileSavesRoot)
    if not info then
        love.filesystem.createDirectory(fileSavesRoot)
        dbg.info("Created fileSaves dir: " .. fileSavesRoot)
    end
else
    love.filesystem.createDirectory("fileSaves")
    dbg.info("Created sandbox fileSaves dir")
end

local font = BitmapFont:new(UP.fileSaves.resolve("font.png"))

local logoPath = UP.fileSaves.resolve('logo.png')
local logoImg = nil
if logoPath then
    logoImg = love.graphics.newImage(logoPath)
    logoImg:setFilter("nearest", "nearest")
end

local BASE_BTN_W = 900
local BASE_BTN_H = 150
local BASE_BTN_GAP = 200
local BASE_BTN_START_Y = 480
local BASE_BTN_START_Y2 = 330
local BASE_LOGO_SCALE = 2
local BASE_FONT_SCALE = 4
local BASE_SMALL_TEXT_SCALE = 2
local BASE_ALERT_W = 600
local BASE_ALERT_H = 300
local BASE_ALERT_BTN_W = 200
local BASE_ALERT_BTN_H = 50
local BASE_ALERT_BTN_MARGIN = 30

local function getMobileScale()
    return love.graphics.getHeight() / 540
end

local function getButtonWidth()
    if isMobile then
        return math.min(800, love.graphics.getWidth() * 0.85)
    else
        return BASE_BTN_W
    end
end

local function getButtonHeight()
    if isMobile then
        return math.min(120, love.graphics.getHeight() * 0.12)
    else
        return BASE_BTN_H
    end
end

local function getButtonStep()
    if isMobile then
        local btnH = getButtonHeight()
        local gap = love.graphics.getHeight() * 0.05
        return btnH + gap
    else
        return BASE_BTN_GAP
    end
end

local function getButtonStartY(scene)
    if isMobile then
        local h = love.graphics.getHeight()
        local btnH = getButtonHeight()
        local step = getButtonStep()
        local gap = step - btnH
        local totalH = 3 * btnH + 2 * gap
        local baseCentered = (h - totalH) / 2
        local scale = getMobileScale()
        if scene == 1 then
            return baseCentered + 60 * scale
        else
            return baseCentered - 150 * scale
        end
    else
        if scene == 2 then
            return BASE_BTN_START_Y2 - BASE_BTN_GAP
        else
            return BASE_BTN_START_Y - BASE_BTN_GAP
        end
    end
end

local function drawButton(x, y, w, h, text)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.setColor(1, 1, 1)

    love.graphics.push()
    local scale = BASE_FONT_SCALE
    if isMobile then
        scale = BASE_FONT_SCALE * getMobileScale()
    end
    love.graphics.translate(x + w/2, y + (h - 8 * scale)/2)
    love.graphics.scale(scale, scale)
    font:drawCentered(text, 0, 0, 0xFFFFFFFF)
    love.graphics.pop()
end

local alertActive = false
local alertText = ""
local alertBtnText = "OK"
local alertCallback = nil
local alertProgress = 0
local alertTarget = 0
local alertClosing = false
local buttonPressed = false
local pressedOnButton = false

local function alert(text, btntext, callback)
    if alertActive then return end
    alertActive = true
    alertText = text
    alertBtnText = btntext or "OK"
    alertCallback = callback
    alertProgress = 0
    alertTarget = 1
    alertClosing = false
end

local ShowMenu = true
local Scene = 1
local convertPressed = false

local texts = { "Play", "Multiplayer", "Quit" }

local convertNeedProcess = false
local convertCode = 0
local convertData = ""
local pressedBtnId = 0

local dirtPath = UP.fileSaves.resolve('dirt.png')
local bgTexture = love.graphics.newImage(dirtPath)
bgTexture:setWrap("repeat", "repeat")

dbg.info(UP.fileSaves.resolve("level.dat"));

dbg.setShowInfo(false)

local function update()
    if UP.fileSaves.exists("level.dat") and not convertPressed then
        if not convertNeedProcess then
            alert("A save file with an old format was found. It needs to be converted to be accessible.", "convert", function()
                dbg.info("Pressed!")
                local olddata = UP.fileSaves.read("level.dat")
                local code, data = convertOldLevelData(olddata)
                convertNeedProcess = true
                convertCode = code
                convertData = data
            end)
        else
            if not alertActive then
                if convertCode == -1 then
                    alert(convertData, "OK")
                end
                if convertCode == 1 then
                    UP.fileSaves.write("save1.dat", convertData)
                    UP.fileSaves.removeFile("level.dat")
                    alert("The level data was successfully converted.", "OK")
                end
                convertPressed = true
                convertNeedProcess = false
            end
        end
    end

    if alertActive then return end

    local w, h = love.graphics.getDimensions()
    local cX = w / 2
    local btnW = getButtonWidth()
    local btnH = getButtonHeight()
    local step = getButtonStep()

    local mouseX, mouseY = love.mouse.getPosition()
    local inBounds = false

    if Scene == 1 then
        local startY = getButtonStartY(1)
        for i = 1, 3 do
            local btnY = startY + (i-1) * step
            if mouseX >= cX - btnW/2 and mouseY >= btnY and mouseX < cX + btnW/2 and mouseY < btnY + btnH then
                inBounds = true
                if isMouseDown() then
                    pressedBtnId = i
                end
                if isMouseJustReleased() then
                    if i == 1 then Scene = 2
                    elseif i == 3 then
                        -- _G.restoreLoveFilesystem()
                        love.event.quit()
                    end
                end
            end
        end
        if not inBounds then pressedBtnId = 0 end
    elseif Scene == 2 then
        local startY = math.max(40, getButtonStartY(2))
        for i = 1, 4 do
            local btnY = startY + (i-1) * step
            if mouseX >= cX - btnW/2 and mouseY >= btnY and mouseX < cX + btnW/2 and mouseY < btnY + btnH then
                inBounds = true
                if isMouseDown() then pressedBtnId = i end
                if isMouseJustReleased() then
                    ShowMenu = false
                    UP.vars["Game::loadLevelID"] = i
                    UP.vars["Game::startGame"] = 1
                end
            end
        end
        local backBtnY = startY + 4 * step + 20
        if mouseX >= cX - btnW/2 and mouseY >= backBtnY and mouseX < cX + btnW/2 and mouseY < backBtnY + btnH then
            inBounds = true
            if isMouseDown() then pressedBtnId = 5 end
            if isMouseJustReleased() then Scene = 1 end
        end
        if not inBounds then pressedBtnId = 0 end
    end
end

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, love.graphics.getWidth() / love.graphics.getHeight(), 0.1, 100)
glMatrixMode(GL_MODELVIEW)
glLoadIdentity()
glClearColor(0.3, 0.3, 0.3, 1)

table.insert(_G.drawCallbacks, function()
    _G.updateMouse()

    if ShowMenu then
        glClear(GL_COLOR_BUFFER_BIT)

        local w, h = love.graphics.getDimensions()
        local cX = w / 2
        local cY = h / 2

        local quadW = w / 4
        local quadH = h / 4
        local bgQuad = love.graphics.newQuad(0, 0, quadW, quadH, bgTexture:getDimensions())
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.draw(bgTexture, bgQuad, 0, 0, 0, 4, 4)

        local dt = love.timer.getDelta()
        if dt > 0.1 then dt = 0.1 end

        if alertActive then
            local speed = 5
            alertProgress = alertProgress + (alertTarget - alertProgress) * math.min(speed * dt, 1)
            if alertClosing and alertProgress < 0.01 then
                alertActive = false
                alertProgress = 0
                alertClosing = false
                pressedOnButton = false
                buttonPressed = false
            end
        end

        update()

        local smallScale = isMobile and (getMobileScale() * BASE_SMALL_TEXT_SCALE) or BASE_SMALL_TEXT_SCALE
        love.graphics.push()
        love.graphics.translate(0, h - 8 * smallScale)
        love.graphics.scale(smallScale, smallScale)
        font:draw("version 0.0.2 | by arti", 0, 0, 0xFFFFFFFF)
        love.graphics.pop()

        local btnW = getButtonWidth()
        local btnH = getButtonHeight()
        local step = getButtonStep()

        if Scene == 1 then -- Menu
            if logoImg then
                local logoScale = BASE_LOGO_SCALE * (isMobile and getMobileScale() or 1)
                local lw = logoImg:getWidth() * logoScale
                local lh = logoImg:getHeight() * logoScale
                local logoX = cX - lw / 2
                local logoY = 40 * (isMobile and getMobileScale() or 1)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(logoImg, logoX, logoY, 0, logoScale, logoScale)
            end

            local startY = getButtonStartY(1)
            for i = 1, 3 do
                local btnY = startY + (i-1) * step
                local btnX = cX - btnW / 2

                if i == 2 then
                    love.graphics.setColor(0.3, 0.3, 0.3)
                else
                    love.graphics.setColor(0.5, 0.5, 0.5)
                end
                if pressedBtnId == i and pressedBtnId ~= 2 then
                    love.graphics.setColor(0.45, 0.45, 0.45)
                end
                drawButton(btnX, btnY, btnW, btnH, texts[i])
            end
        elseif Scene == 2 then -- Play
            local startY = math.max(40, getButtonStartY(2))
            for i = 1, 4 do
                local btnY = startY + (i-1) * step
                local btnX = cX - btnW / 2
                love.graphics.setColor(0.5, 0.5, 0.5)
                if pressedBtnId == i then
                    love.graphics.setColor(0.45, 0.45, 0.45)
                end
                if UP.fileSaves.exists("save" .. i .. ".dat") then
                    drawButton(btnX, btnY, btnW, btnH, "Level " .. i)
                else
                    drawButton(btnX, btnY, btnW, btnH, " - ")
                end
            end
            local backBtnY = startY + 4 * step + 20
            love.graphics.setColor(0.5, 0.5, 0.5)
            if pressedBtnId == 5 then
                love.graphics.setColor(0.45, 0.45, 0.45)
            end
            drawButton(cX - btnW/2, backBtnY, btnW, btnH, "Back")
        end

        local mouseX, mouseY = love.mouse.getPosition()
        if alertActive then
            local winW = isMobile and w * 0.8 or BASE_ALERT_W
            local winH = isMobile and h * 0.55 or BASE_ALERT_H
            local scale = alertProgress
            local winX = cX - winW/2 * scale
            local winY = cY - winH/2 * scale

            local btnW2 = isMobile and w * 0.4 or BASE_ALERT_BTN_W
            local btnH2 = isMobile and h * 0.07 or BASE_ALERT_BTN_H
            local margin = 15

            local btnBaseX = winX + winW*scale/2 - btnW2/2
            local btnBaseY = winY + winH*scale - btnH2 - margin * scale

            local btnScale2 = buttonPressed and 1.1 or 1.0
            local bw = btnW2 * btnScale2
            local bh = btnH2 * btnScale2
            local bx = btnBaseX - (bw - btnW2)/2
            local by = btnBaseY - (bh - btnH2)/2

            if not alertClosing then
                local overButton = mouseX >= bx and mouseX <= bx + bw
                                and mouseY >= by and mouseY <= by + bh

                if _G.isMouseJustPressed() then
                    if overButton then
                        pressedOnButton = true
                        buttonPressed = true
                    else
                        pressedOnButton = false
                        buttonPressed = false
                    end
                elseif _G.isMouseJustReleased() then
                    if pressedOnButton and overButton then
                        if alertCallback then alertCallback() end
                        alertClosing = true
                        alertTarget = 0
                    end
                    pressedOnButton = false
                    buttonPressed = false
                else
                    buttonPressed = _G.isMouseDown() and overButton
                end
            end

            local alpha = 0.5 * alertProgress
            love.graphics.setColor(0, 0, 0, alpha)
            love.graphics.rectangle("fill", 0, 0, w, h)

            love.graphics.setColor(0.2, 0.2, 0.2, alertProgress)
            love.graphics.rectangle("fill", winX, winY, winW*scale, winH*scale)
            love.graphics.setColor(1, 1, 1, alertProgress)
            love.graphics.rectangle("line", winX, winY, winW*scale, winH*scale)

            local alertFontScale = (isMobile and getMobileScale() or 1) * BASE_FONT_SCALE * 0.8
            local padding = 20 * scale

            local textX = winX + padding
            local textY = winY + padding
            local textW = winW*scale - 2 * padding
            local textH = btnBaseY - padding - textY

            local function drawWrappedText(font, text, x, y, width, height)
                local baseScale = (isMobile and getMobileScale() or 1) * BASE_FONT_SCALE * 0.8
                local targetScale = baseScale
                local lines = {}
                local lineHeight = 0

                for attempt = 1, 3 do
                    lines = {}
                    local words = {}
                    for wrd in text:gmatch("%S+") do table.insert(words, wrd) end
                    local line = ""
                    
                    for _, wrd in ipairs(words) do
                        local test = (line == "" and "" or line .. " ") .. wrd
                        if font:width(test) * targetScale > width then
                            table.insert(lines, line)
                            line = wrd
                        else
                            line = test
                        end
                    end
                    if line ~= "" then table.insert(lines, line) end

                    lineHeight = font:getHeight() * targetScale * 1.2
                    local totalH = #lines * lineHeight

                    if totalH > height and attempt < 3 then
                        targetScale = targetScale * 0.85
                    else
                        break
                    end
                end

                local totalH = #lines * lineHeight
                local startY = y + (height - totalH) / 2
                
                for i, linetext in ipairs(lines) do
                    local lineWidthScaled = font:width(linetext) * targetScale
                    local lx = x + (width - lineWidthScaled) / 2
                    local ly = startY + (i-1) * lineHeight
                    
                    love.graphics.push()
                    love.graphics.translate(lx, ly)
                    love.graphics.scale(targetScale, targetScale)

                    font:drawShadow(linetext, 0, 0, 0xFFFFFFFF)
                    
                    love.graphics.pop()
                end
            end

            love.graphics.push()
            love.graphics.setColor(1, 1, 1, alertProgress)
            drawWrappedText(font, alertText, textX, textY, textW, textH)
            love.graphics.pop()

            local btnScale2 = buttonPressed and 1.1 or 1.0
            local bw = btnW2 * btnScale2
            local bh = btnH2 * btnScale2
            local bx = btnBaseX - (bw - btnW2)/2
            local by = btnBaseY - (bh - btnH2)/2

            love.graphics.setColor(0.5, 0.5, 0.5, alertProgress)
            love.graphics.rectangle("fill", bx, by, bw, bh)
            love.graphics.setColor(0, 0, 0, alertProgress)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", bx, by, bw, bh)
            love.graphics.setColor(1, 1, 1, alertProgress)

            love.graphics.push()
            local alertFontScale = (isMobile and getMobileScale() or 1) * BASE_FONT_SCALE * 0.8
            local textHeightScaled = font:getHeight() * (alertFontScale * 0.9)
            local textOffsetY = -3 * alertFontScale
            local fontY = by + (bh - textHeightScaled) / 2 + textOffsetY
            love.graphics.translate(bx + bw / 2, fontY)
            love.graphics.scale(alertFontScale * 0.9, alertFontScale * 0.9)
            font:drawCentered(alertBtnText, 0, 0, 0xFFFFFFFF)
            love.graphics.pop()

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setLineWidth(1)
        end
    end
end)

function love.quit()
    if _G.restoreLoveFilesystem then
        _G.restoreLoveFilesystem()
    end
end