-- http://localhost:5500/Inside%20Playdate.html#basic-playdate-game
-- good tutorial on how to setup a playdate sprite with movement here

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
-- import 'CoreLibs/input' -- not sure what this module does

local gfx = playdate.graphics -- playdate.graphics alias 

local font = gfx.font.new('images/font/whiteglove-stroked') -- borrowed from Examples/2020

local playerSprite = nil
local playerYResting = 120 -- reseting location of sprite
local playerYCurrent = playerYResting -- initialize sprite at resting location of sprite

-- A function to set up our game environment.

function playerSpriteSetUp()

    -- Set up the player sprite.
    -- The :setCenter() call specifies that the sprite will be anchored at its center.
    -- The :moveTo() call moves our sprite to the center of the display.

    local playerImage = gfx.image.new('images/sentry-logo.png')
    assert( playerImage ) -- make sure the image was where we thought

    playerSprite = gfx.sprite.new( playerImage )
    playerSprite:moveTo( 200, playerYCurrent ) -- this is where the center of the sprite is placed; (200,120) is the center of the Playdate screen
    playerSprite:add() -- This is critical!

    playerSprite:setZIndex(1000)

    -- taken from http://localhost:5500/Inside%20Playdate.html#basic-playdate-game
    -- good tutorial on how to setup a playdate sprite with movement here

    import "healthTable" -- imports healthTable table
    
    playerHealth = healthTable[0] -- setup player health 

end

-- Now we'll call the function above to configure our game.
-- After this runs (it just runs once), nearly everything will be
-- controlled by the OS calling `playdate.update()` 30 times a second.

playerSpriteSetUp()

local backgroundX = 0 -- used to calculate background wrapping behaviour
local backgroundWidth = 0 -- used for both backgrounds
local backgroundWallY = 0 -- holds y coordinate for upperleft pixel of backgroundWall
local backgroundWallYOffset = 0 -- used to derive offset of backgroundWallY when jumping

local notice = 'default notice' -- notice is used for debugging crank information

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
        local change, acceleratedChange = playdate.getCrankChange()
        notice = 'change == 0'
        if change > 1 then
            backgroundX -= 2
            notice = 'change > 1'
        elseif change < -1 then
            backgroundX += 2 
            notice = 'change < -1'        
        end

        if backgroundX > backgroundWidth then
            backgroundX = 0
        elseif backgroundX < -400 then
            backgroundX = 0
        end

        self:markDirty()  
	end

    function backgroundWall:update()

        self:markDirty()  
	end

    backgroundWall:setZIndex(1)
	backgroundWall:add()

	backgroundFloor:setZIndex(0)
	backgroundFloor:add()
    
end

createBackgroundSprites()

-- local playerIsJumping = false 
local playerIsFalling = false

function handleJumping()
    if playdate.buttonIsPressed("B") or playdate.buttonIsPressed("A") then
        if playerIsFalling then
            if playerYCurrent < playerYResting then
                playerSprite:moveBy( 0, 8 )
                playerYCurrent += 8
                backgroundWallYOffset -= 4
            end
        else
		    -- playerIsJumping = true
            playerSprite:moveBy( 0, -8 )
            playerYCurrent -= 8
            backgroundWallYOffset += 4
        end
    elseif playerYCurrent < playerYResting then
        playerIsFalling = true
        -- if playerIsJumping then
        --     playerIsJumping = false
        -- end
        playerSprite:moveBy( 0, 8 )
        playerYCurrent += 8
        backgroundWallYOffset -= 4
    else
        playerIsFalling = false 
    end
end

function playdate.update()

	handleJumping()

    if playdate.buttonIsPressed( playdate.kButtonUp ) then
        playerSprite:moveBy( 0, -2 )
    end
    if playdate.buttonIsPressed( playdate.kButtonRight ) then
        playerSprite:moveBy( 2, 0 )
    end
    if playdate.buttonIsPressed( playdate.kButtonDown ) then
        playerSprite:moveBy( 0, 2 )
    end
    if playdate.buttonIsPressed( playdate.kButtonLeft ) then
        playerSprite:moveBy( -2, 0 )
    end

	gfx.sprite.update()
    playdate.timer.updateTimers()

	gfx.setFont(font)
    gfx.drawText('Level: '..playerHealth, 2, 2)
	-- Above using this as example: gfx.drawText('sprite count: '..#gfx.sprite.getAllSprites(), 2, 2)

    
    if playdate.isSimulator then
	    playdate.drawFPS(2, 224)
        gfx.drawText('crank state: '..notice, 2, 210)
        gfx.drawText('backgroundX: '..backgroundX, 2, 196)
        -- gfx.drawText('player is jumping: '..tostring(playerIsJumping), 2, 182)
        gfx.drawText('player is falling: '..tostring(playerIsFalling), 2, 168)
        gfx.drawText('backgroundWallYOffset: '..backgroundWallYOffset, 2, 154)
    end

end