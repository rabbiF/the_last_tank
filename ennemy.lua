local Ennemy = {}
local BULLET_OFFSET = math.rad(90)
local MAX_ENNEMIES = 4
local STATE_DURATION = 2 -- secondes par état
local EXPLOSION_DURATION = 1.0 -- 1 seconde d'explosion

Ennemy.list = {}
Ennemy.explosionImage = nil

local states = {"random", "follow", "pause"}

function Ennemy.Load()
    Ennemy.bulletImage = love.graphics.newImage("assets/images/bulletRed1.png")
    Ennemy.bulletWidth = Ennemy.bulletImage:getWidth()
    Ennemy.bulletHeight = Ennemy.bulletImage:getHeight()
    Ennemy.explosionImage = love.graphics.newImage("assets/images/explosion2.png") -- Une seule fois
    Ennemy.list = {}
    for i=1,MAX_ENNEMIES do
        Ennemy.SpawnOne()
    end
end

function Ennemy.SpawnOne()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local ennemy = {
        image = love.graphics.newImage("assets/images/tank_red.png"),
        width = 0,
        height = 0,
        -- Spawn des ennemis dans la moitié haute de l'écran
        x = math.random(50, w-50),
        y = math.random(50, h/3), -- Ennemis dans le tiers supérieur
        speed = 40,
        angle = math.rad(90),
        cannonAngle = 0,
        state = 1,
        stateTimer = STATE_DURATION,
        alive = true,
        exploding = false,
        explosionTimer = 0,
        bullets = {},
        shootTimer = math.random() * 2
    }
    ennemy.width = ennemy.image:getWidth()
    ennemy.height = ennemy.image:getHeight()
    table.insert(Ennemy.list, ennemy)
end

function Ennemy.Kill(ennemy)
    ennemy.alive = false
    ennemy.exploding = true
    ennemy.explosionTimer = EXPLOSION_DURATION
    print("Ennemi tué - explosion démarrée")
end

function Ennemy.Update(dt, player)
    -- Mise à jour des ennemis
    for i = #Ennemy.list, 1, -1 do
        local e = Ennemy.list[i]
        
        if e.exploding then
            -- Gestion de l'explosion
            e.explosionTimer = e.explosionTimer - dt
            if e.explosionTimer <= 0 then
                -- Explosion terminée, supprimer complètement l'ennemi
                table.remove(Ennemy.list, i)
                print("Explosion terminée - ennemi supprimé de la liste")
            end
        elseif e.alive then
            -- Logique normale des ennemis vivants
            e.stateTimer = e.stateTimer - dt
            if e.stateTimer <= 0 then
                e.state = e.state % 3 + 1
                e.stateTimer = STATE_DURATION
                e.justChangedState = true
            end

            if states[e.state] == "random" then
                if e.justChangedState then
                    e.angle = math.random() * 2 * math.pi
                    e.justChangedState = false
                end
                local dx = math.cos(e.angle)
                local dy = math.sin(e.angle)
                e.x = e.x + dx * e.speed * dt
                e.y = e.y + dy * e.speed * dt
                e.cannonAngle = e.angle - math.pi/2
                
            elseif states[e.state] == "follow" then
                local dx = player.tank.x - e.x
                local dy = player.tank.y - e.y
                local angleToPlayer = math.atan2(dy, dx)
                e.angle = angleToPlayer
                e.x = e.x + math.cos(e.angle) * e.speed * dt
                e.y = e.y + math.sin(e.angle) * e.speed * dt
                e.cannonAngle = angleToPlayer - math.pi/2
                
            elseif states[e.state] == "pause" then
                local dx = player.tank.x - e.x
                local dy = player.tank.y - e.y
                e.cannonAngle = math.atan2(dy, dx) - math.pi/2
            end
            
            -- Empêcher de sortir de l'écran
            e.x = math.max(e.width/2, math.min(love.graphics.getWidth()-e.width/2, e.x))
            e.y = math.max(e.height/2, math.min(love.graphics.getHeight()-e.height/2, e.y))

            -- Gestion des tirs
            e.shootTimer = (e.shootTimer or 0) - dt
            if e.shootTimer <= 0 then
                e.shootTimer = 2
                local angle = e.cannonAngle + BULLET_OFFSET
                local offset = e.height / 2
                local bx = e.x + math.cos(angle) * offset
                local by = e.y + math.sin(angle) * offset
                table.insert(e.bullets, {
                    x = bx,
                    y = by,
                    angle = angle
                })
            end

            -- Déplacement des obus
            for j = #e.bullets, 1, -1 do
                local b = e.bullets[j]
                local speed = 300
                b.x = b.x + math.cos(b.angle) * speed * dt
                b.y = b.y + math.sin(b.angle) * speed * dt
                if b.x < 0 or b.x > love.graphics.getWidth() or b.y < 0 or b.y > love.graphics.getHeight() then
                    table.remove(e.bullets, j)
                end
            end
        end
    end

    -- Régénération des ennemis manquants
    local aliveCount = 0
    for _, e in ipairs(Ennemy.list) do
        if e.alive then aliveCount = aliveCount + 1 end
    end
    
    while aliveCount < MAX_ENNEMIES do
        Ennemy.SpawnOne()
        aliveCount = aliveCount + 1
    end
end

function Ennemy.Draw()
    for _, e in ipairs(Ennemy.list) do
        if e.alive then
            -- Dessiner le tank vivant
            love.graphics.draw(
                e.image,
                e.x, e.y,
                e.cannonAngle,
                1, 1,
                e.width / 2, e.height / 2
            )
            
            -- Afficher l'état
            local stateName = states[e.state]
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(
                stateName,
                e.x - e.width / 2,
                e.y - e.height / 2 - 16
            )
            
            -- Dessiner les obus
            if stateName == "follow" then
                for _, b in ipairs(e.bullets) do
                    love.graphics.draw(
                        Ennemy.bulletImage,
                        b.x, b.y,
                        b.angle + BULLET_OFFSET,
                        1, 1,
                        Ennemy.bulletWidth / 2, Ennemy.bulletHeight / 2
                    )
                end
            end
            
        elseif e.exploding then
            -- Dessiner l'explosion
            love.graphics.setColor(1, 1, 1) -- Blanc normal
            love.graphics.draw(
                Ennemy.explosionImage,
                e.x, e.y,
                0, -- Pas de rotation pour l'explosion
                1, 1,
                Ennemy.explosionImage:getWidth() / 2,
                Ennemy.explosionImage:getHeight() / 2
            )
        end
    end
end

return Ennemy