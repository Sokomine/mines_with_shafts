

---------------------------------------------------------------------------------------
-- a rope that is of use to the mines
---------------------------------------------------------------------------------------
-- the rope can only be digged if there is no further rope above it;
-- Note: This rope also counts as a rail node; thus, carts can move through it
minetest.register_node("mines_with_shafts:rope", {
        description = "rope for climbing",
        tiles = {"mines_with_shafts_rope.png"},
	groups = {snappy=3,choppy=3,oddly_breakable_by_hand=3,rail=1,connect_to_raillike=1},--connect_to_raillike=minetest.raillike_group("rail")},
        walkable = false,
        climbable = true,
        paramtype = "light",
        sunlight_propagates = true,
        drawtype = "plantlike",
	is_ground_content = false,
	can_dig = function(pos, player)
			local below = minetest.get_node( {x=pos.x, y=pos.y-1, z=pos.z});
			if( below and below.name and below.name == "mines_with_shafts:rope" ) then
				if( player ) then
					minetest.chat_send_player( player:get_player_name(),
						'The entire rope would be too heavy. Start digging at its lowest end!');
				end
				return false;
			end
			return true;
		end
})

minetest.register_craft({
	output = "mines_with_shafts:rope",
	recipe = {
		{"default:cotton","default:cotton","default:cotton"}
        }
})


-- Note: This rope also counts as a rail node; thus, carts can move through it
minetest.register_node("mines_with_shafts:ladder", {
	description = "Ladder with rail support",
	drawtype = "signlike",
	tiles = {"default_ladder.png^default_rail.png^mines_with_shafts_rope.png"},
	inventory_image = "default_ladder.png",
	wield_image = "default_ladder.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	climbable = true,
	is_ground_content = false,
	selection_box = {
		type = "wallmounted",
	},
	groups = {choppy=2,oddly_breakable_by_hand=3,rail=1,connect_to_raillike=1}, --connect_to_raillike=minetest.raillike_group("rail")},
	legacy_wallmounted = true,
	sounds = default.node_sound_wood_defaults(),
})



minetest.register_craft({
	output = "mines_with_shafts:ladder 2",
	recipe = {
		{"default:ladder","default:rail"}
        }
})
