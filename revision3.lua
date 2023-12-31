
-- origin of generation at center of grid
-- edges of map are exclusive to endrooms
-- most of the map is horizontal room2s
-- only occasional breaks to move down y axis


-- hcz is much more lenient with many more room3s and room4s

local r = Random.new()

local roompool = game.ServerStorage.activerooms

type roomwrap = {celldata: celldata, roomdata: roomdata, model: Model}

type directions = {left: number ?, right: number ?, up: number ?, down: number ?}

type surrounding = {
	cells: {
		left: roomwrap;
		right: roomwrap;
		up: roomwrap;
		down: roomwrap
	};
	
	coords: {
		left: number;
		right: number;
		up: number;
		down: number
	}
}

type celldata = {
	position: number;
	rotation: number;
	surrounding: surrounding
}

type roomdata = {
	roomtype: string;
	rotation: number;
	
	doorways: directions;
}

local mapdata = { -- scpcbsize 19
	width = 19;
	height = 19;
	
	scale = 40.8
}

mapdata.area = mapdata.width * mapdata.height


local function coordtoposition(a): Vector2
	return Vector2.new(a % mapdata.width, math.floor(a / mapdata.width))
end

local directions = {
	left = 1;
	right = 2;
	up = 3;
	down = 4
}

local doorways = { -- numbered directions
	corner = {left = 1, up = 3};
	
	room1 = {down = 4};
	room2 = {left = 1, right = 2};
	room3 = {left = 1, right = 2, down = 4};
	room4 = {left = 1, right = 2, up = 3, down = 4};
}

local rooms = {
	prequired = {'testroom'; 'room2sl'; 'checkpoint1';};
	
	room1 = {};
	room2 = {'tunnel'; 'room2_4'; 'room2gw_b';};
	room3 = {'room3'; 'room3_3'; 'room3pit'; 'room3z2'; 'room3servers';};
	room4 = {'room4'; 'room4pit'; 'room4z';};
	
	corner = {'lockroom1'; 'room2cpit';}
}

local cells = {}
local stems = {}


local function registerstem(c)
	if c >= 0 and c <= mapdata.area - 1 and not cells[c] and not stems[c] then
		stems[c] = true
	end
end

local function getsurrounding(coord): surrounding
	local class = {
		cells = {};
		
		coords = {
			left = coord - 1;
			right = coord + 1;
			up = coord - mapdata.width;
			down = coord + mapdata.width
		}
	}
	
	
	for a, b in class.coords do
		class.cells[a] = cells[b]
	end
	
	return class
end

local function constcelldata(coord): celldata
	return {
		position = coord;
		rotation = 0;
		surrounding = getsurrounding(coord)
	}
end

local function determineroomdata(celldata: celldata): roomdata
	local gridp = coordtoposition(celldata.position)
	local iscorner = celldata.position == 0 or celldata.position == mapdata.width - 1 or celldata.position == mapdata.area - 1 or celldata.position == mapdata.area - mapdata.width
	
	local roomtype
	local rotation = 0
	
	roomtype = 'room2'
	
	if #celldata.surrounding.cells == 4 then
		roomtype = 'room4'
		rotation = r:NextInteger(0, 4)
	end
	
	if celldata.surrounding.cells.left and celldata.surrounding.cells.right and celldata.surrounding.cells.down and not celldata.surrounding.cells.up then
		roomtype = 'room3'
		rotation = 0
	end
	
	if celldata.surrounding.cells.left and celldata.surrounding.cells.right and not celldata.surrounding.cells.down and celldata.surrounding.cells.up then
		roomtype = 'room3'
		rotation = 1
	end
	
	if celldata.surrounding.cells.left and not celldata.surrounding.cells.right and celldata.surrounding.cells.down and celldata.surrounding.cells.up then
		roomtype = 'room3'
		rotation = 3
	end
	
	if not celldata.surrounding.cells.left and celldata.surrounding.cells.right and celldata.surrounding.cells.down and celldata.surrounding.cells.up then
		roomtype = 'room3'
		rotation = 4
	end
	
	if gridp.X == 0 and not (gridp.Y == 0 or gridp.Y == mapdata.height) then
		roomtype = 'room2'
		rotation = 1
	end
	
	if gridp.Y == 0 and not (gridp.X == 0 or gridp.X == mapdata.width - 1) then
		roomtype = 'room2'
		rotation = 0
	end
	
	if gridp.X == mapdata.width - 1 and not (gridp.Y == 0 or gridp.Y == mapdata.height) then
		roomtype = 'room2'
		rotation = 3
	end
	
	if gridp.Y == mapdata.height - 1 and not (gridp.X == 0 or gridp.X == mapdata.width - 1) then
		roomtype = 'room2'
		rotation = 2
	end
	
	if celldata.surrounding.cells.left and celldata.surrounding.cells.right and not celldata.surrounding.cells.up and not celldata.surrounding.cells.down then
		roomtype = 'room2'
		rotation = 0
	end

	if celldata.surrounding.cells.up and celldata.surrounding.cells.down and not celldata.surrounding.cells.left and not celldata.surrounding.cells.right then
		roomtype = 'room2'
		rotation = 1
	end
	
	
	if iscorner then
		roomtype = 'corner'
		
		rotation = 
			celldata.position == 0 and 2 or
			celldata.position == mapdata.width - 1 and 1 or
			celldata.position == mapdata.area - mapdata.width and 3 or
			0
		
		if #celldata.surrounding.cells > 0 then
			rotation = celldata.surrounding.cells.left and celldata.surrounding.cells.up and 2 or
				celldata.surrounding.cells.left and celldata.surrounding.cells.down and 3 or
				celldata.surrounding.cells.right and celldata.surrounding.cells.down and 0 or
				1
		end
	end
	
	
	local doors = doorways[roomtype] or doorways.room2
	
	print(roomtype)
	print(doors)
	
	if rotation > 0 then
		for a, b in doors do
			b += rotation; b %= 4
		end
	end
	
	print(rotation)
	print(doors)
	
	return {
		roomtype = roomtype;
		rotation = rotation;
		doorways = doors
	}
end

local function deconstcell(coord) -- unstable rn
	local cell = cells[coord]
	
	if not cell then warn('no cell at index') return end
	
	cell.model:Destroy()
	
	--table.clear(cell)
	cells[coord] = false -- just figured out what made the inteliense think this was a bool
end

local function render(a)
	local p = coordtoposition(a.celldata.position)
	a.model.Name = a.celldata.position
	a.model:PivotTo(CFrame.new(Vector3.new(p.X * mapdata.scale, 0, p.Y * mapdata.scale)) * CFrame.fromOrientation(0, math.rad(a.roomdata.rotation * 90), 0))

	a.model.Parent = game.Workspace
end

local function draw(args: {coord: number, overrideroom: string ?, rotation: number ?, roomtype: string ?})
	if cells[args.coord] then warn('overlap') return end
	
	local room
	
	local celldata = constcelldata(args.coord)
	local roomdata = determineroomdata(celldata)
	
	if args.overrideroom then
		room = args.overrideroom
	elseif args.roomtype then
		room = rooms[args.roomtype][r:NextInteger(1, #rooms[args.roomtype])]
	else
		room = rooms[roomdata.roomtype][r:NextInteger(1, #rooms[roomdata.roomtype])]
	end
	
	local model = roompool[room]:Clone()
	
	if args.rotation then
		celldata.rotation = args.rotation
		roomdata.rotation = args.rotation
	end
	
	for a, _ in roomdata.doorways do
		registerstem(celldata.surrounding.coords[a])
	end
	
	
	if stems[args.coord] then
		stems[args.coord] = nil
	end
	
	cells[args.coord] = {
		model = model;
		
		celldata = celldata;
		roomdata = roomdata
	}
	
	args = nil; -- i love gc
end

local function revise()
	--[[for a, b in cells do
		--local draft = determineroomdata(a)
		
		deconstcell(a)
		draw({coord = a})
	end]]
end


for _, a in rooms.prequired do
	draw({coord = r:NextInteger(0, mapdata.area), overrideroom = a})
end
print('prereqs added')

--[[draw({coord = 0})
draw({coord = mapdata.width - 1})
draw({coord = mapdata.area - mapdata.width})
draw({coord = mapdata.area - 1})]]

draw({coord = math.floor(mapdata.width / 2), roomtype = 'room3'}) -- from center
draw({coord = math.floor(mapdata.width / 3), roomtype = 'room3'}) -- left fraction
draw({coord = math.floor(mapdata.width / 3) * 2, roomtype = 'room3'}) -- right fraction

print('corners added')

for a = 0, 2 do
	--if #stems < 1 then break end -- cant do this
	
	for a, b in stems do
		if b then 
			draw({coord = a})
		end
	end
end
print('stems completed'.. ' - iters: 2')

revise()
print('revised')

for _, a in cells do -- i want to see these in order of stems
	render(a)
end
print('set rooms')