pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- ◆ portal inspired ◆
--   by  cameron dugan

--player
px=0
py=0
pxo=0
pyo=0
inputs={}
p_sprites={1,17}
p_damage=0
p_can_move=true
p_move_started=nil

--controlls
input_delay=6
input_buffer={}

--utils
debug=true
debug_vars={}

function _init()
	--key repeat delay
	poke(0x5f5c, input_delay)
	poke(0x5f5d, input_delay)
end


function _draw()
	cls()
	map()
	--player
	d_player()
	if (debug) then
		for i in all(debug_vars) do
			print(i,8)
		end
	end
	debug_vars={}
end

function _update60()
	get_input()
	update_player()
end

function get_input()
	local x,y = 0,0
	if (btnp(0)) x-=1
	if (btnp(1)) x+=1
	if (btnp(2)) y-=1
	if (btnp(3)) y+=1
	add(debug_vars,x)
	add(debug_vars,y)
	if (abs(x)>0 or abs(y)>0) then
		if (#input_buffer <= 2) then
			add(input_buffer,{x=x,y=y})
		end
	end
end

function update_player()
	if (#input_buffer>0) then
		if (p_can_move) then
			move_from_buffer()
		end
	else	
		x=0
		y=0
	end
			--movement
	p_move(x,y)
	--update player sprite offset
	o=animate_movement(x,y,pdx,pdy)
	pxo=o.x
	pyo=o.y
end

function move_from_buffer()
	x=input_buffer[1].x
	y=input_buffer[1].y
	del(input_buffer,input_buffer[1])
end

function d_player()
		spr(
			p_damage+
			get_frame(p_sprites,3)
			,px+pxo
			,py+pyo)
end

function p_move(x,y)
	if (p_can_move) and 
				((abs(x)>0) or abs(y)>0) 
				then
		px+=8*x
		py+=8*y
		--direction during movement
		pdx=x
		pdy=y
		p_can_move=false
		p_move_started=t()
	end
end

--generate offset
function animate_movement(x,y,dx,dy)
	local xo,yo = 0,0
	if (not p_can_move) then
		local dt = t()-p_move_started
		xo=-dx*8+8*input_delay*dt*dx
		yo=-dy*8+8*input_delay*dt*dy
		if (dt > 1/input_delay) then
			p_can_move=true
			xo=0
			yo=0
		end
	end
	return {x=xo,y=yo}
end
	

function get_frame(arr,speed)
	return arr[flr(t()*speed%#arr)+1]
end
__gfx__
000000000000000000000000000000000000000000000000000000000000000000000000dd11ddd1000000002720000022222222272000000000000000000000
000000000066660000566600005666000056550000565500005655000056550000555500dd11111d000000002720000077777777272000000000000000000000
00700700006cc600005cc600005cc600005cc600005cc600005cc600005cc50000588500d1ddd11d000000002720000022222222272000000000000000000000
0007700000666600006666000066660000666600006565000055650000555500005555001ddd1d1d000000002720000000000000272000000000000000000000
000770000006500000065000000650000006500000065000000550000005500000055000ddd1dd11000000002720000000000000272000000000000000000000
007007000066660000666600006665000056650000556500005555000055550000555500111ddd11222222222720000000000000272000000000000000000000
000000000060060000600600006005000060050000500500005005000050050000500500d11dd1dd777777772720000000000000272000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000001d1d1ddd222222222720000000000000272000000000000000000000
00000000006666000056660000566600005655000056550000565500005655000055550000000000000000002222222200000000000000000000000000000000
00000000006cc600005cc600005cc600005cc600005cc600005cc600005cc5000058850000000000000000002777777700000000000000000000000000000000
00000000006666000066660000666600006666000065650000556500005555000055550000000000000000002722222200000000000000000000000000000000
00000000000650000006600000065000000650000005500000055000000550000005500000000000000000002720000000000000000000000000000000000000
00000000000650000006500000065000000650000006500000055000000550000005500000000000000000002720000000000000000000000000000000000000
00000000006666000066660000666500005665000055650000555500005555000055550000000222222000002720000000000000000000000000000000000000
00000000006006000060060000600500006005000050050000500500005005000050050000000277772000002720000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000272272000002720000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000272272000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000277772000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000222222000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
090909090909090b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090909091b2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09090909091b2a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090909091b2a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c2a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000