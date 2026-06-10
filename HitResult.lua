-- HitResult.lua

_G.HitResult = {};

class "HitResult" {
    constructor = function (self, x, y, z, type, face)
        self.x = x;
        self.y = y;
        self.z = z;
        self.type = type;
        self.face = face;
    end;
}