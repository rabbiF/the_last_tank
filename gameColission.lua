-- gameColission.lua - Version corrigée avec debug visuel
local Colission = {}

-- === CONFIGURATION DES RAYONS DE COLLISION ===
-- BEAUCOUP plus généreux que l'original !
local COLLISION_CONFIG = {
    player_radius_factor = 0.4,      -- 40% de la taille du sprite (au lieu de 33%)
    enemy_radius_factor = 0.4,       -- 40% de la taille du sprite  
    bullet_radius_factor = 1.5,      -- 150% de la taille du sprite (très généreux)
    bullet_to_player_factor = 0.45,  -- 45% pour balle vers joueur
    tank_collision_factor = 0.35,    -- 35% pour collision tank vs tank
    
    -- Debug visuel
    debug_enabled = false  -- Passez à true pour voir les cercles de collision
}

-- Fonction utilitaire pour calculer la distance entre deux points
local function getDistance(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx*dx + dy*dy)
end

-- === COLLISION DETECTION AVEC RAYONS OPTIMISÉS ===
local function checkCircleCollision(x1, y1, r1, x2, y2, r2)
    return getDistance(x1, y1, x2, y2) < (r1 + r2)
end

-- === FONCTIONS DE DEBUG VISUEL ===
local function drawDebugCircle(x, y, radius, color)
    if not COLLISION_CONFIG.debug_enabled then return end
    
    love.graphics.setColor(color[1], color[2], color[3], 0.3)
    love.graphics.circle("fill", x, y, radius)
    love.graphics.setColor(color[1], color[2], color[3], 0.8)
    love.graphics.circle("line", x, y, radius)
end

-- === FONCTIONS DE CALCUL DES RAYONS ===
local function getPlayerRadius(player)
    local size = math.max(player.tank.width, player.tank.height)
    return size * COLLISION_CONFIG.player_radius_factor
end

local function getEnemyRadius(enemy)
    local size = math.max(enemy.width, enemy.height)
    return size * COLLISION_CONFIG.enemy_radius_factor  
end

local function getBulletRadius(bulletWidth, bulletHeight)
    local size = math.max(bulletWidth, bulletHeight)
    return size * COLLISION_CONFIG.bullet_radius_factor
end

local function getBulletToPlayerRadius(player)
    local size = math.max(player.tank.width, player.tank.height)
    return size * COLLISION_CONFIG.bullet_to_player_factor
end

local function getTankCollisionRadius(width, height)
    local size = math.max(width, height)
    return size * COLLISION_CONFIG.tank_collision_factor
end

-- === CONFIGURATION DE LA DÉTECTION DE PROXIMITÉ ===
local PROXIMITY_CONFIG = {
    detection_radius = 300,      -- Rayon de détection du joueur
    follow_duration = 5.0,       -- Durée de poursuite forcée
    lost_radius = 450            -- Rayon de perte de contact
}

-- === SYSTÈME DE DÉTECTION DE PROXIMITÉ ===
local function updateEnemyProximityDetection(Player, Ennemy, dt)
    for _, enemy in ipairs(Ennemy.list) do
        if enemy.alive then
            -- Calculer la distance au joueur
            local distance = getDistance(enemy.x, enemy.y, Player.tank.x, Player.tank.y)
            
            -- Initialiser le flag de détection si nécessaire
            enemy.hasDetectedPlayer = enemy.hasDetectedPlayer or false
            
            -- === DÉTECTION IMMÉDIATE (chaque frame) ===
            if distance <= PROXIMITY_CONFIG.detection_radius then
                -- JOUEUR DÉTECTÉ - Forcer le follow via la nouvelle API
                if not enemy.hasDetectedPlayer then
                    Ennemy.ForceFollow(enemy, PROXIMITY_CONFIG.follow_duration)
                    
                    -- Debug
                    if COLLISION_CONFIG.debug_enabled then
                        print("🎯 Ennemi " .. (enemy.id or "?") .. " DÉTECTE le joueur à " .. math.floor(distance) .. "px - Mode FOLLOW forcé")
                    end
                end
                
            elseif distance > PROXIMITY_CONFIG.lost_radius and enemy.hasDetectedPlayer then
                -- JOUEUR PERDU - Arrêter le follow forcé
                Ennemy.StopForceFollow(enemy)
                if COLLISION_CONFIG.debug_enabled then
                    print("❌ Ennemi " .. (enemy.id or "?") .. " PERD le joueur à " .. math.floor(distance) .. "px")
                end
            end
        end
    end
end

-- === GESTION CENTRALISÉE DES COLLISIONS ===
function Colission.Update(dt, Player, Ennemy, Game)
    -- Vérifier que le joueur est vivant
    if not Player.isAlive then
        return
    end
    
    -- === NOUVEAU : Système de détection de proximité ===
    updateEnemyProximityDetection(Player, Ennemy, dt)

    -- === COLLISION : Obus du joueur sur les ennemis ===
    for i = #Player.bullets, 1, -1 do
        local bullet = Player.bullets[i]
        local bulletHit = false
            
        for _, ennemy in ipairs(Ennemy.list) do
            if ennemy.alive then
                local bulletRadius = getBulletRadius(Player.bulletWidth, Player.bulletHeight)
                local ennemyRadius = getEnemyRadius(ennemy)
                    
                if checkCircleCollision(bullet.x, bullet.y, bulletRadius, ennemy.x, ennemy.y, ennemyRadius) then
                    Ennemy.Kill(ennemy)
                    table.remove(Player.bullets, i)
                    bulletHit = true
                    Game.AddScore(50)
                    break
                end
            end
        end
            
        -- === COLLISION : Obus joueur VS obus ennemis ===
        if not bulletHit then
            for _, ennemy in ipairs(Ennemy.list) do
                if ennemy.alive then
                    for j = #ennemy.bullets, 1, -1 do
                        local enemyBullet = ennemy.bullets[j]
                        local playerBulletRadius = getBulletRadius(Player.bulletWidth, Player.bulletHeight)
                        local enemyBulletRadius = getBulletRadius(Ennemy.bulletWidth, Ennemy.bulletHeight)
                            
                        if checkCircleCollision(bullet.x, bullet.y, playerBulletRadius, enemyBullet.x, enemyBullet.y, enemyBulletRadius) then
                            table.remove(Player.bullets, i)
                            table.remove(ennemy.bullets, j)
                            bulletHit = true
                            break
                        end
                    end
                    if bulletHit then break end
                end
            end
        end
    end
        
    -- === COLLISION : Tirs ennemis sur le joueur ===
    for _, ennemy in ipairs(Ennemy.list) do
        if ennemy.alive then
            for i = #ennemy.bullets, 1, -1 do
                local bullet = ennemy.bullets[i]
                local bulletRadius = getBulletRadius(Ennemy.bulletWidth, Ennemy.bulletHeight)
                local playerRadius = getBulletToPlayerRadius(Player)
                   
                if checkCircleCollision(bullet.x, bullet.y, bulletRadius, Player.tank.x, Player.tank.y, playerRadius) then
                    Player.Hit(10) 
                    table.remove(ennemy.bullets, i)
                    break
                end
            end
        end
    end
        
    -- === COLLISION : Joueur contre ennemis (collision physique) ===
    for _, ennemy in ipairs(Ennemy.list) do
        if ennemy.alive then
            local playerRadius = getTankCollisionRadius(Player.tank.width, Player.tank.height)
            local ennemyRadius = getTankCollisionRadius(ennemy.width, ennemy.height)
                
            if checkCircleCollision(Player.tank.x, Player.tank.y, playerRadius, ennemy.x, ennemy.y, ennemyRadius) then
                -- Repousser le joueur et l'ennemi
                local dx = Player.tank.x - ennemy.x
                local dy = Player.tank.y - ennemy.y
                local distance = math.sqrt(dx*dx + dy*dy)
                    
                if distance > 0 then
                    local overlap = (playerRadius + ennemyRadius) - distance
                    local pushX = (dx / distance) * overlap * 0.6
                    local pushY = (dy / distance) * overlap * 0.6
                        
                    -- Repousser les deux entités
                    Player.tank.x = Player.tank.x + pushX
                    Player.tank.y = Player.tank.y + pushY
                    ennemy.x = ennemy.x - pushX * 0.4
                    ennemy.y = ennemy.y - pushY * 0.4
                    
                    -- Contraintes écran
                    ennemy.x = math.max(ennemyRadius, math.min(love.graphics.getWidth()-ennemyRadius, ennemy.x))
                    ennemy.y = math.max(ennemyRadius, math.min(love.graphics.getHeight()-ennemyRadius, ennemy.y))
                    
                    -- Dégâts de contact
                    Player.Hit(2)
                end
            end
        end
    end
end

-- === FONCTION DE DEBUG VISUEL ===
-- Appelez cette fonction dans votre Game.DrawGameplay() pour voir les collisions
function Colission.DrawDebug(Player, Ennemy)
    if not COLLISION_CONFIG.debug_enabled then return end
    
    -- Cercle du joueur (vert)
    if Player.isAlive then
        local playerRadius = getPlayerRadius(Player)
        drawDebugCircle(Player.tank.x, Player.tank.y, playerRadius, {0, 1, 0})
        
        -- Cercle pour réception des balles (bleu)
        local bulletToPlayerRadius = getBulletToPlayerRadius(Player)
        drawDebugCircle(Player.tank.x, Player.tank.y, bulletToPlayerRadius, {0, 0, 1})
        
        -- Cercle pour collision physique (jaune)
        local tankCollisionRadius = getTankCollisionRadius(Player.tank.width, Player.tank.height)
        drawDebugCircle(Player.tank.x, Player.tank.y, tankCollisionRadius, {1, 1, 0})
    end
    
    -- Cercles des ennemis (rouge)
    for _, ennemy in ipairs(Ennemy.list) do
        if ennemy.alive then
            local ennemyRadius = getEnemyRadius(ennemy)
            drawDebugCircle(ennemy.x, ennemy.y, ennemyRadius, {1, 0, 0})
            
            -- Cercle pour collision physique (orange)
            local tankCollisionRadius = getTankCollisionRadius(ennemy.width, ennemy.height)
            drawDebugCircle(ennemy.x, ennemy.y, tankCollisionRadius, {1, 0.5, 0})
            
            -- === CERCLES DE DÉTECTION ===
            local detectionRadius = PROXIMITY_CONFIG.detection_radius
            local lostRadius = PROXIMITY_CONFIG.lost_radius
            
            -- Zone de détection (bleu clair)
            drawDebugCircle(ennemy.x, ennemy.y, detectionRadius, {0.3, 0.7, 1})
            
            -- Zone de perte (bleu très clair)
            drawDebugCircle(ennemy.x, ennemy.y, lostRadius, {0.1, 0.3, 0.5})
            
            -- Afficher l'état actuel de l'ennemi avec couleur
            love.graphics.setColor(1, 1, 1)
            local states = {"random", "follow", "pause"}
            local stateName = states[ennemy.state] or "unknown"
            local hasDetected = ennemy.hasDetectedPlayer and " 👁️" or ""
            local displayText = stateName .. hasDetected
            
            -- Couleur selon l'état
            if ennemy.state == 2 then  -- follow
                love.graphics.setColor(1, 0, 0)  -- Rouge vif
            elseif ennemy.hasDetectedPlayer then
                love.graphics.setColor(1, 1, 0)  -- Jaune
            else
                love.graphics.setColor(1, 1, 1)  -- Blanc
            end
            
            love.graphics.print(displayText, ennemy.x - 25, ennemy.y - 45)
        end
    end
    
    -- Cercles des balles joueur (vert clair)
    for _, bullet in ipairs(Player.bullets) do
        local bulletRadius = getBulletRadius(Player.bulletWidth, Player.bulletHeight)
        drawDebugCircle(bullet.x, bullet.y, bulletRadius, {0.5, 1, 0.5})
    end
    
    -- Cercles des balles ennemies (rouge clair)
    for _, ennemy in ipairs(Ennemy.list) do
        if ennemy.alive then
            for _, bullet in ipairs(ennemy.bullets) do
                local bulletRadius = getBulletRadius(Ennemy.bulletWidth, Ennemy.bulletHeight)
                drawDebugCircle(bullet.x, bullet.y, bulletRadius, {1, 0.5, 0.5})
            end
        end
    end
    
    -- Remettre la couleur normale
    love.graphics.setColor(1, 1, 1)
end

-- === FONCTION POUR ACTIVER/DÉSACTIVER LE DEBUG ===
function Colission.ToggleDebug()
    COLLISION_CONFIG.debug_enabled = not COLLISION_CONFIG.debug_enabled
    print("Debug collision: " .. (COLLISION_CONFIG.debug_enabled and "ON" or "OFF"))
end

function Colission.EnableDebug(enabled)
    COLLISION_CONFIG.debug_enabled = enabled
end

return Colission