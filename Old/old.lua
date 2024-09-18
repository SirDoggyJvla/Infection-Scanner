-- Function to calculate unique squares on the outline of a circle
local function circle_outline_squares(radius)
	radius = 5
    local unique_squares = {}
    local x, y,square

    -- Iterate over angles from 0 to 2π to trace the circle's outline
	local operation = 0
    for theta = 0, math.pi * 2, 0.1 do
		operation = operation + 1
        -- Calculate x and y using the parametric form of a circle
        x = client_player:getX() - round(radius * math.cos(theta))
        y = client_player:getY() - round(radius * math.sin(theta))

		square = getSquare(x,y,0)

		InfectionScanner.AddHighlightSquare(square,{r = 1,g = 0,b = 1})

        -- Store the square coordinates as a key in the table to ensure uniqueness
        unique_squares[x .. "," .. y] = true
    end
	print(operation)

    -- Return the number of unique squares
    local count = 0
    for _ in pairs(unique_squares) do
        count = count + 1
    end

	print(count)

    return count
end