
local count = 0
for pid,coordinates in pairs(global.gps_coordinates) do
	coordinates.surface = coordinates.surface or game.get_player(pid).surface.index
	count = count + 1
end
log(string.format("Updated %d player's coordinates",count))

count = 0
for turret_id,tuple in pairs(global.drivers) do
	if tuple.lamp.valid then
		if not tuple.lamp.get_or_create_control_behavior().get_signal(3).signal then
			tuple.lamp.get_control_behavior().set_signal(3,{signal={type="virtual",name="signal-surface"},count=tuple.lamp.surface.index})
			count = count + 1
		end
	end
end
log(string.format("Updated %d targeting computers",count))

count = 0
for _,payload in pairs(global.payloads) do
	if not payload.target.surface then
		if global.drivers[payload.source].turret.valid then --does the turret still exist?
			payload.target.surface = global.drivers[payload.source].turret.surface.index
			count = count + 1
		end
	end
end
log(string.format("Updated %d payloads",count))