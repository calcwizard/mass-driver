

data:extend({
	{
		name = "mass-driver-gps",
		type = "capsule",
		stack_size = 1,
		icon = "__mass-driver__/graphics/icons/gps.png",
		icon_size = 32,
		capsule_action = {
            type = 'throw',
            uses_stack = false,
            attack_parameters = {
                type = 'projectile',
                ammo_category = 'capsule',
                cooldown = 30,
                range = 1000,
                ammo_type = {
                    category = 'capsule',
                    target_type = 'position',
                    action = {
                        type = 'direct',
                        action_delivery = {
                            type = 'instant',
                            target_effects = {
                                type = 'damage',
                                damage = {type='physical', amount=0}
                            }
                        }
                    }
                }
            }
        },

		subgroup = "capsule",
    	order = "zzz",
	},
    {
        name = "mass-driver-gps",
        type = "recipe",
        enabled = true,
        ingredients = {
            {"electronic-circuit",5},
            {"radar", 1},
        },
        energy_required = 1,
        result = "mass-driver-gps",
    },
})