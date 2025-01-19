require "PrintMedia/PrintMediaDefinitions"
local newFliers = {"TLOUInfectionScanner"}

for i = 1, #newFliers do
    table.insert(PrintMediaDefinitions.Fliers, newFliers[i])
end
