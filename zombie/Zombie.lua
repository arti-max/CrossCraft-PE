--- zombie/Zombie.lua

---@class Zombie : Entity
---@field rotation number
---@field rotationDF number
---@field timeOffs number
---@field speed number
---@field model Model
---@field new fun(level: Level, x: number, y: number, z: number): Zombie
---@field _super any
---@field render fun(self: Zombie, partialTicks: number)
_G.Zombie = {};

class "Zombie" "extends" "Entity" {

    ---@param self Zombie
    ---@param level Level
    ---@param x number
    ---@param y number
    ---@param z number
    constructor = function(self, level, x, y, z)
        self._super.constructor(self, level);

        self.rotation = math.random() * math.pi * 2;
        self.rotationDF = (math.random() + 1.0) * 0.01;
        self.timeOffs = math.random() * 1239813.0;
        self.speed = 1.0;

        self.model = Model.new();

        self:setPosition(x, y, z);
    end;

    ---@param self Zombie
    tick = function(self)
        self._super.tick(self);

        if (self.y < -128) then
            self:remove();
        end

        self.rotation = self.rotation + self.rotationDF;

        self.rotationDF = self.rotationDF * 0.99;
        self.rotationDF = self.rotationDF + (math.random() - math.random()) * math.random() * math.random() * 0.009999999776482582;

        local xx = math.sin(self.rotation);
        local yy = math.cos(self.rotation);

        if (self.grounded and math.random() < 0.08) then
            self.dy = 0.5;
        end

        local speed = 0.02;
        if self.grounded then
            speed = 0.1;
        end

        self:moveRelative(xx, yy, speed);

        self.dy = self.dy - 0.08;

        self:move(self.dx, self.dy, self.dz);

        self.dx = self.dx * 0.91;
        self.dy = self.dy * 0.98;
        self.dz = self.dz * 0.91;

        if self.grounded then
            self.dx = self.dx * 0.7;
            self.dz = self.dz * 0.7;
        end
    end;

    ---@param self Zombie
    ---@param partialTicks number
    render = function(self, partialTicks)
        glPushMatrix();
        glEnable(GL_TEXTURE_2D);
        glEnable(GL_DEPTH_TEST);

        glBindTexture(GL_TEXTURE_2D, textures.char);

        local time = (love.timer.getTime() * 1e9) / 1000000000 * 10 * self.speed + self.timeOffs;

        local x = self.xo + (self.x - self.xo) * partialTicks;
        local y = self.yo + (self.y - self.yo) * partialTicks;
        local z = self.zo + (self.z - self.zo) * partialTicks;

        glTranslatef(x, y, z);
        glScalef(1, -1, 1);

        local size = 7 / 120;
        glScalef(size, size, size);

        local offsetY = math.abs(math.sin(time * 2 / 3)) * 5;
        glTranslatef(0, -offsetY, 0);

        glRotatef(math.deg(self.rotation) + 180, 0, 1, 0);

        self.model:render(time);

        glDisable(GL_TEXTURE_2D);
        glPopMatrix();
    end
}