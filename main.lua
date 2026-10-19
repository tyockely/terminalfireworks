local Particle = {}
Particle.__index = Particle

function Particle.new(x, y, vx, vy, char, life)
    return setmetatable({
        x = x,
        y = y,
        vx = vx,
        vy = vy,
        char = char,
        life = life,
        maxLife = life
    }, Particle)
end

function Particle:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.vy = self.vy + 4.5 * dt
    self.life = self.life - dt
    return self.life > 0
end

local Emitter = {}
Emitter.__index = Emitter

function Emitter.new(x, y)
    return setmetatable({
        x = x,
        y = y,
        particles = {},
        chars = { "*", "+", "o", ".", "@", "#" }
    }, Emitter)
end

function Emitter:burst(count)
    for _ = 1, count do
        local angle = math.random() * 2 * math.pi
        local speed = math.random(3, 12)
        local vx = math.cos(angle) * speed * 2
        local vy = math.sin(angle) * speed
        local char = self.chars[math.random(#self.chars)]
        local life = math.random(12, 25) / 10
        table.insert(self.particles, Particle.new(self.x, self.y, vx, vy, char, life))
    end
end

function Emitter:update(dt)
    local active = {}
    for _, p in ipairs(self.particles) do
        if p:update(dt) then
            table.insert(active, p)
        end
    end
    self.particles = active
end

function Emitter:draw(canvas)
    for _, p in ipairs(self.particles) do
        local rx = math.floor(p.x + 0.5)
        local ry = math.floor(p.y + 0.5)
        if rx >= 1 and rx <= 80 and ry >= 1 and ry <= 24 then
            canvas[ry][rx] = p.char
        end
    end
end

local function clearBuffer()
    local canvas = {}
    for y = 1, 24 do
        canvas[y] = {}
        for x = 1, 80 do
            canvas[y][x] = " "
        end
    end
    return canvas
end

local function renderBuffer(canvas)
    local lines = {}
    for y = 1, 24 do
        lines[y] = table.concat(canvas[y])
    end
    io.write("\27[H" .. table.concat(lines, "\n"))
end

math.randomseed(os.time())
io.write("\27[2J\27[?25l")

local emitters = {}
local dt = 0.04
local frame = 0

while frame < 180 do
    frame = frame + 1

    if frame % 12 == 1 then
        local ex = math.random(15, 65)
        local ey = math.random(5, 12)
        local em = Emitter.new(ex, ey)
        em:burst(math.random(25, 40))
        table.insert(emitters, em)
    end

    local canvas = clearBuffer()
    local activeEmitters = {}

    for _, em in ipairs(emitters) do
        em:update(dt)
        em:draw(canvas)
        if #em.particles > 0 then
            table.insert(activeEmitters, em)
        end
    end
    emitters = activeEmitters

    renderBuffer(canvas)

    local t0 = os.clock()
    while os.clock() - t0 < dt do end
end

io.write("\27[?25h\27[2J\27[HComplete\n")
