-- util/debugPanel.lua

local settings = {
    enabled      = true,
    showInfo     = true,
    breakAtError = false,
    fadeTime     = 0,
}

local broken = false
local messages = {}

local LEVELS = { INFO = "INFO", WARNING = "WARNING", ERROR = "ERROR" }

local function addMessage(text, level)
    if not settings.enabled then return end
    if broken then return end
    if level == LEVELS.INFO and not settings.showInfo then return end

    local now = love.timer.getTime()
    local lines = {}
    for line in (text .. "\n"):gmatch("(.-)\n") do
        table.insert(lines, line)
    end

    for _, line in ipairs(lines) do
        table.insert(messages, {
            text = line,
            level = level,
            time = now
        })
    end

    if level == LEVELS.ERROR and settings.breakAtError then
        broken = true
    end
end
_G.dbg = setmetatable({
    INFO    = LEVELS.INFO,
    WARNING = LEVELS.WARNING,
    ERROR   = LEVELS.ERROR,

    setEnabled = function(en) settings.enabled = en end,
    setShowInfo = function(show) settings.showInfo = show end,
    setBreakAtError = function(brk) settings.breakAtError = brk end,
    setFadeTime = function(seconds) settings.fadeTime = tonumber(seconds) or 0 end,

    isEnabled = function() return settings.enabled end,
    isShowInfo = function() return settings.showInfo end,
    isBreakAtError = function() return settings.breakAtError end,
    getFadeTime = function() return settings.fadeTime end,

    info = function(msg) addMessage(tostring(msg), LEVELS.INFO) end,
    warn = function(msg) addMessage(tostring(msg), LEVELS.WARNING) end,
    error = function(msg) addMessage(tostring(msg), LEVELS.ERROR) end,
}, {
    __call = function(t, msg)
        t.info(msg)
    end
})

_G.drawCallbacks = {}

if not _G._dbgInitialized then
    _G._dbgInitialized = true

    local originalKeypressed = love.keypressed
    love.keypressed = function(key, scancode, isrepeat)
        if key == "c" and love.keyboard.isDown("lctrl", "rctrl") then
            local allText = {}
            for _, msg in ipairs(messages) do
                allText[#allText + 1] = "[" .. msg.level .. "] " .. msg.text
            end
            love.system.setClipboardText(table.concat(allText, "\n"))
            dbg.info("-- Log copied to clipboard --")
        end
        if originalKeypressed then originalKeypressed(key, scancode, isrepeat) end
    end

    local originalDraw = love.draw
    love.draw = function()
        if originalDraw then originalDraw() end

        for _, callback in ipairs(_G.drawCallbacks) do
            local ok, err = pcall(callback)
            if not ok then
                dbg.error("Draw callback error: " .. tostring(err))
            end
        end

        if settings.enabled then
            local now = love.timer.getTime()
            local screenWidth, screenHeight = love.graphics.getDimensions()

            -- адаптивная ширина панели: 90% экрана, но не более 800px
            local panelWidth = math.min(screenWidth * 0.9, 800)
            -- небольшое масштабирование для очень узких экранов
            local scale = math.min(screenWidth / 400, 1.5)
            local lineHeight = math.floor(16 * scale)
            local fontSize = math.max(10, math.floor(12 * scale))
            local padding = math.floor(10 * scale)

            -- удаление устаревших сообщений (кроме ERROR при breakAtError)
            if settings.fadeTime > 0 then
                local newMessages = {}
                for _, msg in ipairs(messages) do
                    local keep = false
                    if settings.breakAtError and msg.level == LEVELS.ERROR then
                        keep = true   -- ошибки всегда остаются
                    elseif (now - msg.time) <= settings.fadeTime then
                        keep = true
                    end
                    if keep then
                        newMessages[#newMessages + 1] = msg
                    end
                end
                messages = newMessages
            end

            -- фильтруем видимые
            local visible = {}
            for _, msg in ipairs(messages) do
                -- проверка fadeTime (ошибки при breakAtError не удаляются по времени)
                local timeOk = (settings.fadeTime <= 0) or
                               (settings.breakAtError and msg.level == LEVELS.ERROR) or
                               ((now - msg.time) <= settings.fadeTime)

                if timeOk then
                    if settings.showInfo or msg.level ~= LEVELS.INFO then
                        visible[#visible + 1] = msg
                    end
                end
            end

            if #visible > 0 then
                local colors = {
                    [LEVELS.INFO]    = {1, 1, 1},
                    [LEVELS.WARNING] = {1, 0.8, 0},
                    [LEVELS.ERROR]   = {1, 0, 0},
                }

                love.graphics.reset()
                local maxLines = 30
                local startIdx = math.max(1, #visible - maxLines + 1)
                local panelHeight = math.min(#visible, maxLines) * lineHeight + padding * 2

                love.graphics.setColor(0, 0, 0, 0.8)
                love.graphics.rectangle("fill", padding, padding, panelWidth, panelHeight)

                local font = love.graphics.newFont(fontSize)
                love.graphics.setFont(font)

                for i = startIdx, #visible do
                    local y = padding + (i - startIdx) * lineHeight + 2
                    local col = colors[visible[i].level] or {1,1,1}
                    love.graphics.setColor(col)
                    -- перенос текста внутри панели
                    love.graphics.printf(visible[i].text, padding + 5, y, panelWidth - 10, "left")
                end
            end
        end
    end
end