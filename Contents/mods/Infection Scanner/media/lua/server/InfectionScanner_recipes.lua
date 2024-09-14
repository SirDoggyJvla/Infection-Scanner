--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Recipes of InfectionScanner.

]]--
--[[ ================================================ ]]--

-- Return true if recipe is valid, false otherwise
Recipe.OnTest.InfectionScannerBatteryInsert = function(sourceItem, result)
	if sourceItem:getFullType() == "TLOU.InfectionScanner" then
		return sourceItem:getUsedDelta() == 0; -- Only allow the battery inserting if the flashlight has no battery left in it.
	end
	return true -- the battery
end

-- Reduce battery value.
Recipe.OnCreate.InfectionScannerBatteryInsert = function(items, result, player)
    print(items)
    local item
    for i = 0,items:size() - 1 do
        item = items:get(i)
        print(item)

        -- we found the battery, we change his used delta according to the battery
        if item:getType() == "Battery" then
            result:setUsedDelta(item:getUsedDelta());
        end
        break
    end
end


-- Return true if recipe is valid, false otherwise
Recipe.OnTest.InfectionScannerBatteryRemoval = function(sourceItem, result)
	return sourceItem:getUsedDelta() > 0;
end

-- When creating item in result box of crafting panel.
Recipe.OnCreate.InfectionScannerBatteryRemoval = function(items, result, player)
    local item
	for i=0, items:size()-1 do
		item = items:get(i)

		-- we found the battery, we change his used delta according to the battery
		if item:getFullType() == "TLOU.InfectionScanner" then
			result:setUsedDelta(item:getUsedDelta());
			-- then we empty the infection scanner used delta (his energy)
			item:setUsedDelta(0);
		end
	end
end