-- Entity.lua

---@class Entity
---@field level Level
---@field heightOffset number
---@field x number
---@field y number
---@field z number
---@field xo number
---@field yo number
---@field zo number
---@field dx number
---@field dy number
---@field dz number
---@field xRot number
---@field yRot number
---@field grounded boolean
---@field aabb AABB
---@field removed boolean
---@field new fun(level: Level): Entity
---@field setPosition fun(self: Entity, x: number, y: number, z: number)
---@field remove fun(self: Entity)
---@field resetPosition fun(self: Entity)
---@field turn fun(self: Entity, x: number, y: number)
---@field tick fun(self: Entity)
---@field move fun(self: Entity, x: number, y: number, z: number)
---@field moveRelative fun(self: Entity, x: number, z: number, speed: number)
---@field isLit fun(self: Entity): boolean
_G.Entity = {};

class "Entity" {
    constructor = function(self, level)
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
        self.removed = false;

        self:resetPosition();
    end;

    setPosition = function (self, x, y, z)
        self.x = x;
        self.y = y;
        self.z = z;

        -- entity size
        local width = 0.3;
        local height = 0.9;

        self.aabb = AABB.new(x - width, y - height, z - width, x + width, y + height, z + width);
    end;

    remove = function(self)
        self.removed = true;
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

    ---@param self Entity
    isLit = function(self)
        return self.level:isLit(math.floor(self.x), math.floor(self.y), math.floor(self.z));
    end;
}

if not Entity then
    dbg.error("Entity class error");
end