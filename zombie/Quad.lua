-- zombie/Quad.lua

---@class Quad
---@field vertices table<Vertex>
---@field vertexCount number
---@field new fun(vertices: table<Vertex>): Quad
---@field new fun(vertices: table<Vertex>, u0: number, v0: number, u1: number, v1: number): Quad
---@field render fun()
_G.Quad = {};

class "Quad" {
    ---Constructor of class
    ---@param self Quad
    constructor = function(self, ...)
        local args = {...};

        if #args == 1 then
            self.vertices = args[1];
            self.vertexCount = #args[1];
        elseif #args == 5 then
            local u0 = args[2];
            local v0 = args[3];
            local u1 = args[4];
            local v1 = args[5];
            self.vertices = args[1];
            self.vertexCount = #args[1];

            self.vertices[1] = args[1][1]:remap(u1, v0);
            self.vertices[2] = args[1][2]:remap(u0, v0);
            self.vertices[3] = args[1][3]:remap(u0, v1);
            self.vertices[4] = args[1][4]:remap(u1, v1);
        end
    end;

    ---Render Quad
    ---@param self Quad
    render = function(self)
        glColor3f(1.0, 1.0, 1.0);

        for i = 4, 1, -1 do
            local v = self.vertices[i];

            glTexCoord2f(v.u / 64.0, v.v / 32.0);

            glVertex3f(v.position.x, v.position.y, v.position.z);
        end
    end
}