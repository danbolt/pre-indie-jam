-- 2D Collision-detection library
local bump = require 'lib.bump'
local Camera = require 'lib.Camera'
local tween = require 'lib.tween'
local Gamestate = require 'lib.gamestate'
local endscreen = require 'scenes.endscreen'

local endbox = require 'endbox'
local mapdata = require 'mapdata'
local player = require 'player'
local world = nil
local currentMap = 'red' 
local currentWalls = {}
local font = love.graphics.newFont("asset/fonts/Sniglet-Regular.ttf", 35)

local levelLogic = {}
local levels = { 'tutorial', 'level1', 'level2', 'level3', 'level4' }
local currentLevel = 1

local src = love.audio.newSource('asset/bgm/roots.mp3', 'stream')

local t = nil
local text = {x = 0, y = 7 * 32, alp = 0, fadeIn = false}

-- image data
local imageData = { redSquare = nil }

local function getCurrentColour(currentMap)
  if currentMap == 'red' then
    return 0.87058,0.14117,0.41568,0.89411,0.28235,0.50980
  elseif currentMap == 'blue' then
    return 0.24705,0.68235,0.98823,0.57647,0.82352,1
  elseif currentMap == 'yellow' then
    return 0.59215,0.34509,0.76078,0.72156,0.50980,0.86666
  elseif currentMap == 'green' then
    return 0.22745,0.96078,0.62745,0.41960,0.97254,0.71764
  end
end

local function getCurrentBackgroundColour(currentMap)
  if currentMap == 'red' then
    return 1,0.62745,0.62745
  elseif currentMap == 'blue' then
    return 0.77254,0.90588,1
  elseif currentMap == 'yellow' then
    return 0.78431,0.60392,0.90588
  elseif currentMap == 'green' then
    return 0.61176,0.98431,0.81568
  end
end

local function renderMap(currentMap,nextMap)
  love.graphics.setColor(1,1,1,1)
  r,g,b,r2,g2,b2 = getCurrentColour(currentMap)
  rb, gb, bb = getCurrentBackgroundColour(currentMap)
  for mapx=1,mapdata.getMapWidth(nextMap) do
    for mapy=1,mapdata.getMapHeight(nextMap) do
     local tile = mapdata.getTileAt(nextMap, mapx, mapy)
      if tile == true then
        love.graphics.setColor(r2,g2,b2,1)
        love.graphics.rectangle("fill", mapx*32, mapy*32,32,32)
      end
     end
   end  
  for mapx=1,mapdata.getMapWidth(currentMap) do
    for mapy=1,mapdata.getMapHeight(currentMap) do
     local tile = mapdata.getTileAt(currentMap, mapx, mapy)
      if tile == true then
        love.graphics.setBackgroundColor(rb,gb,bb)
        love.graphics.setColor(r,g,b,1)
        love.graphics.rectangle("fill", mapx*32, mapy*32,32,32) 
      end
     end
   end
 end
 
 local function addWalls()
  for mapx=1,(mapdata.getMapWidth(currentMap)) do
    for mapy=1,mapdata.getMapHeight(currentMap) do
     local tile = mapdata.getTileAt(currentMap, mapx, mapy)
     if tile == true then 
       local wall = {x= mapx*32, y= mapy*32, w=32, h=32}
       world:add(wall, wall.x, wall.y, wall.w, wall.h)
       table.insert(currentWalls, wall)
    end
   end
 end
end
 
 local function removeMap()
  for i=1, #currentWalls do
    local wall = currentWalls[i]
    world:remove(wall)
  end
  currentWalls = {}
 end
   
   local function nextMap(prevMap)
    if prevMap == 'red' then
     return 'blue'
    elseif prevMap == 'blue' then
      return 'yellow'
    elseif prevMap == 'yellow' then
      return 'green'
    elseif prevMap == 'green' then
      return 'red'
    end
  end  
 
 local function switchMap()
   removeMap()
   currentMap = nextMap(currentMap)
   addWalls()
  end

local function isInWall(map, x, y)
  local playerTileX = math.floor(x / 32)
  local playerTileY = math.floor(y /32)
  
  return mapdata.getTileAt(map, playerTileX, playerTileY)
end

function levelLogic:enter()
  imageData.redSquare = love.graphics.newImage('asset/img/square_red.png')
  imageData.blueSquare = love.graphics.newImage('asset/img/square_blue.png')
  imageData.greenSquare = love.graphics.newImage('asset/img/square_green.png')
  imageData.yellowSquare = love.graphics.newImage('asset/img/square_yellow.png')
  
  imageData.piggySheet = love.graphics.newImage('asset/img/piggysheet.png')
  src:setLooping(true)
  src:play()
  
  love.graphics.setFont(font)
  
  camera = Camera()
  camera:setDeadzone(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, 0, 0)
  camera:setFollowLerp(0.2)
  
  player.spriteSheet = imageData.piggySheet
  
  mapdata.loadLevel(levels[currentLevel])
  
  world = bump.newWorld()
  local wallOfDeath = {x=0,y=0,w=32,h=32*15}
  world:add(wallOfDeath, wallOfDeath.x, wallOfDeath.y, wallOfDeath.w, wallOfDeath.h)
  world:add(player, player.x, player.y, player.w, player.h)
  world:add(endbox, endbox.x, endbox.y, endbox.w, endbox.h)
  addWalls()

end

local function nextLevel()
  world:remove(player)
  removeMap()
  currentMap = 'red'
  player.resetPlayer()
       
  currentLevel = currentLevel + 1
  if currentLevel > #levels then
    src:stop()
    currentLevel = 1    
    Gamestate.switch(endscreen)
  else
    Gamestate.switch(levelLogic)
  end
end
      

local function checkCollisions(dx,dy)
  deltaX, deltaY, collisions, numberofcollisions = world:move(player, player.x + dx, player.y + dy)
    player.x = deltaX
    player.y = deltaY 
    for i=1, numberofcollisions do
      local collision = collisions[i]
      if collision.other == endbox then
        nextLevel()
      end
    end
  end
  

function levelLogic:update(dt)
  local dx, dy = player.updatePlayer(dt) 
    
    camera:update(dt)
    camera:follow(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    
    checkCollisions(dx,dy)
    if t ~= nil then
      local completed = t:update(dt)
      if completed and text.fadeIn then
        t = tween.new(1, text, {alp=0}, 'linear')
        text.fadeIn = false
      end
    end    
end

function levelLogic:draw()
  
  camera:attach()
  renderMap(currentMap, nextMap(currentMap))
  love.graphics.setColor(1,1,1)
  player.drawPlayer()
  endbox.draw()
  love.graphics.setColor(1, 1, 1, text.alp)
  
  love.graphics.printf("Careful where you press the spacebar!", text.x, text.y, love.graphics.getWidth(), 'center')
  
  camera:detach()
  
end


local function tryToSwitchMap()
  playerTopLeft = isInWall(nextMap(currentMap), player.x + 0.5, player.y + 0.5)
  playerTopRight = isInWall(nextMap(currentMap), (player.x + player.w) - 0.5, player.y + 0.5)
  playerBottomLeft = isInWall(nextMap(currentMap), player.x + 0.5, (player.y + player.h) - 0.5)
  playerBottomRight = isInWall(nextMap(currentMap), (player.x + player.w) - 0.5, (player.y + player.h) - 0.5)
  if not (playerTopLeft or playerTopRight or playerBottomLeft or playerBottomRight) then
    switchMap()
  else
    camera:shake(3.5, 1, 60)
    if currentLevel == 1 then
      t = tween.new(2, text, {alp=1}, 'linear')
      text.fadeIn = true
    end      
  end
end

function levelLogic:keypressed(key)
  if key == "space" then
    tryToSwitchMap()
  end
end

function levelLogic:joystickpressed( joystick, button )
  if button == 1 then
    tryToSwitchMap()
  end
end

return levelLogic