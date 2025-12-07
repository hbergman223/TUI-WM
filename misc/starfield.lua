local socket = require("socket")
local engine = require("window")

-- create main window
local win = engine.newWindow("starfield", 80, 24)

-- layers
local bg = win:addLayer("background")
local starsLayer = win:addLayer("stars")
local textLayer = win:addLayer("text", 10)

-- background
bg:addGraphic("box", {x=1, y=1, w=200, h=200, char=" "})

-- title text
textLayer:addText(1, 0, "STARFIELD", "center")

-- generate stars
local starCount = 75
local stars = {}
for i = 1, starCount do
    table.insert(stars, {
        x = math.random(1, 24),
        y = math.random(1, 80),
        speed = math.random(1, 3),
        char = (math.random() < 0.5) and "." or "*"
    })
end

-- hide cursor
io.write("\27[?25l")

-- safe animation loop
local ok, err = pcall(function()
    while true do
        starsLayer:clear()

        for _, star in ipairs(stars) do
            -- Move star
            star.x = star.x - star.speed * 0.2
            if star.x < 1 then
                star.x = 80
                star.y = math.random(1, 24)
                star.speed = math.random(1, 5)
                star.char = (math.random() < 0.5) and "." or "*"
            end
            starsLayer:addText(math.floor(star.y), math.floor(star.x), star.char)
        end

        engine.renderWindow(win)
        socket.sleep(0.01)
    end
end)

-- show cursor again on exit
io.write("\27[?25h")
if not ok then
    print("\nanimation stopped: " .. err)
end