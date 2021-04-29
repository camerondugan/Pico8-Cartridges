pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--room state
boxes={{x=50,y=25,s=7,pushable=true},{x=6,y=5,s=4,pushable=true},{x=37,y=37,s=4,pushable=true}}

--player state
x=5
y=10
speed=1

--draw
function _draw()
	cls()
	rect(1,1,125,125,3)
	foreach(boxes,draw_box)
	--foreach(boxes,push)
	--draw player
	pset(x,y,13)
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
	if (abs(dx)+abs(dy)>0) then
		sfx(0)
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
function box_occupied(ex,ey)
	for b in all(boxes) do
		if ex>=b.x and ex<=(b.x+b.s) then
			if ey>=b.y and ey<=(b.y+b.s) then
				return true
			end
		end
	end
	return false
end

function player_occupied(ex,ey)
	if (x==ex and y==ey) then
		return true
	end
	return false
end

function occupied(ex,ey)
	if box_occupied(ex,ey) then
		print("box")
		return true
	end
	if player_occupied(ex,ey) then
		print("player")
		return true
	end
	if (ex<=1 or ex>124) or (ey<=1 or ey>124) then
		return true
	end
	return false
end

--pushables
function push(b)
	if not b.pushable then
		return false
	end
	c=5
	--pushed right
	for i = 0, b.s, 1 do
		if (dx>0 and x==b.x-1 and y==b.y+i) then
			should_move=true
			for k=0, b.s, 1 do
				if occupied(b.x+b.s+1,b.y+k) then
					should_move=false
				end
			end
			if should_move then
				b.x+=dx
			end
		end
		--pset(b.x-1,b.y+i,c)
	end
	--pushed left
	for i = 0, b.s, 1 do
		if (dx<0 and x==b.x+b.s+1 and y==b.y+i) then
			should_move=true
			for k=0, b.s, 1 do
				if occupied(b.x-1,b.y+k) then
					should_move=false
				end
			end
			if should_move then
				b.x+=dx
			end
		end
		--pset(b.x+b.s+1,b.y+i,c)
	end
	--detect top
	for i = 0, b.s, 1 do
		if (dy>0 and x==b.x+i and y==b.y-1) then
			should_move=true
			for k=0, b.s, 1 do
				if occupied(b.x+k,b.y+b.s+1) then
					should_move=false
				end
			end
			if should_move then
				b.y+=dy
			end
		end
	end
	--detect bottom
	for i = 0, b.s, 1 do
		if (dy<0 and y==b.y+b.s+1 and x==b.x+i) then
			should_move=true
			for k=0, b.s, 1 do
				pset(b.x+k,b.y-1,3)
				if occupied(b.x+k,b.y-1) then
					should_move=false
				end
			end
			if should_move then
				b.y+=dy
			end
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
__sfx__
000400000151005510055100c5000e50010500115000c5000e50010500115000c5000e50010500115000c5000e50010500115000c5000e50010500115000c5000e50010500115000c5000e50010500115000c500
__music__
00 01424344

