--Fichier de gestion du joueur
local Player = {}
-- Statistiques du joueur
Player.maxLife = 100
Player.currentLife = 100
Player.maxLives = 3
Player.lives = 3
Player.isAlive = true
Player.respawnTimer = 0
Player.RESPAWN_DELAY = 2.0 -- 2 secondes avant respawn

local BULLET_OFFSET = math.rad(90)

function Player.Load()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    Player.tank = {
        image = love.graphics.newImage("assets/images/tank_green.png"),
        width = 0,
        height = 0,
        x = screenWidth / 2,
        y = screenHeight - 80,      
        speed = 60,
        angle = math.rad(180)
    }
    Player.tank.width = Player.tank.image:getWidth()
    Player.tank.height = Player.tank.image:getHeight()

    Player.bulletImage = love.graphics.newImage("assets/images/bulletGreen1.png")
    Player.bulletWidth = Player.bulletImage:getWidth()
    Player.bulletHeight = Player.bulletImage:getHeight()
    Player.bullets = {}
    Player.explosionImage = love.graphics.newImage("assets/images/explosion2.png")
    Player.explosionWidth = Player.explosionImage:getWidth()
    Player.explosionHeight = Player.explosionImage:getHeight()

    -- Reset des stats si c'est un nouveau jeu
    if Player.lives <= 0 then
        Player.lives = Player.maxLives
        Player.currentLife = Player.maxLife
        Player.isAlive = true
    end
end

function Player.Hit(damage)
    if not Player.isAlive then return end
    
    Player.currentLife = Player.currentLife - damage
    
    if Player.currentLife <= 0 then
        Player.Die()
    end
end

function Player.Die()
    Player.isAlive = false
    Player.lives = Player.lives - 1
    Player.respawnTimer = Player.RESPAWN_DELAY
    
    if Player.lives > 0 then
        -- Préparer le respawn
        Player.currentLife = Player.maxLife
        -- Ajouter un callback pour notifier main.lua
        if Player.onDeath then
            Player.onDeath() -- Callback pour nettoyer les ennemis
        end
    end
end

function Player.Respawn()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    Player.isAlive = true
    Player.tank.x = screenWidth / 2
    Player.tank.y = screenHeight - 80
    Player.tank.angle = math.rad(180)
    Player.bullets = {} -- Nettoyer les projectiles
end

function Player.Update(dt, ennemy)
    if not Player.isAlive then
        Player.respawnTimer = Player.respawnTimer - dt
        if Player.respawnTimer <= 0 and Player.lives > 0 then
            Player.Respawn()
        end
        return
    end

    local moveX, moveY = 0, 0
    local moveSpeed = Player.tank.speed

    if love.keyboard.isDown("right") then
        moveX = moveX + 1
    end
    if love.keyboard.isDown("left") then
        moveX = moveX - 1
    end
    if love.keyboard.isDown("down") then
        moveY = moveY + 1
    end
    if love.keyboard.isDown("up") then
        moveY = moveY - 1
    end

    -- Normalisation pour la diagonale
    if moveX ~= 0 or moveY ~= 0 then
        local len = math.sqrt(moveX * moveX + moveY * moveY)
        moveX = moveX / len
        moveY = moveY / len
        Player.tank.x = Player.tank.x + moveX * moveSpeed * dt
        Player.tank.y = Player.tank.y + moveY * moveSpeed * dt
    end

    -- Empêcher de sortir de l'écran
    local minX = Player.tank.width / 2
    local maxX = love.graphics.getWidth() - Player.tank.width / 2
    local minY = Player.tank.height / 2
    local maxY = love.graphics.getHeight() - Player.tank.height / 2
    Player.tank.x = math.max(minX, math.min(maxX, Player.tank.x))
    Player.tank.y = math.max(minY, math.min(maxY, Player.tank.y))

    -- Déplacement des obus
    for i = #Player.bullets, 1, -1 do
        local obus = Player.bullets[i]
        local speed = 300
        obus.x = obus.x + math.cos(obus.angle) * speed * dt
        obus.y = obus.y + math.sin(obus.angle) * speed * dt
        if obus.x < 0 or obus.x > love.graphics.getWidth() or obus.y < 0 or obus.y > love.graphics.getHeight() then
            table.remove(Player.bullets, i)
        end
    end

    local rotationSpeed = 2 -- radians/seconde
    -- Rotation du tank
    if love.keyboard.isDown("a") then
        Player.tank.angle = Player.tank.angle - rotationSpeed * dt
    end
    if love.keyboard.isDown("e") then
        Player.tank.angle = Player.tank.angle + rotationSpeed * dt
    end    
end

function Player.Draw()
    if not Player.isAlive then 
        -- dessiner une explosion ou rien
        love.graphics.draw(
            Player.explosionImage,
            Player.tank.x, Player.tank.y,
            Player.tank.angle,
            1, 1,
            Player.explosionWidth / 2,  Player.explosionHeight / 2
        )
        return 
    end

    -- Obus
    for _, obus in ipairs(Player.bullets) do
        love.graphics.draw(
            Player.bulletImage,
            obus.x, obus.y,
            obus.angle + BULLET_OFFSET,
            1, 1,
            Player.bulletWidth / 2, Player.bulletHeight / 2
        )
    end

    -- Tank
    love.graphics.draw(
        Player.tank.image,
        Player.tank.x, Player.tank.y,
        Player.tank.angle,
        1, 1,
        Player.tank.width / 2, Player.tank.height / 2
    )
end

function Player.DrawUI()
    -- Barre de vie
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Santé : ", 10, 50)
    
    -- Fond de la barre
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 80, 50, Player.maxLife, 20)
    
    -- Barre de vie actuelle
    if Player.currentLife > 0 then
        local lifePercent = Player.currentLife / Player.maxLife
        if lifePercent > 0.6 then
            love.graphics.setColor(0, 1, 0) -- Vert
        elseif lifePercent > 0.3 then
            love.graphics.setColor(1, 1, 0) -- Jaune
        else
            love.graphics.setColor(1, 0, 0) -- Rouge
        end
        love.graphics.rectangle("fill", 80, 50, Player.currentLife, 20)
    end
    
    -- Vies restantes
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Vies : " .. Player.lives, 10, 80)
    
    -- Timer de respawn
    if not Player.isAlive and Player.lives > 0 then
        love.graphics.print("Respawn dans : " .. math.ceil(Player.respawnTimer), 10, 110)
    end
end

function Player.KeyPressed(key)
    if key == "space" then
        -- Créer un obus
        -- On utilise l'angle du tank pour déterminer la direction de l'obus
        -- On ajoute un offset de 90 degrés pour que l'obus parte dans la direction
        local angle = Player.tank.angle  + BULLET_OFFSET
        local offset = Player.tank.height / 2
        local bx = Player.tank.x + math.cos(angle) * offset
        local by = Player.tank.y + math.sin(angle) * offset
        table.insert(Player.bullets, {
            x = bx,
            y = by,
            angle = angle
        })
    end
end


return Player