-- Débogueur Visual Studio Code tomblind.local-lua-debugger-vscode
if pcall(require, "lldebugger") then
    require("lldebugger").start()
end

-- Cette ligne permet d'afficher des traces dans la console pendant l'éxécution
io.stdout:setvbuf("no")

local myGame = require("game")
local Player = require("player")
local Ennemy = require("ennemy")

function love.load()
    myGame.Load()
    Player.Load()
    Ennemy.Load()
end

-- Fonction utilitaire pour calculer la distance entre deux points
local function getDistance(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx*dx + dy*dy)
end

-- Fonction utilitaire pour vérifier la collision entre deux cercles
local function checkCircleCollision(x1, y1, r1, x2, y2, r2)
    return getDistance(x1, y1, x2, y2) < (r1 + r2)
end

function love.update(dt)
    myGame.Update(dt)
    Player.Update(dt)
    Ennemy.Update(dt, Player)

    -- Gestion des collisions : obus du joueur sur les ennemis
    for i = #Player.bullets, 1, -1 do
        local bullet = Player.bullets[i]
        local bulletHit = false
        
        for _, ennemy in ipairs(Ennemy.list) do
            if ennemy.alive then
                -- Collision plus précise avec rayon approprié
                local bulletRadius = math.min(Player.bulletWidth, Player.bulletHeight) / 4
                local ennemyRadius = math.min(ennemy.width, ennemy.height) / 3
                
                if checkCircleCollision(bullet.x, bullet.y, bulletRadius, 
                                      ennemy.x, ennemy.y, ennemyRadius) then
                    Ennemy.Kill(ennemy)
                    table.remove(Player.bullets, i)
                    bulletHit = true
                    print("Ennemi touché!")
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
                        
                        if checkCircleCollision(bullet.x, bullet.y, bulletRadius,
                                              enemyBullet.x, enemyBullet.y, enemyBulletRadius) then
                            -- Les deux obus se détruisent
                            table.remove(Player.bullets, i)
                            table.remove(ennemy.bullets, j)
                            bulletHit = true
                            print("Collision entre obus!")
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
                
                if checkCircleCollision(bullet.x, bullet.y, bulletRadius,
                                      Player.tank.x, Player.tank.y, playerRadius) then
                    print("Le joueur est touché !")
                    table.remove(ennemy.bullets, i)
                    -- Ici vous pouvez gérer la mort du joueur
                    -- Player.Hit() ou Player.LoseLife() par exemple
                end
            end
        end
    end
    
    -- Gestion des collisions : joueur contre ennemis (collision physique)
    for _, ennemy in ipairs(Ennemy.list) do
        if ennemy.alive then
            local playerRadius = math.min(Player.tank.width, Player.tank.height) / 3
            local ennemyRadius = math.min(ennemy.width, ennemy.height) / 3
            
            if checkCircleCollision(Player.tank.x, Player.tank.y, playerRadius,
                                  ennemy.x, ennemy.y, ennemyRadius) then
                -- Repousser le joueur ou l'ennemi pour éviter qu'ils se chevauchent
                local dx = Player.tank.x - ennemy.x
                local dy = Player.tank.y - ennemy.y
                local distance = math.sqrt(dx*dx + dy*dy)
                
                if distance > 0 then
                    local overlap = (playerRadius + ennemyRadius) - distance
                    local pushX = (dx / distance) * overlap * 0.5
                    local pushY = (dy / distance) * overlap * 0.5
                    
                    -- Repousser les deux entités
                    Player.tank.x = Player.tank.x + pushX
                    Player.tank.y = Player.tank.y + pushY
                    ennemy.x = ennemy.x - pushX
                    ennemy.y = ennemy.y - pushY
                    
                    print("Collision entre joueur et ennemi!")
                end
            end
        end
    end
end

function love.draw()
    myGame.Draw()
    Player.Draw()
    Ennemy.Draw()
    
    -- Optionnel: Afficher des informations de debug
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Ennemis vivants: " .. #Ennemy.list, 10, 10)
    love.graphics.print("Obus joueur: " .. #Player.bullets, 10, 30)
end

function love.keypressed(key)
    Player.KeyPressed(key)
end