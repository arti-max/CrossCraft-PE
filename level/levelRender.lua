-- level/levelRender.lua

_G.LevelRender = {};

class "LevelRender" {
    constructor = function (self, level)
        self.level = level;
        level:addListener(self);
        self.CHUNK_SIZE = 16;
        self.chunks = {};
        self.chunkAmountX = level.width / self.CHUNK_SIZE;
        self.chunkAmountY = level.depth / self.CHUNK_SIZE;
        self.chunkAmountZ = level.height / self.CHUNK_SIZE;
        self.renderer = Render.new();

        local total = self.chunkAmountX*self.chunkAmountY*self.chunkAmountZ;
        for i = 0, total - 1 do
            self.chunks[i] = 0;
        end

        for x = 0, self.chunkAmountX - 1 do
            for y = 0, self.chunkAmountY - 1 do
                for z = 0, self.chunkAmountZ - 1 do
                    
                    local cx0 = x * self.CHUNK_SIZE;
                    local cy0 = y * self.CHUNK_SIZE;
                    local cz0 = z * self.CHUNK_SIZE;

                    local cx1 = (x + 1) * self.CHUNK_SIZE;
                    local cy1 = (y + 1) * self.CHUNK_SIZE;
                    local cz1 = (z + 1) * self.CHUNK_SIZE;

                    cx1 = math.min(level.width, cx1);
                    cy1 = math.min(level.depth, cy1);
                    cz1 = math.min(level.height, cz1);

                    local chunk = Chunk.new(level, cx0, cy0, cz0, cx1, cy1, cz1);
                    local idx = x * (self.chunkAmountY * self.chunkAmountZ) + y * self.chunkAmountZ + z + 1
                    self.chunks[idx] = chunk;

                end
            end
        end

        self.updateQueue = {}
    end;

    render = function(self, layer)
        glEnable(GL_TEXTURE_2D);
        local frustum = Frustum.getFrustum();

        Chunk.rebuiltThisFrame = 0;

        for _, chunk in ipairs(self.chunks) do
            if (frustum:cubeInFrustumAABB(chunk.aabb)) then
                chunk:render(layer);
            end
        end
    end;

    setDirty = function(self, x0, y0, z0, x1, y1, z1)
        x0 = math.floor(x0 / self.CHUNK_SIZE);
        x1 = math.floor(x1 / self.CHUNK_SIZE);
        y0 = math.floor(y0 / self.CHUNK_SIZE);
        y1 = math.floor(y1 / self.CHUNK_SIZE);
        z0 = math.floor(z0 / self.CHUNK_SIZE);
        z1 = math.floor(z1 / self.CHUNK_SIZE);

        x0 = math.max(x0, 0);
        y0 = math.max(y0, 0);
        z0 = math.max(z0, 0);

        x1 = math.min(x1, self.chunkAmountX - 1);
        y1 = math.min(y1, self.chunkAmountY - 1);
        z1 = math.min(z1, self.chunkAmountZ - 1);

        for x = x0, x1 do
            for y = y0, y1 do
                for z = z0, z1 do
                    local chunk = self.chunks[x * (self.chunkAmountY * self.chunkAmountZ) + y * self.chunkAmountZ + z + 1];

                    chunk:setDirty();
                end
            end
        end

    end;

    renderHit = function(self, hit)
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glColor4f(1.0, 1.0, 1.0, math.sin(love.timer.getTime() * 1000 / 100) * 0.2 + 0.4);

        self.renderer:begin();
        Tile.rock:renderFace(self.renderer, hit.x, hit.y, hit.z, hit.face);
        self.renderer:flush();

        glDisable(GL_BLEND);
    end;


    tileChanged = function(self, x, y, z)
        self:setDirty(x - 1, y - 1, z - 1, x + 1, y + 1, z + 1);
    end;

    lightChanged = function(self, x, z, x0, y1)
        self:setDirty(x - 1, x0 - 1, z - 1, x + 1, y1 + 1, z + 1);
    end;
}