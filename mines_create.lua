
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



mines_with_shafts.get_mines_at = function( minp, maxp, check_range )
	if( true ) then return {{x=100,y=5,z=100, seed=100*64000+100}}; end
	local mine_positions = {};
if(true) then return {{x=-72,y=5,z=168, seed=-72*64000+168}}; end

	local chunk_size = maxp.x - minp.x;
	-- for now: no check for chunks in y direction
	local cy=0;
	for cx=-1*check_range,check_range do
	for cz=-1*check_range,check_range do

		local pos = { x=(minp.x+40+cx*chunk_size), y=20, z=(minp.z+40+cz*chunk_size) };
		if(   math.abs(pos.x)%3==0 and math.abs(pos.z)%3==0
		  and pos.x>=(minp.x+cx*chunk_size) and pos.x<=(maxp.x+cx*chunk_size) 
		  and pos.z>=(minp.z+cz*chunk_size) and pos.z<=(maxp.z+cz*chunk_size)) then
			mine_positions[ #mine_positions+1 ] = {x=pos.x,y=pos.y,z=pos.z, seed = pos.x * 64000 + pos.z};
		end
	end
	end
	return mine_positions;
end
	



mines_with_shafts.create_mine = function( minp, maxp, data, param2_data, a, heightmap, pos, extra_calls_mines )

	-- the main level may have levels of tunnels above and below it;
	-- each mine has its own deterministic value (else we get into trouble with chunks generated below or above)
	local pr = PseudoRandom( pos.seed );
	local main_level_at = pr:next( -128, -50 );
	-- make sure all levels are at heights that are multitudes of 10
	main_level_at    = main_level_at    -    (main_level_at%10) +5;

	local surface_level_at = pr:next( 20,30 );
	surface_level_at = surface_level_at - (surface_level_at%10) +5;

	local chunksize = maxp.x - minp.x + 1;

	-- this is a mapchunk that contains part of the vertical shaft
	if(   pos.x >= minp.x and pos.x <= maxp.x
	  and pos.z >= minp.z and pos.z <= maxp.z) then
		local surface_height = 35;
		-- this is the level that (may) contain the surface
		if( maxp.y >0 ) then
			-- determine average surface height
			local sum_height = 0;
			local count = 0;
			for ax=pos.x-1,pos.x+1 do
			for az=pos.z-1,pos.z+1 do
				local height = 1;
				if( heightmap ) then
					height = heightmap[(az-minp.z)*chunksize+(ax-minp.x)+1];
				-- TODO: add alternate way in case of heightmap not defined
				end
				if( height and ax>=minp.x and ax<=maxp.x and az>=minp.z and az<=maxp.z) then
					if( height > 0 ) then
						sum_height = sum_height + height;
					end
					count = count+1;
				end
			end
			end
			if( count>0 and sum_height>=0
			   and data[ a:index( pos.x, minp.y, pos.z)] ~= cid_mines.c_rope
			   and data[ a:index( pos.x, minp.y, pos.z)] ~= cid_mines.c_fence) then
				surface_height = math.max(1, sum_height/count);
				surface_height = surface_height - (surface_height%10)+4;
--print('SURFACE HEIGHT: '..tostring( surface_height )..' COUNT: '..tostring(count)..' sum: '..tostring(sum_height));
				local spos = {x=pos.x, y=surface_height, z=pos.z};
				-- the schematic for the mining tower will be placed later on (after voxelmanip has been dealt with)
				table.insert( extra_calls_mines.schems,  {x=pos.x-5, y=surface_height-6, z=pos.z-5, file='mining_tower_1_7_90'});
			else
				surface_height = maxp.y+1;
			end

			if( surface_height < 1 ) then
				surface_height = 1;
			end
		end

		-- that part of the vertical shaft that goes through this chunk may not be longer than the vertical chunk size
		local y_start = math.min( maxp.y, surface_height );
		local y_end   = math.max( minp.y, main_level_at );
		local vlength = math.min( maxp.y-minp.y, y_start - y_end);

		-- actually place the VERTICAL shaft
		local vpos = {x=pos.x, y=y_start, z=pos.z};
		mines_with_shafts.place_mineshaft_vertical(minp, maxp, data, param2_data, a, cid_mines, vpos, vlength, extra_calls_mines );
	end

	local npos = {x=pos.x, y=main_level_at; z=pos.z};

if( surface_level_at > 15 ) then
	surface_level_at = surface_level_at - 5;
end
	for i=5,-5,-1 do
		local iteration_depth = 0;
		if( i==0 ) then
			iteration_depth = 0;
		elseif( math.abs(i)<3 ) then
			iteration_depth = 1;
		else
			iteration_depth = 2;
		end
		if( pr:next(1,5)<4 ) then
			npos.y = surface_level_at+i*5;
			mines_with_shafts.create_branches_at_level( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, 1, iteration_depth, heightmap );
		end
		if( pr:next(1,5)<3 ) then 
			npos.y = main_level_at+25+i*5;
			mines_with_shafts.create_branches_at_level( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, 1, iteration_depth, heightmap );
		end
	end
end


mines_with_shafts.create_branches_at_level = function( minp, maxp, data, param2_data, a, cid_mines, pos, extra_calls_mines, pr, primary_axis, initial_iteration_depth, heightmap )
	mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, pos, extra_calls_mines, pr, 1, primary_axis, initial_iteration_depth, heightmap );
	mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, pos, extra_calls_mines, pr,-1, primary_axis, initial_iteration_depth, heightmap );
	-- smaller branches at the side
	if( primary_axis == 1 ) then
		primary_axis = 0;
	else
		primary_axis = 1;
	end
	mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, pos, extra_calls_mines, pr, 1, primary_axis, math.min(3,initial_iteration_depth+2 ), heightmap);
	mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, pos, extra_calls_mines, pr,-1, primary_axis, math.min(3,initial_iteration_depth+2 ), heightmap);
end




mines_with_shafts.create_branch = function( minp, maxp, data, param2_data, a, cid_mines, pos, extra_calls_mines, pr, d1, d2, iteration_depth, heightmap )
	-- abort - do not create branches without limit
	if( iteration_depth > 3 ) then 
		return;
	end
	local l1=40;
	if(     iteration_depth==1 ) then
		l1 = 35;
	elseif( iteration_depth==2 ) then	
		l1 = 25;
	else
		l1 = 15;
	end
	-- branches at heigher iteration levels get shorter
	local length = 4*pr:next(1,math.max(1,l1));
	if( iteration_depth == 1 ) then
		length = length+(4+3);
	end

local material = 'default:wood';
if( iteration_depth == 1 ) then material = 'default:meselamp'; elseif (iteration_depth==2 ) then material = 'wool:pink'; end
	-- create the main tunnel
	mines_with_shafts.place_minetunnel_horizontal(minp, maxp, data, param2_data, a, cid_mines, pos,  d1*length, d2, extra_calls_mines, heightmap, material );

	-- if we went into z direction before, let the branches go into x direction (and vice versa)
	local nd2 = 0;
	if( d2==0 ) then
		nd2 = 1;
	end

	local last_right = true;
	local last_left  = true;
	local dist_last_shaft = 0;
	for i=4,length,4 do
		local p = pr:next(1,30);
		local npos = {x=pos.x, y=pos.y, z=pos.z};
		if( d2==1 ) then
			npos.x = pos.x+i*d1;
		else
			npos.z = pos.z+i*d1;
		end
		-- new branches at both sides
		if(     p==1 and not(last_right or last_left)) then
			mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, d1,    nd2, iteration_depth+1, heightmap );
			mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, d1*-1, nd2, iteration_depth+1, heightmap );
			last_right = true;
			last_left  = true;
		-- new branch at one side
		elseif( (p==2 or p==3) and not(last_left)) then
			mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, d1,    nd2, iteration_depth+1, heightmap );
			last_right = false;
			last_left  = true;
		-- new branch at the other side
		elseif( (p==4 or p==5) and not(last_right)) then
			mines_with_shafts.create_branch( minp, maxp, data, param2_data, a, cid_mines, npos, extra_calls_mines, pr, d1*-1, nd2, iteration_depth+1, heightmap );
			last_right = true; 
			last_left  = false;

		elseif( pr:next(1,6)>3 ) then
			last_right = false;
			last_left  = false;
		end

		-- allow two branches in the same direction - but only rarely
		if( pr:next(1,8)==1 ) then
			last_right = false;
			last_left  = false;
		end

		if false and (pr:next(1,10)==1 or (dist_last_shaft>3 and iteration_depth==0 and pr:next(1,3)==1)) then
			local dir = pr:next(1,5);
			local y_start = npos.y;
			local y_end   = npos.y;
			local h_max = 5;
			if( iteration_depth==0 ) then
				 h_max = 8;
			end
			if(     dir==1 and dist_last_shaft>2) then
				y_start   = y_start + pr:next(1,h_max)*5;
			elseif( dir==2 and dist_last_shaft>2) then
				y_end     = y_end   - pr:next(1,h_max)*5;
			elseif( dir==3 and dist_last_shaft>2) then
				y_start   = y_start + pr:next(1,h_max)*5;
				y_end     = y_end   - pr:next(1,h_max)*5;
			end
			-- make sure the vertical shaft does not go up higher than the surface
			local height = 1;
			if( heightmap ) then
				height = heightmap[(npos.z-minp.z)*( maxp.x - minp.x + 1)+(npos.x-minp.x)+1];
			else
				light = minetest.get_node_light({x=npos.x, y=npos.y+2, z=npos.z}, 0.5);
				if( not(light) or light<14 ) then
					height = pos.y+3;
				end
			end
			if( not( height )) then
				height = 1;
			-- TODO: add alternate way in case heightmap not defined
			end
			y_start = math.min( height, y_start );
			if( y_start > y_end ) then
				local vlength = y_start - y_end +2;
				local vpos = {x=npos.x, y=y_start+2, z=npos.z};
				mines_with_shafts.place_mineshaft_vertical(minp, maxp, data, param2_data, a, cid_mines, vpos, vlength, extra_calls_mines );
				dist_last_shaft = 0;

				if( height and y_start >= height and height>=minp.y and height<=maxp.y and height>=0
				  and npos.x>=minp.x and npos.x<=maxp.x and npos.z>=minp.z and npos.z<=maxp.z) then
					-- TODO: make that configurable
					local schems = { 'mine_shaft_entrance_basic_1_90',
						 'mine_shaft_entrance_stonebrick_1_90',
						 'mine_shaft_entrance_simple_1_90'};
					local i = pr:next(1,#schems);	
					table.insert( extra_calls_mines.schems,  {x=npos.x-2, y=math.max(1,height), z=npos.z-2, file=schems[i]});
				end
			end
		else
			dist_last_shaft = dist_last_shaft + 1;
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
print('PLACING SCHEM '..tostring( v.file )..' AT '..minetest.pos_to_string( v )); -- TODO
			minetest.place_schematic( {x=v.x, y=v.y, z=v.z}, path..v.file..".mts", "0", {}, true);
		end
	end

	-- TODO: fill chests, add text to signs
end


minetest.register_on_generated(function(minp, maxp, seed)
	
	-- do not handle mapchunks which are either too heigh or too deep for a mine
	if(  minp.y < -128 or minp.y > 64) then
		return;
	end
	-- check if there are any mines around which might be part of this maphunk
	local mine_positions = mines_with_shafts.get_mines_at( minp, maxp, 3);
	if( not( mine_positions ) or #mine_positions < 1 ) then
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
	local extra_calls = {mines={}, schems={}};
	for _,pos in ipairs( mine_positions ) do
		mines_with_shafts.create_mine( minp, maxp, data, param2_data, a, heightmap, pos, extra_calls );
	end


	-- store the voxelmanip data
	vm:set_data(data)
	vm:set_param2_data(param2_data)

	vm:calc_lighting( emin, emax);
        vm:write_to_map(data);
        vm:update_liquids();

	mines_with_shafts.handle_metadata( extra_calls );
end) 
