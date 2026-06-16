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

    table.insert(messages, {
        text = tostring(text),
        level = level,
        time = love.timer.getTime(),
    })

    if level == LEVELS.ERROR and settings.breakAtError then
        broken = true
    end
end


_G.dbg = setmetatable({
    INFO    = LEVELS.INFO,
    WARNING = LEVELS.WARNING,
    ERROR   = LEVELS.ERROR,

    setEnabled      = function(v) settings.enabled = v end,
    setShowInfo     = function(v) settings.showInfo = v end,
    setBreakAtError = function(v) settings.breakAtError = v end,
    setFadeTime     = function(s) settings.fadeTime = tonumber(s) or 0 end,

    isEnabled       = function() return settings.enabled end,
    isShowInfo      = function() return settings.showInfo end,
    isBreakAtError  = function() return settings.breakAtError end,
    getFadeTime     = function() return settings.fadeTime end,

    info  = function(msg) addMessage(tostring(msg), LEVELS.INFO) end,
    warn  = function(msg) addMessage(tostring(msg), LEVELS.WARNING) end,
    error = function(msg) addMessage(tostring(msg), LEVELS.ERROR) end,
}, {
    __call = function(t, msg) t.info(msg) end
})


_G.drawCallbacks = {}


if not _G._dbgInitialized then
    _G._dbgInitialized = true

    local function copyLogToClipboard()
        local all = {}
        for _, msg in ipairs(messages) do
            all[#all+1] = "[" .. msg.level .. "] " .. msg.text
        end
        love.system.setClipboardText(table.concat(all, "\n"))
        dbg.info("-- Log copied to clipboard --")
    end

    local origKeypressed = love.keypressed
    love.keypressed = function(key, scancode, isrepeat)
        if key == "c" and love.keyboard.isDown("lctrl", "rctrl") then
            copyLogToClipboard()
        end
        if origKeypressed then origKeypressed(key, scancode, isrepeat) end
    end

    local panelRect = { x=0, y=0, w=0, h=0 }

    local function insidePanel(px, py)
        return px >= panelRect.x and px <= panelRect.x + panelRect.w
           and py >= panelRect.y and py <= panelRect.y + panelRect.h
    end

    local origMousepressed = love.mousepressed
    love.mousepressed = function(x, y, button, istouch)
        if settings.enabled and button == 1 and insidePanel(x, y) then
            copyLogToClipboard()
        end
        if origMousepressed then origMousepressed(x, y, button, istouch) end
    end

    local origTouchpressed = love.touchpressed
    love.touchpressed = function(id, x, y, dx, dy, pressure)
        if settings.enabled and insidePanel(x, y) then
            copyLogToClipboard()
        end
        if origTouchpressed then origTouchpressed(id, x, y, dx, dy, pressure) end
    end

    local origDraw = love.draw
    love.draw = function()
        if origDraw then origDraw() end

        for _, cb in ipairs(_G.drawCallbacks) do
            local ok, err = pcall(cb)
            if not ok then dbg.error("Draw callback error: " .. tostring(err)) end
        end

        if not settings.enabled then return end

        local now = love.timer.getTime()
        local sw, sh = love.graphics.getDimensions()

        -- Параметры панели
        local panelW = math.min(sw * 0.9, 800)
        local scale = math.min(sw / 400, 1.5)
        local fontSize = math.max(10, math.floor(12 * scale))
        local lineH = math.floor(18 * scale)
        local padding = math.floor(8 * scale)

        if settings.fadeTime > 0 then
            local new = {}
            for _, msg in ipairs(messages) do
                if (settings.breakAtError and msg.level == LEVELS.ERROR) or
                   (now - msg.time) <= settings.fadeTime then
                    new[#new+1] = msg
                end
            end
            messages = new
        end

        local visible = {}
        for _, msg in ipairs(messages) do
            local timeOk = (settings.fadeTime <= 0) or
                           (settings.breakAtError and msg.level == LEVELS.ERROR) or
                           ((now - msg.time) <= settings.fadeTime)
            if timeOk and (settings.showInfo or msg.level ~= LEVELS.INFO) then
                visible[#visible+1] = msg
            end
        end

        if #visible == 0 then
            panelRect = { x=0, y=0, w=0, h=0 }
            return
        end

        local font = love.graphics.newFont(fontSize)
        love.graphics.setFont(font)

        local maxTextWidth = panelW - 10
        local wrappedLines = {}
        for _, msg in ipairs(visible) do
            local text = msg.text
            local line = ""
            for char in text:gmatch(".") do
                local candidate = line .. char
                if font:getWidth(candidate) > maxTextWidth then
                    wrappedLines[#wrappedLines+1] = {text = line, level = msg.level}
                    line = char
                else
                    line = candidate
                end
            end
            if line ~= "" then
                wrappedLines[#wrappedLines+1] = {text = line, level = msg.level}
            end
        end

        local maxLines = 30
        local totalLines = #wrappedLines
        local startLine = math.max(1, totalLines - maxLines + 1)
        local visLines = math.min(totalLines, maxLines)

        local panelH = visLines * lineH + padding * 2
        panelRect = { x = padding, y = padding, w = panelW, h = panelH }

        love.graphics.reset()
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", panelRect.x, panelRect.y, panelRect.w, panelRect.h)

        local colors = {
            [LEVELS.INFO]    = {1, 1, 1},
            [LEVELS.WARNING] = {1, 0.8, 0},
            [LEVELS.ERROR]   = {1, 0, 0},
        }

        for i = startLine, totalLines do
            local lineData = wrappedLines[i]
            local y = padding + (i - startLine) * lineH + 2
            local col = colors[lineData.level] or {1,1,1}
            love.graphics.setColor(col)
            love.graphics.print(lineData.text, padding + 5, y)
        end
    end
end