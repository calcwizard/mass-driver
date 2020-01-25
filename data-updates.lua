
local techs = {"artillery-prerequisite","mass-driver",}

-- Industrial Revolution
if mods["IndustrialRevolution"] then
	for k,v in pairs(data.raw.technology["mass-driver"].prerequisites) do
		if v == "construction-robotics" then
			 data.raw.technology["mass-driver"].prerequisites[k] = "personal-roboport-equipment"
		end
	end
end