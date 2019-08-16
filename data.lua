require("lualib/utils")
--require("prototypes.projectiles")
--require("prototypes.technology")
--require("prototypes.recipe")
--require("prototypes.entity")

gun = copy_prototype("gun", "artillery-wagon-cannon", "mass-driver-cannon")
gun.attack_parameters.ammo_category = "driver-armature"

turret = copy_prototype("artillery-turret", "artillery-turret","mass-driver")
turret.gun = gun.name
turret.disable_automatic_firing = true

turretItem = copy_prototype("item","artillery-turret","mass-driver")

flare = copy_prototype("artillery-flare","artillery-flare","mass-driver-flare")
flare.shot_category = "driver-armature"

lamp = copy_prototype("lamp","small-lamp","mass-driver-reader")
lamp.energy_source = {type="void"}
lamp.always_on = true
lamp.minable = nil
lamp.order = "mass-driver-lamp"

projectile = copy_prototype("artillery-projectile","artillery-projectile","driver-projectile")
projectile.action = {
	{
		type = "direct",
		action_delivery = {
			{
				type = "instant",
				target_effects = {
					{
						type = "create-trivial-smoke",
						smoke_name = "artillery-smoke",
						initial_height = 0,
						speed_from_center = 0.05,
						speed_from_center_deviation = 0.005,
						offset_deviation = {{-4,-4},{4,4}},
						max_radius = 3.5,
						repeat_count = 4*4*15,
					},
				}
			}
		}
	},
	{
		type = "area",
		radius = .5,
		action_delivery =
		{
		 	type = "instant",
			target_effects =
			{
				{
					type = "damage",
					damage = {amount = 1000, type = "physical"}
				}
			}
		}
	}
}

projectile.final_action = {
	type = "direct",
	action_delivery =
	{
		type = "instant",
		target_effects = {
			{
				type = "create-entity",
				entity_name = "small-scorchmark",
				check_buildability = true
			},
			{
				type = "create-entity",
				entity_name = "mass-driver-provider",
				check_buildability = true,
				trigger_created_entity = true,
			}
		}
	}
}

chestRequester = copy_prototype("logistic-container","logistic-chest-requester","mass-driver-requester")
chestRequester.minable.result = "driver-payload"

chestProvider = copy_prototype("logistic-container","logistic-chest-active-provider","mass-driver-provider")
chestProvider.minable.result = "driver-payload"
chestProvider.placeable_by = {item = "driver-payload", count = 1}

chestItem = copy_prototype("item","logistic-chest-requester","driver-payload")
chestItem.place_result = "mass-driver-requester"

-- So the vanilla turret doesn't nuke the chest
data.raw["artillery-flare"]["artillery-flare"].shot_category = "artillery-shell"

data:extend({
	{
		type = "ammo-category",
		name = "driver-armature"
	},
	{
		type = "recipe",
		name = "mass-driver",
		enabled = false,
		ingredients = {
			{"artillery-turret", 1},
		},
		energy_required = 10,
		result = "mass-driver",
	},
	{
		type = "recipe",
		name = "driver-armature",
		enabled = false,
		ingredients = {
			{"steel-plate", 10},
			{"battery", 10},
		},
		energy_required = 6,
		result = "driver-armature",
	},
	{
		type = "recipe",
		name = "driver-payload",
		enabled = false,
		ingredients = {
			{"low-density-structure", 5},
			{"electronic-circuit", 3},
			{"advanced-circuit", 1},
		},
		energy_required = 1,
		result = "driver-payload",
	},
	{
		type = "ammo",
		name = "driver-armature",
		icon = "__base__/graphics/icons/artillery-shell.png",
		icon_size = 32,
		ammo_type =
		{
		  category = "driver-armature",
		  target_type = "position",
		  action =
		  {
		    type = "direct",
		    action_delivery =
		    {
		      type = "artillery",
		      projectile = "driver-projectile",
		      starting_speed = 1,
		      direction_deviation = 0,
		      range_deviation = 0,
		      trigger_fired_artillery = true,
		      source_effects =
		      {
		        type = "create-explosion",
		        entity_name = "artillery-cannon-muzzle-flash"
		      },
		    }
		  },
		},
		subgroup = "ammo",
		order = "d[explosive-cannon-shell]-r[driver]",
		stack_size = 1,
	},
	gun,turret,turretItem,flare,projectile,chestProvider,chestRequester,chestItem,lamp
})