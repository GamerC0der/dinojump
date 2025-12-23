local player = {
    x = 80,
    y = 0,
    width = 1,
    height = 1,
    velocityY = 0,
    velocityX = 0,
    isJumping = false
}

local ground = { y = 0, height = 40 }
local obstacles = {}
local coins = {}
local spawnTimer = 0
local coinTimer = 0
local spawnInterval = 1.5
local gameSpeed = 600
local score = 0
local highScore = 0
local gameOver = false
local gameStarted = false
local currentScreen = "levels"
local levels = {true, false, false, false}
local currentLevel = 1
local levelTargets = {50, 150, 250, 0}
local collectedCoins = 0
local loadingTimer = 0
local maxProgressX = 80
local gravity = 1000
local jumpForce = -520

local images = {}
local dinoScale = 1

function love.load()
    love.window.setTitle("Dino Runner")
    
    images.dino = love.graphics.newImage("assets/dino.png")
    images.cactus = love.graphics.newImage("assets/cactus.png")
    images.coin = love.graphics.newImage("assets/coin.png")
    images.lock = love.graphics.newImage("assets/lock.png")
    
    local targetHeight = 60
    dinoScale = targetHeight / images.dino:getHeight()
    player.width = images.dino:getWidth() * dinoScale
    player.height = targetHeight
    
    ground.y = love.graphics.getHeight() - ground.height
    player.y = ground.y - player.height + 1
    
    love.graphics.setFont(love.graphics.newFont(20))
end

function love.update(dt)
    if currentScreen == "loading_endless" then
        loadingTimer = loadingTimer + dt
        if loadingTimer >= 8.0 then
            currentScreen = "game"
            loadingTimer = 0
        end
        return
    end

    if gameOver or currentScreen ~= "game" then return end

    if currentLevel ~= 3 then
        score = score + dt * 10
        if currentLevel ~= 4 and score > highScore then highScore = score end
        gameSpeed = 600 + score * 1.0
        if currentLevel ~= 4 and score >= levelTargets[currentLevel] then
            if currentLevel < 3 then
                levels[currentLevel + 1] = true
            end
            restartGame()
        end
    else
        gameSpeed = 200
        if love.keyboard.isDown("left") then
            player.velocityX = -1
        elseif love.keyboard.isDown("right") then
            player.velocityX = 1
        else
            player.velocityX = 0
        end
        player.x = player.x + player.velocityX * dt * 200
        if player.x > maxProgressX then
            maxProgressX = player.x
        end
    end

    if player.isJumping then
        player.velocityY = player.velocityY + gravity * dt
        player.y = player.y + player.velocityY * dt

        if player.y >= ground.y - player.height then
            player.y = ground.y - player.height + 1
            player.isJumping = false
            player.velocityY = 0
        end
    end

        if currentLevel ~= 3 then
            spawnTimer = spawnTimer + dt
            if spawnTimer >= spawnInterval then
                spawnTimer = 0
                spawnInterval = math.random(10, 20) / 10
                spawnObstacle()
            end
        end

    if (currentLevel == 2 or currentLevel == 4) and coinTimer >= 2.0 and #coins < 6 then coinTimer = 0 table.insert(coins, {x = love.graphics.getWidth(), y = math.random(love.graphics.getHeight() * 0.5, ground.y - 20), width = 20, height = 20})
    elseif currentLevel == 3 and #coins == 0 then
        coins = {{x=200,y=ground.y-20-love.graphics.getHeight()*0.25,width=20,height=20},{x=400,y=ground.y-20-love.graphics.getHeight()*0.25,width=20,height=20},{x=600,y=ground.y-20-love.graphics.getHeight()*0.25,width=20,height=20}}
        obstacles = {{x=300,y=ground.y-50,width=30,height=50},{x=500,y=ground.y-50,width=30,height=50}}
    end
    coinTimer = coinTimer + dt

        for i = #obstacles, 1, -1 do
            local obs = obstacles[i]
            if obs then
                if currentLevel ~= 3 then
                    obs.x = obs.x - gameSpeed * dt
                end
                if obs.x + obs.width < 0 then
                    table.remove(obstacles, i)
                elseif checkCollision(player, obs) then
                    gameOver = true
                    if score > highScore then highScore = score end
                end
            end
        end
        for i = #coins, 1, -1 do
            local coin = coins[i]
            if coin then
                if currentLevel ~= 3 then
                    coin.x = coin.x - gameSpeed * dt
                end
                if coin.x + coin.width < 0 then
                    table.remove(coins, i)
                elseif checkCollision(player, coin) then
                    if currentLevel == 3 then
                        collectedCoins = collectedCoins + 1
                        if collectedCoins >= 3 then
                            levels[4] = true
                            restartGame()
                        end
                    else
                        score = score + 10
                    end
                    table.remove(coins, i)
                end
            end
        end
end

function love.draw()
    love.graphics.clear(1, 1, 1)

    if currentScreen == "loading_endless" then
        local progress = loadingTimer / 8.0
        love.graphics.setColor(0, 0, 0, 0.3 * progress)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        return
    end

    if currentScreen == "levels" then
        love.graphics.setColor(0, 0, 0)
        love.graphics.print("LEVELS", love.graphics.getWidth() / 2 - 30, 50)
        for i = 1, 3 do
            local x = (love.graphics.getWidth() - 2*120) / 2 + (i-1) * 120
            local y = love.graphics.getHeight() / 2 - 50
            love.graphics.circle("line", x, y, 30)
            if levels[i] then love.graphics.print(i, x-5, y-10) else love.graphics.draw(images.lock, x-8, y-8, 0, 0.5, 0.5) end
        end
        local x = love.graphics.getWidth() / 2
        local y = love.graphics.getHeight() / 2 + 50
        love.graphics.rectangle("line", x-60, y-20, 120, 40)
        if levels[4] then
            love.graphics.print("ENDLESS", x-47, y-8)
        else
            love.graphics.draw(images.lock, x-8, y-8, 0, 0.5, 0.5)
        end
        love.graphics.print("High Score: " .. math.floor(highScore), 10, love.graphics.getHeight() - 30)
        return
    end
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.line(0, ground.y, love.graphics.getWidth(), ground.y)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(images.dino, player.x, player.y, 0, dinoScale, dinoScale)
    
    for _, obs in ipairs(obstacles) do love.graphics.draw(images.cactus, obs.x, obs.y, 0, obs.width / images.cactus:getWidth(), obs.height / images.cactus:getHeight()) end
    for _, coin in ipairs(coins) do love.graphics.draw(images.coin, coin.x, coin.y, 0, coin.width / images.coin:getWidth(), coin.height / images.coin:getHeight()) end

    love.graphics.setColor(0, 0, 0)
    if currentLevel == 3 then
        love.graphics.print("Coins: " .. collectedCoins .. "/3", 10, 10)
    elseif currentLevel == 4 then
        love.graphics.print("ENDLESS MODE", 10, 10)
        love.graphics.print("Score: " .. math.floor(score), 10, 35)
        love.graphics.print("High Score: " .. math.floor(highScore), 10, 60)
    else
        love.graphics.print("Score: " .. math.floor(score), 10, 10)
        love.graphics.print("High Score: " .. math.floor(highScore), 10, 35)
    end

    if currentLevel == 1 or currentLevel == 2 or currentLevel == 3 then
        local progress
        if currentLevel == 3 then
            progress = math.min(1, collectedCoins / 3)
        else
            progress = math.min(1, score / levelTargets[currentLevel])
        end
        local barWidth = 200
        local barHeight = 20
        local barX = (love.graphics.getWidth() - barWidth) / 2
        local barY = love.graphics.getHeight() - barHeight - 30
        local cornerRadius = 10

        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", barX + 2, barY + 2, barWidth, barHeight, cornerRadius)

        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, cornerRadius)

        local progressWidth = barWidth * progress
        if progressWidth > 0 then
            love.graphics.setColor(0.2, 0.8, 0.4)
            love.graphics.rectangle("fill", barX, barY, progressWidth, barHeight, cornerRadius)

            love.graphics.setColor(0.4, 0.9, 0.6)
            love.graphics.rectangle("fill", barX, barY, progressWidth, barHeight/2, cornerRadius, cornerRadius, 0, 0)
        end

        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("line", barX, barY, barWidth, barHeight, cornerRadius)

        love.graphics.setColor(1, 1, 1)

        local percentText = math.floor(progress * 100) .. "%"
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(percentText, barX + barWidth / 2 - love.graphics.getFont():getWidth(percentText) / 2, barY + barHeight / 2 - love.graphics.getFont():getHeight() / 2)
    end
    
    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("GAME OVER", love.graphics.getWidth() / 2 - 60, love.graphics.getHeight() / 2 - 30)
        love.graphics.print("Press SPACE to restart", love.graphics.getWidth() / 2 - 100, love.graphics.getHeight() / 2 + 10)
    end
end

function love.keypressed(key)
    if currentScreen == "levels" then
        return
    end
    if currentScreen ~= "game" then currentScreen = "game" return end
    if key == "space" or key == "up" then
        if gameOver then
            restartGame()
        elseif not player.isJumping then
            player.isJumping = true
            player.velocityY = jumpForce - 50
        end
    end


    if key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y)
    if currentScreen == "levels" then
        for i = 1, 3 do
            local cx = (love.graphics.getWidth() - 2*120) / 2 + (i-1) * 120
            local cy = love.graphics.getHeight() / 2 - 50
            if levels[i] and (x-cx)^2 + (y-cy)^2 < 900 then
                currentLevel = i
                currentScreen = "game"
                break
            end
        end
        local cx = love.graphics.getWidth() / 2
        local cy = love.graphics.getHeight() / 2 + 50
        if levels[4] and x >= cx-60 and x <= cx+60 and y >= cy-20 and y <= cy+20 then
            currentLevel = 4
            currentScreen = "loading_endless"
            loadingTimer = 0
        end
    elseif currentScreen ~= "game" then
        currentScreen = "game"
    end
end

function spawnObstacle()
    local obstacle = {
        x = love.graphics.getWidth(),
        width = 30,
        height = 50
    }
    obstacle.y = ground.y - obstacle.height + 1
    table.insert(obstacles, obstacle)
end

function checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end

function restartGame()
    gameOver = false
    currentScreen = "levels"
    score = 0
    collectedCoins = 0
    obstacles = {}
    coins = {}
    spawnTimer = 0
    coinTimer = 0
    gameSpeed = 600
    player.x = 80
    maxProgressX = 80
    player.y = ground.y - player.height + 1
    player.isJumping = false
    player.velocityY = 0
    player.velocityX = 0
end
