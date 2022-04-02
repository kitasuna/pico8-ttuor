function new_gravity_manager()
  local gm = {
    gravities = {},
    projectiles = {},
  }

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

  -- String -> { entity: Entity, grav: Gravity }
  gm.handle_ent_grav_collision = function(name, payload)
    for k, g in pairs(gm.gravities) do
      if g == payload.grav then
        -- g.grow()
      end
    end
  end

  -- String -> { projectile: Projectile }
  gm.handle_proj_player_collision = function(name, payload)
    del(gm.projectiles, payload.projectile) 
  end

  gm.handle_player_death = function(name, payload)
    for k, g in pairs(gm.gravities) do
      del(gm.gravities, g) 
    end
    for k, g in pairs(gm.projectiles) do
      del(gm.projectiles, g) 
    end
  end

  -- String -> { pos_x: Int, pos_y: Int, direction: Int, input_mask: Int }
  gm.handle_button = function(name, payload)

    if (payload.input_mask & (1 << BTN_O)) > 0 and count(gm.gravities) < 1 then
      local pos_x = payload.pos_x
      local pos_y = payload.pos_y
      if payload.direction == 0 then
        pos_x = payload.pos_x
        pos_y = payload.pos_y - 10
      elseif payload.direction == 2 then
        pos_x = payload.pos_x
        pos_y = payload.pos_y + 10
      elseif payload.direction == 1 then
        pos_x = payload.pos_x + 10
        pos_y = payload.pos_y
      else
        pos_x = payload.pos_x - 10
        pos_y = payload.pos_y
      end

      local tmp = new_gravity({pos_x=pos_x, pos_y=pos_y})

      add(gm.gravities, tmp)
    elseif (payload.input_mask & (1 << BTN_O)) == 0 and count(gm.gravities) > 0 then
      for k, g in pairs(gm.gravities) do
        g.release()
      end
    end

    if (payload.input_mask & (1 << BTN_X)) > 0 then
      -- Launch gravity, so eliminate existing gravs?
      -- Maybe need to work this out in level design first
      if count(gm.projectiles) > 0 then
        -- del(gm.projectiles, gm.projectiles[1])
        return
      end

      local pos_x = payload.pos_x
      local pos_y = payload.pos_y
      if payload.direction == 0 then
        pos_x = payload.pos_x
        pos_y = payload.pos_y - 10
      elseif payload.direction == 2 then
        pos_x = payload.pos_x
        pos_y = payload.pos_y + 10
      elseif payload.direction == 1 then
        pos_x = payload.pos_x + 10
        pos_y = payload.pos_y
      else
        pos_x = payload.pos_x - 10
        pos_y = payload.pos_y
      end
      local tmp = new_projectile({pos_x=pos_x, pos_y=pos_y}, payload.direction)
      add(gm.projectiles, tmp)
    end
  end

  gm.update = function()
    for k, g in pairs(gm.gravities) do
      g.update()
      if g.state == "DEAD" then
        del(gm.gravities, g)
      end
    end

    for k, p in pairs(gm.projectiles) do
      p.update()

      if p.ttl < 0 then
        del(gm.projectiles, p)
        qm.ae("PROJ_EXPIRATION", {})
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
  tmp.frame_index = 1

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

    tmp.frame_index += 1
    if tmp.frame_index > 22 then
      tmp.frame_index = 1
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
    -- spr(tmp.frames[tmp.frame_index], tmp.pos_x, tmp.pos_y, 1.0, 1.0, tmp.flip_x, tmp.flip_y)
    circ(tmp.pos_x+4, tmp.pos_y+4, 22 - tmp.frame_index, CLR_PRP)
  end

  return tmp

end

function new_projectile(coords, direction)
  local tmp = new_sprite(48, coords.pos_x, coords.pos_y, 2, 2, false, false)
  tmp.mass = 1
  -- tmp.state = "HELD"
  -- tmp.frame_base = 48
  tmp.frames = {37, 38, 39, 40, 41, 42, 39, 40}
  tmp.frame_index = 1
  tmp.frame_half_step = 1
  tmp.frame_step = 4
  tmp.can_travel = (1 << FLAG_FLOOR) | (1 << FLAG_GAP)
  tmp.ttl = 180
  local launch_velocity = 1.2
  if direction == DIRECTION_UP then
    tmp.vel_x = 0
    tmp.vel_y = -launch_velocity
  elseif direction == DIRECTION_DOWN then
    tmp.vel_x = 0
    tmp.vel_y = launch_velocity
  elseif direction == DIRECTION_RIGHT then
    tmp.vel_x = launch_velocity
    tmp.vel_y = 0
  elseif direction == DIRECTION_LEFT then
    tmp.vel_x = -launch_velocity
    tmp.vel_y = 0
  end

  tmp.update = function()
    tmp.frame_half_step += 1
    if tmp.frame_half_step > tmp.frame_step then
      tmp.frame_half_step = 1
      tmp.frame_index += 1
      if tmp.frame_index > count(tmp.frames) then
        tmp.frame_index = 1
      end
    end

    tmp.ttl -= 1

    ent_update(tmp)()

  end

  tmp.draw = function()
    spr(tmp.frames[tmp.frame_index], tmp.pos_x, tmp.pos_y, 1.0, 1.0, tmp.flip_x, tmp.flip_y)
  end

  return tmp
end

function calc_grav(coords_p, coords_g, vel_p, mass_p, mass_g)
  local dist_x = coords_p.x - coords_g.x
  local dist_y = coords_p.y - coords_g.y
  local dist_x2 = dist_x * dist_x
  local dist_y2 = dist_y * dist_y
  local gdistance = sqrt(dist_x2 + dist_y2)
  local dist_x_component = -(dist_x / gdistance)
  local dist_y_component = -(dist_y / gdistance)
  local G = 3.0
  local new_vel_x = vel_p.x + dist_x_component * (G*mass_p*mass_g) / (gdistance * gdistance)
  if new_vel_x > MAX_VEL then new_vel_x = MAX_VEL end
  if new_vel_x < -MAX_VEL then new_vel_x = -MAX_VEL end
  local new_vel_y = vel_p.y + dist_y_component * (G*mass_p*mass_g) / (gdistance * gdistance)
  if new_vel_y > MAX_VEL then new_vel_y = MAX_VEL end
  if new_vel_y < -MAX_VEL then new_vel_y = -MAX_VEL end
  if gdistance < 0.5 then
    return { gdistance = 0, vel = { x = 0, y = 0 } }
  end
  return { gdistance = gdistance, vel = { x = new_vel_x, y = new_vel_y } }
end

function calc_cheat_grav(coords_p, coords_g, mass_p, mass_g)
  local dist_x = coords_p.x - coords_g.x
  local dist_y = coords_p.y - coords_g.y
  local dist_x2 = dist_x * dist_x
  local dist_y2 = dist_y * dist_y
  local gdistance = sqrt(dist_x2 + dist_y2)
  local dist_x_component = -(dist_x / gdistance)
  local dist_y_component = -(dist_y / gdistance)
  local new_vel_x = dist_x_component * 1.0
  local new_vel_y = dist_y_component * 1.0
  if gdistance < 0.5 then
    return { gdistance = 0, vel = { x = 0, y = 0 } }
  end
  return { gdistance = gdistance, vel = { x = new_vel_x, y = new_vel_y } }
end
