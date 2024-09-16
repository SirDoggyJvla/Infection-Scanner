--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Handle the distribution of the infection scanner.

]]--
--[[ ================================================ ]]--

require 'Items/SuburbsDistributions'
require 'Items/ProceduralDistributions'

local distribution = {
    ["ArmyHangarOutfit"] = {
        {item = "TLOU.InfectionScanner", chance = 0.5},
    },
    ["ArmyStorageElectronics"] = {
        {item = "TLOU.InfectionScanner", chance = 2},
        {item = "TLOU.InfectionScanner", chance = 2},
    },
    ["ArmyStorageOutfit"] = {
        {item = "TLOU.InfectionScanner", chance = 1},
    },
    ["ControlRoomCounter"] = {
        {item = "TLOU.InfectionScanner", chance = 1},
        {item = "TLOU.InfectionScanner", chance = 1},
    },
    ["LockerArmyBedroom"] = {
        {item = "TLOU.InfectionScanner", chance = 4},
    },
}

local item
for k,v in pairs(distribution) do
    for i = 1,#v do
        item = v[i]
        table.insert(ProceduralDistributions.list[k].items, item.item)
        table.insert(ProceduralDistributions.list[k].items, item.chance)
    end
end