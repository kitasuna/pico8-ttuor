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
        -- g.grow()
      end
    end
  end

  -- String -> { pos_x: Int, pos_y: Int, facing: Int, input_mask: Int }
  gm.handle_button = function(name, payload)

    if (payload.input_mask & (1 << BTN_O)) > 0 and count(gm.gravities) < 1 then
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
      grav_count += 1

      add(gm.gravities, tmp)
    elseif (payload.input_mask & (1 << BTN_O)) == 0 and count(gm.gravities) > 0 then
      for k, g in pairs(gm.gravities) do
        g.release()
      end
    end

    if (payload.input_mask & (1 << BTN_X)) > 0 then
      -- Launch gravity, so eliminate existing gravs?
      -- Maybe need to work this out in level design first
    end
  end

  gm.update = function()
    for k, g in pairs(gm.gravities) do
      g.update()
      if g.state == "DEAD" then
        del(gm.gravities, g)
      end
    end
  end

  return gm
end

function new_gravity(coords)
  local tmp = new_sprite(48, coords.pos_x, coords.pos_y, 4, 8, false, false)

  tmp.mass = 1
  tmp.ttl = 30
  tmp.state = "HELD"
  -- tmp.frame_base = 48
  tmp.frames = {48, 49, 50}
  tmp.frame_index = 1
  tmp.frame_half_step = 1
  tmp.frame_step = 4

  tmp.update = function()
    if tmp.state == "PERSISTENT" then
      tmp.frames = {37, 38, 39}
    end

    if tmp.state == "RELEASED" then
      tmp.ttl -= 1
      if tmp.ttl <= 0 then
        tmp.state = "DEAD"
      end
    end

    tmp.frame_half_step += 1
    if tmp.frame_half_step > tmp.frame_step then
      tmp.frame_half_step = 1
      tmp.frame_index += 1
      if tmp.frame_index > count(tmp.frames) then
        tmp.frame_index = 1
      end
    end
  end

  tmp.release = function()
    if tmp.state == "HELD" and tmp.mass == 1 then
      tmp.state = "RELEASED"
    elseif tmp.state == "HELD" and tmp.mass > 1 then
      tmp.state = "PERSISTENT"
    end
  end

  tmp.draw = function()
    spr(tmp.frames[tmp.frame_index], tmp.pos_x, tmp.pos_y, 1.0, 1.0, tmp.flip_x, tmp.flip_y)
    circ(tmp.pos_x+4, tmp.pos_y+4, 22, CLR_RED)
  end

  return tmp

end

