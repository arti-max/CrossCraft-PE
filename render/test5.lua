-- render/test5.lua

love.window.setMode(800, 600, {
    depth = 16,
    resizable = true,
    vsync = true
})

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, love.graphics.getWidth() / love.graphics.getHeight(), 0.1, 100)

glMatrixMode(GL_MODELVIEW)
glLoadIdentity()

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LEQUAL)

glDisable(GL_CULL_FACE)
-- glCullFace(GL_BACK)

glClearColor(0.3, 0.5, 0.9, 1)

-- ====== Создаём тестовую текстуру 16x16 (цветные клетки) ======
local tex16
do
    local imgData = love.image.newImageData(16, 16)
    for y = 0, 15 do
        for x = 0, 15 do
            -- шахматная текстура: чёрно-белые клетки 8x8
            local r = (x % 8 < 4) ~= (y % 8 < 4) and 1 or 0.2
            local g = r * 0.5
            local b = 0.8
            imgData:setPixel(x, y, r, g, b, 1)
        end
    end
    tex16 = love.graphics.newImage(imgData)
    tex16:setFilter("nearest", "nearest")
end

-- ====== Параметры вращения и FPS ======
local angle = 0
local lastFPS = 0
local frameCounter = 0
local fpsTimer = 0

-- ====== Коллбек отрисовки ======
table.insert(_G.drawCallbacks, function()
    -- обновление FPS
    frameCounter = frameCounter + 1
    fpsTimer = fpsTimer + love.timer.getDelta()
    if fpsTimer >= 1 then
        lastFPS = frameCounter
        frameCounter = 0
        fpsTimer = 0
    end

    angle = angle + 1.5
    if angle >= 360 then angle = angle - 360 end

    -- очистка
    glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)

    -- камера: отодвигаемся и вращаем
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    glTranslatef(0, 0, -3)                     -- отодвигаем камеру
    glRotatef(angle, 1, 0, 0)                 -- вращение вокруг Y
    -- можно добавить наклон
    -- glRotatef(30, 1, 0, 0)

    -- рисуем треугольник с текстурой
    glEnable(GL_TEXTURE_2D)
    glBindTexture(GL_TEXTURE_2D, tex16)

    glBegin(GL_TRIANGLES)
        -- белый цвет, чтобы текстура была видна без затемнения
        glColor3f(0.5, 0.5, 0.5)
        
        -- левый нижний угол
        glTexCoord2f(0, 0)
        glVertex3f(-0.7, -0.7, 0)
        
        -- правый нижний
        glTexCoord2f(1, 0)
        glVertex3f( 0.7, -0.7, 0)
        
        -- верхний центр
        glTexCoord2f(0.5, 1)
        glVertex3f( 0.0,  0.7, 0)
    glEnd()

    glDisable(GL_TEXTURE_2D)

    dbg("Textured Tri FPS: " .. lastFPS .. " | Angle: " .. string.format("%.1f", angle))
end)