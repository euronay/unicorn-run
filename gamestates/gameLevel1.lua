-- Import our libraries.
local Gamestate = require 'libs.hump.gamestate'
local Class = require 'libs.hump.class'

-- Grab our base class
local levelBase = require 'gamestates.levelBase'

-- Import the Entities we will build.
local Player = require 'entities.player'
local camera = require 'libs.camera'

local Star = require 'entities.star'

-- Declare a couple immportant variables
player = nil

local gameLevel1 = Class{
  __includes = levelBase
}

function gameLevel1:init()
  levelBase.init(self, 'assets/levels/level1.lua')
end

function gameLevel1:enter()
  player = Player(self.world,  32, 64)
  levelBase.Entities:add(player)

  -- TODO move this logic to lavelBase
  -- load objects from map
  for _, layer in pairs(self.map.layers) do
    if layer.type == 'objectgroup' and layer.name == "Entities" then
      for _, object in ipairs( layer.objects ) do
        if object.type == "star" then
          local star = Star(self.world, object.x, object.y)
          levelBase.Entities:add(star)
        end
      end
    end
  end
end

function gameLevel1:update(dt)
  self.map:update(dt) -- remember, we inherited map from LevelBase
  levelBase.Entities:update(dt) -- this executes the update function for each individual Entity

  levelBase.positionCamera(self, player, camera)
end

function gameLevel1:draw()
  -- Attach the camera before drawing the entities
  camera:set()

  self.map:draw(-camera.x, -camera.y) -- Remember that we inherited map from LevelBase
  levelBase.Entities:draw() -- this executes the draw function for each individual Entity

  camera:unset()
  -- Be sure to detach after running to avoid weirdness
end

-- All levels will have a pause menu
function gameLevel1:keypressed(key)
  levelBase:keypressed(key)
end

return gameLevel1