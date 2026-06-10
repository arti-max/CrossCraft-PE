-- Timer.lua
_G.Timer = {}

class "Timer" {
    constructor = function(self, ticksPerSecond)
        self.tps = ticksPerSecond
        self.timeScale = 1.0
        self.fps = 0.0
        self.passedTime = 0.0
        self.ticks = 0
        self.partialTicks = 0.0
        self.lastTime = love.timer.getTime()
        self.callback = nil
    end,

    onTick = function(self, fn)
        self.callback = fn
    end,

    advanceTime = function(self)
        local now = love.timer.getTime()
        local passed = now - self.lastTime
        self.lastTime = now

        passed = math.max(0, math.min(passed, 1.0))

        if passed > 0 then
            self.fps = 1.0 / passed
        end

        self.passedTime = self.passedTime + passed * self.timeScale * self.tps
        self.ticks = math.min(100, math.floor(self.passedTime))
        self.passedTime = self.passedTime - self.ticks
        self.partialTicks = self.passedTime
        for i = 1, self.ticks do
            if self.callback then self.callback(i) end
        end
    end,

    getPartialTicks = function(self)
        return self.partialTicks
    end,
}