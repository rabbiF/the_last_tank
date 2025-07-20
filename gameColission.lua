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

-- === FONCTIONS DE CALCUL DES RAYONS (FORCÉES) ===
local function getEnemyRadius(enemy)
    return 20 
end

local function getBulletRadius(bulletWidth, bulletHeight)
    return 12
end

local function getBulletToPlayerRadius(player)
    return 30
end

local function getTankCollisionRadius(width, height)
    return 25
end

-- === CONFIGURATION DE LA DÉTECTION DE PROXIMITÉ ===
local PROXIMITY_CONFIG = {
    detection_radius = 300,      -- Rayon de détection du joueur
    follow_duration = 8.0,       -- === AUGMENTÉ : 8 secondes de poursuite ===
    lost_radius = 500            -- === AUGMENTÉ : Zone de perte plus grande ===
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
                end
                
            elseif distance > PROXIMITY_CONFIG.lost_radius and enemy.hasDetectedPlayer then
                -- JOUEUR PERDU - Arrêter le follow forcé
                Ennemy.StopForceFollow(enemy)
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
    
    -- DEBUG: Compter les bullets ennemies avant collision
    local bulletCountBefore = 0
    for _, ennemy in ipairs(Ennemy.list) do
        if ennemy.alive then
            bulletCountBefore = bulletCountBefore + #ennemy.bullets
        end
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
            
        -- === COLLISION : Obus joueur VS obus ennemis (PROTECTION TEMPORELLE) ===
        if not bulletHit then
            for _, ennemy in ipairs(Ennemy.list) do
                if ennemy.alive then
                    for j = #ennemy.bullets, 1, -1 do
                        local enemyBullet = ennemy.bullets[j]
                        
                        -- === PROTECTION TEMPORELLE au lieu de distance ===
                        if (enemyBullet.lifetime or 0) > 0.1 then  -- Bullet active depuis plus de 0.1 seconde
                            local playerBulletRadius = getBulletRadius(Player.bulletWidth, Player.bulletHeight)
                            local enemyBulletRadius = getBulletRadius(Ennemy.bulletWidth, Ennemy.bulletHeight)
                                
                            if checkCircleCollision(bullet.x, bullet.y, playerBulletRadius, enemyBullet.x, enemyBullet.y, enemyBulletRadius) then
                                table.remove(Player.bullets, i)
                                table.remove(ennemy.bullets, j)
                                bulletHit = true
                                break
                            end             
                        end
                    end
                    if bulletHit then break end
                end
            end
        end
    end
        
    -- === COLLISION : Tirs ennemis sur le joueur (PROTECTION TEMPORELLE AMÉLIORÉE) ===
    for _, ennemy in ipairs(Ennemy.list) do
        if ennemy.alive then
            for i = #ennemy.bullets, 1, -1 do
                local bullet = ennemy.bullets[i]
                
                -- === PROTECTION TEMPORELLE au lieu de distance ===
                if (bullet.lifetime or 0) > 0.15 then  -- Protection temporelle plus longue pour le joueur
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


return Colission