-- test3_debug.lua – минимальный тест одного куба (без списков, без cull, без depth)
if glBegin then dbg("glBegin OK") else dbg("glBegin NIL!") end
_G.drawCallbacks = _G.drawCallbacks or {}

-- ====== Настройка проекции ======
glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(math.rad(70), love.graphics.getWidth() / love.graphics.getHeight(), 0.1, 100)

dbg("Projection set: fov=70, aspect=" .. love.graphics.getWidth()/love.graphics.getHeight())

glMatrixMode(GL_MODELVIEW)
glLoadIdentity()

-- Отключаем всё, что может помешать
-- glDisable(GL_CULL_FACE)
-- glDisable(GL_DEPTH_TEST)
glClearColor(0.2, 0.2, 0.2, 1)

-- ====== Функция одного куба (Quad'ы) ======
local function drawOneCube(x, y, z, size, r, g, b)
    local s = size * 0.5
    glBegin(GL_QUADS)
    glColor3f(r, g, b)

    -- передняя (Z+)
    glVertex3f(x-s, y-s, z+s); glVertex3f(x+s, y-s, z+s); glVertex3f(x+s, y+s, z+s); glVertex3f(x-s, y+s, z+s)
    -- задняя (Z-)
    glVertex3f(x+s, y-s, z-s); glVertex3f(x-s, y-s, z-s); glVertex3f(x-s, y+s, z-s); glVertex3f(x+s, y+s, z-s)
    -- верхняя (Y+)
    glVertex3f(x-s, y+s, z+s); glVertex3f(x+s, y+s, z+s); glVertex3f(x+s, y+s, z-s); glVertex3f(x-s, y+s, z-s)
    -- нижняя (Y-)
    glVertex3f(x-s, y-s, z-s); glVertex3f(x+s, y-s, z-s); glVertex3f(x+s, y-s, z+s); glVertex3f(x-s, y-s, z+s)
    -- правая (X+)
    glVertex3f(x+s, y-s, z+s); glVertex3f(x+s, y-s, z-s); glVertex3f(x+s, y+s, z-s); glVertex3f(x+s, y+s, z+s)
    -- левая (X-)
    glVertex3f(x-s, y-s, z-s); glVertex3f(x-s, y-s, z+s); glVertex3f(x-s, y+s, z+s); glVertex3f(x-s, y+s, z-s)

    glEnd()
end

local angle = 0
local testMode = 1   -- 1 = прямой рендер, 2 = список
local lastFPS = 0
local frameCounter = 0
local timer = 0

-- ====== Коллбек отрисовки ======
table.insert(_G.drawCallbacks, function()
    -- камера (как в test2)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    glTranslatef(0, 0, -10)

    -- Очистка точно как в test2 (с 0)
    glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT);

    glBegin(GL_TRIANGLES)
        glColor3f(1, 0, 0)
        glVertex3f(-0.5, 0, 0)
        glColor3f(1, 0, 0)
        glVertex3f(0.5, 0, 0)
        glColor3f(1, 0, 0)
        glVertex3f(0, 0.5, 0)
    glEnd()

    frameCounter = frameCounter + 1
    timer = timer + love.timer.getDelta()
    if timer >= 1 then
        lastFPS = frameCounter
        frameCounter = 0
        timer = 0
    end

    dbg("Single triangle drawn (glClear(0)) | FPS: " .. lastFPS)
end)