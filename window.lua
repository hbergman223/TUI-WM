-- Improved Lua Window Engine v6 (animation-ready)
local Engine = {}

-- Utilities
local function clamp(val, min, max) return math.max(min, math.min(max, val)) end

-- Layer class
local Layer = {}
Layer.__index = Layer

function Layer:new(name, zIndex)
    return setmetatable({
        name = name or "Layer",
        zIndex = zIndex or 0,
        text = {},
        graphics = {},
        subwindows = {},
        visible = true
    }, self)
end

function Layer:addText(row, col, text, align)
    align = align or "left"
    local firstLine = true
    for line in text:gmatch("[^\n]+") do
        table.insert(self.text, {row=row, col=(firstLine and col or 1), text=line, align=align})
        row = row + 1
        firstLine = false
    end
end

function Layer:addGraphic(shape, params)
    params = params or {}
    params.char = params.char or (shape=="circle" and "O" or "#")
    params.transparent = params.transparent or false
    table.insert(self.graphics, {shape=shape, params=params})
end

function Layer:addSubWindow(subWin, x, y)
    table.insert(self.subwindows, {window=subWin, x=x, y=y})
end

function Layer:clear() self.text, self.graphics, self.subwindows = {}, {}, {} end
function Layer:setVisible(v) self.visible = v end

-- Window class
local Window = {}
Window.__index = Window

function Engine.newWindow(type, width, height)
    return setmetatable({type=type, width=width, height=height, layers={}}, Window)
end

function Window:addLayer(name, zIndex)
    local layer = Layer:new(name or "Layer"..(#self.layers+1), zIndex)
    table.insert(self.layers, layer)
    return layer
end

-- Canvas creation
local function createCanvas(width, height, bg) 
    bg = bg or " "
    local canvas = {}
    for r=1,height do
        canvas[r] = {}
        for c=1,width do canvas[r][c] = bg end
    end
    return canvas
end

-- Draw line helper
local function drawLine(canvas, x1,y1,x2,y2,char)
    local dx,dy = math.abs(x2-x1), math.abs(y2-y1)
    local sx,sy = x1<x2 and 1 or -1, y1<y2 and 1 or -1
    local err = dx-dy
    while true do
        if canvas[y1] and canvas[y1][x1] then canvas[y1][x1]=char end
        if x1==x2 and y1==y2 then break end
        local e2=2*err
        if e2>-dy then err=err-dy; x1=x1+sx end
        if e2<dx then err=err+dx; y1=y1+sy end
    end
end

-- Rendering engine
function Engine.renderWindowToCanvas(win)
    local canvas=createCanvas(win.width, win.height)
    table.sort(win.layers,function(a,b) return (a.zIndex or 0)<(b.zIndex or 0) end)
    for _,layer in ipairs(win.layers) do
        if layer.visible then
            -- graphics
            for _,g in ipairs(layer.graphics) do
                local s,p=g.shape,g.params
                if s=="box" then
                    local yEnd=clamp((p.y or 1)+(p.h or 1)-1,1,win.height)
                    local xEnd=clamp((p.x or 1)+(p.w or 1)-1,1,win.width)
                    for r=clamp(p.y or 1,1,win.height),yEnd do
                        for c=clamp(p.x or 1,1,win.width),xEnd do
                            if not p.transparent or canvas[r][c]==" " then canvas[r][c]=p.char end
                        end
                    end
                elseif s=="circle" then
                    local cx,cy,radius=p.x or 1,p.y or 1,p.radius or 1
                    for r=clamp(cy-radius,1,win.height),clamp(cy+radius,1,win.height) do
                        for c=clamp(cx-radius,1,win.width),clamp(cx+radius,1,win.width) do
                            local dx,dy=c-cx,r-cy
                            if dx*dx+dy*dy<=radius*radius then
                                if not p.transparent or canvas[r][c]==" " then canvas[r][c]=p.char end
                            end
                        end
                    end
                elseif s=="line" then
                    drawLine(canvas,clamp(p.x1,1,win.width),clamp(p.y1,1,win.height),
                                     clamp(p.x2,1,win.width),clamp(p.y2,1,win.height),
                                     p.char or "#")
                end
            end
            -- text
            for _,t in ipairs(layer.text) do
                local row,col=t.row,t.col
                local txt=t.text
                if t.align=="center" then col=math.floor((win.width-#txt)/2)+1
                elseif t.align=="right" then col=win.width-#txt+1 end
                for i=1,#txt do
                    local r,c=row,col+i-1
                    if r>=1 and r<=win.height and c>=1 and c<=win.width then
                        canvas[r][c]=txt:sub(i,i)
                    end
                end
            end
            -- subwindows
            for _,sw in ipairs(layer.subwindows) do
                local subCanvas=Engine.renderWindowToCanvas(sw.window)
                local offsetX,offsetY=sw.x or math.floor(win.width/2),sw.y or math.floor(win.height/2)
                local halfW,halfH=math.floor(sw.window.width/2),math.floor(sw.window.height/2)
                for r=1,#subCanvas do
                    for c=1,#subCanvas[r] do
                        local tr=r+offsetY-halfH
                        local tc=c+offsetX-halfW
                        if tr>=1 and tr<=win.height and tc>=1 and tc<=win.width then
                            canvas[tr][tc]=subCanvas[r][c]
                        end
                    end
                end
            end
        end
    end
    return canvas
end

-- Double-buffered terminal rendering
local previousCanvas = nil
function Engine.renderWindow(win)
    local canvas = Engine.renderWindowToCanvas(win)
    io.write("\27[H") -- cursor home

    for r=1,#canvas do
        local line = table.concat(canvas[r])
        if not previousCanvas or line ~= table.concat(previousCanvas[r]) then
            io.write("\27["..r..";1H"..line)
        end
    end

    previousCanvas = canvas
end

-- Optional render loop
function Engine.renderLoop(win,fps)
    fps=fps or 30
    local sleepTime=1/fps
    while true do
        Engine.renderWindow(win)
        os.execute("sleep "..sleepTime)
    end
end

return Engine
