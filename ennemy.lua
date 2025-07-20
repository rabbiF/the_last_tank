local Ennemy = {}
local BULLET_OFFSET = math.rad(90)
local MAX_ENNEMIES = 4
local STATE_DURATION = 2 -- secondes par état
local EXPLOSION_DURATION = 1.0 -- 1 seconde d'explosion
-- === MACHINE À ÉTATS DES ENNEMIS ===
-- States: 1=random, 2=follow, 3=pause (cycle de 2s chacun)
local states = {"random", "follow", "pause"}

-- === FONCTION POUR REMPLACER math.atan2 ===
local function atan2(y, x)
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 then
        if y >= 0 then
            return math.atan(y / x) + math.pi
        else
            return math.atan(y / x) - math.pi
        end
    elseif y > 0 then
        return math.pi / 2
    elseif y < 0 then
        return -math.pi / 2
    else
        return 0  -- Cas où x=0 et y=0
    end
end

function Ennemy.Load()
    Ennemy.bulletImage = love.graphics.newImage("assets/images/bulletRed1.png")
    Ennemy.bulletWidth = Ennemy.bulletImage:getWidth()
    Ennemy.bulletHeight = Ennemy.bulletImage:getHeight()
    Ennemy.explosionImage = love.graphics.newImage("assets/images/explosion2.png")
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
        x = math.random(50, w-50),
        y = math.random(50, h/3),
        speed = 40,
        angle = math.rad(90),
        cannonAngle = 0,
        state = 1,
        stateTimer = STATE_DURATION,
        alive = true,
        exploding = false,
        explosionTimer = 0,
        bullets = {},
        shootTimer = math.random() * 2,
        -- === AJOUT MINIMAL POUR LA DÉTECTION ===
        id = #Ennemy.list + 1,
        hasDetectedPlayer = false,
        forceFollow = false,
        followEndTime = 0
    }
    ennemy.width = ennemy.image:getWidth()
    ennemy.height = ennemy.image:getHeight()
    table.insert(Ennemy.list, ennemy)
end

function Ennemy.Kill(ennemy)
    ennemy.alive = false
    ennemy.exploding = true
    ennemy.explosionTimer = EXPLOSION_DURATION
end

function Ennemy.Update(dt, player)
    for i = #Ennemy.list, 1, -1 do
        local e = Ennemy.list[i]
        
        if e.exploding then
            e.explosionTimer = e.explosionTimer - dt
            if e.explosionTimer <= 0 then
                table.remove(Ennemy.list, i)
            end
        elseif e.alive then
            -- === SEULE MODIFICATION : Vérifier le follow forcé ===
            local currentTime = love.timer.getTime()
            if e.forceFollow and currentTime < e.followEndTime then
                -- Follow forcé par détection
                e.state = 2
            else
                e.forceFollow = false
                e.stateTimer = e.stateTimer - dt
                if e.stateTimer <= 0 then
                    e.state = e.state % 3 + 1
                    e.stateTimer = STATE_DURATION
                    e.justChangedState = true
                end
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
                -- === UTILISE LA FONCTION CUSTOM AU LIEU DE math.atan2 ===
                local angleToPlayer = atan2(dy, dx)
                e.angle = angleToPlayer
                e.x = e.x + math.cos(e.angle) * e.speed * dt
                e.y = e.y + math.sin(e.angle) * e.speed * dt
                e.cannonAngle = angleToPlayer - math.pi/2
                
            elseif states[e.state] == "pause" then
                local dx = player.tank.x - e.x
                local dy = player.tank.y - e.y
                -- === Utilise atan2 au lieu de math.atan ===
                e.cannonAngle = atan2(dy, dx) - math.pi/2
            end
            
            -- Empêcher de sortir de l'écran
            e.x = math.max(e.width/2, math.min(love.graphics.getWidth()-e.width/2, e.x))
            e.y = math.max(e.height/2, math.min(love.graphics.getHeight()-e.height/2, e.y))

            -- === GESTION DES TIRS (AMÉLIORÉE) ===
            if states[e.state] == "follow" or states[e.state] == "pause" then
                e.shootTimer = (e.shootTimer or 0) - dt
                if e.shootTimer <= 0 then
                    e.shootTimer = 2
                    local fireAngle = e.cannonAngle + math.pi/2
                    local offset = math.max(e.width, e.height) * 0.8
                    local bx = e.x + math.cos(fireAngle) * offset
                    local by = e.y + math.sin(fireAngle) * offset
                    
                    -- === CRÉATION AMÉLIORÉE DE LA BULLET ===
                    table.insert(e.bullets, {
                        x = bx,
                        y = by,
                        angle = fireAngle,
                        id = math.random(1000, 9999),
                        owner = e.id,
                        lifetime = 0,
                        created_time = love.timer.getTime(),
                        speed = 300
                    })
                end
            else
                e.shootTimer = math.random() * 2
            end

            -- === DÉPLACEMENT DES OBUS (AMÉLIORÉ) ===            
            for j = #e.bullets, 1, -1 do
                local b = e.bullets[j]
                local speed = b.speed or 300
                
                -- === INCRÉMENTER LA DURÉE DE VIE ===
                b.lifetime = (b.lifetime or 0) + dt
                
                -- Mouvement
                b.x = b.x + math.cos(b.angle) * speed * dt
                b.y = b.y + math.sin(b.angle) * speed * dt
                
                -- === LIMITE DE TEMPS pour éviter les bullets infinies ===
                local maxLifetime = 10.0  -- 10 secondes max
                if b.lifetime > maxLifetime then
                    table.remove(e.bullets, j)
                end
                -- === LIMITES  ===
                local margin = 100
                local screenW = love.graphics.getWidth()
                local screenH = love.graphics.getHeight()
                
                if b.x < -margin or b.x > screenW + margin or 
                   b.y < -margin or b.y > screenH + margin then
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

-- === API POUR GAMECOLISSION ===
function Ennemy.ForceFollow(enemy, duration)
    enemy.forceFollow = true
    enemy.followEndTime = love.timer.getTime() + duration
    enemy.state = 2
    enemy.hasDetectedPlayer = true
end

function Ennemy.StopForceFollow(enemy)
    enemy.forceFollow = false
    enemy.hasDetectedPlayer = false
end

-- === FONCTION DRAW ===
function Ennemy.Draw()
    -- ÉTAPE 1: Dessiner d'abord tous les tanks
    for _, e in ipairs(Ennemy.list) do
        if e.alive then
            -- Dessiner le tank ennemi
            love.graphics.setColor(1, 1, 1) -- Blanc pour le tank
            love.graphics.draw(
                e.image,
                e.x, e.y,
                e.cannonAngle,
                1, 1,
                e.width / 2, e.height / 2
            )
    
        elseif e.exploding then
            -- Dessiner l'explosion
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(
                Ennemy.explosionImage,
                e.x, e.y,
                0,
                1, 1,
                Ennemy.explosionImage:getWidth() / 2,
                Ennemy.explosionImage:getHeight() / 2
            )
        end
    end
    
    -- ÉTAPE 2: Dessiner TOUTES les bullets PAR-DESSUS les tanks
    for _, e in ipairs(Ennemy.list) do
        if e.alive and #e.bullets > 0 then

            -- === DESSINER LES BULLETS  ===
            for i, b in ipairs(e.bullets) do
                
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
    
    -- Remettre la couleur blanche par défaut
    love.graphics.setColor(1, 1, 1)
end

return Ennemy