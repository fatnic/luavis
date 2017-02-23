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

    local L1 = {X1=a.x,Y1=a.y,X2=b.x,Y2=b.y}
    local L2 = {X1=c.x,Y1=c.y,X2=d.x,Y2=d.y}

    local d = (L2.Y2 - L2.Y1) * (L1.X2 - L1.X1) - (L2.X2 - L2.X1) * (L1.Y2 - L1.Y1)

    if (d == 0) then return false end

    local n_a = (L2.X2 - L2.X1) * (L1.Y1 - L2.Y1) - (L2.Y2 - L2.Y1) * (L1.X1 - L2.X1)
    local n_b = (L1.X2 - L1.X1) * (L1.Y1 - L2.Y1) - (L1.Y2 - L1.Y1) * (L1.X1 - L2.X1)

    local ua = n_a / d
    local ub = n_b / d

    if (ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1) then
        local x = L1.X1 + (ua * (L1.X2 - L1.X1))
        local y = L1.Y1 + (ua * (L1.Y2 - L1.Y1))
        return true, {x=x, y=y}
    end

    return false
end

Wall = {}
function Wall.new(x, y, w, h)
    wall = {}

    wall.position = { x = x, y = y }
    wall.dimensions = { w = w, h = h }

    wall.segments = {}
    table.insert(wall.segments, { a = { x = x, y = y }, b = { x = x + w, y = y } })
    table.insert(wall.segments, { a = { x = x + w, y = y }, b = { x = x + w, y = y + h } })
    table.insert(wall.segments, { a = { x = x + w, y = y + h }, b = { x = x, y = y + h } })
    table.insert(wall.segments, { a = { x = x, y = y + h }, b = { x = x, y = y } })

    wall.points = {}
    for _, segment in pairs(wall.segments) do
        table.insert(wall.points, segment.a)
    end

    return wall
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
    local angles = self:calcAngles()
    local rays = self:calcRays(angles)
    for _, ray in pairs(rays) do
        ray.intersect = self:calcNearestIntersect(ray)
    end
    table.sort(rays, function(a, b) return a.angle < b.angle end)

    local polygon = {}
    for _, ray in ipairs(rays) do
        table.insert(polygon, ray.intersect.x)
        table.insert(polygon, ray.intersect.y)
        print(ray.intersect.x, ray.intersect.y)
    end

    love.graphics.setColor(255, 255, 255, 30)
    love.graphics.polygon('fill', polygon)

end

function Vision:calcAngles()
    local rawAngles = {}
    local precision = 0.0000001

    for _, wall in pairs(self.walls) do
        for _, point in pairs(wall.points) do
            local angle = math.atan2(point.y - self.origin.y, point.x - self.origin.x)
            table.insert(rawAngles, tools.normaliseRadian(angle - precision))
            table.insert(rawAngles, tools.normaliseRadian(angle))
            table.insert(rawAngles, tools.normaliseRadian(angle + precision))
        end
    end

    local uniqueAngles = { rawAngles[1] }
    for _, a in pairs(rawAngles) do
        local found = false
        for _, u in pairs(uniqueAngles) do
            if u == a then
                found = true
                break
            end
        end
        if not found then table.insert(uniqueAngles, a) end
    end

    return uniqueAngles
end

function Vision:calcRays(angles)
    local rays = {}
    local maxRay = tools.vectorDistance({ x = 0, y = 0 }, { x = love.graphics:getWidth(), y = love.graphics:getHeight() })
    for _, angle in pairs(angles) do
        local ray = { a = self.origin, angle = angle }
        local delta = { x = math.cos(angle), y = math.sin(angle) }
        local magDelta = tools.vectorMag(delta, maxRay)
        ray.b = { x = self.origin.x + magDelta.x, y = self.origin.y + magDelta.y }
        table.insert(rays, ray)
    end
    return rays
end

function Vision:calcNearestIntersect(ray)
    local closestIntersect = ray.b
    closestIntersect.distance = tools.vectorDistance(ray.a, ray.b)

    for _, wall in pairs(self.walls) do
        for _, segment in pairs(wall.segments) do
            local found, intersect = tools.doLinesIntersect(ray, segment) 
            if found then
                local distance = tools.vectorDistance(ray.a, intersect)
                if distance < closestIntersect.distance then
                    closestIntersect = intersect
                    closestIntersect.distance = distance
                end
            end
        end
    end
    -- debug
    -- love.graphics.setColor(100, 140, 155)
    -- love.graphics.circle('line', closestIntersect.x, closestIntersect.y, 3)
    return closestIntersect
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
        love.graphics.setColor(0, 0, 155)
        for _, segment in pairs(wall.segments) do
            love.graphics.line(segment.a.x, segment.a.y, segment.b.x, segment.b.y)
        end
        love.graphics.setColor(150, 150, 0)
        for _, point in pairs(wall.points) do
            love.graphics.circle('fill', point.x, point.y, 1)
        end
    end
end
--

return Vision
