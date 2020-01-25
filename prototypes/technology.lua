

local prereqTech = 	{
	name = "artillery-prerequisite",
	type = "technology",
	icons = {
		{
			icon = data.raw.technology["artillery"].icon,
			icon_size = data.raw.technology["artillery"].icon_size,
			tint = {r=0,g=0,b=0, a=0.5},
		},
	},
	unit = {
		count = 200,
		time = 30,
		ingredients = {
			{"automation-science-pack", 1},
			{"logistic-science-pack", 1},
			{"chemical-science-pack", 1},
			{"military-science-pack", 1},
			{"utility-science-pack", 1},
		}
	},
	prerequisites = {"utility-science-pack"},
	effects = {},
	order = "d-e-g",
}

local driverTech = 	{
	name = "mass-driver",
	type = "technology",
	icons = {
		{
			icon = data.raw.technology["artillery"].icon,
			icon_size = data.raw.technology["artillery"].icon_size,
		},
		{
			icon = "__mass-driver__/graphics/icons/logistic-chest.png",
			icon_size = 32,
			shift = {32,48},
			scale = 1,
		}
	},
	unit = {
		count = 200,
		time = 30,
		ingredients = {
			{"automation-science-pack", 1},
			{"logistic-science-pack", 1},
			{"chemical-science-pack", 1},
			{"military-science-pack", 1},
			{"utility-science-pack", 1},
		}
	},
	prerequisites = {"electric-energy-accumulators","artillery-prerequisite","construction-robotics","circuit-network"},
	effects = {
		{type = "unlock-recipe", recipe = "mass-driver"},
		{type = "unlock-recipe", recipe = "mass-driver-em-armature"},
		{type = "unlock-recipe", recipe = "mass-driver-payload"},
	},
	order = "d-e-h"
}

data:extend({driverTech})
if data.raw.technology["artillery"] then
	table.insert(data.raw.technology["artillery"].effects, {type = "unlock-recipe", recipe = "mass-driver-booster-armature"})
end

-- if the driver prereq tech doesn't exist, add it and restructure the tech tree
if not data.raw.technology["artillery-prerequisite"] then
	data:extend({prereqTech})

	-- restructure the rest of the tech tree to fit the new stuff
	data.raw.technology["artillery"].unit.count = data.raw.technology["artillery"].unit.count - prereqTech.unit.count

	for k,v in pairs(data.raw.technology["artillery-shell-range-1"].prerequisites) do
		if v == "artillery" then
			data.raw.technology["artillery-shell-range-1"].prerequisites[k] = "artillery-prerequisite"
		end
	end

	for k,v in pairs(data.raw.technology["artillery-shell-speed-1"].prerequisites) do
		if v == "artillery" then
			data.raw.technology["artillery-shell-speed-1"].prerequisites[k] = "artillery-prerequisite"
		end
	end

	table.insert(data.raw.technology["artillery"].prerequisites,"artillery-prerequisite")
end



-- milsci removal
local techs = {"artillery-prerequisite", "mass-driver", "artillery-shell-range-1", "artillery-shell-speed-1"}
if not settings.startup["mass-driver-use-milsci"].value then
	for _,tech in pairs(techs) do
		if data.raw.technology[tech] then
			for k,v in pairs(data.raw.technology[tech].ingredients) do
				if v[1] == "military-science-pack" then
					table.remove(data.raw.technology[tech].ingredients,k)
				end
			end
		end
	end
end
