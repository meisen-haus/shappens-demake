-- -- -- 
--
-- Handle Pickup Sprites
--
-- -- --

playerHasPickup = false
pickupCount = 0

function inventoryPickup()
	local inventory = gfx.sprite.new()

	local pickupImg = gfx.image.new('images/file-mini')

	local w, h = pickupImg:getSize()
	inventory:setImage(pickupImg)
	inventory:moveTo(2 + (w/2), 16 + (h/2))
	inventory:add()

	function inventory:update()
		if playdate.buttonIsPressed("B") and playdate.buttonIsPressed("A") and playerHealth >= 1 then
			updatePlayerHealth('heal')
			playerHasPickup = false
			inventory:remove()
		end
	end
	
end

function createPickup()

	if pickupCount < 1 then
		local pickup = gfx.sprite.new()

		local pickupImg

		if math.random(2) > 1 then
			pickupImg = gfx.image.new('images/map-file-no-trans')
		else
			pickupImg = gfx.image.new('images/dif-file-no-trans')
		end

		local w, h = pickupImg:getSize()
		pickup:setImage(pickupImg)
		pickup:setCollideRect(0, 0, w, h)
		---
		-- The base of the player sprite at rest is 170 pixels
		pickup:moveTo(400 + w, 165 - (h/2) + backgroundWallYOffset) --todo: randomize on floor or in air more distinctly
		pickup:add()
		pickupCount += 1

		-- pickup.isEnemy = true
		pickup.isPickup = true

		function pickup:collisionResponse(other)
			return gfx.sprite.kCollisionTypeOverlap
		end

		function pickup:update()

			if start ~= true then -- only move sprites if the start condition is false
				local newX = pickup.x
				
				newX -= 2 -- always decrement position by 2

				if crankChange >= 1 and (playerIsJumping or playerIsFalling) then
					newX -= 2
				elseif crankChange <= -1 and (playerIsJumping or playerIsFalling) then
					newX += 4
				end
		
				if newX < 0 - h then
					pickupCount -= 1
					pickup:remove()
				else
					pickup:moveTo(newX, 165 - (h/2) + backgroundWallYOffset)
				end
			end
		end
	
		pickup:setZIndex(100)
	end
end