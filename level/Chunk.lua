-- level/Chunk.lua

_G.Chunk = {};

class "Chunk" {
    __staticinit = function (self)
        self.updates = 0;
        self.rebuiltThisFrame = 0;
        self.renderer = Render.new();
    end;

    constructor = function (self, level, x0, y0, z0, x1, y1, z1)
        self.level = level;

        self.aabb = nil;
        self.x0 = x0;
        self.y0 = y0;
        self.z0 = z0;
        self.x1 = x1;
        self.y1 = y1;
        self.z1 = z1;

        self.dirty = true;

        self.lists = glGenLists(2); -- 1 - light, 2 - shadow

        self.aabb = AABB.new(x0, y0, z0, x1, y1, z1);
    end;

    rebuild = function(self, layer)
        if not terrainTex then return end
        
        if (Chunk.rebuiltThisFrame == 4) then
            return;
        end

        Chunk.updates=Chunk.updates+1;
        Chunk.rebuiltThisFrame=Chunk.rebuiltThisFrame+1;

        self.dirty = false;

        local c_glNewList, c_glEndList = glNewList, glEndList
        local c_glEnable, c_glDisable = glEnable, glDisable
        local c_glBindTexture = glBindTexture

        local getTile = self.level.getTile
        local level = self.level
        local renderer = Chunk.renderer
        local depthLimit = level.depth/2-1

        c_glNewList(self.lists + layer, GL_COMPILE);
        c_glEnable(GL_TEXTURE_2D);
        c_glBindTexture(GL_TEXTURE_2D, terrainTex);
        Chunk.renderer:begin();

        local x0, x1 = self.x0, self.x1 - 1
        local y0, y1 = self.y0, self.y1 - 1
        local z0, z1 = self.z0, self.z1 - 1

        for x = x0, x1 do
            for y = y0, y1 do
                for z = z0, z1 do
                    if (level:getTile(x, y, z) == 1) then
                        if (y == depthLimit) then
                            Tile.grass:render(renderer, level, x, y, z, layer);
                        else
                            Tile.rock:render(renderer, level, x, y, z, layer);
                        end
                    end
                end
            end
        end

        Chunk.renderer:flush();
        c_glEndList();
        c_glDisable(GL_TEXTURE_2D);
    end;

    render = function(self, layer)
        if (self.dirty) then
            self:rebuild(0);
            self:rebuild(1);
        end
        glEnable(GL_TEXTURE_2D);
        glCallList(self.lists + layer);
        glDisable(GL_TEXTURE_2D);
    end;


    setDirty = function(self)
        self.dirty = true;
    end;
}