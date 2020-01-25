
data:extend({
	{
		type = "recipe",
		name = "mass-driver",
		enabled = false,
		ingredients = {
			{"advanced-circuit", 20},
			{"concrete", 60},
			{"iron-gear-wheel",20},
			{"steel-plate",20},
			{"accumulator",10},
			{"radar",1},
		},
		energy_required = 30,
		result = "mass-driver",
	},
	{
		type = "recipe",
		name = "mass-driver-em-armature",
		enabled = false,
		ingredients = {
			{"steel-plate", 10},
		},
		energy_required = 4,
		result = "mass-driver-em-armature",
	},
	{
		type = "recipe",
		name = "mass-driver-booster-armature",
		enabled = false,
		ingredients = {
			{"mass-driver-em-armature",1},
			{"rocket-fuel",10},
			{"low-density-structure",2},
		},
		energy_required = 10,
		result = "mass-driver-booster-armature",
	},
	{
		type = "recipe",
		name = "mass-driver-payload",
		enabled = false,
		ingredients = {
			{"low-density-structure", 8},
			{"electronic-circuit", 3},
			{"advanced-circuit", 1},
		},
		energy_required = 1,
		result = "mass-driver-payload",
	},
})