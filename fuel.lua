function new_fuel_manager()
  local fm = {
    fuels = {},
  }

  fm.add_fuel = function(coords)
    local tmp = new_fuel(coords)
    add(fm.fuels, tmp)
  end

  fm.reset = function()
    fm.fuels = {}
  end

  -- String -> Fuel -> Void
  fm.handle_collision = function(name, payload)
    del(fm.fuels, payload)
  end

  -- String -> { pos_x: Int, pos_y: Int }
  fm.handle_gravity = function(name, payload)

    -- Find any fuel in range
    -- Calculate change in velocity based on distance of fuel from payload pos
    for k, fuel in pairs(fm.fuels) do
      local dist_x = fuel.pos_x - payload.pos_x
      local dist_y = fuel.pos_y - payload.pos_y
      local dist_x2 = dist_x * dist_x
      local dist_y2 = dist_y * dist_y
      local gdistance = sqrt(dist_x2 + dist_y2)
      local dist_x_component = -(dist_x / gdistance)
      local dist_y_component = -(dist_y / gdistance)
      local G = 2.0
      local fuel_mass = 1.0
      if gdistance < 48 then
        fuel.vel_x += dist_x_component * (G*fuel_mass) / (gdistance * gdistance)
        if fuel.vel_x > MAX_VEL then fuel.vel_x = MAX_VEL end
        if fuel.vel_x < -MAX_VEL then fuel.vel_x = -MAX_VEL end
        fuel.vel_y += dist_y_component * (G*fuel_mass) / (gdistance * gdistance)
        if fuel.vel_y > MAX_VEL then fuel.vel_y = MAX_VEL end
        if fuel.vel_y < -MAX_VEL then fuel.vel_y = -MAX_VEL end
      end
    end
  end

  return fm
end

function new_fuel(coords)
  local tmp = new_sprite(3, coords.pos_x, coords.pos_y, 4, 6)

  tmp.vel_x = 0
  tmp.vel_y = 0

  tmp.update = function(fuel)
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

