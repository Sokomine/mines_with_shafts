
mines_with_shafts.place_mineshaft_vertical = function(minp, maxp, data, param2_data, a, cid, pos, length, extra_calls )

	-- do not place mineshafts that would be larger in x/z-direction than the current mapchunk
	if(  pos.x==minp.x or pos.x==maxp.x
	  or pos.z==minp.z or pos.z==minp.z ) then
		return;
	end

	local step = 1;
	local y_start = pos.y;
	if( length<0 ) then
		step   = -1;
		length = length-3;
		y_start = y_start+3;
	end

	for i=y_start,y_start+length,step do

		-- abort if not inside mapchunk or if a rope (from another tunnel?) was found
		if( i<minp.y or i>maxp.y or (math.abs(i-y_start)>4 and data[ a:index( pos.x, i, pos.z )]==cid.c_rope )) then
			return;
		end

		if( i>0 ) then
			local anz_daylight = 0;
			for x=-1,1 do
				for z=-1,1 do
					local light = minetest.get_node_light({x=pos.x+x, y=i, z=pos.z+z}, 0.5);
					if( light and light==15 ) then
						anz_daylight = anz_daylight+1;
					end
				end
			end
			-- the shaft has reached the top
			if( anz_daylight > 3 ) then
				-- TODO: build alternate mine entrances and choose one randomly
				table.insert( extra_calls.schems,  {x=pos.x-5, y=i-7, z=pos.z-5, file='mining_tower_1_7_90'});
				return;
			end
		end

		-- the central place always gets a rope
		data[ a:index( pos.x, i, pos.z ) ] = cid.c_rope;

		-- ..sourrounded by mineladders
		data[ a:index( pos.x-1, i, pos.z-1 ) ] = cid.c_mineladder;
		data[ a:index( pos.x-1, i, pos.z   ) ] = cid.c_mineladder;
		data[ a:index( pos.x-1, i, pos.z+1 ) ] = cid.c_mineladder;

		data[ a:index( pos.x+1, i, pos.z-1 ) ] = cid.c_mineladder;
		data[ a:index( pos.x+1, i, pos.z   ) ] = cid.c_mineladder;
		data[ a:index( pos.x+1, i, pos.z+1 ) ] = cid.c_mineladder;

		data[ a:index( pos.x,   i, pos.z-1 ) ] = cid.c_mineladder;
		data[ a:index( pos.x,   i, pos.z+1 ) ] = cid.c_mineladder;

		-- ..which always have the same wallmounted value
		param2_data[ a:index( pos.x-1, i, pos.z   ) ] = 3;
		param2_data[ a:index( pos.x-1, i, pos.z+1 ) ] = 3;

		param2_data[ a:index( pos.x,   i, pos.z+1 ) ] = 4;
		param2_data[ a:index( pos.x+1, i, pos.z+1 ) ] = 4;

		param2_data[ a:index( pos.x+1, i, pos.z-1 ) ] = 2;
		param2_data[ a:index( pos.x+1, i, pos.z   ) ] = 2;

		param2_data[ a:index( pos.x-1, i, pos.z-1 ) ] = 5;
		param2_data[ a:index( pos.x,   i, pos.z-1 ) ] = 5;

		-- we do need a bit of light from time to time!
		if( math.abs(i-y_start)%20==5 ) then
	
			if( pos.x-1>minp.x ) then
				data[ a:index( pos.x-2, i, pos.z-1 ) ] = cid.c_meselamp;
				data[ a:index( pos.x-2, i, pos.z+1 ) ] = cid.c_meselamp;
			end
			if( pos.x+1<maxp.x ) then
				data[ a:index( pos.x+2, i, pos.z-1 ) ] = cid.c_meselamp;
				data[ a:index( pos.x+2, i, pos.z+1 ) ] = cid.c_meselamp;
			end
			if( pos.z-1>minp.z ) then
				data[ a:index( pos.x-1, i, pos.z-2 ) ] = cid.c_meselamp;
				data[ a:index( pos.x+1, i, pos.z-2 ) ] = cid.c_meselamp;
			end
			if( pos.z+1<maxp.z ) then
				data[ a:index( pos.x-1, i, pos.z+2 ) ] = cid.c_meselamp;
				data[ a:index( pos.x+1, i, pos.z+2 ) ] = cid.c_meselamp;
			end
		end
	end
end
