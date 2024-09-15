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

Events.OnFillInventoryObjectContextMenu.Add(InfectionScanner.OnFillInventoryObjectContextMenu)

Events.OnTick.Add(InfectionScanner.OnTick)