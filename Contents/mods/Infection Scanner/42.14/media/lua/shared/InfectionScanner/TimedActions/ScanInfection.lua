---REQUIREMENTS
require("TimedActions/ISBaseTimedAction")

local IS_SERVER = isServer()


---@namespace InfectionScanner


---@class ScanInfection : ISBaseTimedAction
---@field target IsoPlayer
local ScanInfection = ISBaseTimedAction:derive("InfectionScanner_ScanInfection")

function ScanInfection:waitToStart()
    local target = self.target
    if target == self.character then
        return true
    end

    self.character:faceThisObject(target)
    return self.character:shouldBeTurning()
end


---@return boolean
function ScanInfection:isValid()
    return true
end


function ScanInfection:update()

end

function ScanInfection:start()
    -- self:setActionAnim(actionAnim)
end



function ScanInfection:serverStart()
    return true
end


function ScanInfection:stop()
    ISBaseTimedAction.stop(self)
end


function ScanInfection:complete()
    return true
end


function ScanInfection:perform()
    ISBaseTimedAction.perform(self)
end


function ScanInfection:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end

    return -1
end


---@param character IsoPlayer
---@param target IsoPlayer
---@return self
---@nodiscard
function ScanInfection:new(character, target)
    ---@type ScanInfection
    local o = ISBaseTimedAction.new(self, character)

    o.character = character
    o.target = target
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = true

    o.maxTime = o:getDuration()
    -- o.useProgressBar = false

    return o
end


_G[ScanInfection.Type] = ScanInfection


return ScanInfection