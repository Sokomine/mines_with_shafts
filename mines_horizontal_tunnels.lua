-----------------------------------------------------
-- this creates the horizontal tunnels for the mines
----------------------------------------------------


-- if length is <0, the tunnel will go in the opposite direction;
-- returns the length of the new tunnel
mines_with_shafts.place_minetunnel_horizontal = function(minp, maxp, data, param2_data, a, cid, pos, length, parallel_to_x_axis, extra_calls, heightmap )

	-- we are only responsible for this tunnel if the central part of it is contained in this mapchunk;
	-- that way, there will always be exactly one mapchunk responsible for each tunnel,
	-- and the heightmap can be used as well;
	-- further boundary checks are not necessary as the tunnel will be smaller than the shell
	if(   (                          ( pos.y < minp.y or pos.y > maxp.y))
	   or (parallel_to_x_axis==0 and ( pos.x < minp.x or pos.x > maxp.x))
	   or (parallel_to_x_axis==1 and ( pos.z < minp.z or pos.z > maxp.z))
	   -- eliminate wrong parameters
	   or (parallel_to_x_axis~=0 and parallel_to_x_axis~=1)
	   or (not(heightmap))) then
		return 0;
	end

	local step = 1;
	if( length<0 ) then
		step = -1;
	end
	local ax = pos.x;
	local az = pos.z;
	local vector_quer = {x=0,z=0};
	if(     parallel_to_x_axis==0 ) then
		if(     pos.x < minp.x and step>0) then
			ax = minp.x;
			length = length-( minp.x-pos.x );
		elseif( pos.x > maxp.x and step<0) then
			ax = maxp.x;
			length = length-( pos.x-maxp.x );
		end
		vector_quer = {x=1,z=0};
	elseif( parallel_to_x_axis==1 ) then
		if(     pos.z < minp.z and step>0) then
			az = minp.z;
			length = length-( minp.z-pos.z );
		elseif( pos.z > maxp.z and step<0) then
			az = maxp.z;
			length = length-( pos.z-maxp.z );
		end
		vector_quer = {x=0,z=1};
	end
 
	local candidates = {};
	for i=1,length,step do
		local height = heightmap[(az-minp.z)*80+(ax-minp.x)+1];
		if( height and ax>=minp.x and ax<=maxp.x and az>=minp.z and az<=maxp.z) then
--			data[ a:index( ax, height, az )] = minetest.get_content_id('wool:pink');

			local is_below_ground = false;
			if( height>pos.y+2 or maxp.y<0) then
				is_below_ground = true;
			end

			local seq_nr = 0;
			if(     az==pos.z ) then
				seq_nr = (ax+2)%4;
			elseif( ax==pos.x ) then
				seq_nr = (az+2)%4;
			end
			candidates[ #candidates+1 ] = {x=ax,y=pos.y,z=az,seq_nr=seq_nr,is_below_ground=is_below_ground};
		end	
		if( parallel_to_x_axis==1 ) then
			ax = ax + step;
		else
			az = az + step;
		end
	end

	-- add some open mineshafts for the entrances
	local change_occoured = true;
	for i=1,#candidates do
		if( i>1 and candidates[i].is_below_ground and not(candidates[i-1].is_below_ground)) then
			for j=i-1,math.max(1,i-6) do
				candidates[j].is_below_ground = true;
			end
		end
	end
	for i=#candidates,2,-1 do
		if( i<#candidates and candidates[i-1].is_below_ground and not(candidates[i].is_below_ground)) then
			for j=i,math.min(#candidates,i+5) do
				candidates[j].is_below_ground = true;
			end
		end
	end
			

-- TODO: just for visualization
	local id_wood = minetest.get_content_id('default:wood');
	local id_mese = minetest.get_content_id('default:pinewood');
	for i,v in ipairs( candidates ) do
		if( v and v.is_below_ground==true ) then
			cid.c_wood = id_wood;
			local res = mines_with_shafts.do_minetunnel_horizontal_slice( minp, maxp, data, param2_data, a, cid,
				{x=v.x, y=v.y, z=v.z}, vector_quer, v.seq_nr, (length<0), extra_calls);
		else
			cid.c_wood = id_mese;
		end
	end
	cid.c_wood = id_wood;

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
		if( old_node==cid.c_air or old_node==cid.c_fence) then
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
