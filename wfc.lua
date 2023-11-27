local cellDatas = {
	type1 = {up = "BCB", down = "BAB", left = "BCB", right = "BAB", rev = 0, origin = "type1"},
	type2 = {up = "BBB", down = "BBB", left = "BAB", right = "BAB", rev = 0, origin = "type2"},
	type3 = {up = "BBB", down = "BAB", left = "BAB", right = "BAB", rev = 0, origin = "type3"},
	type4 = {up = "BCB", down = "BAB", left = "BAB", right = "BAB", rev = 0, origin = "type4"},
	type5 = {up = "BBB", down = "BAB", left = "BBB", right = "BAB", rev = 0, origin = "type5"}
}

local cellTypes = {}

local gridSize = 10

local tryCount = 0

local CELL_SIZE = Vector3.new(64, 17, 64)

grid = {}

local function getCellData(cellType)
	return cellDatas[cellType]
end

local function rotate(cellData, deg90, cellType)
	local newCell = {}
	if (deg90 == 1) then
		newCell["up"] = cellData.left
		newCell["right"] = cellData.up
		newCell["down"] = cellData.right
		newCell["left"] = cellData.down
	elseif (deg90 == 2) then
		newCell["up"] = cellData.down
		newCell["right"] = cellData.left
		newCell["down"] = cellData.up
		newCell["left"] = cellData.right
	elseif (deg90 == 3) then
		newCell["up"] = cellData.right
		newCell["right"] = cellData.down
		newCell["down"] = cellData.left
		newCell["left"] = cellData.up
	end
	newCell["rev"] = deg90
	newCell["origin"] = cellType
	return newCell
end

local function setData()
	local newCellDatas = {}
	cellTypes = {}
	
	local cnt = 0
	for _, _ in pairs(cellDatas) do
		cnt += 1
	end
	
	print(cnt)
	
	local typeC = cnt + 1
	
	for deg = 1, 3 do
		for typeS = 1, cnt do
			local ocn = "type" .. typeS
			local originCell = getCellData(ocn)
			newCellDatas["type" .. typeC] = rotate(originCell, deg, ocn)
			typeC += 1
		end
	end
	
	--for x = 1, 4 do
	--	for y = 1, 3 do
	--		local ocn = "type" .. x
	--		local originCell = getCellData(ocn)
	--		newCellDatas["type" .. typeC] = rotate(originCell, y, ocn)
	--		typeC += 1
	--	end
	--end

	--for k, v in pairs(cellDatas) do
	--	for x = 1, 3 do
	--		newCellDatas["type" .. typeC] = rotate(v, x, k)
	--		typeC += 1
	--	end
	--end

	--print(newCellDatas)

	for k, v in pairs(newCellDatas) do
		cellDatas[k] = v
	end

	for k, _ in pairs(cellDatas) do
		table.insert(cellTypes, k)
	end

	print(cellDatas, cellTypes)
end

local function init()
	grid = {}
	tryCount = 0

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
		table.insert(collapsableCells, {z = math.random(2, gridSize - 1), x = math.random(2, gridSize - 1)})
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

		--print(z, x, cell, " collapsed!")

		return z, x
	end

	return nil
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

	--print(grid)
	return true
end

local function performWFC()
	local l = observe()

	local cz, cx = collapse(l)

	--print(cz, cx, l)

	local t = propagate(cz, cx)

	if (not t) then
		--print("error! regenerate!")
		init()
	end

	return t
end

local function getRealType(cellType)
	return cellDatas[cellType]
end

local ceiling = game.ReplicatedStorage.celling

local function getOutput(level)
	local output = {}
	local possibleSpawnPoints = {}
	local possibleExitPoints = {}
	if grid then
		for z = 1, gridSize do
			for x = 1, gridSize do
				if (grid[z][x].collapsed) then
					local cellType = grid[z][x].possibleTypes[1]
					local realType = getRealType(cellType).origin
					local rev = getRealType(cellType).rev
					local pattern = "(%a+)(%d+)"
					
					local randNum = math.random(0, 3)
					local _, number = realType:match(pattern)
					local randType = "type" .. (randNum * 5) + number
					
					--print(realType, randType, rev, randNum)
					
					print(z, x, randType, rev)
					
					if randType then
						--print(string.format("Cell (%d, %d) Type: %s", z, x, cellType))
						if game.Workspace.Cell:FindFirstChild(randType) then
							local origin = game.Workspace.Cell:WaitForChild(randType)
							local copy = origin:Clone()
							local newPosition = Vector3.new(
								(x - 1) * CELL_SIZE.X + (CELL_SIZE.X / 2),
								150,
								(z - 1) * CELL_SIZE.Z + (CELL_SIZE.Z / 2) + (level - 1) * 100
							)
							local rotation = CFrame.Angles(0, math.rad(-90 * rev), 0)
							copy:PivotTo(CFrame.new(newPosition) * rotation)
							if (randType == "type10" or randType == "type20") then
								copy:PivotTo(copy:GetPivot() * CFrame.Angles(0, math.rad(90), math.rad(-90)))
								print("pivoting!")
							end
							copy.Parent = workspace
							
							local pos = Vector3.new(
								(x - 1) * CELL_SIZE.X + (CELL_SIZE.X / 2), 
								172.8, 
								(z - 1) * CELL_SIZE.Z + (CELL_SIZE.Z / 2) + (level - 1) * 100
							)
							local cp = ceiling:Clone()
							cp:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.rad(-90 * rev), 0))
							cp.Parent = workspace
						end
						if (output[cellType] == nil) then
							output[cellType] = 1
						else
							output[cellType] += 1
						end
						if (randType == "type1" or randType == "type3" or randType == "type14") then
							local obj = {z = z, x = x}
							table.insert(possibleSpawnPoints, obj)
						end
					end
				end
			end
		end
		print(output)
		
		local sl = workspace.SpawnLocation
		local rand = math.random(#possibleSpawnPoints)
		local obj = possibleSpawnPoints[rand]
		sl.Position = Vector3.new(
			(obj.x - 1) * CELL_SIZE.X + (CELL_SIZE.X / 2), 
			157, 
			(obj.z - 1) * CELL_SIZE.Z + (CELL_SIZE.Z / 2) + (level - 1) * 100
		)
		sl.Parent = workspace
		
		local p1 = Instance.new("Part")
		p1.Size = Vector3.new(CELL_SIZE.X * gridSize, 46, 2)
		p1.Position = Vector3.new(
			(CELL_SIZE.X * gridSize) / 2, 
			150, 
			-1 + (level - 1) * 100
		)
		p1.Anchored = true
		p1.Material = Enum.Material.Concrete
		p1.Parent = workspace

		local p2 = Instance.new("Part")
		p2.Size = Vector3.new(2, 46, CELL_SIZE.X * gridSize)
		p2.Position = Vector3.new(
			-1, 
			150, 
			(CELL_SIZE.X * gridSize) / 2 + (level - 1) * 100
		)
		p2.Anchored = true
		p2.Material = Enum.Material.Concrete
		p2.Parent = workspace

		local p3 = Instance.new("Part")
		p3.Size = Vector3.new(CELL_SIZE.X * gridSize, 46, 2)
		p3.Position = Vector3.new(
			(CELL_SIZE.X * gridSize) / 2, 
			150, 
			(CELL_SIZE.X * gridSize) + 1 + (level - 1) * 100
		)
		p3.Anchored = true
		p3.Material = Enum.Material.Concrete
		p3.Parent = workspace

		local p4 = Instance.new("Part")
		p4.Size = Vector3.new(2, 46, CELL_SIZE.X * gridSize)
		p4.Position = Vector3.new(
			(CELL_SIZE.X * gridSize) + 1, 
			150, 
			(CELL_SIZE.X * gridSize) / 2 + (level - 1) * 100
		)
		p4.Anchored = true
		p4.Material = Enum.Material.Concrete
		p4.Parent = workspace
		
	else
		print("Failed to generate a valid grid after multiple attempts.")
	end
end 

local function run(level)
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

	getOutput(level)
end

--setData()

--init()

--run(level)