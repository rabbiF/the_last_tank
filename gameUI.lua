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

    UI.menuState = "MAIN"  -- MAIN, TIMED_CONFIG, SCORE_CONFIG
    UI.selectedOption = 1
    
    -- Définition des menus
    UI.menus = {
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

function UI.Update(dt)

end

function UI.Draw()

end

function UI.DrawMenu()
    if not UI.assets then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("ERREUR: Assets non chargés!", 10, 10)
        return
    end

    -- Dessiner le fond
    UI.DrawTiledBackground()
    
    local screenWidth = love.graphics.getWidth()
    local currentMenu = UI.menus[UI.menuState]
    
    -- Logo avec titre du menu actuel
    UI.DrawLogoWithAdaptedText(screenWidth / 2, 60, currentMenu.title)
    
    -- Menu avec boutons
    UI.DrawButtonMenu(currentMenu.options, 180)  -- Y = 180 pour position des boutons
end

-- texte adapté par rapport au logo
function UI.DrawLogoWithAdaptedText(centerX, y, text)
    if not UI.assets then return end
    
    -- Taille du logo à l'échelle désirée
    local logoScale = 1.5  -- 120% de la taille originale
    
    -- Calculer les dimensions du logo
    local logo1Width = UI.assets.logo1:getWidth() * logoScale
    local logo2Width = UI.assets.logo2:getWidth() * logoScale
    local logo3Width = UI.assets.logo3:getWidth() * logoScale
    local totalLogoWidth = logo1Width + logo2Width + logo3Width
    local logoHeight = UI.assets.logo1:getHeight() * logoScale
    
    -- Position du logo centré
    local logoX = centerX - totalLogoWidth / 2
    
    -- Dessiner le logo
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(UI.assets.logo1, logoX, y, 0, logoScale, logoScale)
    love.graphics.draw(UI.assets.logo2, logoX + logo1Width, y, 0, logoScale, logoScale)
    love.graphics.draw(UI.assets.logo3, logoX + logo1Width + logo2Width, y, 0, logoScale, logoScale)
    
    -- Calculer la position du texte pour qu'il soit centré SUR le logo
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()

    
    local textX = centerX - textWidth / 2  -- Centré horizontalement
    local textY = y + (logoHeight - textHeight) / 2  -- Centré verticalement sur le logo
    
    -- Dessiner le contour du texte pour la lisibilité
    love.graphics.setColor(0, 0, 0)  -- Noir
    local outlineSize = 2
    for dx = -outlineSize, outlineSize do
        for dy = -outlineSize, outlineSize do
            if dx ~= 0 or dy ~= 0 then
                love.graphics.print(text, textX + dx, textY + dy)
            end
        end
    end
    
    -- Dessiner le texte principal
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, textX, textY)
end

-- Répéter le fond en mosaïque
function UI.DrawTiledBackground()
    if not UI.assets or not UI.assets.background then return end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    local bgWidth = UI.assets.background:getWidth()
    local bgHeight = UI.assets.background:getHeight()
    
    love.graphics.setColor(1, 1, 1)
    
    -- Répéter l'image sur toute la surface
    for x = 0, screenWidth, bgWidth do
        for y = 0, screenHeight, bgHeight do
            love.graphics.draw(UI.assets.background, x, y)
        end
    end
end

function UI.DrawLogoWithCustomFont(centerX, y, text)
    -- Utiliser votre fonction existante mais avec la police titre
    local originalFont = love.graphics.getFont()
    local titleFont = UI.fonts and UI.fonts.title or UI.defaultFont
    
    love.graphics.setFont(titleFont)
    
    -- Appeler votre fonction existante
    UI.DrawLogoWithAdaptedText(centerX, y, text)
    
    -- Remettre la police originale
    love.graphics.setFont(originalFont)
end


function UI.DrawMenuWithButtons()
    if not UI.assets then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("ERREUR: Assets non chargés!", 10, 10)
        return
    end

    -- Dessiner le fond
    UI.DrawFullscreenBackground()
    
    local screenWidth = love.graphics.getWidth()
    local currentMenu = UI.menus[UI.menuState]
    
    -- Logo avec titre
    UI.DrawLogoWithCustomFont(screenWidth / 2, 60, currentMenu.title)
    
    -- Menu avec boutons
    UI.DrawButtonMenu(currentMenu.options, 200)  -- Y = 200 pour position des boutons
end

function UI.DrawButtonMenu(options, startY)
    local screenWidth = love.graphics.getWidth()
    local buttonSpacing = 60  -- Espacement entre les boutons
    
    for i, option in ipairs(options) do
        local y = startY + (i-1) * buttonSpacing
        local isSelected = (i == UI.selectedOption)
        
        UI.DrawMenuButton(option.text, screenWidth / 2, y, isSelected)
    end
    
    -- Instructions
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HAUT/BAS  Naviguer    ENTRÉE Sélectionner", 20, love.graphics.getHeight() - 30)
end

function UI.DrawMenuButton(text, centerX, y, isSelected)
    if not UI.assets then return end
    
    -- Utiliser la police bouton
    local originalFont = love.graphics.getFont()
    local buttonFont = UI.fonts and UI.fonts.button or UI.defaultFont
    love.graphics.setFont(buttonFont)
    
    -- Calculer la taille du texte
    local textWidth = buttonFont:getWidth(text)
    local textHeight = buttonFont:getHeight()
    
    -- Choisir l'image du bouton de base
    local buttonImage = isSelected and UI.assets.buttonSelected or UI.assets.buttonNormal
    local buttonHeight = buttonImage:getHeight() + 10
    
    --  NOUVEAU : Calculer la largeur adaptée du bouton
    local padding = 40  -- Espacement intérieur (20px de chaque côté)
    local minButtonWidth = 120  -- Largeur minimale du bouton
    local adaptedButtonWidth = math.max(minButtonWidth, textWidth + padding)
    
    -- Position du bouton centré
    local buttonX = centerX - adaptedButtonWidth / 2
    
    -- DESSINER LE BOUTON ADAPTATIF
    UI.DrawNineSliceButton(buttonImage, buttonX, y, adaptedButtonWidth, buttonHeight)
    
    -- Position du texte (toujours centré)
    local textX = centerX - textWidth / 2
    local textY = y + (buttonHeight - textHeight) / 2
    
    -- Dessiner le texte   
    love.graphics.setColor(0.2, 0.2, 0.2)  -- Gris foncé pour normal

    
    love.graphics.print(text, textX, textY)
    
    -- Flèche pour l'option sélectionnée
    if isSelected and UI.assets.arrow then
        --local arrowX = buttonX - UI.assets.arrow:getWidth() - 10
        local arrowX = buttonX + adaptedButtonWidth
        --local arrowY = y + buttonHeight / 2 - UI.assets.arrow:getHeight() / 2
        local arrowY = y + buttonHeight - UI.assets.arrow:getHeight() / 2
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(UI.assets.arrow, arrowX, arrowY, -math.pi/2)
    end
    
    -- Remettre la police originale
    love.graphics.setFont(originalFont)
end

-- FONCTION POUR DESSINER UN BOUTON ÉTIRÉ
function UI.DrawAdaptiveButton(buttonImage, x, y, targetWidth, targetHeight)
    local originalWidth = buttonImage:getWidth()
    local originalHeight = buttonImage:getHeight()
    
    -- Méthode 1 : Étirement simple (peut déformer les bordures)
    local scaleX = targetWidth / originalWidth
    local scaleY = targetHeight / originalHeight
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(buttonImage, x, y, 0, scaleX, scaleY)
end

-- Bouton 9-slice (bordures préservées)
function UI.DrawNineSliceButton(buttonImage, x, y, targetWidth, targetHeight)
    local originalWidth = buttonImage:getWidth()
    local originalHeight = buttonImage:getHeight()
    
    -- Taille des bordures (ajustez selon votre image)
    local borderSize = 5
    
    -- Si le bouton cible est plus petit que les bordures, utiliser l'étirement simple
    if targetWidth < borderSize * 2 or targetHeight < borderSize * 2 then
        UI.DrawAdaptiveButton(buttonImage, x, y, targetWidth, targetHeight)
        return
    end
    
    love.graphics.setColor(1, 1, 1)
    
    -- Coins (ne s'étirent pas)
    -- Coin haut-gauche
    local topLeft = love.graphics.newQuad(0, 0, borderSize, borderSize, originalWidth, originalHeight)
    love.graphics.draw(buttonImage, topLeft, x, y)
    
    -- Coin haut-droite  
    local topRight = love.graphics.newQuad(originalWidth - borderSize, 0, borderSize, borderSize, originalWidth, originalHeight)
    love.graphics.draw(buttonImage, topRight, x + targetWidth - borderSize, y)
    
    -- Coin bas-gauche
    local bottomLeft = love.graphics.newQuad(0, originalHeight - borderSize, borderSize, borderSize, originalWidth, originalHeight)
    love.graphics.draw(buttonImage, bottomLeft, x, y + targetHeight - borderSize)
    
    -- Coin bas-droite
    local bottomRight = love.graphics.newQuad(originalWidth - borderSize, originalHeight - borderSize, borderSize, borderSize, originalWidth, originalHeight)
    love.graphics.draw(buttonImage, bottomRight, x + targetWidth - borderSize, y + targetHeight - borderSize)
    
    -- Bordures (s'étirent dans une direction)
    -- Bordure haute
    local topBorder = love.graphics.newQuad(borderSize, 0, originalWidth - borderSize * 2, borderSize, originalWidth, originalHeight)
    local horizontalScale = (targetWidth - borderSize * 2) / (originalWidth - borderSize * 2)
    love.graphics.draw(buttonImage, topBorder, x + borderSize, y, 0, horizontalScale, 1)
    
    -- Bordure basse
    local bottomBorder = love.graphics.newQuad(borderSize, originalHeight - borderSize, originalWidth - borderSize * 2, borderSize, originalWidth, originalHeight)
    love.graphics.draw(buttonImage, bottomBorder, x + borderSize, y + targetHeight - borderSize, 0, horizontalScale, 1)
    
    -- Bordure gauche
    local leftBorder = love.graphics.newQuad(0, borderSize, borderSize, originalHeight - borderSize * 2, originalWidth, originalHeight)
    local verticalScale = (targetHeight - borderSize * 2) / (originalHeight - borderSize * 2)
    love.graphics.draw(buttonImage, leftBorder, x, y + borderSize, 0, 1, verticalScale)
    
    -- Bordure droite
    local rightBorder = love.graphics.newQuad(originalWidth - borderSize, borderSize, borderSize, originalHeight - borderSize * 2, originalWidth, originalHeight)
    love.graphics.draw(buttonImage, rightBorder, x + targetWidth - borderSize, y + borderSize, 0, 1, verticalScale)
    
    -- Centre (s'étire dans les deux directions)
    local center = love.graphics.newQuad(borderSize, borderSize, originalWidth - borderSize * 2, originalHeight - borderSize * 2, originalWidth, originalHeight)
    love.graphics.draw(buttonImage, center, x + borderSize, y + borderSize, 0, horizontalScale, verticalScale)
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
        print("Lancement Survival")
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
        print("Lancement Timed:", minutes, "minutes")
        Game.SetTimedMode(minutes)
        Game.StartGameplay()
        
    elseif action == "score" then
        local target = selectedOption.value
        print("Lancement Score:", target, "points")
        Game.SetScoreMode(target)
        Game.StartGameplay()
        
    elseif action == "back" then
        UI.menuState = "MAIN"
        UI.selectedOption = 1
    end
end

-- INTERFACES POUR GAME.LUA
function UI.DrawMenuInterface()
    UI.DrawMenuWithButtons()
end

function UI.KeyPressedMenuInterface(key)
    UI.KeyPressedMenu(key)
end

return UI