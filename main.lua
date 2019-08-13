-- Pull in Gamestate from the HUMP library
Gamestate = require 'libs.hump.gamestate'

-- Pull in each of our game states
local mainMenu = require 'gamestates.mainMenu'
local gameLevel1 = require 'gamestates.gameLevel1'
local pause = require 'gamestates.pause'

function love.load()
  love.graphics.setBackgroundColor(1,1,1,1)
  Gamestate.registerEvents()
  Gamestate.switch(gameLevel1)
end
