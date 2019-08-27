local Class = require "libs.hump.class"
local Entity = require "entities.entity"

local star =
    Class {
    __includes = Entity
}

function star:init(world, x, y)
    self.image = love.graphics.newImage("/assets/star.png")
    self.properties = {
        collidable = false,
        name = "star"
    }    

    Entity.init(self, world, x - (self.image:getWidth() / 2), y - (self.image:getHeight() / 2), self.image:getWidth(), self.image:getHeight())

    self.elapsed = 0
    self.anchorY = y

    self.world:add(self, self:getRect())
end

function star:update(dt)
    -- bounces the start up and down
    self.elapsed = self.elapsed + 2.5 * dt
    self.y = self.anchorY + math.cos(self.elapsed) * 10
end

function star:draw()
    love.graphics.draw(self.image, self.x, self.y)
end

return star
