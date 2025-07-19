local Player = require("player")
local Ennemy = require("ennemy")
local UI = require("gameUI")
-- Fichier pour gérer la carte et les tuiles du jeu
local Game = {}


Game.Map = {}
Game.Map.Grid =  {
    {1, 21, 21, 21, 21, 1, 21, 21, 21, 21, 21, 21, 21},
    {21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21},
    {21, 21, 21, 21, 1, 21, 21, 21, 21, 21, 21, 21, 21},
    {1, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 1, 21},
    {21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21},
    {21, 21, 21, 21, 21, 1, 21, 21, 21, 21, 21, 21, 21},
    {21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21},
    {21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21},
    {21, 21, 21, 1, 21, 21, 21, 21, 21, 21, 21, 1, 21},
    {21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21},
    {21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21},
    {21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21},
    {21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21}
  }


Game.Map.MAP_WIDTH = 16
Game.Map.MAP_HEIGHT = 12
Game.Map.TILE_WIDTH  = 64
Game.Map.TILE_HEIGHT = 64

Game.TileSheet = nil
Game.TileTextures = {}
Game.TileTypes = {}


-- === PARTIE MAE (nouvelle) ===
Game.State = {
    current = "MENU",
    previous = nil
}

-- Modes de jeu disponibles
Game.GameModes = {
    current = "survival",  -- Par défaut    
    -- Configuration Survival
    survival = {
        active = false
    },    
    -- Configuration Timed  
    timed = {
        active = false,
        duration = 60,      -- Durée en secondes
        timeRemaining = 0   -- Temps restant
    },    
    -- Configuration Score
    score = {
        active = false,
        target = 1000,      -- Score à atteindre
        current = 0         -- Score actuel
    }
}
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

-- === FONCTIONS DE CONFIGURATION DES MODES ===
function Game.SetSurvivalMode()
    print("Mode Survival sélectionné")
    Game.GameModes.current = "survival"
    Game.GameModes.survival.active = true
    Game.GameModes.timed.active = false
    Game.GameModes.score.active = false
end

function Game.SetTimedMode(minutes)
    minutes = minutes or 2  -- 2 minutes par défaut
    print("Mode Timed sélectionné:", minutes, "minutes")
    Game.GameModes.current = "timed"
    Game.GameModes.timed.active = true
    Game.GameModes.timed.duration = minutes * 60
    Game.GameModes.timed.timeRemaining = minutes * 60
    Game.GameModes.survival.active = false
    Game.GameModes.score.active = false
end

function Game.SetScoreMode(targetScore)
    targetScore = targetScore or 1000  -- 1000 points par défaut
    print("Mode Score sélectionné:", targetScore, "points")
    Game.GameModes.current = "score"
    Game.GameModes.score.active = true
    Game.GameModes.score.target = targetScore
    Game.GameModes.score.current = 0
    Game.GameModes.survival.active = false
    Game.GameModes.timed.active = false
end

function Game.StartGameplay()
    Game.ChangeState("GAMEPLAY")
    
    Player.Load()
    Ennemy.Load()
    
    -- Configuration du callback de mort du joueur
    Player.onDeath = function()
        Ennemy.Load()
    end
end

-- === FONCTIONS MAE ===
function Game.ChangeState(newState)
    Game.State.previous = Game.State.current
    Game.State.current = newState
    print(newState)
    -- Actions lors des transitions
    if newState == "MENU" then
        Game.OnreturnMenu()
    elseif newState == "GAMEPLAY" then
        Game.OnreturnGameplay()
    elseif newState == "PAUSE" then
        Game.OnreturnPause()
    elseif newState == "GAMEOVER" then
        Game.OnreturnGameOver()
    elseif newState == "VICTORY" then
        Game.OnreturnVictory()
    end
end

-- === CALLBACKS D'ÉTATS ===
function Game.OnreturnMenu()
    print("=== MENU ===")
end

function Game.OnreturnGameplay()
    print("=== GAMEPLAY DÉMARRÉ ===")
end

function Game.OnreturnPause()
    print("=== PAUSE ===")
end

function Game.OnreturnGameOver()
    print("=== GAME OVER ===")
end

function Game.OnreturnVictory()
    print("=== VICTOIRE ===")
end

-- === FONCTIONS PRINCIPALES ===
function Game.Load()
    
    Game.TileSheet = love.graphics.newImage("assets/images/terrain.png")
    local nbColumns = Game.TileSheet:getWidth() / Game.Map.TILE_WIDTH
    local nbLines = Game.TileSheet:getHeight() / Game.Map.TILE_HEIGHT

    local l,c
    local id = 1
    Game.TileTextures[0] = nil
    for l=1,nbLines do
        for c=1,nbColumns do
            Game.TileTextures[id] = love.graphics.newQuad(
                (c-1)*Game.Map.TILE_WIDTH, 
                (l-1)*Game.Map.TILE_HEIGHT, 
                Game.Map.TILE_WIDTH, 
                Game.Map.TILE_HEIGHT, 
                Game.TileSheet:getWidth(), 
                Game.TileSheet:getHeight()
            )

            id = id + 1
        end
    end

    Game.TileTypes[21] = "Sand"
    Game.TileTypes[1] = "Grass"
    

   Game.Map.SeenGrid = {}
    for l=1, Game.Map.MAP_HEIGHT do
        Game.Map.SeenGrid[l] = {}
        for c=1, Game.Map.MAP_WIDTH do
            Game.Map.SeenGrid[l][c] = false
        end
    end

    Player.Load()
    Ennemy.Load()

    Player.onDeath = function()
        Ennemy.Load() -- Recharger les ennemis quand le joueur meurt        
    end   

    UI.Load()
end

function Game.Update(dt)
    if Game.State.current == "MENU" then
        Game.UpdateMenu(dt)
    elseif Game.State.current == "GAMEPLAY" then
        Game.UpdateGameplay(dt)
    elseif Game.State.current == "PAUSE" then
        Game.UpdatePause(dt)
    elseif Game.State.current == "GAMEOVER" then
        Game.UpdateGameOver(dt)
    elseif Game.State.current == "VICTORY" then
        Game.UpdateVictory(dt)
    end
end

function Game.Draw()
    -- Toujours dessiner la carte en arrière-plan
    Game.DrawMap()
    
    if Game.State.current == "MENU" then
        Game.DrawMenu()
    elseif Game.State.current == "GAMEPLAY" then
        Game.DrawGameplay()
    elseif Game.State.current == "PAUSE" then
        Game.DrawPause()
    elseif Game.State.current == "GAMEOVER" then
        Game.DrawGameOver()
    elseif Game.State.current == "VICTORY" then
        Game.DrawVictory()
    end
end

function Game.KeyPressed(key)
    if key == "escape" then
        love.event.quit()  -- Quitter le jeu
    elseif Game.State.current == "MENU" then
        Game.KeyPressedMenu(key)
    elseif Game.State.current == "GAMEPLAY" then
        Game.KeyPressedGameplay(key)
    elseif Game.State.current == "PAUSE" then
        Game.KeyPressedPause(key)
    elseif Game.State.current == "GAMEOVER" then
        Game.KeyPressedGameOver(key)
    elseif Game.State.current == "VICTORY" then
        Game.KeyPressedVictory(key)
    end
end

-- === LOGIQUES PAR ÉTAT ===
function Game.UpdateMenu(dt)
    -- Logique du menu (pour plus tard avec UI)
end

function Game.UpdateGameplay(dt) 
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
                    
                if checkCircleCollision(bullet.x, bullet.y, bulletRadius, ennemy.x, ennemy.y, ennemyRadius) then
                    Ennemy.Kill(ennemy)
                    table.remove(Player.bullets, i)
                    bulletHit = true
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

    -- Gestion spécifique des modes
    if Game.GameModes.timed.active then
        Game.GameModes.timed.timeRemaining = Game.GameModes.timed.timeRemaining - dt
        if Game.GameModes.timed.timeRemaining <= 0 then
            Game.ChangeState("VICTORY")
        end
    elseif Game.GameModes.score.active then
        -- Le score sera mis à jour lors des destructions d'ennemis
        if Game.GameModes.score.current >= Game.GameModes.score.target then
            Game.ChangeState("VICTORY")
        end
    end
    -- Mode survival : pas de condition de victoire

    if Player.currentLife <= 0  then
        Game.ChangeState("GAMEOVER")
    end
end

function Game.UpdatePause(dt)
    -- Rien ne bouge en pause
end

function Game.UpdateGameOver(dt)
    -- Logique de game over
end

function Game.UpdateVictory(dt)
    -- Logique de victoire
end

-- === FONCTIONS DE DESSIN ===
function Game.DrawMap()
    local c, l
    for l = 1, Game.Map.MAP_HEIGHT do
        for c = 1, Game.Map.MAP_WIDTH do
            if Game.Map.Grid[l] ~= nil and Game.Map.Grid[l][c] ~= nil then
                local id = Game.Map.Grid[l][c]            
                local texQuad = Game.TileTextures[id]
                if texQuad ~= nil then
                    local x = (c-1) * Game.Map.TILE_WIDTH
                    local y = (l-1) * Game.Map.TILE_HEIGHT
                    love.graphics.draw(Game.TileSheet, texQuad, x, y)
                end
            end
        end
    end
end

function Game.DrawMenu()
    UI.DrawMenu()
end

function Game.DrawGameplay()
    
    Player.Draw()
    Ennemy.Draw()
    Player.DrawUI()
    
    -- Affichage spécifique au mode
    love.graphics.setColor(1, 1, 1)
    if Game.GameModes.timed.active then
        love.graphics.print("Temps restant: " .. math.ceil(Game.GameModes.timed.timeRemaining), 10, 150)
    elseif Game.GameModes.score.active then
        love.graphics.print("Score: " .. Game.GameModes.score.current .. "/" .. Game.GameModes.score.target, 10, 150)
    else
        love.graphics.print("Mode: Survival", 10, 150)
    end
end

function Game.DrawPause()
    Game.DrawGameplay()  -- Dessiner le jeu en arrière-plan
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("=== PAUSE ===", love.graphics.getWidth()/2 - 50, love.graphics.getHeight()/2)
end

function Game.DrawGameOver()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("=== GAME OVER ===", love.graphics.getWidth()/2 - 80, love.graphics.getHeight()/2)
end

function Game.DrawVictory()
    love.graphics.setColor(0, 1, 0)
    love.graphics.print("=== VICTOIRE ===", love.graphics.getWidth()/2 - 70, love.graphics.getHeight()/2)
end

-- === GESTION DES TOUCHES PAR ÉTAT ===
function Game.KeyPressedMenu(key)
    UI.KeyPressedMenu(key)
end

function Game.KeyPressedGameplay(key)

    if key == "escape" then
        Game.ChangeState("PAUSE")
    else
        -- Transmettre toutes les autres touches au joueur
        Player.KeyPressed(key)        
    end
end

function Game.KeyPressedPause(key)
    if key == "escape" then
        Game.ChangeState("GAMEPLAY")
    end
end

function Game.KeyPressedGameOver(key)
    if key == "return" then 
        Game.ChangeState("MENU")
    end
end

function Game.KeyPressedVictory(key)
    if key == "return" then 
        Game.ChangeState("MENU")
    end
end
-- === FONCTIONS UTILITAIRES ===
function Game.AddScore(points)
    if Game.GameModes.score.active then
        Game.GameModes.score.current = Game.GameModes.score.current + points
        print("Score:", Game.GameModes.score.current .. "/" .. Game.GameModes.score.target)
    end
end


return Game