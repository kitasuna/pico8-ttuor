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

  -- Check if there are any obstacles at these coordinates
  om.check_collision = function(player)
    for k, obs in pairs(om.obstacles) do
      if collides(player, obs) then
        return true
      end
    end
    return false
  end

  -- String -> {pos_x: Int, pos_y: Int, mass: Int }
  om.handle_gravity = function(name, payload)

    -- Find any obs in range
    -- Calculate change in velocity based on distance of obs from payload pos
    for k, obs in pairs(om.obstacles) do
      local dist_x = obs.pos_x+4 - payload.pos_x
      local dist_y = obs.pos_y+4 - payload.pos_y
      local dist_x2 = dist_x * dist_x
      local dist_y2 = dist_y * dist_y
      local gdistance = sqrt(dist_x2 + dist_y2)
      local dist_x_component = -(dist_x / gdistance)
      local dist_y_component = -(dist_y / gdistance)
      local G = 3.0
      local mass = 1.0
      if gdistance < 22*payload.mass then
        obs.vel_x += dist_x_component * (G*mass*payload.mass) / (gdistance * gdistance)
        if obs.vel_x > MAX_VEL then obs.vel_x = MAX_VEL end
        if obs.vel_x < -MAX_VEL then obs.vel_x = -MAX_VEL end
        obs.vel_y += dist_y_component * (G*mass) / (gdistance * gdistance)
        if obs.vel_y > MAX_VEL then obs.vel_y = MAX_VEL end
        if obs.vel_y < -MAX_VEL then obs.vel_y = -MAX_VEL end
      end
    end
  end

  om.handle_obs_grav_collision = function(name, payload)
    printh("OBS GRAV COLL666!")
    del(om.obstacles, payload.obs)
  end

  return om
end

function new_obstacle(coords)
  local tmp = new_sprite(32 + rnd(2), coords.pos_x, coords.pos_y, 8, 6)

  tmp.vel_x = 0
  tmp.vel_y = 0

  tmp.update = function()
    local map_offset_x = 16
    local map_offset_y = 16
    local next_x = (tmp.pos_x + tmp.vel_x - map_offset_x) + (tmp.vel_x > 0 and 7 or 0)
    local next_y = (tmp.pos_y + tmp.vel_y - map_offset_y) + (tmp.vel_y > 0 and 7 or 0)
    local now_map_x = (tmp.pos_x - map_offset_x) \ 8
    local now_map_y = (tmp.pos_y - map_offset_y) \ 8
    local next_map_x = (next_x) \ 8
    local next_map_y = (next_y) \ 8

    if fget(mget(next_map_x, now_map_y), FLAG_FLOOR) == false then
      tmp.vel_x = 0
      if tmp.vel_y != 0 then
        tmp.vel_y = tmp.vel_y / 3
        add(timers, {
          ttl = 40,
          f = function() end,
          cleanup = function()
            tmp.vel_y = 0
          end
        })
        end
    else
      tmp.pos_x += tmp.vel_x
    end

    if fget(mget(now_map_x, next_map_y), FLAG_WALL) == true then
      tmp.vel_y = 0
      if tmp.vel_x != 0 then
        tmp.vel_x = tmp.vel_x / 3
        add(timers, {
          ttl = 40,
          f = function() end,
          cleanup = function()
            tmp.vel_x = 0
          end
        })
      end
    else
      tmp.pos_y += tmp.vel_y
    end

    if tmp.pos_x >= RESOLUTION_X - tmp.size_x then
      tmp.vel_x = -tmp.vel_x
    elseif tmp.pos_x < 0 then
      tmp.vel_x = -tmp.vel_x
    end

    if tmp.pos_y >= RESOLUTION_Y - tmp.size_y then
      tmp.vel_y = -tmp.vel_y
    elseif tmp.pos_y < 0 then
      tmp.vel_y = -tmp.vel_y
    end
  end

  return tmp
end
