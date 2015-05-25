
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


-- TODO
mines_with_shafts.create_mine = function( minp, maxp, data, param2_data, a )
	local npos = {x=minp.x+40,y=minp.y+40,z=minp.z+40,bsizex=100,bsizez=1};
	local backwards = false;
	local extra_calls_mines = {mines={}};

	mines_with_shafts.place_minetunnel_horizontal(minp, maxp, data, param2_data, a, cid_mines, npos,  4*math.random(1,10), 1, extra_calls_mines );
	mines_with_shafts.place_minetunnel_horizontal(minp, maxp, data, param2_data, a, cid_mines, npos, -4*math.random(1,10), 1, extra_calls_mines );
	mines_with_shafts.place_minetunnel_horizontal(minp, maxp, data, param2_data, a, cid_mines, npos,  4*math.random(1,10), 0, extra_calls_mines );
	mines_with_shafts.place_minetunnel_horizontal(minp, maxp, data, param2_data, a, cid_mines, npos, -4*math.random(1,10), 0, extra_calls_mines );

	local npos2 = {x=npos.x,y=npos.y,z=npos.z};
	for i=1,10 do
		npos2.z = npos2.z+8;
--		mines_with_shafts.place_minetunnel_horizontal(minp, maxp, data, param2_data, a, cid_mines, npos2, 8*i, 1, extra_calls_mines );
	end

	mines_with_shafts.place_mineshaft_vertical(minp, maxp, data, param2_data, a, cid_mines, npos,  60, extra_calls );
	mines_with_shafts.place_mineshaft_vertical(minp, maxp, data, param2_data, a, cid_mines, npos, -60, extra_calls );

	return extra_calls_mines;
end


-- set up metadata by calling on_construct
mines_with_shafts.handle_metadata = function( extra_calls )

	-- call on_construct for those nodes that need it
	for _,v in pairs( extra_calls.mines ) do
		if( v.typ and mines_with_shafts.deco[ v.typ ] and mines_with_shafts.deco[ v.typ ][5]) then
			local on_construct = mines_with_shafts.deco[ v.typ ][5];
			on_construct( {x=v.x, y=v.y, z=v.z} );
		end
	end
	-- TODO: fill chests, add text to signs
end


minetest.register_on_generated(function(minp, maxp, seed)

	-- TODO: mines still float in the air
	-- limit height of the mines
	if(  minp.y < -256 or minp.y > 64) then
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


	-- actually create the mine
	local extra_calls = mines_with_shafts.create_mine( emin, emax, data, param2_data, a );


	-- store the voxelmanip data
	vm:set_data(data)
	vm:set_param2_data(param2_data)

	vm:calc_lighting( tmin, tmax);
        vm:write_to_map(data);
        vm:update_liquids();

	mines_with_shafts.handle_metadata( extra_calls );
end) 
