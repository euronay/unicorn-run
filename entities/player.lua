local Class = require 'libs.hump.class'
local Entity = require 'entities.Entity'
local anim8 = require 'libs.anim8.anim8'

local player = Class{
  __includes = Entity -- Player class inherits our Entity class
}

function player:init(world, x, y)

  self.runImg = love.graphics.newImage('/assets/player-run.png')
  local g = anim8.newGrid(128, 128, self.runImg:getWidth(), self.runImg:getHeight())
  self.runAnim = anim8.newAnimation(g('1-6', 1), 0.1)


  Entity.init(self, world, x, y, 128, 128)

  -- Add our unique player values
  self.xVelocity = 0 -- current velocity on x, y axes
  self.yVelocity = 0
  self.acc = 100 -- the acceleration of our player
  self.maxSpeed = 200 -- the top speed
  self.friction = 20 -- slow our player down - we could toggle this situationally to create icy or slick platforms
  self.gravity = 200 -- we will accelerate towards the bottom

    -- These are values applying specifically to jumping
  self.isJumping = false -- are we in the process of jumping?
  self.isGrounded = false -- are we on the ground?
  self.hasReachedMax = false  -- is this as high as we can go?
  self.jumpAcc = 500 -- how fast do we accelerate towards the top
  self.jumpMaxSpeed = 11 -- our speed limit while jumping

  self.world:add(self, self:getRect())
end

function player:collisionFilter(other)
  -- local x, y, w, h = self.world:getRect(other)
  -- local playerBottom = self.y + self.h
  -- local otherBottom = y + h

  -- if playerBottom <= y then -- bottom of player collides with top of platform.
  --   return 'slide'
  -- end
  
  if other.properties.collidable then
    return 'slide'
  end

end

function player:update(dt)
  local prevX, prevY = self.x, self.y

  -- Apply Friction
  self.xVelocity = self.xVelocity * (1 - math.min(dt * self.friction, 1))
  self.yVelocity = self.yVelocity * (1 - math.min(dt * self.friction, 1))

  -- Apply gravity
  self.yVelocity = self.yVelocity + self.gravity * dt

	if love.keyboard.isDown("left", "a") and self.xVelocity > -self.maxSpeed then
		self.xVelocity = self.xVelocity - self.acc * dt
	elseif love.keyboard.isDown("right", "d") and self.xVelocity < self.maxSpeed then
		self.xVelocity = self.xVelocity + self.acc * dt
	end

  -- The Jump code gets a lttle bit crazy.  Bare with me.
  if love.keyboard.isDown("up", "w") then
    if -self.yVelocity < self.jumpMaxSpeed and not self.hasReachedMax then
      self.yVelocity = self.yVelocity - self.jumpAcc * dt
    elseif math.abs(self.yVelocity) > self.jumpMaxSpeed then
      self.hasReachedMax = true
    end

    self.isGrounded = false -- we are no longer in contact with the ground
  end

  -- these store the location the player will arrive at should
  local goalX = self.x + self.xVelocity
  local goalY = self.y + self.yVelocity

  -- Move the player while testing for collisions
  self.x, self.y, collisions, len = self.world:move(self, goalX, goalY, self.collisionFilter)

  -- Loop through those collisions to see if anything important is happening
  for i, coll in ipairs(collisions) do
    if coll.touch.y > goalY then  -- We touched below (remember that higher locations have lower y values) our intended target.
      self.hasReachedMax = true -- this scenario does not occur in this demo
      self.isGrounded = false
    elseif coll.normal.y < 0 then
      self.hasReachedMax = false
      self.isGrounded = true
    end
  end

  -- Update animation
  self.runAnim:update(dt)
end

function player:draw()
  self.runAnim:draw(self.runImg, self.x, self.y)
  --love.graphics.draw(self.img, self.x, self.y)
end

return player