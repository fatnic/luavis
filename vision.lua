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

    self.points = {}
    for _, segment in pairs(self.segments) do
        table.insert(self.points, segment.a)
    end

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
    for _, p in pairs(self.points) do
        love.graphics.points(p.x, p.y)
    end
end

local Vision = {}
Vision.__index = Vision

function Vision.new(walls)
    local self = setmetatable({}, Vision)

    self.walls = {}
    table.insert(self.walls, Wall.new(0, 0, love.graphics:getWidth(), love.graphics:getHeight()))
    for _, wall in pairs(walls) do 
        table.insert(self.walls, Wall.new(unpack(wall))) 
    end

    self.origin = { x = love.graphics:getWidth() / 2, y = love.graphics:getHeight() / 2 }

    return self
end

function Vision:update()
    local points = self:getPoints()
    local angles = self:calcAngles(points)
end

function Vision:getPoints()
    local points = {}    
    for _, wall in pairs(self.walls) do
        for _, point in pairs(wall.points) do
            table.insert(points, point)
        end
    end
    -- make unique
    local unique = {points[1]}
    for _, point in pairs(points) do
        local found = false
        for _, u in pairs(unique) do
            if point.x == u.x and point.y == u.y then 
                found = true
                break 
            end
        end
        if not found then table.insert(unique, point) end
    end
    return unique
end

function Vision:calcAngles(points)
    local angles = {}
    local precision = 0.00001
    for _, point in pairs(points) do
        local angle = math.atan2(point.y - self.origin.y, point.x - self.origin.x)
        print(angle)
    end
end

function Vision:setOrigin(x, y)
    self.origin.x, self.origin.y = x, y
end

-- DEBUG FUNCTIONS - DELETE
function Vision:drawOrigin()
    love.graphics.setColor(255, 255, 100)
    love.graphics.circle('fill', self.origin.x, self.origin.y, 3)
end

function Vision:drawWalls()
    for _, wall in pairs(self.walls) do wall:drawPoints() end
end
--

return Vision
