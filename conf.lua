function love.conf(t)
    t.identity = "PhysicsIKDemo"
    t.appendidentity = false

    t.version = "11.5"
    t.console = false
    
    t.window.title = "Physics‑Based IK Demo"
    t.window.icon = nil
    t.window.width = 1040
    t.window.height = 600
    t.window.resizable = true
    t.window.minwidth = 640
    t.window.minheight = 400
    t.window.borderless = false
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
    t.window.vsync = 1
    t.window.msaa = 4
end
