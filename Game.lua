-- Game.lua

_G.Game = {};

class "Game" {
    constructor = function(self)
        self.timer = Timer.new(20)
        self.running = false
        self.frames = 0;
        self.lastTime = love.timer.getTime() * 1000;
        self.angle = 0;
        self.cameraDragging = false;
        self.prevMouseX = 0;
        self.prevMouseY = 0;
        self.hitResult = nil;
        dbg.setBreakAtError(true);
        dbg.setFadeTime(4);
        dbg.setShowInfo(false);
    end;

    setup = function(self)
        dbg.info("Setup Enter")
        self.width  = love.graphics.getWidth()
        self.height = love.graphics.getHeight()

        love.window.setMode(self.width, self.height, {depth = 24, resizable = true})


        local atlasPath = UP.fileSaves.resolve('atlas.png')
        if atlasPath then
            local tex = love.graphics.newImage(atlasPath)
            if tex then
                tex:setFilter("nearest", "nearest")
                _G.terrainTex = tex
                dbg("Atlas loaded from fileSaves!")
            else
                dbg("Failed to create Image from atlas.png")
            end
        else
            dbg("atlas.png not found in fileSaves")
        end

        self.fogColor = {
            14 / 255.0,
            11 / 255.0,
            10 / 255.0
        }

        glEnable(GL_CULL_FACE)
        glCullFace(GL_BACK)
        glClearDepth(1.0);
        glEnable(GL_DEPTH_TEST)
        glDepthFunc(GL_LEQUAL)
        glClearColor(0.0, 0.7, 1.0, 1.0)

        glMatrixMode(GL_PROJECTION)
        glLoadIdentity()
        gluPerspective(70, self.width / self.height, 0.05, 1000)
        glMatrixMode(GL_MODELVIEW)

        self.level = Level.new(256, 256, 64)
        self.levelRender = LevelRender.new(self.level);
        self.player = Player.new(self.level);

        self.controls = Controls.new(self.player);

        local game = self
        table.insert(_G.drawCallbacks, function()
            game:update();
        end)

        dbg.info("Setup End");

        self.running = true;
    end;

    update = function(self)
        self.timer:advanceTime();
        self.angle = self.angle+1;

        self:handleCameraInput();
        self.controls:pollInput(self.cameraTouchId);

        for i = 1, self.timer.ticks do
            self:tick();
        end

        self:render(self.timer:getPartialTicks());

        self.frames=self.frames+1;

        while (love.timer.getTime() * 1000 >= self.lastTime + 1000) do
            dbg(tostring(self.frames) .. " fps, " .. tostring(Chunk.updates));
            
            Chunk.updates = 0;
            self.lastTime = self.lastTime+1000;
            self.frames=0;
        end
    end;

    tick = function (self)
        if love.keyboard.isDown("escape") then
            love.mouse.setRelativeMode(false);
        end
        if self.player.touchRespawn then
            self.player:resetPosition();
            self.player.touchRespawn = false;
        end
        if self.player.touchSave then
            self.level:save();
            self.player.touchSave = false;
        end
        self.player:tick();
        
    end;

    render = function(self, partialTicks)
        -- local mx, my = love.mouse.getPosition();

        -- self.player:turn(mx, my);

        glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)
        glLoadIdentity();
        self:setupCamera(partialTicks);
        self:raycast();

        if (self.player.touchBreak) then
            if (self.hitResult ~= nil) then
                self.level:setTile(self.hitResult.x, self.hitResult.y, self.hitResult.z, 0);
            end
            self.player.touchBreak = false;
        end
        if (self.player.touchPlace) then
            if (self.hitResult ~= nil) then
                local x = self.hitResult.x;
                local y = self.hitResult.y;
                local z = self.hitResult.z;

                if (self.hitResult.face == 1) then y=y+1 end;
                if (self.hitResult.face == 2) then y=y-1 end;
                if (self.hitResult.face == 3) then x=x+1 end;
                if (self.hitResult.face == 4) then x=x-1 end;
                if (self.hitResult.face == 5) then z=z+1 end;
                if (self.hitResult.face == 6) then z=z-1 end;

                self.level:setTile(x, y, z, 1);
            end
            self.player.touchPlace = false;
        end


        glEnable(GL_FOG);
        glFogi(GL_FOG_MODE, GL_LINEAR);
        glFogf(GL_FOG_START, -10);
        glFogf(GL_FOG_END, 20);
        glFogfv(GL_FOG_COLOR, self.fogColor);
        glDisable(GL_FOG);

        self.levelRender:render(0);

        glEnable(GL_FOG);

        self.levelRender:render(1);

        glDisable(GL_FOG);
        glDisable(GL_TEXTURE_2D);

        if (self.hitResult ~= nil) then
            self.levelRender:renderHit(self.hitResult);
        end

        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();


        local swidth = self.width * 240 / self.height;
        local sheight = self.height * 240 / self.height;
        glClear(GL_DEPTH_BUFFER_BIT);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(0.0, swidth, sheight, 0.0, 100.0, 300.0);
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        glTranslatef(0, 0, -200);
        glPushMatrix();
        glScalef(16, 16, 16);
        glRotatef(-30, 1, 0, 0);
        glRotatef(45.0, 0, 1, 0);
        glScalef(-1, -1, -1);
        local renderer = Render.new();
        renderer:begin();
        Tile.rock:render(renderer, self.level, -1, -1, -1, 0);
        renderer:flush();
        glPopMatrix();

        if self.controls then
            glMatrixMode(GL_PROJECTION);
            glLoadIdentity();
            glMatrixMode(GL_MODELVIEW);
            glLoadIdentity();
            self.controls:render();
        end
    end;

    raycast = function(self) 
        if (self.hitResult ~= nil) then
            self.hitResult = nil;
        end

        local ray = Ray.fromPlayer(self.player);

        self.hitResult = ray:trace(self.level, 5.0);
    end;

    setupCamera = function(self, partialTicks)
        glMatrixMode(GL_PROJECTION)
        glLoadIdentity()
        gluPerspective(70, love.graphics.getWidth() / love.graphics.getHeight(), 0.05, 1000)
        glMatrixMode(GL_MODELVIEW)
        glLoadIdentity()
        self:moveCameraToPlayer(partialTicks)
    end;

    moveCameraToPlayer = function(self, partialTicks)
        glTranslatef(0, 0, -0.3);
        -- rotate camera
        glRotatef(self.player.xRot, 1, 0, 0);
        glRotatef(self.player.yRot, 0, 1, 0);
        -- interpolate move
        local x = self.player.xo + (self.player.x - self.player.xo) * partialTicks;
        local y = self.player.yo + (self.player.y - self.player.yo) * partialTicks;
        local z = self.player.zo + (self.player.z - self.player.zo) * partialTicks;

        -- move camera
        glTranslatef(-x, -y, -z)
    end;

    handleCameraInput = function(self)
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()

        local touches = love.touch.getTouches()
        if #touches > 0 then
            if not self.cameraTouchId then
                for _, id in ipairs(touches) do
                    local tx, ty = love.touch.getPosition(id)
                    if tx > w / 2 and not (self.controls and self.controls:isPointOverControl(tx, ty)) then
                        self.cameraTouchId = id
                        self.prevMouseX, self.prevMouseY = tx, ty
                        break
                    end
                end
            else
                local stillActive = false
                for _, id in ipairs(touches) do
                    if id == self.cameraTouchId then
                        stillActive = true
                        break
                    end
                end
                if not stillActive then
                    self.cameraTouchId = nil
                end
            end

            if self.cameraTouchId then
                local tx, ty = love.touch.getPosition(self.cameraTouchId)
                local dx = tx - self.prevMouseX
                local dy = ty - self.prevMouseY
                self.player:turn(dx, -dy)
                self.prevMouseX, self.prevMouseY = tx, ty
            end
        else
            local mx, my = love.mouse.getPosition()
            if self.controls and self.controls:isPointOverControl(mx, my) then
                self.cameraTouchId = nil
                return
            end

            if love.mouse.isDown(1) then
                if not self.cameraDragging then
                    if mx > w / 2 then
                        self.cameraDragging = true
                        self.prevMouseX, self.prevMouseY = mx, my
                    end
                else
                    local dx = mx - self.prevMouseX
                    local dy = my - self.prevMouseY
                    self.player:turn(dx, -dy)
                    self.prevMouseX, self.prevMouseY = mx, my
                end
            else
                self.cameraDragging = false
            end
            self.cameraTouchId = nil
        end
    end;
}



local game = Game.new()
game:setup();