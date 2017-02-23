Vision = require 'vision'

walls = {
    {50,50,200,40}, 
    {220,520,200,40},
    {500, 200, 75, 75},
}

function love.load()
    vision = Vision.new(walls)
end

function love.update(dt)
end

function love.draw()
    vision:update()
    vision:drawOrigin()
    vision:drawWalls()
end

function love.mousemoved(x, y)
    vision:setOrigin(x, y)
end
