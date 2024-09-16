--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Handle client side commands received.

]]--
--[[ ================================================ ]]--

-- localy initialize player
local client_player = getPlayer()
local function initTLOU_OnGameStart(playerIndex, player_init)
	client_player = getPlayer()
end
Events.OnCreatePlayer.Remove(initTLOU_OnGameStart)
Events.OnCreatePlayer.Add(initTLOU_OnGameStart)

-- requirements
local InfectionScanner = require "InfectionScanner_module"

InfectionScanner.OnServerCommand = function(module, command, args)
    -- skip if not our module
    if module ~= "InfectionScanner" then return end

    -- ask to the scanned if he is infected to send to the checker
    if command == "AskIfInfected" then
        -- get the scanned
        local scanned = getPlayerByOnlineID(args.scannedID)

        -- not for us
        if scanned ~= client_player then return end

        -- send the answer
        args.isInfected = scanned:getBodyDamage():IsInfected()
        sendClientCommand("InfectionScanner","AnswerToChecker",args)

    -- send the answer of scanned to checker
    elseif command == "AnswerToChecker" then
        local checker = getPlayerByOnlineID(args.checkerID)

        -- not for us or invalid
        if checker and checker ~= client_player then return end

        -- store result
        local isInfected = args.isInfected
        local scanned = getPlayerByOnlineID(args.scannedID)
        InfectionScanner.Scanned[scanned].result = isInfected and "Infected" or "notInfected"
    end
end

Events.OnServerCommand.Add(InfectionScanner.OnServerCommand)