local tools = {}

tools.normaliseRadian = function(rad)
    local result = rad % (2 * math.pi)
    if result < 0 then result = result + (2 * math.pi) end
    return result
end

tools.vectorLength = function(vec)
    return math.sqrt(vec.x * vec.x + vec.y * vec.y)
end

-- tools.vectorNormalise = function(vec)
--     local len = tools.vectorLength(vec)
--     return { x = vec.x / len, y = vec.y / len }
-- end

-- tools.vectorMag = function(vec, mag)
--     local v = tools.vectorNormalise(vec)
--     return { x = v.x * mag, y = v.y * mag }
-- end

tools.vectorDistance = function(v1, v2)
    return tools.vectorLength({ x = v1.x - v2.x, y = v1.y - v2.y })
end

tools.doLinesIntersect = function(ray, segment)
    local r_px, r_py = ray.a.x, ray.a.y
    local r_dx, r_dy = ray.b.x - ray.a.x, ray.b.y - ray.a.y

    local s_px, s_py = segment.a.x, segment.a.y
    local s_dx, s_dy = segment.b.x - segment.a.x, segment.b.y - segment.a.y

    local r_mag = math.sqrt(r_dx * r_dx + r_dy * r_dy)
    local s_mag = math.sqrt(s_dx * s_dx + s_dy * s_dy)
    if (r_dx / r_mag == s_dx / s_mag and r_dy / r_mag == s_dy / s_mag) then return false end

    local t2 = (r_dx * (s_py - r_py) + r_dy * (r_px - s_px)) / (s_dx * r_dy - s_dy * r_dx)
    local t1 = (s_px + s_dx * t2 - r_px) / r_dx;

    if (t1 < 0) then return false end
    if (t2 < 0 or t2 > 1) then return false end

    return true, { x = r_px + r_dx * t1, y = r_py + r_dy * t1, param = t1 }
end

-- tools.doLinesIntersect2 = function( ray, segment )

--     local a, b = ray.a, ray.b
--     local c, d = segment.a, segment.b

--     local L1 = {X1=a.x,Y1=a.y,X2=b.x,Y2=b.y}
--     local L2 = {X1=c.x,Y1=c.y,X2=d.x,Y2=d.y}

--     local d = (L2.Y2 - L2.Y1) * (L1.X2 - L1.X1) - (L2.X2 - L2.X1) * (L1.Y2 - L1.Y1)

--     if (d == 0) then return false end

--     local n_a = (L2.X2 - L2.X1) * (L1.Y1 - L2.Y1) - (L2.Y2 - L2.Y1) * (L1.X1 - L2.X1)
--     local n_b = (L1.X2 - L1.X1) * (L1.Y1 - L2.Y1) - (L1.Y2 - L1.Y1) * (L1.X1 - L2.X1)

--     local ua = n_a / d
--     local ub = n_b / d

--     if (ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1) then
--         local x = L1.X1 + (ua * (L1.X2 - L1.X1))
--         local y = L1.Y1 + (ua * (L1.Y2 - L1.Y1))
--         return true, {x=x, y=y}
--     end

--     return false
-- end

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
    -- local rays = self:calcRays(angles)
    local rays = {}
    for _, a in pairs(angles) do
        local ray = self:calcNearestIntersect(a)
        table.insert(rays, ray)
    end
    -- for _, ray in pairs(rays) do
    --     ray.intersect = self:calcNearestIntersect(ray)
    -- end
    -- table.sort(rays, function(a, b) return a.angle < b.angle end)

    -- for _, r in pairs(rays) do
    --     print(r.intersect.x, r.intersect.y)
    -- end
    -- os.exit()

    -- for _, ray in pairs(rays) do
    --     if ray.intersect.x < 0 or ray.intersect.x > love.graphics:getWidth() or ray.intersect.y < 0 or ray.intersect.y > love.graphics:getHeight() then
    --         love.graphics.setColor(155, 155, 20)
    --         love.graphics.line(ray.a.x, ray.a.y, ray.intersect.x, ray.intersect.y)
    --     end
    -- end

    local polygon = {}
    for _, ray in ipairs(rays) do
        table.insert(polygon, ray.intersect.x)
        table.insert(polygon, ray.intersect.y)
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

    -- local uniqueAngles = { rawAngles[1] }
    -- for _, a in pairs(rawAngles) do
    --     local found = false
    --     for _, u in pairs(uniqueAngles) do
    --         if u == a then
    --             found = true
    --             break
    --         end
    --     end
    --     if not found then table.insert(uniqueAngles, a) end
    -- end

    return rawAngles
end

-- function Vision:calcRays(angles)
--     local rays = {}
--     local maxRay = tools.vectorDistance({ x = 0, y = 0 }, { x = love.graphics:getWidth(), y = love.graphics:getHeight() }) + 2
--     for _, angle in pairs(angles) do
--         local ray = { a = self.origin, angle = angle }
--         ray.b = { x = self.origin.x + maxRay * math.cos(angle), y = self.origin.y + maxRay * math.sin(angle) }
--         table.insert(rays, ray)
--     end
--     return rays
-- end

function Vision:calcNearestIntersect(angle)
    local delta = { x = math.cos(angle), y = math.sin(angle) }
    local ray = { a = self.origin, b = { x = self.origin.x + delta.x, y = self.origin.y + delta.y } }

    local closestIntersect = nil

    for _, wall in pairs(self.walls) do
        for _, segment in pairs(wall.segments) do
            local found, intersection = tools.doLinesIntersect(ray, segment)
            if found then
                if not closestIntersect or intersection.param < closestIntersect.param then 
                    closestIntersect = intersection 
                end
            end
        end
    end

    ray.intersect = closestIntersect
    love.graphics.setColor(100, 140, 155)
    love.graphics.circle('line', ray.intersect.x, ray.intersect.y, 6)
    ray.angle = angle
    return ray
end

-- function Vision:calcNearestIntersect(ray)
--     local closestIntersect = ray.b
--     closestIntersect.distance = tools.vectorDistance(ray.a, ray.b)

--     for _, wall in pairs(self.walls) do
--         for _, segment in pairs(wall.segments) do
--             local found, intersect = tools.doLinesIntersect(ray, segment) 
--             if found then
--                 local distance = tools.vectorDistance(ray.a, intersect)
--                 if distance < closestIntersect.distance then
--                     closestIntersect = intersect
--                     closestIntersect.distance = distance
--                 end
--             end
--         end
--     end
--     -- debug
--     love.graphics.setColor(100, 140, 155)
--     love.graphics.circle('line', closestIntersect.x, closestIntersect.y, 6)
--     return closestIntersect
-- end

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
