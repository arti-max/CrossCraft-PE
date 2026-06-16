-- level/tile/Tile.lua

---@class Tile
---@field id number
---@field textureId number
---@field mayPick boolean
---@field tiles table
---@field rock Tile
---@field grass Tile
---@field new function create new class object
---@field getUV fun(self: Tile, textureId: number): number, number, number, number
---@field shouldRenderFace fun(self: Tile, level: Level, x: number, y: number, z: number, layer: number): boolean
---@field render fun(self: Tile, renderer: Render, level: Level, x: number, y: number, z: number, layer: number)
---@field renderFace fun(self: Tile, render: Render, x: number, y: number, z: number, face: number)
---@field getTexture fun(self: Tile, face: number): number
---@field tick fun(self: Tile, level: Level, x: number, y: number, z: number)
_G.Tile = {};


class "Tile" {

    ---Constructor of Tile
    ---@param self Tile
    ---@param id number
    ---@param textureId number
    constructor = function(self, id, textureId)
        self.id =  id;
        self.textureId = textureId;
        Tile.tiles[id] = self;
        self.mayPick = true;
    end;

    getUV = function(self, textureId)
        local u0 = textureId % 4 * (1 / 4);
        local v0 = math.floor(textureId / 4) * (1 / 4);
        local u1 = u0 + (1 / 4);
        local v1 = v0 + (1 / 4);

        return u0, v0, u1, v1;
    end;

    ---@param self Tile
    ---@param face number
    ---@return number
    getTexture = function (self, face)
        return self.textureId;
    end;

    ---@param self Tile
    ---@param level Level
    ---@param x number
    ---@param y number
    ---@param z number
    tick = function (self, level, x, y, z)
        -- nothing
    end;

    ---Checks the face to render
    ---@param self Tile
    ---@param level Level
    ---@param x number
    ---@param y number
    ---@param z number
    ---@param layer number
    ---@return boolean
    shouldRenderFace = function(self, level, x, y, z, layer)
        return (level:getTile(x, y, z) == 0);
    end;

    ---render tile
    ---@param self Tile
    ---@param renderer Render
    ---@param level Level
    ---@param x number
    ---@param y number
    ---@param z number
    ---@param layer number
    render = function(self, renderer, level, x, y, z, layer)
        local shadeX = 0.6;
        local shadeY = 1.0;
        local shadeZ = 0.8;

        local brightness = level:getBrightness(x, y, z);

        if self:shouldRenderFace(level, x, y+1, z, layer) then
            brightness = level:getBrightness(x, y+1, z)*shadeY;
            if (layer == 1) ~= (brightness == shadeY) then
                renderer:color(brightness, brightness, brightness);
                self:renderFace(renderer, x, y, z, 1);
            end
        end
        if self:shouldRenderFace(level, x, y-1, z, layer) then
            brightness = level:getBrightness(x, y-1, z)*shadeY;
            if (layer == 1) ~= (brightness == shadeY) then
                renderer:color(brightness, brightness, brightness);
                self:renderFace(renderer, x, y, z, 2);
            end
        end
        if self:shouldRenderFace(level, x+1, y, z, layer) then
            brightness = level:getBrightness(x+1, y, z)*shadeX;
            if (layer == 1) ~= (brightness == shadeX) then
                renderer:color(brightness, brightness, brightness);
                self:renderFace(renderer, x, y, z, 3);
            end
        end
        if self:shouldRenderFace(level, x-1, y, z, layer) then
            brightness = level:getBrightness(x-1, y, z)*shadeX;
            if (layer == 1) ~= (brightness == shadeX) then
                renderer:color(brightness, brightness, brightness);
                self:renderFace(renderer, x, y, z, 4);
            end
        end
        if self:shouldRenderFace(level, x, y, z+1, layer) then
            brightness = level:getBrightness(x, y, z+1)*shadeZ;
            if (layer == 1) ~= (brightness == shadeZ) then
                renderer:color(brightness, brightness, brightness);
                self:renderFace(renderer, x, y, z, 5);
            end
        end
        if self:shouldRenderFace(level, x, y, z-1, layer) then
            brightness = level:getBrightness(x, y, z-1)*shadeZ;
            if (layer == 1) ~= (brightness == shadeZ) then
                renderer:color(brightness, brightness, brightness);
                self:renderFace(renderer, x, y, z, 6);
            end
        end
    end;

    renderFace = function(self, render, x, y, z, face)
        local u0, v0, u1, v1 = self:getUV(self:getTexture(face));

        local x0 = x;
        local y0 = y;
        local z0 = z;
        local x1 = x+1;
        local y1 = y+1;
        local z1 = z+1;

        if face == 1 then -- Y+ 
            render:vertexUV(x1, y1, z1, u1, v1);
            render:vertexUV(x1, y1, z0, u1, v0);
            render:vertexUV(x0, y1, z0, u0, v0);
            render:vertexUV(x0, y1, z1, u0, v1);
        elseif face == 2 then -- Y- 
            render:vertexUV(x0, y0, z1, u0, v1);
            render:vertexUV(x0, y0, z0, u0, v0);
            render:vertexUV(x1, y0, z0, u1, v0);
            render:vertexUV(x1, y0, z1, u1, v1);
        elseif face == 3 then -- X+ 
            render:vertexUV(x1, y0, z1, u0, v1);
            render:vertexUV(x1, y0, z0, u1, v1);
            render:vertexUV(x1, y1, z0, u1, v0);
            render:vertexUV(x1, y1, z1, u0, v0);
        elseif face == 4 then -- X- 
            render:vertexUV(x0, y1, z1, u1, v0);
            render:vertexUV(x0, y1, z0, u0, v0);
            render:vertexUV(x0, y0, z0, u0, v1);
            render:vertexUV(x0, y0, z1, u1, v1);
        elseif face == 5 then -- Z+ 
            render:vertexUV(x0, y1, z1, u0, v0);
            render:vertexUV(x0, y0, z1, u0, v1);
            render:vertexUV(x1, y0, z1, u1, v1);
            render:vertexUV(x1, y1, z1, u1, v0);
        elseif face == 6 then -- Z- 
            render:vertexUV(x0, y1, z0, u1, v0);
            render:vertexUV(x1, y1, z0, u0, v0);
            render:vertexUV(x1, y0, z0, u0, v1);
            render:vertexUV(x0, y0, z0, u1, v1);
        end
    end;
}

---@type table<number, Tile>
Tile.tiles = {};
