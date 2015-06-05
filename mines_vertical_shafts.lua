
mines_with_shafts.place_mineshaft_vertical = function(minp, maxp, data, param2_data, a, cid, pos, length, extra_calls )

	for i=pos.y,math.max( minp.y, pos.y-length),-1 do
		-- the central place always gets a rope
		if( pos.x>=minp.x and pos.x<=maxp.x and pos.z>=minp.z and pos.z<=maxp.z) then
			data[ a:index( pos.x, i, pos.z ) ] = cid.c_rope;
		end

		if( pos.x >minp.x and pos.x<=maxp.x) then
			-- ..sourrounded by mineladders
			if( pos.z> minp.z and pos.z<=maxp.z) then
				data[        a:index( pos.x-1, i, pos.z-1 ) ] = cid.c_mineladder;
				param2_data[ a:index( pos.x-1, i, pos.z-1 ) ] = 5;
			end
			if( pos.z>=minp.z and pos.z<=maxp.z) then
				data[        a:index( pos.x-1, i, pos.z   ) ] = cid.c_mineladder;
				param2_data[ a:index( pos.x-1, i, pos.z   ) ] = 3;
			end
			if( pos.z>=minp.z and pos.z< maxp.z) then
				data[        a:index( pos.x-1, i, pos.z+1 ) ] = cid.c_mineladder;
				param2_data[ a:index( pos.x-1, i, pos.z+1 ) ] = 3;
			end
		end

		if( pos.x>=minp.x and pos.x< maxp.x ) then
			if( pos.z> minp.z and pos.z<=maxp.z) then
				data[        a:index( pos.x+1, i, pos.z-1 ) ] = cid.c_mineladder;
				param2_data[ a:index( pos.x+1, i, pos.z-1 ) ] = 2;
			end
			if( pos.z>=minp.z and pos.z<=maxp.z) then
				data[        a:index( pos.x+1, i, pos.z   ) ] = cid.c_mineladder;
				param2_data[ a:index( pos.x+1, i, pos.z   ) ] = 2;
			end
			if( pos.z>=minp.z and pos.z< maxp.z) then
				data[        a:index( pos.x+1, i, pos.z+1 ) ] = cid.c_mineladder;
				param2_data[ a:index( pos.x+1, i, pos.z+1 ) ] = 4;
			end
		end

		if( pos.x>=minp.x and pos.x<=maxp.x ) then
			if( pos.z> minp.z and pos.z<=maxp.z) then
				data[        a:index( pos.x,   i, pos.z-1 ) ] = cid.c_mineladder;
				param2_data[ a:index( pos.x,   i, pos.z-1 ) ] = 5;
			end
			if( pos.z>=minp.z and pos.z< maxp.z) then
				data[        a:index( pos.x,   i, pos.z+1 ) ] = cid.c_mineladder;
				param2_data[ a:index( pos.x,   i, pos.z+1 ) ] = 4;
			end
		end

		-- we do need a bit of light from time to time!
		if( mines_with_shafts.place_meselamps==true and i%20==5 ) then
	
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
