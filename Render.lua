-- Render.lua

_G.Render = {};

class "Render" {
    MAX_VERTICES = 100000;


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

    begin = function (self)
        self.vertices = {};
        self.u = 0;
        self.v = 0;
        self.idx = 0;
        self.isTexture = false;
        self.isColor = false;
        glBegin(GL_QUADS);
    end;

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

    texture = function(self, u, v)
        self.isTexture = true;
        self.u = u;
        self.v = v;
    end;

    color = function(self, r, g, b)
        self.isColor = true;
        self.colR = r;
        self.colG = g;
        self.colB = b;
    end;

    vertexUV = function(self, x, y, z, u, v)
        self:texture(u, v);
        self:vertex(x, y, z);
    end;
}