-- the namespace
mines_with_shafts = {};

mines_with_shafts.modpath = minetest.get_modpath( "mines_with_shafts");

-- the mod comes with its own ladder and rope; both act as rails for carts
dofile(mines_with_shafts.modpath.."/nodes.lua")

dofile(mines_with_shafts.modpath.."/mines_horizontal_tunnels.lua")
dofile(mines_with_shafts.modpath.."/mines_create.lua")

-- TODO: give credits to the texture creator(s)
-- TODO: add vertical shafts
