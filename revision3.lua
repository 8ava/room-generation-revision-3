
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
	celldata: celldata;
	rotation: number;
	
	doorways: directions;
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

local function determineroomdata(celldata: celldata)
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
	
	if rotation > 0 then
		for a, b in doors do
			b += rotation; b %= 5
		end
	end
	
	return {
		roomtype = roomtype;
		rotation = rotation;
		doorways = doors
	}
end

local function deconstcell(a) -- unstable rn
	--[[local cell = cells[a]
	
	if not cell then warn('no cell at index') return end
	
	cell.model:Destroy()
	
	table.clear(cell)
	cells[a] = nil]]
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
	
	
	for a, _ in roomdata.doorways do
		registerstem(celldata.surrounding.coords[a])
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
	for a, b in cells do
		local currentsurrounding = getsurrounding(a)
		local surroundedby4 = currentsurrounding.cells.left and currentsurrounding.cells.right and currentsurrounding.cells.up and currentsurrounding.cells.down
		
		if b.roomdata.roomtype == 'room2' then
			if b.roomdata.rotation == 0 and currentsurrounding.cells.up or currentsurrounding.cells.down then
				if currentsurrounding.cells.up and currentsurrounding.cells.up.roomdata.doorways.down then
					warn(tostring(a)..' '.. b.roomdata.roomtype.. '  SHOULDBE  room3')

					deconstcell(a)
					draw(a)
				end
				
				if currentsurrounding.cells.down and currentsurrounding.cells.down.roomdata.doorways.up then
					warn(tostring(a)..' '.. b.roomdata.roomtype.. '  SHOULDBE  room3')

					deconstcell(a)
					draw(a)
				end
			end
		end
		
		if surroundedby4 and not (b.roomdata.roomtype == 'room4' or b.roomdata.roomtype == 'corner') then
			warn(tostring(a)..' '.. b.roomdata.roomtype.. '  SHOULDBE  room4')
			
			deconstcell(a)
			draw(a)
		end
	end
end


for _, a in rooms.prequired do
	draw(r:NextInteger(0, mapdata.area), a)
end
print('prereqs added')

draw(0)
draw(mapdata.width - 1)
draw(mapdata.area - mapdata.width)
draw(mapdata.area - 1)
print('corners added')

for a = 0, 99 do
	for a, b in stems do
		if b then 
			draw(a)
		end
	end
end
print('stems completed'.. ' - iters: 99')

revise()
print('revised')

for _, a in cells do
	if not a.celldata then continue end -- error with deconst
	
	local p = coordtoposition(a.celldata.position)
	a.model.Name = a.celldata.position
	a.model:PivotTo(CFrame.new(Vector3.new(p.X * mapdata.scale, 0, p.Y * mapdata.scale)) * CFrame.fromOrientation(0, math.rad(a.roomdata.rotation * 90), 0))
	
	a.model.Parent = game.Workspace
end
print('set rooms')