-- util/Matrix.lua
_G.Matrix4x4 = {}
Matrix4x4.__index = Matrix4x4

-- Создание единичной матрицы (column‑major)
function Matrix4x4.new()
    local self = setmetatable({}, Matrix4x4)
    self:identity()
    return self
end

-- Заполнить единичной матрицей (column‑major)
function Matrix4x4:identity()
    self.data = {
        1, 0, 0, 0,   -- column 0
        0, 1, 0, 0,   -- column 1
        0, 0, 1, 0,   -- column 2
        0, 0, 0, 1    -- column 3
    }
end

-- Умножение текущей матрицы на другую (self = self * other), column‑major
function Matrix4x4:mul(other)
    local m = self.data
    local n = other.data
    local result = {}
    for j = 0, 3 do        -- столбцы other
        for i = 0, 3 do    -- строки self
            local sum = 0
            for k = 0, 3 do
                -- m[i][k] * n[k][j]
                local a = m[k*4 + i + 1]   -- col=k, row=i
                local b = n[j*4 + k + 1]   -- col=j, row=k
                sum = sum + a * b
            end
            result[j*4 + i + 1] = sum      -- col=j, row=i
        end
    end
    self.data = result
end

-- Оператор * (возвращает новую матрицу, не изменяя аргументы)
function Matrix4x4:__mul(other)
    local res = Matrix4x4.new()
    res.data = {unpack(self.data)}
    res:mul(other)
    return res
end

-- Перспективная проекция (column‑major)
function Matrix4x4:perspective(fov, aspect, near, far)
    local f = 1 / math.tan(fov / 2)
    local nf = 1 / (near - far)
    self.data = {
        f / aspect, 0, 0, 0,                      -- column 0
        0,          f, 0, 0,                      -- column 1
        0,          0, (far + near) * nf, -1,     -- column 2
        0,          0, 2 * far * near * nf, 0     -- column 3
    }
end

-- Видовая матрица (lookAt) – column‑major, классический gluLookAt
function Matrix4x4:lookAt(eyeX, eyeY, eyeZ, targetX, targetY, targetZ, upX, upY, upZ)
    -- forward = target - eye
    local fx = targetX - eyeX
    local fy = targetY - eyeY
    local fz = targetZ - eyeZ
    local fLen = math.sqrt(fx*fx + fy*fy + fz*fz)
    fx, fy, fz = fx/fLen, fy/fLen, fz/fLen

    -- side = cross(forward, up)
    local sx = fy * upZ - fz * upY
    local sy = fz * upX - fx * upZ
    local sz = fx * upY - fy * upX
    local sLen = math.sqrt(sx*sx + sy*sy + sz*sz)
    sx, sy, sz = sx/sLen, sy/sLen, sz/sLen

    -- up = cross(side, forward)
    local ux = sy * fz - sz * fy
    local uy = sz * fx - sx * fz
    local uz = sx * fy - sy * fx

    self.data = {
        sx,  sy,  sz,  -(sx*eyeX + sy*eyeY + sz*eyeZ),   -- column 0
        ux,  uy,  uz,  -(ux*eyeX + uy*eyeY + uz*eyeZ),   -- column 1
        -fx, -fy, -fz,  (fx*eyeX + fy*eyeY + fz*eyeZ),   -- column 2
        0,   0,   0,   1                                   -- column 3
    }
end

-- Перенос (translate) – column‑major
function Matrix4x4:translate(x, y, z)
    local m = Matrix4x4.new()
    m.data = {
        1, 0, 0, 0,   -- col 0
        0, 1, 0, 0,   -- col 1
        0, 0, 1, 0,   -- col 2
        x, y, z, 1    -- col 3
    }
    self:mul(m)
end

-- Поворот вокруг оси X (угол в радианах) – column‑major
function Matrix4x4:rotateX(angle)
    local c, s = math.cos(angle), math.sin(angle)
    local m = Matrix4x4.new()
    m.data = {
        1, 0,  0, 0,     -- col 0
        0, c,  s, 0,     -- col 1
        0, -s, c, 0,     -- col 2
        0, 0,  0, 1      -- col 3
    }
    self:mul(m)
end

-- Поворот вокруг оси Y – column‑major
function Matrix4x4:rotateY(angle)
    local c, s = math.cos(angle), math.sin(angle)
    local m = Matrix4x4.new()
    m.data = {
        c, 0, -s, 0,     -- col 0
        0, 1,  0, 0,     -- col 1
        s, 0,  c, 0,     -- col 2
        0, 0,  0, 1      -- col 3
    }
    self:mul(m)
end

-- Поворот вокруг оси Z – column‑major
function Matrix4x4:rotateZ(angle)
    local c, s = math.cos(angle), math.sin(angle)
    local m = Matrix4x4.new()
    m.data = {
        c,  s, 0, 0,     -- col 0
        -s, c, 0, 0,     -- col 1
        0,  0, 1, 0,     -- col 2
        0,  0, 0, 1      -- col 3
    }
    self:mul(m)
end

-- Поворот вокруг произвольной оси (column‑major)
function Matrix4x4:rotateAxis(angle, x, y, z)
    local len = math.sqrt(x*x + y*y + z*z)
    if len == 0 then return end
    x, y, z = x/len, y/len, z/len

    local c = math.cos(angle)
    local s = math.sin(angle)
    local t = 1 - c

    local m = Matrix4x4.new()
    -- Элементы вычисляются по формуле Родригеса, раскладываем по столбцам
    m.data = {
        t*x*x + c,    t*x*y + s*z,  t*x*z - s*y,  0,  -- col 0
        t*x*y - s*z,  t*y*y + c,    t*y*z + s*x,  0,  -- col 1
        t*x*z + s*y,  t*y*z - s*x,  t*z*z + c,    0,  -- col 2
        0,            0,            0,            1   -- col 3
    }
    self:mul(m)
end

-- Применить матрицу через love.graphics (если нужно)
function Matrix4x4:apply()
    love.graphics.setMatrix(self.data)
end