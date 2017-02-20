local Wall = {}
Wall.__index = Wall

function Wall.new(x, y, w, h)
    local self = setmetatable({}, Wall)

    self.position = {  x = x, y = y }
    self.dimensions = { w = w, h = h }

    self.segments = {}
    table.insert(self.segments, { a = { x = x, y = y }, b = { x = x + w, y = y } })
    table.insert(self.segments, { a = { x = x + w, y = y }, b = { x = x + w, y = y + h } })
    table.insert(self.segments, { a = { x = x + w, y = y + h }, b = { x = x, y = y + h } })
    table.insert(self.segments, { a = { x = x, y = y + h }, b = { x = x, y = y } })

    return self
end

function Wall:draw()
    love.graphics.setColor(0, 155, 0)
    love.graphics.rectangle('fill', self.position.x, self.position.y, self.dimensions.w, self.dimensions.h)
end

function Wall:drawSegments()
    love.graphics.setColor(0, 0, 155)
    for _, s in pairs(self.segments) do
        love.graphics.line(s.a.x, s.a.y, s.b.x, s.b.y)
    end
end

function Wall:drawPoints()
    love.graphics.setColor(255, 255, 100)
    for _, s in pairs(self.segments) do
        love.graphics.points(s.a.x, s.a.y)
    end
end

local Vision = {}
Vision.__index = Vision

function Vision.new(walls)
    local self = setmetatable({}, Vision)

    self.walls = {}
    for _, wall in pairs(walls) do table.insert(self.walls, Wall.new(wall[1], wall[2], wall[3], wall[4])) end

    self.origin = { x = love.graphics:getWidth() / 2, y = love.graphics:getHeight() / 2 }

    return self
end

-- DEBUG FUNCTIONS - DELETE
function Vision:drawWalls()
    for _, wall in pairs(self.walls) do wall:draw() end
end

return Vision
