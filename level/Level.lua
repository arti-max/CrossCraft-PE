-- level/Level.lua

_G.Level = {};

local function packU16BE(num)
    local high = math.floor(num / 256)
    local low = num % 256
    return string.char(high, low)
end

local function unpackU16BE(data, pos)
    local high = string.byte(data, pos)
    local low = string.byte(data, pos + 1)
    return high * 256 + low, pos + 2
end


class "Level" {
    constructor = function(self, width, height, depth)
        self.width = width; -- size by x
        self.height = height; -- size by z
        self.depth = depth; -- size by y
        self.blocks = {};
        self.lightDepths = {};
        self.listeners = {};
        local total = width*height*depth;
        for i = 0, total - 1 do
            self.blocks[i] = 0;
        end
        total = width*height;
        for i = 0, total-1 do
            self.lightDepths[i] = 0;
        end

        local loaded = false
        local ok, err = pcall(function()
            loaded = self:load()
        end)

        if not ok or not loaded then
            if not ok then
                dbg.error("Error load level data: " .. tostring(err));
            end
            dbg.warn("Save data not found. Generate default world...");

            self:generateMap();
        end
    end,

    tileIdx = function(self, x, y, z)
        return (y * self.height + z) * self.width + x;
    end,

    ---Save level data to file
    ---@param self Level
    save = function(self)
        local path = UP.fileSaves.resolve("level.dat");
        if not path then return end

        local header = packU16BE(self.width) .. packU16BE(self.depth) .. packU16BE(self.height); -- uint16 * 3

        local blockParts = {}
        for i = 1, #self.blocks do
            blockParts[i] = string.char(self.blocks[i] % 256)
        end
        local blockData = table.concat(blockParts)

        -- local blockCount = self.width*self.height*self.depth;
        -- local blockData = love.data.pack(string.rep("B", blockCount), self.blocks);

        local data = header .. blockData
        UP.fileSaves.write("level.dat", data);
    end;

    ---Load level data from save file if exists
    ---@param self Level
    ---@return boolean loaded
    load = function(self)
        local path = UP.fileSaves.resolve("level.dat");
        if not UP.fileSaves.exists("level.dat") then 
            return false;
        end

        local data = UP.fileSaves.read("level.dat");
        if not data or #data < 6 then return false end

        local pos = 1
        local w, d, h
        w, pos = unpackU16BE(data, pos)
        d, pos = unpackU16BE(data, pos)
        h, pos = unpackU16BE(data, pos)

        self.width = w;
        self.depth = d;
        self.height = h;

        local blockCount = w * d * h
        self.blocks = {}
        for i = 1, blockCount do
            self.blocks[i] = string.byte(data, pos)
            pos = pos + 1
        end

        self:calcLightDepths(0, 0, w, h);

        return true;
    end;

    generateMap = function(self)
        for x=0, self.width-1 do
            for z=0, self.height-1 do
                for y=0, self.depth/2-1 do
                    self.blocks[self:tileIdx(x, y, z)] = 1;
                end
            end
        end

        -- dbg("Generate caves...");
        -- for i = 1, 10000 do
        --     local caveSize = math.random(7)
        --     local caveX = math.random(self.width) - 1
        --     local caveY = math.random(self.depth) - 1
        --     local caveZ = math.random(self.height) - 1

        --     for radius = 0, caveSize - 1 do
        --         for sphere = 1, 1000 do
        --             local offsetX = math.floor(math.random() * radius * 2 - radius)
        --             local offsetY = math.floor(math.random() * radius * 2 - radius)
        --             local offsetZ = math.floor(math.random() * radius * 2 - radius)

        --             local dist = offsetX * offsetX + offsetY * offsetY + offsetZ * offsetZ
        --             if dist <= radius * radius then
        --                 local tileX = caveX + offsetX
        --                 local tileY = caveY + offsetY
        --                 local tileZ = caveZ + offsetZ

        --                 if tileX > 0 and tileY > 0 and tileZ > 0
        --                     and tileX < self.width - 1
        --                     and tileY < self.depth
        --                     and tileZ < self.height - 1 then
        --                     self.blocks[self:tileIdx(tileX, tileY, tileZ)] = 0
        --                 end
        --             end
        --         end
        --     end
        -- end

        self:calcLightDepths(0, 0, self.width, self.height);
        -- dbg("Caves generated!");
    end;


    ---get tile from pos
    ---@param self Level
    ---@param x number
    ---@param y number
    ---@param z number
    ---@return tileId
    getTile = function(self, x, y, z)
        if x >= 0 and y >= 0 and z >= 0 and x < self.width and y < self.depth and z < self.height then
            return self.blocks[(y * self.height + z) * self.width + x]
        end
        return 0;
    end;

    ---Set tile into level
    ---@param self Level
    ---@param x number
    ---@param y number
    ---@param z number
    ---@param id number
    setTile = function(self, x, y, z, id)
        if x >= 0 and y >= 0 and z >= 0 and x < self.width and y < self.depth and z < self.height then
            self.blocks[(y * self.height + z) * self.width + x] = id;

            self:calcLightDepths(x, z, 1, 1);

            for _, listener in ipairs(self.listeners) do
                listener:tileChanged(x, y, z);
            end

        end
    end;

    ---Calculate block lights
    ---@param self Level
    ---@param x0 number
    ---@param z0 number
    ---@param x1 number
    ---@param z1 number
    calcLightDepths = function(self, x0, z0, x1, z1)
        for x = x0, (x0+x1)-1 do
            for z = z0, (z0+z1)-1 do
                local deptho = self.lightDepths[x + z * self.width];

                local depth = self.depth - 1;
                while (depth > 0 and not (self:getTile(x, depth, z) == 1)) do
                    depth=depth-1;
                end

                self.lightDepths[x + z * self.width] = depth;

                if (deptho ~= depth) then
                    local y0 = math.min(deptho, depth)
                    local y1 = math.max(deptho, depth);

                    for _, listener in ipairs(self.listeners) do
                        listener:lightChanged(x, z, y0, y1);
                    end
                end

            end
        end
    end;

    ---get tiles AABB around playerbb 
    ---@param self Level
    ---@param playerBB AABB
    ---@return list[AABB]
    getCubes = function (self, playerBB)
        if (playerBB == nil) then dbg("PLAYER ABBB IS NIL!!") end;
        local list = {};

        local x0 = math.max(0, math.floor(playerBB.min.x) - 1);
        local x1 = math.min(self.width, math.floor(playerBB.max.x) + 1);
        local y0 = math.max(0, math.floor(playerBB.min.y) - 1);
        local y1 = math.min(self.depth, math.floor(playerBB.max.y) + 1);
        local z0 = math.max(0, math.floor(playerBB.min.z) - 1);
        local z1 = math.min(self.height, math.floor(playerBB.max.z) + 1);

        for x = x0, x1 do
            for y = y0, y1 do
                for z = z0, z1 do
                    if self:getTile(x, y, z) == 1 then
                        table.insert(list, AABB.new(x, y, z, x+1, y+1, z+1));
                    end
                end
            end
        end

        return list;
    end;

    ---Get brightness of tile
    ---@param self Level
    ---@param x number Tile x
    ---@param y number Tile y
    ---@param z number Tile z
    ---@return number color 
    getBrightness = function(self, x, y, z) 
        local dark = 0.8;
        local light = 1.0;

        if (x < 0 or y < 0 or z < 0 or x >= self.width or y >= self.depth or z >= self.height) then
            return light;
        end

        if (y < self.lightDepths[x + z * self.width]) then
            return dark;
        end

        return light;
    end;

    getBlockRegion = function(self, x0, y0, z0, x1, y1, z1)
        local region = {}
        local idx = 1
        local w, h, d = self.width, self.height, self.depth
        local blocks = self.blocks
        for y = y0, y1-1 do
            for z = z0, z1-1 do
                for x = x0, x1-1 do
                    if x >= 0 and y >= 0 and z >= 0 and x < w and y < d and z < h then
                        region[idx] = blocks[(y * h + z) * w + x]
                    else
                        region[idx] = 0
                    end
                    idx = idx + 1
                end
            end
        end
        return region
    end;

    getLightMap = function(self, x0, z0, x1, z1)
        local map = {}
        local lightDepths = self.lightDepths
        local w = self.width
        for x = x0, x1-1 do
            for z = z0, z1-1 do
                if x >= 0 and z >= 0 and x < self.width and z < self.height then
                    map[x] = map[x] or {}
                    map[x][z] = lightDepths[x + z * w]
                else
                    map[x] = map[x] or {}
                    map[x][z] = -1
                end
            end
        end
        return map
    end;

    ---add level listeners
    ---@param self Level
    ---@param listener LevelRener
    addListener = function(self, listener)
        table.insert(self.listeners, listener);
    end;


}
