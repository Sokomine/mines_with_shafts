
local cid_mines = {};

cid_mines.c_ignore       = minetest.get_content_id('ignore');
cid_mines.c_air          = minetest.get_content_id('air');

-- basic material used for the tunnels
cid_mines.c_wood         = minetest.get_content_id('default:wood');
cid_mines.c_fence        = minetest.get_content_id('default:fence_wood');
cid_mines.c_torch        = minetest.get_content_id('default:torch');
cid_mines.c_rail         = minetest.get_content_id( mines_with_shafts.rail_typ_name );

-- basic additional material used for the shafts
cid_mines.c_mineladder   = minetest.get_content_id('mines_with_shafts:ladder');
cid_mines.c_rope         = minetest.get_content_id('mines_with_shafts:rope');
cid_mines.c_meselamp     = minetest.get_content_id('default:meselamp');

-- node types that force mine shafts to end there (floodings are still possible)
cid_mines.c_lava         = minetest.get_content_id('default:lava_source');
cid_mines.c_lava_flowing = minetest.get_content_id('default:lava_flowing');
cid_mines.c_water        = minetest.get_content_id('default:water_source');
cid_mines.c_cobble       = minetest.get_content_id('default:cobble');


mines_with_shafts.count_daylight = function( pos )
	local anz_daylight = 0;
	for x=pos.x-1,pos.x+1 do
		for z=pos.z-1,pos.z+1 do
			local light = minetest.get_node_light({x=x, y=pos.y, z=z}, 0.5);
			if( light and light==15 ) then
				anz_daylight = anz_daylight+1;
			end
		end
	end

	return anz_daylight;
end


mines_with_shafts.get_avg_surface_height = function( minp, maxp, pos, range, heightmap )
	local sum_height = 0;
	local anz_height = 0;
	for x=math.max( minp.x, pos.x-range ), math.min( maxp.x, pos.x+range ) do
	for z=math.max( minp.z, pos.z-range ), math.min( maxp.z, pos.z+range ) do
		local height = heightmap[(z-minp.z)*80+(x-minp.x)+1];
		-- only count the borders
		if( height>minp.y and height>-1 and (x==pos.x+range or z==pos.z+range or x==pos.x-range or z==pos.z-range)) then
			sum_height = sum_height + height;
			anz_height = anz_height + 1;
		end
	end
	end
	-- unable to determine height
	if( anz_height < 1 ) then
		return -64000;
	end
--print('anz_height: '..tostring( anz_height )..' res: '..tostring( math.floor( sum_height / anz_height +0.5 ))..' for '..minetest.pos_to_string({x=pos.x,y=math.floor( sum_height / anz_height +0.5 ), z=pos.z}));
	return math.floor( sum_height / anz_height +0.5 );
end

-- TODO: actually create convincing, random mines
mines_with_shafts.create_mine = function( minp, maxp, data, param2_data, a, heightmap )
	local pos = {x=minp.x+40,y=minp.y+40,z=minp.z+40,bsizex=100,bsizez=1};
	local extra_calls_mines = {mines={}, schems={}};

	-- initialize pseudorandom number generator
	-- TODO: check for better ways to init it
	local pr = PseudoRandom( pos.x * 64000 + pos.z );
	-- make sure not too many mines get generated
	if( pr:next(1,10)>3 ) then
		return extra_calls_mines;
	end
--TODO local i2=math.random(1,10); for i=1,i2 do pr:next(1,pr:next(2,100)); end

	local surface_height = 1;
	-- this is the level that (may) contain the surface
	if( minp.y <0 and maxp.y >0 ) then
--		surface_height = mines_with_shafts.get_avg_surface_height( minp, maxp, pos, 1, heightmap );
		for h=maxp.y,0 do
			if( mines_with_shafts.count_daylight( {x=pos.x, y=h, z=pos.z})>3) then
				surface_height = h;
			end
		end
		if( surface_height < 1 ) then
			surface_height = 1;
		end
		local spos = {x=pos.x, y=surface_height, z=pos.z};
		while( mines_with_shafts.count_daylight( spos )<4 and spos.y<maxp.y) do
			spos.y = spos.y+1;
		end
		surface_height = spos.y;
		-- the schematic for the mining tower will be placed later on (after voxelmanip has been dealt with)
		table.insert( extra_calls_mines.schems,  {x=pos.x-5, y=surface_height-6, z=pos.z-5, file='mining_tower_1_7_90'});
	end

	-- the main level may have levels of tunnels above and below it;
	-- each mine has its own deterministic value (else we get into trouble with chunks generated below or above)
	local main_level_at = pr:next( -128, -50 );
	-- make sure all levels are at heights that are multitudes of 10
	main_level_at = main_level_at - (main_level_at%10) +5;

	-- that part of the vertical shaft that goes through this chunk may not be longer than the vertical chunk size
	local y_start = math.min( maxp.y, surface_height );
	local y_end   = math.max( minp.y, main_level_at );
	local vlength = math.min( maxp.y-minp.y, y_start - y_end);

	-- actually place the VERTICAL shaft
	local vpos = {x=pos.x, y=y_start, z=pos.z};
	mines_with_shafts.place_mineshaft_vertical(minp, maxp, data, param2_data, a, cid_mines, vpos, vlength, extra_calls_mines );

	local npos = {x=pos.x, y=main_level_at; z=pos.z};
--	mines_with_shafts.create_branches_at_level( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, 1, 0 );

	local surface_level_at = pr:next( 0,30 );
	surface_level_at = surface_level_at - (surface_level_at%10) +5;
	for i=3,-3,-1 do
		npos.y = 15+i*5;
		local iteration_depth = 0;
		if( i==0 ) then
			iteration_depth = 0;
		elseif( i==1 or i==-1 ) then
			iteration_depth = 1;
		else
			iteration_depth = 2;
		end
		if( pr:next(1,5)<4 and npos.y<surface_level_at) then
			mines_with_shafts.create_branches_at_level( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, 1, iteration_depth );
		end
		npos.y = main_level_at +15+i*5;
		if( pr:next(1,5)<4 and npos.y<surface_level_at) then
			mines_with_shafts.create_branches_at_level( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, 1, iteration_depth );
		end
	end
		
--[[
	npos.y = surface_level_at+20;
	mines_with_shafts.create_branches_at_level( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, 1, 2 );
	npos.y = surface_level_at+10;
	mines_with_shafts.create_branches_at_level( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, 1, 1 );
	npos.y = surface_level_at;
	mines_with_shafts.create_branches_at_level( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, 1, 0 );
	npos.y = surface_level_at-10;
	mines_with_shafts.create_branches_at_level( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, 1, 1 );
	npos.y = surface_level_at-20;
	mines_with_shafts.create_branches_at_level( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, 1, 2 );
--]]
	return extra_calls_mines;
end


mines_with_shafts.create_branches_at_level = function( minp, maxp, data, param2_data, a, cid_mines, pos, extra_calls_mines, pr, primary_axis, initial_iteration_depth )
	mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, pos, extra_calls_mines, pr, 1, primary_axis, initial_iteration_depth );
	mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, pos, extra_calls_mines, pr,-1, primary_axis, initial_iteration_depth );
	-- smaller branches at the side
	if( primary_axis == 1 ) then
		primary_axis = 0;
	else
		primary_axis = 1;
	end
	mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, pos, extra_calls_mines, pr, 1, primary_axis, math.min(3,initial_iteration_depth+2 ));
	mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, pos, extra_calls_mines, pr,-1, primary_axis, math.min(3,initial_iteration_depth+2 ));
end




mines_with_shafts.create_branch = function( minp, maxp, data, param2_data, a, cid_mines, pos, extra_calls_mines, pr, d1, d2, iteration_depth )
	-- abort - do not create branches without limit
	if( iteration_depth > 3 ) then 
		return;
	end
	local l1=40;
	if(     iteration_depth==1 ) then
		l1 = 25;
	elseif( iteration_depth==2 ) then	
		l1 = 15;
	else
		l1 = 10;
	end
	-- branches at heigher iteration levels get shorter
	local length = 4*pr:next(1,math.max(1,l1));
	if( iteration_depth == 1 ) then
		length = length+(4+3);
	end

	-- create the main tunnel
	mines_with_shafts.place_minetunnel_horizontal(minp, maxp, data, param2_data, a, cid_mines, pos,  d1*length, d2, extra_calls_mines );


	-- if we went into z direction before, let the branches go into x direction (and vice versa)
	local nd2 = 0;
	if( d2==0 ) then
		nd2 = 1;
	end

	local last_right = true;
	local last_left  = true;
	local dist_last_shaft = 0;
	for i=4,length,4 do
		local p = pr:next(1,25);
		local npos = {x=pos.x, y=pos.y, z=pos.z};
		if( d2==1 ) then
			npos.x = pos.x+i*d1;
		else
			npos.z = pos.z+i*d1;
		end
		-- new branches at both sides
		if(     p==1 and not(last_right or last_left)) then
			mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, d1,    nd2, iteration_depth+1 );
			mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, d1*-1, nd2, iteration_depth+1 );
			last_right = true;
			last_left  = true;
		-- new branch at one side
		elseif( (p==2 or p==3) and not(last_left)) then
			mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, d1,    nd2, iteration_depth+1 );
			last_right = false;
			last_left  = true;
		-- new branch at the other side
		elseif( (p==4 or p==5) and not(last_right)) then
			mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, d1*-1, nd2, iteration_depth+1 );
			last_right = true; 
			last_left  = false;
		elseif( pr:next(1,6)>1 ) then
			last_right = false;
			last_left  = false;
		end

		dist_last_shaft = dist_last_shaft+1;
		if( iteration_depth==0 and p<=5 and dist_last_shaft>3 and pr:next(1,4)==1) then
--[[
			local shaft_at = {0,0,0,0,0};
			local vpos = {x=npos.x, y=npos.y+2, z=npos.z};
			local vlength = 12;
			if( pos.y-20>minp.y ) then --and pr:next(1,2)==1 ) then
				vlength = 22;
			end
			mines_with_shafts.place_mineshaft_vertical(minp, maxp, data, param2_data, a, cid_mines, vpos, vlength, extra_calls_mines );
			vpos.y = vpos.y-12;
			mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, vpos, extra_calls_mines, pr, d1, d2, 1 );
			if( vlength==22  ) then
				vpos.y = vpos.y-10;
				mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, vpos, extra_calls_mines, pr, d1, d2, 2 );
			end
--]]
			
--[[
			local vlength = 0;
			local y_start = npos.y+2;
			local vpos = {x=npos.x, y=npos.y+2, z=npos.z};
			for level=-2,2 do
				if( pr:next(1,3)~=3) then
					vpos.y = npos.y + level*10 +2;
					mines_with_shafts.create_branches_at_level( minp, maxp, data, param2_data, a, cid_mines, vpos, extra_calls_mines, pr, d2, pr:next(2,3) );

					if(     level==-2 ) then
						vpos.y  = npos.y+20;
						vlength = 20;
					elseif( level==-1 and vlength==0 ) then
						vpos.y  = npos.y+10;
						vlength = 10;
					elseif( level==1) then
						vlength = vlength + 10;
					elseif( level==2 ) then
						vlength = vlength + 10;
					end
				end
			end
			if( vlength > 0 ) then
				vpos.y = vpos.y+2;
				vlength = vlength +2;
				mines_with_shafts.place_mineshaft_vertical(minp, maxp, data, param2_data, a, cid_mines, vpos, vlength, extra_calls_mines );
			end
--]]
		end
		-- allow two branches in the same direction - but only rarely
		if( pr:next(1,5)==1 ) then
			last_right = false;
			last_left  = false;
		end
	end
end


-- set up metadata by calling on_construct;
-- also places schematics for mine entrances/mining towers
mines_with_shafts.handle_metadata = function( extra_calls )

	-- call on_construct for those nodes that need it
	for _,v in pairs( extra_calls.mines ) do
		if( v.typ and mines_with_shafts.deco[ v.typ ] and mines_with_shafts.deco[ v.typ ][5]) then
			local on_construct = mines_with_shafts.deco[ v.typ ][5];
			on_construct( {x=v.x, y=v.y, z=v.z} );
		end
	end

	local path = mines_with_shafts.modpath..'/schems/';
	for _,v in pairs( extra_calls.schems ) do
		if( v.file ) then
			minetest.place_schematic( {x=v.x, y=v.y, z=v.z}, path..v.file..".mts", "0", {}, true);
		end
	end

	-- TODO: fill chests, add text to signs
end


minetest.register_on_generated(function(minp, maxp, seed)
	
	-- TODO: for testing: create just *one* mine
--	if( minp.x<-80 or maxp.x>80 or minp.z<-80 or maxp.z>80) then return; end
	if( (minp.x%160)%2==1 or (minp.z%160)%2==1 ) then
		return;
	end

	-- limit height of the mines
	if(  minp.y < -128 or minp.y > 64) then
		return;
	end

	local vm;
	local a;
	local data;
	local param2_data;
	-- get the voxelmanip object
	local emin;
	local emax;
	-- if no voxelmanip data was passed on, read the data here
	if( not( vm ) or not( a) or not( data ) or not( param2_data ) ) then
		vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
		if( not( vm )) then
			return;
		end

		a = VoxelArea:new{
			MinEdge={x=emin.x, y=emin.y, z=emin.z},
			MaxEdge={x=emax.x, y=emax.y, z=emax.z},
		}

		data = vm:get_data()
		param2_data = vm:get_param2_data()
	end

	local heightmap = minetest.get_mapgen_object('heightmap');

	-- actually create the mine
	local extra_calls = mines_with_shafts.create_mine( emin, emax, data, param2_data, a, heightmap );


	-- store the voxelmanip data
	vm:set_data(data)
	vm:set_param2_data(param2_data)

	vm:calc_lighting( emin, emax);
        vm:write_to_map(data);
        vm:update_liquids();

	mines_with_shafts.handle_metadata( extra_calls );
end) 
