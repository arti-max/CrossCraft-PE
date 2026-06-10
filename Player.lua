-- Player.lua

_G.Player = {}

class "Player" {
    
    constructor = function (self, level)
        self.level = level;
        self.heightOffset = 1.62;
        self.x = 0;
        self.y = 0;
        self.z = 0;
        self.xo = 0;
        self.yo = 0;
        self.zo = 0;
        self.dx = 0;
        self.dy = 0;
        self.dz = 0;
        self.xRot = 0;
        self.yRot = 0;
        self.grounded = false;
        self.aabb = nil;
        -- for mobile:
        self.useTouch = false;
        self.touchMoveX = 0;
        self.touchMoveY = 0;
        self.touchJump = false;
        self.touchRespawn = false;
        self.touchSave = false;
        
        -- break/place
        self.touchBreak = false;
        self.touchPlace = false;
        self.prevTouchBreak = false;
        self.prevTouchPlace = false;
        self.prevKeyBreak = false;
        self.prevKeyPlace = false;
        

        self:resetPosition();
    end;


    setPosition = function (self, x, y, z)
        self.x = x;
        self.y = y;
        self.z = z;

        -- player size
        local width = 0.3;
        local height = 0.9;

        self.aabb = AABB.new(x - width, y - height, z - width, x + width, y + height, z + width);
    end;

    resetPosition = function(self)
        local x = math.random() * self.level.width;
        local y = self.level.depth + 3;
        local z = math.random() * self.level.height;

        self:setPosition(x, y, z);
    end;

    turn = function (self, x, y)
        self.yRot = self.yRot + x * tonumber(UP.vars["Sensetivity"]);
        self.xRot = self.xRot - y * tonumber(UP.vars["Sensetivity"]);

        self.xRot = math.max(-90.0, self.xRot);
        self.xRot = math.min(90.0, self.xRot);
    end;

    tick = function (self)
        self.xo = self.x;
        self.yo = self.y;
        self.zo = self.z;

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
    end;

    move = function (self, x, y, z)
        local xo = x;
        local yo = y;
        local zo = z;

        local aabbs = self.level:getCubes(self.aabb:expand(x, y, z));

        for _, abb in ipairs(aabbs) do
            y = abb:clipYCollide(self.aabb, y);
        end
        self.aabb:move(0, y, 0);

        for _, abb in ipairs(aabbs) do
            x = abb:clipXCollide(self.aabb, x);
        end
        self.aabb:move(x, 0, 0);

        for _, abb in ipairs(aabbs) do
            z = abb:clipZCollide(self.aabb, z);
        end
        self.aabb:move(0, 0, z);

        self.grounded = (yo ~= y) and (yo < 0);

        if x ~= xo then self.dx = 0 end;
        if y ~= yo then self.dy = 0 end;
        if z ~= zo then self.dz = 0 end;

        self.x = (self.aabb.min.x + self.aabb.max.x) / 2;
        self.y = self.aabb.min.y + self.heightOffset;
        self.z = (self.aabb.min.z + self.aabb.max.z) / 2;
    end;

    moveRelative = function(self, x, z, speed)
        local dist = x*x + z*z;

        if (dist < 0.01) then
            return;
        end

        dist = speed / math.sqrt(dist);
        x = x * dist;
        z = z * dist;

        local sin = math.sin(math.rad(self.yRot));
        local cos = math.cos(math.rad(self.yRot));

        self.dx = self.dx + (x * cos - z * sin);
        self.dz = self.dz + (z * cos + x * sin);
    end;
}