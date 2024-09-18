--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Events of InfectionScanner.

]]--
--[[ ================================================ ]]--

-- requirements
local InfectionScanner = require "InfectionScanner_module"
require "InfectionScanner_main"

-- check context menu
Events.OnFillInventoryObjectContextMenu.Add(InfectionScanner.OnFillInventoryObjectContextMenu)
Events.OnFillWorldObjectContextMenu.Add(InfectionScanner.OnFillWorldObjectContextMenu)

-- scan
Events.OnTick.Add(InfectionScanner.OnTick)

-- play scanner sound when equiping
Events.OnEquipPrimary.Add(InfectionScanner.OnEquipPrimary)

-- -- Code by Rodriguo

-- local enabled = true
-- InfectionScanner.highlightsSquares = {}

-- function InfectionScanner.AddHighlightSquare(square, ISColors)
--     if not square or not ISColors then return end
--     table.insert(InfectionScanner.highlightsSquares, {square = square, color = ISColors})
-- end

-- function InfectionScanner.RenderHighLights()
--     if not enabled then return end

--     if #InfectionScanner.highlightsSquares == 0 then return end
--     for _, highlight in ipairs(InfectionScanner.highlightsSquares) do
--         if highlight.square ~= nil and instanceof(highlight.square, "IsoGridSquare") then
--             local x,y,z = highlight.square:getX(), highlight.square:getY(), highlight.square:getZ()
--             local r,g,b,a = highlight.color.r, highlight.color.g, highlight.color.b, 0.8

--             local floorSprite = IsoSprite.new()
--             floorSprite:LoadFramesNoDirPageSimple('media/ui/FloorTileCursor.png')
--             floorSprite:RenderGhostTileColor(x, y, z, r, g, b, a)
--         else
--             print("Invalid square")
--         end
--     end
-- end

-- -- debug tool
-- Events.OnPostRender.Add(InfectionScanner.RenderHighLights)