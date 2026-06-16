-- level/Level.lua

---@class Level
---@field width number
---@field height number
---@field depth number
---@field blocks table<number, number>
---@field lightDepths table<number, number>
---@field listeners table
---@field LEVEL_SAVE_VER number
---@field tileIdx fun(self: Level, x: number, y: number, z: number): number
---@field save fun(self: Level)
---@field load fun(self: Level): boolean
---@field generateMap fun(self: Level)
---@field getTile fun(self: Level, x: number, y: number, z: number): number
---@field setTile fun(self: Level, x: number, y: number, z: number, id: number)
---@field calcLightDepths fun(self: Level, x0: number, z0: number, x1: number, z1: number)
---@field getCubes fun(self: Level, playerBB: AABB): AABB[]
---@field getBrightness fun(self: Level, x: number, y: number, z: number): number
---@field getBlockRegion fun(self: Level, x0: number, y0: number, z0: number, x1: number, y1: number, z1: number): number[]
---@field getLightMap fun(self: Level, x0: number, z0: number, x1: number, z1: number): table
---@field addListener fun(self: Level, listener: LevelRender)
---@field isLit fun(self: Level, x: number, y: number, z: number)
---@field tick fun(self: Level)
---@field new fun(width: number, height: number, depth: number): Level
_G.Level = {};

local function packU16BE(num)
    local high = math.floor(num / 256)
    local low = num % 256
    return string.char(high, low)
end

local function packU8BE(num)
    local n = math.floor(num % 256)
    return string.char(n)
end


local function unpackU8BE(data, pos)
    local n = string.byte(data, pos)
    return n, pos + 1
end

local function unpackU16BE(data, pos)
    local high = string.byte(data, pos)
    local low = string.byte(data, pos + 1)
    return high * 256 + low, pos + 2
end

local function packString(str)
    local len = #str
    return packU16BE(len) .. str
end

local function unpackString(data, pos)
    local len, newPos = unpackU16BE(data, pos)
    local str = string.sub(data, newPos, newPos + len - 1)
    return str, newPos + len
end


class "Level" {
    constructor = function(self, width, height, depth)
        self.width = width; -- size by x
        self.height = height; -- size by z
        self.depth = depth; -- size by y
        self.blocks = {};
        self.lightDepths = {};
        self.listeners = {};
        self.LEVEL_SAVE_VER = 2;
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
            loaded = self:load();
        end)

        if not ok or not loaded then
            if not ok then
                dbg.error("Error load level data: " .. tostring(err));
            end
            dbg.warn("Save data not found. Generate default world... ");

            self:generateMap();
        end

        -- local ok, err = pcall(self.generateMap, self)
        -- if not ok then
        --     dbg.error("Map generation crashed: " .. tostring(err))
        --     for x = 0, self.width-1 do
        --         for z = 0, self.height-1 do
        --             for y = 0, self.depth/2-1 do
        --                 self.blocks[self:tileIdx(x, y, z)] = Tile.rock.id
        --             end
        --         end
        --     end
        -- end
    end;

    tileIdx = function(self, x, y, z)
        return (y * self.height + z) * self.width + x;
    end;

    ---Save level data to file
    ---@param self Level
    save = function(self)
        local path = "save" .. UP.vars["Game::loadLevelID"] .. ".dat";
        if not path then return end

        local header = packString("ccpe");
        header = header .. packU16BE(self.width) .. packU16BE(self.depth) .. packU16BE(self.height); -- uint16 * 3
        header = header .. packU8BE(self.LEVEL_SAVE_VER); -- level save format version


        local totalBlocks = self.width * self.height * self.depth;
        local blockParts = {};
        for i = 0, totalBlocks - 1 do
            blockParts[i+1] = string.char(self.blocks[i] % 256);
        end
        local blockData = table.concat(blockParts);

        -- local blockCount = self.width*self.height*self.depth;
        -- local blockData = love.data.pack(string.rep("B", blockCount), self.blocks);

        local data = header .. blockData;
        UP.fileSaves.write(path, data);
    end;

    ---Load level data from save file if exists
    ---@param self Level
    ---@return boolean loaded
    load = function(self)
        local name = "save" .. UP.vars["Game::loadLevelID"] .. ".dat";
        if not UP.fileSaves.exists(name) then
            return false;
        end
        local data = UP.fileSaves.read(name);
        if not data or #data < 6 then return false end

        local pos = 1;
        local magic;
        magic, pos = unpackString(data, pos);
        if magic ~= "ccpe" then
            dbg.warn("Not CrossCraft PE level save format!");
            return false;
        end

        local w, d, h;
        local ver = 1;
        w, pos = unpackU16BE(data, pos);
        d, pos = unpackU16BE(data, pos);
        h, pos = unpackU16BE(data, pos);
        ver, pos = unpackU8BE(data, pos);

        if ver > self.LEVEL_SAVE_VER then
            dbg.warn("This version of the game does not support this world's save format.")
            return false;
        end

        self.width = w;
        self.depth = d;
        self.height = h;

        local blockCount = w * d * h;
        self.blocks = {};
        for i = 0, blockCount - 1 do
            self.blocks[i] = string.byte(data, pos);
            pos = pos + 1;
        end

        self:calcLightDepths(0, 0, w, h);

        return true;
    end;

    convert = function(self)
        
    end;

    generateMap = function(self)
        local w, h, d = self.width, self.height, self.depth
        local seed = math.random(1, 65535);

        local fbm = _G.CCNoise.fbm;

        local firstHeightMap = {};
        local secondHeightMap = {};
        local cliffMap = {};
        local rockMap = {};

        local scaleHeight1 = 30;
        local scaleHeight2 = 15;
        local scaleCliff = 20;
        local scaleRock = 25;

        for x = 0, w-1 do
            for z = 0, h-1 do
                local idx = x + z * w;
                firstHeightMap[idx] = fbm(x/scaleHeight1, z/scaleHeight1, seed, 4, 2.0, 0.5) * 128;
                secondHeightMap[idx] = fbm(x/scaleHeight2, z/scaleHeight2, seed+10, 4, 3.0, 0.6) * 128;
                cliffMap[idx] = fbm(x/scaleCliff, z/scaleCliff, seed+20, 2, 2.0, 0.4) * 128;
                rockMap[idx] = fbm(x/scaleRock, z/scaleRock, seed+45, 2, 2.0, 0.4) * 128;
            end
        end

        for x = 0, w-1 do
            for y = 0, d-1 do
                for z = 0, h-1 do
                    local colIdx = x + z * w

                    local h1 = firstHeightMap[colIdx];
                    local h2 = secondHeightMap[colIdx];
                    local cliff = cliffMap[colIdx];
                    local rock = rockMap[colIdx];
                    local surface = 0;

                    if cliff < 64 then
                        h2 = h1;
                    end

                    surface = math.floor(math.max(h1, h2) / 12 + self.depth / 4);
                    local mrock = math.floor(rock / 12 + self.depth / 4);

                    if (mrock > surface - 4) then
                        mrock = surface - 4;
                    end

                    local idx = (y * self.height + z) * self.width + x;

                    local id = 0;

                    local surface = math.floor(surface);

                    if (y == surface) then
                        id = Tile.grass.id;
                    end

                    if (y < surface) then
                        id = Tile.dirt.id;
                    end

                    if (y <= mrock) then
                        id = Tile.rock.id;
                    end
                    self.blocks[idx] = id;
                end
            end
        end
        dbg.info("end world generation");
        self:calcLightDepths(0, 0, self.width, self.height);
    end;

    ---Tile ticking
    ---@param self Level
    tick = function(self)
        local w, h, d = self.width, self.height, self.depth;
        local tiles = w * h * d;

        local ticks = math.floor(tiles / 400);

        for _ = 0, ticks-1 do
            local x = math.random(0, w);
            local y = math.random(0, d);
            local z = math.random(0, h);

            local tile = Tile.tiles[self:getTile(x, y, z)];
            if tile ~= nil then
                tile:tick(self, x, y, z);
            end
        end
    end;


    ---get tile from pos
    ---@param self Level
    ---@param x number
    ---@param y number
    ---@param z number
    ---@return number
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
                while (depth > 0 and not (self:getTile(x, depth, z) > 0)) do
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
    ---@return table<AABB> | nil
    getCubes = function (self, playerBB)
        if (playerBB == nil) then dbg("PLAYER ABBB IS NIL!!"); return; end;
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
                    local id = self:getTile(x, y, z);
                    if id > 0 and Tile.tiles[id] ~= nil then
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

    ---add level listeners
    ---@param self Level
    ---@param listener LevelRender
    addListener = function(self, listener)
        table.insert(self.listeners, listener);
    end;

    ---Check pos in light
    ---@param self Level
    ---@param x number
    ---@param y number
    ---@param z number
    isLit = function(self, x, y, z)
        return (x < 0 or y < 0 or z < 0 or x >= self.width or z >= self.height or y >= self.lightDepths[x + z * self.width]);
    end;
}
