require("script/utils")

const = read_only{
	default_turret_range = settings.startup["mass-driver-default-range"].value,
	min_range = 32,
	red = {r=255,g=0,b=0},
	green = {r=0,g=255,b=0},
	blue = {r=0,g=0,b=255},
	inv_root2 = 1/math.sqrt(2),
	stage1_discount = 1000, -- chemical armature reduces effective distance by this amount
	uint_max = 4294967295,
	name = {
		surface = "mass-driver-payload-storage"
	},
}

names = read_only{
	reader = "mass-driver-reader",
	turret = "mass-driver",
	eei = "mass-driver-eei",
	provider = "mass-driver-provider",
	payload = "mass-driver-requester",
	flare = "mass-driver-flare",
	gps = "mass-driver-gps",
	flag = "mass-driver-flag",
	booster_armature = "mass-driver-booster-armature",
	planetary_armature = "mass-driver-planetary-armature",
	signal_x = "signal-X",
	signal_y = "signal-Y",
	signal_surface = "signal-surface",
	gps_copy = "mass-driver.gps-copy",
	gps_paste = "mass-driver.gps-paste",
}


function map_signals(entity)
	local signals = entity.get_merged_signals()
	if signals == nil then return {} end
	local output = {}
	for _,signal in pairs(signals) do
		output[signal.signal.name] = signal.count
	end
	return output
end

function remove_pair(uid)
	local tuple = global.drivers[uid]
	if tuple.turret.valid then
		tuple.turret.destroy()
	end
	if tuple.lamp.valid then
		tuple.lamp.destroy()
	end
	if tuple.eei.valid then
		tuple.eei.destroy()
	end
	global.drivers[uid] = nil
end

function setup_pair(turret)
	local turret_position = turret.position

	local lamp_position = {x = turret_position.x+1, y = turret_position.y+1}
	local ghost = turret.surface.find_entities_filtered{position=lamp_position,radius=0.25,ghost_name=names.reader}[1]
	local lamp = nil
	if ghost then
		_,lamp = ghost.silent_revive()
	else
--		lamp = turret.surface.find_entities_filtered{position=lamp_position,radius=0.25,name=names.reader}[1]
--		if not lamp then
			lamp = turret.surface.create_entity{name=names.reader, position=lamp_position, direction=defines.direction.south, force=turret.force}
--		end
	end
	
	local eei = turret.surface.create_entity{name=names.eei, position={turret_position.x-1,turret_position.y+1}, force=turret.force}
	eei.electric_buffer_size = calculate_energy_cost(global.turret_range[turret.force.index]) + 1000
	eei.operable = false

	global.drivers[turret.unit_number] = {turret=turret, lamp=lamp, eei=eei}
	turret.active = false
	--local parameter = {{signal={type="virtual", name="signal-X"},count=turret.position.x,index=1},{signal={type="virtual", name="signal-Y"},count=turret.position.y,index=2}}
	paste_coordinates(turret,turret.last_user.index)

	global.drivers[turret.unit_number].alert = rendering.draw_text{text="ready", surface=turret.surface,target=turret,target_offset={0,-2},color={r=1,g=1,b=1},forces={turret.force},visible=false,alignment="center"}

end

-- updates all EEI buffers based on their force's range.  If given a force will only update that force's buffers, otherwise updates all buffers
function update_eei_buffers(force)
	for _,v in pairs(global.drivers) do
		if (force == nil or v.eei.force == force) then
			v.eei.electric_buffer_size = calculate_energy_cost(global.turret_range[v.eei.force.index]) + 1000
		end
	end
end

function spill_items(manifest,flag)
	for i = 1,#manifest.get_inventory(defines.inventory.chest) do
		flag.surface.spill_item_stack(flag.position,manifest.get_inventory(defines.inventory.chest)[i],false,flag.force,false)
	end
end



function is_in_range(turret,position)
	return distance_between(turret.position,position) < global.turret_range[turret.force.index] and distance_between(turret.position,position) > const.min_range
end

function iterate_turrets()
	for uid,v in pairs(global.drivers) do
		local turret,lamp = v.turret,v.lamp
		
		-- if the turret or lamp is missing
		if not turret or not turret.valid then
			remove_pair(uid)
		elseif not lamp or not lamp.valid or not v.eei or not v.eei.valid then
			setup_pair(turret)

		-- if the turret isn't shooting, check to see if it can shoot
		elseif not turret.active then 
			local signals = map_signals(lamp)
			if signals == nil then error("signal was nil") end  -- TODO: error checking because this is a fail state
			if signals["signal-check"] and signals["signal-check"] > 0 then
				local target = {
					x = (signals[names.signal_x] or 0) - 0.5,
					y = (signals[names.signal_y] or 0) - 0.5,
				}
				draw_line(turret, target)
				if check_can_fire_turret(turret,target,signals) then
					return true --only one turret can be activated per tick
				end		
			else
				rendering.set_visible(v.alert, false)
			end
		end
	end
	return false
end

function iterate_chests()
	for uid,chest in pairs(global.chests) do
		if not chest or not chest.valid then
			global.chests[uid] = nil
		elseif not chest.has_items_inside() then
			chest.order_deconstruction(chest.force)
			global.chests[chest.unit_number] = nil
		end
	end
end

function check_can_fire_turret(turret, position,signalMap)

	-- don't fire if the target is out of range
	local distance = distance_between(turret.position,position)
	local ammo = turret.get_inventory(defines.inventory.artillery_turret_ammo).is_empty() or turret.get_inventory(defines.inventory.artillery_turret_ammo)[1].name

	-- if gun is empty (result of is_empty() )
	if ammo == true then
		show_error(turret.unit_number,"no-ammo")
		return false
	elseif ammo == names.planetary_armature then -- interplanetary ammo, uses different range checks
		position.surface = signalMap[names.signal_surface] or turret.surface.index
	else
		if distance > global.turret_range[turret.force.index] or distance < const.min_range then
			show_error(turret.unit_number,"out-of-range")
			return false
		end

		if ammo == names.booster_armature then
			distance = distance - const.stage1_discount
			distance = distance > 0 and distance or 0
		end
		position.surface = turret.surface.index
	end

	-- get the chest to load.  if there is no chest, fail
	local chest = turret.surface.find_entities_filtered{position=turret.position,radius=2.9,name=names.payload,force=turret.force, limit=1}[1]
	if not chest then
		show_error(turret.unit_number,"no-payload")
		return false
	end

	-- check if the target is obstructed in blocking mode
	if (signalMap["signal-dot"] and not turret.surface.can_place_entity{name=names.provider,position=position}) then
		show_error(turret.unit_number,"target-obstructed")
		return false
	end

	-- check if there is sufficient energy in the EEI
	local energy = calculate_energy_cost(distance)
	if energy > 0 and energy > global.drivers[turret.unit_number].eei.energy then
		show_error(turret.unit_number,"no-power")
		return false
	end

	-- game.print(serpent.block(signalMap))

	return fire_turret(turret, position, chest, energy)
end


function fire_turret(turret, position, chest, energy)
	
	--if not (turret and position and chest and energy) then
	--	error("Missing variable in scope")
	--end

	
	if not global.chest_surface or not game.surfaces[global.chest_surface] or not game.surfaces[global.chest_surface].valid then
		global.chest_surface = create_chest_surface()
	end
	local proxy = chest.clone{surface=global.chest_surface,position={0.5,0.5}}

	table.insert(global.payloads, {target = position,inventory = proxy, source=turret.unit_number})
	
	local ghostSurface, ghostPosition = chest.surface, chest.position
	chest.die(chest.force)
	ghostSurface.find_entity("entity-ghost", ghostPosition).time_to_live = const.uint_max
	
	ghostSurface.create_entity{name=names.flare,position=position,frame_speed=0,vertical_speed=0,height=0,movement={0,0},force=turret.force}
	global.drivers[turret.unit_number].last_target = position
	turret.active = true

	global.drivers[turret.unit_number].eei.energy = global.drivers[turret.unit_number].eei.energy - energy

	rendering.set_visible(global.drivers[turret.unit_number].alert, false)

	return true
end

function calculate_turret_range(force)
	if force then
		global.turret_range[force.index] = const.default_turret_range * (1 + force.artillery_range_modifier)
	else
		for _,f in pairs(game.forces) do
			global.turret_range[f.index] = const.default_turret_range * (1 + f.artillery_range_modifier)
		end
	end
end

-- generates the surface for storing chests, returning surface index
function create_chest_surface()
	if game.surfaces[const.name.surface] and game.surfaces[const.name.surface].valid then
		return game.surfaces[const.name.surface].index
	end
	local mapgen = game.default_map_gen_settings
	mapgen.height = 1
	mapgen.width = 1
	return game.create_surface(const.name.surface, mapgen).index
end

function paste_coordinates(turret, pid)
	local position = global.gps_coordinates[pid] or turret.position
	if not position.surface then
		position.surface = turret.surface.index
	end
	local reader = global.drivers[turret.unit_number].lamp
	local control = reader.get_or_create_control_behavior()
	control.set_signal(1,{signal={type="virtual",name=names.signal_x},count=position.x})
	control.set_signal(2,{signal={type="virtual",name=names.signal_y},count=position.y})
	control.set_signal(3,{signal={type="virtual",name=names.signal_surface},count=position.surface})
	draw_line(turret, position)
end

script.on_nth_tick(1,function(event) iterate_turrets() iterate_chests() end)

script.on_init(function(event)
	global = {
		payloads = {},
		drivers = {},
		chests = {},
		turret_range = {},
		gps_coordinates = {},
		player_rendering = {},
		settings = {mass = settings.global["mass-driver-payload-mass"].value * 1000},
		chest_surface = create_chest_surface(),
	}
	calculate_turret_range()
end)

script.on_configuration_changed(function(event) 
	calculate_turret_range()
	update_eei_buffers()
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	if (event.setting == "mass-driver-payload-mass") then
		global.settings.mass = settings.global["mass-driver-payload-mass"].value * 1000
	end
end)

script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, function(event) 
	if event.created_entity.name == names.turret then
		setup_pair(event.created_entity)
	end
end)

script.on_event({defines.events.script_raised_built, defines.events.script_raised_revive}, function(event) 
	if event.entity and event.entity.name == names.turret then
		setup_pair(event.entity)
	end
end)

script.on_event({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity,defines.events.on_entity_died,defines.events.script_raised_destroy}, function(event)
	if event.entity and event.entity.name == names.turret then
		remove_pair(event.entity.unit_number)
	end
end)

script.on_event(defines.events.on_entity_cloned, function(event)
	local name = event.destination.name
	if name == names.turret then
		setup_pair(event.destination)
	elseif name == names.eei or name == names.reader then
		event.destination.destroy()
	elseif name == names.provider then
		global.chests[event.destination.unit_number] = event.destination
	end
end)

script.on_event(defines.events.on_trigger_fired_artillery, function(event)
	if event.source and event.source.name == names.turret then
		event.source.active = false

		_,speed = calculate_energy_cost(distance_between(event.source.position,global.drivers[event.source.unit_number].last_target))
		event.source.surface.create_entity{name=event.entity.name,position=event.entity.position,force=event.entity.force,target=global.drivers[event.source.unit_number].last_target,source=event.source,speed=speed*const.inv_root2/60}
		event.entity.destroy()

		-- just waiting on 0.17.70
		-- event.entity.speed = speed
	end
end)

script.on_event(defines.events.on_trigger_created_entity, function(event)
	if event.entity.name == names.flag then
		local position = event.entity.position
		--game.print(serpent.line(position))
		--game.print(serpent.line(event.source.position))
		for k,v in pairs(global.payloads) do
			if (v.target.x == position.x and v.target.y == position.y and (v.surface == nil or v.surface == event.entity.surface.index)) and (event.source and event.source.unit_number == v.source or global.drivers[v.source] == event.source) then
				--local chests = event.entity.surface.find_entities_filtered{name=names.provider,position=position,radius=10,limit=1}
				--local chest = chests[1]
				local chest = event.entity.surface.find_entity(names.provider, event.entity.position)
				if chest then
					--game.print("found a chest")
					local inventory = chest.get_inventory(defines.inventory.chest)
					if v.inventory and v.inventory.valid then
						for i=1,#v.inventory.get_inventory(defines.inventory.chest) do
							chest.insert(v.inventory.get_inventory(defines.inventory.chest)[i])
						end
					else
						log("Invalid payload: " .. serpent.line(v))
					end
					global.chests[chest.unit_number] = chest
				else
					event.entity.surface.create_entity{name="ground-explosion",position=position}
					spill_items(v.inventory,event.entity)
				end
				v.inventory.destroy()
				global.payloads[k] = nil
				goto success
			end
		end
		game.print("Error: No payload found")
		::success::
		event.entity.destroy()
	end
end)

script.on_event(defines.events.on_player_used_capsule, function(event)
	if event.item.name == names.gps then
		local player = game.get_player(event.player_index)
		local turret = player.surface.find_entity(names.turret, event.position)
		if turret then
			paste_coordinates(turret, player.index)
			player.print("GPS coordinates pasted.")
		else
			local pos = {x = math.ceil(event.position.x), y = math.ceil(event.position.y),surface_id = player.surface.index}
			player.print({names.gps_copy,pos.x-0.5, pos.y-0.5,player.surface.name}) --,string.format("[gps=%i,%i] saved to clipboard.", pos.x, pos.y))
			global.gps_coordinates[event.player_index] = pos
		end
	end
end)

script.on_event({defines.events.on_research_finished, defines.events.on_technology_effects_reset}, function(event)
	local force = event.force or (event.research and event.research.force)
	calculate_turret_range(force)
	update_eei_buffers(force)
end)

script.on_event({defines.events.on_chunk_deleted,defines.events.on_surface_cleared, defines.events.on_surface_deleted}, function(event)
	if event.surface_index == global.chest_surface then
		payloads = {}
		game.print("Error: Payload surface was cleared")
		log("Payload surface was cleared")
		global.chest_surface = nil
	end
end)

