--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Every context menu actions for the scanner.

]]--
--[[ ================================================ ]]--

-- requirements
local InfectionScanner = require "InfectionScanner_module"
require "TimedActions/InfectionScanner/ISInsertBattery"
require "TimedActions/InfectionScanner/ISRemoveBattery"

-- -- localy initialize player
-- local client_player = getPlayer()
-- local function initTLOU_OnGameStart(playerIndex, player_init)
-- 	client_player = getPlayer()
-- end
-- Events.OnCreatePlayer.Remove(initTLOU_OnGameStart)
-- Events.OnCreatePlayer.Add(initTLOU_OnGameStart)



--- CHANGE MODE ---

--#region Change mode

InfectionScanner.Change2Scanning = function(player,scanner)
    player:getEmitter():playSound('InfectionScanner_modeSwitch')
    addSound(nil, player:getX(), player:getY(), player:getZ(), 7, 7)
    scanner:getModData().InfectionScanner_mode = "Scanning"
end

InfectionScanner.Change2SporeDetector = function(player,scanner)
    player:getEmitter():playSound('InfectionScanner_modeSwitch')
    addSound(nil, player:getX(), player:getY(), player:getZ(), 7, 7)
    scanner:getModData().InfectionScanner_mode = "SporeDetector"
end

--#endregion



--- HANDLE BATTERY ---

--#region Change/Remove battery

---Change the battery from the scanner.
---@param player IsoPlayer
---@param scanner InventoryItem
---@param battery Drainable
---@param inventory ItemContainer
InfectionScanner.ChangeBattery = function(player,scanner,battery,inventory)
	-- transfer scanner and battery in main inventory if not in it
	ISInventoryPaneContextMenu.transferIfNeeded(player, battery)
	ISInventoryPaneContextMenu.transferIfNeeded(player, scanner)

	-- add an action to change battery
	ISTimedActionQueue.add(InfectionScanner_ISInsertBattery:new(player,scanner,battery,inventory,20))
end

---Remove the battery from the scanner.
---@param player IsoPlayer
---@param scanner InventoryItem
---@param inventory ItemContainer
InfectionScanner.RemoveBattery = function(player,scanner,inventory)
	-- transfer scanner in main inventory if not in it
	ISInventoryPaneContextMenu.transferIfNeeded(player, scanner)

	-- add an action to remove battery
	ISTimedActionQueue.add(InfectionScanner_ISRemoveBattery:new(player,scanner,inventory,20))
end

--#endregion



--- CHECK FOR INFECTION ---

--#region Check for infection

---Check if a player is infected with the infection scanner.
---@param checker IsoPlayer
---@param scanned IsoMovingObject
InfectionScanner.CheckForInfection = function(checker,scanned)
	checker:addLineChatElement("scanning...")

	-- note the scanned for checking later
	InfectionScanner.Scanned[scanned] = {time = os.time(),result = ""}

	-- in MP, ask for answer
	if instanceof(scanned,"IsoPlayer") then
	---@cast scanned IsoPlayer

		-- if SP or checker is scanned then directly note the result
		if not isClient() or checker == scanned then
			local isInfected = scanned:getBodyDamage():IsInfected()
			InfectionScanner.Scanned[scanned].result = isInfected and "Infected" or "notInfected"

		-- if MP, the result needs to be received from the scanned
		else
			sendClientCommand('InfectionScanner','AskIfInfected',{scannedID = scanned:getOnlineID(),checkerID = checker:getOnlineID()})
			InfectionScanner.Scanned[scanned].result = "Waiting"
		end
	end

	scanned:addLineChatElement("target of scan")

	-- play sound of the scanner (automatically synced)
	checker:getEmitter():playSound('InfectionScanner_run')
	addSound(nil, checker:getX(), checker:getY(), checker:getZ(), 7, 7)
end

--#endregion