

function map_signals(entity)
	local signals = entity.get_merged_signals()
	if signals == nil then return nil end
	local output = {}
	for _,signal in pairs(signals) do
		output[signal.signal.name] = signal.count
	end
	return output
end


function iterate_turrets()
	for uid,v in pairs(global.drivers) do
		local turret,lamp = v.turret,v.lamp
		
		-- if the turret isn't shooting, check to see if it can shoot
		if not turret.active then 
			signals = map_signals(lamp)
			if signals == nil then return false end  -- TODO: error checking because this is a fail state
			if signals["signal-check"] and signals["signal-check"] > 0 then
				local x = signals["signal-X"] - 0.5 or -0.5
				local y = signals["signal-Y"] - 0.5 or -0.5
				if fire_turret(turret,{x=x,y=y}) then
					return true --only one turret can be activated per tick
				end
			end
		end
	end
	return false
end

function iterate_chests()
	for uid,chest in pairs(global.chests) do
		if chest == nil or not chest.has_items_inside() then
			chest.order_deconstruction(chest.force)
			global.chests[chest.unit_number] = nil
		end
	end
end

function fire_turret(turret, position)
	--game.print("pew-pewing at: " .. serpent.block(position))

	--don't fire if the turret doesn't have ammo
	if turret.get_inventory(defines.inventory.artillery_turret_ammo).is_empty() then
		return false
	end




	--local x,y = event.entity.position.x, event.entity.position.y
	for _,entity in pairs(turret.surface.find_entities_filtered{position=turret.position,radius=3,name="mass-driver-requester",force=turret.force, limit=1}) do
		
		table.insert(global.payloads, {target = position,inventory = entity.get_inventory(defines.inventory.chest).get_contents()})
		entity.die(entity.force)
		turret.surface.create_entity{name="mass-driver-flare",position=position,frame_speed=0,vertical_speed=0,height=0,movement={0,0},force=turret.force}
		turret.active = true
		return true
	end
end



script.on_nth_tick(1,function(event) iterate_turrets() iterate_chests() end)

script.on_init(function(event)
	global.payloads = {}
	global.drivers = {}
	global.chests = {}
end)

script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, function(event) 
	if event.created_entity.name == "mass-driver" then
		local turret = event.created_entity
		local lamp_position = turret.position
		lamp_position.x, lamp_position.y = lamp_position.x+1, lamp_position.y+1
		local lamp = turret.surface.create_entity{name="mass-driver-reader", position=lamp_position, force=turret.force}
		global.drivers[turret.unit_number] = {turret=turret, lamp=lamp}
		turret.active = false
	end
end)

script.on_event({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity,defines.events.on_entity_died}, function(event)
	if event.entity.name == "mass-driver" then
		local entity = event.entity
		for _,e in pairs(entity.surface.find_entities_filtered{area=entity.bounding_box,name="mass-driver-reader"}) do
			e.destroy()
		end
		global.drivers[entity.unit_number] = nil
	end
end)


script.on_event(defines.events.on_trigger_fired_artillery, function(event)
	event.source.active = false
end)

script.on_event(defines.events.on_trigger_created_entity, function(event)
	if event.entity.name == "mass-driver-provider" then
		local chest = event.entity
		local inventory = event.entity.get_inventory(defines.inventory.chest)
		for k,v in pairs(global.payloads) do
			if (v.target.x == chest.position.x and v.target.y == chest.position.y) then
				for item,num in pairs(v.inventory) do
					inventory.insert{name=item,count=num}
				end
				global.payloads[k] = nil
				break
			end
		end
		global.chests[chest.unit_number] = chest
		--event.entity.order_deconstruction(event.entity.force)
	end
end)