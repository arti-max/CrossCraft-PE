-- util/Ray.lua
_G.Ray = {}

class "Ray" {
    constructor = function(self, x, y, z, dx, dy, dz)
        self.x = x
        self.y = y
        self.z = z
        self.dx = dx
        self.dy = dy
        self.dz = dz
    end;


    fromPlayer = function(player)
        local xRot = -math.rad(player.xRot)
        local yRot = -math.rad(player.yRot)

        local cosX = math.cos(xRot)
        local sinX = math.sin(xRot)
        local cosY = math.cos(yRot)
        local sinY = math.sin(yRot)

        local dx = -sinY * cosX
        local dy = sinX
        local dz = -cosY * cosX

        local startX = player.x
        local startY = player.y
        local startZ = player.z

        return Ray.new(startX, startY, startZ, dx, dy, dz)
    end;

    trace = function(self, level, maxDistance)
        maxDistance = maxDistance or 5.0
        return self:traceBlocks(level, maxDistance)
    end;

    traceBlocks = function(self, level, maxDistance)
        local x, y, z = self.x, self.y, self.z
        local dx, dy, dz = self.dx, self.dy, self.dz

        local length = math.sqrt(dx*dx + dy*dy + dz*dz)
        if length < 0.0001 then return nil end
        local dirX = dx / length
        local dirY = dy / length
        local dirZ = dz / length

        local blockX = math.floor(x)
        local blockY = math.floor(y)
        local blockZ = math.floor(z)

        local stepX = dirX > 0 and 1 or -1
        local stepY = dirY > 0 and 1 or -1
        local stepZ = dirZ > 0 and 1 or -1

        local tDeltaX = (math.abs(dirX) < 0.0001) and math.huge or math.abs(1.0 / dirX)
        local tDeltaY = (math.abs(dirY) < 0.0001) and math.huge or math.abs(1.0 / dirY)
        local tDeltaZ = (math.abs(dirZ) < 0.0001) and math.huge or math.abs(1.0 / dirZ)

        local tMaxX, tMaxY, tMaxZ

        if dirX > 0 then
            tMaxX = (blockX + 1.0 - x) / dirX
        elseif dirX < 0 then
            tMaxX = (blockX - x) / dirX
        else
            tMaxX = math.huge
        end

        if dirY > 0 then
            tMaxY = (blockY + 1.0 - y) / dirY
        elseif dirY < 0 then
            tMaxY = (blockY - y) / dirY
        else
            tMaxY = math.huge
        end

        if dirZ > 0 then
            tMaxZ = (blockZ + 1.0 - z) / dirZ
        elseif dirZ < 0 then
            tMaxZ = (blockZ - z) / dirZ
        else
            tMaxZ = math.huge
        end

        local currentDistance = 0.0
        local lastFace = -1

        while currentDistance < maxDistance do
            if blockX < 0 or blockX >= level.width or
               blockY < 0 or blockY >= level.depth or
               blockZ < 0 or blockZ >= level.height then
                break
            end

            local tileId = level:getTile(blockX, blockY, blockZ)
            if tileId ~= 0 then
                local tile = Tile.tiles[tileId]
                if tile and tile.mayPick then
                    return {
                        type = 0,   -- 0 = блок
                        x = blockX,
                        y = blockY,
                        z = blockZ,
                        face = lastFace
                    }
                end
            end

            if tMaxX < tMaxY then
                if tMaxX < tMaxZ then
                    -- X
                    currentDistance = tMaxX
                    tMaxX = tMaxX + tDeltaX
                    blockX = blockX + stepX
                    lastFace = (stepX > 0) and 4 or 3   -- 4 (X-), 3 (X+)
                else
                    -- Z
                    currentDistance = tMaxZ
                    tMaxZ = tMaxZ + tDeltaZ
                    blockZ = blockZ + stepZ
                    lastFace = (stepZ > 0) and 6 or 5   -- 6 (Z-), 5 (Z+)
                end
            else
                if tMaxY < tMaxZ then
                    -- Y
                    currentDistance = tMaxY
                    tMaxY = tMaxY + tDeltaY
                    blockY = blockY + stepY
                    lastFace = (stepY > 0) and 2 or 1   -- 2 (Y-), 1 (Y+)
                else
                    -- Z
                    currentDistance = tMaxZ
                    tMaxZ = tMaxZ + tDeltaZ
                    blockZ = blockZ + stepZ
                    lastFace = (stepZ > 0) and 6 or 5
                end
            end
        end

        return nil
    end;
}