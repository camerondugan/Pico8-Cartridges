pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
//how often it steps
step = 5000
step⧗ = step

screen_w = 128
screen_h = 128
xmod = 0
ymod = 0

search_attempts = .2
life_potency = 1.35
starting_lifeforms = 100

function _init()
	cls()
	cls()
	for i=0,starting_lifeforms do
		step⧗ = step
		while(step⧗ >= 0) do
			step⧗ -= 1/30
		end
		step *= .97
		if step <=0 then
			step = 10
		end
		pset(flr(rnd(screen_w)+1),flr(rnd(screen_h)+1),i)
	end
end

function _draw()
	multiply()
end

function multiply()
	for x=0,screen_w do
		for y=0,screen_h do
			collor = pget(x,y)
			if collor != 0 then
				success = 0
				for i=0,search_attempts do
					xmod = rnd(3)-1
					ymod = rnd(3)-1
					to_fill_x = non_color_adjacent_x(x,y,collor)
					to_fill_y = non_color_adjacent_y(x,y,collor)
					if (to_fill_x != nil) then
						pset(to_fill_x,to_fill_y,collor)
						success = 1
						if flr(rnd(life_potency)) == 0 then
							pset(x,y,0)
						end
					end
				end
				if success==0 then
					pset(x,y,0)
				end
			end
		end
	end
end

function non_color_adjacent_x(x,y,collor)
	if pget(x+xmod,y+ymod) != collor then
		return (x+xmod)
	end	
end

function non_color_adjacent_y(x,y,collor)
	if pget(x+xmod,y+ymod) != collor then
		return (y+ymod)
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
