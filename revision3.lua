
local r = Random.new()

local roompool = game.ServerStorage.activerooms

type surrounding = {
	cells: {
		left: boolean;
		right: boolean;
		up: boolean;
		down: boolean
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
	celldata: celldata;
	
}

local mapdata = {
	width = 19;
	height = 19;
	
	scale = 40.8
}

mapdata.area = mapdata.width * mapdata.height


local function coordtoposition(a): Vector2
	return Vector2.new(a % mapdata.width, math.floor(a / mapdata.width))
end

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

local function determineroomdata(celldata: celldata)
	local gridp = coordtoposition(celldata.position)
	local iscorner = celldata.position == 0 or celldata.position == mapdata.width - 1 or celldata.position == mapdata.area - 1 or celldata.position == mapdata.area - mapdata.width
	
	local roomtype
	local rotation = 0
	
	roomtype = 'room4'
	
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
		roomtype = 'room3'
		rotation = 1
	end
	
	if gridp.Y == 0 and not (gridp.X == 0 or gridp.X == mapdata.width - 1) then
		roomtype = 'room3'
		rotation = 0
	end
	
	if gridp.X == mapdata.width - 1 and not (gridp.Y == 0 or gridp.Y == mapdata.height) then
		roomtype = 'room3'
		rotation = 3
	end
	
	if gridp.Y == mapdata.height - 1 and not (gridp.X == 0 or gridp.X == mapdata.width - 1) then
		roomtype = 'room3'
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
	
	return {
		roomtype = roomtype;
		rotation = rotation
	}
end

local function draw(c, override)
	if cells[c] then warn('overlap') return end
	
	local room
	
	local celldata = constcelldata(c)
	local roomdata = determineroomdata(celldata)
	
	if override then
		room = override
	else
		room = rooms[roomdata.roomtype][r:NextInteger(1, #rooms[roomdata.roomtype])]
	end
	
	local model = roompool[room]:Clone()
	
	
	for _, a in celldata.surrounding.coords do
		registerstem(a)
	end
	
	
	if stems[c] then
		stems[c] = nil
	end
	
	cells[c] = {
		model = model;
		
		celldata = celldata;
		roomdata = roomdata
	}
end

local function revise()
	for _, a in cells do
		if #a.celldata.surrounding.cells == 4 then
			warn('needs to be changed')
		end
	end
end


for _, a in rooms.prequired do
	draw(r:NextInteger(0, mapdata.width * mapdata.height), a)
end
print('prereqs added')

draw(0)
draw(mapdata.width - 1)
draw(mapdata.area - mapdata.width)
draw(mapdata.area - 1)
print('corners added')

for a = 0, 1 do
	for a, b in stems do
		if b then 
			draw(a)
		end
	end
end
print('stems completed'.. ' - iters: 1')

revise()
print('revised')

for _, a in cells do
	local p = coordtoposition(a.celldata.position)
	a.model:PivotTo(CFrame.new(Vector3.new(p.X * mapdata.scale, 0, p.Y * mapdata.scale)) * CFrame.fromOrientation(0, math.rad(a.roomdata.rotation * 90), 0))
	
	a.model.Parent = game.Workspace
end
print('set rooms')