Vision = require 'vision'

walls = {
    {20,20,200,40}, 
    {500,20,200,40},
}

function love.load()
    vision = Vision.new(walls)
end

function love.update(dt)

end

function love.draw()
    love.graphics.setColor(255, 255, 100)
    love.graphics.circle('fill', vision.origin.x, vision.origin.y, 3)
    vision:draw()
end
