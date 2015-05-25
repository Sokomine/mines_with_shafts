-----------------------------------------------------
-- this creates the horizontal tunnels for the mines
----------------------------------------------------


-- if length is <0, the tunnel will go in the opposite direction
mines_with_shafts.place_minetunnel_horizontal = function(minp, maxp, data, param2_data, a, cid, pos, length, parallel_to_x_axis, extra_calls )

	-- minetunnels are not allowed to follow the borders of mapchunks while beeing only partly contained in that chunk
	-- as this would make consistent placement a lot harder and is not really needed for convincing mines
	if(  (pos.y-2 < minp.y and pos.y+2 > minp.y )
	  or (pos.y-2 < maxp.y and pos.y+2 > maxp.y )
	  or (pos.z-2 < minp.z and pos.z+2 > minp.z and parallel_to_x_axis == 1)
	  or (pos.z-2 < maxp.z and pos.z+2 > maxp.z and parallel_to_x_axis == 1)
	  or (pos.x-2 < minp.x and pos.x+2 > minp.x and parallel_to_x_axis == 0)
	  or (pos.x-2 < maxp.x and pos.x+2 > maxp.x and parallel_to_x_axis == 0)) then
		return;
	end

	local vector      = {x=0,y=0,z=0};
	local vector_quer = {x=0,y=0,z=0};
	-- the tunnel extends in x direction
	if(     parallel_to_x_axis == 1 ) then
		if( length>0) then
			vector.x = 1;
		else
			vector.x = -1;
		end
		vector_quer.z = 1;
	elseif( parallel_to_x_axis == 0 ) then
		if( length>0) then
			vector.z = 1;
		else
			vector.z = -1;
		end
		vector_quer.x = 1;
	else
		-- wrong parameters
		return;
	end

	-- compensate for the added length of the central crossing
	if( length<0 ) then
		length = length-3;
	else
		length = length+3;
	end
	-- the actual start position will be 2 nodes further back, thus creating nice crossings
	local ax = pos.x+(-2*vector.x);
	local az = pos.z+(-2*vector.z);
	for i=1,math.abs(length) do
		-- go one step further in eitzer x or z direction
		ax = ax+vector.x;
		az = az+vector.z;

		-- make sure we do not exceed the boundaries of the mapchunk
		if(   ax < minp.x or ax > maxp.x
		   or az < minp.z or az > maxp.z ) then
			return;
		end
		
		local res = mines_with_shafts.do_minetunnel_horizontal_slice( minp, maxp, data, param2_data, a, cid,
			{x=ax, y=pos.y, z=az}, vector_quer, i%4, (length<0), extra_calls);
		-- abort if there is anything that prevents the mine from progressing in that direction
		if( res < 0 ) then
			return;
		end
	end
end

-- internal function
-- * go one node into the direction given by vector
-- * place a support beam made from wood and fences if beam_seq_nr==0
-- * place torches and random nodes at the sides otherwise
-- * returns a value >= 0 if everything went fine
-- * returns a value <0 if the mine has to end at this place (i.e. sunlight detected, or water/lava found
mines_with_shafts.do_minetunnel_horizontal_slice = function( minp, maxp, data, param2_data, a, cid, pos, vector, beam_seq_nr, backwards, extra_calls )
	local p = {x=pos.x, y=pos.y, z=pos.y};

	local ax=pos.x;
	local az=pos.z;

	local no_daylight = true;
	-- check if there are any nodes that force an end to the tunnel
	for ax=pos.x+(vector.x*-2),pos.x+(vector.x*2) do
	for az=pos.z+(vector.z*-2),pos.z+(vector.z*2) do
		for y=-1,2 do
			local old_node = data[ a:index( ax, pos.y+y, az)];
				-- we have hit a vertical minetunnel
			if( old_node==cid.c_mineladder or old_node==cid.c_rope ) then
				-- the tunnel may still continue behind this vertical tunnel
				return 0;
			end

			-- we do not want to build a tunnel through lava or water; though both may flow in if we digged too far
			-- (the poor inhabitants will have given up the tunnel)
			if( old_node==cid.c_lava or old_node==cid.c_lava_flowing or old_node==cid.c_water ) then
				-- the tunnel has to end here
print('MINESHAFT abort due to water or lava at '..minetest.pos_to_string( pos));
				return -1;
			end

			if( math.abs(ax-pos.x)<2 and math.abs(az-pos.z)<2 ) then
				-- as soon as any of the 3 topmost nodes receives no daylight, we do not need to check any longer
				if( y==2 and no_daylight) then
					local light = minetest.get_node_light({x=ax, y=pos.y+y, z=az}, 0.5);
					if( light and light==15 ) then
						no_daylight = false;
					end
				end
	
				-- if there is air at the bottom, place some wood to walk on (even if the tunnel will later be aborted)
				if( y==-1 and old_node==cid.c_air) then
					data[ a:index( ax, pos.y+y, az)] = cid.c_wood;
				end
			end
		end
	end
	end
 
	-- there will always be a rail on the ground
	data[ a:index( pos.x, pos.y,   pos.z )] = cid.c_rail;
	-- ..and air directly above so that players can walk through
	data[ a:index( pos.x, pos.y+1, pos.z )] = cid.c_air;

	-- if all three topmost nodes receive daylight, then it's time to end our tunnel
	if( not( no_daylight )) then
print('MINESHAFT abort due to daylight at '..minetest.pos_to_string(pos));
		return -2;
	end

	-- every 4th tunnel has a wooden support beam
	if( beam_seq_nr == 0 ) then
		-- either vector.x or vector.z is 0; the other value will be 1
		ax = vector.x;
		az = vector.z;
		-- place the four fences at the sides
		data[ a:index( pos.x-ax, pos.y,   pos.z-az )] = cid.c_fence;
		data[ a:index( pos.x-ax, pos.y+1, pos.z-az )] = cid.c_fence;
		data[ a:index( pos.x+ax, pos.y,   pos.z+az )] = cid.c_fence;
		data[ a:index( pos.x+ax, pos.y+1, pos.z+az )] = cid.c_fence;
		-- place the three wooden planks on top of the fences
		data[ a:index( pos.x,    pos.y+2, pos.z    )] = cid.c_wood; 
		data[ a:index( pos.x-ax, pos.y+2, pos.z-az )] = cid.c_wood; 
		data[ a:index( pos.x+ax, pos.y+2, pos.z+az )] = cid.c_wood; 
		-- all has been placed successfully
		return 1;
	end


	-- create the tunnel as such
	for ax=pos.x+(vector.x*-1),pos.x+(vector.x*1) do
	for az=pos.z+(vector.z*-1),pos.z+(vector.z*1) do
		for ay = pos.y, pos.y+2 do
			if( (ax ~= pos.x or az ~= pos.z) and ( ay>pos.y or data[a:index(ax,ay,az)]~=cid.c_rail)) then
				data[ a:index( ax, ay, az )] = cid.c_air;
			end
		end
	end
	end

	-- attach a torch to the beam
	local p2 = -1;
	if(     beam_seq_nr == 1 ) then
		if(     vector.x ~= 0 and not(backwards )) then
			p2 = 5;
		elseif( vector.x ~= 0 and backwards ) then
			p2 = 4;
		elseif( vector.z ~= 0 and not(backwards )) then
			p2 = 3;
		elseif( vector.z ~= 0 and backwards ) then
			p2 = 2;
		end
	-- put air in the middle
	elseif( beam_seq_nr == 2 ) then
		data[ a:index( pos.x,    pos.y+2, pos.z    )] = cid.c_air; 
	-- attach a torch to the beam
	elseif( beam_seq_nr == 3 ) then
		if(     vector.x ~= 0 and not(backwards )) then
			p2 = 4;
		elseif( vector.x ~= 0 and backwards ) then
			p2 = 5;
		elseif( vector.z ~= 0 and not(backwards )) then
			p2 = 2;
		elseif( vector.z ~= 0 and backwards ) then
			p2 = 3;
		end
	end
	if( p2 > -1 ) then
		data[        a:index( pos.x, pos.y+2, pos.z )] = cid.c_torch;
		param2_data[ a:index( pos.x, pos.y+2, pos.z )] = p2;
	end


	-- there may be decorative random blocks at both sides
	mines_with_shafts.place_random_decoration( data, param2_data, a, cid, {x=pos.x+vector.x, y=pos.y, z=pos.z+vector.z},  1, vector, extra_calls );
	mines_with_shafts.place_random_decoration( data, param2_data, a, cid, {x=pos.x-vector.x, y=pos.y, z=pos.z-vector.z}, -1, vector, extra_calls );

	-- the tunnel has been created successfully
	return 1;
end


-- internal function
-- * place a random decoration at one of the sides (or dig a one-node-wide hole or water source into the floor)
mines_with_shafts.place_random_decoration = function( data, param2_data, a, cid, pos, side, vector, extra_calls )

	-- only place something there if the place is currently empty
	if( data[ a:index( pos.x, pos.y, pos.z )]~=cid.c_air ) then
		return;
	end

	-- most places remain empty
	local c = math.random( 1, mines_with_shafts.deco_average_distance );
	if( c > #mines_with_shafts.deco_list
	   or not( #mines_with_shafts.deco_list[ c ])
	   or not( mines_with_shafts.deco[ mines_with_shafts.deco_list[c]] )) then
		return;
	end
	local deco = mines_with_shafts.deco[ mines_with_shafts.deco_list[c] ];

	-- apply the offset to the y direction and set the node to its id
	data[ a:index( pos.x, pos.y+deco[2], pos.z )] = deco[3];

	-- handle facedir nodes
	if(     deco[4]==1 ) then
		local p2 = 0;
		if(     side==-1 and vector.x~=0 ) then p2 = 3;
		elseif( side== 1 and vector.x~=0 ) then p2 = 1;
		elseif( side==-1 and vector.z~=0 ) then p2 = 2;
		elseif( side== 1 and vector.z~=0 ) then p2 = 0;
		end
		param2_data[ a:index( pos.x, pos.y+deco[2], pos.z )] = p2;
	-- handle wallmounted nodes
	elseif( deco[4]==2 ) then
		local p2 = 0;
		if(     side==-1 and vector.x~=0 ) then p2 = 3;
		elseif( side== 1 and vector.x~=0 ) then p2 = 2;
		elseif( side==-1 and vector.z~=0 ) then p2 = 5;
		elseif( side== 1 and vector.z~=0 ) then p2 = 4;
		end
		param2_data[ a:index( pos.x, pos.y+deco[2], pos.z )] = p2;
	end

	-- handle nodes which require calls to on_construct (i.e. chests)
	if( deco[5] ) then
		table.insert( extra_calls.mines, {x=pos.x, y=pos.y+deco[2], z=pos.z, typ=mines_with_shafts.deco_list[c]} );
	end
end
