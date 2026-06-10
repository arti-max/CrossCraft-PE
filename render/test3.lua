-- render/test3.lua

-- ====== Настройка проекции ======
love.window.setMode(800, 600, {
        depth = 24,
        resizable = true,
        vsync = true
    })

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, love.graphics.getWidth() / love.graphics.getHeight(), 0.1, 100)

glMatrixMode(GL_MODELVIEW)
glLoadIdentity()

-- ====== Состояния OpenGL ======
glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LEQUAL)

glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
-- glDisable(GL_CULL_FACE);
-- glDisable(GL_DEPTH_TEST);

glClearColor(0.3, 0.5, 0.9, 1)

-- ====== Функция построения куба ======
local function drawCube(x, y, z, size, r, g, b)
    local s = size * 0.5
    
    local faces = {
        -- Передняя (Z+) -> Смотрим спереди: лево-низ, право-низ, право-верх, лево-верх
        {
            { x-s, y-s, z+s },
            { x+s, y-s, z+s },
            { x+s, y+s, z+s },
            { x-s, y+s, z+s },
        },
        -- Задняя (Z-) -> Смотрим сзади: право-низ, лево-низ, лево-верх, право-верх
        {
            { x+s, y-s, z-s },
            { x-s, y-s, z-s },
            { x-s, y+s, z-s },
            { x+s, y+s, z-s },
        },
        -- Верхняя (Y+) -> Смотрим сверху: лево-зад, лево-перед, право-перед, право-зад
        {
            { x-s, y+s, z-s },
            { x-s, y+s, z+s },
            { x+s, y+s, z+s },
            { x+s, y+s, z-s },
        },
        -- Нижняя (Y-) -> Смотрим снизу: лево-перед, лево-зад, право-зад, право-перед
        {
            { x-s, y-s, z+s },
            { x-s, y-s, z-s },
            { x+s, y-s, z-s },
            { x+s, y-s, z+s },
        },
        -- Правая (X+) -> Смотрим справа: перед-низ, зад-низ, зад-верх, перед-верх
        {
            { x+s, y-s, z+s },
            { x+s, y-s, z-s },
            { x+s, y+s, z-s },
            { x+s, y+s, z+s },
        },
        -- Левая (X-) -> Смотрим слева: зад-низ, перед-низ, перед-верх, зад-верх
        {
            { x-s, y-s, z-s },
            { x-s, y-s, z+s },
            { x-s, y+s, z+s },
            { x-s, y+s, z-s },
        },
    }

    glBegin(GL_QUADS)
    for _, face in ipairs(faces) do
        -- Оставляем случайные цвета для теста граней, если нужно
        glColor3f(math.random(), math.random(), math.random())
        for _, v in ipairs(face) do
            glVertex3f(v[1], v[2], v[3])
        end
    end
    glEnd()
end

-- ====== Дисплейный список с несколькими кубами ======
local listID = glGenLists(1)
glNewList(listID, GL_COMPILE)

drawCube(0, 0, 0, 0.5, 1, 1, 1);

-- for i = 0, 2 do
--     drawCube(i * 2 - 3, 0, 0, 1.0, 1, 0.15 * i, 0.15)           -- красноватые
--     drawCube(i * 2 - 3, 1.5, 0, 1.0, 0.15, 1, 0.15 * i)         -- зеленоватые
-- end

glEndList()

-- ====== Параметры камеры ======
local angle = 0
local lastFPS = 0
local frameCounter = 0
local fpsTimer = 0

-- ====== Коллбек отрисовки ======
table.insert(_G.drawCallbacks, function()
    angle = angle + 0.5
    if angle >= 360 then angle = angle - 360 end

    -- замер FPS
    frameCounter = frameCounter + 1
    fpsTimer = fpsTimer + love.timer.getDelta()
    if fpsTimer >= 1 then
        lastFPS = frameCounter
        frameCounter = 0
        fpsTimer = 0
    end

    -- камера вращается вокруг центра
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    local radius = 6
    local camX = math.cos(math.rad(angle)) * radius
    local camZ = math.sin(math.rad(angle)) * radius
    -- вручную строим lookAt через rotate/translate
    glTranslatef(0, 0, -radius)
    glRotatef(angle, 1, 1, 1)
    -- glTranslatef(0, -1, 0)   -- чуть опускаем камеру к кубикам

    glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)

    -- drawCube(0, 0, 0, 1, 1, 1, 1);
    glCallList(listID)

    dbg("Cubes FPS: " .. lastFPS .. " | Angle: " .. angle)
end)