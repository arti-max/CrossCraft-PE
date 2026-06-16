-- zombie/Model.lua

---@class Model
---@field head ModelPart
---@field body ModelPart
---@field arm0 ModelPart
---@field arm1 ModelPart
---@field leg0 ModelPart
---@field leg1 ModelPart
---@field new fun()
---@field render fun(self: Model, partialTicks: number)
_G.Model = {};

class "Model" {
    ---@param self Model
    constructor = function(self)
        self.head = ModelPart.new(0, 0):addBox(-4, -8, -4, 8, 8, 8);
        self.body = ModelPart.new(16, 16):addBox(-4, 0, -2, 8, 12, 4);
        self.arm0 = ModelPart.new(40, 16):addBox(-3, -2, -2, 4, 12, 4);
        self.arm0:setPos(-5, 2, 0);
        self.arm1 = ModelPart.new(40, 16):addBox(-1, -2, -2, 4, 12, 4);
        self.arm1:setPos(5, 2, 0);
        self.leg0 = ModelPart.new(0, 16):addBox(-2, 0, -2, 4, 12, 4);
        self.leg0:setPos(-2, 12, 0);
        self.leg1 = ModelPart.new(0, 16):addBox(-2, 0, -2, 4, 12, 4);
        self.leg1:setPos(2, 12, 0);
    end;

    ---@param self Model
    ---@param partialTicks number
    render = function(self, partialTicks)
        self.head.yRot = math.sin(partialTicks * 0.83);
        self.head.xRot = math.sin(partialTicks) * 0.8;
        self.arm0.xRot = math.sin(partialTicks * 0.6662 + math.pi) * 2;
        self.arm0.zRot = math.sin(partialTicks * 0.2312) + 1;
        self.arm1.xRot = math.sin(partialTicks * 0.6662) * 2;
        self.arm1.zRot = math.sin(partialTicks * 0.2812) - 1;
        self.leg0.xRot = math.sin(partialTicks * 0.6662) * 1.4;
        self.leg1.xRot = math.sin(partialTicks * 0.6662 + math.pi) * 1.4;

        self.head:render();
        self.body:render();
        self.arm0:render();
        self.arm1:render();
        self.leg0:render();
        self.leg1:render();
    end
}