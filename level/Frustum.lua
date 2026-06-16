-- level/Frustum.lua

---@class Frustum
---@field normalizePlane fun(self: Frustum, frustum: table, side: number)
---@field calculateFrustum fun(self: Frustum)
---@field pointInFrustum fun(self: Frustum, x: number, y: number, z: number): boolean
---@field sphereInFrustum fun(self: Frustum, x: number, y: number, z: number, radius: number): boolean
---@field cubeInFrustum fun(self: Frustum, minX: number, minY: number, minZ: number, maxX: number, maxY: number, maxZ: number): boolean
---@field cubeInFrustumAABB fun(self: Frustum, aabb: AABB): boolean
_G.Frustum = {
    RIGHT  = 0,
    LEFT   = 1,
    BOTTOM = 2,
    TOP    = 3,
    BACK   = 4,
    FRONT  = 5,

    A = 1, B = 2, C = 3, D = 4
}

local m_Frustum = {}
for i = 0, 5 do
    m_Frustum[i] = {0, 0, 0, 0}
end

local instance = nil

---@return Frustum
function Frustum.getInstance()
    if not instance then
        instance = setmetatable({}, { __index = Frustum })
    end
    return instance
end

---@param self Frustum
---@param frustum table
---@param side number
function Frustum:normalizePlane(frustum, side)
    local plane = frustum[side]
    local a, b, c = plane[Frustum.A], plane[Frustum.B], plane[Frustum.C]
    local magnitude = math.sqrt(a * a + b * b + c * c)
    if magnitude ~= 0 then
        plane[Frustum.A] = a / magnitude
        plane[Frustum.B] = b / magnitude
        plane[Frustum.C] = c / magnitude
        plane[Frustum.D] = plane[Frustum.D] / magnitude
    end
end

---@param self Frustum
function Frustum:calculateFrustum()
    local proj = {}
    local modl = {}
    glGetFloat(GL_PROJECTION_MATRIX, proj)
    glGetFloat(GL_MODELVIEW_MATRIX, modl)

    local clip = {}
    clip[1]  = modl[1]*proj[1] + modl[2]*proj[5] + modl[3]*proj[9]  + modl[4]*proj[13]
    clip[2]  = modl[1]*proj[2] + modl[2]*proj[6] + modl[3]*proj[10] + modl[4]*proj[14]
    clip[3]  = modl[1]*proj[3] + modl[2]*proj[7] + modl[3]*proj[11] + modl[4]*proj[15]
    clip[4]  = modl[1]*proj[4] + modl[2]*proj[8] + modl[3]*proj[12] + modl[4]*proj[16]

    clip[5]  = modl[5]*proj[1] + modl[6]*proj[5] + modl[7]*proj[9]  + modl[8]*proj[13]
    clip[6]  = modl[5]*proj[2] + modl[6]*proj[6] + modl[7]*proj[10] + modl[8]*proj[14]
    clip[7]  = modl[5]*proj[3] + modl[6]*proj[7] + modl[7]*proj[11] + modl[8]*proj[15]
    clip[8]  = modl[5]*proj[4] + modl[6]*proj[8] + modl[7]*proj[12] + modl[8]*proj[16]

    clip[9]  = modl[9]*proj[1] + modl[10]*proj[5] + modl[11]*proj[9]  + modl[12]*proj[13]
    clip[10] = modl[9]*proj[2] + modl[10]*proj[6] + modl[11]*proj[10] + modl[12]*proj[14]
    clip[11] = modl[9]*proj[3] + modl[10]*proj[7] + modl[11]*proj[11] + modl[12]*proj[15]
    clip[12] = modl[9]*proj[4] + modl[10]*proj[8] + modl[11]*proj[12] + modl[12]*proj[16]

    clip[13] = modl[13]*proj[1] + modl[14]*proj[5] + modl[15]*proj[9]  + modl[16]*proj[13]
    clip[14] = modl[13]*proj[2] + modl[14]*proj[6] + modl[15]*proj[10] + modl[16]*proj[14]
    clip[15] = modl[13]*proj[3] + modl[14]*proj[7] + modl[15]*proj[11] + modl[16]*proj[15]
    clip[16] = modl[13]*proj[4] + modl[14]*proj[8] + modl[15]*proj[12] + modl[16]*proj[16]

    -- RIGHT
    m_Frustum[Frustum.RIGHT][Frustum.A] = clip[4]  - clip[1]
    m_Frustum[Frustum.RIGHT][Frustum.B] = clip[8]  - clip[5]
    m_Frustum[Frustum.RIGHT][Frustum.C] = clip[12] - clip[9]
    m_Frustum[Frustum.RIGHT][Frustum.D] = clip[16] - clip[13]
    self:normalizePlane(m_Frustum, Frustum.RIGHT)

    -- LEFT
    m_Frustum[Frustum.LEFT][Frustum.A] = clip[4]  + clip[1]
    m_Frustum[Frustum.LEFT][Frustum.B] = clip[8]  + clip[5]
    m_Frustum[Frustum.LEFT][Frustum.C] = clip[12] + clip[9]
    m_Frustum[Frustum.LEFT][Frustum.D] = clip[16] + clip[13]
    self:normalizePlane(m_Frustum, Frustum.LEFT)

    -- DOWN
    m_Frustum[Frustum.BOTTOM][Frustum.A] = clip[4]  + clip[2]
    m_Frustum[Frustum.BOTTOM][Frustum.B] = clip[8]  + clip[6]
    m_Frustum[Frustum.BOTTOM][Frustum.C] = clip[12] + clip[10]
    m_Frustum[Frustum.BOTTOM][Frustum.D] = clip[16] + clip[14]
    self:normalizePlane(m_Frustum, Frustum.BOTTOM)

    -- UP
    m_Frustum[Frustum.TOP][Frustum.A] = clip[4]  - clip[2]
    m_Frustum[Frustum.TOP][Frustum.B] = clip[8]  - clip[6]
    m_Frustum[Frustum.TOP][Frustum.C] = clip[12] - clip[10]
    m_Frustum[Frustum.TOP][Frustum.D] = clip[16] - clip[14]
    self:normalizePlane(m_Frustum, Frustum.TOP)

    -- FAR
    m_Frustum[Frustum.BACK][Frustum.A] = clip[4]  - clip[3]
    m_Frustum[Frustum.BACK][Frustum.B] = clip[8]  - clip[7]
    m_Frustum[Frustum.BACK][Frustum.C] = clip[12] - clip[11]
    m_Frustum[Frustum.BACK][Frustum.D] = clip[16] - clip[15]
    self:normalizePlane(m_Frustum, Frustum.BACK)

    -- NEAR
    m_Frustum[Frustum.FRONT][Frustum.A] = clip[4]  + clip[3]
    m_Frustum[Frustum.FRONT][Frustum.B] = clip[8]  + clip[7]
    m_Frustum[Frustum.FRONT][Frustum.C] = clip[12] + clip[11]
    m_Frustum[Frustum.FRONT][Frustum.D] = clip[16] + clip[15]
    self:normalizePlane(m_Frustum, Frustum.FRONT)
end


function Frustum:pointInFrustum(x, y, z)
    for i = 0, 5 do
        local p = m_Frustum[i]
        if p[Frustum.A]*x + p[Frustum.B]*y + p[Frustum.C]*z + p[Frustum.D] <= 0 then
            return false
        end
    end
    return true
end

function Frustum:sphereInFrustum(x, y, z, radius)
    for i = 0, 5 do
        local p = m_Frustum[i]
        if p[Frustum.A]*x + p[Frustum.B]*y + p[Frustum.C]*z + p[Frustum.D] <= -radius then
            return false
        end
    end
    return true
end

function Frustum:cubeInFrustum(minX, minY, minZ, maxX, maxY, maxZ)
    for i = 0, 5 do
        local a, b, c, d = m_Frustum[i][1], m_Frustum[i][2], m_Frustum[i][3], m_Frustum[i][4]
        if a * minX + b * minY + c * minZ + d > 0 then goto continue end
        if a * maxX + b * minY + c * minZ + d > 0 then goto continue end
        if a * minX + b * maxY + c * minZ + d > 0 then goto continue end
        if a * maxX + b * maxY + c * minZ + d > 0 then goto continue end
        if a * minX + b * minY + c * maxZ + d > 0 then goto continue end
        if a * maxX + b * minY + c * maxZ + d > 0 then goto continue end
        if a * minX + b * maxY + c * maxZ + d > 0 then goto continue end
        if a * maxX + b * maxY + c * maxZ + d > 0 then goto continue end
        do return false end;
        ::continue::
    end
    return true
end

function Frustum:cubeInFrustumAABB(aabb)
    return self:cubeInFrustum(aabb.min.x, aabb.min.y, aabb.min.z,
                              aabb.max.x, aabb.max.y, aabb.max.z)
end

function Frustum.getFrustum()
    local f = Frustum.getInstance()
    f:calculateFrustum()
    return f
end