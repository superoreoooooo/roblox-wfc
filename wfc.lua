local cellDatas = {
	type1 = {up = "1A", down = "2A", left = "3A", right = "4F"},
	type2 = {up = "4F", down = "1A", left = "2A", right = "3A"},
	type3 = {up = "3A", down = "4F", left = "1A", right = "2A"},
	type4 = {up = "2A", down = "3A", left = "4F", right = "1A"}
}

local cellTypes = {}

local gridSize = 8

local tryCount = 0

grid = {}

local function init()
	cellTypes = {}
	grid = {}
	tryCount = 0
	
	for k, _ in pairs(cellDatas) do
		table.insert(cellTypes, k)
	end
	
	for z = 1, gridSize do
		grid[z] = {}
		for x = 1, gridSize do
			grid[z][x] = {
				collapsed = false,
				possibleTypes = cellTypes
			}
		end
	end
end

local function getEntropy(z, x)
	local cell = grid[z][x]
	
	return #cell.possibleTypes
end

local function observe()
	local lowestEntropy = #cellTypes
	local collapsableCells = {}
	
	for z = 1, gridSize do
		for x = 1, gridSize do
			if (lowestEntropy >= getEntropy(z, x)) then
				local cell = grid[z][x]
				
				if (cell.collapsed == false) then
					if (lowestEntropy ~= getEntropy(z, x)) then
						collapsableCells = {}
					end
					table.insert(collapsableCells, {z = z, x = x})
				end
			end
		end
	end

	if (tryCount == 0) then
		collapsableCells = {}
		table.insert(collapsableCells, {z = 1, x = 1})
		tryCount += 1
	end
	
	return collapsableCells
end

local function collapse(lowEntropyCells)
	local pick = lowEntropyCells[math.random(#lowEntropyCells)]
	local z = pick.z
	local x = pick.x
	local cell = grid[z][x]
	
	if (cell.collapsed == false) then
		local typePick = math.random(#cell.possibleTypes)
		local t = cell.possibleTypes[typePick]
		
		cell.possibleTypes = {t}
		cell.collapsed = true
		
		print(z, x, cell, " collapsed!")
		
		return z, x
	end
	
	return nil
end

local function getCellData(cellType)
	return cellDatas[cellType]
end

local function isPossibleSide(cell1Type, cell2Type, cell1Side)
	local opposite = {up = "down", down = "up", right = "left", left = "right"}
	return getCellData(cell1Type)[cell1Side] == getCellData(cell2Type)[opposite[cell1Side]]
end

local function propagate(z, x)
	local collapsedCell = grid[z][x]
	
	if (z - 1 > 0) then
		local effectedCell = grid[z - 1][x]
		local possibleTypes = {}
		for n, v in ipairs(effectedCell.possibleTypes) do
			if (isPossibleSide(collapsedCell.possibleTypes[1], v, "left")) then
				table.insert(possibleTypes, v)
			end
		end
		if (#possibleTypes ~= 0) then
			--print(possibleTypes)
			effectedCell.possibleTypes = possibleTypes
		else 
			return false
		end
	end
	
	if (z + 1 < gridSize) then
		local effectedCell = grid[z + 1][x]
		local possibleTypes = {}
		for n, v in ipairs(effectedCell.possibleTypes) do
			if (isPossibleSide(collapsedCell.possibleTypes[1], v, "right")) then
				table.insert(possibleTypes, v)
			end
		end
		if (#possibleTypes ~= 0) then
			--print(possibleTypes)
			effectedCell.possibleTypes = possibleTypes
		else 
			return false
		end
	end
	
	if (x - 1 > 0) then
		local effectedCell = grid[z][x - 1]
		local possibleTypes = {}
		for n, v in ipairs(effectedCell.possibleTypes) do
			if (isPossibleSide(collapsedCell.possibleTypes[1], v, "down")) then
				table.insert(possibleTypes, v)
			end
		end
		if (#possibleTypes ~= 0) then
			--print(possibleTypes)
			effectedCell.possibleTypes = possibleTypes
		else 
			return false
		end
	end

	if (x + 1 < gridSize) then
		local effectedCell = grid[z][x + 1]
		local possibleTypes = {}
		for n, v in ipairs(effectedCell.possibleTypes) do
			if (isPossibleSide(collapsedCell.possibleTypes[1], v, "up")) then
				table.insert(possibleTypes, v)
			end
		end
		if (#possibleTypes ~= 0) then
			--print(possibleTypes)
			effectedCell.possibleTypes = possibleTypes
		else 
			return false
		end
	end
	
	print(grid)
	return true
end

local function performWFC()
	local l = observe()

	local cz, cx = collapse(l)

	print(cz, cx, l)
	
	local t = propagate(cz, cx)
	
	if (not t) then
		print("error! regenerate!")
		init()
	end
	
	return t
end

local function getOutput()
	local CELL_SIZE = Vector3.new(40, 10, 40)

	if grid then
		for z = 1, gridSize do
			for x = 1, gridSize do
				if (grid[z][x].collapsed) then
					local cellType = grid[z][x].possibleTypes[1]
					--print(getCellType(cellType))
					if cellType then
						--print(string.format("Cell (%d, %d) Type: %s", z, x, cellType))
						if game.Workspace.Cells:FindFirstChild(cellType) then
							
							local cellTemplate = game.Workspace.Cells:WaitForChild(cellType)
							local newCell = cellTemplate:Clone()

							newCell.Position = Vector3.new((x - 1) * CELL_SIZE.X, 6.5, (z - 1) * CELL_SIZE.Z)
							newCell.Parent = workspace  -- You can set a different parent if needed

							newCell.Anchored = true  -- Ensure the part is anchored
							newCell.CanCollide = true  -- If you want the part to be solid
						end
					end
				end
			end
		end
	else
		print("Failed to generate a valid grid after multiple attempts.")
	end
end




local function run()
	local done = false
	
	while not done do
		done = performWFC()
		
		for z = 1, gridSize do
			for x = 1, gridSize do
				if (grid[z][x].collapsed == false) then
					done = false
				end
			end
		end
	end

	print(grid)

	getOutput()
end


init()


run()