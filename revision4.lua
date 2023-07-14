--[[

rules


mapdata class

dimensions
width
height
scale

segments
lightcontainment
heavycontainment
enterancezone


roomtypes -- going to centralize datapoint

corner
room1
room2
room3
room4

]]

type directions = {
	left: any;
	right: any;
	up: any;
	down: any
}

type roomtype = {
	doorways: directions
}

local mapdata = {
	dimensions = {
		width = 19;
		height = 19;

		scale = 40
	}
}

local roomtypes =  {
	corner = {doorways = {}}
}