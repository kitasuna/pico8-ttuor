function new_gravity_manager()
  local gm = {
    gravities = {},
  }

  gm.add_gravity = function(coords)
    local tmp = new_gravity(coords)
    add(om.obstacles, tmp)
  end

  gm.reset = function()
    gm.gravities = {}
  end

  -- Used to check for obstacle / gravity collision
  gm.check_collision = function(obs)
    for k, g in pairs(gm.gravities) do
      if collides(obs, g) then
        return true
      end
    end
    return false
  end

  -- String -> { obs: Obstacle, grav: Gravity }
  gm.handle_obs_grav_collision = function(name, payload)
    -- TODO also change sprite here
    for k, g in pairs(gm.gravities) do
      if g == payload.grav then
        g.mass += 1
        g.num = 37
      end
    end
  end

  -- String -> { pos_x: Int, pos_y: Int, facing: Int, input_mask: Int }
  gm.handle_button = function(name, payload)
    if (payload.input_mask & (1 << 1)) > 0 then
      local pos_x = payload.pos_x
      local pos_y = payload.pos_y
      if payload.facing == 0 then
        pos_x = payload.pos_x
        pos_y = payload.pos_y - 10
      elseif payload.facing == 2 then
        pos_x = payload.pos_x
        pos_y = payload.pos_y + 10
      elseif payload.facing == 1 then
        pos_x = payload.pos_x + 10
        pos_y = payload.pos_y
      else
        pos_x = payload.pos_x - 10
        pos_y = payload.pos_y
      end

      local tmp = new_gravity({pos_x=pos_x, pos_y=pos_y})

      add(gm.gravities, tmp)

      -- Display sprite for 30 frames
      add(timers, {
        ttl = 30,
        f = function() end,
        cleanup = function()
          if tmp.mass <= 1 then
            del(gm.gravities, tmp)
          end
        end
      })
    end
  end

  return gm
end

function new_gravity(coords)
  local tmp = new_sprite(16, coords.pos_x, coords.pos_y, 4, 8, false, false)

  tmp.active = true
  tmp.mass = 1


  return tmp
end

