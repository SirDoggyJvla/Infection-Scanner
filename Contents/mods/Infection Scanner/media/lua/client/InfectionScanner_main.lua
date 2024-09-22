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

-- compatible patches
local activatedMods_Bandits = getActivatedMods():contains("Bandits")
local activatedMods_SporeZones = getActivatedMods():contains("BB_SporeZones")

if activatedMods_SporeZones then
	InfectionScanner.Modes["SporeDetector"] = {func = "Change2SporeDetector"}
end

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



---Test function to recursively find batteries that are not dead in the inventory.
---@param item InventoryItem
---@return boolean
InfectionScanner.isBattery = function(item)
	return item:getType() == "Battery" and item:getUsedDelta() ~= 0
end


---Test function to recursively find scanners in the inventory.
---@param item InventoryItem
---@return boolean
InfectionScanner.isScanner = function(item)
	return item:getFullType() == "TLOU.InfectionScanner"
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

		-- if item is a scanner
		if item:getFullType() == "TLOU.InfectionScanner" then
			local option
			local subMenu
			--- GET SCANNER DATA ---

			-- retrieve batteries in the inventory
			local inventory = player:getInventory()
			local batteries = ArrayList.new()
			inventory:getAllEvalRecurse(InfectionScanner.isBattery, batteries)
			local batteriesAmount = batteries:size()

			-- check if scanner is charged, equiped and activated
			local charged = item:getUsedDelta() ~= 0
			local equiped = equipedItem and equipedItem == item
			local scanner_modData = item:getModData()
			local activated = item:isActivated()


			--- CHANGE MODE OF SCANNER ---

			-- get mode
			local scannerMode = scanner_modData.InfectionScanner_mode
			if not scannerMode then
				item:getModData().InfectionScanner_mode = "Scanning"
				scannerMode = "Scanning"
			end

			local scannerModeName = getText("ContextMenu_InfectionScanner_Mode"..scannerMode)

			-- change mode
			-- create the option to change mode
			option = context:addOption(getText("ContextMenu_InfectionScanner_ChangeMode",scannerModeName))
			if not equiped then
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

			-- valid to change mode
			else
				-- create the submenu to change mode
				subMenu = context:getNew(context)
				context:addSubMenu(option, subMenu)

				-- add every modes as an option
				local optionName, func
				for k,v in pairs(InfectionScanner.Modes) do
					optionName = getText("ContextMenu_InfectionScanner_Mode"..k)
					func = InfectionScanner[v.func]

					option = subMenu:addOption(optionName, player, func, item)

					-- already in this mode
					if k == scannerMode then
						option.notAvailable = true
					end

					-- scanner needs to be equiped
					if not equiped then
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

					-- add the tooltip of the mode
					else
						local tooltip = ISWorldObjectContextMenu.addToolTip()
						tooltip.description = getText("Tooltip_InfectionScanner_Mode"..k)
						option.toolTip = tooltip

					end
				end
			end


			--- SCANNING MODE ---

			if scannerMode == "Scanning" then
				
				InfectionScanner.AddScannerOptionToContext(context,player,player,true,equiped,charged,activated,"ContextMenu_InfectionScanner_ScanYourself")
			
			elseif scannerMode == "SporeDetector" then
				
			
			end


			--- HANDLE BATTERY ---


			-- create the submenu to insert or swap a battery
			if not charged then
				option = context:addOption(getText("ContextMenu_InfectionScanner_InsertBattery"))
			else
				option = context:addOption(getText("ContextMenu_InfectionScanner_SwapBattery"))
			end

			-- if not batteries, then make option unavailable
			if batteriesAmount > 0 then
				subMenu = context:getNew(context)
				context:addSubMenu(option, subMenu)

				-- add every battery as an option to insert or swap battery
				local battery
				for j = 0,batteriesAmount - 1 do
					battery = batteries:get(j)

					local repairPercent = math.floor(battery:getUsedDelta() * 100.0).."%"
					subMenu:addOption(battery:getDisplayName()..":  "..repairPercent, player, InfectionScanner.ChangeBattery, item, battery, inventory)
				end
			else
				option.notAvailable = true
				local tooltip = ISWorldObjectContextMenu.addToolTip()
				tooltip.description = getText("Tooltip_InfectionScanner_noBatteriesAvailable")
				option.toolTip = tooltip
			end

			-- add option to remove the battery if present
			if charged then
				option = context:addOption(getText("ContextMenu_InfectionScanner_RemoveBattery"), player, InfectionScanner.RemoveBattery, item, inventory)
			end


			--- ONLY ADD OPTIONS FOR A SINGLE SCANNER ---
			break
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


InfectionScanner.createCircleDirectionCheck = function(radius,directions)
	-- create a direction table if doesn't exist already
	directions = directions or table.newarray()

	-- check from 1 to radius
	local uniques = {}
	local squares,x,y,uniqueKey,d
	for r = 1,radius do
		squares = table.newarray()

		-- create coordinates of squares of the circle of radius r
		for theta = 0, math.pi * 2, 0.01 do
			-- Calculate x and y using the parametric form of a circle
			x = round(r * math.cos(theta))
			y = round(r * math.sin(theta))

			-- get distance from center point
			d = ( x*x + y*y )^0.5

			-- verify these coordinates are not used for a direction check (to not have duplicate directions)
			uniqueKey = x..","..y
			if not uniques[uniqueKey] then
				-- add these coordinates in this circle
				uniques[uniqueKey] = true
				table.insert(squares,table.newarray(x,y,d))
			end
		end

		-- store them at this radius value
		table.sort(squares,function(a,b) return a[3] < b[3] end)
		directions[r] = squares
	end

	return directions
end

InfectionScanner.DirectionCheck = InfectionScanner.createCircleDirectionCheck(20)

---Determines the closest square and its distance to the start points based on a validation function `isValid`.
---
---Checks within a `radius` and in circle starting from the start points and going outward.
---Checks every floors within `min_h` and `max_h`
---@param startX number
---@param startY number
---@param radius int
---@param min_h int
---@param max_h int
---@param directions table
---@param isValid function
---@return IsoGridSquare|nil
---@return number|nil
InfectionScanner.findNearestValidSquare = function(startX, startY , radius, min_h, max_h, directions, isValid)
	-- iterate through every directions, starting at the nearest circle
	local direction,increase,x,y,x_dir,y_dir,square
	for r = 1,radius do
		-- retrieve directions
		direction = directions[r]
		if direction then
			-- iterate through every directions pointing to the circle coordinates
			for i = 1,#direction do
				-- retrieve the direction coordinates
				increase = direction[i]
				x_dir = increase[1]
				y_dir = increase[2]

				-- calculates point to check coordinates
				x = startX + x_dir
				y = startY + y_dir

				-- check within every floors
				for h = min_h,max_h do
					-- get square
					square = getSquare(x,y,h)

					-- verify square is valid
					if square and isValid(square) then
						return square,increase[3]
					end
				end
			end
		end
	end

	-- no squares found
	return nil, nil
end

InfectionScanner.OnTick = function(tick)
	local current_time = os.time()
	local time, result
	for scanned,tbl in pairs(InfectionScanner.Scanned) do
		time = current_time - tbl.time
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


	-- Cordyceps Spore Zone compatibility spore detection
	if activatedMods_SporeZones then
		-- cache emitters
		local emitter = client_player:getEmitter()
		local sporeZoneDetectorEmitter1 = emitter:isPlaying('InfectionScanner_SporeZone1')
		local sporeZoneDetectorEmitter2 = emitter:isPlaying('InfectionScanner_SporeZone2')

		-- we don't need to do any check if any of these emitters are playing
		if sporeZoneDetectorEmitter1 or sporeZoneDetectorEmitter2 then return end

		-- only update every n seconds minimum sound time
		local lastCheck = InfectionScanner.lastCheck
		if not lastCheck then InfectionScanner.lastCheck = current_time return end
		if current_time - lastCheck < 0.38 then return end
		InfectionScanner.lastCheck = current_time

		-- retrieve the first scanner
		local inventory = client_player:getInventory()
		local scanners = ArrayList.new()
		inventory:getAllEvalRecurse(InfectionScanner.isScanner,scanners)
		local scannersAmount = scanners:size()

		-- check every scanners
		if scannersAmount > 0 then
			local scanner, charged, activated
			for i = 0,scannersAmount - 1 do
				-- verify that scanner is activated, charged and in spore detection mode
				scanner = scanners:get(i)
				activated = scanner:isActivated()
				charged = scanner:getUsedDelta() ~= 0
				if activated and charged and scanner:getModData().InfectionScanner_mode == "SporeDetector" then
					-- check if scanner is valid to detect (attached or in hands)
					local primaryItem = client_player:getPrimaryHandItem()
					if scanner:getAttachedSlotType() or primaryItem and primaryItem == scanner then


						--- IN BUILDING ---

						if InfectionScanner.isSquareSporeZone(client_player) then
							emitter:playSound('InfectionScanner_SporeZone2')
							addSound(nil, client_player:getX(), client_player:getY(), client_player:getZ(), 7, 7)
						end



						--- CLOSE TO A SPORE ZONE ---

						if not emitter:isPlaying('InfectionScanner_SporeZone2') then
							-- detection radius
							local radius = SandboxVars.InfectionScanner.SporeZoneRadius

							-- get player coordinates
							local p_x = client_player:getX()
							local p_y = client_player:getY()
							local p_z = client_player:getZ()

							-- makes sure the code doesn't do weird shit when at the world height limit
							-- to check a floor above and below
							local min_h = p_z - 1
							min_h = min_h < 0 and 0 or min_h > 7 and 7 or min_h
							local max_h = p_z + 1
							max_h = max_h < 0 and 0 or max_h > 7 and 7 or max_h

							-- retrieve nearest spore zone square
							local _,dist = InfectionScanner.findNearestValidSquare(p_x,p_y,radius,min_h,max_h,InfectionScanner.DirectionCheck,InfectionScanner.isSquareSporeZone)

							-- check if something is detected
							if dist then
								-- check if should bip
								local lastBip = InfectionScanner.lastBip
								local shouldBip = true
								if lastBip then
									local bipTime = lastBip.time
									local diffTime = current_time - bipTime
									dist = dist - dist%1
									local timeToBip = (dist - 1)/5 * 3
									if diffTime < timeToBip then
										shouldBip = false
									end
								end

								if shouldBip then
									emitter:playSound('InfectionScanner_SporeZone1')
									addSound(nil, client_player:getX(), client_player:getY(), client_player:getZ(), 7, 7)
									InfectionScanner.lastBip = {time = current_time, dist = dist}
								end
							elseif InfectionScanner.lastBip then
								InfectionScanner.lastBip = nil
							end
						end



						-- skip other scanners, no point in running all of them
						break
					end
				end
			end
		end
	end
end

---When equiping the item, play a sound of it turning on.
---@param character any
---@param inventoryItem any
InfectionScanner.OnEquipPrimary = function(character, inventoryItem)
	if character == client_player and inventoryItem and inventoryItem:getFullType() == "TLOU.InfectionScanner" then
		local activated = inventoryItem:isActivated()

		if activated then
			character:getEmitter():playSound('InfectionScanner_start')
			addSound(nil, character:getX(), character:getY(), character:getZ(), 7, 7)
		end
	end
end
