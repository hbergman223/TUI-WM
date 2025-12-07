local socket = require("socket")
local engine = require("window")

-- desktop init
local desktop = engine.newWindow("desktop", 80, 24)
local bg = desktop:addLayer("background/taskbar", 0)
local tb = desktop:addLayer("taskbar contents", 10)
local subWindowLayer = desktop:addLayer("subwindow", 20)

-- desktop wallpaper
bg:addGraphic("box", {x=1, y=1, w=80, h=22, char="`"})

-- desktop taskbar (fixed, no window minimizing yet)
bg:addGraphic("box", {x=1, y=23, w=80, h=1, char="="})

-- desktop taskbar contents
tb:addText(24, 1,  "    TUI Lua Desktop", "left")
tb:addText(24, 1, "Desktop 1", "center")
tb:addText(24, 1, "(running on LWE v6)    ", "right")

-- reusable window creation helper
function createWindow(title, sizeX, sizeY)
    local subwin = engine.newWindow(title, sizeX, sizeY)
    local subBg = subwin:addLayer("sub_bg")
    local subFg = subwin:addLayer("sub_fg")
    
    -- frame and interior
    subBg:addGraphic("box", {x=1, y=1, w=sizeX, h=sizeY, char="#"})
    subBg:addGraphic("box", {x=2, y=2, w=sizeX - 2, h=sizeY - 2, char=" "})
    
    -- title bar components
    local controls = "-{ - + X }-"
    local leftLabel = "[ " .. title .. " ]"
    
    -- calculate positions
    local leftLabelStart = 2  -- start position for title
    local leftLabelEnd = leftLabelStart + #leftLabel - 1  -- end position of title
    local controlsStart = sizeX - #controls  -- start position for controls
    
    -- add title on left
    subFg:addText(1, leftLabelStart, leftLabel, "left")
    
    -- add filler in the middle (if there's space)
    local fillerStart = leftLabelEnd + 1
    local fillerEnd = controlsStart - 1
    local fillerWidth = fillerEnd - fillerStart + 1
    
    if fillerWidth > 0 then
        subFg:addGraphic("box", {x=fillerStart, y=1, w=fillerWidth, h=1, char="#"})
    end
    
    -- add controls on right
    subFg:addText(1, controlsStart, controls, "left")
    
    return subwin
end

-- create a subwindow
local subwin = createWindow("development", 40, 8)

-- attach subwindow to desktop
subWindowLayer:addSubWindow(subwin, 40, 8)

-- loop at 60 FPS
local ok, err = pcall(function()
    while true do
        engine.renderWindow(desktop)
        socket.sleep(0.01)
    end
end)

-- show cursor again on exit
io.write("\27[?25h")
if not ok then
    print("\nanimation stopped: " .. err)
end


--[[
NOTES:
Format bugs like this: DD/MM/YYYY - {contributor's name} <{email}> - {bug}

BUGS:

7/12/2025 - Hunter Bergman <hunterbergman125@gmail.com> - bug where when rendering at 60 FPS, line 19 never shows.

END OF BUGS
]]--