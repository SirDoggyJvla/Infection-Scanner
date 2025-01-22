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

InfectionScanner_ISInsertBattery = ISBaseTimedAction:derive("InfectionScanner_ISInsertBattery")

function InfectionScanner_ISInsertBattery:isValid()
	return true
end

function InfectionScanner_ISInsertBattery:waitToStart()
	return false
end

function InfectionScanner_ISInsertBattery:update()

end

function InfectionScanner_ISInsertBattery:start()
	self:setActionAnim("Craft")
end

function InfectionScanner_ISInsertBattery:stop()
	ISBaseTimedAction.stop(self);
end

function InfectionScanner_ISInsertBattery:perform()
    local scanner = self.scanner
    local battery = self.battery

    -- set the charge of the scanner
    scanner:setCurrentUsesFloat(battery:getCurrentUsesFloat())

	-- remove the battery from inventory
	local inventory = self.inventory
	inventory:Remove(battery)
	inventory:removeItemOnServer(battery)

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function InfectionScanner_ISInsertBattery:new (character,scanner,battery,inventory,time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = false
	o.stopOnRun = true
	o.maxTime = time

	-- custom fields
    o.inventory = inventory -- player inventory
	o.scanner = scanner
	o.battery = battery
	return o
end
