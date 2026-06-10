-- Controls.lua

_G.Controls = {}

class "Controls" {
    constructor = function(self, player)
        self.player = player

        local os = love.system.getOS()
        self.isMobile = (os == "Android" or os == "iOS")

        if (self.isMobile) then
            love.window.setFullscreen(true, "desktop");
            UP.vars["Sensetivity"] = UP.vars["Sensetivity"]+0.20;
        end

        self.player.useTouch = self.isMobile
        self.visible = self.isMobile

        self.btnSize = 60
        self.actionBtnSize = 60
        self.actionGap = 8

        self.smallBtnSize = 36
        self.smallBtnGap = 8

        self.lastBreak = false
        self.lastPlace = false
        self.lastRespawn = false
        self.lastSave = false

        self:layout()
    end;

    layout = function(self)
        local w, h = love.graphics.getDimensions()
        self.dpadCenterX = w * 0.18
        self.dpadCenterY = h * 0.65
        self.actionBtnX = w * 0.95
        local as = self.actionBtnSize
        local gap = self.actionGap
        self.actionBtnBuildY = h * 0.50
        self.actionBtnJumpY  = self.actionBtnBuildY + as/2 + gap + as/2
        self.actionBtnBreakY = self.actionBtnJumpY + as/2 + gap + as/2

        local sbs = self.smallBtnSize
        local sbGap = self.smallBtnGap
        local margin = 8
        self.smallBtnGroupX = w - 2 * sbs - sbGap - margin
        self.smallBtnY = 40
    end;

    isPointOverControl = function(self, x, y)
        local s = self.btnSize
        local cx, cy = self.dpadCenterX, self.dpadCenterY
        local hs = s / 2

        if x >= cx - hs and x <= cx + hs and y >= cy - hs and y <= cy + hs then
            return true
        end
        -- up
        if x >= cx - hs and x <= cx + hs and y >= cy - hs*3 and y <= cy - hs then return true end
        -- down
        if x >= cx - hs and x <= cx + hs and y >= cy + hs and y <= cy + hs*3 then return true end
        -- left
        if x >= cx - hs*3 and x <= cx - hs and y >= cy - hs and y <= cy + hs then return true end
        -- right
        if x >= cx + hs and x <= cx + hs*3 and y >= cy - hs and y <= cy + hs then return true end

        local ax = self.actionBtnX
        local as = self.actionBtnSize
        local ahs = as / 2
        if x >= ax - ahs and x <= ax + ahs then
            if y >= self.actionBtnBuildY - ahs and y <= self.actionBtnBuildY + ahs then return true end
            if y >= self.actionBtnJumpY - ahs  and y <= self.actionBtnJumpY + ahs  then return true end
            if y >= self.actionBtnBreakY - ahs and y <= self.actionBtnBreakY + ahs then return true end
        end

        local sbs = self.smallBtnSize
        local gx = self.smallBtnGroupX
        local gy = self.smallBtnY
        if y >= gy and y <= gy + sbs then
            if x >= gx and x <= gx + sbs then return true end
            if x >= gx + sbs + self.smallBtnGap and x <= gx + 2*sbs + self.smallBtnGap then return true end
        end
        return false
    end;

    pollInput = function(self, cameraTouchId)
        if not self.isMobile then
            return
        end

        local moveX, moveY = 0, 0
        local jump = false
        local breakAction = false
        local placeAction = false
        local respawnAction = false
        local saveAction = false

        local function processPos(x, y)
            local cx, cy = self.dpadCenterX, self.dpadCenterY
            local s = self.btnSize
            local hs = s / 2
            if x >= cx - hs and x <= cx + hs then
                if y >= cy - hs*3 and y <= cy - hs then moveY = -1 end
                if y >= cy + hs and y <= cy + hs*3 then moveY = 1 end
            end
            if y >= cy - hs and y <= cy + hs then
                if x >= cx - hs*3 and x <= cx - hs then moveX = -1 end
                if x >= cx + hs and x <= cx + hs*3 then moveX = 1 end
            end

            local ax = self.actionBtnX
            local as = self.actionBtnSize
            local ahs = as / 2
            if x >= ax - ahs and x <= ax + ahs then
                if y >= self.actionBtnJumpY - ahs and y <= self.actionBtnJumpY + ahs then
                    jump = true
                end
                if y >= self.actionBtnBuildY - ahs and y <= self.actionBtnBuildY + ahs then
                    placeAction = true
                end
                if y >= self.actionBtnBreakY - ahs and y <= self.actionBtnBreakY + ahs then
                    breakAction = true
                end
            end

            local sbs = self.smallBtnSize
            local gx = self.smallBtnGroupX
            local gy = self.smallBtnY
            if y >= gy and y <= gy + sbs then
                if x >= gx and x <= gx + sbs then
                    respawnAction = true
                elseif x >= gx + sbs + self.smallBtnGap and x <= gx + 2*sbs + self.smallBtnGap then
                    saveAction = true
                end
            end
        end

        local touches = love.touch.getTouches()
        if #touches > 0 then
            for _, id in ipairs(touches) do
                if id ~= cameraTouchId then
                    local tx, ty = love.touch.getPosition(id)
                    processPos(tx, ty)
                end
            end
        else
            if not cameraTouchId and love.mouse.isDown(1) then
                local mx, my = love.mouse.getPosition()
                processPos(mx, my)
            end
        end

        self.player.touchMoveX = moveX
        self.player.touchMoveY = moveY
        self.player.touchJump = jump

        local breakPressed = breakAction and not self.lastBreak
        local placePressed = placeAction and not self.lastPlace
        local respawnPressed = respawnAction and not self.lastRespawn
        local savePressed = saveAction and not self.lastSave

        self.player.touchBreak = breakPressed
        self.player.touchPlace = placePressed
        self.player.touchRespawn = respawnPressed
        self.player.touchSave = savePressed

        self.lastBreak = breakAction
        self.lastPlace = placeAction
        self.lastRespawn = respawnAction
        self.lastSave = saveAction
    end;

    render = function(self)
        if not self.visible then return end
        self:layout()

        love.graphics.push("all")
        love.graphics.reset()

        local function drawGraphicButton(x, y, w, h, drawIcon)
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle("fill", x, y, w, h)
            love.graphics.setColor(0, 0, 0)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", x, y, w, h)
            love.graphics.setColor(1, 1, 1)
            local margin = 8
            drawIcon(x + margin, y + margin, w - 2*margin, h - 2*margin)
        end

        local function drawTextButton(x, y, w, h, text)
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle("fill", x, y, w, h)
            love.graphics.setColor(0, 0, 0)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", x, y, w, h)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(text, x, y + h/2 - 8, w, "center")
        end

        local cx, cy = self.dpadCenterX, self.dpadCenterY
        local s = self.btnSize
        local hs = s / 2

        -- Up
        drawGraphicButton(cx - hs, cy - hs*3, s, s, function(x, y, w, h)
            love.graphics.polygon("fill", x + w/2, y, x + w, y + h, x, y + h)
        end)
        -- Down
        drawGraphicButton(cx - hs, cy + hs, s, s, function(x, y, w, h)
            love.graphics.polygon("fill", x, y, x + w, y, x + w/2, y + h)
        end)
        -- Left
        drawGraphicButton(cx - hs*3, cy - hs, s, s, function(x, y, w, h)
            love.graphics.polygon("fill", x, y + h/2, x + w, y, x + w, y + h)
        end)
        -- Right
        drawGraphicButton(cx + hs, cy - hs, s, s, function(x, y, w, h)
            love.graphics.polygon("fill", x, y, x + w, y + h/2, x, y + h)
        end)

        -- Build, Jump, Break
        local ax = self.actionBtnX
        local as = self.actionBtnSize
        local ahs = as / 2

        drawTextButton(ax - ahs, self.actionBtnBuildY - ahs, as, as, "Build")
        drawTextButton(ax - ahs, self.actionBtnJumpY  - ahs, as, as, "Jump")
        drawTextButton(ax - ahs, self.actionBtnBreakY - ahs, as, as, "Break")

        local sbs = self.smallBtnSize
        local gx = self.smallBtnGroupX
        local gy = self.smallBtnY
        drawTextButton(gx, gy, sbs, sbs, "R")
        drawTextButton(gx + sbs + self.smallBtnGap, gy, sbs, sbs, "S")

        love.graphics.pop()
    end;
}