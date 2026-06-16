-- zombie/Vertex.lua

---@class Vertex
---@field position Vec3
---@field u number
---@field v number
---@field new function
---@field remap fun(self: Vertex, u: number, v: number): Vertex
_G.Vertex = {};

class "Vertex" {

    constructor = function(self, ...)
        local args = {...};

        if #args == 5 then
            self.position = Vec3.new(args[1], args[2], args[3]);
            self.u = args[4];
            self.v = args[5];
        elseif #args == 3 then
            local v = args[1];
            local mt = getmetatable(v);
            if mt == Vec3 then
                self.position = v;
                self.u = args[2];
                self.v = args[3];
            elseif mt == Vertex then
                self.position = v.position;
                self.u = args[2];
                self.v = args[3];
            else
                dbg.error("Vertex constructor err: invalid first arg type");
            end
        else
            dbg.error("vertex constructor err: expected 5 numbers or 3 args (Vec3/Vertex, u, v)");
        end
    end;

    ---Remap u,v coords
    ---@param self Vertex
    ---@param u number
    ---@param v number
    ---@return Vertex
    remap = function(self, u, v)
        return Vertex.new(self, u, v);
    end
}