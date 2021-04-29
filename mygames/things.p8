pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--room state
boxes={{x=50,y=25,s=7,pushable=false},{x=6,y=5,s=4,pushable=true},{x=37,y=37,s=4,pushable=true}}

--player state
x=5
y=10
speed=1

--draw
function _draw()
	cls()
	rect(1,1,125,125,3)
	foreach(boxes,draw_box)
	--draw player
	pset(x,y,1)
end

function draw_box(b)
	rectfill(b.x,b.y,b.x+b.s,b.y+b.s,4)
end

--game overview
function _update60()
	boxcol=false
	get_input()
	foreach(boxes,push)
	move()
end

--input
function get_input()
	dx=0
	dy=0
	if btn(0) then
		dx-=speed
	end
	if btn(1) then
		dx+=speed
	end
	if btn(2) then
	 dy-=speed
	end
	if btn(3) then
		dy+=speed
	end
end

--player movement
function move()
	if not collides(boxes,dx,dy) then
		x+=dx
		y+=dy
	end
end

--collision
function collides(boxes,dx,dy)
	px=x+dx
	py=y+dy
	--wall
	if (py<2 or py>124)then
		return true
	end
	if (px<2 or px>124)then
		return true
	end
	--boxes
	foreach(boxes,boxcollides)
	if boxcol then
		return true end
	return false
end

--collision
function boxcollides(b)
	if (px>=b.x and px<=(b.x+b.s)) then
		if (py>=b.y and py<=(b.y+b.s)) then
			boxcol=true
		end
	end
end

--occupency
function box_occupied(b)
	if (px>=b.x and px<=(b.x+b.s)) then
		if (py>=b.y and py<=(b.y+b.s)) then
			box_occupied=true
		end
	end
end

function player_occupied(ex,ey)
	if (x==ex and x==ey) then
		player_occupied=true
	end
end

function occupied(ex,ey)
	occupied=false
	foreach(boxes,box_occupied)
	if box_occupied then
		occupied=true
	end
	player_occupied(ex,ey)
	if (player_occupied) then
		occupied=true
	end
end

--pushables
function push(b)
	if not b.pushable then
		return false
	end
	c=5
	--detect left
	for i = 0, b.s, 1 do
		if (dx>0 and x==b.x-1 and y==b.y+i) then
			b.x+=dx
		end
		--pset(b.x-1,b.y+i,c)
	end
	--detect right
	for i = 0, b.s, 1 do
		if (dx<0 and x==b.x+b.s+1 and y==b.y+i) then
			b.x+=dx
		end
		--pset(b.x+b.s+1,b.y+i,c)
	end
	--detect top
	for i = 0, b.s, 1 do
		if (dy>0 and x==b.x+i and y==b.y-1) then
			b.y+=dy
		end
	end
	--detect bottom
	for i = 0, b.s, 1 do
		if (dy<0 and y==b.y+b.s+1 and x==b.x+i) then
			b.y+=dy
		end
		--pset(b.x+i,b.y+b.s+1,c)
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
