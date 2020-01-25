

function redraw_lines()
	local visible = #global.player_rendering > 0
	for k,v in pairs(global.drivers) do
		if v.render then
			rendering.set_players(v.render, global.player_rendering)
			rendering.set_visible(v.render, visible)
		else
			log("Mass driver id# "..k.." doesn't have a valid line rendering")
		end
	end
end

function draw_line(turret, position)
	-- position.x,position.y = position.x - 0.5, position.y - 0.5
	local tid = turret.unit_number
	local color = is_in_range(turret,position) and const.green or const.red
	if global.drivers[tid].render then
		rendering.set_color(global.drivers[tid].render, color)
		rendering.set_to(global.drivers[tid].render, position)
	else
		global.drivers[tid].render = rendering.draw_line{color=color,width="2",from=turret,to=position,surface=turret.surface,forces={turret.force}}
	end
	redraw_lines()
end

function render_gps(event)
	if game.get_player(event.player_index).cursor_stack and game.get_player(event.player_index).cursor_stack.valid_for_read and game.get_player(event.player_index).cursor_stack.name == "mass-driver-gps" then
		global.player_rendering[event.player_index] = event.player_index
		redraw_lines()
	else
		if global.player_rendering[event.player_index] then 
			global.player_rendering[event.player_index] = nil
			redraw_lines()
		end
	end
end

-- displays a floating-text error message above a turret
function show_error (turretID, message)
	rendering.set_text(global.drivers[turretID].alert, {"mass-driver-error." .. message})
	rendering.set_visible(global.drivers[turretID].alert, true)

	--[[
	if not global.drivers[turret.unit_number].last_alert or game.tick > global.drivers[turret.unit_number].last_alert + 60 then
		turret.surface.create_entity{name="stationary-flying-text", position={turret.position.x-.5,turret.position.y-1},force=turret.force,text=message}
		global.drivers[turret.unit_number].last_alert = game.tick
	end
	]]
end