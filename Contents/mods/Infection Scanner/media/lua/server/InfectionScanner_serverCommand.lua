--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Handle server side commands received.

]]--
--[[ ================================================ ]]--

local InfectionScanner_server = {Commands = {}}

InfectionScanner_server.OnClientCommand = function(module, command, player, args)
    -- skip if not our module
    if module ~= "InfectionScanner" then return end

    -- ask to the scanned if he is infected to send to the checker
    if command == "AskIfInfected" then
        local scanned = getPlayerByOnlineID(args.scannedID)
        if scanned then
            sendServerCommand(scanned,"InfectionScanner","AskIfInfected",args)
        end

    -- send the answer of scanned to checker
    elseif command == "AnswerToChecker" then
        local checker = getPlayerByOnlineID(args.checkerID)
        if checker then
            sendServerCommand(checker,"InfectionScanner","AnswerToChecker",args)
        end
    end
end

Events.OnClientCommand.Add(InfectionScanner_server.OnClientCommand)

return InfectionScanner_server