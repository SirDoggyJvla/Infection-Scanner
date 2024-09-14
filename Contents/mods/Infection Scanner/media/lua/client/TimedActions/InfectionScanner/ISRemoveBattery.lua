--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Defines the timed action of replacing the battery of the InfectionScanner.

]]--
--[[ ================================================ ]]--

require "TimedActions/ISBaseTimedAction"

InfectionScanner_ISRemoveBattery = ISBaseTimedAction:derive("InfectionScanner_ISRemoveBattery")

function InfectionScanner_ISRemoveBattery:isValid()
	return true
end

function InfectionScanner_ISRemoveBattery:waitToStart()
	return false
end

function InfectionScanner_ISRemoveBattery:update()

end

function InfectionScanner_ISRemoveBattery:start()
	self:setActionAnim("Craft")
end

function InfectionScanner_ISRemoveBattery:stop()
	ISBaseTimedAction.stop(self);
end

function InfectionScanner_ISRemoveBattery:perform()
    local scanner = self.scanner
    local charge = scanner:getUsedDelta()

	-- create a battery
	local battery = InventoryItemFactory.CreateItem("Base.Battery")
	battery:setUsedDelta(charge)

	self.character:getInventory():AddItem(battery)

    -- set the charge of the scanner
    scanner:setUsedDelta(0);

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function InfectionScanner_ISRemoveBattery:new (character,scanner,inventory,time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = false
	o.stopOnRun = true
	o.maxTime = time

	-- custom fields
    o.inventory = inventory
	o.scanner = scanner
	return o
end
