-- -- -- 
--
-- Handle Pickup Sprites
--
-- -- --

maxPickups = 10
pickupCount = 0

pickupSpriteCount = 0

function destroyPickup(pickup)
	createExplosion(pickup.x, pickup.y)
	pickup:remove()
	pickupSpriteCount -= 1
end

function createPickup()

	local pickup = gfx.sprite.new()

	local pickupImg

	pickupImg = gfx.image.new('images/map-file')

	local w, h = pickupImg:getSize()
	pickup:setImage(pickupImg)
    pickup:setCollideRect(0, 0, w, h)
    ---
    -- The base of the player sprite at rest is 170 pixels
	pickup:moveTo(400 + h, math.random(170)) --todo: randomize on floor or in air more distinctly
	pickup:add()

    -- pickup.isEnemy = true
    pickup.isPickup = true

	pickupSpriteCount += 1

    function pickup:collisionResponse(other)
		return gfx.sprite.kCollisionTypeOverlap
	end

	function pickup:update()

		local newX = pickup.x
        
        if crankChange >= 1 then
            newX -= 6
        elseif crankChange <= -1 then
            newX -= 4
        elseif crankChange == 0 then
            newX -= 4
        end

		if newX < 0 - h then
			pickup:remove()
			pickupSpriteCount -= 1
        else
            pickup:moveTo(newX, pickup.y - foregroundSpriteYOffset)
		end
	end


	pickup:setZIndex(100)
	return pickup
end



function spawnPickupIfNeeded()
	if pickupSpriteCount < maxBackgroundSprites then
		if math.random(math.floor(120/maxBackgroundSprites)) == 1 then
			createPickup()
		end
	end
end
