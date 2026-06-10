-- phys/aabb.lua

_G.AABB = {}

class "AABB" {
    constructor = function(self, x0, y0, z0, x1, y1, z1)
        self.min = {x = x0, y = y0, z = z0}
        self.max = {x = x1, y = y1, z = z1}
    end;

    clone = function(self)
        return AABB.new(self.min.x, self.min.y, self.min.z,
                        self.max.x, self.max.y, self.max.z)
    end;

    expand = function(self, x, y, z)
        local minX, minY, minZ = self.min.x, self.min.y, self.min.z
        local maxX, maxY, maxZ = self.max.x, self.max.y, self.max.z

        if x < 0 then minX = minX + x else maxX = maxX + x end
        if y < 0 then minY = minY + y else maxY = maxY + y end
        if z < 0 then minZ = minZ + z else maxZ = maxZ + z end

        return AABB.new(minX, minY, minZ, maxX, maxY, maxZ)
    end;

    grow = function(self, x, y, z)
        return AABB.new(
            self.min.x - x, self.min.y - y, self.min.z - z,
            self.max.x + x, self.max.y + y, self.max.z + z
        )
    end;

    intersects = function(self, other)
        return (self.min.x < other.max.x and self.max.x > other.min.x) and
               (self.min.y < other.max.y and self.max.y > other.min.y) and
               (self.min.z < other.max.z and self.max.z > other.min.z)
    end;

    move = function(self, dx, dy, dz)
        self.min.x = self.min.x + dx
        self.min.y = self.min.y + dy
        self.min.z = self.min.z + dz
        self.max.x = self.max.x + dx
        self.max.y = self.max.y + dy
        self.max.z = self.max.z + dz
    end;

    offset = function(self, dx, dy, dz)
        return AABB.new(
            self.min.x + dx, self.min.y + dy, self.min.z + dz,
            self.max.x + dx, self.max.y + dy, self.max.z + dz
        )
    end;

    clipXCollide = function(self, other, x)
        if other.max.y <= self.min.y or other.min.y >= self.max.y then return x end
        if other.max.z <= self.min.z or other.min.z >= self.max.z then return x end

        if x > 0 and other.max.x <= self.min.x then
            local max = self.min.x - other.max.x   -- epsilon = 0
            if max < x then x = max end
        elseif x < 0 and other.min.x >= self.max.x then
            local max = self.max.x - other.min.x
            if max > x then x = max end
        end
        return x
    end;

    clipYCollide = function(self, other, y)
        if other.max.x <= self.min.x or other.min.x >= self.max.x then return y end
        if other.max.z <= self.min.z or other.min.z >= self.max.z then return y end

        if y > 0 and other.max.y <= self.min.y then
            local max = self.min.y - other.max.y
            if max < y then y = max end
        elseif y < 0 and other.min.y >= self.max.y then
            local max = self.max.y - other.min.y
            if max > y then y = max end
        end
        return y
    end;

    clipZCollide = function(self, other, z)
        if other.max.x <= self.min.x or other.min.x >= self.max.x then return z end
        if other.max.y <= self.min.y or other.min.y >= self.max.y then return z end

        if z > 0 and other.max.z <= self.min.z then
            local max = self.min.z - other.max.z
            if max < z then z = max end
        elseif z < 0 and other.min.z >= self.max.z then
            local max = self.max.z - other.min.z
            if max > z then z = max end
        end
        return z
    end;

    resolveCollision = function(self, staticAABB)
        local dx = 0
        if self.max.x > staticAABB.min.x and self.min.x < staticAABB.min.x then
            dx = staticAABB.min.x - self.max.x
        elseif self.min.x < staticAABB.max.x and self.max.x > staticAABB.max.x then
            dx = staticAABB.max.x - self.min.x
        end

        local dy = 0
        if self.max.y > staticAABB.min.y and self.min.y < staticAABB.min.y then
            dy = staticAABB.min.y - self.max.y
        elseif self.min.y < staticAABB.max.y and self.max.y > staticAABB.max.y then
            dy = staticAABB.max.y - self.min.y
        end

        local dz = 0
        if self.max.z > staticAABB.min.z and self.min.z < staticAABB.min.z then
            dz = staticAABB.min.z - self.max.z
        elseif self.min.z < staticAABB.max.z and self.max.z > staticAABB.max.z then
            dz = staticAABB.max.z - self.min.z
        end

        local absDx, absDy, absDz = math.abs(dx), math.abs(dy), math.abs(dz)
        if absDx < absDy and absDx < absDz then
            return dx, 0, 0
        elseif absDy < absDz then
            return 0, dy, 0
        else
            return 0, 0, dz
        end
    end;
}