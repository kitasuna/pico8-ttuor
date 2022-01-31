function new_obstacle_manager()
  local om = {
    obstacles = {},
  }

  om.add_obstacle = function(coords)
    local tmp = new_obstacle(coords)
    add(om.obstacles, tmp)
  end

  om.reset = function()
    om.obstacles = {}
  end

  -- String -> Obstacle -> Void
  om.handle_collision = function(name, payload)
    -- Bounce off player
    if payload.obstacle.vel_x != 0 or payload.obstacle.vel_y != 0 then
      payload.obstacle.vel_x = -payload.obstacle.vel_x
      payload.obstacle.vel_y = -payload.obstacle.vel_y
    end

  end

  -- Check if there are any obstacles at these coordinates
  om.check_collision = function(player)
    for k, obs in pairs(om.obstacles) do
      if collides(player, obs) then
        return true
      end
    end
    return false
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
      local mass = 3.0
      if gdistance < 2 then
        obs.vel_x = 0
        obs.vel_y = 0
      elseif gdistance < 48 then
        obs.vel_x += dist_x_component * (G*mass) / (gdistance * gdistance)
        if obs.vel_x > MAX_VEL then obs.vel_x = MAX_VEL end
        if obs.vel_x < -MAX_VEL then obs.vel_x = -MAX_VEL end
        obs.vel_y += dist_y_component * (G*mass) / (gdistance * gdistance)
        if obs.vel_y > MAX_VEL then obs.vel_y = MAX_VEL end
        if obs.vel_y < -MAX_VEL then obs.vel_y = -MAX_VEL end
      end
    end
  end

  return om
end

function new_obstacle(coords)
  local tmp = new_sprite(32 + rnd(2), coords.pos_x, coords.pos_y, 8, 6)

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
