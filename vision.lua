local tools = {}

tools.normaliseRadian = function(rad)
    local result = rad % (2 * math.pi)
    if result < 0 then result = result + (2 * math.pi) end
    return result
end

tools.vectorLength = function(vec)
    return math.sqrt(vec.x * vec.x + vec.y * vec.y)
end

tools.vectorNormalise = function(vec)
    local len = tools.vectorLength(vec)
    return { x = vec.x / len, y = vec.y / len }
end

tools.vectorMag = function(vec, mag)
    local v = tools.vectorNormalise(vec)
    return { x = v.x * mag, y = v.y * mag }
end

tools.vectorDistance = function(v1, v2)
    return tools.vectorLength({ x = v1.x - v2.x, y = v1.y - v2.y })
end

tools.doLinesIntersect = function( ray, segment )

        local a, b = ray.a, ray.b
        local c, d = segment.a, segment.b
        -- parameter conversion
        local L1 = {X1=a.x,Y1=a.y,X2=b.x,Y2=b.y}
        local L2 = {X1=c.x,Y1=c.y,X2=d.x,Y2=d.y}
        
        -- Denominator for ua and ub are the same, so store this calculation
        local d = (L2.Y2 - L2.Y1) * (L1.X2 - L1.X1) - (L2.X2 - L2.X1) * (L1.Y2 - L1.Y1)
        
        -- Make sure there is not a division by zero - this also indicates that the lines are parallel.
        -- If n_a and n_b were both equal to zero the lines would be on top of each
        -- other (coincidental).  This check is not done because it is not
        -- necessary for this implementation (the parallel check accounts for this).
        if (d == 0) then return false end
        
        -- n_a and n_b are calculated as seperate values for readability
        local n_a = (L2.X2 - L2.X1) * (L1.Y1 - L2.Y1) - (L2.Y2 - L2.Y1) * (L1.X1 - L2.X1)
        local n_b = (L1.X2 - L1.X1) * (L1.Y1 - L2.Y1) - (L1.Y2 - L1.Y1) * (L1.X1 - L2.X1)
        
        -- Calculate the intermediate fractional point that the lines potentially intersect.
        local ua = n_a / d
        local ub = n_b / d
        
        -- The fractional point will be between 0 and 1 inclusive if the lines
        -- intersect.  If the fractional calculation is larger than 1 or smaller
        -- than 0 the lines would need to be longer to intersect.
        if (ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1) then
                local x = L1.X1 + (ua * (L1.X2 - L1.X1))
                local y = L1.Y1 + (ua * (L1.Y2 - L1.Y1))
                return true, {x=x, y=y}
        end
        
        return false
end

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
    local rays = self:calcRays(angles)
    rays = self:calcIntersects(rays)
    table.sort(rays, function(a, b) return a.angle < b.angle end)
    local poly = {}
    for _, r in pairs(rays) do
        table.insert(poly, r.intersect.x)
        table.insert(poly, r.intersect.y)
    end
    love.graphics.polygon('line', poly)
end

function Vision:getPoints()
    -- TODO: Remove this first loop
    local points = {}    
    for _, wall in pairs(self.walls) do
        for _, point in pairs(wall.points) do
            table.insert(points, point)
        end
    end

    local unique = { points[1] }
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
    local precision = 0.0000001
    for _, point in pairs(points) do
        local angle = math.atan2(point.y - self.origin.y, point.x - self.origin.x)
        table.insert(angles, tools.normaliseRadian(angle) - precision)
        table.insert(angles, tools.normaliseRadian(angle))
        table.insert(angles, tools.normaliseRadian(angle) + precision)
    end
    return angles
end

function Vision:calcRays(angles)
    local rays = {}
    local maxLine = tools.vectorDistance({ x = 0, y = 0 }, { x = love.graphics.getWidth(), y = love.graphics.getHeight() })
    for _, angle in pairs(angles) do
        local r = { angle = angle, a = self.origin }
        local delta = { x = math.cos(angle), y = math.sin(angle) }
        local destination = tools.vectorMag(delta, maxLine)
        r.b = { x = self.origin.x + destination.x, y = self.origin.y + destination.y }
        table.insert(rays, r)
    end
    return rays
end

function Vision:calcIntersects(rays)
    local rt = {} 
    for _, ray in pairs(rays) do
        local closestIntersect = nil
        for _, wall in pairs(self.walls) do
            for _, segment in pairs(wall.segments) do
                local found, intersect = tools.doLinesIntersect(ray, segment)
                if found and not closestIntersect then 
                    closestIntersect = intersect 
                    break
                end
                if found and tools.vectorDistance(self.origin, intersect) < tools.vectorDistance(self.origin, closestIntersect) then
                    closestIntersect = intersect
                end
            end
        end
        ray.intersect = closestIntersect
        if ray.intersect then table.insert(rt, ray) end
    end
    return rt
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
    for _, wall in pairs(self.walls) do 
        wall:drawSegments()
        wall:drawPoints() 
    end
end
--

return Vision
