pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--room state
boxes={{x=50,y=25,sx=17,sy=17,pushable=true},{x=6,y=5,sx=10,sy=10,pushable=true},{x=37,y=37,sx=8,sy=8,pushable=true}}

--player state
p={}
p.x=5
p.y=10
p.sx=2
p.sy=4
speed=1

--draw
function _draw()
	cls()
	rect(1,1,125,125,3)
	foreach(boxes,draw_box)
	--foreach(boxes,push)
	--draw player
	rectfill(p.x,p.y,p.x+p.sx,p.y+p.sy,13)
end

function draw_box(b)
	--body
	rectfill(b.x,b.y,b.x+b.sx,b.y+b.sy,4)
	rectfill(b.x+1,b.y+1,b.x+b.sx-1,b.y+b.sy-1,15)
	--wood bars
	line(b.x,b.y,b.x+b.sx,b.y+b.sy,4)
	line(b.x+b.sx,b.y,b.x,b.y+b.sy,4)
	--metal corners
	pset(b.x,b.y,5)
	pset(b.x+b.sx,b.y)
	pset(b.x,b.y+b.sy)
	pset(b.x+b.sx,b.y+b.sy)
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
	if (btn(0))	dx-=speed
	if (btn(1))	dx+=speed
	if (btn(2)) dy-=speed
	if (btn(3))	dy+=speed
	if (abs(dx)+abs(dy)>0)	sfx(0)
end

--player movement
function move()
	if not collides(boxes,dx,dy) then
		p.x+=dx
		p.y+=dy
	end
end

--collision
function collides(boxes,dx,dy)
	px=p.x+dx
	py=p.y+dy
	--wall
	if (py<2 or py>124)	return true
	if (px<2 or px>124)	return true
	if (py+p.sy<2 or py+p.sy>124)	return true
	if (px+p.sy<2 or px+p.sx>124)	return true
	--boxes
	boxcol=false
	foreach(boxes,boxcollides)
	if (boxcol)	return true
	return false
end

--collision
function boxcollides(b)
	for sx=0,p.sx,1 do
		for sy=0,p.sy,1 do
			if (px+sx>=b.x and px+sx<=(b.x+b.sx)) then
				if (py+sy>=b.y and py+sy<=(b.y+b.sy)) then
					boxcol=true
					return
				end
			end
		end
	end
end

--occupency
function box_occupied(ex,ey)
	for b in all(boxes) do
		if ex>=b.x and ex<=(b.x+b.sx) then
			if ey>=b.y and ey<=(b.y+b.sy) then
				return true
			end
		end
	end
	return false
end

function player_occupied(ex,ey)
	if ((ex>=p.x and ex<=p.x+p.sx) and (ey>=p.y and ey<=p.y+p.sy)) then
		return true
	end
	return false
end

function occupied(ex,ey)
	if (box_occupied(ex,ey)) return true
	if (player_occupied(ex,ey)) 	return true
	if ((ex<=1 or ex>124) or (ey<=1 or ey>124)) return true
	return false
end

--pushables
function push(b)
	if not b.pushable then
		return false
	end
	--pushed right
	for i = 0, b.sy, 1 do --right box pixel
		if (dx>0 and player_occupied(b.x-1,b.y+i)) then
			should_move=true
			for k=0, b.sy, 1 do
				if occupied(b.x+b.sx+1,b.y+k) then
					should_move=false
				end
			end
			if should_move then
				b.x+=dx
			end
		end
	end
	--pushed left
	for i=0,b.sy,1 do --right box pixels
		if (dx<0 and player_occupied(b.x+b.sx+1,b.y+i)) then
			should_move=true
			for k=0, b.sy, 1 do
				if occupied(b.x-1,b.y+k) then
					should_move=false
				end
			end
			if (should_move) b.x+=dx
		end
	end
	--detect top
	for i = 0, b.sx, 1 do --box width
		if (dy>0 and player_occupied(b.x+i,b.y-1)) then
			should_move=true
			for k=0, b.sx, 1 do
				if occupied(b.x+k,b.y+b.sy+1) then
					should_move=false
				end
			end
			if (should_move) b.y+=dy
		end
	end
	--detect bottom
	for i = 0, b.sy, 1 do
		if (dy<0 and player_occupied(b.x+i,b.y+b.sy+1)) then
			should_move=true
			for k=0, b.sy, 1 do
				pset(b.x+k,b.y-1,3)
				if occupied(b.x+k,b.y-1) then
					should_move=false
				end
			end
			if (should_move) b.y+=dy
		end
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

