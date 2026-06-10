-- level/Tile.lua

_G.Tile = {};

class "Tile" {

    constructor = function(self, id, textureId)
        self.id =  id;
        self.textureId = textureId;
        Tile.tiles[id] = self;
        self.mayPick = true;

        local u0 = textureId % 4 * 0.25;
        local v0 = math.floor(textureId / 4) * 0.25;
        self.u0 = u0;
        self.v0 = v0;
        self.u1 = u0 + 0.25;
        self.v1 = v0 + 0.25;
    end;

    getUV = function(self, textureId)
        local u0 = textureId % 4 * (1 / 4);
        local v0 = math.floor(textureId / 4) * (1 / 4);
        local u1 = u0 + (1 / 4);
        local v1 = v0 + (1 / 4);

        return u0, v0, u1, v1;
    end;

    shouldRenderFace = function(self, level, x, y, z, layer)
        return (level:getTile(x, y, z) == 0);
    end;

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
        local u0, v0, u1, v1 = self.u0, self.v0, self.u1, self.v1;

        local x0 = x;
        local y0 = y;
        local z0 = z;
        local x1 = x+1;
        local y1 = y+1;
        local z1 = z+1;

        if face == 1 then -- Y+ 
            render:vertexUV(x1, y1, z1, u0, v0);
            render:vertexUV(x1, y1, z0, u0, v1);
            render:vertexUV(x0, y1, z0, u1, v1);
            render:vertexUV(x0, y1, z1, u1, v0);
        elseif face == 2 then -- Y- 
            render:vertexUV(x0, y0, z1, u0, v0);
            render:vertexUV(x0, y0, z0, u1, v0);
            render:vertexUV(x1, y0, z0, u1, v1);
            render:vertexUV(x1, y0, z1, u0, v1);
        elseif face == 3 then -- X+ 
            render:vertexUV(x1, y0, z1, u0, v0);
            render:vertexUV(x1, y0, z0, u0, v1);
            render:vertexUV(x1, y1, z0, u1, v1);
            render:vertexUV(x1, y1, z1, u1, v0);
        elseif face == 4 then -- X- 
            render:vertexUV(x0, y1, z1, u0, v0);
            render:vertexUV(x0, y1, z0, u0, v1);
            render:vertexUV(x0, y0, z0, u1, v1);
            render:vertexUV(x0, y0, z1, u1, v0);
        elseif face == 5 then -- Z+ 
            render:vertexUV(x0, y1, z1, u0, v0);
            render:vertexUV(x0, y0, z1, u1, v0);
            render:vertexUV(x1, y0, z1, u1, v1);
            render:vertexUV(x1, y1, z1, u0, v1);
        elseif face == 6 then -- Z- 
            render:vertexUV(x0, y1, z0, u0, v0);
            render:vertexUV(x1, y1, z0, u0, v1);
            render:vertexUV(x1, y0, z0, u1, v1);
            render:vertexUV(x0, y0, z0, u1, v0);
        end
    end;
}


Tile.tiles = {}
Tile.rock = Tile.new(1, 0)
Tile.grass = Tile.new(2, 1)