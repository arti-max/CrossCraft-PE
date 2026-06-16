-- render/GL.lua 

_G.GL = {}

-- ==================== CONSTS ====================
GL_PROJECTION = 1
GL_MODELVIEW  = 2
GL_TEXTURE = 3

GL_PROJECTION_MATRIX = 0x0BA6
GL_MODELVIEW_MATRIX  = 0x0BA7

GL_COLOR_BUFFER_BIT = 1
GL_DEPTH_BUFFER_BIT = 2

GL_POINTS    = 0x0000
GL_LINES     = 0x0001
GL_TRIANGLES = 0x0004
GL_QUADS     = 0x0007

GL_CULL_FACE  = 0x0B44
GL_DEPTH_TEST = 0x0B71
GL_BLEND      = 0x0BE2
GL_ALPHA_TEST = 0x0BC0
GL_FOG        = 0x0B60
GL_TEXTURE_2D = 0x0DE1
GL_SMOOTH     = 0x1D01

GL_SRC_ALPHA           = 0x0302
GL_ONE_MINUS_SRC_ALPHA = 0x0303

GL_NEVER    = 0x0200
GL_LESS     = 0x0201
GL_LEQUAL   = 0x0203
GL_GREATER  = 0x0204
GL_NOTEQUAL = 0x0205
GL_GEQUAL   = 0x0206
GL_ALWAYS   = 0x0207

GL_FOG_MODE = 0x0B65
GL_LINEAR   = 0x2601
GL_EXP      = 0x0800
GL_EXP2     = 0x0801

GL_TEXTURE_MIN_FILTER = 0x2801
GL_TEXTURE_MAG_FILTER = 0x2800
GL_NEAREST = 0x2600
GL_LINEAR  = 0x2601

GL_COMPILE = 0x1300
GL_RGBA    = 0x1908
GL_UNSIGNED_BYTE = 0x1401

GL_FRONT          = 0x0404
GL_BACK           = 0x0405
GL_FRONT_AND_BACK = 0x0408
GL_FOG_START      = 0x0B62
GL_FOG_END        = 0x0B63
GL_FOG_COLOR      = 0x0B66
GL_FOG_DENSITY    = 0x0B64


local matrixMode = GL_MODELVIEW
local projMatrix = Matrix4x4.new()
local modelViewMatrix = Matrix4x4.new()
local currentMatrix = modelViewMatrix
local matrixStack = {}

local enabled = {}
local clearColor = {0, 0, 0, 1}
local currentPrimitive = nil
local currentVertices = {}   -- {x,y,z, r,g,b,a, u,v}
local currentColor = {1,1,1,1}
local currentTexCoord = {0,0}
local currentTexture = nil

local displayLists = {}
local nextListID = 1
local listMode = nil
local recordingList = false
local currentList = nil

local cullFaceMode = 1
local depthFunc = nil          -- GL_LEQUAL etc
local alphaFunc = nil          -- GL_ALWAYS etcc
local alphaRef = 0.0
local blendSrcFactor = nil
local blendDstFactor = nil
local fogMode = nil
local fogStart = 0.0
local fogEnd = 1.0
local fogColor = {1,1,1,1}
local textureMinFilter = GL_NEAREST
local textureMagFilter = GL_NEAREST
local clearDepthValue = 1.0
local depthMode = GL_LEQUAL;
local texturingEnabled = false
local fogDensity = 0.001
local depthMask = true

local depthFuncToString = {
    [GL_LEQUAL] = "lequal",
    [GL_LESS] = "less",
    [GL_GREATER] = "greater",
    [GL_GEQUAL] = "gequal",
    [GL_NOTEQUAL] = "notequal",
    [GL_ALWAYS] = "always",
    [GL_NEVER] = "never",
}

local shaderCode = [[
    #pragma language glsl3

    #ifdef GL_ES
    precision highp int;
    #endif

    uniform LOVE_HIGHP_OR_MEDIUMP mat4 uMVP;
    uniform LOVE_HIGHP_OR_MEDIUMP mat4 uMV;
    
    uniform int uCullEnabled;
    uniform int uCullFace;
    uniform int uTexturingEnabled;
    uniform int uFogEnabled;
    uniform int uFogMode;
    
    uniform LOVE_HIGHP_OR_MEDIUMP vec3 uFogColor;
    uniform LOVE_HIGHP_OR_MEDIUMP float uFogStart;
    uniform LOVE_HIGHP_OR_MEDIUMP float uFogEnd;
    uniform LOVE_HIGHP_OR_MEDIUMP float uFogDensity;

    varying LOVE_HIGHP_OR_MEDIUMP vec2 vTexCoord;
    varying LOVE_HIGHP_OR_MEDIUMP vec4 vColor;
    
    varying LOVE_HIGHP_OR_MEDIUMP float vFogFactor;

    #ifdef VERTEX
    vec4 position(mat4 mvp, vec4 vertex) {
        vTexCoord = VertexTexCoord.xy;
        vColor = VertexColor;
        
        vec4 eyePos = uMV * vec4(vertex.xyz, 1.0);
        LOVE_HIGHP_OR_MEDIUMP float dist = abs(eyePos.z);
        
        if (uFogEnabled == 1) {
            if (uFogMode == 1) {
                vFogFactor = (uFogEnd - dist) / (uFogEnd - uFogStart);
            } else if (uFogMode == 2) {
                vFogFactor = exp(-uFogDensity * dist);
            } else if (uFogMode == 3) {
                vFogFactor = exp(-pow(uFogDensity * dist, 2.0));
            } else {
                vFogFactor = 1.0;
            }
            vFogFactor = clamp(vFogFactor, 0.0, 1.0);
        } else {
            vFogFactor = 1.0;
        }
        
        return uMVP * vec4(vertex.xyz, 1.0);
    }
    #endif

    #ifdef PIXEL
    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 screencoord) {

        if (uCullEnabled == 1) {
            if (uCullFace == 1 && !gl_FrontFacing) discard;
            if (uCullFace == 2 && gl_FrontFacing) discard;
        }

        vec4 finalColor = vColor;
        
        if (uTexturingEnabled == 1) {
            finalColor *= Texel(tex, vTexCoord);
        }

        if (uFogEnabled == 1) {
            finalColor.rgb = mix(uFogColor, finalColor.rgb, vFogFactor);
        }

        return finalColor;
    }
    #endif
]]

local glShader = nil
local ok, result = pcall(love.graphics.newShader, shaderCode)
if ok then
    glShader = result
else
    dbg.error("Shader compilation failed: " .. tostring(result))
    glShader = nil
end


-- ==================== transform ====================
if not Matrix4x4.transform then
    function Matrix4x4:transform(x, y, z)
        local m = self.data
        local px = m[1]*x + m[5]*y + m[9]*z  + m[13]
        local py = m[2]*x + m[6]*y + m[10]*z + m[14]
        local pz = m[3]*x + m[7]*y + m[11]*z + m[15]
        local w  = m[4]*x + m[8]*y + m[12]*z + m[16]

        if w ~= 0 and w ~= 1 then
            px = px / w
            py = py / w
            pz = pz / w
        end

        local sx = (px + 1) * 0.5 * love.graphics.getWidth()
        local sy = (-py + 1) * 0.5 * love.graphics.getHeight()
        return sx, sy, pz
    end
end

if not Matrix4x4.ortho then
    function Matrix4x4:ortho(left, right, bottom, top, znear, zfar)
        local m = self.data
        local rml = right - left
        local tmb = top - bottom
        local fmn = zfar - znear
        
        for i = 1, 16 do m[i] = 0 end
        
        m[1] = 2.0 / rml
        m[6] = 2.0 / tmb
        m[11] = -2.0 / fmn
        m[13] = -(right + left) / rml
        m[14] = -(top + bottom) / tmb
        m[15] = -(zfar + znear) / fmn
        m[16] = 1.0
    end
end

-- ==================== STATE CONTROL ====================
function glEnable(mode)
    enabled[mode] = true
    
    if mode == GL_DEPTH_TEST then
        if depthFunc then glDepthFunc(depthFunc) else love.graphics.setDepthMode("lequal", true) end
    elseif mode == GL_BLEND then
        love.graphics.setBlendMode("alpha")
    elseif mode == GL_TEXTURE_2D then
        texturingEnabled = true
    end
end

function glDisable(mode)
    enabled[mode] = false
    
    if mode == GL_DEPTH_TEST then
        love.graphics.setDepthMode("always", false)
    elseif mode == GL_BLEND then
        love.graphics.setBlendMode("replace")
    elseif mode == GL_TEXTURE_2D then
        texturingEnabled = false
    end
end

function glClearColor(r, g, b, a)
    clearColor = {r, g, b, a or 1}
end

function glClearDepth(depth)
    clearDepthValue = math.max(0.0, math.min(1.0, depth))
end

function glGetFloat(pname, out)
    if pname == GL_PROJECTION_MATRIX then
        for i = 1, 16 do
            out[i] = projMatrix.data[i]
        end
    elseif pname == GL_MODELVIEW_MATRIX then
        for i = 1, 16 do
            out[i] = modelViewMatrix.data[i]
        end
    end
end

function glClear(mask)
    local wantColor = (bit.band(mask, GL_COLOR_BUFFER_BIT) ~= 0)
    local wantDepth = (bit.band(mask, GL_DEPTH_BUFFER_BIT) ~= 0)

    local r, g, b, a, depth = nil, nil, nil, nil, nil
    if wantColor then
        r, g, b, a = unpack(clearColor)
    end
    if wantDepth then
        depth = clearDepthValue
    end
    
    local ok = pcall(love.graphics.clear, r, g, b, a, nil, depth)
    if not ok then
        pcall(love.graphics.clear,
            wantColor and r or 0,
            wantColor and g or 0,
            wantColor and b or 0,
            wantColor and a or 0,
            nil,
            wantDepth and depth or nil
        )
    end
end

function glOrtho(left, right, bottom, top, nearVal, farVal)
    currentMatrix:ortho(left, right, bottom, top, nearVal, farVal)
end

function glCullFace(mode)
    if mode == GL_BACK then
        cullFaceMode = 1
    elseif mode == GL_FRONT then
        cullFaceMode = 2
    end
end

function glDepthFunc(func)
    depthFunc = func
    if enabled[GL_DEPTH_TEST] then
        local mode = depthFuncToString[func] or "lequal"
        love.graphics.setDepthMode(mode, depthMask)
    end
end

function glDepthMask(flag)
    depthMask = flag
    if flag then
        love.graphics.setDepthMode(depthFunc and depthFuncToString[depthFunc] or "lequal", true)
    else
        love.graphics.setDepthMode(depthFunc and depthFuncToString[depthFunc] or "lequal", false)
    end
end

function glAlphaFunc(func, ref)
    alphaFunc = func
    alphaRef = ref or 0.0
end

function glBlendFunc(sfactor, dfactor)
    blendSrcFactor = sfactor
    blendDstFactor = dfactor
    if enabled[GL_BLEND] then
        love.graphics.setBlendMode("alpha")  -- GL_SRC_ALPHA/GL_ONE_MINUS_SRC_ALPHA
    end
end

-- ==================== FOG ========================

function glFogi(pname, param)
    if pname == GL_FOG_MODE then
        if param == GL_LINEAR then
            fogMode = 1
        elseif param == GL_EXP then
            fogMode = 2
        elseif param == GL_EXP2 then
            fogMode = 3
        else
            fogMode = 1
        end
    end
end

function glFogf(pname, param)
    if pname == GL_FOG_START or pname == 0x0B62 then
        fogStart = param
    elseif pname == GL_FOG_END or pname == 0x0B63 then
        fogEnd = param
    elseif pname == GL_FOG_DENSITY or pname == 0x0B64 then
        fogDensity = param
    end
end

function glFogfv(pname, params)
    if pname == GL_FOG_COLOR or pname == 0x0B66 then
        fogColor = {params[1], params[2], params[3], params[4]}
    end
end

-- ==================== TEXTURE ====================

function glTexParameteri(target, pname, param)
    if target == GL_TEXTURE_2D then
        if pname == GL_TEXTURE_MIN_FILTER then
            textureMinFilter = param
            if currentTexture then
                if param == GL_NEAREST then
                    currentTexture:setFilter("nearest", "nearest")
                elseif param == GL_LINEAR then
                    currentTexture:setFilter("linear", "linear")
                end
            end
        elseif pname == GL_TEXTURE_MAG_FILTER then
            textureMagFilter = param
            if currentTexture then
                if param == GL_NEAREST then
                    currentTexture:setFilter("nearest", "nearest")
                elseif param == GL_LINEAR then
                    currentTexture:setFilter("linear", "linear")
                end
            end
        end
    end
end

-- ==================== МАТРИЦЫ ====================
function glMatrixMode(mode)
    matrixMode = mode
    if mode == GL_PROJECTION then
        currentMatrix = projMatrix
    else
        currentMatrix = modelViewMatrix
    end
end

function glLoadIdentity()
    if currentMatrix then currentMatrix:identity() end
end

function glTranslatef(x, y, z)
    local trans = Matrix4x4.new()
    trans:translate(x, y, z)
    currentMatrix:mul(trans)
end

function glRotatef(angle, x, y, z)
    if angle == 0 or (x == 0 and y == 0 and z == 0) then return end
    
    local rad = math.rad(angle)
    local rot = Matrix4x4.new()
    
    rot:rotateAxis(rad, x, y, z)
    
    currentMatrix:mul(rot)
end

function glScalef(x, y, z)
    local scale = Matrix4x4.new()
    scale.data = {
        x, 0, 0, 0,
        0, y, 0, 0,
        0, 0, z, 0,
        0, 0, 0, 1
    }
    currentMatrix:mul(scale)
end

function glPushMatrix()
    local copy = Matrix4x4.new()
    copy.data = {unpack(currentMatrix.data)}
    table.insert(matrixStack, {mode = matrixMode, matrix = copy})
end

function glPopMatrix()
    local top = table.remove(matrixStack)
    if top then
        matrixMode = top.mode
        currentMatrix = top.matrix
        if matrixMode == GL_PROJECTION then
            projMatrix = currentMatrix
        else
            modelViewMatrix = currentMatrix
        end
    end
end

function gluPerspective(fov, aspect, near, far)
    currentMatrix:identity()
    currentMatrix:perspective(fov, aspect, near, far)
end

-- ==================== VISUAL ====================
function glColor3f(r, g, b)
    currentColor = {r, g, b, 1}
end

function glColor4f(r, g, b, a)
    currentColor = {r, g, b, a or 1}
end

function glBindTexture(target, texture)
    if target == GL_TEXTURE_2D then
        currentTexture = texture
    end
end

-- ==================== IMM ====================
function glBegin(mode)
    currentPrimitive = mode
    currentVertices = {} 
end

function glTexCoord2f(u, v)
    currentTexCoord = {u, v}
end

function glVertex3f(x, y, z)
    local vertex = {
        x = x, y = y, z = z,
        r = currentColor[1], g = currentColor[2], b = currentColor[3], a = currentColor[4],
        u = currentTexCoord[1], v = currentTexCoord[2]
    }
    
    table.insert(currentVertices, vertex)
end

-- ==================== MESH BUILDING ====================
local function buildMeshFromVertices(vertices, mode)
    local meshVertices = {}

    local vertexFormat = {
        {"VertexPosition", "float", 3},  -- x, y, z
        {"VertexTexCoord", "float", 2},  -- u, v
        {"VertexColor", "float", 4}     -- r, g, b, a
    }

    if mode == GL_TRIANGLES then
        for i = 1, #vertices - 2, 3 do
            local v1, v2, v3 = vertices[i], vertices[i+1], vertices[i+2]
            table.insert(meshVertices, {v1.x, v1.y, v1.z, v1.u, v1.v, v1.r, v1.g, v1.b, v1.a})
            table.insert(meshVertices, {v2.x, v2.y, v2.z, v2.u, v2.v, v2.r, v2.g, v2.b, v2.a})
            table.insert(meshVertices, {v3.x, v3.y, v3.z, v3.u, v3.v, v3.r, v3.g, v3.b, v3.a})
        end
    elseif mode == GL_QUADS then
        for i = 1, #vertices - 3, 4 do
            local v1, v2, v3, v4 = vertices[i], vertices[i+1], vertices[i+2], vertices[i+3]
            for _, verts in ipairs({{v1,v2,v3}, {v1,v3,v4}}) do
                for _, v in ipairs(verts) do
                    table.insert(meshVertices, {v.x, v.y, v.z, v.u, v.v, v.r, v.g, v.b, v.a})
                end
            end
        end
    end

    if #meshVertices > 0 then
        local mesh = love.graphics.newMesh(vertexFormat, meshVertices, "triangles", "static")
        if currentTexture then mesh:setTexture(currentTexture) end
        return mesh
    end
    return nil
end


function sendShaderData()
    if glShader == nil then return end
    glShader:send("uCullEnabled", enabled[GL_CULL_FACE] and 1 or 0)
    glShader:send("uCullFace", cullFaceMode)
    glShader:send("uTexturingEnabled", texturingEnabled and 1 or 0)
    glShader:send("uFogEnabled", enabled[GL_FOG] and 1 or 0)
    glShader:send("uMV", "column", modelViewMatrix.data)
    glShader:send("uFogMode", fogMode or 1)
    glShader:send("uFogColor", {fogColor[1], fogColor[2], fogColor[3]})
    glShader:send("uFogStart", fogStart)
    glShader:send("uFogEnd", fogEnd)
    glShader:send("uFogDensity", fogDensity or 0.001)
end

local function applyRenderState()
    love.graphics.setShader(glShader)

    if enabled[GL_CULL_FACE] then
        love.graphics.setMeshCullMode(cullFaceMode == 2 and "front" or "back")
    else
        love.graphics.setMeshCullMode("none")
    end

    if enabled[GL_DEPTH_TEST] then
        local mode = "lequal"
        if depthFunc == GL_LEQUAL then mode = "lequal"
        elseif depthFunc == GL_LESS then mode = "less"
        elseif depthFunc == GL_GREATER then mode = "greater"
        elseif depthFunc == GL_GEQUAL then mode = "gequal"
        elseif depthFunc == GL_NOTEQUAL then mode = "notequal"
        elseif depthFunc == GL_ALWAYS then mode = "always"
        elseif depthFunc == GL_NEVER then mode = "never"
        end
        love.graphics.setDepthMode(mode, depthMask)
    else
        love.graphics.setDepthMode("always", false)
    end

    if enabled[GL_BLEND] then
        love.graphics.setBlendMode("alpha")
    else
        love.graphics.setBlendMode("replace")
    end
end

-- ==================== glEnd ====================
function glEnd()
    if not currentPrimitive or #currentVertices == 0 then
        currentPrimitive = nil
        currentVertices = {}
        return
    end

    if recordingList and currentList then
        currentList.primitive = currentPrimitive
        for _, v in ipairs(currentVertices) do
            table.insert(currentList.vertices, v)
        end
    else
        local mesh = buildMeshFromVertices(currentVertices, currentPrimitive)
        if mesh then
            applyRenderState();
            
            local mvp = projMatrix * modelViewMatrix
            glShader:send("uMVP", "column", mvp.data)
            
            sendShaderData();
            
            love.graphics.draw(mesh)
            
            love.graphics.setShader()
        end
    end
    
    currentPrimitive = nil
    currentVertices = {}
end

-- ==================== DISPLAY LISTS ====================
function glGenLists(n)
    local base = nextListID
    nextListID = nextListID + n
    return base
end

function glNewList(listID, mode)
    displayLists[listID] = {
        vertices = {},
        primitive = nil,
        mesh = nil,
        dirty = true,
    }
    recordingList = true
    currentList = displayLists[listID]
    listMode = mode
end

function glEndList()
    if not currentList then return end
    recordingList = false
    
    if #currentList.vertices > 0 then
        currentList.mesh = buildMeshFromVertices(currentList.vertices, currentList.primitive)
    end
    
    currentList.dirty = false
    currentList = nil
end

local function matrixEqual(a, b)
    for i = 1, 16 do
        if a.data[i] ~= b.data[i] then return false end
    end
    return true
end

function glCallList(listID)
    local list = displayLists[listID]
    if not list or not list.mesh then return end

    applyRenderState();
    
    local mvp = projMatrix * modelViewMatrix
    glShader:send("uMVP", "column", mvp.data)
    
    sendShaderData();
    
    love.graphics.draw(list.mesh)
    
    love.graphics.setShader()
end

function glClearDisplayLists()
    displayLists = {}
    nextListID = 1
end

-- ==================== In Future ====================
function glHint(target, mode) end
function glTexImage2D(target, level, internalformat, width, height, border, format, type, data) end

-- ==================== INIT ====================
glMatrixMode(GL_PROJECTION)
glLoadIdentity()
glMatrixMode(GL_MODELVIEW)
glLoadIdentity()
