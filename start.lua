start = true
clearing = false

function handleStartUp()

    local startImage = gfx.image.new('/images/shappens')
    assert( startImage ) -- make sure the image was where we thought
    
    local w, h = startImage:getSize()
    local startScreen = gfx.sprite.new(startImage)
    startScreen:moveTo( 200, 120 ) -- this is where the center of the sprite is placed; (200,120) is the center of the Playdate screen
    startScreen:setZIndex(32766) --max possible ZIndex minus one
    startScreen.isStartScreen = true
    startScreen:add() -- This is critical!

    local logoImage = gfx.image.new('/images/shappens-demake')
    assert( logoImage ) -- make sure the image was where we thought
    
    local logoSprite = gfx.sprite.new(logoImage)
    logoSprite:moveTo( 200, 264 ) -- this is where the center of the sprite is placed; (200,120) is the center of the Playdate screen
    logoSprite:setZIndex(32767) --max possible ZIndex
    logoSprite.isStartScreen = true
    logoSprite.frame = 1
    logoSprite:add() -- This is critical!

    
    function logoSprite:update()
        if clearing ~= true then
            if logoSprite.frame <= 50 then
                logoSprite.frame += 1
    
                logoSprite:moveTo( 200, 264 - (logoSprite.frame * 2))
            end
        else 
            local newY = logoSprite.y
            logoSprite:moveTo( 200, newY - 2)
            if newY < - 30 then
                logoSprite:remove()
            end
        end

        self:markDirty()
    end

    function startScreen:update()
        local newY = startScreen.y

        if clearing == true and newY > -120 then
            startScreen:moveTo( 200, newY - 2)
        elseif clearing == true then
            start = false
            clearing = false
            startScreen:remove()
        end

        self:markDirty()
    end
end

function clearStart()
    clearing = true
end