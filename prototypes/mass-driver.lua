function scale_picture(picture, scale)
	for k,v in pairs(picture.layers) do
		v.scale = (v.scale or 1) * scale
		if v.hr_version then
			v.hr_version.scale = (v.hr_version.scale or 1) * scale
		end
	end
end

local gun = copy_prototype("gun", "artillery-wagon-cannon", "mass-driver-cannon")
gun.attack_parameters.ammo_category = "mass-driver-armature"
gun.attack_parameters.range = settings.startup["mass-driver-default-range"].value
gun.attack_parameters.cooldown = 60

local turret = copy_prototype("artillery-turret", "artillery-turret","mass-driver")
turret.gun = gun.name
turret.disable_automatic_firing = true
turret.manual_range_modifier = 1
turret.collision_box = {{-.95,-.95},{.95,.95}}
turret.tile_height = 3
turret.tile_width = 3

local turretItem = {
    type = "item",
    name = "mass-driver",
    icons = {
		{
		   	icon = "__mass-driver__/graphics/icons/mass-driver.png",
    		icon_size = 32,
    		--tint = {r=0,g=0,b=255}
    	},
    	{
    	    icon = "__mass-driver__/graphics/icons/mass-driver.png",
    		icon_size = 32,
    		tint = {r=0,g=0,b=255,a=80}
    	},	
	},
    subgroup = "defensive-structure",
    order = "b[turret]-d[mass-driver]",
    place_result = "mass-driver",
    stack_size = 10
 }

local flare = copy_prototype("artillery-flare","artillery-flare","mass-driver-flare")
flare.shot_category = "mass-driver-armature"

local reader = copy_prototype("constant-combinator","constant-combinator","mass-driver-reader")
reader.item_slot_count = 3
reader.minable = nil
reader.order = "mass-driver-reader"
reader.collision_box = nil --{{-.1,-.1},{.1,.1}}
reader.tile_width = 1
reader.tile_height = 1
--reader.selectable_in_game = false
table.insert(reader.flags,"not-deconstructable")
table.insert(reader.flags,"not-selectable-in-game")
--reader.placeable_by = {item = "constant-combinator", count = 1}

local readerItem = {
	type = "item",
	name = "mass-driver-reader",
	icon = "__core__/graphics/empty.png",
	icon_size = 1,
	flags = {"hidden"},
	place_result="mass-driver-reader",
	order = "c[combinators]-c[mass-driver-reader]",
	stack_size=1
}


local chestItem = copy_prototype("item","logistic-chest-requester","mass-driver-payload")
chestItem.place_result = "mass-driver-requester"
chestItem.icon = "__mass-driver__/graphics/icons/logistic-chest.png"
chestItem.icon_size = 32

-- Chest before launch --
local chestRequester = copy_prototype("logistic-container","logistic-chest-requester","mass-driver-requester")
chestRequester.icon = chestItem.icon
chestRequester.icon_size = chestItem.icon_size
chestRequester.inventory_size = const.inventory_size
chestRequester.minable.result = "mass-driver-payload"
chestRequester.animation.layers[1].filename = "__mass-driver__/graphics/entities/logistic-chest/logistic-chest-requester.png"
chestRequester.animation.layers[1].hr_version.filename = "__mass-driver__/graphics/entities/logistic-chest/hr-logistic-chest-requester.png"
chestRequester.corpse = nil
chestRequester.dying_explosion = nil

local chestProvider = nil
-- Chest after landing --
if settings.startup["mass-driver-provider-type"].value == "steel-chest" then
	chestProvider = copy_prototype("container",settings.startup["mass-driver-provider-type"].value,"mass-driver-provider")
	chestProvider.picture.layers[1].filename = "__mass-driver__/graphics/entities/logistic-chest/logistic-chest-requester.png"
	chestProvider.picture.layers[1].height = 38 
	chestProvider.picture.layers[1].hr_version.filename = "__mass-driver__/graphics/entities/logistic-chest/hr-logistic-chest-requester.png"
	chestProvider.picture.layers[1].hr_version.height = 74
else
	chestProvider = copy_prototype("logistic-container",settings.startup["mass-driver-provider-type"].value,"mass-driver-provider")
	chestProvider.animation.layers[1].filename = "__mass-driver__/graphics/entities/logistic-chest/logistic-chest-requester.png"
	chestProvider.animation.layers[1].hr_version.filename = "__mass-driver__/graphics/entities/logistic-chest/hr-logistic-chest-requester.png"
end
chestProvider.icon = chestItem.icon
chestProvider.icon_size = chestItem.icon_size
chestProvider.inventory_size = const.inventory_size
chestProvider.minable.result = "mass-driver-payload"
chestProvider.placeable_by = {item = "mass-driver-payload", count = 1}

local chestProxy = copy_prototype("container","steel-chest","mass-driver-chest-proxy")
chestProxy.flags = {"hidden", "not-on-map","not-selectable-in-game"}
chestProxy.order="zzz"
chestProxy.minable=nil
chestProxy.collision_box = nil
chestProxy.selection_box = nil

local projectile = copy_prototype("artillery-projectile","artillery-projectile","driver-projectile")
projectile.action = {
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
					damage = {amount = 2000, type = "impact"}
				}
			}
		}
	},
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
					{
						type = "create-entity",
						entity_name = "mass-driver-provider",
						check_buildability = true,
					},
					{
						type = "create-entity",
						entity_name = "mass-driver-flag",
						trigger_created_entity = true,
					},
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
			--[[{
				type = "create-entity",
				entity_name = "mass-driver-provider",
				check_buildability = true,
				trigger_created_entity = true,
			}]]
		}
	}
}
projectile.picture = { 
	filename = chestRequester.animation.layers[1].filename,
	height = 38,
	width = 34,
	scale = .5,
}
projectile.shadow.filename = "__mass-driver__/graphics/entities/artillery-projectile/hr-shell-shadow.png"
projectile.chart_picture.filename = "__mass-driver__/graphics/entities/artillery-projectile/artillery-shoot-map-visualization.png"
projectile.height_from_ground = 280 / 64






-- So the vanilla turret doesn't nuke the chest
data.raw["artillery-flare"]["artillery-flare"].shot_category = "artillery-shell"

data:extend({
	{
		type = "ammo-category",
		name = "mass-driver-armature"
	},
	{
		type = "ammo",
		name = "mass-driver-em-armature",
		icons = {
			{ 
				icon = "__base__/graphics/icons/artillery-shell.png",
				icon_size = 64,
			},
			{ 
				icon = "__base__/graphics/icons/artillery-shell.png",
				icon_size = 64,
				tint = {r=0,g=0,b=255,a=50},
			},
		},
		ammo_type =
		{
		  category = "mass-driver-armature",
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
		order = "d[explosive-cannon-shell]-r[driver]a",
		stack_size = 10,
	},
	{
		type = "ammo",
		name = "mass-driver-booster-armature",
		icons = {
			{ 
				icon = "__base__/graphics/icons/artillery-shell.png",
				icon_size = 64,
			},
			{ 
				icon = "__base__/graphics/icons/artillery-shell.png",
				icon_size = 64,
				tint = {r=255,g=0,b=0,a=50},
			},
		},
		ammo_type =
		{
		  category = "mass-driver-armature",
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
		order = "d[explosive-cannon-shell]-r[driver]b",
		stack_size = 1,
	},
	{
		name = "mass-driver-flag",
		type = "simple-entity",
		pictures = flare.pictures,
		flags = {"hidden", "not-on-map","not-selectable-in-game"},
		collision_mask = {},


	},
	{
		type = "electric-energy-interface",
	    name = "mass-driver-eei",
	    icons = turretItem.icons,
	    localised_name = {"entity-name.mass-driver"},
	    flags = {},
	    max_health = 150,
	    collision_box = {{-0.4,-2.4},{2.4,0.4}},
	    selection_box = {{-0.5, -2.5}, {2.5, 0.5}},
	    selectable_in_game = false,
	    energy_source ={
			type = "electric",
			buffer_capacity = "1MJ",
			usage_priority = "secondary-input",
			input_flow_limit = "2MW"
		},
	    energy_production = "0W",
	    energy_usage = "0W",
	    picture =
	    {
	      filename = "__core__/graphics/empty.png",
	      priority = "extra-high",
	      width = 1,
	      height = 1
	    },
	    order = "h-e-e-i-1",
	},
	{
	    type = "virtual-signal",
	    name = "signal-surface",
	    icon = "__core__/graphics/icons/category/surface-editor.png",
	    icon_size = 128, icon_mipmaps = 2,
	    subgroup = "virtual-signal",
	    order = "e[signal]-[4surface]"
	},
	gun,turret,turretItem,flare,projectile,chestProvider,chestRequester,chestProxy,chestItem,reader,readerItem
})

