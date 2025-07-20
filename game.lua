-- === ARCHITECTURE MODULAIRE ===
-- game.lua : Orchestrateur principal (MAE + modes)
-- player.lua/ennemy.lua : Logique métier
-- gameUI.lua : Interface utilisateur
-- gameColission.lua : Système de collision centralisé
local Player = require("player")
local Ennemy = require("ennemy")
local UI = require("gameUI")

-- Fichier pour gérer la carte et les tuiles du jeu
local Game = {}

Game.Map = {}
-- Tilemap statique
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
    current = "MENU", -- MAE non-linéaire : MENU ↔ GAMEPLAY ↔ PAUSE/GAMEOVER/VICTORY
    previous = nil
}

-- === MODES DE JEU CONFIGURABLES ===
-- Survival : Survie infinie
-- Timed : Chronométré avec victoire si temps écoulé  
-- Score : Objectif de points à atteindre
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

-- === FONCTIONS DE CONFIGURATION DES MODES ===
function Game.SetSurvivalMode()
    Game.GameModes.current = "survival"
    Game.GameModes.survival.active = true
    Game.GameModes.timed.active = false
    Game.GameModes.score.active = false
end

function Game.SetTimedMode(minutes)
    minutes = minutes or 2  -- 2 minutes par défaut
    Game.GameModes.current = "timed"
    Game.GameModes.timed.active = true
    Game.GameModes.timed.duration = minutes * 60
    Game.GameModes.timed.timeRemaining = minutes * 60
    Game.GameModes.survival.active = false
    Game.GameModes.score.active = false
end

function Game.SetScoreMode(targetScore)
    targetScore = targetScore or 1000  -- 1000 points par défaut
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
    if Game.State.current == "GAMEPLAY" then
        Game.UpdateGameplay(dt)
    end

    if love.keyboard.isDown("d") then
        Ennemy.debug = true  -- voir l'etat des ennemis  {"random", "follow", "pause"}
    else
        Ennemy.debug = false
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

    -- Gestion des collissions
    local Colission = require("gameColission")
    Colission.Update(dt, Player, Ennemy, Game)

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

function Game.DrawText(text)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, love.graphics.getWidth()/2 - 50, love.graphics.getHeight()/2)
end

function Game.DrawPause()
    Game.DrawGameplay()  -- Dessiner le jeu en arrière-plan
    love.graphics.setColor(0, 0, 0, 0.5)
    Game.DrawText("=== PAUSE ===")
end

function Game.DrawGameOver()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    Game.DrawText("=== GAME OVER ===")
end

function Game.DrawVictory()
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    Game.DrawText("=== VICTOIRE ===")
end

-- === GESTION DES TOUCHES PAR ÉTAT ===
function Game.KeyPressedMenu(key)
    UI.KeyPressedMenu(key)
end

function Game.KeyPressedGameplay(key)
    if key == "backspace" then
        Game.ChangeState("PAUSE")
    else 
        Player.KeyPressed(key)  -- Transmettre toutes les autres touches au joueur   
    end
end

function Game.KeyPressedPause(key)
    if key == "backspace" then
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
    end
end


return Game