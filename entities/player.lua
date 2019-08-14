local Class = require 'libs.hump.class'
local Entity = require 'entities.Entity'
local anim8 = require 'libs.anim8.anim8'
local states = require 'libs.states'

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
  self.jumpTimerMax = 0.8
  self.jumpTimer = self.jumpTimerMax
  self.jumpAcc = 500 -- how fast do we accelerate towards the top
  self.jumpMaxSpeed = 1000 -- our speed limit while jumping

  -- State
  self.state = "falling"
  self.elapsed = 0

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

function player:setState(state, ...)
  assert(states[state], "invalid state")

  -- Exit previous state
  if states[self.state].exit then
    states[self.state]:exit(self)
  end

  self.state = state
  self.elapsed = 0

  -- Enter next state
  if states[self.state].enter then
    states[self.state]:enter(self, ...)
  end
end

function player:updateState(dt)
  self.elapsed = self.elapsed + dt;
  if states[self.state].update then
    states[self.state]:update(self, dt)
  end
end

function player:message(event, ...)
  print("called message with self " .. self.state .. " event " .. event)
  if states[self.state].message then
    states[self.state]:message(self, event, ...)
  end
end

function player:update(dt)
  local prevX, prevY = self.x, self.y
  local wasGrounded = self.isGrounded
  local hadReachedMax = self.hasReachedMax

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
    if self.yVelocity < self.jumpMaxSpeed and not self.hasReachedMax then
      --print("jumping vel:" .. self.yVelocity .. " max:" .. self.jumpMaxSpeed .. " reached: " .. tostring(self.hasReachedMax))
      self.yVelocity = self.yVelocity - self.jumpAcc * dt
    elseif math.abs(self.yVelocity) > self.jumpMaxSpeed then
      --print("reached max vel:" .. self.yVelocity .. " max:" .. self.jumpMaxSpeed .. " reached: " .. tostring(self.hasReachedMax))
      self.yVelocity = 0
      self.hasReachedMax = true
    end
  
    self.isGrounded = false -- we are no longer in contact with the ground
  end


  -- self.jumpTimer = self.jumpTimer - (1 * dt)
  -- if love.keyboard.isDown("up", "w") and not self.isJumping and self.isGrounded then -- when the player hits jump
  --   self.isJumping = true
  --   self.isGrounded = false
  --   self.yVelocity = -self.jumpAcc * dt
  --   jumpTimer = jumpTimerMax
  -- elseif love.keyboard.isDown("up", "w") and self.jumpTimer > 0 and self.isJumping then
  --   self.yVelocity = self.yVelocity + -self.jumpAcc * dt
  -- elseif not love.keyboard.isDown("up", "w") and self.isJumping then -- if the player releases the jump button mid-jump...
  --   if self.yVelocity < self.jumpMaxSpeed then -- and if the player's velocity has reached the minimum velocity (minimum jump height)...
  --     self.yVelocity = self.jumpMaxSpeed -- terminate the jump
  --   end
  --   self.isJumping = false
  --   self.jumpTimer = self.jumpTimerMax
  -- end

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

  -- Update states - from https://2dengine.com/?p=fsm
  if self.isGrounded and not wasGrounded then
    self:message("hitground")
  end
  if not self.isGrounded and wasGrounded then
    self:message("fall")
  end
  if self.hasReachedMax and not hadReachedMax then
    self:message("hitroof")
  end
  if self.xVelocity ~= 0 then
    self:message("move")
  end
  if self.yVelocity < 0 then
    self:message("jump")
  end
  if self.xVelocity == 0 then
    self:message("stop")
  end

  self:updateState(dt)

  -- Update animation
  self.runAnim:update(dt)
end

function player:draw()
  self.runAnim:draw(self.runImg, self.x, self.y)
  --love.graphics.draw(self.img, self.x, self.y)
end

return player