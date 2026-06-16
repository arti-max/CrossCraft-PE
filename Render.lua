-- Render.lua

---@class Render
---@field MAX_VERTICES number
---@field vertices table
---@field isColor boolean
---@field isTexture boolean
---@field u number
---@field v number
---@field colR number
---@field colG number
---@field colB number
---@field idx number
---@field begin fun(self: Render)
---@field flush fun(self: Render): table
---@field vertex fun(self: Render, x: number, y: number, z: number)
---@field texture fun(self: Render, u: number, v: number)
---@field color fun(self: Render, r: number, g: number, b: number)
---@field vertexUV fun(self: Render, x: number, y: number, z: number, u: number, v: number)
---@field new fun(): Render
_G.Render = {};

class "Render" {
    MAX_VERTICES = 100000;

    ---@param self Render
    constructor = function(self)
        self.vertices = {};
        self.isColor = false;
        self.isTexture = false;
        self.u = 0;
        self.v = 0;
        self.colR = 1.0;
        self.colG = 1.0;
        self.colB = 1.0;
        self.idx = 0;

    end;

    ---@param self Render
    begin = function (self)
        self.vertices = {};
        self.u = 0;
        self.v = 0;
        self.idx = 0;
        self.isTexture = false;
        self.isColor = false;
        glBegin(GL_QUADS);
    end;

    ---@param self Render
    ---@return table vertices
    flush = function (self)

        -- if self.isTexture then
        --     glEnable(GL_TEXTURE_2D);
        -- end
        
        glEnd();
        if (#self.vertices > 0) then
            dbg("Rendered " .. #self.vertices .. " vertices");
        end
        return self.vertices;
    end;

    ---@param self Render
    ---@param x number
    ---@param y number
    ---@param z number
    vertex = function(self, x, y, z)
        self.idx = self.idx+1;
        if self.isTexture then
            -- self.vertices[self.idx] = {x, y, z, self.u, self.v};
            glTexCoord2f(self.u, self.v);
            -- glColor3f(self.u, self.v, 1);
        end
        if self.isColor then
            glColor3f(self.colR, self.colG, self.colB);
        end
        glVertex3f(x, y, z);
        
        -- if self.idx > Render.MAX_VERTICES then
        --     self:flush();
        --     self:begin();
        -- end
    end;

    ---@param self Render
    ---@param u number
    ---@param v number
    texture = function(self, u, v)
        self.isTexture = true;
        self.u = u;
        self.v = v;
    end;

    ---@param self Render
    ---@param r number
    ---@param g number
    ---@param b number
    color = function(self, r, g, b)
        self.isColor = true;
        self.colR = r;
        self.colG = g;
        self.colB = b;
    end;

    ---@param self Render
    ---@param x number
    ---@param y number
    ---@param z number
    ---@param u number
    ---@param v number
    vertexUV = function(self, x, y, z, u, v)
        self:texture(u, v);
        self:vertex(x, y, z);
    end;
}