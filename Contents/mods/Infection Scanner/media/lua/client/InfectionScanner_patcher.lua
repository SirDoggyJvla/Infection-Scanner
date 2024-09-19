--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Patches for compatibility or new features linked to other mods or vanilla features.

]]--
--[[ ================================================ ]]--

-- requirements
local InfectionScanner = require "InfectionScanner_module"

-- localy initialize player
local client_player = getPlayer()
local function initTLOU_OnGameStart(playerIndex, player_init)
	client_player = getPlayer()
end
Events.OnCreatePlayer.Remove(initTLOU_OnGameStart)
Events.OnCreatePlayer.Add(initTLOU_OnGameStart)

if not InfectionScanner.patched_onActivateItem then
    local vanilla_onActivateItem = ISInventoryPaneContextMenu.onActivateItem
    InfectionScanner.patched_onActivateItem = true

    ISInventoryPaneContextMenu.onActivateItem = function(light, playerIndex)
        if light:getFullType() == "TLOU.InfectionScanner" and not light:isActivated() then
            local player = getSpecificPlayer(playerIndex)
            player:getEmitter():playSound('InfectionScanner_start')
            addSound(nil, player:getX(), player:getY(), player:getZ(), 7, 7)
        end

        vanilla_onActivateItem(light,playerIndex)
    end
end

if getActivatedMods():contains("BB_SporeZones") then

    local updateZoneChance = function()
        local climateManager = getClimateManager()

        local currZoneChance = 0
        if not SandboxVars.SporeZones.StartDay then

            if SandboxVars.SporeZones.ZoneChance then
                currZoneChance = SandboxVars.SporeZones.ZoneChance
            else
                currZoneChance = 5
            end

            return
        end

        local dayInfo = climateManager:getCurrentDay()
        local startDate = os.time{day = SandboxVars.StartDay, year = 1992 + SandboxVars.StartYear, month = SandboxVars.StartMonth}
        local currDate = os.time{day = dayInfo:getDay(), year = dayInfo:getYear(), month = dayInfo:getMonth() + 1}

        local daysfrom = os.difftime(startDate, currDate) / (24 * 60 * 60)
        local currDay = math.floor(daysfrom)
        if currDay < 0 then currDay = -currDay end

        if currDay >= SandboxVars.SporeZones.StartDay then
            if SandboxVars.SporeZones.DailyIncrement == 0 then
                currZoneChance = SandboxVars.SporeZones.ZoneChance
            elseif currZoneChance < SandboxVars.SporeZones.ZoneChance then
                currZoneChance = (currDay - (SandboxVars.SporeZones.StartDay - 1)) * SandboxVars.SporeZones.DailyIncrement
                if currZoneChance > SandboxVars.SporeZones.ZoneChance then currZoneChance = SandboxVars.SporeZones.ZoneChance end
            end
        end

        InfectionScanner.SporeZoneChance = currZoneChance
    end

    local everyHour = function()
        local climateManager = getClimateManager()
        if climateManager:getCurrentDay():getHour() + 1 == getGameTime():getStartTimeOfDay() then
            updateZoneChance()
        end
    end

    Events.OnGameStart.Add(updateZoneChance)
    Events.EveryHours.Add(everyHour)

    -- Hijacked the create spore zone function by Braven simply to not draw or start infecting the player if creating the spore zone from outside.
    local function CreateSporeZone(building, buildingDef, playerObj, buildingSq, zoneSq)
        local args = {
            origin = { x = buildingSq:getX(), y = buildingSq:getY(), z = buildingSq:getZ() },
            groundZero = { x = zoneSq:getX(), y = zoneSq:getY(), z = zoneSq:getZ() }
        }
        sendClientCommand(playerObj, 'SporeZone', 'TransmitSporeZone', args)

        if SandboxVars.SporeZones.GroundZero then
            local args2 = { x = zoneSq:getX(), y = zoneSq:getY(), z = zoneSq:getZ() }
            sendClientCommand(playerObj, 'SporeZone', 'CreateSporeZoneTile', args2)
        end

        if SandboxVars.SporeZones.SpawnCorpses == true then
            local bodyAmount = math.floor((buildingDef:getH() * buildingDef:getW()) / 50)
            if bodyAmount < 1 then bodyAmount = 1 end

            for _ = 0, bodyAmount - 1 do
                local randomSq = BuildingHelper.getFreeTileFromBuilding(building:getDef())
                if randomSq then
                    local infectedBody = createRandomDeadBody(randomSq, 1)
                    local bodyInv = infectedBody:getContainer()
                    infectedBody:transmitCompleteItemToServer()

                    if bodyInv then
                        bodyInv:AddItem("Base.Cordyceps")
                        Utils_SporeZones.SpawnLootTable(bodyInv)
                    end

                    sendItemsInContainer(infectedBody, bodyInv)
                end
            end
        end
    end

    InfectionScanner.isSquareSporeZone = function(entry)
        local building = entry:getBuilding()
        if not building then return false end

        -- retrieve building informations
        local buildingDef = building:getDef()
        local zCoord = (buildingDef:getFirstRoom() and buildingDef:getFirstRoom():getZ()) or 0
        local buildingSq = client_player:getCell():getGridSquare(buildingDef:getX(), buildingDef:getY(), zCoord)
        local zoneSq = buildingDef:getFreeSquareInRoom()

        -- verify building is valid
        if buildingSq and zoneSq then
            local buildingSq_modData = buildingSq:getModData()

            -- initialize building if not already
            if not (buildingSq_modData.isSporeZone or buildingSq_modData.visitedBefore) then
                if buildingSq then
                    buildingSq_modData.visitedBefore = true
                    if ZombRand(0,100) < InfectionScanner.SporeZoneChance then
                        CreateSporeZone(building, buildingDef, client_player, buildingSq, zoneSq)
                    else
                        local args = { origin = { x = buildingSq:getX(), y = buildingSq:getY(), z = buildingSq:getZ() } }
                        sendClientCommand(client_player, 'SporeZone', 'TransmitVisited', args)
                    end
                end

            -- tick for spore zone sound
            elseif buildingSq_modData.isSporeZone then
                return true

            end
        end

        return false
    end

end