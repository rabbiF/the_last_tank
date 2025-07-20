local UI = {}

function UI.Load()
    UI.assets = {
        arrow = love.graphics.newImage("assets/images/ui/arrow.png"),
        buttonNormal = love.graphics.newImage("assets/images/ui/buttonNormal.png"),
        buttonSelected = love.graphics.newImage("assets/images/ui/buttonSelected.png"),
        background = love.graphics.newImage("assets/images/ui/fond.png"),
        logo1 = love.graphics.newImage("assets/images/ui/rectangle1.png"),
        logo2 = love.graphics.newImage("assets/images/ui/rectangle2.png"),
        logo3 = love.graphics.newImage("assets/images/ui/rectangle3.png")
    }
     UI.fonts = {
        title = love.graphics.newFont("assets/fonts/AllertaStencil-Regular.ttf", 24),      -- Police titre
        menu = love.graphics.newFont("assets/fonts/AllertaStencil-Regular.ttf", 16),       -- Police menu
        button = love.graphics.newFont("assets/fonts/AllertaStencil-Regular.ttf", 14),     -- Police boutons
        small = love.graphics.newFont("assets/fonts/AllertaStencil-Regular.ttf", 12)       -- Petits textes
    }

    -- Police par défaut pour les erreurs si le chargement échoue
    UI.defaultFont = love.graphics.newFont(16)

    UI.menuState = "MAIN"  -- MAIN, TIMED_CONFIG, SCORE_CONFIG, COMMANDES
    UI.selectedOption = 1
    
    -- Définition des menus
    UI.menus = {
        -- Menu principal + sous-menus (Timed/Score)
        MAIN = {
            title = "THE LAST TANK",
            options = {
                {text = "SURVIVAL", action = "survival"},
                {text = "TIMED", action = "timed_config"},
                {text = "SCORE", action = "score_config"}
            }
        },
        
        TIMED_CONFIG = {
            title = "DUREE DE SURVIE",
            options = {
                {text = "1 MINUTE", action = "timed", value = 1},
                {text = "2 MINUTES", action = "timed", value = 2},
                {text = "5 MINUTES", action = "timed", value = 5},
                {text = "RETOUR", action = "back"}
            }
        },
        
        SCORE_CONFIG = {
            title = "OBJECTIF DE SCORE",
            options = {
                {text = "500 POINTS", action = "score", value = 500},
                {text = "1000 POINTS", action = "score", value = 1000},
                {text = "2000 POINTS", action = "score", value = 2000},
                {text = "RETOUR", action = "back"}
            }
        }
    }
end
-- === ARCHITECTURE MODULAIRE UI ===
-- Évite les dépendances circulaires UI ↔ Renderer
local Renderer = require("gameUIrenderer")

-- LE MENU
function UI.DrawMenu()
    if not UI.assets then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("ERREUR: Assets non chargés!", 10, 10)
        return
    end

    -- Dessiner le fond
    Renderer.DrawTiledBackground()
    
    local screenWidth = love.graphics.getWidth()
    local currentMenu = UI.menus[UI.menuState]
    
    -- Logo avec titre du menu actuel
    Renderer.DrawLogoWithAdaptedText(screenWidth / 2, 60, currentMenu.title, UI.assets)
    
    -- Menu avec boutons
    Renderer.DrawButtonMenu(currentMenu.options, 180, UI)  -- Y = 180 pour position des boutons

    Renderer.DrawControlsInMenu()
end

--  NAVIGATION CLAVIER
function UI.KeyPressedMenu(key)
    local currentMenu = UI.menus[UI.menuState]
    local maxOptions = #currentMenu.options
    
    if key == "up" then
        UI.selectedOption = UI.selectedOption - 1
        if UI.selectedOption < 1 then
            UI.selectedOption = maxOptions
        end
        
    elseif key == "down" then
        UI.selectedOption = UI.selectedOption + 1
        if UI.selectedOption > maxOptions then
            UI.selectedOption = 1
        end
        
    elseif key == "return" then
        UI.ExecuteMenuSelection()
    end
end

function UI.ExecuteMenuSelection()
    local currentMenu = UI.menus[UI.menuState]
    local selectedOption = currentMenu.options[UI.selectedOption]
    local action = selectedOption.action
    
    -- Import Game pour éviter les dépendances circulaires
    local Game = require("game")
    
    if action == "survival" then
        Game.SetSurvivalMode()
        Game.StartGameplay()        
    elseif action == "timed_config" then
        UI.menuState = "TIMED_CONFIG"
        UI.selectedOption = 1        
    elseif action == "score_config" then
        UI.menuState = "SCORE_CONFIG"
        UI.selectedOption = 1    
    elseif action == "timed" then
        local minutes = selectedOption.value
        Game.SetTimedMode(minutes)
        Game.StartGameplay()
        
    elseif action == "score" then
        local target = selectedOption.value
        Game.SetScoreMode(target)
        Game.StartGameplay()
        
    elseif action == "back" then
        UI.menuState = "MAIN"
        UI.selectedOption = 1
    end
end

return UI