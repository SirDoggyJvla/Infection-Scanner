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

-- compatible patches
local activatedMods_Bandits = getActivatedMods():contains("Bandits")

-- localy initialize player
local client_player = getPlayer()
local function initTLOU_OnGameStart(playerIndex, player_init)
	client_player = getPlayer()
end
Events.OnCreatePlayer.Remove(initTLOU_OnGameStart)
Events.OnCreatePlayer.Add(initTLOU_OnGameStart)

---Verify `movingObject` is in range of `player` to scan.
---@param p_x float
---@param p_y float
---@param p_z float
---@param movingObject IsoMovingObject
---@return boolean
InfectionScanner.CheckInRange = function(p_x,p_y,p_z,movingObject)
	-- verify height is the same
	local m_z = movingObject:getZ()
	local h = p_z - m_z
	h = h < 0 and -h or h
	if h < 0.25 then
		-- verify distance is the same
		local m_x = movingObject:getX()
		local m_y = movingObject:getY()

		local d = ( (m_x - p_x)^2 + (m_y - p_y)^2 )
		return d < 2
	end

	return false
end

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

---Add to `context` an option for the `checker` to scan the `scanned` with the predefined `text`.
---Various states can be given to make the option not available to click:
--- - `inRanged`
--- - `equiped`
--- - `charged`
--- - `activated`
---@param context table
---@param checker IsoPlayer
---@param scanned IsoMovingObject
---@param inRange boolean
---@param equiped boolean
---@param charged boolean
---@param activated boolean
---@param text string
InfectionScanner.AddScannerOptionToContext = function(context,checker,scanned,inRange,equiped,charged,activated,text)
	local option = context:addOption(getText(text),checker,InfectionScanner.CheckForInfection,scanned)

	-- scanner has no battery
	if not inRange then
		option.notAvailable = true
		local tooltip = ISWorldObjectContextMenu.addToolTip()
		tooltip.description = getText("Tooltip_InfectionScanner_notInRange")
		option.toolTip = tooltip

	-- scanner needs to be equiped
	elseif not equiped then
		option.notAvailable = true
		local tooltip = ISWorldObjectContextMenu.addToolTip()
		tooltip.description = getText("Tooltip_InfectionScanner_needEquiping")
		option.toolTip = tooltip

	-- scanner needs to be ON
	elseif not activated then
		option.notAvailable = true
		local tooltip = ISWorldObjectContextMenu.addToolTip()
		tooltip.description = getText("Tooltip_InfectionScanner_isOFF")
		option.toolTip = tooltip

	-- scanner needs to be charged
	elseif not charged then
		option.notAvailable = true
		local tooltip = ISWorldObjectContextMenu.addToolTip()
		tooltip.description = getText("Tooltip_InfectionScanner_noBattery")
		option.toolTip = tooltip



	end
end


---When right clicking the scanner, show options to add or remove battery and scan yourself.
---@param playerIndex int
---@param context table
---@param items table
InfectionScanner.OnFillInventoryObjectContextMenu = function(playerIndex, context, items)
	-- retrieve player
	local player = getSpecificPlayer(playerIndex)

	local equipedItem = player:getPrimaryHandItem()

	-- check if item is scanner
	local item
	for i = 1,#items do
		-- retrieve the item
		item = items[i]
		if not instanceof(item, "InventoryItem") then
            item = item.items[1];
        end

		if item:getFullType() == "TLOU.InfectionScanner" then
			-- check if scanner is charged
			local charged = item:getUsedDelta() ~= 0
			local equiped = equipedItem and equipedItem == item

			-- add option to scan yourself
			InfectionScanner.AddScannerOptionToContext(context,player,player,true,equiped,charged,item:isActivated(),"ContextMenu_InfectionScanner_ScanYourself")

			-- retrieve batteries in the inventory
			local inventory = player:getInventory()
			local batteries = ArrayList.new()
			inventory:getAllEvalRecurse(InfectionScanner.isBattery, batteries)

			-- create the submenu to insert or swap a battery
			local option
			if not charged then
				option = context:addOption(getText("ContextMenu_InfectionScanner_InsertBattery"))
			else
				option = context:addOption(getText("ContextMenu_InfectionScanner_SwapBattery"))
			end
			local subMenu = context:getNew(context)
			context:addSubMenu(option, subMenu)

			-- add every as an option to insert or swap battery
			local battery
			for j = 0,batteries:size() - 1 do
				battery = batteries:get(j)

				local repairPercent = math.floor(battery:getUsedDelta() * 100.0).."%"
				subMenu:addOption(battery:getDisplayName()..":  "..repairPercent, player, InfectionScanner.ChangeBattery, item, battery, inventory)
			end

			-- add option to remove the battery if present
			if charged then
				option = context:addOption(getText("ContextMenu_InfectionScanner_RemoveBattery"), player, InfectionScanner.RemoveBattery, item, inventory)
			end
		end
	end
end

InfectionScanner.OnFillWorldObjectContextMenu = function(playerIndex, context, worldObjects, test)
	-- get player
	local player = getSpecificPlayer(playerIndex)

	-- verify player has scanner in hand
	local scanner = player:getPrimaryHandItem()
	if not scanner or scanner:getFullType() ~= "TLOU.InfectionScanner" then return end

	-- check if scanner is charged
	local charged = scanner:getUsedDelta() ~= 0
	local activated = scanner:isActivated()

	-- get player coordinates
	local p_x = player:getX()
	local p_y = player:getY()
	local p_z = player:getZ()

    -- objects can be in duplicate in the `worldObjects` for some reasons
    local objects = {}
    for i = 1,#worldObjects + 1 do
        objects[worldObjects[i]] = true
    end

    -- iterate through every objects
	local alreadyChecked = {}
	local o_x,o_y,o_z,h,inRange,square,movingObjects,movingObject,option,valid
    for object,_ in pairs(objects) do
		-- verify player is on same height
		o_z = object:getZ()
		h = o_z - p_z
		h = h < 0 and -h or h

		-- verify object is in range
		if h < 1 then
			-- verify object is in range
			o_x = object:getX()
			o_y = object:getY()

			-- iterate through adjacent squares
			for i = -1,1,1 do
				for j = -1,1,1 do
					-- retrieve moving objects
					square = getSquare(o_x + i,o_y + j,o_z)
					movingObjects = square:getMovingObjects()
					for k = 0, movingObjects:size() - 1 do
						movingObject = movingObjects:get(k)

						-- verify object was not already checked (happens when 2 objects with the same movingObjects)
						if not alreadyChecked[movingObject] then
							alreadyChecked[movingObject] = true

							-- verify movingObject is the player calling the context menu
							if movingObject ~= player then

								-- verify player can see movingObject
								if player:CanSee(movingObject) then
									-- movingObject is a player
									if instanceof(movingObject,"IsoPlayer") then
										-- verify movingObject is in range
										inRange = InfectionScanner.CheckInRange(p_x,p_y,p_z,movingObject)
										InfectionScanner.AddScannerOptionToContext(context,player,movingObject,inRange,true,charged,activated,"ContextMenu_InfectionScanner_ScanHuman")

									-- movingObject is a zombie, verify if human from Bandits
									elseif activatedMods_Bandits and instanceof(movingObject,"IsoZombie") then
										local brain = BanditBrain.Get(movingObject)
										if movingObject:getVariableBoolean("Bandit") or brain then
											-- it's a human, check for infection too
											inRange = InfectionScanner.CheckInRange(p_x,p_y,p_z,movingObject)
											InfectionScanner.AddScannerOptionToContext(context,player,movingObject,inRange,true,charged,activated,"ContextMenu_InfectionScanner_ScanHuman")
										end
									end
								end
							else
								InfectionScanner.AddScannerOptionToContext(context,player,movingObject,true,true,charged,activated,"ContextMenu_InfectionScanner_ScanYourself")

							end
						end
					end
				end
			end
		end
	end
end

InfectionScanner.OnTick = function(tick)
	local time, result
	for scanned,tbl in pairs(InfectionScanner.Scanned) do
		time = os.time() - tbl.time
		result = tbl.result

		-- waited too long
		if time >= 5 then
			client_player:addLineChatElement("error",1,0.5,0)

			-- remove scanned from list to scan
			InfectionScanner.Scanned[scanned] = nil

		-- time elapsed and got the answer needed
		elseif time >= 1.4 and result ~= "Waiting" then

			-- check if scanned is infected based on its class
			local isInfected

			-- check player
			if instanceof(scanned,"IsoPlayer") then
				isInfected = result == "Infected"

			-- check bandit
			elseif instanceof(scanned,"IsoZombie") then
				if activatedMods_Bandits then
					local brain = BanditBrain.Get(scanned)
					local infection = brain.infection
					if infection and infection > 0 then
						isInfected = true
					end
				end
			end

			-- give result of scan
			if isInfected then
				client_player:addLineChatElement("positive",1,0,0)
			else
				client_player:addLineChatElement("negative",0,1,0)
			end

			-- remove scanned from list to scan
			InfectionScanner.Scanned[scanned] = nil
		end
	end
end

---When equiping the item, play a sound of it turning on.
---@param character any
---@param inventoryItem any
InfectionScanner.OnEquipPrimary = function(character, inventoryItem)
	if character == client_player and inventoryItem and inventoryItem:getFullType() == "TLOU.InfectionScanner" then
		character:getEmitter():playSound('InfectionScanner_start')
		addSound(nil, character:getX(), character:getY(), character:getZ(), 7, 7)
	end
end