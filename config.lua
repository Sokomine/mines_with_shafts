
-- nodes that may be found at the side of the tunnels randomly;
-- * increase the first number to increase (relative) frequency of that node
-- * set the second number to -1 in order to bury the node in the ground 
--   (or 1 to put it up one node higher)
mines_with_shafts.deco = {
	["tnt:tnt"                   ] = {1,0},
	["default:chest"             ] = {5,0},
	["default:desert_stone"      ] = {1,0},
	["default:stone"             ] = {1,0},
	["default:stone_with_coal"   ] = {1,0},
	["default:stone_with_iron"   ] = {1,0},
	["default:stone_with_copper" ] = {1,0},
	["default:stone_with_mese"   ] = {1,0},
	["default:stone_with_diamond"] = {1,0},
	["default:sand"              ] = {1,0},
	["default:gravel"            ] = {2,0},
	["default:ladder"            ] = {2,0},
	["default:ladder"            ] = {2,1}, -- ladder on the wall
	["default:sandstone"         ] = {1,0},
	["default:coalblock"         ] = {2,0},
	["default:steelblock"        ] = {1,0},
	["default:copperblock"       ] = {1,0},
	["default:sign_wall"         ] = {2,1}, -- a sign at eye level
	["default:sign_wall"         ] = {1,0}, -- a sign on floor level
	["default:torch"             ] = {2,1},
	["cottages:shelf"            ] = {4,0},
	["cottages:barrel"           ] = {2,0},
	["cottages:tub"              ] = {1,0},
	["cottages:table"            ] = {1,0},
	["cottages:bench"            ] = {3,0},
	-- burried decorations
	["default:water_source"      ] = {2,-1},
	["air"                       ] = {2,-1},
	["stairs:slab_wood"          ] = {1,-1},
	["stairs:slab_stone"         ] = {1,-1},
	["stairs:slab_cobble"        ] = {1,-1},
	["stairs:stair_wood"         ] = {1,-1},
	["stairs:stair_stone"        ] = {1,-1},
	["stairs:stair_cobble"       ] = {1,-1},
}


-- how many nodes ought to be between two randomly placed decos?
mines_with_shafts.deco_average_distance = 15;

-- set to true in order to get meselamps in vertical shafts all 20 nodes
mines_with_shafts.place_meselamps = false;

-- some tunnels are above ground;
-- they may require a bridge in order to reach further parts of the network;
-- the entrances also become better visible that way
mines_with_shafts.MIN_BRIDGE_LENGTH = 5
-- bridges can never grow longer than this size
mines_with_shafts.MAX_BRIDGE_LENGTH = 12

-- put a mese lamp where a tunnel would be placed above ground (only for debugging purposes)
mines_with_shafts.MARK_TUNNELS = nil; --minetest.get_content_id('default:meselamp');
