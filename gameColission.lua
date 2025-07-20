local Colission = {}
-- Fonction utilitaire pour calculer la distance entre deux points
local function getDistance(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx*dx + dy*dy)
end

-- === COLLISION DETECTION AVEC RAYONS OPTIMISÉS ===
-- Utilise des cercles de collision pour performance et précision
local function checkCircleCollision(x1, y1, r1, x2, y2, r2)
    return getDistance(x1, y1, x2, y2) < (r1 + r2)
end

-- === GESTION CENTRALISÉE DES COLLISIONS ===
function Colission.Update(dt, Player, Ennemy, Game)
-- Gestion des collisions : obus du joueur sur les ennemis
    for i = #Player.bullets, 1, -1 do
        local bullet = Player.bullets[i]
        local bulletHit = false
            
        for _, ennemy in ipairs(Ennemy.list) do
            if ennemy.alive then
                -- Collision plus précise avec rayon approprié
                local bulletRadius = math.min(Player.bulletWidth, Player.bulletHeight) / 4
                local ennemyRadius = math.min(ennemy.width, ennemy.height) / 3
                    
                if checkCircleCollision(bullet.x, bullet.y, bulletRadius, ennemy.x, ennemy.y, ennemyRadius) then
                    Ennemy.Kill(ennemy)
                    table.remove(Player.bullets, i)
                    bulletHit = true
                    Game.AddScore(50)
                    break -- on sort de la boucle ennemy, l'obus est détruit
                end
                    
            end
        end
            
            -- Si l'obus n'a pas touché d'ennemi, vérifier collision avec obus ennemis
        if not bulletHit then
            for _, ennemy in ipairs(Ennemy.list) do
                if ennemy.alive then
                    for j = #ennemy.bullets, 1, -1 do
                        local enemyBullet = ennemy.bullets[j]
                        local bulletRadius = math.min(Player.bulletWidth, Player.bulletHeight) / 4
                        local enemyBulletRadius = math.min(Ennemy.bulletWidth, Ennemy.bulletHeight) / 4
                            
                        if checkCircleCollision(bullet.x, bullet.y, bulletRadius, enemyBullet.x, enemyBullet.y, enemyBulletRadius) then
                            -- Les deux obus se détruisent
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
        
        -- Gestion des collisions : tirs ennemis sur le joueur
    for _, ennemy in ipairs(Ennemy.list) do
        if ennemy.alive then
            for i = #ennemy.bullets, 1, -1 do
                local bullet = ennemy.bullets[i]
                local bulletRadius = math.min(Ennemy.bulletWidth, Ennemy.bulletHeight) / 4
                local playerRadius = math.min(Player.tank.width, Player.tank.height) / 3
                   
                if checkCircleCollision(bullet.x, bullet.y, bulletRadius, Player.tank.x, Player.tank.y, playerRadius) then
                    Player.Hit(10) 
                    table.remove(ennemy.bullets, i)
                    break -- on sort de la boucle ennemy, l'obus est détruit
                end
            end
        end
    end
        
    -- Gestion des collisions : joueur contre ennemis (collision physique)
    for _, ennemy in ipairs(Ennemy.list) do
        if ennemy.alive then
            local playerRadius = math.min(Player.tank.width, Player.tank.height) / 3
            local ennemyRadius = math.min(ennemy.width, ennemy.height) / 3
                
            if checkCircleCollision(Player.tank.x, Player.tank.y, playerRadius, ennemy.x, ennemy.y, ennemyRadius) then
                -- Repousser le joueur ou l'ennemi pour éviter qu'ils se chevauchent
                local dx = Player.tank.x - ennemy.x
                local dy = Player.tank.y - ennemy.y
                local distance = math.sqrt(dx*dx + dy*dy)
                    
                if distance > 0 then
                    local overlap = (playerRadius + ennemyRadius) - distance
                    local pushX = (dx / distance) * overlap * 0.3
                    local pushY = (dy / distance) * overlap * 0.3
                        
                    -- Repousser les deux entités
                    Player.tank.x = Player.tank.x + pushX
                    Player.tank.y = Player.tank.y + pushY
                    ennemy.x = math.max(ennemyRadius, math.min(love.graphics.getWidth()-ennemyRadius, ennemy.x))
                    ennemy.y = math.max(ennemyRadius, math.min(love.graphics.getHeight()-ennemyRadius, ennemy.y))                        
                end
            end
        end
    end
end

return Colission