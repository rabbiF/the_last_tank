local Ennemy = {}
local BULLET_OFFSET = math.pi / 2
local MAX_ENNEMIES = 4
local STATE_DURATION = 2 -- secondes par état

Ennemy.list = {}

local states = {"random", "follow", "pause"}

function Ennemy.SpawnOne()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local ennemy = {
        image = love.graphics.newImage("images/tank_red.png"),
        width = 0,
        height = 0,
        x = math.random(50, w-50),
        y = math.random(50, h-50),
        speed = 40,
        angle = 0,
        cannonAngle = 0, -- Angle séparé pour le canon
        state = 1, -- 1=random, 2=follow, 3=pause
        stateTimer = STATE_DURATION,
        alive = true,
        bullets = {},
        shootTimer = math.random() * 2 -- pour désynchroniser les tirs
    }
    ennemy.width = ennemy.image:getWidth()
    ennemy.height = ennemy.image:getHeight()
    table.insert(Ennemy.list, ennemy)
end

function Ennemy.Load()
    Ennemy.bulletImage = love.graphics.newImage("images/bulletRed1.png")
    Ennemy.bulletWidth = Ennemy.bulletImage:getWidth()
    Ennemy.bulletHeight = Ennemy.bulletImage:getHeight()
    Ennemy.list = {}
    for i=1,MAX_ENNEMIES do
        Ennemy.SpawnOne()
    end
end

function Ennemy.Update(dt, player)
    -- Déplacement et états
    for _, e in ipairs(Ennemy.list) do
        if e.alive then
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
                -- En mode random, le canon suit la direction de déplacement
                e.cannonAngle = e.angle - math.pi/2
                
            elseif states[e.state] == "follow" then
                local dx = player.tank.x - e.x
                local dy = player.tank.y - e.y
                local angleToPlayer = math.atan2(dy, dx)
                
                -- Pour le déplacement, on utilise l'angle direct
                e.angle = angleToPlayer
                e.x = e.x + math.cos(e.angle) * e.speed * dt
                e.y = e.y + math.sin(e.angle) * e.speed * dt
                
                -- Pour l'orientation du canon, on ajuste selon l'orientation du sprite
                -- Si le canon du sprite pointe vers le haut, on soustrait π/2
                e.cannonAngle = angleToPlayer - math.pi/2
                
            elseif states[e.state] == "pause" then
                -- En pause, on garde l'orientation actuelle du canon
                -- Optionnel: faire pointer le canon vers le joueur même en pause
                local dx = player.tank.x - e.x
                local dy = player.tank.y - e.y
                e.cannonAngle = math.atan2(dy, dx) - math.pi/2
            end
            
            -- Empêcher de sortir de l'écran
            e.x = math.max(e.width/2, math.min(love.graphics.getWidth()-e.width/2, e.x))
            e.y = math.max(e.height/2, math.min(love.graphics.getHeight()-e.height/2, e.y))
        end
    end

    -- Régénération si moins de MAX_ENNEMIES
    local count = 0
    for _, e in ipairs(Ennemy.list) do
        if e.alive then count = count + 1 end
    end
    while count < MAX_ENNEMIES do
        Ennemy.SpawnOne()
        count = count + 1
    end

    -- Gestion des tirs ennemis
    for _, e in ipairs(Ennemy.list) do
        if e.alive then
            e.shootTimer = (e.shootTimer or 0) - dt
            if e.shootTimer <= 0 then
                e.shootTimer = 2
                -- Utiliser l'angle du canon pour tirer
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

            -- Déplacement des obus ennemis
            for i = #e.bullets, 1, -1 do
                local b = e.bullets[i]
                local speed = 300
                b.x = b.x + math.cos(b.angle) * speed * dt
                b.y = b.y + math.sin(b.angle) * speed * dt
                if b.x < 0 or b.x > love.graphics.getWidth() or b.y < 0 or b.y > love.graphics.getHeight() then
                    table.remove(e.bullets, i)
                end
            end
        end
    end
end

function Ennemy.Draw()
    for _, e in ipairs(Ennemy.list) do
        if e.alive then
            -- Dessiner le tank avec l'angle du canon
            love.graphics.draw(
                e.image,
                e.x, e.y,
                e.cannonAngle, -- Utiliser cannonAngle au lieu de angle
                1, 1,
                e.width / 2, e.height / 2
            )
            -- Affiche l'état au-dessus du tank
            local stateName = states[e.state]
            love.graphics.setColor(1, 1, 1) -- blanc
            love.graphics.print(
                stateName,
                e.x - e.width / 2,
                e.y - e.height / 2 - 16 -- 16 pixels au-dessus du tank
            )
            if stateName == "follow" then
                -- Dessin des obus (pour tous les états, pas seulement follow)
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
        end
    end
end

function Ennemy.Kill(ennemy)
    ennemy.alive = false
end

return Ennemy