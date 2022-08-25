-- http://localhost:5500/Inside%20Playdate.html#basic-playdate-game
-- good tutorial on how to setup a playdate sprite with movement here

-- -- --
--
-- Globals
--
-- -- --

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/animation"

-- import 'CoreLibs/input' -- todo: not sure what this module does

gfx = playdate.graphics -- playdate.graphics alias 
gfx.setBackgroundColor(gfx.kColorBlack)

font = gfx.font.new('images/font/whiteglove-stroked') -- borrowed from Examples/2020

local notice = 'default notice' -- notice is used for debugging crank information
crankChange = 0

-- -- --
-- 
-- Background Sprites
--
-- -- -- 

local backgroundX = 0 -- used to calculate background wrapping behaviour
local backgroundWidth = 0 -- used for both backgrounds
local backgroundWallY = 0 -- holds y coordinate for upperleft pixel of backgroundWall
local backgroundWallYOffset = 0 -- used to derive offset of backgroundWallY when jumping
foregroundSpriteYOffset = 0

local function createBackgroundSprites()

	local backgroundFloor = gfx.sprite.new()
	local backgroundFloorImage = gfx.image.new('images/backgroundFloor.png')
	local width, height = backgroundFloorImage:getSize()
	backgroundWidth = width -- use this for both background images
	backgroundFloor:setBounds(0, 0, 400, 240)
    -- If an image is attached to the sprite, 
    -- the size will be defined by that image, 
    -- and not by the width and height parameters passed in to setBounds().
    -- http://localhost:5500/Inside%20Playdate.html#m-graphics.sprite.setBounds

    local backgroundWall = gfx.sprite.new()
    local backgroundWallImage = gfx.image.new('images/backgroundWall.png')
    local width, height = backgroundWallImage:getSize()
    assert(height == 331)
    backgroundWallY = 100 - height -- should be -231 on init
    backgroundWall:setBounds(0, 0, 400, 240)
    
    


	function backgroundFloor:draw(x, y, width, height)
		backgroundFloorImage:draw(backgroundX, 0 + backgroundWallYOffset)
        if backgroundX < 0 then 
            backgroundFloorImage:draw(backgroundX+backgroundWidth, 0 + backgroundWallYOffset)
        else
		    backgroundFloorImage:draw(backgroundX-backgroundWidth, 0 + backgroundWallYOffset)
        end
	end

    function backgroundWall:draw(x, y, width, height)
        backgroundWallImage:draw(backgroundX, backgroundWallY + backgroundWallYOffset)
        if backgroundX < 0 then 
            backgroundWallImage:draw(backgroundX+backgroundWidth, backgroundWallY + backgroundWallYOffset)
        else
		    backgroundWallImage:draw(backgroundX-backgroundWidth, backgroundWallY + backgroundWallYOffset)
        end
    end

	function backgroundFloor:update()
        if backgroundX > backgroundWidth then
            backgroundX = 0
        elseif backgroundX < -400 then
            backgroundX = 0
        end

        self:markDirty()  
	end

    function backgroundWall:update()
        self:markDirty()  -- todo: is this necessary?
	end

    backgroundWall:setZIndex(1)
	backgroundWall:add()

	backgroundFloor:setZIndex(0)
	backgroundFloor:add()
    
end

createBackgroundSprites()


-- -- -- 
--
-- Handle Enemy Sprites
--
-- -- --

local maxEnemies = 10
local enemyCount = 0

maxBackgroundSprites = 4
local pooSpriteCount = 0

local player = nil

local score = 0

local explosionImages = {}
for i = 1, 8 do
	explosionImages[i] = gfx.image.new('images/x/'..i)
end

function createExplosion(x, y)

	local s = gfx.sprite.new()
    s.isExplosion = true
	s.frame = 1
	local img = gfx.image.new('images/explosion/'..s.frame)
	s:setImage(img)
	s:moveTo(x, y)

	function s:update()
        if dead ~= true then
            s.frame += 1
            if s.frame > 11 then
                s:remove()
            else
                local img = gfx.image.new('images/explosion/'..s.frame)
                s:setImage(img)
            end
        end
	end

	s:setZIndex(2000)
	s:add()

end


local function destroyPoo(poo)

	createExplosion(poo.x, poo.y)
	poo:remove()
	pooSpriteCount -= 1
end

local function createPoo()

	local poo = gfx.sprite.new()

	local pooImg

	pooImg = gfx.image.new('images/poo')

	local w, h = pooImg:getSize()
	poo:setImage(pooImg)
    poo:setCollideRect(0, 0, w, h)
    ---
    -- The base of the player sprite at rest is 170 pixels
	poo:moveTo(400 + h, math.random(170)) --todo: randomize on floor or in air more distinctly
	poo:add()

    poo.isEnemy = true

	pooSpriteCount += 1

    function poo:collisionResponse(other)
		return gfx.sprite.kCollisionTypeOverlap
	end

	function poo:update()

		local newX = poo.x
        
        if crankChange >= 1 then
            newX -= 6
        elseif crankChange <= -1 then
            newX -= 4
        elseif crankChange == 0 then
            newX -= 4
        end

		if newX < 0 - h then
            score += 1
			poo:remove()
			pooSpriteCount -= 1
        else
            poo:moveTo(newX, poo.y - foregroundSpriteYOffset)
		end
	end


	poo:setZIndex(100)
	return poo
end



local function spawnPooIfNeeded()
	if pooSpriteCount < maxBackgroundSprites then
		if math.random(math.floor(120/maxBackgroundSprites)) == 1 then
			createPoo()
		end
	end
end

-- -- --
--
-- Pickup Sprites
-- 
-- -- --

import "pickups"

-- -- --
-- 
-- Player Sprite
-- 
-- -- --

local playerSprite = nil
local playerYResting = 120 -- reseting location of sprite's top
local playerYCurrent = playerYResting -- initialize sprite at resting location of sprite

local function updatePlayerHealth(action)
    if action == "damage" and playerHealth ~= 4 then
        playerHealth += 1
    else 
        handleDeath()
    end

end

function playerSpriteSetUp()

    -- Set up the player sprite.
    -- The :setCenter() call specifies that the sprite will be anchored at its center.
    -- The :moveTo() call moves our sprite to the center of the display.

    local playerImage = gfx.image.new('/images/player/player-run-1')
    assert( playerImage ) -- make sure the image was where we thought
    
    local w, h = playerImage:getSize()
    
    playerSprite = gfx.sprite.new( playerImage )
    playerSprite.isPlayer = true
    playerSprite.frame = 1

    playerSprite:setCollideRect(0, 0, w, h)
    playerSprite:moveTo( 200, playerYCurrent ) -- this is where the center of the sprite is placed; (200,120) is the center of the Playdate screen
    playerSprite:add() -- This is critical!

    function playerSprite:collisionResponse(other)
		return gfx.sprite.kCollisionTypeOverlap
	end

	function playerSprite:update()

		local dx = 0
		local dy = 0

        if dead ~= true then
            if playerIsJumping ~= true and playerIsFalling ~= true then -- these two states signal if the player is on the ground
                if playerSprite.frame < 13 then
                    playerSprite.frame += 1
                elseif playerSprite.frame == 13 then
                    playerSprite.frame = 1
                end
        
                local playerImage = gfx.image.new('/images/player/player-run-'..playerSprite.frame)
                assert( playerImage ) -- make sure the image was where we thought
                
                playerSprite:setImage(playerImage)
            else
                local playerImage = gfx.image.new('/images/player/player-jump-1')
                assert( playerImage ) -- make sure the image was where we thought
                
                playerSprite:setImage(playerImage)
            end

            local actualX, actualY, collisions, length = playerSprite:moveWithCollisions(playerSprite.x + dx, playerSprite.y + dy)
            for i = 1, length do
                local collision = collisions[i]
                if collision.other.isEnemy == true then	-- crashed into enemy plane
                    destroyPoo(collision.other)
                    updatePlayerHealth("damage")
                    collision.other:remove()
                    score -= 1
                elseif collision.other.isPickup == true then
                    destroyPickup(collision.other)
                    --todo: implement item storage
                    collision.other:remove()
                    score += 10
                end
            end
        end

	end

    playerSprite:setZIndex(1000)

    -- taken from http://localhost:5500/Inside%20Playdate.html#basic-playdate-game
    -- good tutorial on how to setup a playdate sprite with movement here

    import "healthTable" -- imports healthTable table
    
    playerHealth = 0 -- initialize playerHealth as 0 - corresponds to "INFO" on healthTable

end

-- Now we'll call the function above to configure our game.
-- After this runs (it just runs once), nearly everything will be
-- controlled by the OS calling `playdate.update()` 30 times a second.

playerSpriteSetUp()

-- -- --
-- Handle Death
-- -- --

import "death"

-- -- --
-- Handle Player Jumping
-- -- -- 
playerIsJumping = false
playerIsFalling = false

function handleJumping()
    if playdate.buttonIsPressed("B") or playdate.buttonIsPressed("A") or playdate.buttonIsPressed(playdate.kButtonUp) then --todo: remove b and a if required for something else
        if playerIsFalling then
            if playerYCurrent < playerYResting then
                playerSprite:moveBy( 0, 8 )
                foregroundSpriteYOffset = 8
                playerYCurrent += 8
                backgroundWallYOffset -= 4
            elseif playerYCurrent == playerYResting then
                playerIsFalling = false
                foregroundSpriteYOffset = 0
            end
        else
		    playerIsJumping = true
            playerSprite:moveBy( 0, -8 )
            foregroundSpriteYOffset = -8
            playerYCurrent += foregroundSpriteYOffset
            backgroundWallYOffset += 4
        end
    elseif playerYCurrent < playerYResting then
        playerIsFalling = true
        if playerIsJumping then
            playerIsJumping = false
        end
        playerSprite:moveBy( 0, 8 )
        foregroundSpriteYOffset = 8
        playerYCurrent += foregroundSpriteYOffset
        backgroundWallYOffset -= 4
    else
        playerIsFalling = false 
        foregroundSpriteYOffset = 0
    end
end

-- -- -- 
--
-- Game Flow
--
-- -- --


function playdate.update()
    gfx.setFont(font)

    local change, acceleratedChange = playdate.getCrankChange()
    crankChange = change

    notice = 'change == 0'
    if change >= 1 then
        backgroundX -= 2
        notice = 'change > 1'
    elseif change <= -1 then
        backgroundX += 2 
        notice = 'change < -1'
    elseif change == 0 then
        notice = 'change == 0'        
    end

    if dead ~= true then
        spawnPickupIfNeeded()
        spawnPooIfNeeded()
        handleJumping()
    end
    
    gfx.sprite.update()
    
    playdate.timer.updateTimers()
    
    gfx.drawText('LEVEL: '..healthTable[playerHealth], 2, 2)
    gfx.drawText('SCORE: '..score, 300, 2)
	-- Above using this as example: gfx.drawText('sprite count: '..#gfx.sprite.getAllSprites(), 2, 2)

    if playdate.isSimulator then
	    -- playdate.drawFPS(2, 224)
        -- gfx.drawText('crank state: '..notice, 2, 210)
        -- gfx.drawText('backgroundX: '..backgroundX, 2, 196)
        -- gfx.drawText('player is jumping: '..tostring(playerIsJumping), 2, 182)
        -- gfx.drawText('player is falling: '..tostring(playerIsFalling), 2, 168)
        -- gfx.drawText('backgroundWallYOffset: '..backgroundWallYOffset, 2, 154)
        -- gfx.drawText('foregroundSpriteYOffset'..foregroundSpriteYOffset, 2, 140)
        -- gfx.drawText('sprite count: '..#gfx.sprite.getAllSprites(), 2, 16)
	    -- gfx.drawText('max enemies: '..maxEnemies, 2, 30)
    end

end