-- zombie/ModelPart.lua

---@class ModelPart
---@field tx number
---@field ty number
---@field x number
---@field y number
---@field z number
---@field quads table<Quad>
---@field xRot number
---@field yRot number
---@field zRot number
---@field list number
---@field compiled boolean
---@field new fun(tx: number, ty: number): ModelPart
---@field setTextureOffset fun(self: ModelPart, tx: number, ty: number)
---@field addBox fun(self: ModelPart, offsetX: number, offsetY: number, offsetZ: number, width: number, height: number, depth: number): ModelPart
---@field setPos fun(self: ModelPart, x: number, y: number, z: number)
---@field render fun(self: ModelPart)
_G.ModelPart = {};

class "ModelPart" {

    ---Constructor of class
    ---@param self ModelPart
    ---@param tx number
    ---@param ty number
    constructor = function(self, tx, ty)
        self.tx = tx;
        self.ty = ty;

        self.x = 0;
        self.y = 0;
        self.z = 0;

        self.quads = {};

        self.xRot = 0;
        self.yRot = 0;
        self.zRot = 0;

        self.list = glGenLists(1);
        self.compiled = false;
    end;

    ---Set uv offset
    ---@param self ModelPart
    ---@param tx number
    ---@param ty number
    setTextureOffset = function(self, tx, ty)
        self.tx = tx;
        self.ty = ty;
    end;

    ---Set part position
    ---@param self ModelPart
    ---@param x number
    ---@param y number
    ---@param z number
    setPos = function(self, x, y, z)
        self.x = x;
        self.y = y;
        self.z = z;
    end;


    ---Render model part
    ---@param self ModelPart
    ---@param offsetX number
    ---@param offsetY number
    ---@param offsetZ number
    ---@param width number
    ---@param height number
    ---@param depth number
    ---@return ModelPart
    addBox = function(self, offsetX, offsetY, offsetZ, width, height, depth)
        local x = offsetX + width;
        local y = offsetY + height;
        local z = offsetZ + depth;

        local vBottom1 = Vertex.new(offsetX, offsetY, offsetZ, 0.0, 0.0);
        local vBottom2 = Vertex.new(x,       offsetY, offsetZ, 0.0, 8.0);
        local vBottom3 = Vertex.new(offsetX, offsetY, z,       0.0, 0.0);
        local vBottom4 = Vertex.new(x,       offsetY, z,       0.0, 8.0);

        local vTop1 = Vertex.new(x,       y, z,       8.0, 8.0);
        local vTop2 = Vertex.new(offsetX, y, z,       8.0, 0.0);
        local vTop3 = Vertex.new(x,       y, offsetZ, 8.0, 8.0);
        local vTop4 = Vertex.new(offsetX, y, offsetZ, 8.0, 0.0);

        local tx = self.tx;
        local ty = self.ty;

        self.quads = {
            -- 0
            Quad.new({vBottom4, vBottom2, vTop3, vTop1},
                tx + depth + width,          ty + depth,
                tx + depth + width + depth,  ty + depth + height),
            -- 1
            Quad.new({vBottom1, vBottom3, vTop2, vTop4},
                tx,             ty + depth,
                tx + depth,     ty + depth + height),
            -- 2
            Quad.new({vBottom4, vBottom3, vBottom1, vBottom2},
                tx + depth,             ty,
                tx + depth + width,     ty + depth),
            -- 3
            Quad.new({vTop3, vTop4, vTop2, vTop1},
                tx + depth + width,         ty,
                tx + depth + width + width, ty + depth),
            -- 4
            Quad.new({vBottom2, vBottom1, vTop4, vTop3},
                tx + depth,             ty + depth,
                tx + depth + width,     ty + depth + height),
            -- 5
            Quad.new({vBottom3, vBottom4, vTop1, vTop2},
                tx + depth + width + depth,         ty + depth,
                tx + depth + width + depth + width, ty + depth + height)
        };

        return self;
    end;

    ---@param self ModelPart
    render = function(self)
        glPushMatrix();
        glTranslatef(self.x, self.y, self.z);
        glRotatef(math.deg(self.zRot), 0, 0, 1);
        glRotatef(math.deg(self.yRot), 0, 1, 0);
        glRotatef(math.deg(self.xRot), 1, 0, 0);
        if self.compiled then
            glCallList(self.list);
        else
            glNewList(self.list, GL_COMPILE);

            glBegin(GL_QUADS);

            for _, quad in ipairs(self.quads) do
                quad:render();
            end

            glEnd();
            glEndList();

            glCallList(self.list);
            self.compiled = true;
        end

        glPopMatrix();
    end
}