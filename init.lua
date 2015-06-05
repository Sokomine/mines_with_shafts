-- the namespace
mines_with_shafts = {};

mines_with_shafts.modpath = minetest.get_modpath( "mines_with_shafts");

-- the mod comes with its own ladder and rope; both act as rails for carts
dofile(mines_with_shafts.modpath.."/nodes.lua")


-- TODO: give credits to the texture creator(s)

-- use the powerrail from carts if available
mines_with_shafts.rail_typ_name = 'default:rail';
if( minetest.get_modpath( 'carts' )
   and minetest.registered_nodes[ 'carts:powerrail' ]) then
	mines_with_shafts.rail_typ_name = 'carts:powerrail';
end

dofile(mines_with_shafts.modpath.."/config.lua")
dofile(mines_with_shafts.modpath.."/mines_horizontal_tunnels.lua")
dofile(mines_with_shafts.modpath.."/mines_vertical_shafts.lua")
dofile(mines_with_shafts.modpath.."/mines_create.lua")

-- create a list containing all possible decorations for the sides of the mines
mines_with_shafts.init_deco_list = function()

	mines_with_shafts.deco_list = {};
	
	for k,v in pairs( mines_with_shafts.deco ) do
		local reg_node = minetest.registered_nodes[ k ];
		if( reg_node ) then

			mines_with_shafts.deco[k][3] = minetest.get_content_id( k );

			-- nodes with wallmounted or facedir need to be treated diffrently
			mines_with_shafts.deco[k][4] = 0;
			if(     reg_node.paramtype2 and reg_node.paramtype2=='facedir' ) then
				mines_with_shafts.deco[k][4] = 1;
			elseif( reg_node.paramtype2 and reg_node.paramtype2=='wallmounted' ) then
				mines_with_shafts.deco[k][4] = 2;
			end

			mines_with_shafts.deco[k][5] = nil;
			-- nodes with on_construct need special treatment as welll
			if( reg_node.on_construct ) then
				mines_with_shafts.deco[k][5] = reg_node.on_construct;
			end

			-- now add the node to the list as often as requested
			for i=1,mines_with_shafts.deco[k][1] do
				mines_with_shafts.deco_list[ #mines_with_shafts.deco_list+1 ] = k;
			end
		end
	end
	
	-- make sure the average distance remains constant even if we add more nodes
	mines_with_shafts.deco_average_distance = mines_with_shafts.deco_average_distance
		* #mines_with_shafts.deco_list;
end
mines_with_shafts.init_deco_list();


-- adjust some node definitions in order to avoid cavegen griefing
local def = minetest.registered_nodes['default:wood'];
def.is_ground_content = false;
minetest.register_node( ':default:wood', def );

def = minetest.registered_nodes[mines_with_shafts.rail_typ_name];
def.is_ground_content = false;
minetest.register_node( ':'..mines_with_shafts.rail_typ_name, def );
