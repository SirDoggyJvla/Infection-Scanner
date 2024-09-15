--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Core of InfectionScanner to change the stats.

]]--
--[[ ================================================ ]]--

-- requirements
local InfectionScanner = require "InfectionScanner_module"
require "TimedActions/ISInsertBattery"
require "TimedActions/ISRemoveBattery"

-- localy initialize player
local client_player = getPlayer()
local function initTLOU_OnGameStart(playerIndex, player_init)
	client_player = getPlayer()
end
Events.OnCreatePlayer.Remove(initTLOU_OnGameStart)
Events.OnCreatePlayer.Add(initTLOU_OnGameStart)

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

---Test function to recursively find every batteries that are not dead in the inventory.
---@param item InventoryItem
---@return boolean
InfectionScanner.isBattery = function(item)
	return item:getType() == "Battery" and item:getUsedDelta() ~= 0
end

---Check if a player is infected with the infection scanner.
---@param player any
InfectionScanner.CheckForInfection = function(player)
	player:addLineChatElement("scanning...")
	player:getModData().InfectionScanner_check = os.time()
end



---When right clicking the scanner, show options to add or remove battery and scan yourself.
---@param playerIndex int
---@param context table
---@param items table
InfectionScanner.OnFillInventoryObjectContextMenu = function(playerIndex, context, items)
	-- retrieve player
	local player = getSpecificPlayer(playerIndex)

	-- check if item is scanner
	local item
	for i = 1,#items do
		-- retrieve the item
		item = items[i]
		if not instanceof(item, "InventoryItem") then
            item = item.items[1];
        end

		if item:getFullType() == "TLOU.InfectionScanner" then
			-- Do something
			print("Scanner detected")
			local option = context:addOption(getText("ContextMenu_InfectionScanner_ScanYourself"),player,InfectionScanner.CheckForInfection)

			-- check if scanner is charged
			local charged = item:getUsedDelta() ~= 0

			-- scanner has no battery
			if not charged then
				option.notAvailable = true
                local tooltip = ISWorldObjectContextMenu.addToolTip()
                tooltip.description = getText("Tooltip_InfectionScanner_noBattery")
                option.toolTip = tooltip

			-- scanner needs to be equiped
			elseif player:getPrimaryHandItem() ~= item then
				option.notAvailable = true
                local tooltip = ISWorldObjectContextMenu.addToolTip()
                tooltip.description = getText("Tooltip_InfectionScanner_needEquiping")
                option.toolTip = tooltip

			-- scanner needs to be ON
			elseif not item:isActivated() then
				option.notAvailable = true
                local tooltip = ISWorldObjectContextMenu.addToolTip()
                tooltip.description = getText("Tooltip_InfectionScanner_isOFF")
                option.toolTip = tooltip

			end

			-- retrieve batteries in the inventory
			local inventory = player:getInventory()
			local batteries = ArrayList.new()
			inventory:getAllEvalRecurse(InfectionScanner.isBattery, batteries)

			-- create the submenu to insert or swap a battery
			if not charged then
				option = context:addOption(getText("ContextMenu_InfectionScanner_InsertBattery"))
			else
				option = context:addOption(getText("ContextMenu_InfectionScanner_SwapBattery"))
			end
			local subMenu = context:getNew(context)
			context:addSubMenu(option, subMenu)

			local battery
			for j = 0,batteries:size() - 1 do
				battery = batteries:get(j)

				local repairPercent = math.floor(battery:getUsedDelta() * 100.0).."%"
				subMenu:addOption(battery:getDisplayName()..":  "..repairPercent, player, InfectionScanner.ChangeBattery, item, battery, inventory)
			end

			-- add option to remove the battery
			if charged then
				option = context:addOption(getText("ContextMenu_InfectionScanner_RemoveBattery"), player, InfectionScanner.RemoveBattery, item, inventory)
			end
		end
	end
end

InfectionScanner.OnTick = function(tick)
	local movingObjects = client_player:getCell():getObjectList()

	local movingObject
	for i = 0,movingObjects:size() - 1 do
		movingObject = movingObjects:get(i)
		if instanceof(movingObject,"IsoPlayer") then
			-- verify scanner check is done
			local scanner_check = movingObject:getModData().InfectionScanner_check
			if scanner_check and os.time() - scanner_check >= 0.1 then
				movingObject:getModData().InfectionScanner_check = nil

				-- give result of scan
				local isInfected = movingObject:getBodyDamage():IsInfected()
				if isInfected then

					movingObject:addLineChatElement("positive",1,0,0)
				else

					movingObject:addLineChatElement("negative",0,1,0)
				end
			end
		end
	end
end