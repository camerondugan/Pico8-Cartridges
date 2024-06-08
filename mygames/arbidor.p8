pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--     ☉ arbidor ☉
--   by  cameron dugan

--flags=[
-- 0=walls
-- 1=orange portal
-- 4=blue portal

--AI
Bots={}

--UI
Playing=true
Paused=false

--map
MX=0
MY=0

--controlls
Input_Delay=6
Input_Buffer={}

--utils
Debug=true
D={}

--level 15 is for tips
--game essentials
Levels={1,2,3,5,4,6,7,8,9,10,11,12,13,14,15,14}
This_LVL=3
Doom=100
Doom_I=Doom

function New_Defaults()
	--key repeat delay
	poke(0x5f5c, Input_Delay)
	poke(0x5f5d, Input_Delay)
	--disable black transparency
	palt(0,false)
	--make pink transparent
	palt(14,true)
	--add menu items
	menuitem(1,"1 bit color",MonoColor)
	menuitem(2,"2 bit color",DualColor)
	menuitem(3,"gameboy colors",GameBoyColors)
	--set filter properly
	if (This_LVL<=3 and not SpokeToEO and CustomPalette==0) then
		DarkFilter()
	end
	if (CustomPalette==1) then MonoFilter() end
	if (CustomPalette==2) then DarkFilter() end
	if (CustomPalette==3) then GameBoyFilter() end
end

function _init()
	music(0)
	--srand(69)
	New_Defaults()
	MapInit()
	InitTiles()
	InitNPCs()
	PlayWelcomeText()
	JustPlaying=false
end

function _draw()
	if Playing then
		cls()
		★_bg()
		map(MX,MY)
		DrawTiles()
		--player
		DrawPlayer()
		DrawNPCs()
		DrawTileEffects()
		portal_fx(PortalPosition1.x,PortalPosition1.y,PortalColor(0),p)
		portal_fx(PortalPosition2.x,PortalPosition2.y,PortalColor(1),p)
		if (DrawBox and BBG) then cls() end
		DrawUI()
		DrawClickableText()
		if (LVL_T) then d_transitions() end
		if (#Players==0) then LoadLVL() end
		if (Doom<=0) then
			LoadLVL(1)
			Doom=Doom_I
		end
	end
	--game over
	if(not Playing and JustPlaying) then
		reload()
		ClickText({"you can no longer move","want to restart?","press ctrl and r","at the same time.","it works at all times"},false)
	end
	JustPlaying=Playing
end

function Update_Tiles()
	for t in all(Tiles) do
		if (t.update ~= nil) then t:update() end
	end
end

function _update60()
	if (Playing) then
		GetInput()
		ManageQueue() --text queue
		--level finished
		CheckFinished()
		SystemReset()
		ManageCorrupt()
	end
	if (Playing and not Paused) then
		UpdatePlayer()
		Update_Tiles()
		UpdateNPCs()
		Doom=Doom-0.01
	end
	ParseDuringText()
	--debugging
	if (Debug) then
		for i in all(D) do
			print(i,6)
		end
	end
	D={}
end

InputX,InputY = 0,0
function GetInput()
	add(D,tostr(InputX))
	add(D,tostr(InputY))
	InputX, InputY = 0, 0
	if (not Paused) then
		if (btnp(0)) then InputX=InputX-1 print("l") end
		if (btnp(1)) then InputX=InputX+1 end
		if (btnp(2)) then InputY=InputY-1 end
		if (btnp(3)) then InputY=InputY+1 end
		add(D,tostr(InputX))
		add(D,tostr(InputY))

		-- if btnp(4) or btnp(5) then LoadLVL() end
	end
	for player in all(Players) do
		if (abs(InputX)>0 or abs(InputY)>0) then
			if (#player.input_buffer < 2) then
				add(player.input_buffer,{x=InputX,y=InputY})
			end
		end
	end
	if (btnp(5) or btnp(4) and BoxI) then
		BoxCollapse=true
	end
end

function RemoveFromBuff(player)
	InputX=player.input_buffer[1].x
	InputY=player.input_buffer[1].y
	deli(player.input_buffer,1)
end


function InitTiles()
	for i=MX,15+MX do
		for k=MY,15+MY do
			SetPlayerStart(i,k)
			SetTiles(i,k)
		end
	end
end

LVL_TT=0--lvl transition timer
LVL_T=false
LVL_TD=0.3
function LoadNextLVL()
	--timer
	if not LVL_T then
		if LVL_TT==0 then
			LVL_TT=t()
			LVL_T=true
			sfx(1)
		end
	end
	local timer=t()-LVL_TT
	--animation
	if (timer<LVL_TD) then
		line_fade()
	end
	--game_logic
	if (timer<LVL_TD/4) then
		for p in all(Players) do
			p.can_move=false
		end
	elseif (timer<LVL_TD) then
		Paused=true
	else
--lvl shift
		LoadLVL(This_LVL+1)
		ResetOffset=t()%ResetTime
		Paused=false
		LVL_T=false
		LVL_TT=0
		if (#Players==0) then
			reload()
			InitTiles()
		end
		PlayWelcomeText()
	end
end

function LoadLVL(num)
	if (num ~= nil) then
		This_LVL=num
	else
		BatteryWarning=true
		Doom=Doom-Doom_I/5
		reload()
		reset()
		New_Defaults()
	end
	if (This_LVL>15) then
		Doom_I=50
		Doom=min(50,Doom)
	end
	LVL_ENDED()
	MapInit()
	Players={}
	Tiles={}
	NPCs={}
	Players_Start={}
	InitTiles()		
	InitNPCs()
	init_★()
end

function LVL_ENDED()
	if (SpokeToEO) SpokeToEO=false
end
-->8
--pixel fx

MONO_COLOR=true
Shift_Filter=true

--filters

function MonoPXL(x,y)
	local p = pget(x,y)
	if (p==0 or p==14) then
		pset(x,y,0)
	else
		pset(x,y,7)
	end
end

function DarkPXL(x,y)
	local p = pget(x,y)
	if(p==0 or p==14) then
		pset(x,y,0)
	elseif(p>5 and p<7) then
		pset(x,y,6)
	else
		pset(x,y,5)
	end
end

function DarkFilter()
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

function GameBoyFilter()
	pal({[0]=0,3,131,11,138,139,134,135,136,137,138,139,140,141,142,143},1)
	for p=0,15 do
		if(p==0 or p==14) then
			pal(p,0) --floor
		elseif(p>5 and p<7) then
			pal(p,4) --body
		elseif(p>8 and p<13) then
			pal(p,5) --highlights
		else
			pal(p,2) --shadows
		end
	end
end

CustomPalette=0

function MonoColor()
	DefinePalette()
	CustomPalette=1
	MonoFilter()
end

function DualColor()
	DefinePalette()
	CustomPalette=2
	DarkFilter()
end

function GameBoyColors()
	CustomPalette=3
	GameBoyFilter()
end
function MonoFilter()
	for p=0,15 do
		if (p==0 or p==14) then
			pal(p,0)
		else
			pal(p,6)
		end
	end
end

function DefinePalette()
		pal({[0]=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15},1)
end

function NoFilter()
	for p=0,15 do
		pal(p,p)
	end
end

LastPXL=0
LastPXL2=0
function shift_pxl(x,y)
	local p = pget(x,y)
	pset(x,y,LastPXL2)
	LastPXL2=LastPXL
	LastPXL=p
end

function FunMirror(x,y,bm)
	local t,b,a,cx,cy,dx,dy = true,0,1,x,y,-1,-1
	while (b<bm) do
		--add to distance
		if (b%2==0) then a=a+1 end
		--update instance
		t=not t
		if (t) then dx=dx*-1 end
		if (not t) then dy=dy*-1 end
		for _=0,a-2 do
			--update position
			if (t) then cx=cx+dx end
			if (not t) then cy=cy+dy end
			shift_pxl(cx,cy)
		end
		b=b+1
	end
end

function Static(ax,ay,w,h,c)
	for _=1,c do
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
	if (Portal_Activated) then
		sfx(0,0)
	 pfx=t()
	 Portal_Activated=false
	 should_pfx=true
	end
	if (should_pfx) then
		fxt=(t()-pfx)*speed
		if (fxt<1) then
		 CircleFillB(ax+4,ay+4,fxt*8,c,c2)
		 hide_player=true
		elseif (fxt<2) then
			CircleFillB(ax+4,ay+4,(2-fxt)*8,c,c2)
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
	local timer=(t()-LVL_TT)
	for i=0,128 do
		for k=0,128,1+LVL_TD-timer do
			if (k%5!=0) then
		 	pset(i,k,0)
			else
				DarkPXL(i,k)
			end
		end
	end
end

-->8
--player
Players={}
Players_Start={}
PlayerSprites={1,17}

function SetPlayerStart(i,k)
	local firstLoad=true
	if #Players > 0 then
		firstLoad=false
	end
	local d=mget(i,k)
	local e=false
	local mapx=i*8
	local mapy=k*8
	if firstLoad then
		for s in all(Players_Start) do
			if (mapx==s.x and mapy==s.y) then
				return
			end
		end
	end
	if (d>=1 and d<=8) then
		e=true
		if not firstLoad then
			add(Tiles,NewFloorTile(mapx,mapy))
		else
			add(Players,NewPlayer((i-MX)*8,(k-MY)*8,d-1))
		end
	elseif (d>=17 and d<=24) then
		e=true
		if not firstLoad then
			add(Tiles,NewFloorTile(mapx,mapy))
		else
			add(Players,NewPlayer((i-MX)*8,(k-MY)*8,d-17))
		end
	end
	if e then
		add(Tiles,NewFloorTile(mapx,mapy))
		add(Players_Start,{x=mapx,y=mapy})
	end
end

function NewPlayer(ax,ay,ad)
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

function UpdatePlayer()
	for player in all(Players) do
		portal_fx(player.x,player.y,12,player)
	end
	CombinePlayer()
	MovePlayers()
end

function CombinePlayer()
	for i,p1 in pairs(Players) do
		for k,p2 in pairs(Players) do
			if (i~=k) then
				if (p1.x==p2.x and p1.y==p2.y) then
					local p3=NewPlayer(p1.x, p1.y, max(0,min(p1.damage,p2.damage)
												 - (8-max(p1.damage,p2.damage))))
					del(Players,p1)
					del(Players,p2)
					add(Players,p3)
				end
			end
		end
	end
end

function MovePlayers()
	for _,player in pairs(Players) do
		local should_slerp = true
		if (player.can_move) then
			--grab input from buffer
			if #player.input_buffer>0 and not Collides(player,InputX,InputY) then
				RemoveFromBuff(player)
			else
				InputX=0
				InputY=0
			end
			--move
			if (not Collides(player,InputX,InputY)) then
				if abs(InputX)+abs(InputY)>0 then sfx(6,0) end
				player.di=PlayerMove(player,InputX,InputY)
			else
				player.di=Bump(player,InputX,InputY)
				OnPlayerCollide(player)
			end
		end
		if(should_slerp) then
			if Slerp(player) then player.can_move=true end
		end
		--die if necessary
		if player.damage>7 then del(Players,player) end
	end
end

function OnPlayerCollide(player)
	local npc = IsNPC(player.x+InputX*8,player.y+InputY*8)
	if npc~=nil then
		player.ox,player.oy=0,0
		ShouldSlerp=false
		if npc.dialogue ~=nil then
			ClickText(npc:dialogue())
		end
		if npc.push ~=nil then
			npc:push(InputX,InputY)
		end
	end
end

--player slide interpelate
function Slerp(p)
	local o=SlerpMovement(p,InputX,InputY, Input_Delay)
	p.xo=o.x
	p.yo=o.y
	--if move ended, call move end
	if(o.done) then OnPlayerMoved(p) end
	return o.done
end

-- when animation done
function OnPlayerMoved(p)
	Teleport(p)
	local t=GSIFO(p)
	--if corrupt tile
	if(t==36) then
		QueCorrupt(10)
		sfx(8,0)
	end
	Pickup(p)
	--move enemies if is last player
	if (p==Players[#Players] and (InputX!=0 or InputY!=0)) MoveEnemies()
end

function Teleport(p)
	--get cur tile
	local ntile=GSIFO(p,0,0)
	local pos=OtherPortalPosition(p,ntile)
	p.x=pos.x
	p.y=pos.y
	if (pos.moved)then
		Portal_Activated=true
		TakeDamage(p,1)
	end 
end

function Pickup(player)
	for tile in all(Tiles) do
		if tile.type =="pickable" then
			if tile.x-MX*8==player.x and tile.y-MY*8==player.y then
				tile:pickup()
				del(Tiles,tile)
			end
		end
	end
end

--draw player
function DrawPlayer()
	for player in all(Players) do
		if (not player.hidden) then
			spr(
				player.damage+
				GetFrame(PlayerSprites,2)
				         ,player.x+player.xo
				         ,player.y+player.yo)
		end
	end
end

--player move
function PlayerMove(player,x,y)
	if abs(x)>0 or abs(y)>0 then
		Doom-=0.25
		player.x+=8*x
		player.y+=8*y
		--direction during movement
		player.dx=x
		player.dy=y
		player.can_move=false
		player.move_started=t()
	end
	return 8
end

function Bump(player,x,y)
	player.dx=x
	player.dy=y
	player.can_move=false
	player.move_started=t()
	return -2
end

function TakeDamage(player,dmg)
	sfx(2,0)
	player.damage=player.damage+dmg
	player.damage=min(player.damage,8)
end
-->8
--tiles

Tiles={}

function SetTiles(i,k)
	if TileExists(i,k) then return end
	local tile=mget(i,k)
	if (tile==43) then
		add(Tiles,NewFloorTile(i*8,k*8))
		add(Tiles,NewLvlButton(i*8,k*8))
	elseif (tile==36) then
		add(Tiles,NewCoreTile(i*8,k*8))
	elseif (tile==37) then
		add(Tiles,NewCoreSlot(i*8,k*8))
	elseif (tile==38) then
		add(Tiles,NewFloorTile(i*8,k*8))
	elseif (tile==57) then
		add(Tiles,NewFloorTile(i*8,k*8))
		add(Tiles,NewBattery(i*8,k*8))
	end
end

function TileExists(i,k)
	for tile in all(Tiles) do
		if tile.x/8==i and tile.y/8==k then return true end
	end
	return false
end

function CheckFinished()
	local b,c = true,0
	for tile in all(Tiles) do
		if (tile.type == "level_btn") then
			c+=1
			local tb = tile:is_pressed()
			b=b and tb
		end
	end
	--if all lvl btns are pressed
	if (b and c>0) LoadNextLVL()
end

function DrawTiles()
	for tile in all(Tiles) do
		spr(tile.s,tile.x-MX*8,tile.y-MY*8)
		if (tile.draw!=nil) tile:draw()
	end
end

function DrawTileEffects()
	for tile in all(Tiles) do
			if tile.draw_effect~=nil then
				tile:draw_effect()
			end
	end
end

--portal variables
PortalPosition1={x=px,y=py}
PortalPosition2={x=px,y=py}
CPortal=false

--portal color
function PortalColor(n)
	local p1c=12
	local p2c=9
	if (n==0) then
		if (CPortal) then return p1c
		else return p2c end
	else
		if (CPortal) then return p2c
		else return p1c end
	end
end

--get other portal pos
function OtherPortalPosition(player, portal)
	local op = portal
	local is_portal=false
	if (op==33) then
		op=32
		is_portal=true
		CPortal=false
	elseif (op==32) then
		op=33
		is_portal=true
		CPortal=true
	end
	if (is_portal) then
		for i=MX,MX+15 do
			for k=MY,MY+15 do
				if (mget(i,k) == op) then
					local p1x,p1y=(i-MX),(k-MY)
					PortalPosition1.x=p1x*8
					PortalPosition1.y=p1y*8
					PortalPosition2.x=player.x
					PortalPosition2.y=player.y
					return {x=p1x*8,y=p1y*8,moved=is_portal}
				end
			end
		end
	end
	return {x=player.x,y=player.y,moved=is_portal}
end

function NewFloorTile(ax,ay)
	return{
		x=ax,
		y=ay,
		s=9,
	}
end

function NewBattery(ax,ay)
	return{
		x=ax,
		y=ay,
		s=57,
		type="pickable",
		pickup=function(s)
			Doom=Doom_I
			sfx(7,0)
		end
	}
end

function NewCoreTile(mx,my)
	return{
		x=mx,
		y=my,
		s=36,
		draw_effect=function(self)
			local rx,ry=self.x-MX*8,self.y-MY*8
			for i=0,t()%2 do
				FunMirror(rx+3,ry+3,(3.5+CorruptQue/8)*8)
			end
		end
	}
end

function NewCoreSlot(mx,my)
return{
		x=mx,
		y=my,
		s=37,
		type="level_btn",
		draw=function(s)
			if (not s:is_pressed()) then
				local x,y=s.x-MX*8,s.y-MY*8
				Static(x+2,y+2,4,4,25)
			end
		end,
		is_pressed=function(s)
			for npc in all(NPCs) do
				if (npc.type=="core") then
					if (npc.x+(npc.xo or 0) == s.x-8*MX and
								npc.y+(npc.yo or 0)== s.y-8*MY) then
						return true
					end
				end
			end
			return false
		end
	}
end

function NewLvlButton(mx,my)
	return{
		x=mx,
		y=my,
		s=43,
		type="level_btn",
		is_pressed=function(self)
			for p in all(Players) do
				if (p.x+p.xo == self.x-8*MX and
								p.y+p.yo == self.y-8*MY) then
					return true
				end
			end
			for n in all(NPCs) do
				n.xo=n.xo or 0
				n.yo=n.yo or 0
				if (n.x+n.xo == self.x-8*MX and
							 n.y+n.yo == self.y-8*MY) then
					return true
    end
   end
			return false
		end
	}
end
-->8
--utils + corruption

function Longest(tbl)
	local bestLen=0
	for t in all(tbl) do
		if #t>bestLen then
			bestLen=#t
		end
	end
	return bestLen
end

--corruption
CorruptQue=0
CorruptSpeed=1 --corrupt speed

function ManageCorrupt()
	if (CorruptQue<=0) then
		CorruptQue=0
		return
	end
	CorruptNow(min(CorruptSpeed,CorruptQue))
	CorruptQue=CorruptQue-CorruptSpeed
	CorruptSpeed=CorruptSpeed+1
	InitTiles()
end

function QueCorrupt(x)
	if (x==nil) then x=0 end
	CorruptQue=CorruptQue+x
	CorruptSpeed=1
end

--corrupt now
function CorruptNow(x)
	for _=0,x do
		repeat
			local mem=rnd(0x8000)
			Doom=Doom-0.05
			BatteryWarning=true
		until
			--make mem target only
			--visual aspects
			(0x5f00<=mem and mem<=0x5f1f)
			--sound
			or (0x5f31<=mem and mem<=0x5f35)
			-- or (mem<=0x42ff and mem>0x30ff)
			-- or(mem>=0x6000 and mem<0x7fff)
			or (mem<=0x2fff) --0x1000 not touch map
		-- modify memory
				poke(mem,rnd(0x100))
	end
end

function Occupied(ax,ay)
	for player in all(Players) do
		if (player.x == ax and player.y == ay) then return true end
	end
	for n in all(NPCs) do
		if (n.x == ax and n.y == ay) then return true end
	end
	return false
end

-- top-left reset timer
SystemTimer=t()
ResetOffset=0
ResetTime=10
function SystemReset()
	SystemTimer=t()-ResetOffset
	SystemTimer=SystemTimer%ResetTime
	if (SystemTimer<0.01) then
		reload()
		reset()
		New_Defaults()
		Tiles={}
		--p_start_pos={}
		local tnpc={}
		for npc in all(NPCs) do
			if (npc.push ~= nil) then
				add(tnpc,npc)
			end
		end
		NPCs={}
		for npc in all(tnpc) do
			add(NPCs,npc)
			add(Tiles,NewFloorTile(npc.x-8*MX,npc.y-8*MY))
		end
		InitTiles()
		InitNPCs()
	end
end

--move collision
function Collides(player,dx,dy)
	local fdx,fdy=8*dx,8*dy
	--if upcoming has solid flag
	local a = fget(GSIFO(player,dx,dy),0)
	--if player out of bounds
	local b = InB(player,fdx,fdy)
	local c = false
	local npc= IsNPC(player.x+fdx,player.y+fdy)
	if (npc ~= nil) then
		c=true		
		if (npc.type=="enemy"and player.type=="player") then
			TakeDamage(player,npc.atk)
			npc:move()
		end
	end
	return (a or not b or c)
end

--get sprite in front of player
function GSIFO(player,dx,dy)
	dx,dy=dx or 0,dy or 0
	return mget(MX+player.x/8+dx,MY+player.y/8+dy)
end

--in bounds detection
function InB(player,dx,dy)
	local a=false
	local b=false --for bounds
	local x,y = player.x+dx,player.y+dy
	if 0<=x and 128>x then
		a=true
	end
	if 0<=y and 128>y then
		b=true
	end
	return a and b
end

--generate offset
function SlerpMovement(player,x,y,dur)
	local done = false
	if (not player.can_move) then
		local dt = t()-(player.move_started or t())
		player.dx=player.dx or 0
		player.dy=player.dy or 0
		player.xo=-player.dx*player.di+player.di*dur*dt*player.dx
		player.yo=-player.dy*player.di+player.di*dur*dt*player.dy
		if (dt >= 1/dur) then
			done=true
			player.xo=0
			player.yo=0
		end
	end
	return {x=player.xo,y=player.yo,done=done}
end

--animation
function GetFrame(arr,animSpeed)
	return arr[flr(t()*animSpeed%#arr)+1]
end

--drawing
function CircleFillB(x,y,rad,c1,c2)
	circfill(x,y,rad,c1)
	circ(x,y,rad,c2)
end

function MapInit()
	local l=Levels[This_LVL]
	MX=l*16-16
	MX=MX%128
	MY=flr(l/9)*16
end
-->8
--npcs

NPCs={}

function InitNPCs()
	for i=MX,15+MX do
		for k=MY,15+MY do
			GetNPCs(i,k)
		end
	end
end

function GetNPCs(i,k)
	local npc=mget(i,k)
	local noc=not Occupied((i-MX)*8,(k-MY)*8)
	if npc==34 then
		add(NPCs,NewEB((i-MX)*8,(k-MY)*8))
			for io=0,1 do
				for ko=0,1 do
					add(Tiles,NewFloorTile((i+io)*8,(k+ko)*8))
				end
			end
	elseif (npc==53 or npc==54) and noc then
		add(Tiles,NewFloorTile(i*8,k*8))
		if noc then add(NPCsNewBugg((i-MX)*8,(k-MY)*8,53)) end
	elseif((npc==55 or npc==56) and noc) then
		add(Tiles,NewFloorTile(i*8,k*8))
		if noc then add(NPCs,NewBunny((i-MX)*8,(k-MY)*8,55)) end
	elseif(npc==38 and noc) then
		add(Tiles,NewFloorTile(i*8,k*8))
		if noc then add(NPCs,NewCore((i-MX)*8,(k-MY)*8)) end
	end
end

function DrawNPCs()
	for npc in all(NPCs) do
		npc:draw()
	end
end

function UpdateNPCs()
	for npc in all(NPCs) do
		npc:update()
	end
end

function IsNPC(mx,my)
	for npc in all(NPCs) do
		npc.w=npc.w or 1
		npc.h=npc.h or 1
		if ((mx>=npc.x and mx<npc.x+npc.w*8)
		 and (my>=npc.y and my<npc.y+npc.h*8)) then
			return npc
		end
	end
	return nil
end

function MoveEnemies()
	for npc in all(NPCs) do
		if (npc.type == "enemy") then
			npc:move()
		end
	end
end

function NewEnemy(mx,my,as)
	return {
		x=mx,--pos
		y=my,
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
		local t=SlerpMovement(s,s.dx*8,s.dy*8,Input_Delay)
			s.xo=t.x
			s.yo=t.y
		end,
	}
end

function NewBug(mx,my,as)
	local bug = NewEnemy(mx,my,as)
	bug.mknew=0
	bug.update=function(s)
		local t=SlerpMovement(s,s.dx*8,s.dy*8,Input_Delay)
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
		if (not Collides(s,s.dx,s.dy)) then
			s.x+=s.dx*8
			s.y+=s.dy*8
			s.move_started=t()
		end
	end
	return bug
end

function NewBunny(ax,ay,as)
	local bunny = NewEnemy(ax,ay,as)
	bunny.mknew=0
	bunny.draw=function(s)
		spr(s.s+2*t()%2,s.x+s.xo,s.y+s.yo)
	end
	bunny.move=function(s)
		s.dx=flr(rnd(2.9)-1)
		s.dy=flr(rnd(2.9)-1)
		if (s.dx!=0) then s.f=(s.dx<0) end
			if (not Collides(s,s.dx,s.dy)) then
				if (s.dx!=0 or s.dy!=0) then
					if (s.mknew==2) then add(NPCs,NewBug(s.x,s.y,s.s)) end
					s.mknew=s.mknew+1
					s.mknew=s.mknew%3
				end
				s.x=s.x+s.dx*8
				s.y=s.y+s.dy*8
				s.move_started=t()
			end
		end
	return bunny
end

-- enlightened being
SpokeToEO=false
EBLines={}
function NewEB(mapX,mapY)
	return {
		s=34,
		type="enlightened",
		x=mapX,
		y=mapY,
		w=2,
		h=2,
		ox=0,
		oy=0,
		update=function(s)
			s.oy=sin(t()/3)+0.1
		end,
		dialogue=function(s)
			s.c=s.c or 0
			if (This_LVL == 3) then
			if (s.c==0) then
				mset(45,12,43)
				InitTiles()
				NoFilter()
				SpokeToEO=true
			end
				-- text on screen is upper/lowercase backwards :(
				if s.c==1 then
					return {"zzz..!▥  ","☉sight enhanced☉  "}
				end
				if s.c<3 then
					return {"hELLO THERE.", "oUR WORLD IS IN DANGER.", "wE NEED YOUR HELP STRANGER.","fREE US FROM THE CORRUPTION!"}
				end
				if s.c<4 then
				 return {"gODSPEED!","wE WILL REMAKE YOU", "wHEN WE MUST."}
				end
				if s.c>=4 then
					return {"i HAVE SAID EVERYTHING THERE IS TO SAY..."}
				end
			elseif (This_LVL == 15) then
				Doom_I=50
				Doom=min(Doom_I,Doom)
				return {"time is running short.","the battery is draining faster."}
			elseif (This_LVL >3) then
				return {"strange seeing","you again..."}
			end
			s.c=s.c+1
		end,
		draw=function(s)
		 spr(s.s,s.x+s.ox,s.y+s.oy,s.w,s.h)
		end,
	}
end

function NewCore(ax,ay)
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
		local t=SlerpMovement(s,s.dx*8,s.dy*8,Input_Delay)
		s.xo=t.x
		s.yo=t.y
	end
	core.move=function(s)
		if (not Collides(s,s.dx,s.dy)) then
			s.x=s.x+s.dx*8
			s.y=s.x+s.dy*8
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

NarratorSpeak={
	{{"where am i?"}},
	{{"why is","everything so","  pixelated?  "}},
	{{"who is this?..."}},
	{{""}},
}

function Dialogue()
	return NarratorSpeak[This_LVL]
end

--utils
Clicked=false
ShouldDrawBox=false --should draw
BBG=false
BoxCollapse=false --should bc
BowWidth=0
BoxHeight=0
BoxX=0
BoxY=0

BoxI=true --interactive
BoxC1=0 --black
Boxc2=6 --grey
BoxTXT={}

function PlayWelcomeText()
	MultiClickText(Dialogue(),nil,nil,nil,nil)
end

TextC=0
TextQueue={}
--multiple click_texts at once
function MultiClickText(txts,ai,ax,ay,abbg)
	for txt in all(txts) do
		add(TextQueue,{txt,ai,ax,ay,abbg})
	end
end

--text queue
function ManageQueue()
	-- for i=1,#TextQueue do
	-- 	local t = TextQueue[i]
	-- end
	if (not ShouldDrawBox and #TextQueue>0) then
		local i=TextQueue[1]
		ClickText(i[1],i[2],i[3],i[4],i[5])
		deli(TextQueue,1)
	end
end

function ParseDuringText()
	Paused=ShouldDrawBox
end

--enable click through text
function ClickText(txt,i,x,y,abbg)
	BoxTXT=txt
	BowWidth=4*Longest(txt)+4
	BoxHeight=10*#txt+2

	BoxX=x or ( 64-BowWidth/2 )
	BoxY=y or ( 64-BoxHeight/2 )
	BoxI=i or true
	if (abbg~=nil) then BBG=abbg end

	ShouldDrawBox=true
	BoxCollapse=false
end

--draw click through text
function DrawClickableText()
	if (not Clicked) then
		AnimatedBox(BoxTXT)
	end
end

CurrentBoxWidth=0
function AnimatedBox(tbl,i)
	if ShouldDrawBox then
		DrawBox(tbl,CurrentBoxWidth,BoxHeight,i)
	end
	local spd=2+Longest(tbl)/20
	if (not BoxCollapse) then
		if (CurrentBoxWidth<BowWidth) then CurrentBoxWidth+=spd end
		if (CurrentBoxWidth>BowWidth) then CurrentBoxWidth=BowWidth end
	else
		if (CurrentBoxWidth>0) then
			CurrentBoxWidth=CurrentBoxWidth-spd
		else
			ShouldDrawBox=false
		end
	end
end

function DrawBox(tbl,w,h,i)
	local bo=BowWidth/2-w/2
	rectfill(
		BoxX+bo,
		BoxY,
		BoxX+w+bo,
		BoxY+h,
		BoxC1
	)
	rect(
		BoxX+bo,
		BoxY,
		BoxX+w+bo,
		BoxY+h,
		Boxc2
	)
	local o=3
	for txt in all(tbl) do
		local txt_w=#txt*4
		if (txt_w+2<=w) then
			print(txt,bo+BoxX+w/2-txt_w/2+1,BoxY+o+1)
		end
		o+=10
	end
	if (BoxI and BowWidth<=w) then
		local iconx, icony= bo+BoxX+w-10,BoxY+h
		rectfill(iconx-1,icony-1,iconx+7,icony+5,0)
		print("❎",iconx,icony,6)
	end
end

function Bar(x,y,w,h,c1,c2,p)
	local pe=min(p,1)
	if (pe<0) pe=0
	rectfill(x+1,y,x+(w-1),y+(h-1),0)
	rectfill(x+1,y,x+(w-1)*pe,y+(h-1),c2)
	rect(x,y,x+w-1,y+h,c1)
end

function ArrowFill(x,y,p)
	local pe=min(p,1)
	if (pe<0) then pe=0 end
	rectfill(x,y,x+7,y+7,0)
	rectfill(x+8-7*min(1,pe*2),y+6,x+7,y+7,12)
	rectfill(x,y+7,x+1,y+7-7*min(1,max(0,(pe*2-.75))),12)
	rectfill(x+7*(min(1,max(0,(pe*2-1)))),y+4,x,y,12)
	spr(39,x,y)
end

function DrawBattery(x,y,p)
	if (not p) then p=0 end
	if (p<0) then p=0 end
	if (p>1) then p=1 end
	c=11
	c2=3
	if (p<0.5) then
		c=8
		c2=2
	end
	rect(x+3,y,x+4,y,5)
	rectfill(x+2,y+1,x+5,y+7,c2)
	local height=y+8*(1-p)
	if (height<8) then rectfill(x+2,height+1,x+5,y+7,c) end
end

BatteryWarning=false
BatteryWarnTime=-1

function DrawBatteryWarning(x,y)
	rectfill(x+1,y-1,x+6,y+8,8)
end

function DrawUI()
	if (BatteryWarning) then
		BatteryWarning=false
		BatteryWarnTime=t()
	end
	if (t()-BatteryWarnTime<0.3) then
	if (20*t()%2>=1) then
				DrawBatteryWarning(120,1)
	end
	end
	DrawBattery(120,1,max(0,Doom)/Doom_I)
	ArrowFill(0,1,SystemTimer/ResetTime)
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
0000000000000000eeeeeea0daeeeeee9abcdf010c51c1c0eec1cceededdeedd00000000eeeeeeeeeeeeeeee0000000000000000000000000000000000000000
0000000000000000eeeeeea00aeeeeee234567890c1c15c0eecc1ceededdeddd00000000eeeeeeeeeeeeeeee0000000000000000000000000000000000000000
099999900cccccc0eeeeee9aa9eeeeeeabcdf0120cd15dc0eecccceededddddd00000000eeeeeeeeeeeeeeee0088880000000000000000000000000000000000
1111111111111111eeeeeee99eeeeeee3456789a0cccccc0eeeeeeeedeeeeedd00000000eeeeeeeeeeeeeeee0dddddd000000000000000000000000000000000
0000000000000000eeeeea9999aeeeeebcdf012300000000eeeeeeee0dddddd000000000eeeeeeeeeeeeeeee0000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeea9e99e9aeeee00000000eeeee8e8eeeeeeeeee8ee8eeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000
eee66666666665eeeeeeae9999eaeeee00000000eeee8e8eeeeee8e8ee8ee8eeee8ee8eeeeeeeeee000000000000000000000000000000000000000000000000
ee6666666666665eeeee9ee99ee9eeee00000000eeeea8aeeeee8e8eeea88aeeee8ee8eeeee55eee000000000000000000000000000000000000000000000000
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
1010190a1a101010190a0a0a0a1a10101010101010101010101010101010101010101010100a0a0a0a10101010101010101010101010101010101010101010101010190a0a0a1a1010101010101010101010101010101010190a1a10101010101010101010101010101010101010101010101010101010101010101010101010
10191d091c1a10191d090909091c1a101010101010101010101010101010101010100a101d090909091c100a1010101010101010190a0a0a0a1a10101010101010100d2409251c1a1010190a0a0a0a1a1010190a1a1010100d390b10101010101010101010101010101010101010101010101010101010101010101010101010
100d0909090b100d0909090909090b1010101024101010101010101010101010101d090e0909090909090e091c101010101010100d252525250b10101010101010100d090926090b10100d250909090b10100d011c1a10100d091c1a101010101010101010101010101010101010101010101010101010101010101010101010
191d0909091c1a0d0909010909090b1010101010101010190a0a0a0a0a0a0a1a0d0939090925090925090939090b1010101010191d090909091c1a101010101010100d090909091c0a0a1d260935090b10100d09090b10100d09090b190a0a1a1010101010101010101010101010101010101010101010101010101010101010
0d09090909090b0d0909092109090b1010101010190a0a1d090909090909250b101e090f0909090909090f091b1010101010100d0909090935090b101010101010191d0935090909090909090909090b1010291e091c0a1a291e2b1c1d09090b1010101010101010101010101010101010101010101010101010101010101010
0d09092b09090b0d0909090909090b10101010191d09090909091b0c0c0c0c2a10100c101e090101091b100c101010101010100d0909090909090b1010101010100d090909091b0c0c0c0c1e2109090b1010100d0909091c0a1d0909092b090b1010101010190a0a0a0a1a101010101010101010101010101010101010101010
0d09090909090b291e090909091b2a101010100d0909090109090b101010101010101010101e09091b101010101010101010100d0926262626090b1010101010100d09091b0c2a190a0a1a290c0c0c2a101010291e090909090909091b0c0c2a10101010100d010909090b101010101010101010101010101010101010101010
0d09090909090b10290c0c0c0c2a101010190a1d090909091b0c2a101010101010101010100d09090b101010101010101010100d0909090909090b1010101010100d2b1b2a10191d09351c1a10190a1a10190a0a1d090909090909091c0a1a1010101010100d092223090b101010101010101010101010101010101010101010
0d09240909090b1010190a0a0a1a1010191d090909091b0c2a10101010101010101010190a1d09091c0a1a1010101010101010291e360909091b2a1010101010100d210b10191d090909090b100d350b100d01090909093509090909092b0b1010101010100d093233090b101010101010101010101010101010101010101010
0d09090909090b190a1d0909091c0a1a0d09090909090b1010101010101010101010191d0909090909091c1a10101010101010100d090909010b10101010101010290c2a100d090921091b2a10290c2a10290c0c1e0909090909091b0c0c2a1010101010100d0909092b0b101010101010101010101010101010101010101010
0d09090922230b0d090909090909090b0d0926091b0c2a10102410101010101010100d09092609092609090b1010101010101010290c0c0c0c2a10101010101010190a1a10291e0909010b10101010101010190a1d0909090909091c0a0a1a101010101010290c0c0c0c2a101010101010101010101010101010101010101010
0d09090932330b0d2009092b0909240b291e39090b10101024241010101010101010291e0909090909091b2a1010101010101010101010101010101010101010100d350b1010290c0c0c2a10190a1a1010100d010909091b1e09090909090b101010101010101010101010101010101010101010101010101010101010101010
291e0921091b2a0d090909090909090b10290c0c2a1010101010101010101010101010291e091b1e091b2a100a0a1a101010101010101010101010101010101010290c2a190a1a190a1a10100d370b101010291e091b0c2a291e0909092b0b101010101010101010101010101010101010101010101010101010101010101010
100d0909090b10290c1e0939091b0c2a10101010101010101010101010101010101010100d090b0d090b100d22090b101010101010101010101010101010101010190a1a0d350b0d200b1010290c2a10101010290c2a190a0a1d090909090b101010101010101010101010101010101010101010101010101010101010101010
10291e091b2a101010290c0c0c2a101010101010101010101010101010101010101010100d2b0b0d2b0b100d09090b1010101010101010101010101010101010100d350b290c2a290c2a1010101010101010101010100d390909091b0c0c2a101010101010101010101010101010101010101010101010101010101010101010
1010290c2a10101010101010101010101010101010101010101010101010101010101010290c2a290c2a10290c0c2a101010101010101010101010101010101010290c2a101010101010101010101010101010101010290c0c0c0c2a101010101010101010101010101010101010101010101010101010101010101010101010
__sfx__
d60200002505725057250570d0070c0070c0070c0070c0070c0070c0070b0070b0070b0070c0070d0070e0070f007110071200713007160071800715007120070e0070a007010070000700007000070000700007
560200002f2512e2712c2712a26129261272612526122251202511f2511e2611d2621b2521a2421924217242152421424212241112410f2410e2310d2310c2310c2310b2410a2410925108262072720627205272
a10300002165324653226531c6531d65326603006032a60300603006032a6030060326603006032160315603126031360300603126030060313603196031e6031f6031e6031c6031960315603136031260310603
0a0e0000165551b5550050521555005052655500505295550050500505295550050526555005052255515555135551455500505185551c5552055500505225550050500505005050050500505005050050500505
3e1100001c7521f752207522275224752007021c7521a7021b7520470219752007021c7521d7521e752007022575222752207521d752007021b7021b752197521675218752007020070200702007020070200000
a40800001d6511a64118631166111f6011e6011c6011c6011a6011a6011a6011a6011c6011c6011c6011c60100601006010060100601006010060100601006010060100601006010060100601006010060100601
100500001e0441e0141e0040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004
21060000317563e756000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
47020000172531f253152531e25313253192531a253122531a2531525313253062031f2031f20302203102030f2032520325203002031d2031d20310203222032320324203252032620317203172031520313203
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b91400001715117157171571714217147171471714117137171371713217127171271712117117171121711715157151511515715147151421514715147151311513715137151221512715127151111511715111
b91400000000012152121571215712141121471214712142121371213712131121271212712122121171211712111101571015710152101471014710141101471013710132101371012710127101271011710117
b91400001315213157131511314713142131471314113137131321313713121131221312713117131111311712152121571215112147121421214712141121371213212137121211212712122121171211112117
b91400000e1570e1510e1570e1420e1470e1410e1470e1370e1370e1320e1270e1270e1270e1110e1170e1170d1570d1520d1570d1470d1470d1410d1470d1370d1370d1320d1270d1270d1270d1110d1170d117
b9140000210412104721047210421c0471c0471c0471c042230412304723047230471a0411a0411a0471a0471f0421f0471f0471f047170421704717047170411a0471a0471a0471a0421c0471c0471c0421c047
d1140000217522175521755217521c7551c7551c7521c755237552375223755237551a7521a7551a7551a7521f7551f7551f7521f755177551775217755177551a7521a7551a7551a7521c7551c7551c7521c755
8b1400000d1650e16510165121650d1650e16510165121650d1650e16510165121650d1650e16510165121650d1650e16510165121620d1650e16510165121610d1650e16510165121620d1650e1651016512161
69140000210552105121055210511c0551c0511c0551c0532305526052280552a0551a0511a0551a0531a0551f055210522305526055170511705517051170551a0551c0521f05523052210551e0522305525052
bd1400002a74025740287432674028742287422a7402574026740287402a7402b7422d7402b7402d7422a740257411e7402174025742267402674028742257402374021741237402574023742217402374225740
b91400002a74225745217422174223740257452874026740267402574021742217421a7401a7421a7421a74215745197421e7451c7451f745237421e7451f745217401f745217452374026740257422374221742
b11400000e1570e1570e1550e1450e1470e1470e1470e1371a1311a1371a1271a1271a1271a1171a1171a1170d1570d1570d1550d1450d1470d1470d1470d1371913119135191251912519125191151911519115
b114000013157131571315513145131471314713147131371f1311f1371f1271f1271f1271f1171f1171f11712157121571215512145121471214712147121371e1311e1351e1251e1251e1251e1151e1151e115
7014000025732257321e73225732257321e7321e7321e732267322573223732257322673225732237322173225731257311e73225732257321e7321e7321e7322573523733217351f7331e7351c7331a7341a732
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

