
-- if artillery is already researched, research the prereq for it too
for _,force in pairs(game.forces) do
	if force.technologies["artillery"] and force.technologies["artillery"].researched then
		force.technologies["artillery-prerequisite"].researched = true
	end
end

