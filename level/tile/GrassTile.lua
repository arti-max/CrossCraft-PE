-- level/tile/GrassTile.lua

_G.GrassTile = {};

class "GrassTile" "extends" "Tile" {
    constructor = function (self, tileId)
        self._super.constructor(self, tileId, 1)
    end;

    getTexture = function(self, face)
        if face == 1 then
            return 1;
        elseif face == 2 then
            return 4;
        else
            return 5;
        end
    end;

    tick = function(self, level, x, y, z)
        if (level:isLit(x, y, z)) then
            for _=1, 4 do
                local tx = x + math.random(0, 3) - 1;
                local ty = y + math.random(0, 5) - 3;
                local tz = z + math.random(0, 3) - 1;

                if (level:getTile(tx, ty, tz) == Tile.dirt.id and level:isLit(tx, ty, tz)) then
                    level:setTile(tx, ty, tz, Tile.grass.id);
                end
            end
        else
            level:setTile(x, y, z, Tile.dirt.id);
        end
    end
}