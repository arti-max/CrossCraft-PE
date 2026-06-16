-- Player.lua

---@class Player : Entity
---@field useTouch boolean
---@field touchMoveX number
---@field touchMoveY number
---@field touchJump boolean
---@field touchRespawn boolean
---@field touchSave boolean
---@field touchBreak boolean
---@field touchPlace boolean
---@field prevTouchBreak boolean
---@field prevTouchPlace boolean
---@field prevKeyBreak boolean
---@field prevKeyPlace boolean
---@field _super any
---@field new fun(level: Level): Player

_G.Player = {}

class "Player" "extends" "Entity" {
    
    ---@param self Player
    ---@param level Level
    constructor = function(self, level)
        self._super.constructor(self, level);
        -- for mobile:
        self.useTouch = false;
        self.touchMoveX = 0;
        self.touchMoveY = 0;
        self.touchJump = false;
        self.touchRespawn = false;
        self.touchSave = false;
        self.touchZombie = false;
        
        -- break/place
        self.touchBreak = false;
        self.touchPlace = false;
        self.prevTouchBreak = false;
        self.prevTouchPlace = false;
        self.prevKeyBreak = false;
        self.prevKeyPlace = false;
    end;


    tick = function(self)
        self._super.tick(self);

        local xx = 0;
        local yy = 0;

        if (love.keyboard.isDown("r")) then
            self:resetPosition();
        end

        if (love.keyboard.isDown("return")) then
            local ok, err = pcall(function() 
                self.level:save();
            end);
            if not ok then
                dbg.error("Error in save level data: " .. tostring(err));
            end
        end

        if self.useTouch then
            xx = self.touchMoveY;
            yy = self.touchMoveX;
            if self.touchJump and self.grounded then
                self.dy = 0.5;
            end
        else
            if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
                xx = xx - 1;
            end
            if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
                xx = xx + 1;
            end
            if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
                yy = yy - 1;
            end
            if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
                yy = yy + 1;
            end

            if (love.keyboard.isDown("space")) and self.grounded then
                self.dy = 0.5;
            end
        end

        local speed = 0.1;
        if not self.grounded then
            speed = 0.02;
        end
        self:moveRelative(yy, xx, speed);

        self.dy = self.dy - 0.08;

        self:move(self.dx, self.dy, self.dz);

        self.dx = self.dx * 0.91;
        self.dy = self.dy * 0.98;
        self.dz = self.dz * 0.91;

        if self.grounded then
            self.dx = self.dx * 0.6;
            self.dz = self.dz * 0.6;
        end

        if not self.useTouch then
            local keyBreak = love.keyboard.isDown("e");
            local keyPlace = love.keyboard.isDown("q");

            if keyBreak and not self.prevKeyBreak then
                self.touchBreak = true;
            end
            if keyPlace and not self.prevKeyPlace then
                self.touchPlace = true;
            end

            self.prevKeyBreak = keyBreak;
            self.prevKeyPlace = keyPlace;
        end
    end
}

if not Player then
    dbg.error("Player class error");
end