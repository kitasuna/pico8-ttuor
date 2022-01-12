function new_obstacle_manager()
  local om = {
    obstacles = {},
  }

  om.add_obstacle = function(coords)
    local tmp = new_obstacle(coords)
    add(om.obstacles, tmp)
  end

  -- String -> { index: Int }
  om.handle_collision = function(name, payload)
    om.obstacles[payload.index] = nil
  end

  om.handle_gravity = function(name, payload)

    -- Find any obs in range
    -- Calculate change in velocity based on distance of obs from payload pos
    for k, obs in pairs(om.obstacles) do
      local dist_x = obs.pos_x - payload.pos_x
      local dist_y = obs.pos_y - payload.pos_y
      local dist_x2 = dist_x * dist_x
      local dist_y2 = dist_y * dist_y
      local gdistance = sqrt(dist_x2 + dist_y2)
      local dist_x_component = -(dist_x / gdistance)
      local dist_y_component = -(dist_y / gdistance)
      local G = 2.0
      local mass = 1.0
      if gdistance < 48 then
        obs.vel_x += dist_x_component * (G*mass) / (gdistance * gdistance)
        obs.vel_y += dist_y_component * (G*mass) / (gdistance * gdistance)
      end
    end
  end

  return om
end

function new_obstacle(coords)
  local tmp = new_sprite(32, coords.pos_x, coords.pos_y, 6, 6)

  tmp.vel_x = 0
  tmp.vel_y = 0

  tmp.update = function(obs)
    tmp.pos_x += tmp.vel_x
    if tmp.pos_x >= RESOLUTION_X - tmp.size_x then
      tmp.vel_x = -tmp.vel_x
    elseif tmp.pos_x < 0 then
      tmp.vel_x = -tmp.vel_x
    end

    tmp.pos_y += tmp.vel_y
    if tmp.pos_y >= RESOLUTION_Y - tmp.size_y then
      tmp.vel_y = -tmp.vel_y
    elseif tmp.pos_y < 0 then
      tmp.vel_y = -tmp.vel_y
    end
  end

  return tmp
end
