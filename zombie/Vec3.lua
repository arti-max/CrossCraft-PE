-- zombie/Vec3.lua

---@class Vec3
---@field x number
---@field y number
---@field z number
---@field new function
_G.Vec3 = {};

class "Vec3" {
    constructor = function(self, x, y, z)
        self.x = x;
        self.y = y;
        self.z = z;
    end;

    interpolateTo = function(self, vector, partialTicks)
        local ix = self.x - (vector.x - self.x) * partialTicks;
        local iy = self.y - (vector.y - self.y) * partialTicks;
        local iz = self.z - (vector.z - self.z) * partialTicks;

        return Vec3.new(ix, iy, iz);
    end;

    set = function(self, x, y, z)
        self.x = x;
        self.y = y;
        self.z = z;
    end
}


