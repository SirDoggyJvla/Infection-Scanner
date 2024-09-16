--[[ ================================================ ]]--
--[[  /~~\'      |~~\                  ~~|~    |      ]]--
--[[  '--.||/~\  |   |/~\/~~|/~~|\  /    | \  /|/~~|  ]]--
--[[  \__/||     |__/ \_/\__|\__| \/   \_|  \/ |\__|  ]]--
--[[                     \__|\__|_/                   ]]--
--[[ ================================================ ]]--
--[[

Handle the crafting recipe to dismantle the scanner.

]]--
--[[ ================================================ ]]--

local randCraft = newrandom()
function Recipe.OnCreate.DismantleInfectionScanner(items, result, player, selectedItem)
    local success = 50 + (player:getPerkLevel(Perks.Electricity)*5);
    for _=1,randCraft:random(1,3) do
        local r = randCraft:random(1,3);
        if r==1 then
            player:getInventory():AddItem("Base.ElectronicsScrap");
        elseif r==2 then
            player:getInventory():AddItem("Radio.ElectricWire");
        elseif r==3 then
            player:getInventory():AddItem("Base.Aluminum");
        end
    end
    if randCraft:random(0,99)<success then
        player:getInventory():AddItem("Base.Amplifier");
    end
    if randCraft:random(0,99)<success then
        player:getInventory():AddItem("Base.LightBulb");
    end

    for i=0,items:size() - 1 do
        local item = items:get(i)
        if item:getFullType() == "TLOU.InfectionScanner" then
            local charge = item:getUsedDelta()

            if charge ~= 0 then
                -- create a battery
                local battery = InventoryItemFactory.CreateItem("Base.Battery")
                battery:setUsedDelta(charge)

                player:getInventory():AddItem(battery)
            end
        end
    end
end

function Recipe.OnGiveXP.DismantleInfectionScanner(recipe, ingredients, result, player)
    player:getXp():AddXP(Perks.Electricity, 20);
end