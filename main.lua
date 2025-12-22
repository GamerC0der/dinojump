local player = {
    x = 80,
    y = 0,
    width = 1,
    height = 1,
    velocityY = 0,
    isJumping = false
}

local ground = { y = 0, height = 40 }
local obstacles = {}
local spawnTimer = 0
local spawnInterval = 1.5
local gameSpeed = 600
local score = 0
local highScore = 0
local gameOver = false
local gameStarted = false
local currentScreen = "levels"
local levels = {true, false, false}
local currentLevel = 1
local levelTargets = {50, 100, 250}
local gravity = 1000
local jumpForce = -520

local images = {}
local dinoScale = 1

function love.load()
    love.window.setTitle("Dino Runner")
    
    images.dino = love.graphics.newImage("assets/dino.png")
    images.cactus = love.graphics.newImage("assets/cactus.png")
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
    if gameOver or currentScreen ~= "game" then return end

    score = score + dt * 10
    gameSpeed = 600 + score * 1.0

    if score >= levelTargets[currentLevel] then
        if currentLevel < 3 then
            levels[currentLevel + 1] = true
        end
        restartGame()
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
    
    spawnTimer = spawnTimer + dt
    if spawnTimer >= spawnInterval then
        spawnTimer = 0
        spawnInterval = math.random(10, 20) / 10
        spawnObstacle()
    end
    
    for i = #obstacles, 1, -1 do
        local obs = obstacles[i]
        obs.x = obs.x - gameSpeed * dt
        
        if obs.x + obs.width < 0 then
            table.remove(obstacles, i)
        end
        
        if checkCollision(player, obs) then
            gameOver = true
            if score > highScore then
                highScore = score
            end
        end
    end
end

function love.draw()
    love.graphics.clear(1, 1, 1)

    if currentScreen == "levels" then
        love.graphics.setColor(0, 0, 0)
        love.graphics.print("LEVELS", love.graphics.getWidth() / 2 - 30, 50)
        for i = 1, 3 do
            local x = (love.graphics.getWidth() - 240) / 2 + (i-1) * 120
            local y = love.graphics.getHeight() / 2
            love.graphics.circle("line", x, y, 30)
            if levels[i] then love.graphics.print(i, x-5, y-10) else love.graphics.draw(images.lock, x-8, y-8, 0, 0.5, 0.5) end
        end
        return
    end
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.line(0, ground.y, love.graphics.getWidth(), ground.y)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(images.dino, player.x, player.y, 0, dinoScale, dinoScale)
    
    for _, obs in ipairs(obstacles) do
        love.graphics.draw(images.cactus, obs.x, obs.y, 0,
            obs.width / images.cactus:getWidth(),
            obs.height / images.cactus:getHeight())
    end
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Score: " .. math.floor(score), 10, 10)
    love.graphics.print("High Score: " .. math.floor(highScore), 10, 35)

    local progress = math.min(1, score / levelTargets[currentLevel])
    local barWidth = 150
    local barHeight = 15
    local barX = 10
    local barY = 60

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

    love.graphics.setColor(0, 0.7, 0)
    love.graphics.rectangle("fill", barX, barY, barWidth * progress, barHeight)

    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight)

    love.graphics.setColor(1, 1, 1)
    local percentText = math.floor(progress * 100) .. "%"
    love.graphics.print(percentText, barX + barWidth / 2 - love.graphics.getFont():getWidth(percentText) / 2, barY + barHeight + 5)
    
    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("GAME OVER", love.graphics.getWidth() / 2 - 60, love.graphics.getHeight() / 2 - 30)
        love.graphics.print("Press SPACE to restart", love.graphics.getWidth() / 2 - 100, love.graphics.getHeight() / 2 + 10)
    end
end

function love.keypressed(key)
    if currentScreen == "levels" then return end
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
            local cx = (love.graphics.getWidth() - 240) / 2 + (i-1) * 120
            local cy = love.graphics.getHeight() / 2
            if levels[i] and (x-cx)^2 + (y-cy)^2 < 900 then
                currentLevel = i
                currentScreen = "game"
                break
            end
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
    obstacles = {}
    spawnTimer = 0
    gameSpeed = 600
    player.y = ground.y - player.height + 1
    player.isJumping = false
    player.velocityY = 0
end
