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