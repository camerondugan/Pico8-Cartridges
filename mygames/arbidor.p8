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
paused=false

--map
mx=0
my=0

--controlls
input_delay=6
input_buffer={}

--utils
debug=true
d={}

--game essentials
levels={1,2,3,5,4,6,7,8,9,10,11,12}
this_lvl=1
doom=100
doom_i=doom

function new_defaults()
	--key repeat delay
	poke(0x5f5c, input_delay)
	poke(0x5f5d, input_delay)
	--disable black transparency
	palt(0,false)
	--make pink transparent
	palt(14,true)
	if (this_lvl<=3 and not has_spoken) then
		dark_filter()
	end
end

function _init()
	music(0)
	--srand(69)
	new_defaults()
	init_map()
	init_tiles()
	init_npcs()
	play_welcome_txt()
	jp=false
end

function _draw()
	if (playing) then
		cls()	
		★_bg()
		map(mx,my)
		d_tiles()
		--player
		d_player()
		d_npcs()
		d_tile_effects()
		portal_fx(pp1.x,pp1.y,pc(0),p)
		portal_fx(pp2.x,pp2.y,pc(1),p)
		if (dbox and bbg) cls()
		d_ui()
		d_click_txt()
		if (lvl_t) d_transitions()
		if (#players==0) load_lvl()
		if (doom<=0) then
			load_lvl(1)
			doom=doom_i
		end
	end
	--game over
	if(not playing and jp) then
		reload()
		click_txt({"you can no longer move","want to restart?","press ctrl and r","at the same time.","it works at all times"},false)
	end
	jp=playing
	--debugging
	if (debug) then
		for i in all(d) do
			print(i,8)
		end
	end
	d={}
end

function update_tiles()
	for t in all(tiles) do
		if (t.update != nil) t:update()
	end
end

function _update60()
 if (playing) then
		get_input()
	 manage_q() --text queue
	 --level finished
	 check_finished()
	 system_reset()
	 corrupt()
	end
	if (playing and not paused) then
		update_player()
		update_tiles()
		u_npcs()
		doom-=0.01
	end	
	pause_during_txt()
end

function get_input()
	local x,y = 0,0
	if (not paused) then
		if (btnp(0)) x-=1
		if (btnp(1)) x+=1
		if (btnp(2)) y-=1
		if (btnp(3)) y+=1
		if (btnp(4)or btnp(5)) load_lvl()
	end
	for p in all(players) do
		if (abs(x)>0 or abs(y)>0) then
			if (#p.input_buffer < 2) then
				add(p.input_buffer,{x=x,y=y})
			end
		end
	end
	if (btnp(5) or btnp(4) and box_i) then
		box_collapse=true
	end
end

function remove_from_buffer(p)
	x=p.input_buffer[1].x
	y=p.input_buffer[1].y
	del(p.input_buffer,p.input_buffer[1])
end

function init_tiles()
	for i=mx,15+mx do
		for k=my,15+my do
			set_player_start(i,k)
			set_tiles(i,k)
		end
	end
end

lvl_tt=0--lvl transition timer
lvl_t=false
lvl_td=0.3
function load_next_lvl()
	--timer
	if not lvl_t then
		if lvl_tt==0 then
			lvl_tt=t()
			lvl_t=true
		end
	end
	local timer=t()-lvl_tt
	--animation
	if (timer<lvl_td) then
		line_fade()
	end
	--game_logic
	if (timer<lvl_td/4) then
		for p in all(players) do
			p.can_move=false
		end
	elseif (timer<lvl_td) then
		paused=true
	else
--lvl shift
		load_lvl(this_lvl+1)
		reset_offset=t()%reset_time
		paused=false
		lvl_t=false
		lvl_tt=0
		if (#players==0) then
			reload()
			init_tiles()
		end
		play_welcome_txt()
	end
end

function load_lvl(num)
	if (num != nil) then
		this_lvl=num
	else
		bat_warn=true
		doom-=20
	end
	on_lvl_end()
	init_map()
	players={}
	tiles={}
	npcs={}
	p_start_pos={}
	init_tiles()		
	init_npcs()
	init_★()
end

function on_lvl_end()
	if (has_spoken) has_spoken=false
end
-->8
--pixel fx

mono_color=true
shift_filter=true

--filters

function mono_pxl(x,y)
	local p = pget(x,y)
	if (p==0 or p==14) then
		pset(x,y,0)
	else
		pset(x,y,7)
	end
end

function dark_pxl(x,y)
	local p = pget(x,y)
	if(p==0 or p==14) then
		pset(x,y,0)
	elseif(p>5 and p<7) then
		pset(x,y,6)
	else
		pset(x,y,5)
	end
end

function dark_filter()
	for p=0,15 do
		if(p==0 or p==14) then
			pal(p,0) --floor
		elseif(p>5 and p<7) then
			pal(p,13) --body
		elseif(p>8 and p<13) then
			pal(p,2) --highlights
		else
			pal(p,1) --shadows
		end
	end
end

function mono_filter()
	for p=0,15 do
		if (p==0 or p==14) then
			pal(p,0)
		else
			pal(p,6)
		end
	end
end

function no_filter()
	for p=0,15 do
		pal(p,p)
	end
end

last_pxl=0
last_pxl2=0
function shift_pxl(x,y)
	local p = pget(x,y)
	pset(x,y,last_pxl2)
	last_pxl2=last_pxl
	last_pxl=p
end

function fun_mirror(x,y,bm)
	local t,b,a,cx,cy,dx,dy = true,0,1,x,y,-1,-1
	while (b<bm) do
		--add to distance
		if (b%2==0) a+=1
		--update instance
		t=not t
		if (t) dx*=-1
		if (not t) dy*=-1
		for i=0,a-2 do
			--update position
			if (t) cx+=dx
			if (not t) cy+=dy
			shift_pxl(cx,cy)
		end
		b+=1
	end
end

function static(ax,ay,w,h,c)
	for i=1,c do
		shift_pxl(rnd(w)+ax,rnd(h)+ay)
	end
end

--stars
★_l1={} --stars layer 1
★_l2={} --stars layer 2
★_l3={}
n★_l1=40 --num of stars l1
n★_l2=50 --num of stars l2
n★_l3=25
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
	★o={x=rnd(2)-1,y=rnd(2)-1}
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
		sfx(0,0)
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
		end
	end
end

--transitions
function d_transitions()
	line_fade()
end

function line_fade()
	local timer=(t()-lvl_tt)
	for i=0,128 do
		for k=0,128,1+lvl_td-timer do
			if (k%5!=0) then
		 	pset(i,k,0)
			else
				dark_pxl(i,k)
			end
		end
	end
end

-->8
--player
players={}
p_start_pos={}
p_sprites={1,17}

--input x,y
x,y = 0,0

function set_player_start(i,k)
	local d=mget(i,k)
	local e=false
	local ax,ay=i*8,k*8
	for s in all(p_start_pos) do
		if (ax==s.x and ay==s.y) then
			return
		end
	end
	if (d>=1 and d<=8) then
		e=true
		add(players,new_player((i-mx)*8,(k-my)*8,d-1))
	elseif (d>=17 and d<=24) then
		e=true
		add(players,new_player((i-mx)*8,(k-my)*8,d-17))
	end
	if (e) then
		add(tiles,new_flr_tile(ax,ay))
		add(p_start_pos,{x=ax,y=ay})
	end
end

function new_player(ax,ay,ad)
	return {
		x=ax,
		y=ay,
		xo=0,
		yo=0,
		di=8,
		can_move=true,
		move_started=nil,
		damage=ad,
		hidden=false,
		input_buffer={},
		type="player",
	}
end

function update_player()
	for p in all(players) do
		portal_fx(p.x,p.y,12,p)
	end
	combine_players()
	p_movement()
end

function combine_players()
	for i,p1 in pairs(players) do
		for k,p2 in pairs(players) do
			if (i!=k) then
				
				if (p1.x==p2.x and p1.y==p2.y) then
					p3=new_player(p1.x,
																			p1.y,
max(0,min(p1.damage,p2.damage)-(8-max(p1.damage,p2.damage))))
					del(players,p1)
					del(players,p2)
					add(players,p3)
				end
			end		
		end
	end
end

function p_movement()
	for i,p in pairs(players) do
		local should_slerp = true
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
				if(abs(x)+abs(y)>0)	sfx(6,0)
				p.di=p_move(p,x,y)
			else
				p.di=bump(p,x,y)
				on_p_col(p)
			end
		end
		if(should_slerp) then
			if(slerp(p)) p.can_move=true
		end
		--die if necessary
		if (p.damage>7) del(players,p)
	end
end

function on_p_col(p)
	local npc = is_npc(p.x+x*8,p.y+y*8)
	if(npc!=nil) then
		p.ox,p.oy=0,0
		should_slerp=false	
		if (npc.dialogue !=nil) then			
			click_txt(npc:dialogue())
		end
		if (npc.push !=nil) then
			npc:push(x,y)
		end
	end
end

--player slerp
function slerp(p)
	local o=slerp_movement(p,x,y,
																				input_delay)
	p.xo=o.x
	p.yo=o.y
	--if move ended, call move end
	if(o.done) on_p_move_fin(p)
	return o.done
end

function on_p_move_fin(p)
	teleport(p)
	local t=gsifo(p)
	--if corrupt tile, corrupt
	if(t==36) then
		q_corrupt(10)
		sfx(8,0)
	end
	pickup(p)
	--move enemies if is last player
	if (p==players[#players] and (x!=0 or y!=0)) move_enemies()
end

function teleport(p)
	--get cur tile
	local ntile=gsifo(p,0,0)
	local pos=other_portal_pos(p,ntile)
	p.x=pos.x
	p.y=pos.y
	if (pos.moved)then
		portal_activated=true
		take_dmg(p,1)
	end 
end

function pickup(p)
	for t in all(tiles) do
		if (t.type =="pickable") then
			if (t.x-mx*8==p.x and 
							t.y-my*8==p.y) then
				t:pickup()
				del(tiles,t)
			end
		end
	end
end

--draw player
function d_player()
	for p in all(players) do
		if (not p.hidden) then
			spr(
				p.damage+
				get_frame(p_sprites,2)
				         ,p.x+p.xo
				         ,p.y+p.yo)
		end
	end
end

--player move
function p_move(p,x,y)
	if	abs(x)>0 or abs(y)>0 then
		doom-=0.25
		p.x+=8*x
		p.y+=8*y
		--direction during movement
		p.dx=x
		p.dy=y
		p.can_move=false
		p.move_started=t()	
	end
	return 8
end

function bump(p,x,y)
	p.dx=x
	p.dy=y
	p.can_move=false
	p.move_started=t()
	return -2
end

function take_dmg(p,dmg)
	sfx(2,0)
	p.damage+=dmg
	p.damage=min(p.damage,8)
end
-->8
--tiles

tiles={}

function set_tiles(i,k)
	if (tile_oc(i,k)) return
	local tile=mget(i,k)
	if (tile==43) then
		add(tiles,new_flr_tile(i*8,k*8))
		add(tiles,new_level_btn(i*8,k*8))
	elseif (tile==36) then
		add(tiles,new_cor_tile(i*8,k*8))
	elseif (tile==37) then
		add(tiles,new_core_slot(i*8,k*8))
	elseif (tile==38) then
		add(tiles,new_flr_tile(i*8,k*8))
	elseif (tile==57) then
		add(tiles,new_flr_tile(i*8,k*8))
		add(tiles,new_charge(i*8,k*8))
	end
end

function tile_oc(i,k)
	for t in all(tiles) do
		if (t.x/8==i and t.y/8==k) return true
	end
	return false
end

function check_finished()
	local b,c = true,0
	for tile in all(tiles) do
		if (tile.type == "level_btn") then
			c+=1
			local tb = tile:is_pressed()
			b=b and tb
		end
	end
	--if all lvl btns are pressed
	if (b and c>0) load_next_lvl()
end

function d_tiles()
	for t in all(tiles) do
		spr(t.s,t.x-mx*8,t.y-my*8)
		if (t.draw!=nil) t:draw()
	end
end

function d_tile_effects()
	for t in all(tiles) do
			if (t.draw_effect!=nil) then
				t:draw_effect()
			end
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
		for i=mx,mx+15 do
			for k=my,my+15 do
				if (mget(i,k) == op) then
					local p1x,p1y=(i-mx),(k-my)
					pp1.x=p1x*8
					pp1.y=p1y*8
					pp2.x=p.x
					pp2.y=p.y
					return {x=p1x*8,y=p1y*8,moved=is_portal}
				end
			end
		end
	end
	return {x=p.x,y=p.y,moved=is_portal}
end

function new_flr_tile(ax,ay)
	return{
		x=ax,
		y=ay,
		s=9,
	}
end

function new_charge(ax,ay)
	return{
		x=ax,
		y=ay,
		s=57,
		type="pickable",
		pickup=function(s)
			doom=doom_i
			sfx(7,0)
		end
	}
end

function new_cor_tile(ax,ay)
	return{
		x=ax,
		y=ay,
		s=36,
		draw_effect=function(self)
			local rx,ry=self.x-mx*8,self.y-my*8
			for i=0,t()%2 do
				fun_mirror(rx+3,ry+3,(3.5+corrupts/8)*8)
			end
		end
	}
end

function new_core_slot(ax,ay)
return{
		x=ax,
		y=ay,
		s=37,
		type="level_btn",
		draw=function(s)
			if (not s:is_pressed()) then
				local x,y=s.x-mx*8,s.y-my*8
				static(x+2,y+2,4,4,25)
			end
		end,
		is_pressed=function(s)
			for npc in all(npcs) do
				if (npc.type=="core") then
					if (npc.x+(npc.xo or 0) == s.x-8*mx and
								npc.y+(npc.yo or 0)== s.y-8*my) then
						return true
					end
				end
			end
			return false
		end
	}
end

function new_level_btn(ax,ay)
	return{
		x=ax,
		y=ay,
		s=43,
		type="level_btn",
		is_pressed=function(self)
			for p in all(players) do
				if (p.x+p.xo == self.x-8*mx and
								p.y+p.yo == self.y-8*my) then
					return true
				end
			end
			for n in all(npcs) do
				n.xo=n.xo or 0
				n.yo=n.yo or 0
				if (n.x+n.xo == self.x-8*mx and
							 n.y+n.yo == self.y-8*my) then
					return true
    end
   end
			return false
		end
	}
end
-->8
--utils

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
n_c=1 --corrupt speed

function corrupt()
	if (corrupts<=0) then
		corrupts=0
		return
	end
	corrupt_n(min(n_c,corrupts))
	corrupts-=n_c
	n_c+=1
	init_tiles()
end

function q_corrupt(x)
	if (x==nil) x=0
	corrupts+=x
	n_c=1
end

--corrupt now
mem=rnd(0x8000)
function corrupt_n(x)
	for i=0,x do
		repeat
			mem=rnd(0x8000)
			doom-=0.05
			bat_warn=true
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

function occupied(ax,ay)
	for p in all(players) do
		if (p.x == ax and p.y == ay) return true
	end
	for n in all(npcs) do
		if (n.x == ax and n.y == ay) return true
	end
	return false
end

sys_timer=t()
reset_offset=0
reset_time=10
function system_reset()
	sys_timer=t()-reset_offset
	sys_timer%=reset_time
	if (sys_timer<0.01) then
		--reload()
		reset()
		new_defaults()
		tiles={}
		p_start_pos={}
		local tnpc={}
		for npc in all(npcs) do
			if (npc.push != nil) then
				add(tnpc,npc)
			end
		end
		npcs={}
		for npc in all(tnpc) do
			add(npcs,npc)
			add(tiles,new_flr_tile(npc.x-8*mx,npc.y-8*my))
		end
		init_tiles()
		init_npcs()
	end
end

--move collision
function collide(p,dx,dy)
	local fdx,fdy=8*dx,8*dy
	--if upcoming has solid flag
	local a = fget(gsifo(p,dx,dy),0) 
	--if player out of bounds
	local b = in_b(p,fdx,fdy)
	local c = false
	local npc= is_npc(p.x+fdx,p.y+fdy)
	if (npc != nil) then
		c=true		
		if (npc.type=="enemy"and p.type=="player") then
			take_dmg(p,npc.atk)
			npc:move()
		end
	end
	return (a or not b or c)
end

--get sprite in front of player
function gsifo(p,dx,dy)
	dx,dy=dx or 0,dy or 0
	return mget(mx+p.x/8+dx,my+p.y/8+dy)
end

--boundary detection
function in_b(p,dx,dy)
	local a=false
	local b=false --for bounds
	local x,y = p.x+dx,p.y+dy
	if 0<=x and 128>x then
		a=true
	end
	if 0<=y and 128>y then
		b=true
	end
	return a and b
end

--generate offset
function slerp_movement(p,x,y,dur)
	local xo,yo,done = 0,0,false
	if (not p.can_move) then
		local dt = t()-(p.move_started or t())
		p.dx=p.dx or 0
		p.dy=p.dy or 0
		p.xo=-p.dx*p.di+p.di*dur*dt*p.dx
		p.yo=-p.dy*p.di+p.di*dur*dt*p.dy
		if (dt >= 1/dur) then
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

function init_map()
	local l=levels[this_lvl]
	mx=l*16-16
	mx%=128
	my=flr(l/9)*16
end
-->8
--npcs

npcs={}

function init_npcs()
	for i=mx,15+mx do
		for k=my,15+my do
			get_npcs(i,k)
		end
	end
end

function get_npcs(i,k)
	local npc=mget(i,k)
	local noc=not occupied((i-mx)*8,(k-my)*8)
	if (npc==34) then
 	add(npcs,new_eb((i-mx)*8,(k-my)*8))
		for io=0,1 do
			for ko=0,1 do
				add(tiles,new_flr_tile((i+io)*8,(k+ko)*8))
			end
		end    
	elseif(npc==53) then
		add(tiles,new_flr_tile(i*8,k*8))
		if (noc) add(npcs,new_bug((i-mx)*8,(k-my)*8,53))
	elseif(npc==55 and noc) then
		add(tiles,new_flr_tile(i*8,k*8))
		if (noc) add(npcs,new_bunny((i-mx)*8,(k-my)*8,55))
	elseif(npc==38 and noc) then
		add(tiles,new_flr_tile(i*8,k*8))
		if (noc) add(npcs,new_core((i-mx)*8,(k-my)*8))
	end
end

function d_npcs()
	for npc in all(npcs) do
		npc:draw()
	end
end

function u_npcs()
	for npc in all(npcs) do
		npc:update()
	end
end

function is_npc(ax,ay)
	for npc in all(npcs) do
		npc.w=npc.w or 1
		npc.h=npc.h or 1
		if ((ax>=npc.x and ax<npc.x+npc.w*8)
		 and (ay>=npc.y and ay<npc.y+npc.h*8)) then
			return npc
		end
	end
	return nil
end

function move_enemies()
	for npc in all(npcs) do
		if (npc.type == "enemy") then
			npc:move()
		end
	end
end

function new_enemy(ax,ay,as)
	return {
		x=ax,--pos
		y=ay,
		xo=0,--offset
		yo=0,
		dx=0,
		dy=0,--dir of movement
		di=8,--distance
		move_started=0,
		s=as,--sprite
		f=false,--flip
		can_move=false,--ignored
		atk=1,--attack
		type="enemy",
		draw=function(s)
			spr(s.s,s.x+s.xo,s.y+s.yo,1,1,s.f)
		end,
		update=function(s)
		local t=slerp_movement(s,s.dx*8,s.dy*8,input_delay)
			s.xo=t.x
			s.yo=t.y
		end,
	}
end

function new_bug(ax,ay,as)
	local bug = new_enemy(ax,ay,as)
	bug.mknew=0
	bug.update=function(s)
		local t=slerp_movement(s,s.dx*8,s.dy*8,input_delay)
		s.xo=t.x
		s.yo=t.y
	end
	bug.draw=function(s)
			spr(s.s+t()%2,s.x+s.xo,s.y+s.yo,1,1,s.f)
	end
	bug.move=function(s)
		s.dx=flr(rnd(2.9)-1)
		s.dy=flr(rnd(2.9)-1)
		if (s.dx!=0) s.f=(s.dx<0)
		if (not collide(s,s.dx,s.dy)) then
			s.x+=s.dx*8
			s.y+=s.dy*8
			s.move_started=t()
		end
	end
	return bug
end

function new_bunny(ax,ay,as)
	local bunny = new_enemy(ax,ay,as)
	bunny.mknew=0
	bunny.draw=function(s)
			spr(s.s+2*t()%2,s.x+s.xo,s.y+s.yo)
	end	
	bunny.move=function(s)
		s.dx=flr(rnd(2.9)-1)
		s.dy=flr(rnd(2.9)-1)
		if (s.dx!=0) s.f=(s.dx<0)
			if (not collide(s,s.dx,s.dy)) then
				if (s.dx!=0 or s.dy!=0) then
					if (s.mknew==2) add(npcs,new_bug(s.x,s.y,s.s))
					s.mknew+=1
					s.mknew%=3
				end
				s.x+=s.dx*8
				s.y+=s.dy*8
				s.move_started=t()
			end
		end
	return bunny
end

has_spoken=false
function new_eb(ax,ay)
	return {
		s=34,
		type="enlightened",
		x=ax,
		y=ay,
		w=2,
		h=2,
		ox=0,
		oy=0,
		update=function(s)
			s.oy=sin(t()/3)+0.1
		end,
		dialogue=function(s)
			if (this_lvl >3) return {"strange seeing","you again..."}
						s.c=s.c or 0
		 if (s.c==0) then
		 	mset(45,12,43)
		 	init_tiles()
		 	no_filter()
		 	has_spoken=true
			end
			s.c+=1
			if (s.c==1)	return {"zzz..!▥░▥    ","☉sight enhanced☉  "}
			if (s.c<3) return {"now go.","free us from corruption!"} 
			if (s.c<4) return {"try not to worry.","we will remake you."}
			if (s.c>=4) return {"..."}
		end,
		draw=function(s)
		 spr(s.s,s.x+s.ox,s.y+s.oy,s.w,s.h)
		end,
	}
end

function new_core(ax,ay)
	local core = {}
	core.type="core"
	core.move_started,core.di=0,8
	core.x,core.y,core.dx,core.dy=
	ax,    ay    ,0      ,0
	core.draw=function(s)
		s.xo=s.xo or 0
		s.yo=s.yo or 0
		spr(38,s.x+s.xo,s.y+s.yo)
	end	
	core.update=function(s)
		local t=slerp_movement(s,s.dx*8,s.dy*8,input_delay)
		s.xo=t.x
		s.yo=t.y
	end
	core.move=function(s)
		if (not collide(s,s.dx,s.dy)) then
			s.x+=s.dx*8
			s.y+=s.dy*8
			s.move_started=t()
		end
	end
	core.push=function(s,adx,ady)
		s.dx=adx
		s.dy=ady
		s:move()
		sfx(5,0)
	end
	return core
end
-->8
--ui

--dialogue

---/ text that appears at the
--   start of a level, but
--   not connected to the level
--   itself, just the nth room

level_speak={
	{{"where am i?"},},
	{{"why is","everything so","  pixelated?  "}},
	{{"the maker..."}},
}

function dialogue()
	return level_speak[this_lvl]
end

--utils
clicked=false
dbox=false --should draw
bbg=false
box_collapse=false --should bc
box_w=0
box_h=0
box_x=0
box_y=0

box_i=true --interactive
box_c1=0 --black
box_c2=6 --grey
box_txt={}

function play_welcome_txt()
	multi_ct(dialogue(),nil,nil,nil,nil)
end

text_c=0
text_q={}
--multiple click_texts at once
function multi_ct(txts,ai,ax,ay,abbg)
	for txt in all(txts) do
		add(text_q,{txt,ai,ax,ay,abbg})
	end
end

--text queue
function manage_q()
	for i=1,#text_q do
		local t = text_q[i]
	end
	if (not dbox and #text_q>0) then
		local i=text_q[1]
		click_txt(i[1],i[2],i[3],i[4],i[5])
		deli(text_q,1)
	end
end

function pause_during_txt()
	paused=dbox
end

--enable click through text
function click_txt(txt,i,x,y,abbg)
	box_txt=txt
	box_w=4*l(txt)+4
	box_h=10*#txt+2
	
	box_x=x or 64-box_w/2
	box_y=y or 64-box_h/2
	box_i=i or true
	if (abbg!=nil)	bbg=abbg
	
	dbox=true
	box_collapse=false
end

--draw click through text
function d_click_txt()
	if (not clicked) then
		animated_d_box(box_txt)
	end
end

cur_box_w=0
function animated_d_box(tbl,i)
	if (dbox) then
		draw_box(tbl,cur_box_w,box_h,i)
	end
	local spd=2+l(tbl)/20
	if (not box_collapse) then
		if (cur_box_w<box_w) cur_box_w+=spd
		if (cur_box_w>box_w) cur_box_w=box_w
	else
		if (cur_box_w>0) then
			cur_box_w-=spd
		else
			dbox=false
		end
	end	
end

function draw_box(tbl,w,h,i)
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
			print(txt,bo+box_x+w/2-txt_w/2+1,box_y+o+1)
		end
		o+=10
	end
	if (box_i and box_w<=w) then
		local iconx, icony= bo+box_x+w-10,box_y+h
		rectfill(iconx-1,icony-1,iconx+7,icony+5,0)
		print("❎",iconx,icony,6)
	end
end

function bar(x,y,w,h,c1,c2,p)
	local pe=min(p,1)
	if (pe<0) pe=0
	rectfill(x+1,y,x+(w-1),y+(h-1),0)
	rectfill(x+1,y,x+(w-1)*pe,y+(h-1),c2)
	rect(x,y,x+w-1,y+h,c1)
end

function arrow_fill(x,y,p)
	local pe=min(p,1)
	if (pe<0) pe=0
	rectfill(x,y,x+7,y+7,0)
	rectfill(x+8-7*min(1,pe*2),y+6,x+7,y+7,12)
	rectfill(x,y+7,x+1,y+7-7*min(1,max(0,(pe*2-.75))),12)
	rectfill(x+7*(min(1,max(0,(pe*2-1)))),y+4,x,y,12)
	spr(39,x,y)
end

function d_battery(x,y,p)
	if (not p) p=0
	if (p<0) p=0
	if (p>1) p=1
	local c=11
	local c2=3
	if (p<0.5) then
		c=8
		c2=2
	end
	rect(x+3,y,x+4,y,5)
	rectfill(x+2,y+1,x+5,y+7,c2)
	local height=y+8*(1-p)
	
	if (height<8)rectfill(x+2,height+1,x+5,y+7,c)
end

bat_warn=false
b_warn_t=-1
function d_bat_warn(x,y)
	rectfill(x+1,y-1,x+6,y+8,8)
end

function d_ui()
	if (bat_warn) then
		bat_warn=false
		b_warn_t=t()
	end
	if (t()-b_warn_t<0.3) then
	if (20*t()%2>=1) then
				d_bat_warn(120,1)
	end
	end
	d_battery(120,1,max(0,doom)/doom_i)
	arrow_fill(0,1,sys_timer/reset_time)
end
__gfx__
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000eeeeeeee656eeeee66666666eeeee656656ee65666666666
00000000ee6666eeee5666eeee5666eeee5655eeee5655eeee5655eeee5655eeee5555ee00000000eeeeeeee656eeeee55566555eeeee656656ee66665555666
00700700ee6cc6eeee5cc6eeee5cc6eeee5cc6eeee5cc6eeee5cc6eeee5cc5eeee5ee5ee00000000eeeeeeee656eeeee66666666eeeee656656ee66665666656
00077000ee6666eeee6666eeee6666eeee6666eeee6565eeee5565eeee5555eeee5555ee00000000eeeeeeee666eeeeeeeeeeeeeeeeee666656ee656656ee656
00077000eee65eeeeee65eeeeee65eeeeee65eeeeee65eeeeee55eeeeee55eeeeee55eee00000000eeeeeeee666eeeeeeeeeeeeeeeeee666656ee656656ee656
00700700ee6666eeee6666eeee6665eeee5665eeee5565eeee5555eeee5555eeee5555ee0000d00066666666656eeeeeeeeeeeeeeeeee65666666656666ee656
00000000ee6ee6eeee6ee6eeee6ee5eeee6ee5eeee5ee5eeee5ee5eeee5ee5eeee5ee5ee0000000055566555656eeeeeeeeeeeeeeeeee65665555556666ee656
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000066666666656eeeeeeeeeeeeeeeeee65666666666656ee656
eeeeeeeeee6666eeee5666eeee5666eeee5655eeee5655eeee5655eeee5655eeee5555eeeeeeeeeeeeeeeeee66666666656eeeeeeeeee6566666666600000000
eeeeeeeeee6cc6eeee5cc6eeee5cc6eeee5cc6eeee5cc6eeee5cc6eeee5cc5eeee5ee5eeeeeeeeeeeeeeeeee65555665666eeeeeeeeee6665665555600000000
eeeeeeeeee6666eeee6666eeee6666eeee6666eeee6565eeee5565eeee5555eeee5555eeeeeeeeeeeeeeeeee65666666666eeeeeeeeee6666666665600000000
eeeeeeeeeee65eeeeee66eeeeee65eeeeee65eeeeee55eeeeee55eeeeee55eeeeee55eeeeeeeeeeeeeeeeeee656eeeee656eeeeeeeeee656eeeee65600000000
eeeeeeeeeee65eeeeee65eeeeee65eeeeee65eeeeee65eeeeee55eeeeee55eeeeee55eeeeeeeeeeeeeeeeeee656eeeee656eeeeeeeeee656eeeee65600000000
eeeeeeeeee6666eeee6666eeee6665eeee5665eeee5565eeee5555eeee5555eeee5555eeeeeee666666eeeee666eeeee6566666666666656eeeee66600000000
eeeeeeeeee6ee6eeee6ee6eeee6ee5eeee6ee5eeee5ee5eeee5ee5eeee5ee5eeee5ee5eeeeeee655556eeeee666eeeee6555566556655556eeeee66600000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee656656eeeee656eeeee6666666666666666eeeee65600000000
0000000000000000eeeeeeeeeeeeeeee0123456700000000eeeeeeee0dddedd000000000eeeee656656eeeee0000000000000000000000000000000000000000
0000000000000000eeeeeeeeeeeeeeee89abcdf00cccccc0eeeeeeeeddddeedd00000000eeeee655556eeeee0000000000000000000000000000000000000000
0000000000000000eeeeeeeaaeeeeeee123456780cd51dc0eecccceedeeeeeed00000000eeeee666666eeeee0000000000000000000000000000000000000000
0000000000000000eeeeeeaaaaeeeeee9abcdf010c51c1c0eec1cceededdeedd00000000eeeeeeeeeeeeeeee0000000000000000000000000000000000000000
0000000000000000eeeeeeaaaaeeeeee234567890c1c15c0eecc1ceededdeddd00000000eeeeeeeeeeeeeeee0000000000000000000000000000000000000000
099999900cccccc0eeeeee9aa9eeeeeeabcdf0120cd15dc0eecccceededddddd00000000eeeeeeeeeeeeeeee0088880000000000000000000000000000000000
1111111111111111eeeeeee99eeeeeee3456789a0cccccc0eeeeeeeedeeeeedd00000000eeeeeeeeeeeeeeee0dddddd000000000000000000000000000000000
0000000000000000eeeeea9999aeeeeebcdf012300000000eeeeeeee0dddddd000000000eeeeeeeeeeeeeeee0000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeea9e99e9aeeee00000000eeeee8e8eeeeeeeeee8ee8eeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000
eee66666666665eeeeeeae9999e9eeee00000000eeee8e8eeeeee8e8ee8ee8eeee8ee8eeeeeeeeee000000000000000000000000000000000000000000000000
ee6666666666665eeeee9ee99eeeeeee00000000eeeea8aeeeee8e8eeea88aeeee8ee8eeeee55eee000000000000000000000000000000000000000000000000
ee6666666666665eeee4449999444eee00000000ee82882eee82a8aeee8888eeeea88aeeee3333ee000000000000000000000000000000000000000000000000
ee66665eee66665eeee44444aa444eee00000000e88222eee882882eeee22eeeee8888eeeebbbbee000000000000000000000000000000000000000000000000
ee6665eeeee6665eeeee44449944eeee00000000e88882eee88222eeeee88eeeeee22eeeeebbbbee000000000000000000000000000000000000000000000000
ee6665eeeee6665eeeeeeeeeeeeeeeee00000000e88822eee88822eeee8888eeee8888eeeebbbbee000000000000000000000000000000000000000000000000
ee6665eeeee6665eeeeeeeeeeeeeeeee00000000e2e2e2eee2e2e2eeee8ee8eeee8ee8eeeeeeeeee000000000000000000000000000000000000000000000000
ee6665eeeee6665eeeefeeeeeeed6dd6eeeeeeee5dee11ee00000000eddddddeee66665e000000000000000000000000eeeeeeee000000000000000000000000
ee6666eeee66665eeeffffeedded6666ee88888eeed6665e00000000eeb3b3eeee65165e000000000000000000000000e776e776000000000000000000000000
ee6666666666665eeff57f8e66ded66de88eee8eee6c86ee00000000eeddddeeee66d65e000000000000000000000000e7777776000000000000000000000000
ee6666666666665eeeffff8ec66d6666eeeeee8e1e66661e00000000ee5252eeeee665ee000000000000000000000000e7888876000000000000000000000000
ee6666666666665eee88888ecc6d6cc6eee8888eeee6deee00000000d525252deee665ee000000000000000000000000e7777776000000000000000000000000
eee66666666665eeeeeee8ee66666666eee8eeeeeee66e1e00000000ee5252eeee66665e000000000000000000000000ee77776e000000000000000000000000
eeee666666665eeeee8eeeeedd6cc6ddeeeeeeeeee5e15ee00000000ee2525eeee65e65e000000000000000000000000ee76e76e000000000000000000000000
eeee665665665eeeeeeeeee8ed6666deeee8eeeeee5eeeee00000000ed5252deeeeeeeee000000000000000000000000eeeeeeee000000000000000000000000
eeee665665665eee0000000000000000000000000000000055eeee55eeeeeeee0000000000000000e5ee5eee0000000000000000000000000000000000000000
eeee665665665eee000000000000000000000000000000005e8778e5eeeeeeee0000000000000000eeeeeee50000000000000000000000000000000000000000
eeee665665665eee00000000000000000000000000000000e77cc77e777ee77e0000000000000000ee5555ee0000000000000000000000000000000000000000
eeee665665665eee00000000000000000000000000000000772cc2787677776e00000000000000005e5665ee0000000000000000000000000000000000000000
eeee665665665eee00000000000000000000000000000000872cc277705777ee0000000000000000ee5665e50000000000000000000000000000000000000000
eeee665665665eee00000000000000000000000000000000e77cc77e7776677e0000000000000000ee5555ee0000000000000000000000000000000000000000
eeee665665665eee000000000000000000000000000000005e8778e5666ee66e00000000000000005eeeeeee0000000000000000000000000000000000000000
eeee665665665eee0000000000000000000000000000000055eeee55eeeeeeee0000000000000000eee5ee5e0000000000000000000000000000000000000000
eeee665665665eee00000000000000007eaaaa7e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeee65e65ee65eee0000000000000000ea9999a70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeee65eeeee65eee00000000000000007a9889ae0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeee0000000000000000ea9889a70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeee00000000000000007a9889ae0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeee0000000000000000ea9999a70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeee00000000000000007eaaaa7e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeee0000000000000000e7e7e7ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05550550000000000000006000000000005000000000000000000000000500000000000000000000000000000000000000000000000000000000000000055000
55550055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222200
50000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222200
50550055000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000222200
50550555600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222200
50555555000000000000000000000000000000000000050000000000000000000000000000000000005000000000000000000000000000000000000000222200
52222255000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222200
05555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222200
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006000000000000000000000000000006000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000500000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000
00000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000
00000000000000000000000000000000000000500000000000000000000000000000000000000000000050000000000000000000000000000000000000000000
00000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000005
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000
00000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000
00000000000000000000000000500000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000
00000000000000000000000000000666666666666666666666666666666666666666666666666666666666666666666666600000000000000000000000000000
06000000000000000000000000000655555665555556655555566555555665555556655555566555555665555556655555600000000000000005000000000000
00000000000000000000000000000656666666666666666666666666666666666666666666666666666666666666666665600000000000000000000000000000
00000000000000000000000000000656000000000000000000000000000000000000000000000000000000000000000065650000000000000000000000000000
00000000000000000000000000000656006666000000000000000000000000000000000000000000000000000000000065600000000000000000000000500000
00000000000000000000000000000656006226000000000000000000000000000000000000000000000000000000000065600000000000000000000000000000
00000000000000050000000000000666006666000000000000000000000000000000000000000000000000000000000066600000000000000050000000000000
00000000000000000000000000000666000650000000000000000000000000000000000000000000000000000000000066600000000000000000000000000000
00000000000000000000000000000656006666000000500000005000000050000000500000005000000050000055550065600000000000000000000000000000
00000000000000000000005000000656006006000000000000000000000000000000000000000000000000000555555065600000000000000000000000000000
00000000000000000000000000000656000000000000000000000000000000000000000000000000000000000000000065600000000000000000000000000000
00000006000000000000000000000656666666666666666666666666666666666666666666666666666666666666666665600000000000000000000000000000
00000000000000000000000000000655555665555556655555566555555665555556655555566555555665555556655555600000000000000000000000000000
00000000000000000000000000000666666666666666666666666666666666666666666666666666666666666666666666600000000000000000000000000000
00000000000000000000000000006000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000050000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000
00000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000500000000000500000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000005000000600000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000600
00000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000050000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000
00000000000600000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000006000000000000000000000000000000060000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000050000006000000000000050000000000000005000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000600000000000000000000
00000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000
00000000000000000006000000000000000000000500000000000000000000000500000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000
00000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000050000000000000500000000000000000000000000000000000000000000000000000000000000000
00000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000001010101010100000000000000000001010101010100020001010000000000010100000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1010101010101010101010101010101010101010101010101010101010101010190a0a0a1a10101010101010101010101010101010190a0a0a0a1a10101010101010190a0a0a0a0a0a0a0a0a1a1010101010190a0a0a0a0a0a0a0a0a0a1a10101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010100d0909091c1a1010101010101010101010101010100d090909090b101010101010100d01090909090939092b0b10101010191d090909090909090909091c1a10101010101010101010101010101010101010101010190a1a1010101010101010
10101010101010101010101010101010101010101010101010101010101010100d090109091c1a1010101010101010101010190a0a1d091b1e091c0a1a1010101010290c0c0c0c0c0c0c0c0c2a101010191d0909090909090909090909091c1a1010101010101010101010101010101010101010191d091c1a10101010101010
1010101010101010101010101010101010101010101010101010101010101010291e090909091c1a101010101010101010100d010924090b0d09092b0b101010101010101010101010101010101010100d09090909090909090909090909090b1010101010190a0a0a0a1a1010101010101010191d0909091c1a101010101010
10101010101010101010101010101010101010190a0a0a0a0a0a0a0a1a10101010291e090909091c1a101010101010101010290c0c0c0c2a290c0c0c2a1010101010190a0a0a0a0a1a101010101010100d09090909090909090909090909090b10101010191d090909091c1a101010101010191d09010925091c1a1010101010
101010101010101010101010101010101010100d01090924090909090b1010101010291e090909090b101010101010101010101010101010101010101010101010100d010924092b0b101010101010100d09090909090909090909090909090b101010191d0909090909091c1a10101010100d090909090909091c1a10101010
101010190a0a0a0a0a0a0a0a1a1010101010100d09090924090909090b101010101010291e0920090b10101010101010101010101010101010101010101010101010290c0c0c0c0c2a101010101010100d09090909090909090909090909090b1010100d09090909092509090b1010101010291e090909090909091c1a101010
1010100d010909090909092b0b1010101010100d09090924090909090b101010101010100d0909090b1010101010101010101010101010101010101010101010101010101010101010101010101010100d09090909090909090909090909090b1010100d09090909090909090b101010101010291e090909090909391c1a1010
101010290c0c0c0c0c0c0c0c2a1010101010100d09090924090909090b10101010101010290c0c0c2a10101010101010101010101010101010101010101010101010190a0a0a0a0a0a0a0a1a101010100d010909090909090909350909092b0b1010100d09012609090909090b10101010101010291e090909260924240b1010
101010101010101010101010101010101010100d090909240909092b0b1010101010101010190a0a0a0a0a0a0a1a10101010101010101010101010101010101010100d010909242409092b0b101010100d09090909370909090909090909090b1010100d09090909090909240b1010101010101010291e24090909091b2a1010
10101010101010101010101010101010101010290c0c0c0c0c0c0c0c2a10101010101010100d090909090909091c1a101010101010190a1a101010190a1a10101010290c0c0c0c0c0c0c0c2a101010100d09090909090909090909090909090b101010291e0909090909241b2a101010101010101010291e092b091b2a101010
101010101010101010101010101010101010101010101010101010101010101010101010100d09090922230909090b1010101010100d2b0b1010100d010b1010101010101010101010101010101010100d09090909090909090909090909090b10101010291e090909241b2a1010101010101010101010291e091b2a10101010
101010101010101010101010101010101010101010101010101010101010101010101010100d09210932330909090b1010101010191d091c0a0a0a1d090b1010101010101010101010101010101010100d09090909090909090909090909090b1010101010290c0c0c0c2a10101010101010101010101010290c2a1010101010
101010101010101010101010101010101010101010101010101010101010101010101010100d090909090909091b2a10101010100d09090909090909240b101010101010101010101010101010101010291e0909090909090909090909091b2a1010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010290c0c0c0c0c0c0c2a101010101010290c0c0c0c0c0c0c0c2a10101010101010101010101010101010101010291e090909090909090909091b2a101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010290c0c0c0c0c0c0c0c0c0c2a10101010101010101010101010101010101010101010101010101010101010101010
1010190a1a101010190a0a0a0a1a10101010101010101010101010101010101010101010100a0a0a0a101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10191d091c1a10191d090909091c1a101010101010101010101010101010101010100a101d090909091c100a1010101010101010190a0a0a0a1a10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
100d0909090b100d0909090909090b1010101024101010101010101010101010101d090e0909090909090e091c101010101010100d252525250b10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
191d0909091c1a0d0909010909090b1010101010101010190a0a0a0a0a0a0a1a0d0909090925090925090909090b1010101010191d090909091c1a101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
0d09090909090b0d0909092109090b1010101010190a0a1d090909090909250b101e090f0909090909090f091b1010101010100d0909090935090b101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
0d09092b09090b0d0909090909090b10101010191d09090909091b0c0c0c0c2a10100c101e090101091b100c101010101010100d0909090909090b101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
0d09090909090b291e090909091b2a101010100d0909090109090b101010101010101010101e09091b101010101010101010100d0935262626260b101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
0d09090909090b10290c0c0c0c2a101010190a1d090909091b0c2a101010101010101010390d09090b391010101010101010100d0909260909090b101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
0d09240909090b1010190a0a0a1a1010191d090909091b0c2a10101010101010101010190a1d09091c0a1a1010101010101010291e092609091b2a101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
0d09090909090b190a1d0909091c0a1a0d09090909090b1010101010101010101010191d0909090909091c1a10101010101010100d092609010b10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
0d09090922090b0d090909090909090b0d0926091b0c2a10102410101010101010100d09092609092609090b1010101010101010290c0c0c0c2a10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
0d09090909090b0d2009092b0909240b291e39090b10101024241010101010101010291e0909090909091b2a101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
291e0921091b2a0d090909090909090b10290c0c2a1010101010101010101010101010291e091b1e091b2a100a0a1a101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
100d0909090b10290c1e0939091b0c2a10101010101010101010101010101010101010100d090b0d090b100d22090b101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10291e091b2a101010290c0c0c2a101010101010101010101010101010101010101010100d2b0b0d2b0b100d09090b101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1010290c2a10101010101010101010101010101010101010101010101010101010101010290c2a290c2a10290c0c2a101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
__sfx__
d60200002505725057250570d0070c0070c0070c0070c0070c0070c0070b0070b0070b0070c0070d0070e0070f007110071200713007160071800715007120070e0070a007010070000700007000070000700007
570300002f0402e0402c0402a04029040270402504022040200401f0401e0401d0401b0401a0401904017040150401404012040110400f0400e0400d0400c0400c0400b0400a0400904008040070400604005040
a10300002165324653226531c6531d65326603006032a60300603006032a6030060326603006032160315603126031360300603126030060313603196031e6031f6031e6031c6031960315603136031260310603
0a0e0000165551b5550050521555005052655500505295550050500505295550050526555005052255515555135551455500505185551c5552055500505225550050500505005050050500505005050050500505
3e1100001c7521f752207522275224752007021c7521a7021b7520470219752007021c7521d7521e752007022575222752207521d752007021b7021b752197521675218752007020070200702007020070200000
a50800001d6511a65118651166511f6011e6011c6011c6011a6011a6011a6011a6011c6011c6011c6011c60100601006010060100601006010060100601006010060100601006010060100601006010060100601
110500001e0541e0541e0540000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004
21060000317563e756000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
47020000172531f253152531e25313253192531a253122531a2531525313253062031f2031f20302203102030f2032520325203002031d2031d20310203222032320324203252032620317203172031520313203
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
911400001715117157171571714217147171471714117137171371713217127171271712117117171121711715157151511515715147151421514715147151311513715137151221512715127151111511715111
911400000000012152121571215712141121471214712142121371213712131121271212712122121171211712111101571015710152101471014710141101471013710132101371012710127101271011710117
911400001315213157131511314713142131471314113137131321313713121131221312713117131111311712152121571215112147121421214712141121371213212137121211212712122121171211112117
911400000e1570e1510e1570e1420e1470e1410e1470e1370e1370e1320e1270e1270e1270e1110e1170e1170d1570d1520d1570d1470d1470d1410d1470d1370d1370d1320d1270d1270d1270d1110d1170d117
a1140000210412104721047210421c0471c0471c0471c042230412304723047230471a0411a0411a0471a0471f0421f0471f0471f047170421704717047170411a0471a0471a0471a0421c0471c0471c0421c047
a1140000217522175521755217521c7551c7551c7521c755237552375223755237551a7521a7551a7551a7521f7551f7551f7521f755177551775217755177551a7521a7551a7551a7521c7551c7551c7521c755
591400000d1650e16510165121650d1650e16510165121650d1650e16510165121650d1650e16510165121650d1650e16510165121620d1650e16510165121610d1650e16510165121620d1650e1651016512161
7d140000210552105121055210511c0551c0511c0551c0532305526052280552a0551a0511a0551a0531a0551f055210522305526055170511705517051170551a0551c0521f05523052210551e0522305525052
a31400002a74025740287432674028742287422a7402574026740287402a7402b7422d7402b7402d7422a740257411e7402174025742267402674028742257402374021741237402574023742217402374225740
a11400002a74225745217422174223740257452874026740267402574021742217421a7401a7421a7421a74215745197421e7451c7451f745237421e7451f745217401f745217452374026740257422374221742
911400000e1570e1570e1550e1450e1470e1470e1470e1371a1311a1371a1271a1271a1271a1171a1171a1170d1570d1570d1550d1450d1470d1470d1470d1371913119135191251912519125191151911519115
9114000013157131571315513145131471314713147131371f1311f1371f1271f1271f1271f1171f1171f11712157121571215512145121471214712147121371e1311e1351e1251e1251e1251e1151e1151e115
5914000025732257321e73225732257321e7321e7321e732267322573223732257322673225732237322173225731257311e73225732257321e7321e7321e7322573523733217351f7331e7351c7331a7341a732
00140000001050010500105001050e105001050e1050e105061050e1050e105001050e1050e105001050c1050c105001050c1050c105071050c1050c105001050c1050c105001050710507105001050710507105
0014000015102001021a102001021510218102021020010216102001020f102151020010215102161021510215102181020010212102161020010200102151020010200102131021310213102131020010200102
001400000e1030e1030e1030e1030e1030e1030e1030e1030e1030e1030e1030e1030e1030e1030e1030e1030c1030c1030c1030c1030c1030c1030c1030c1030c1030c1030c1030c1030c1030c1030c1030c103
__music__
01 4a0a4344
00 4d0c4e44
00 4a0b0a44
00 4c0d0c4f
01 4d0c0e0d
00 4a0b100a
01 4d0c0e0f
00 4a0a0b12
00 54151114
00 4a0b1013
02 4a0b1016

