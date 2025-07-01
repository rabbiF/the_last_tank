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


function Game.Load()
    
    Game.TileSheet = love.graphics.newImage("images/terrain.png")
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

end


function Game.Update(dt)

end


function Game.Draw()
    local c, l

    for l=1, Game.Map.MAP_HEIGHT do
        for c=1, Game.Map.MAP_WIDTH do
            if Game.Map.Grid[l]~= nil and Game.Map.Grid[l][c] ~= nil then
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

return Game