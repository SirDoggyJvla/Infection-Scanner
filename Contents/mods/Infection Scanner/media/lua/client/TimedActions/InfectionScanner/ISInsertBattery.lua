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
    local charge = battery:getUsedDelta()

    -- if scanner has a non-empty battery then
    if scanner:getUsedDelta() ~= 0 then
        battery:setUsedDelta(scanner:getUsedDelta())
    else
        local container = self.inventory
        container:Remove(battery)
        container:removeItemOnServer(battery)
    end

    -- set the charge of the scanner
    scanner:setUsedDelta(charge);

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
    o.inventory = inventory
	o.scanner = scanner
	o.battery = battery
	return o
end
