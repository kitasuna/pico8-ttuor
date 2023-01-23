-- Int -> Int -> Int -> Color[] -> ParticleSource
function flsrc(pos_x, pos_y, grav, colors)
  local tmp = {
    pos_x = pos_x,
    pos_y = pos_y,
    max_vel_y = 2,
    grav = grav,
    ps = {},
    colors = colors,
    direction = nil,
  }

  tmp.reset = function()
    tmp.ps = {}
  end

  tmp.update = function()
    for k, p in pairs(tmp.ps) do
      -- Accel
      p.pos_y += p.vel_y
      if tmp.grav != 0 then
        p.vel_y = mid(-tmp.max_vel_y, p.vel_y + tmp.grav, tmp.max_vel_y)
      end

      p.pos_x += p.vel_x  

      p.ttl -= 1
      if p.ttl <= 0 then
        del(tmp.ps, p)
      end
    end
  end

  tmp.addDir = function(vel_x, vel_y, ttl)
    if tmp.direction == DIRECTION_UP then
      tmp.add(vel_x, -vel_y, true, false, ttl)
    elseif tmp.direction == DIRECTION_DOWN then
      tmp.add(vel_x, vel_y, true, false, ttl)
    elseif tmp.direction == DIRECTION_LEFT then
      tmp.add(-vel_x, vel_y, false, true, ttl)
    elseif tmp.direction == DIRECTION_RIGHT then
      tmp.add(vel_x, vel_y, false, true, ttl)
    end
  end

  tmp.add = function(vel_x, vel_y, jitter_x, jitter_y, ttl)
    local newP = {
      color = tmp.colors[flr(rnd(#tmp.colors)) + 1],
      pos_x = tmp.pos_x,
      pos_y = tmp.pos_y,
      ttl = ttl,
    }
    if jitter_x then
      newP.vel_x = rnd(abs(vel_x)) - (vel_x / 2)
    else
      newP.vel_x = rnd(abs(vel_x))
      if vel_x < 0 then
        newP.vel_x = -newP.vel_x
      end
    end

    if jitter_y then
      newP.vel_y = rnd(abs(vel_y)) - (vel_y / 2)
    else
      newP.vel_y = rnd(abs(vel_y))
      if vel_y < 0 then
        newP.vel_y = -newP.vel_y
      end
    end
    add(tmp.ps, newP)
  end

  tmp.draw = function() 
    for k, p in pairs(tmp.ps) do
     pset(p.pos_x, p.pos_y, p.color)
    end
  end
  return tmp
end
