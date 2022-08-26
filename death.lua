dead = false

function handleDeath()
    dead = true
    local sprites = gfx.sprite.getAllSprites()
    local arrayCount, hashCount = table.getsize(sprites)

    for i = 1, arrayCount do
        local sprite = sprites[i]
        if sprite.isPlayer then
            local playerImage = gfx.image.new('/images/player/player-run-'..sprite.frame)

            playerImage:setInverted(true)

            sprite:setImage(playerImage)
        elseif sprite.isExplosion ~= true then
            sprite:remove()
        end
    end

    local deathImage = gfx.image.new('/images/you-died')
    assert( deathImage ) -- make sure the image was where we thought
    
    local w, h = deathImage:getSize()
    deathMessage = gfx.sprite.new( deathImage:fadedImage(0.02, gfx.image.kDitherTypeBurkes) )
    deathMessage.frame = 1
    deathMessage.fade = 0.02
    deathMessage:moveTo( 200, 202 ) -- this is where the center of the sprite is placed; (200,120) is the center of the Playdate screen
    deathMessage:add() -- This is critical!

    function deathMessage:update()
        if deathMessage.frame <= 50 then
            deathMessage.frame += 1
            deathMessage.fade += 0.02

            local deathImage = gfx.image.new('/images/you-died')
            assert( deathImage )

            deathMessage:setImage( deathImage:fadedImage(deathMessage.fade, gfx.image.kDitherTypeBurkes) )
        end

        self:markDirty()
    end
end