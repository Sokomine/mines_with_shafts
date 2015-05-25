
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

		-- TODO: check daylight


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
