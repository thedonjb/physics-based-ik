local chain = {}
local N = 12
local segLen = 22
local iterations = 20
local damping = 0.995
local gravityOn = false
local target = { x = 0, y = 0 }
local dragging = false
local draggingBase = false
local followMouse = true

local cam = { x = 0, y = 0 }
local pan = { active = false, ox = 0, oy = 0 }

local function makeChain(cx, cy)
    chain = {}
    for i = 0, N do
        local x = cx
        local y = cy + i * segLen
        chain[i] = {
            x = x,
            y = y,
            px = x,
            py = y,
            fixed = (i == 0)
        }
    end
end

function love.load()
    love.window.setTitle("Physics-based IK (PBD)")
    love.graphics.setBackgroundColor(0.08, 0.09, 0.11)
    local w, h = love.graphics.getDimensions()
    target.x, target.y = w * 0.6, h * 0.4
    makeChain(w * 0.4, h * 0.4)
end

local function integrate(dt)
    local ax, ay = 0, gravityOn and 900 or 0
    for i = 0, N do
        local n = chain[i]
        if not n.fixed then
            local vx = (n.x - n.px) * damping
            local vy = (n.y - n.py) * damping
            n.px, n.py = n.x, n.y
            n.x = n.x + vx + ax * dt * dt
            n.y = n.y + vy + ay * dt * dt
        end
    end
end

local function satisfy(i)
    local a, b = chain[i - 1], chain[i]
    local dx = b.x - a.x
    local dy = b.y - a.y
    local dist = math.sqrt(dx * dx + dy * dy) + 1e-8
    local diff = (dist - segLen) / dist
    local moveX = dx * 0.5 * diff
    local moveY = dy * 0.5 * diff

    if not a.fixed and not b.fixed then
        a.x = a.x + moveX
        a.y = a.y + moveY
        b.x = b.x - moveX
        b.y = b.y - moveY
    elseif a.fixed and not b.fixed then
        b.x = b.x - 2 * moveX
        b.y = b.y - 2 * moveY
    elseif not a.fixed and b.fixed then
        a.x = a.x + 2 * moveX
        a.y = a.y + 2 * moveY
    end
end

local function endEffectorConstraint(stiffness)
    local tip = chain[N]
    local dx = target.x - tip.x
    local dy = target.y - tip.y
    tip.x = tip.x + dx * stiffness
    tip.y = tip.y + dy * stiffness
end

local function solve()
    for it = 1, iterations do
        endEffectorConstraint(0.20)
        for i = 1, N do satisfy(i) end
        if chain[0].fixed then
            chain[0].x, chain[0].y = chain[0].x, chain[0].y
        end
    end
end

function love.update(dt)
    local mx, my = love.mouse.getPosition()
    mx, my = mx - cam.x, my - cam.y

    if followMouse then
        target.x, target.y = mx, my
    elseif dragging then
        target.x, target.y = mx, my
    elseif draggingBase then
        chain[0].x, chain[0].y = mx, my
    end

    integrate(dt)
    solve()
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(cam.x, cam.y)

    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0.13, 0.14, 0.18)
    local spacing = 40
    local startX = math.floor(-cam.x / spacing) * spacing
    local startY = math.floor(-cam.y / spacing) * spacing
    for x = startX, w - cam.x, spacing do
        love.graphics.line(x, -cam.y, x, h - cam.y)
    end
    for y = startY, h - cam.y, spacing do
        love.graphics.line(-cam.x, y, w - cam.x, y)
    end

    love.graphics.setLineWidth(3)
    for i = 1, N do
        local a, b = chain[i - 1], chain[i]
        love.graphics.setColor(0.85, 0.88, 0.95)
        love.graphics.line(a.x, a.y, b.x, b.y)
    end

    for i = 0, N do
        local n = chain[i]
        if i == 0 then
            love.graphics.setColor(0.45, 0.9, 0.6)
        elseif i == N then
            love.graphics.setColor(0.95, 0.7, 0.3)
        else
            love.graphics.setColor(0.75, 0.8, 0.9)
        end
        love.graphics.circle("fill", n.x, n.y, (i == 0 or i == N) and 6 or 4)
    end

    love.graphics.setColor(0.98, 0.35, 0.4)
    love.graphics.circle("line", target.x, target.y, 10)

    love.graphics.pop()

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(
        "[LMB drag] target  |  [RMB drag] move base  |  [MMB drag] pan view\n" ..
        "[Space] toggle follow  |  [Up/Down] add/remove segments\n" ..
        "[Wheel] seg length  |  [G] gravity  |  [R] reset",
        12, 12)
end

function love.mousepressed(x, y, button)
    local wx, wy = x - cam.x, y - cam.y
    if button == 1 then
        dragging = true
        followMouse = false
        target.x, target.y = wx, wy
    elseif button == 2 then
        draggingBase = true
    elseif button == 3 then
        pan.active = true
        pan.ox, pan.oy = x - cam.x, y - cam.y
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then dragging = false end
    if button == 2 then draggingBase = false end
    if button == 3 then pan.active = false end
end

function love.mousemoved(x, y, dx, dy)
    if pan.active then
        cam.x = cam.x + dx
        cam.y = cam.y + dy
    end
end

function love.wheelmoved(_, y)
    segLen = math.max(6, math.min(120, segLen + y * 2))
end

function love.keypressed(key)
    if key == "space" then
        followMouse = not followMouse
    elseif key == "up" then
        N = math.min(64, N + 1)
        makeChain(chain[0].x, chain[0].y)
    elseif key == "down" then
        N = math.max(1, N - 1)
        makeChain(chain[0].x, chain[0].y)
    elseif key == "g" then
        gravityOn = not gravityOn
    elseif key == "r" then
        local w, h = love.graphics.getDimensions()
        makeChain(w * 0.4, h * 0.4)
    end
end
