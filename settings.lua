
data:extend({ 	

	-- startup
	{
		type = "int-setting",
		name = "mass-driver-default-range",
		setting_type = "startup",
		minimum_value = 32,
		default_value = 560,
		order = "a"
	},
	{
		type = "bool-setting",
		name = "mass-driver-use-milsci",
		setting_type = "startup",
		default_value = true,
		order = "c"
	},
	{	type = "string-setting",
		name = "mass-driver-provider-type",
		setting_type = "startup",
		allowed_values = {"logistic-chest-active-provider", "logistic-chest-passive-provider","steel-chest"},
		default_value = "logistic-chest-active-provider",
		order = "b"
	},
	{	type = "double-setting",
		name = "mass-driver-payload-mass",
		setting_type = "runtime-global",
		minimum_value = 0.01,
		default_value = 2,
		order = "b"
	}
})

