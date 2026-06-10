-- render/test6.lua

love.window.setMode(800, 600, {
    resizable = true,
    vsync = true
    -- без depth
})

glMatrixMode(GL_PROJECTION)
glLoadIdentity()
gluPerspective(70, love.graphics.getWidth() / love.graphics.getHeight(), 0.1, 100)
glMatrixMode(GL_MODELVIEW)
glLoadIdentity()

-- Никаких тестов глубины и куллинга
glClearColor(0.3, 0.5, 0.9, 1)

local angle = 0
local frameCount = 0
local fpsTimer = 0
local lastFPS = 0

dbg.setBreakAtError(true);

table.insert(_G.drawCallbacks, function()
    frameCount = frameCount + 1
    fpsTimer = fpsTimer + love.timer.getDelta()
    if fpsTimer >= 1 then
        lastFPS = frameCount
        frameCount = 0
        fpsTimer = 0
    end

    angle = angle + 1.5
    if angle >= 360 then angle = angle - 360 end

    -- Очистка только цвета
    glClear(GL_COLOR_BUFFER_BIT)

    -- Камера
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    glTranslatef(0, 0, -3)
    glRotatef(angle, 0, 1, 0)

    -- Цветной треугольник (без текстур)
    glBegin(GL_TRIANGLES)
        glColor3f(1, 0, 0)
        glVertex3f(-0.7, -0.7, 0)
        glColor3f(0, 1, 0)
        glVertex3f( 0.7, -0.7, 0)
        glColor3f(0, 0, 1)
        glVertex3f( 0.0,  0.7, 0)
    glEnd()

    dbg("Mobile test FPS: " .. lastFPS)
end)