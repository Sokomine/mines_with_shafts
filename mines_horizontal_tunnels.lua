-----------------------------------------------------
-- this creates the horizontal tunnels for the mines
----------------------------------------------------


-- if length is <0, the tunnel will go in the opposite direction;
-- returns the length of the new tunnel
mines_with_shafts.place_minetunnel_horizontal = function(minp, maxp, data, param2_data, a, cid, pos, length, parallel_to_x_axis, extra_calls, heightmap )

	-- exclude those tunnels that are not part of this mapchunk
	-- we are only responsible for this tunnel if the central part of it is contained in this mapchunk;
	-- that way, there will always be exactly one mapchunk responsible for each tunnel,
	-- and the heightmap can be used as well;
	-- further boundary checks are not necessary as the tunnel will be smaller than the shell
	if( pos.y < minp.y or pos.y > maxp.y 
	   or (parallel_to_x_axis==1 and ((pos.z < minp.z or pos.z > maxp.z) or (length>0 and pos.x>maxp.x) or (length<0 and pos.x<minp.x))) 
	   or (parallel_to_x_axis~=1 and ((pos.x < minp.x or pos.x > maxp.x) or (length>0 and pos.z>maxp.z) or (length<0 and pos.z<minp.z)))) then 
		return;
	end

	local px = 0;
	local pz = 0;
	if(parallel_to_x_axis==1) then
		px = 1;
		pz = 0;
	else
		px = 0;
		pz = 1;
	end
	if( length<0 ) then
		px = px*-1;
		pz = pz*-1;
	end
	local vector_quer = {x=math.abs(pz),z=math.abs(px)};
	local chunksize = maxp.x-minp.x+1;
	local ax = pos.x;
	local az = pos.z;
	local candidates = {};
	local d = 5; -- distance to the last slice of the tunnel that was definitely below ground
	for i=1,math.abs(length) do
		local seq_nr = 0;
		if(     az==pos.z ) then
			seq_nr = (ax+2)%4;
		elseif( ax==pos.x ) then
			seq_nr = (az+2)%4;
		end
		if( ax >= minp.x and ax <= maxp.x and az >= minp.z and az <= maxp.z and pos.y >= minp.y and pos.y <= maxp.y) then

			if( pos.y < 0 ) then
				d = 0;
			else
				local height = 1;
				if( heightmap ) then
					height = heightmap[(az-minp.z)*chunksize+(ax-minp.x)+1];
				else
					light = minetest.get_node_light({x=ax, y=pos.y+2, z=az}, 0.5);
					if( not(light) or light<14 ) then
						height = pos.y+3;
					end
				end
				if( height and height > minp.y and height < maxp.y ) then
					if(     height <= pos.y+1 ) then
						if( mines_with_shafts.MARK_TUNNELS ) then
							data[ a:index( ax, height, az )] = mines_with_shafts.MARK_TUNNELS;
						end
						d = d+1;
						if( d>=5) then
							candidates[ #candidates+1 ] = {ax,az,seq_nr};
						end
					elseif( height > pos.y+1 ) then
						d = 0;
					end
				else
					candidates[ #candidates+1 ] = {ax,az,seq_nr};
				end
			end

			if( d<5 ) then
				local res = mines_with_shafts.do_minetunnel_horizontal_slice( minp, maxp, data, param2_data, a, cid,
					{x=ax, y=pos.y, z=az}, vector_quer, seq_nr, (length<0), extra_calls);
				-- place the last 5 slices so that the entrance looks better
				if( #candidates > 0 ) then
					local bridge_length = mines_with_shafts.MIN_BRIDGE_LENGTH;
					if( #candidates <= mines_with_shafts.MAX_BRIDGE_LENGTH ) then
						bridge_length = #candidates;
					end
					for j=math.max(1,#candidates-bridge_length),#candidates do
						local res = mines_with_shafts.do_minetunnel_horizontal_slice( minp, maxp, data, param2_data, a, cid,
							{x=candidates[j][1], y=pos.y, z=candidates[j][2]}, vector_quer, candidates[j][3], (length<0), extra_calls);
					end
					candidates = {};
				end
			end
		end
		ax = ax+px;
		az = az+pz;
	end

	return math.abs(length);
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

	-- check if there are any nodes that force an end to the tunnel
	for ax=pos.x+(vector.x*-2),pos.x+(vector.x*2) do
	for az=pos.z+(vector.z*-2),pos.z+(vector.z*2) do
		for y=-1,2 do
			local old_node = data[ a:index( ax, pos.y+y, az)];
			-- we have hit a vertical minetunnel
			if( old_node==cid.c_mineladder or old_node==cid.c_rope ) then
				-- the tunnel may still continue behind this vertical tunnel
--print('MINETUNNEL abort due to shaft at '..minetest.pos_to_string( pos));
				return 0;
			end
	
			-- we do not want to build a tunnel through lava or water; though both may flow in if we digged too far
			-- (the poor inhabitants will have given up the tunnel)
			if( old_node==cid.c_lava or old_node==cid.c_lava_flowing or old_node==cid.c_water ) then
				-- the tunnel has to end here
--print('MINETUNNEL abort due to water or lava at '..minetest.pos_to_string( pos));
				return -1;
			end
		end
	end
	end

	for i=-1,1 do
		local ax = pos.x+(vector.x*i );
		local az = pos.z+(vector.z*i );
		local old_node = data[ a:index( ax, pos.y-1, az)];
		-- if there is air at the bottom, place some wood to walk on (even if the tunnel will later be aborted)
		if( old_node==cid.c_air or old_node==cid.c_fence or old_node==cid.c_ignore) then
			data[ a:index( ax, pos.y-1, az)] = cid.c_wood;
		end
		if( beam_seq_nr==0 and i~=0) then
			local k=-2;
			local ground_found = false;
			while( not( ground_found)
			  and pos.y+k>=minp.y-16
			  and a:contains( ax, pos.y+k, az )) do
				local old_node = data[  a:index( ax, pos.y+k, az)];
				if(     old_node == cid.c_air ) then
					data[ a:index( ax, pos.y+k, az)] = cid.c_fence;
				elseif( old_node == cid.c_water 
				     or old_node == cid.c_lava ) then
					data[ a:index( ax, pos.y+k, az)] = cid.c_cobble;
				else
					ground_found = true;
				end
				k = k-1;
			end
		end
	end
 
	-- there will always be a rail on the ground
	data[ a:index( pos.x, pos.y,   pos.z )] = cid.c_rail;
	data[ a:index( pos.x, pos.y+1, pos.z )] = cid.c_air;

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
		if(     vector.x ~= 0 ) then
			p2 = 5;
		elseif( vector.z ~= 0 ) then
			p2 = 3;
		end
	-- put air in the middle
	elseif( beam_seq_nr == 2 ) then
		data[ a:index( pos.x,    pos.y+2, pos.z    )] = cid.c_air; 
	-- attach a torch to the beam
	elseif( beam_seq_nr == 3 ) then
		if(     vector.x ~= 0 ) then
			p2 = 4;
		elseif( vector.z ~= 0 ) then
			p2 = 2;
		end
	end
	if( p2 > -1 ) then
		data[        a:index( pos.x, pos.y+2, pos.z )] = cid.c_torch;
		param2_data[ a:index( pos.x, pos.y+2, pos.z )] = p2;
	end


	-- there may be decorative random blocks at both sides
	mines_with_shafts.place_random_decoration( minp, maxp, data, param2_data, a, cid, {x=pos.x+vector.x, y=pos.y, z=pos.z+vector.z},  1, vector, extra_calls );
	mines_with_shafts.place_random_decoration( minp, maxp, data, param2_data, a, cid, {x=pos.x-vector.x, y=pos.y, z=pos.z-vector.z}, -1, vector, extra_calls );

	-- the tunnel has been created successfully
	return 1;
end


-- internal function
-- * place a random decoration at one of the sides (or dig a one-node-wide hole or water source into the floor)
mines_with_shafts.place_random_decoration = function( minp, maxp, data, param2_data, a, cid, pos, side, vector, extra_calls )

	-- only place something there if the place is currently empty
	if(  pos.x<minp.x or pos.x>maxp.x
	  or pos.y<minp.y or pos.y>maxp.y
	  or pos.z<minp.z or pos.z>maxp.z
	  or data[ a:index( pos.x, pos.y, pos.z )]~=cid.c_air ) then
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

	local yoff = deco[2];
	if( yoff < minp.y or yoff > maxp.y ) then
		yoff = 0;
	end
	-- apply the offset to the y direction and set the node to its id
	data[ a:index( pos.x, pos.y+yoff, pos.z )] = deco[3];

	-- handle facedir nodes
	if(     deco[4]==1 ) then
		local p2 = 0;
		if(     side==-1 and vector.x~=0 ) then p2 = 3;
		elseif( side== 1 and vector.x~=0 ) then p2 = 1;
		elseif( side==-1 and vector.z~=0 ) then p2 = 2;
		elseif( side== 1 and vector.z~=0 ) then p2 = 0;
		end
		param2_data[ a:index( pos.x, pos.y+yoff, pos.z )] = p2;
	-- handle wallmounted nodes
	elseif( deco[4]==2 ) then
		local p2 = 0;
		if(     side==-1 and vector.x~=0 ) then p2 = 3;
		elseif( side== 1 and vector.x~=0 ) then p2 = 2;
		elseif( side==-1 and vector.z~=0 ) then p2 = 5;
		elseif( side== 1 and vector.z~=0 ) then p2 = 4;
		end
		param2_data[ a:index( pos.x, pos.y+yoff, pos.z )] = p2;
	end

	-- handle nodes which require calls to on_construct (i.e. chests)
	if( deco[5] ) then
		table.insert( extra_calls.mines, {x=pos.x, y=pos.y+yoff, z=pos.z, typ=mines_with_shafts.deco_list[c]} );
	end
end
