Vision = require 'vision'

walls = {
    {20,20,200,40}, 
    {220,520,200,40},
}

function love.load()
    vision = Vision.new(walls)
end

function love.update(dt)
    vision:setOrigin(love.mouse:getX(), love.mouse:getY())
end

function love.draw()
    vision:update()
    vision:drawOrigin()
    vision:drawWalls()
end
