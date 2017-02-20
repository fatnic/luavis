Vision = require 'vision'

walls = {
    {20,20,200,40}, 
    {500,20,200,40},
}

function love.load()
    vision = Vision.new(walls)
    vision:setOrigin(100, 100)
end

function love.update(dt)

end

function love.draw()
    vision:drawOrigin()
    vision:drawWalls()
end
