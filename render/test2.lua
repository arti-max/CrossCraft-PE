-- test2.lua 

-- ====== Настройка проекции и состояния ======
glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(math.rad(70), love.graphics.getWidth() / love.graphics.getHeight(), 0.05, 1000)

glMatrixMode(GL_MODELVIEW)
glLoadIdentity()
glTranslatef(0, 0, -3)

glClearColor(0.2, 0.3, 0.8, 1)
glEnable(GL_CULL_FACE);
glCullFace(GL_BACK)
glEnable(GL_DEPTH_TEST);
glDepthFunc(GL_LEQUAL)
-- glDisable(GL_CULL_FACE)

-- ====== Создание дисплейного списка с 5000 случайных треугольников ======
local bigListID = glGenLists(1)
glNewList(bigListID, GL_COMPILE)
glBegin(GL_TRIANGLES)
for i = 1, 5000 do
    local x = (math.random() * 4) - 2
    local y = (math.random() * 4) - 2
    local z = (math.random() * 4) - 2
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

-- ====== Переменные для теста ======
local angle = 0
local testMode = 1   -- 1 = прямой рендер, 2 = список
local lastFPS = 0
local frameCounter = 0
local timer = 0

-- ====== Обработка клавиш для переключения режимов ======
local originalKeypressed = love.keypressed
love.keypressed = function(key)
    if key == "1" then
        testMode = 1
        dbg("Switched to DIRECT render")
    elseif key == "2" then
        testMode = 2
        dbg("Switched to DISPLAY LIST render")
    end
    if originalKeypressed then originalKeypressed(key) end
end

-- ====== Коллбек отрисовки ======
table.insert(_G.drawCallbacks, function()
    -- Обновление поворота
    angle = angle + 0.1
    if angle >= 360 then angle = angle - 360 end

    -- Настройка модельно-видовой матрицы
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    glTranslatef(0, 0, -10)
    glRotatef(angle, 1, 1, 1)

    glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT);

    if testMode == 1 then
        -- Прямой рендер: каждый кадр генерируем и проецируем 5000 треугольников
        glBegin(GL_TRIANGLES)
        for i = 1, 5000 do
            local x = (math.random() * 4) - 2
            local y = (math.random() * 4) - 2
            local z = (math.random() * 4) - 2
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