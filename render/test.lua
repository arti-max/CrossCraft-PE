-- render/test.lua

-- ====== Константы GL ======
GL_PROJECTION = 1
GL_MODELVIEW  = 2
GL_TRIANGLES = 31
GL_QUADS     = 30
GL_CULL_FACE = 10
GL_COMPILE   = 60

-- ====== Глобальные переменные матриц ======
local matrixMode = nil
local projMatrix = Matrix4x4.new()
local modelViewMatrix = Matrix4x4.new()
local currentMatrix = nil

projMatrix:perspective(math.rad(70), love.graphics.getWidth() / love.graphics.getHeight(), 0.1, 100)

-- ====== Функции управления матрицами ======
function glMatrixMode(mode)
    if mode == GL_PROJECTION then
        matrixMode = "projection"
        currentMatrix = projMatrix
    elseif mode == GL_MODELVIEW then
        matrixMode = "modelview"
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
    local rad = math.rad(angle)
    local rot = Matrix4x4.new()
    if x ~= 0 then rot:rotateX(rad) end
    if y ~= 0 then rot:rotateY(rad) end
    if z ~= 0 then rot:rotateZ(rad) end
    currentMatrix:mul(rot)
end

-- ====== Метод transform для Matrix4x4 ======
if not Matrix4x4.transform then
    function Matrix4x4:transform(x, y, z)
        local m = self.data
        local w = m[4]*x + m[8]*y + m[12]*z + m[16]
        if w == 0 then w = 1 end
        local px = (m[1]*x + m[5]*y + m[9]*z  + m[13]) / w
        local py = (m[2]*x + m[6]*y + m[10]*z + m[14]) / w
        local pz = (m[3]*x + m[7]*y + m[11]*z + m[15]) / w
        local screenW = love.graphics.getWidth()
        local screenH = love.graphics.getHeight()
        local sx = (px + 1) * 0.5 * screenW
        local sy = (-py + 1) * 0.5 * screenH
        return sx, sy, pz
    end
    dbg("Matrix4x4.transform added")
end

-- ====== Состояние CULL FACE ======
local cullFaceEnabled = false

function glEnable(mode)
    if mode == GL_CULL_FACE then
        cullFaceEnabled = true
    end
end

function glDisable(mode)
    if mode == GL_CULL_FACE then
        cullFaceEnabled = false
    end
end

-- ====== GL-подобные обёртки для вершин ======
local currentPrimitive = nil
local currentVertices = {}
local currentColor = {1.0, 1.0, 1.0, 1.0}
local clearColor = {0, 0, 0, 1}

function glClearColor(r, g, b, a)
    clearColor = {r, g, b, a or 1}
end

function glClear(mask)
    love.graphics.clear(clearColor[1], clearColor[2], clearColor[3], clearColor[4])
end

function glColor3f(r, g, b)
    currentColor = {r, g, b, 1.0}
end

function glColor4f(r, g, b, a)
    currentColor = {r, g, b, a or 1.0}
end

function glBegin(mode)
    currentPrimitive = mode
    currentVertices = {}
end

function glVertex3f(x, y, z)
    table.insert(currentVertices, {x = x, y = y, z = z, r = currentColor[1], g = currentColor[2], b = currentColor[3], a = currentColor[4]})
end

-- Вспомогательная функция отсечения
local function isBackface(sx1, sy1, sx2, sy2, sx3, sy3)
    local area = (sx2 - sx1) * (sy3 - sy1) - (sx3 - sx1) * (sy2 - sy1)
    return area < 0
end

-- Сборка меша из массива вершин (для прямого рендера и списков)
local function buildMeshFromVertices(vertices, mvp, cull)
    local meshVertices = {}

    local function projectVertex(v)
        return mvp:transform(v.x, v.y, v.z)
    end

    local function addTriangle(sx1, sy1, v1, sx2, sy2, v2, sx3, sy3, v3)
        if cull and isBackface(sx1, sy1, sx2, sy2, sx3, sy3) then
            return
        end
        table.insert(meshVertices, {sx1, sy1, 0, 0, v1.r, v1.g, v1.b, v1.a})
        table.insert(meshVertices, {sx2, sy2, 0, 0, v2.r, v2.g, v2.b, v2.a})
        table.insert(meshVertices, {sx3, sy3, 0, 0, v3.r, v3.g, v3.b, v3.a})
    end

    -- обрабатываем тройки вершин (TRIANGLES)
    for i = 1, #vertices - 2, 3 do
        local v1, v2, v3 = vertices[i], vertices[i+1], vertices[i+2]
        local sx1, sy1, _ = projectVertex(v1)
        local sx2, sy2, _ = projectVertex(v2)
        local sx3, sy3, _ = projectVertex(v3)
        addTriangle(sx1, sy1, v1, sx2, sy2, v2, sx3, sy3, v3)
    end

    if #meshVertices > 0 then
        return love.graphics.newMesh(meshVertices, "triangles", "static")
    end
    return nil
end

function glEnd()
    if not currentPrimitive or #currentVertices == 0 then
        currentPrimitive = nil
        return
    end

    local mvp = projMatrix * modelViewMatrix
    local mesh = buildMeshFromVertices(currentVertices, mvp, cullFaceEnabled)
    if mesh then
        love.graphics.draw(mesh)
    end
    currentPrimitive = nil
end

-- ====== ДИСПЛЕЙНЫЕ СПИСКИ ======
local displayLists = {}
local nextListID = 1
local currentList = nil

function glGenLists(n)
    local base = nextListID
    nextListID = nextListID + n
    return base
end

function glNewList(listID, mode)
    displayLists[listID] = {
        vertices = {},
        mesh = nil,
        dirty = false,
    }
    currentList = displayLists[listID]
end

function glEndList()
    if not currentList then return end
    currentList.vertices = currentVertices
    currentList.dirty = true
    currentVertices = {}
    currentList = nil
end

function glCallList(listID)
    local list = displayLists[listID]
    if not list then return end

    if list.dirty then
        local mvp = projMatrix * modelViewMatrix   -- используем текущую MVP
        list.mesh = buildMeshFromVertices(list.vertices, mvp, cullFaceEnabled)
        list.dirty = false
    end

    if list.mesh then
        love.graphics.draw(list.mesh)
    end
end

-- ====== ИНИЦИАЛИЗАЦИЯ ТЕСТА ======
glMatrixMode(GL_PROJECTION)
glLoadIdentity()
glMatrixMode(GL_MODELVIEW)
glLoadIdentity()
glTranslatef(0, 0, -3)

glClearColor(0.2, 0.3, 0.8, 1)
glDisable(GL_CULL_FACE)

local angle = 0
local testMode = 1   -- 1 = прямой рендер, 2 = список
local lastFPS = 0
local frameCounter = 0
local timer = 0

-- Создаём большой список с 5000 случайных треугольников
local bigListID = glGenLists(1)
glNewList(bigListID, GL_COMPILE)
glBegin(GL_TRIANGLES)
for i = 1, 5000 do
    local x = math.random(-2, 2)
    local y = math.random(-2, 2)
    local z = math.random(-2, 2)
    glColor3f(math.random(), math.random(), math.random())
    glVertex3f(x, y, z)
    glColor3f(math.random(), math.random(), math.random())
    glVertex3f(x + 0.1, y, z)
    glColor3f(math.random(), math.random(), math.random())
    glVertex3f(x, y + 0.1, z)
end
glEnd()
glEndList()
dbg("Big list compiled with 5000 triangles")

-- ====== ОБРАБОТЧИК КЛАВИШ ДЛЯ ПЕРЕКЛЮЧЕНИЯ РЕЖИМОВ ======
local originalKeypressed = love.keypressed
love.keypressed = function(key)
    if key == "1" then
        testMode = 1
        dbg("Switched to DIRECT render")
    elseif key == "2" then
        testMode = 2
        dbg("Switched to DISPLAY LIST render")
    end
    -- пробросим дальше, чтобы не сломать Ctrl+C из debugPanel
    if originalKeypressed then originalKeypressed(key) end
end

-- ====== КОЛЛБЕК ОТРИСОВКИ ======
table.insert(_G.drawCallbacks, function()
    angle = angle + 1
    if angle >= 360 then angle = angle - 360 end

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    glTranslatef(0, 0, -3)
    glRotatef(angle, 0, 1, 0)

    glClear(0)

    if testMode == 1 then
        -- Прямой рендер: каждый кадр заново генерируем и проецируем 5000 треугольников
        glBegin(GL_TRIANGLES)
        for i = 1, 5000 do
            local x = math.random(-2, 2)
            local y = math.random(-2, 2)
            local z = math.random(-2, 2)
            glColor3f(math.random(), math.random(), math.random())
            glVertex3f(x, y, z)
            glColor3f(math.random(), math.random(), math.random())
            glVertex3f(x + 0.1, y, z)
            glColor3f(math.random(), math.random(), math.random())
            glVertex3f(x, y + 0.1, z)
        end
        glEnd()
    else
        -- Список: один раз собранный меш просто рисуется
        glCallList(bigListID)
    end

    -- Замер FPS
    frameCounter = frameCounter + 1
    timer = timer + love.timer.getDelta()
    if timer >= 1 then
        lastFPS = frameCounter
        frameCounter = 0
        timer = 0
    end

    dbg("Mode: " .. (testMode == 1 and "DIRECT" or "LIST") .. " | FPS: " .. lastFPS .. " | Angle: " .. angle)
end)