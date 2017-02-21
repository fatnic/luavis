Vision = require 'vision'

walls = {
    {20,20,200,40}, 
    {220,520,200,40},
}

function love.load()
    vision = Vision.new(walls)
    vision:update()
end

function love.update(dt)
end

function love.draw()
    -- vision:drawOrigin()
    vision:drawWalls()
end
