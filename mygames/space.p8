pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- ☉ the immortal project ☉
--   by  cameron dugan

--flags=[
-- 0=walls
-- 1=orange portal
-- 4=blue portal

--ai
bots={}

--ui
playing=true

--map
mx=0
my=0

--controlls
input_delay=10
input_buffer={}

--utils
debug=true
d={}

function _init()
	--srand(69)
	--key repeat delay
	poke(0x5f5c, input_delay)
	poke(0x5f5d, input_delay)
	--disable black transparency
	palt(0,false)
	--make pink transparent
	palt(14,true)
	
	init_tiles()
	click_txt({"welcome,","please be wary","teleporting is dangerous"})
end

function _draw()
	cls()	
	★_bg()
	map(mx,my)
	--player
	d_player()
	d_tiles()
	portal_fx(pp1.x,pp1.y,pc(0),p)
	portal_fx(pp2.x,pp2.y,pc(1),p)
	d_click_txt()
	if (debug) then
		for i in all(d) do
			print(i,8)
		end
	end
	d={}
end

function _update60()
	if (playing) then
		get_input()
		update_player()
		update_tiles()
		corrupt()
	end
end

function get_input()
	local x,y = 0,0
	if (btnp(0)) x-=1
	if (btnp(1)) x+=1
	if (btnp(2)) y-=1
	if (btnp(3)) y+=1
	for p in all(players) do
		if (abs(x)>0 or abs(y)>0) then
			if (#p.input_buffer < 2) then
				add(p.input_buffer,{x=x,y=y})
			end
		end
	end
	if (btnp(5) and dbox) then
		box_collapse=true
	end
end

function remove_from_buffer(p)
	x=p.input_buffer[1].x
	y=p.input_buffer[1].y
	del(p.input_buffer,p.input_buffer[1])
end

function init_tiles()
	for i=0,16 do
		for k=0,16 do
			set_player_start(i,k)
			set_tiles(i,k)
		end
	end
end


-->8
--pixel fx

--stars
★_l1={} --stars layer 1
★_l2={} --stars layer 2
★_l3={}
n★_l1=80 --num of stars l1
n★_l2=100 --num of stars l2
n★_l3=50
--★ offset
★o={x=1,y=1}


function ★_bg()
	if #★_l1==0 and 
					#★_l2==0 and 
					#★_l3==0 then
		init_★()
	end
	draw_★(★_l1,6)
	draw_★(★_l2,2)
	draw_★(★_l3,1)
	update_★_pos()
end

function init_★()
	★_l1={}
	★_l2={}
	★_l3={}
	★_l1=generate_★s(★_l1,n★_l1)
	★_l2=generate_★s(★_l2,n★_l2)
	★_l3=generate_★s(★_l3,n★_l3)
end

function generate_★s(arr,num)
	local x,y,n = 0,0,0
	while n<num do--screen height
		x=flr(rnd(128))
		y=(y+flr(rnd(128)))%128
		add(arr,{x=x,y=y})
		n+=1
	end
	return arr
end

function draw_★(arr,c)
	for coord in all(arr) do
		pset(coord.x,
							coord.y,c)
	end
end

function update_★_pos()
	for i=1,#★_l1 do
		★_l1[i]=move_★(★_l1[i],
																			★o,
																			1)
	end
	for i=1,#★_l2 do
		★_l2[i]=move_★(★_l2[i],
																			★o,
																			1/3)
	end
	for i=1,#★_l3 do
		★_l3[i]=move_★(★_l3[i],
																			★o,
																			1/7)
	end
end

function move_★(arr1,arr2,ratio)
	return {x=(arr1.x+ratio*arr2.x)%128,
									y=(arr1.y+ratio*arr2.y)%128}
end

--portals
function portal_fx(ax,ay,c,p)
	local speed=4
	local c2
	if (c==12) c2=13
	if (c==10) c2=9
	if (portal_activated) then
		sfx(0)
	 pfx=t()
	 portal_activated=false
	 should_pfx=true
	end
	if (should_pfx) then
		fxt=(t()-pfx)*speed
		if (fxt<1) then
		 circfill_b(ax+4,ay+4,fxt*8,c,c2)
		 hide_player=true
		elseif (fxt<2) then
			circfill_b(ax+4,ay+4,(2-fxt)*8,c,c2)
			hide_player=false
		else
			should_pfx=false
			q_corrupt(100)
		end
	end
end
-->8
--player

players={}

p_sprites={1,17}

--input x,y
x,y = 0,0

function set_player_start(i,k)
	if (mget(i,k)==1) then
		mset(i,k,9)
		add(players,new_player(i*8,k*8,0))
	end
end

function new_player(ax,ay,ad)
	return {
		x=ax,
		y=ay,
		xo=0,
		yo=0,
		can_move=true,
		move_started=nil,

		damage=ad,
		hidden=false,
		input_buffer={}
	}
end

function update_player()
	p_movement()
	for p in all(players) do
		portal_fx(p.x,p.y,12,p)
	end
end

--player_move
function p_movement()
	for i,p in pairs(players) do
		if (p.can_move) then
			--grab input from buffer
			if (#p.input_buffer>0 and not
					 collide(p,x,y))    then
					remove_from_buffer(p)
			else	
				x=0
				y=0
			end
			--move
			if (not collide(p,x,y)) then
				p_move(p,x,y)
			end
		end
		if (slerp(p)) then
			p.can_move = true
		end
	end
end

--player slerp
function slerp(p)
	local o=
					slerp_movement(p,x,
																				y,
																				input_delay)
	p.xo=o.x
	p.yo=o.y
	--teleport if landed on stuff
	if (o.done) then
		on_p_move_fin(p)
	end
		--update can_move
	return o.done
end

function on_p_move_fin(p)
	--get cur tile
	local ntile=gsifo(p,0,0)
	local pos=other_portal_pos(p,ntile)
	p.x=pos.x
	p.y=pos.y
	if (pos.moved)then
		portal_activated=true
		corrupt(0)
		take_dmg(p,1)
	end 
end

--draw player
function d_player()
	for p in all(players) do
		if (not p.hidden) then
			spr(
				p.damage+
				get_frame(p_sprites,3)
				         ,p.x+p.xo
				         ,p.y+p.yo)
		end
	end
end

--player move
function p_move(p,x,y)
	if	abs(x)>0 or abs(y)>0 then
		p.x+=8*x
		p.y+=8*y
		--direction during movement
		p.dx=x
		p.dy=y
		p.can_move=false
		p.move_started=t()	
	end
end

function take_dmg(p,dmg)
	p.damage+=dmg
	p.damage=min(p.damage,7)
end
-->8
--tiles

tiles={}
laser_sprites={34,35,36,37,38,39}
laser = {x=0,
									y=0,
								 s=34
								}

function set_tiles(i,k)
	if (mget(i,k)==39) then
		mset(i,k,9)
		add(tiles,new_laser(i*8,k*8,34))
	end
end

function update_tiles()
	for tile in all(tiles) do
		tile:update()
	end
end

function d_tiles()
	for t in all(tiles) do
		spr(t.s,t.x,t.y)
	end
end

--portal variables
pp1={x=px,y=py}
pp2={x=px,y=py}
cportal=false

--portal color
function pc(n)
	local p1c=12
	local p2c=9
	if (n==0) then
		if (cportal) then return p1c
		else return p2c end
	else
		if (cportal) then return p2c
		else return p1c end
	end
end

--get other portal pos
function other_portal_pos(p,portal)
	local op = portal
	local is_portal=false
	if (op==33) then 
		op=32
		is_portal=true
		cportal=false
	elseif (op==32) then
		op=33
		is_portal=true
		cportal=true
	end
	if (is_portal) then
		for i=mx,mx+16 do
			for k=my,my+16 do
				if (mget(i,k) == op) then
					pp1.x=i*8
					pp1.y=k*8
					pp2.x=p.x
					pp2.y=p.y
					return {x=i*8,y=k*8,moved=is_portal}
				end
			end
		end
	end
	return {x=p.x,y=p.y,moved=is_portal}
end

--laser update
function new_laser(ax,ay,as)
return{
 x=ax,
	y=ay,
	s=as,
	update=function(self)
		self.s=get_frame(laser_sprites,5)
		if (mget(ax/8,ay/8)!=9) del(tiles,self)
	end
}
end
-->8
--utils
clicked=false
cbox=true --click box
dbox=false --should draw
box_collapse=false --should bc
box_w=nil
box_h=nil
box_x=nil
box_y=nil
box_c1=0 --black
box_c2=6 --grey
box_txt={}

--enable click through text
function click_txt(txt,x,y)
	box_txt=txt
	box_w=4*l(txt)+2
	box_h=10*#txt
	--default center
	if (x==nil) x=64-box_w/2
	if (y==nil) y=64-box_h/2
	box_x=x
	box_y=y
	dbox=true
end

--draw click through text
function d_click_txt()
	if (not clicked) then
		animated_d_box(box_txt)
	end
end

cur_box_w=0
function animated_d_box(tbl)
	if (dbox) then
		draw_box(tbl,cur_box_w,box_h)
	end
	local spd=l(tbl)/6.6
	if (not box_collapse) then
		if (cur_box_w<box_w) cur_box_w+=spd
		--potentially unneccesary
		if (cur_box_w>box_w) cur_box_w=box_w
	else
		if (cur_box_w>0) then
			cur_box_w-=spd
		else
			dbox=false
		end
	end	
end

function draw_box(tbl,w,h)
	local bo=box_w/2-w/2
	rectfill(
		box_x+bo,
		box_y,
		box_x+w+bo,
		box_y+h,
		box_c1
	)
	rect(
		box_x+bo,
		box_y,
		box_x+w+bo,
		box_y+h,
		box_c2
	)
	local o=3
	for txt in all(tbl) do
		local txt_w=#txt*4
		if (txt_w+2<=w) then
			print(txt,bo+box_x+w/2-txt_w/2+1,box_y+o)
		end
		o+=10
	end
	if (cbox and box_w<=w) then
		local iconx, icony= bo+box_x+w-10,box_y+h
		rectfill(iconx-1,icony-1,iconx+7,icony+5,0)
		print("❎",iconx,icony,6)
	end
end

--longest
function l(tbl)
	len=0
	for t in all(tbl) do
		local l = #t
		if (#t>len) len=#t
	end
	return len
end

--corruption
corrupts=0
n_c=1
tic=0

function corrupt()
	tic+=1
	if (tic!=3) then
		return
	else
		tic=0
	end
	if (corrupts<=0) then
		corrupts=0
		return
	end
	corrupt_n(min(n_c,corrupts))
	corrupts-=n_c
	if (n_c<60)	n_c*=2
end

function q_corrupt(x)
	if (x!=nil) then
		corrupts+=x
		n_c=1
	end
end

--corrupt now
function corrupt_n(x)
	for i=0,x do
		repeat
			mem=rnd(0x8000)
		--make mem target only
		--visual aspects
		until --(mem>=0x6000
						--		and mem<0x7fff)
					(0x5f00<=mem 
								and mem<=0x5f1f)
					or (0x5f31<=mem 
								and mem<=0x5f35)
--sound	or (mem<=0x42ff
				--				and mem>0x30ff)
					or (mem<=0x2fff) --0x1000 not touch map
		poke(mem,rnd(0x100))
	end
end

--player collision
function collide(p,dx,dy)
	--if upcoming has solid flag
	return fget(gsifo(p,dx,dy),0)
end

--get sprite in front of player
function gsifo(p,dx,dy)
	return mget(p.x/8+dx,p.y/8+dy)
end

--generate offset
function slerp_movement(p,x,y,dur)
	local xo,yo,done = 0,0,false
	if (not p.can_move) then
		local dt = t()-p.move_started
		p.xo=-p.dx*8+8*dur*dt*p.dx
		p.yo=-p.dy*8+8*dur*dt*p.dy
		if (dt > 1/dur) then
			done=true
			p.xo=0
			p.yo=0
		end
	end
	return {x=p.xo,y=p.yo,done=done}
end

--animation
function get_frame(arr,speed)
	return arr[flr(t()*speed%#arr)+1]
end

--drawing
function circfill_b(x,y,rad,c1,c2)
	circfill(x,y,rad,c1)
	circ(x,y,rad,c2)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeee6eeeeeee66666666eeeeeee60000000000000000
00000000006666000056660000566600005655000056550000565500005655000055550000000000eeeeeeee6eeeeeeeeeeeeeeeeeeeeee60000000000000000
00700700006cc600005cc600005cc600005cc600005cc600005cc600005cc500005cc50000000000eeeeeeee6eeeeeeeeeeeeeeeeeeeeee60000000000000000
00077000006666000066660000666600006666000065650000556500005555000055550000000000eeeeeeee6eeeeeeeeeeeeeeeeeeeeee60000000000000000
00077000000650000006500000065000000650000006500000055000000550000005500000000000eeeeeeee6eeeeeeeeeeeeeeeeeeeeee60000000000000000
0070070000666600006666000066650000566500005565000055550000555500005555000000d000eeeeeeee6eeeeeeeeeeeeeeeeeeeeee60000000000000000
00000000006006000060060000600500006005000050050000500500005005000050050000000000eeeeeeee6eeeeeeeeeeeeeeeeeeeeee60000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000666666666eeeeeeeeeeeeeeeeeeeeee60000000000000000
eeeeeeee0066660000566600005666000056550000565500005655000056550000555500eeeeeeeeeeeeeeee666666666eeeeeee000000000000000000000000
eeeeeeee006cc600005cc600005cc600005cc600005cc600005cc600005cc500005cc500eeeeeeeeeeeeeeee6eeeeeee6eeeeeee000000000000000000000000
eeeeeeee0066660000666600006666000066660000656500005565000055550000555500eeeeeeeeeeeeeeee6eeeeeee6eeeeeee000000000000000000000000
eeeeeeee0006500000066000000650000006500000055000000550000005500000055000eeeeeeeeeeeeeeee6eeeeeee6eeeeeee000000000000000000000000
eeeeeeee0006500000065000000650000006500000065000000550000005500000055000eeeeeeeeeeeeeeee6eeeeeee6eeeeeee000000000000000000000000
eeeeeeee0066660000666600006665000056650000556500005555000055550000555500eeeeeeeeeeeeeeee6eeeeeee6eeeeeee000000000000000000000000
eeeeeeee0060060000600600006005000060050000500500005005000050050000500500eeeeeeeeeeeeeeee6eeeeeee6eeeeeee000000000000000000000000
eeeeeeee0000000000000000000000000000000000000000000000000000000000000000eeeeeee66eeeeeee6eeeeeee66666666000000000000000000000000
0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaeeeeeeeeeeeeeeeeee66eeeeeee0000000000000000000000000000000000000000
0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeea99aeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000
0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaeeeea9889aeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000
0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeea99aeea988889aeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000
0000000000000000eeeeeeeeeeeeeeeeeeeaaeeeeeeaaeeeea9889aea988889aeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000
0000000000000000eeeeeeeeee5555eeee5995eee5a99a5e5988889559888895eeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000
099999900cccccc0e555555ee598895ee598895ee598895ee588885ee588885eeeeeeeeeeeeeeeeeeeeeeeee0033330000000000000000000000000000000000
1111111111111111e555555ee555555ee555555ee555555ee555555ee555555eeeeeeeeeeeeeeeeeeeeeeeee0111111000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000600000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000200000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000
00000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000
00000000000000066666666666666666666666666666666660000000006000000000000000000000000000000000100000000000000010000000000000000000
00002000000000060000000000000000000000000000000060000000000000000000000000000000000000000200000006000000000000000000000000000000
00000000000000060000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000000000000060000000000000200000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000200000000000000000000
00000000000000060000d0000000d0000000d0000000d00060000000000000000020000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000000000000060000000000000000000000000000000000000600002000000000000000000000000000000000000
00000000600000060000000000000000000000000000000066666666666666666000000000200000000000000000000000000000000000002000000000000000
00000000000000060000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000600
00000000000000060000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000000000000000000000000000006000000000000000000000000000200000000000000000000000600000000001
00000000060000060000000000000000000000000000000000000000000000006000000000000600000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000200000000000000000000
00000000000000060000d0000000d0000000d0000000d0000000d0000000d0006000000000000000000000000000000000000000060000000000000000000000
00000000000000060000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000
00100000000000060000000000000000000000000000000000000000000000006600000600000000000000000000000000000000000000000000000000000000
00002000000000060000000000000000000000000000000000000000000000006000000000000000000000000000000000000000600000000000000000000000
00000000000000060000000000000000006666000000000000000000000000006000000000000000000000000000000000000000000000000020000000000000
00000000000000060000000000000000006cc6000000000000000000000000006000000000000000000000600000000000000000000000000000000000000000
00000000000000060000000000000000006666000000000000000000000000006000000000000000000000000000600000000000000000000000000000000000
00000000000000060000000000000000000650000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000
00000000000000060000d0000000d000006666000000d0000000d0000000d0006000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000000006006000000000000000000000000006000000000000000000000000000001000000000000000000000000000000000
00200000000000060000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000000000000000000000666666666000000000000000000000000000000000000000200000000000000000000000
00000000000000060000000000000000000000000000000000000000600000020000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000000000000000000000600000000000000000000000000600000006000000000000000020000000000000000000
00000000000000060000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000100
00000000000000060000d0000000d0000000d000000000000000d000600000000000000000200000000000000000000000000000000020000000000060000000
00000000000010060000000000000000000000000cccccc000000000600000000000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000001111111100000000601000060000000000000000000000000000000000000000000000020000000000000000
00000000000000060000000000000000000000000000000000000000600000000000000000010000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000000000000000000000600000000000000000000000000000000000000000006000000000000000060000060000
00000000000000060000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000
00000000000002060000000000000000000000000000000000000000600000000000002000000000000000000000000000000000000000000100000000000000
00000000000000060000d0000000d0000000d0000000d0000000d000600000000000000000000000000000000000000000000000002000000000000000000000
00000000000000060000000000000000000000000000000000000000600000000000000000000000000000000000000000000200000000000000000000000000
00000000000000060000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000002000
00000000000000060000000000000000000000006666666666666666600000000000000000200000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000006000000000000000000000000000000000000000000000000000000006000000000000000000000000000000
06000000000000060000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000060000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001000006000aa00000000000000000006000000000000000000000000000000000000000000000000000000000200000000000000000000000000000
000000000000000605a99a500000d0000000d0006000000000000000000000000000000000000000000000000000000000000000000000000000060000000000
00000000000000060598895000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000100000060555555000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000066666666666666666666666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000060000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000010000000000000002000000000000000000000000000000000000000000000000000000000002000000000000
00000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000002000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000006000000000000000000601000000000000000000000000000000000000000000000000000060000600000000000000006000000060000000000000000
00000000000000000010000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000100000000000000000000000000000006000000000060000000000000000000000000000000000000000000000000000000200000000
00000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000020000000020000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000200000000
00000000000000000000000000000000000000000200000000000000002000000000000000000000000000000000000000000600000000000000000000000000
00000016000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000020000000000000000000000000000000020000000000000000006000000000000000000000000000000000000000020000000000000000000000000
00000000000000000000006000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000026000000006
00000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000
00000000000000000000000200000000000000002000000000000000000000000000000000000000000000000000001000000000000000000000000000000000
00002000000010000000000000000000000010000000000000000000000000000000000666666666666666666666666666666666600006000000000600000000
00000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000600000000000000000000000
00200000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000600000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000600000000002000000000000
00000000000000000000000000000000000000000000000000000100000000000000000600000000000000000000000000000000600001000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000600200000000000000000000
0000000000000000000000000000000000002000000000000000000000000000000000060000d0000000d0000000d0000000d000600000000000000000000000
00000000000000000000000200000000000000000000000000000000000000000000000600000000000000000000000000000000600000000000000000000000
00000000000001000000000006000000000000000000000002200000000000000000000600000000000000000000000000000000666666666000000000000000
00000000000000000000000000000002000000000000000000000000020000000000000600000000000000000000000000000000000000006020000000000000
00000000000000000000000000000000000006000000000000000000000000000000000600000000000000000000000000000000000000006000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000006000000000000000
00000000000000000000000000000000000000000002100000000000000000000000000600000000000000000000000000000000000000006000000000000000
00000000000000000000000000000000200000000000000000000000000000000000000600000000000000000000000000000000000000006000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000060000d0000000d0000000d0000000d0000000d0006000000000000000
00000000000000000000000000000000000000000000000020000000000000000000000600000000000000000000000000000000000000006000000000000000
00000000000000000220000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000006000600000000000
00000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000006006000000000000
00000000000000000000000000000000000060000000000000000000000000000000000600000000000000000000000000000000000000006000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000006010000000000000
00000000000000000600000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000006000000000000000
00000000000001000000000000000000000000000000000000000000000600000000000600000000000000000000000000000000000000006000000000000000
0000000000000000000000000000000000000000000000600000000000000000000000060000d0000000d0000000d0000000d0000000d0006000000000000000
00000000000000000000000000000000000000000000000002000000000000000100000600000000000000000000000000000000000000006000000001000000
00000000000006000000000000000000000000000000000000000000100000000000000600000000000000000000000000000000000000006000000000000000
00000000000000000000000100000000000000000000000000000000000000000000000600000000000000000000000000000000000000006000000000000000
00000002000000000000000000000000000000000000000000000000002000000000000600000000000000000000000000000000000000006000000000000000
00000002000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000006000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000006000000000000000
00002000000000000000060000000000000000000000000000020000000000000000000600000000000000000000000000000000000000006000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000060000d000000000000000d0000000d0000000d0006000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000600000000099999900000000000000000000000006000000000000000
00000000000000000000000000000000000000000000000000000000000002000000000600000000111111110000000000000000000000006000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000666666666000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000600000000000000000000000
00000000006000000000000000000000000000000000000000002000000000000000000600000000000000000000000000000000600000000000000000000000
00000060000000000000000000000000600000000000000000000000000000000000000600000000000000000000000000000000600000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000aa000600200000000000000000000
0000000000000000000002000000000000000000000000000000000000000000000020060000d0000000d0000000d00005a99a50600000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000100000600000000000000000000000005988950600000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000005555550600000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000666666666666666666666666666666666600000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000100000000000000000000
00000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000206000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000001010101000000000000000000000001010101000000021000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
10190a0a0a0a1a10101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
100d090909091c0a1a1010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
100d0901090909090b1010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
100d090901092b090b1010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
100d09090921091b2a1010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
100d09090909090b101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
100d2709091b0c2a101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10290c0c0c2a1010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010190a0a0a0a1a101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010100d090909091c1a1010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010100d09090909090b1010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010100d090909092b0b1010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010100d09200909090b1010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010100d090909271b2a1010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010290c0c0c0c2a101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
510100000e0560e0560d0560d0560c0560c0560c0560c0560c0560c0560b0560b0560b0560c0560d0060e0060f006110061200613006160061800615006120060e0060a006010060000600006000060000600006
62100000165551b5550050521555005052655500505295550050500505295550050526555005052255515555135551455500505185551c5552055500505225550050500505005050050500505005050050500505
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e00000910509105061050910509105001050910509105061050910509105001050910509105001050710507105001050710507105071050710507105001050710507105001050710507105001050010500105
000e0000151020010215102001021510213102021020010211102001020f1021010200102101021110200102121021310200102121021110200102001021010200102001020f1020f1020f1020f1020010200102
000e00000010300103001030010300103001030010300103001030010300103091030910309103091030710307103071030710307103071030710307103071030710307103071030710307103071030710307103
000e0000001050010500105001050e105001050e1050e105061050e1050e105001050e1050e105001050c1050c105001050c1050c105071050c1050c105001050c1050c105001050710507105001050710507105
000e000015102001021a102001021510218102021020010216102001020f102151020010215102161021510215102181020010212102161020010200102151020010200102131021310213102131020010200102
000e00000e1030e1030e1030e1030e1030e1030e1030e1030e1030e1030e1030e1030e1030e1030e1030e1030c1030c1030c1030c1030c1030c1030c1030c1030c1030c1030c1030c1030c1030c1030c1030c103
__music__
03 01555644
00 54555644
00 58595744

