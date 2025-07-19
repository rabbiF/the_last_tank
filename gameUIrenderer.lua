local Renderer = {}

-- pour afficher les contrôles dans le menu
function Renderer.DrawControlsInMenu()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Position en bas à droite ou gauche du menu
    local startX = 20  -- Ou screenWidth - 200 pour la droite
    local startY = screenHeight - 150
    
    -- Titre
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("COMMANDES:", startX, startY)
    
    -- Commandes essentielles
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("ZSQD Déplacement", startX, startY + 20)
    love.graphics.print("ESPACE Tirer", startX, startY + 40)
    love.graphics.print("A/E Rotation", startX, startY + 60)
    love.graphics.print("RETOUR ARRIERE Pause", startX, startY + 80)
    love.graphics.print("ECHAP Quitter", startX, startY + 100)
end

-- texte adapté par rapport au logo
function Renderer.DrawLogoWithAdaptedText(centerX, y, text, assets)
    if not assets then return end
    
    -- Taille du logo à l'échelle désirée
    local logoScale = 1.5  -- 120% de la taille originale
    
    -- Calculer les dimensions du logo
    local logo1Width = assets.logo1:getWidth() * logoScale
    local logo2Width = assets.logo2:getWidth() * logoScale
    local logo3Width = assets.logo3:getWidth() * logoScale
    local totalLogoWidth = logo1Width + logo2Width + logo3Width
    local logoHeight = assets.logo1:getHeight() * logoScale
    
    -- Position du logo centré
    local logoX = centerX - totalLogoWidth / 2
    
    -- Dessiner le logo
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(assets.logo1, logoX, y, 0, logoScale, logoScale)
    love.graphics.draw(assets.logo2, logoX + logo1Width, y, 0, logoScale, logoScale)
    love.graphics.draw(assets.logo3, logoX + logo1Width + logo2Width, y, 0, logoScale, logoScale)
    
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
function Renderer.DrawTiledBackground()
    local UI = require("gameUI")
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

-- texte adapté par rapport à une font
function Renderer.DrawLogoWithCustomFont(centerX, y, text, assets, fonts, defaultFont)
    -- Utiliser votre fonction existante mais avec la police titre
    local originalFont = love.graphics.getFont()
    local titleFont = fonts and fonts.title or defaultFont
    
    love.graphics.setFont(titleFont)
    
    -- Appeler votre fonction existante
    Renderer.DrawLogoWithAdaptedText(centerX, y, text, assets)
    
    -- Remettre la police originale
    love.graphics.setFont(originalFont)
end

-- FONCTION POUR DESSINER UN MENU AVEC DES BOUTONS
function Renderer.DrawMenuWithButtons(UI)
    if not UI.assets then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("ERREUR: Assets non chargés!", 10, 10)
        return
    end

    -- Dessiner le fond
    Renderer.DrawFullscreenBackground()
    
    local screenWidth = love.graphics.getWidth()
    local currentMenu = UI.menus[UI.menuState]
    
    -- Logo avec titre
    Renderer.DrawLogoWithCustomFont(screenWidth / 2, 60, currentMenu.title, UI.assets, UI.fonts, UI.defaultFont)
    
    -- Menu avec boutons
    Renderer.DrawButtonMenu(currentMenu.options, 200, UI)  -- Y = 200 pour position des boutons
end

-- FONCTION POUR DESSINER UN MENU
function Renderer.DrawButtonMenu(options, startY, UI)
    local screenWidth = love.graphics.getWidth()
    local buttonSpacing = 60  -- Espacement entre les boutons
    
    for i, option in ipairs(options) do
        local y = startY + (i-1) * buttonSpacing
        local isSelected = (i == UI.selectedOption)
        
        Renderer.DrawMenuButton(option.text, screenWidth / 2, y, isSelected, UI)
    end
    
    -- Instructions
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HAUT/BAS  Naviguer    ENTRÉE Sélectionner", 20, love.graphics.getHeight() - 30)
end

-- FONCTION POUR DESSINER CHAQUE BOUTON DU MENU
function Renderer.DrawMenuButton(text, centerX, y, isSelected, UI)
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
    Renderer.DrawNineSliceButton(buttonImage, buttonX, y, adaptedButtonWidth, buttonHeight)
    
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
function Renderer.DrawAdaptiveButton(buttonImage, x, y, targetWidth, targetHeight)
    local originalWidth = buttonImage:getWidth()
    local originalHeight = buttonImage:getHeight()
    
    -- Méthode 1 : Étirement simple (peut déformer les bordures)
    local scaleX = targetWidth / originalWidth
    local scaleY = targetHeight / originalHeight
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(buttonImage, x, y, 0, scaleX, scaleY)
end

-- Bouton 9-slice (bordures préservées)
function Renderer.DrawNineSliceButton(buttonImage, x, y, targetWidth, targetHeight)
    local originalWidth = buttonImage:getWidth()
    local originalHeight = buttonImage:getHeight()
    
    -- Taille des bordures (ajustez selon votre image)
    local borderSize = 5
    
    -- Si le bouton cible est plus petit que les bordures, utiliser l'étirement simple
    if targetWidth < borderSize * 2 or targetHeight < borderSize * 2 then
        Renderer.DrawAdaptiveButton(buttonImage, x, y, targetWidth, targetHeight)
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

return Renderer