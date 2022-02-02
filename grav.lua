function new_gravity()
  local tmp = {
    active = false,
    cooldown = false,
    crit_mass = 0,
    size_x = 8,
    size_y = 8,
    pos_x = 0,
    pos_y = 0,
    sprites = {}
  }

  -- String -> { obs: Obstacle }
  tmp.handle_obs_grav_collision = function(name, payload)
    printh("OBS GRAV COLL!")
    tmp.crit_mass += 1
  end

  -- String -> { pos_x: Int, pos_y: Int, input_mask: Int }
  tmp.handle_button = function(name, payload)
    if count(tmp.sprites) > 0 then
      return
    end

    if (payload.input_mask & (1 << 1)) > 0 then
      if tmp.cooldown == true then
        return
      end

      tmp.active = true
      if payload.facing == 0 then
        tmp.pos_x = payload.pos_x
        tmp.pos_y = payload.pos_y - 10
      elseif payload.facing == 2 then
        tmp.pos_x = payload.pos_x
        tmp.pos_y = payload.pos_y + 10
      elseif payload.facing == 1 then
        tmp.pos_x = payload.pos_x + 10
        tmp.pos_y = payload.pos_y
      else
        tmp.pos_x = payload.pos_x - 10
        tmp.pos_y = payload.pos_y
      end

      add(tmp.sprites, new_sprite(16, tmp.pos_x, tmp.pos_y, 4, 8, false, false))
      -- Display sprite for 30 frames
      add(timers, {
        ttl = 30,
        f = function() end,
        cleanup = function()
          tmp.active = false
          tmp.cooldown = true
          tmp.sprites = {}
        end
      })
      -- Have an add'l 30 frames of cooldown
      add(timers, {
        ttl = 60,
        f = function() end,
        cleanup = function()
          tmp.active = false
          tmp.cooldown = false
          tmp.sprites = {}
        end
      })
    end
  end

  tmp.reset = function()
    tmp.active = false
    tmp.cooldown = false
    tmp.pos_x = 256
    tmp.pos_y = 256
    tmp.sprites = {}
  end

  return tmp
end

