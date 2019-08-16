

local lubethrower_entity = util.table.deepcopy(data.raw["fluid-turret"]["flamethrower-turret"])
lubethrower_entity.name = "lubethrower-turret"
lubethrower_entity.minable = {mining_time = 0.5, result = "lubethrower-turret"}
lubethrower_entity.attack_parameters.min_range = 1
lubethrower_entity.attack_parameters.range = 10
lubethrower_entity.attack_parameters.fluids = {{type="lubricant"}}
lubethrower_entity.attack_parameters.ammo_type =
      {
        category = "flamethrower",
        action =
        {
          type = "direct",
          action_delivery =
          {
            type = "stream",
            stream = "lubethrower-stream",
            source_offset = {0.15, -0.5}
          }
        }
      }


local lubethrower_stream = util.table.deepcopy(data.raw.stream["flamethrower-fire-stream"])
lubethrower_stream.name = "lubethrower-stream"
lubethrower_stream.particle_horizontal_speed = 0.2* 0.75 * 1.5*5
lubethrower_stream.action =
    {
      {
        type = "area",
        radius = 2.5,
        action_delivery =
        {
          type = "instant",
          target_effects =
          {
            {
              type = "create-sticker",
              sticker = "speedup-sticker"
            }
          }
        }
      }
    }



local speedup_sticker = util.table.deepcopy(data.raw.sticker["slowdown-sticker"])
speedup_sticker.name = "speedup-sticker"
speedup_sticker.target_movement_modifier = 10


local lubethrower_item = util.table.deepcopy(data.raw.item["flamethrower-turret"])
lubethrower_item.name = "lubethrower-turret"
lubethrower_item.place_result = "lubethrower-turret"



data:extend({lubethrower_entity, lubethrower_stream, speedup_sticker, lubethrower_item})
