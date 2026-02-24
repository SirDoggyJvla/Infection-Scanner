---REQUIREMENTS
local rdm = newrandom()
local Enums = require "InfectionScanner/enums"


InfectionScannerRecipes = {}



--- tostring so the game stops screaming at me about giving an ItemKey instead of a string
local ELECTRONIC_SCRAP = tostring(ItemKey.Normal.ELECTRONICS_SCRAP)
local ELECTRIC_WIRE = tostring(ItemKey.Normal.ELECTRIC_WIRE)
local ALUMINUM = tostring(ItemKey.Normal.ALUMINUM)
local SCANNER_MODULE = tostring(ItemKey.Normal.SCANNER_MODULE)
local LIGHT_BULB = tostring(ItemKey.Normal.LIGHT_BULB)
local AMPLIFIER = tostring(ItemKey.Normal.AMPLIFIER)
local BATTERY = tostring(ItemKey.Drainable.BATTERY)



---@param data CraftRecipeData
---@param character IsoPlayer
InfectionScannerRecipes.DismantleInfectionScanner = function(data, character)
    local success = 50 + (character:getPerkLevel(Perks.Electricity)*5)
    local inv = character:getInventory()

    if rdm:random(0, 100) < success then
        inv:AddItem(AMPLIFIER)
    end
    if rdm:random(0, 100) < success then
        inv:AddItem(LIGHT_BULB)
    end
    if rdm:random(0, 100) < success then
        inv:AddItem(SCANNER_MODULE)
    end

    --- radio base items
    local amount = rdm:random(1, 3)
    for i=1, amount do
        local r = rdm:random(1, 3)
        if r == 1 then
            inv:AddItem(ELECTRONIC_SCRAP)
        elseif r == 2 then
            inv:AddItem(ELECTRIC_WIRE)
        elseif r == 3 then
            inv:AddItem(ALUMINUM)
        end
    end

    -- remove battery
    local items = data:getAllConsumedItems()
    for i=0, items:size() - 1 do
        local item = items:get(i)
        if item:getFullType() == Enums.SCANNER_ITEM then
            local charge = item:getCurrentUsesFloat()
            if charge ~= 0 then
                local battery = instanceItem(BATTERY)
                battery:setCurrentUsesFloat(charge)
                inv:AddItem(battery)
            end
        end
    end
end

return InfectionScannerRecipes