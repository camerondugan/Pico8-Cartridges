pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- ◆ portals in space ◆
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
	
	get_player_start()
end

function _draw()
	cls()	
	★_bg()
	map(mx,my)
	--player
	d_player()
	portal_fx(pp1.x,pp1.y,pc(0))
	portal_fx(pp2.x,pp2.y,pc(1))
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
		corrupt()
	end
end

function get_input()
	local x,y = 0,0
	if (btnp(0)) x-=1
	if (btnp(1)) x+=1
	if (btnp(2)) y-=1
	if (btnp(3)) y+=1
	if (abs(x)>0 or abs(y)>0) then
		if (#input_buffer < 2) then
			add(input_buffer,{x=x,y=y})
		end
	end
end

function remove_from_buffer()
	x=input_buffer[1].x
	y=input_buffer[1].y
	del(input_buffer,input_buffer[1])
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
function portal_fx(x,y,c)
	local speed=4
	local c2
	if (c==12) c2=13
	if (c==10) c2=9
	if (portal_activated) then
	 pfx=t()
	 portal_activated=false
	 should_pfx=true
	end
	if (should_pfx) then
		fxt=(t()-pfx)*speed
		if (fxt<1) then
		 circfill_b(x+4,y+4,fxt*8,c,c2)
		 hide_player=true
		elseif (fxt<2) then
			circfill_b(x+4,y+4,(2-fxt)*8,c,c2)
			hide_player=false
		else
			should_pfx=false
			q_corrupt(100)
			take_dmg(1)
		end
	end
end
-->8
--player
px=0
py=0
pxo=0
pyo=0
p_can_move=true
p_move_started=nil

p_sprites={1,17}
p_damage=0
hide_player=false

function get_player_start()
	for i=0,16 do
		for k=0,16 do
			if (mget(i,k)==1) then
				mset(i,k,9)
				px=i*8
				py=k*8
			end
		end
	end
end

function update_player()
	p_movement()
	portal_fx(px,py,12)
	if (p_slerp()) then
		p_can_move=true
	end
end

--player_move
function p_movement()
	if (p_can_move) then
		--grab input from buffer
		if (#input_buffer>0 and not
				 collide(x,y))    then
			remove_from_buffer()
		else	
			x=0
			y=0
		end
		--move
		if (not collide(x,y)) then
			p_move(x,y)
		end
	end
end

--player slerp
function p_slerp()
	local o=
					slerp_movement(x,
																				y,
																				pdx,
																				pdy,
																				input_delay)
	pxo=o.x
	pyo=o.y
	--teleport if landed on stuff
	if (o.done) then
		on_p_move_fin()
	end
		--update can_move
	return o.done
end

function on_p_move_fin()
	--get cur tile
	local ntile=gsifo(0,0)
	local pos=other_portal_pos(ntile)
	px=pos.x
	py=pos.y
	if (pos.moved)then
		portal_activated=true
		corrupt(0)
	end 
end

--draw player
function d_player()
	if (not hide_player) then
		spr(
			p_damage+
			get_frame(p_sprites,3)
			,px+pxo
			,py+pyo)
	end
end

--player move
function p_move(x,y)
	if	abs(x)>0 or abs(y)>0 then
		px+=8*x
		py+=8*y
		--direction during movement
		pdx=x
		pdy=y
		p_can_move=false
		p_move_started=t()	
	end
end

function take_dmg(dmg)
	p_damage+=dmg
	p_damage=min(p_damage,7)
end
-->8
--game tiles

--portal variables
pp1={x=px,y=py}
pp2={x=px,y=py}
cportal=false

--portal
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

function other_portal_pos(portal)
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
					pp2.x=px
					pp2.y=py
					return {x=i*8,y=k*8,moved=is_portal}
				end
			end
		end
	end
	return {x=px,y=py,moved=is_portal}
end
-->8
--utils
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
					or (mem<=0x42ff
								and mem>0x30ff)
					or (mem<0x1000)
		poke(mem,rnd(0x100))
	end
end

function collide(dx,dy)
	--if upcoming has solid flag
	return fget(gsifo(dx,dy),0)
end

--get sprite in front of player
function gsifo(dx,dy)
	return mget(px/8+dx,py/8+dy)
end

--generate offset
function slerp_movement(x,y,dx,dy,dur)
	local xo,yo,done = 0,0,false
	if (not p_can_move) then
		local dt = t()-p_move_started
		xo=-dx*8+8*dur*dt*dx
		yo=-dy*8+8*dur*dt*dy
		if (dt > 1/dur) then
			done=true
			xo=0
			yo=0
		end
	end
	return {x=xo,y=yo,done=done}
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000066666666000000060000000000000000
00000000006666000056660000566600005655000056550000565500005655000055550000000000000000006000000000000000000000060000000000000000
00700700006cc600005cc600005cc600005cc600005cc600005cc600005cc5000058850000000000000000006000000000000000000000060000000000000000
00077000006666000066660000666600006666000065650000556500005555000055550000000000000000006000000000000000000000060000000000000000
00077000000650000006500000065000000650000006500000055000000550000005500000000000000000006000000000000000000000060000000000000000
0070070000666600006666000066650000566500005565000055550000555500005555000000d000000000006000000000000000000000060000000000000000
00000000006006000060060000600500006005000050050000500500005005000050050000000000000000006000000000000000000000060000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000666666666000000000000000000000060000000000000000
00000000006666000056660000566600005655000056550000565500005655000055550000000000000000006666666660000000000000000000000000000000
00000000006cc600005cc600005cc600005cc600005cc600005cc600005cc5000058850000000000000000006000000060000000000000000000000000000000
00000000006666000066660000666600006666000065650000556500005555000055550000000000000000006000000060000000000000000000000000000000
00000000000650000006600000065000000650000005500000055000000550000005500000000000000000006000000060000000000000000000000000000000
00000000000650000006500000065000000650000006500000055000000550000005500000000000000000006000000060000000000000000000000000000000
00000000006666000066660000666500005665000055650000555500005555000055550000000000000000006000000060000000000000000000000000000000
00000000006006000060060000600500006005000050050000500500005005000050050000000000000000006000000060000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000006600000006000000066666666000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000006600000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
099999900cccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
mmmmmmmmmmmcmmm7mmmbmm5m4mmmmm5mmmmmmm5mmmmmmm5mmm7fmmmfmmmmmmmm4mmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmbmmmmmmmmmm
mmmmmmmmmimmm5mmmmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmfmmmmm5mmm4mmm5mmmmmmm5mmmmmmm5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
4mmmmmmmmmmmmf4mmm4fmmmmmm4fmmmmmm4fmmmmmm4fmmmmmmmmmmmfmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmm
mmmmmmmmmmmm7cmmmcmmmmmmmcmmmmmmmcmmmmmmmcmmmmmmmm5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmccmmmmmmmmmmmimmmmmmmmmmmmmm4mmmmmmm4mmmm5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmm
mmmmmmmm5mmmmmmmmmmmm7mmmmmmm7mmmmmmm7mmmmmmm7mm4fmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmm4fmmmmmmimmmmmmmmmmmmmmmmmmmmmmmmmbmm7mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmm
mmmmmmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmm7mmmmfmmmmmmm5mmm7fmmmfmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm57fm7f7mmfm5mc7mmfm5mc7mmfm5mc7mmfm5mcmmm47mmmmmmmmm5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmm54mmmmmf5mmmmmmf5mmmmmmf5mmmmmmf5m4mmmmmmmmmm5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm7mfmmmmmfmfmmmmmfmfmmmmmfmfmmmmmfmfmmmmmmmmcmmmm4fmmmmmmmmmmmfmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmm
mmmmmmmm55mfmmmmmmmfmmm7mmmfmmm7mmmfmmm7mmmfmmm7mmmfmm4fmcmmmmmmmm5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmm5m5mmffmmm5mmmm7mm5mmmm7mm5mmmm7mm5mmmm7mmmmc7mmmmmmmmmm4mmmm5mmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmfmmmmmm54f4mmmmm4f4mmmmm4f4mmmmm4f4mmm4mmmmmmmmmmmmmm7mm4fmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmcmmm5cmm5f7mm77m5f7mm77m5f7mm77m5f7mm77mmmfmm5mmmmmmmmmm7mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm5mmmmmmm5mmmmmmm5mmmbmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmmmmmm4mbmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm57fm7f7mmfm5mc7mmfm5mc7mmfm5mc7mmfm5mc7mmfm5mc7mmfm5mcmmmffmmcmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmm
mmmmmmmmmmmmmm54mmmmmf5mmmmmmf5mmmmmbf5mmmmmmf5mmmmmmf5mmmmmmf5mmc4m4m4mmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm7mfmmmmmfmfmmmmmfmfmmmmmfmfmmmmmfifmmmmmfmfmmmmmfmfmmmcmmmcmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmm55mfmmmmmmmfmmm7mmmfmmb7mmbfmmm7mmbfmmm7mmmfmmm7mmmfmbb7mbmbmm4mmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmm5m5mmffmmm5mmmm7mm5mmmm7mm5mmmm7mm5mmmm7mm5mmmm7mm5mmmm7mmm7mfmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmfmmmmmm54f4mmmmm4f4mmmmm4f4mmbmm4f4mmmmm4f4mmmmm4f4mmmmmmmmmmmmcmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmcmmm5cm45f7mm77m5f7mm77m5f7mm77m5f7mm77m5f7mm77m5f7mm77fm77m5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmmc5fmmmmmm5mmmmmmmmmm4mmmmmmmmmmmmmmimmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm57fm7f7mmfm5mc7mmfm5mc74mfm5mc7mmfm5mc7m55m5m57mmfm5mcmmmffmmcmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmb
mmmmmmmmmmmmmm54mmmmmf5mmmmmmf5mmmmmmf5mmmmmmf5mm45mmf5mmmmmmf5mmc4m4m4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm7mfmmmmmfmfmmmmmfifmmmmmfmfmmimmfmfmmmmmfmffmmmmfmfmmmcmmmcmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmm55mfmmmmmmmfmmm7mmmfmmm7mmmfmbm7mmmfmmm7mmmf5mm7mmmfmmm7mmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmm5m5bmffmmm5mmmm7mm5mmmm7mm5mmmm7mm5mmmm7cm5m55m7mm5mmmm7mmm7mfmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmfmmmmmm54f4mmmmm4f4mmmmm4f4mmmmm4f4mmmmm4f44m54c4f4mbmmmmmmmmmmcmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmcmmm5cmm5f7mm77m5f7mm77m5f7mm77m5f7mm77m5fcmmf7m5f7mm77fm77m5bmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm5mmmmmmm5mmmmmmb5mmmmmmm5mmmmmc7mmmmffmm5mmmmm7mmmmmm7m47m4mmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm57fm7f7mmfm5mc7mmfm5mc7mmfm5mcmmmmmmmm7mifm5mcfmmm7mmmmcm4m4mmmmmbmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmimmm54mmmmmf5mmmmmmf5mmmmmmf5mmmmmmmmmmmmmmf5mmmmm7mm7mmm4cmmmmmmmmmmmmmmmmmmmmbmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm7mfmmmmmfmfmmmmmfmfmmmmmfmfmmmm4mcmmmmmmfmfmmmmmmmmmmmmm5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmm55mfmmmmmmmfmmm7mmmfmmm7mmmfmmm7mmmmmmmmmmmfmmm7mmmfmmmmmmm5mmmfmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmm
mmmmmmmm5m5mmffmmm5mmmm7mm5mmmm7mm5mmmm7mmmmmmmmmm5mmmm7m4fmmmmmmmcmmm7mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmfmmmmmm54f4mmmmm4f4mmmim4f4mmmmmmmf4cmcm4f4mmmmmmmfmmmmmmmmmmmm5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmcmmm5cm45f7mm77m5f7mm77m5f7mm77mmbm44m7m5f7mm77mmmmmf5mmmmm7m4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmm
mmmmmmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm57fm7f7mmfm5mc7mmfm5mc7mmfi5mc7mmfm5mc7mmfm5mcmmmffmmcmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmbmmmmmmmmm54mmmmmf5mmmmmmf5mmmmmmf5mmmmmmf5mmmmmmf5mmc4m4m4mmmmmmmmimmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm7mfmmmmmfmfmmmmmfmfmmmmmfmfmmmmmfmfmmmmmfmfmmmcmmmcmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmm4mmmmmmmmmmmmmmmmmmmm
mmmmmmmm55mfmmmmmmmfmmm7mmmfmmm7mmmfmbm7mmmfmmm7mmmfmmm7mmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmbmmmmmmmmm4mmmmmmbmmmm
mmmmmmmm5m5mmffmmm5mmmm7mm5mmmm7mm5mmmm7mm5mmmm7mm5mmmm7mmm7mfmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmm
mm4mmmmmfmmmmmm54f4mmmmm4f4mmmmm4f4mbmmm4f4mmmmm4f4mmmmmmmmmbmmcmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmcmmm5cmm5f7mm77m5f7mm77m5f7mm77m5f7mm77m5f7mm77fm77m5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmm7mmmmmm7mmmm4mm7i47m4mmmmmmmmmmmmmmmmmmmmmmmmmmm4bmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm57fm7f7mmfm5mc7mmfm5mc7mmfm5mcfmmm7mmm57mm5mmmmcm4m4mmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmm54mmmmmf5mmmmmmf5mmmmmbf5mmmmm7mm77m7m55mmmmm4cmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmm7mfmmmmmfmfmmmmmfmfmmmmmfmfmmmmmmmmmmm4mmcmbmmmm5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmm55mfmmmm4mmfmmm7mmmf4mm7mmmfmmm7mmmfmmmmmmmm4m4mmmm5mmmfmmmmmmmm4mmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmm5i5mmffmmm5mmmm7mm5mmmm7mm5mmmm7m4fmmmmmmmmmmmm4mmcmmm7mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmm4mmmmmmmmmmm
mmmmmmmmfmmmmmm54f4mmmmm4f4mmmmm4f4mmmmmmmfmmmmmm4mm7mmmmmmmmmm5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmcmmm5cmm5f7mm77m5f7mm77m5f7mm77mmmmmf5mffmm4mmmmmmm7m4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmm4mmmmmmmm4mm7mmmm4mm7mmmm4mm7m47m4mmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmimmmmmmmmmmmmm57mm5mmm57mm5mmm57mm5mmmmcm4m4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmm
mmmmmmmmfmmm5mmm7m7m55mm7m7m55mm7m7m55mmmmm4cmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
4mmmmmmmmmmmmmfmmmmcmmmmmmmcmmmmmmmcmmmmmm5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmcfmmmcmmmmmmm4mmmmmmm4mmmmmmm4mmmm5mmmfmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmm5mmmm4mmmmmmmmm4mmmmmmm4mmmmmmm4mmcmmm7mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmifmmmmmf7m4mm7mmmm4mm7mmmm4mm7mmmmmmmmmm5mmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmimmmmmmmmm
mmmm4mmmmccm4mmmffmm4mmmffmm4mmmffmm4mmmmbmm7m4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmimm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmimmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmcmmm7mmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmm7fmmmfmmmmmmmmmmmmmmmm
mmmmmmmmmimmmmmmmmmmmmmmmmmmmmmmmmmmmmmmimmmmmmmmmmmmmmmmmmmmmmmmmmmm5mmmmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmfmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmm4mbmmmmmmmmmmmmmmmmmmmf4mmm4fmmmmmm4fmmmmmm4fmmmmmm4fmmmm4mmmmmmfmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm7cmmmcmmmmmmmcmmmmmmmcmmmmmmmcmmmmmmmm5mmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmccmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmm5mmmmmmmmmmmmmmmm4m
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm5mmmmmmmmmmmm7mmmmmmm7mmmmmmb7mmmmmmm7mm4fmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4fmmmmmmmmmmmmmmmmmmimmmmmmmmmmmmmmmm7mmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmm7mmmmfmmm7fmmmfmmmmmmmm
mmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmimmmmmmmmmmmmmmmmmmmmmmmmm57fm7f7mmfm5mc7mmfm5mc7m4fm5mc7mmfm5mcmmm47mmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm54mmmmmf5mmmmmmf5mmmmmmf5mmmmmmf5m4mmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmm7mfmmmmmfmfmmmmmfmfmmmmmfmfmmmmmfmfmmmmmmmmcmmmmmmmmbfmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm55mfmmmmmmmfmmm7mmmfmmm7mmmfmmm74mbfmmm7mmmfmm4fmm5mmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm5m5mmffmmm5mmmm7im5mmmm7mm5mmmm7mm5mmmm7mmmmc7mm4mmmm5mmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmfmmmmmm54f4mmmmm4f4mmmmm4f4mmmmm4f4mmmmmmmmmmmmm4fmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmcmmm5cmm5f7mm77m5f7mm77m5f7mm77m5f7mm77mmmfmm5mm7mmmmmmmmbmmmmm
mmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmbmmmbmmmmmmmmimmmmmmmmmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mmmmmmmmmm4mmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmimmmmmmmmmmmmmmmmbmmmmmmmmmmmmmm57fm7f7mmfm5mc7mmfm5mc7mmfm5mc7mmfm5mc7mmfm5mcmmmffmmcmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmm4mm54mmmmmf5mmmmmmf5mmmmmmf5mmmmmmf5mmmmmmf5mmc4m4m4mmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm7mfmmmmmfmfmmmmmfmfmmmmmfmfmmmmmfmfmmmmmfmfmmmcmmmcmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm55mfmmmmmmmfmmm7mmmfmmm7mmmfmmm7mmmfmmm7mmmfmmm7mmmmmm4mmmmmmmmm
mmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm5m5mmffmmm5mmmm7mm5mmmm7mm5mmmm7mm5mmmm7mm5mmmm7mmm7mfmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmfmmmmmm54f4mmmmm4f4mmmmm4f4mmmmm4f4mmmmm4f4mmmmmmmmmmmmcmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmm4mbmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmcmmm5cmm5f7mm77m5f7mm77m5f7mm77m5f7mm77m5f7mm77fm77m5mmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm5mmmmmmm5mmmmmmm5mmmbmmm5mmmmmim5mmmmmmb5mmmmmmmmmm4mmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm57fm7f7mmfm5mc7mmfm5mc7mmfm5mc7mmfm5mc7mmfm5mcmmmffmmcmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm54mmmmmf5mmmmmmf5mmmmmmf5mmmmmmf5mmmmmmf5mmc4m4m4mmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmbmmmmmmmmmmmmmmbmmmmmmmmmmmm7mfmmmmmfmfmmmmmfmfmmmmmfmfmmmmmf4fmmmmmfmfmmmcmmmcmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm55mfmmmmmmmfmmm7mmmfmmm7mmmfmmm7mmmfmmm7mmmfmmm7mmmmmm4mmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm5m5mmffmmm5mmmm7mm5mmmm7mm5mmmm7mm5mmmm7mm5mmmm7mmm7mfmmmmmmmmmm
mmmmmmimmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmfmmmmmm54f4mmmmm4f4mmmmm4f4mmmmm4f4mmmmm4f4mmmmmmmmmmmmcmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmcmmm5cmm5f7mm77m5f7mm77m5f7mm77m5f7mm77m5f7mm77fm77m5mmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmimmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4m5mmmmmmm5mmmmmmmmmmmmmmm5mmmmmmm5mmmmmmm5mmmmmmmmmm4mmmmmmmmmm
mmmmmmmmmmmmmmmbmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm57fm7f7mmfm5mcmmm5mm7m7mmfm5mc7mmfm5mc7mmfm5mcmmmffmmcmmmmmmmm
mmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmimmmmmmmmmmmmmmmmmmmmmmmmmmm54mmmmmf5mmmm4mmmmmmmmmf5mmmmmmf5mmmmmmf5mmc4m4m4mmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm7mfmmmmmfmfmmmmmmmmmmmmmfmfmmmmmfmfmmimmfmfmmmcmmmcmmmmmmmmmmm
immmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmbmmmmmmmmmmmm55mfmmmmmmmfmmm77mmm4mmmmmmfmmm7mmmfmmm7mmmfmmm7mmmmmm4mmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmimmmmmmmmmmmmmmmmmmmmmmmmmm5m5mmffmmm5mmmm7mcmfm5m7mm5mmmm7mm5mmmm7mm5mmmm7mmm7mfmmmmmmmmmm
mmmmmmmmmbmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmfmmmmmm54f4mmmmm7cmmmm4m4f4mmmmm4f4mmmmm4f4mmmmmmmmmmmmcmmmmmmmm
mmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmcmmm5cmm5f7mm77fmmmfcmcm5f7mm77m5f7mm77m5f7mm77fm77m5mmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm5mmmmmmm5mmmmmmm5mmmmmim5mmmmmmm5mmmmm7mmmmmm7m47m4mmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm57fm7f7mmfm5mc7mmfm5mc7mmfm5mc7mmfm5mcfmmm74mmmcm4m4mmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmimm4mmmmmmmmmmmmmmmmmmm54bmmmmf5mmmmimf5immmmmf5mmmmmmf5mmmmm7mm7mmm4cmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm7mfmmmmmfmfmmmmmfmfmmmmmfmfmmmmmfmfmmmmmmmmmmmmm5mmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmm55mfmmmmmmmfmmm7mmmfmmm7mmmfmmm7mmmfmmm7mmmfmmmmmmm5mmmfmmmmmmmm
mmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm5m5mmffmmm5mmmm7mm5mmmm7mm5mmmm7mm5mmmm7m4fmmmmmmmcmmm7mmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmfmmmmmm54f4mmmmm4f4mmmmm4f4mmmmm4f4mmmmmmmfmmmmmmmmmmmm5mmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmimmmmmmmmmmmmmmmmmmmmmcmmm5cmm5f7mm77m5f7mm77m5f7mm77m5f7mm77mmmmmf5mmmmm7m4mmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmm4mmmmmmmm4mm7mmmm4mm7mmmm4mm7mmmm4mm7m47m4mmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmmm57mm5mmm57mm5mmm57mm5mmm57mm5mmmmcm4m4mmmmmmmmmmmmmbmmmm
mmmmmmmmmmmmmmmimmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmfmmm5mmm7m7m55mm7m7m55mm7m7455mm7m7m55mmmmm4cmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmfmmmmc4mmmmmmcmmmmmmmcmmmmmmmcmmmmmm5mmmmmmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm4mmmmmmmmmmmmcfmmmcmmmmmmm4mmmmmmm4mmmmmmm4mmmmmmm4mmmm5mmmfmmmmmmmmmmmmmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmm5mmmm4mmmmmmmmm4mmmmmmm4mmmmmmm4mmmmmmm4mmcmmm7mmmmmmmmmmm4mmmmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmfmmmmmf7m4mm7mmmm4mm7mmmm4mm7mmmm4mm7mmmmmmmmmm5mmmmmm4mmmmmmmmm
mmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmmmmmmmmmmmmmmmmmmmmccm4mmmffmm4mmmffmm4mmmffmm4mmmffmm4mmmmmmm7m4mmmmmmmmmmmmmmmmm

__gff__
0000000000000000000001010101000000000000000000000001010101000000021000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
00190a0a0a0a1a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d090909091c0a1a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d0909090909090b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d0909010909090b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d09090921091b2a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d09090909090b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d0909091b0c2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00290c0c0c2a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000190a0a0a0a1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000d090909091c1a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000d09090909090b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000d09090909090b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000d09200909090b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000d090909091b2a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000290c0c0c0c2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
c60600000702013000140001600017000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
