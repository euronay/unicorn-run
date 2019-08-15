local Class = require 'libs.hump.class'
local Entity = require 'entities.entity'
local anim8 = require 'libs.anim8.anim8'
local states = require 'libs.states'

local player = Class{
  __includes = Entity -- Player class inherits our Entity class
}

function player:init(world, x, y)

  self.images = {}
  self.images.standing = love.graphics.newImage('/assets/player-idle.png')
  self.images.running = love.graphics.newImage('/assets/player-run.png')
  self.images.jumping = self.images.running
  self.images.falling = self.images.running
  
  local g = anim8.newGrid(128, 128, 768, 128) -- animation for 6 frame caharcter sprite
  self.rightAnim = anim8.newAnimation(g('1-6', 1), 0.1)
  self.leftAnim = self.rightAnim:clone():flipH()


  Entity.init(self, world, x, y, 128, 128)

  -- Add our unique player values
  self.xVelocity = 0 -- current velocity on x, y axes
  self.yVelocity = 0
  self.acc = 200 -- the acceleration of our player
  self.maxSpeed = 500 -- the top speed
  self.friction = 20 -- slow our player down - we could toggle this situationally to create icy or slick platforms
  self.gravity = 250 -- we will accelerate towards the bottom

    -- These are values applying specifically to jumping
  self.isJumping = false -- are we in the process of jumping?
  self.isGrounded = false -- are we on the ground?
  self.hasReachedMax = false  -- is this as high as we can go?
  self.jumpTimerMax = 0.3
  self.jumpTimer = self.jumpTimerMax
  self.jumpAcc = 750 -- how fast do we accelerate towards the top
  self.jumpMaxSpeed = 8.5 -- our speed limit while jumping

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
  local wasJumping = self.isJumping
  local wasGrounded = self.isGrounded
  local hadReachedMax = self.hasReachedMax

  -- Apply Friction
  self.xVelocity = self.xVelocity * (1 - math.min(dt * self.friction, 1))
  self.yVelocity = self.yVelocity * (1 - math.min(dt * self.friction, 1))

  -- Apply gravity
  self.yVelocity = self.yVelocity + self.gravity * dt

	if love.keyboard.isDown("left", "a") and self.xVelocity > -self.maxSpeed then
    self.xVelocity = self.xVelocity - self.acc * dt
    self:message("move")
	elseif love.keyboard.isDown("right", "d") and self.xVelocity < self.maxSpeed then
    self.xVelocity = self.xVelocity + self.acc * dt
    self:message("move")
  else
    self:message("stop")
	end

  --Jump code
  self.jumpTimer = self.jumpTimer - (1 * dt)
  if love.keyboard.isDown("up", "w") then

    if not self.isJumping and self.isGrounded then -- Starting the jump
      self.isJumping = true
      self.isGrounded = false
      self.yVelocity = self.yVelocity - self.jumpAcc * dt
      self.jumpTimer = self.jumpTimerMax
      self:message("jump")
    elseif self.jumpTimer > 0 and self.isJumping then -- Still jumping but have not hit timer
      print(2 .. "timer: " .. self.jumpTimer)
      self.yVelocity = self.yVelocity - self.jumpAcc * dt
    elseif self.isJumping and self.yVelocity < 0 then -- Jump timer has run out, so slow down
      self.yVelocity = self.yVelocity + self.jumpAcc * dt
    elseif self.isJumping then -- We've stopped, so stop jumping and let gravity take us down
      self.isJumping = false
      self:message("hitroof")
    end
  end


  -- these store the location the player will arrive at should
  local xTarget = self.x + self.xVelocity
  local yTarget = self.y + self.yVelocity

  -- Move the player while testing for collisions
  self.x, self.y, collisions, len = self.world:move(self, xTarget, yTarget, self.collisionFilter)

  self.isGrounded = false
  -- Loop through those collisions to see if anything important is happening
  for i, coll in ipairs(collisions) do
    if coll.touch.y > yTarget then  -- We touched below (remember that higher locations have lower y values) our intended target.
      self.hasReachedMax = true -- this scenario does not occur in this demo
      self.isGrounded = false
      self:message("hitroof")
    elseif coll.normal.y < 0 then
      self.hasReachedMax = false
      self.isGrounded = true
      self:message("hitground")
    end
  end

  -- Update states - from https://2dengine.com/?p=fsm
  -- if self.isGrounded and not wasGrounded then
  --   self:message("hitground")
  -- end
  -- if not self.isGrounded and wasGrounded then
  --   self:message("fall")
  -- end
  -- if self.hasReachedMax and not hadReachedMax then
  --   self:message("hitroof")
  -- end
  -- -- if self.isJumping and not wasJumping then
  -- --   self:message("jump")
  -- -- end
  -- if self.xVelocity ~= 0 then
  --   self:message("move")
  -- end
  -- if self.yVelocity < 0 then
  --   self:message("jump")
  -- end
  -- if self.xVelocity == 0 then
  --   self:message("stop")
  -- end

  self:updateState(dt)

  -- Update animation
  self.rightAnim:update(dt)
  self.leftAnim:update(dt)
end

function player:draw()
  if self.xVelocity < 0 then
    self.leftAnim:draw(self.images[self.state], self.x, self.y)
  else
    self.rightAnim:draw(self.images[self.state], self.x, self.y)
  end
  --love.graphics.draw(self.img, self.x, self.y)
end

return player