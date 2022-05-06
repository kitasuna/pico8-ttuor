function new_gravity_manager()
  local gm = {
    gravities = {},
    projectiles = {},
    gbeam = nil,
    state = "ENABLED",
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
    if gm.state == "DISABLED" and (payload.input_mask & (1 << BTN_O)) == 0 then
      gm.state = "ENABLED"
      return
    elseif gm.state == "DISABLED" then
      return
    end

    if (payload.input_mask & (1 << BTN_O)) > 0 and gm.gbeam == nil then
      local pos_x = payload.pos_x
      local pos_y = payload.pos_y
      if payload.direction == DIRECTION_UP then
        pos_y -= 6
      elseif payload.direction == DIRECTION_DOWN then
        pos_y += 6
      elseif payload.direction == DIRECTION_RIGHT then
        pos_x += 6
      elseif payload.direction == DIRECTION_LEFT then
        pos_x -= 6
      end
      local tmp = new_gbeam({pos= {x=pos_x, y=pos_y}, direction=payload.direction})

      gm.gbeam = tmp
    elseif (payload.input_mask & (1 << BTN_O)) == 0 and gm.gbeam != nil then
      -- Remove gbeam
      gm.gbeam = nil 
      -- Add event to stop affected items
      qm.ae("GBEAM_REMOVED", {})
    end
        
    if (payload.input_mask & (1 << BTN_X)) > 0 and count(gm.projectiles) == 0 then
      local pos_x = payload.pos_x
      local pos_y = payload.pos_y
      if payload.direction == 0 then
        pos_x = payload.pos_x - 3
        pos_y = payload.pos_y - 10
      elseif payload.direction == 2 then
        pos_x = payload.pos_x - 3
        pos_y = payload.pos_y + 10
      elseif payload.direction == 1 then
        pos_x = payload.pos_x + 10
        pos_y = payload.pos_y - 3
      else
        pos_x = payload.pos_x - 10
        pos_y = payload.pos_y - 3
      end
      local tmp = new_projectile({pos_x=pos_x, pos_y=pos_y}, payload.direction)
      add(gm.projectiles, tmp)
    end
  end

  gm.handle_entity_reaches_target = function(name, payload)
    -- ej add handling here...
    gm.state = "DISABLED"
    gm.gbeam = nil 
  end

  gm.update = function()
    for k, g in pairs(gm.gravities) do
      g.update()
      if g.state == "DEAD" then
        del(gm.gravities, g)
      end
    end

    if gm.gbeam != nil then
      gm.gbeam.update()
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

-- Int -> Coords -> Int -> Coords
function move_in_direction(direction, pos, vel)
  if direction == DIRECTION_UP then
    pos.y -= vel
  elseif direction == DIRECTION_DOWN then
    pos.y += vel
  elseif direction == DIRECTION_RIGHT then
    pos.x += vel
  elseif direction == DIRECTION_LEFT then
    pos.x -= vel
  end
  return pos
end

-- { pos :: Coords, direction :: Int }
function new_gbeam(payload)
  -- local tmp = new_sprite(48, coords.pos_x, coords.pos_y, 2, 2, false, false)
  local tmp = {}
  tmp.head = { pos = { x=payload.pos.x, y=payload.pos.y } }
  tmp.tail = { pos = { x=payload.pos.x, y=payload.pos.y } }
  tmp.direction = payload.direction
  -- Set to max extent, can always pull this in later
  tmp.tail = { pos = move_in_direction(payload.direction, payload.pos, 30) }
  tmp.state = "HELD"

  -- Move in direction until we hit:
  -- 1) a sprite
  -- 2) a bad tile
  -- 3) our max extent
  -- TODO: Add collision with map tiles
  local iter_pos = { x=flr(tmp.head.pos.x), y=flr(tmp.head.pos.y) }
  local collision_found = false
  while (iter_pos.x != flr(tmp.tail.pos.x) or iter_pos.y != flr(tmp.tail.pos.y)) and not collision_found do
    iter_pos = move_in_direction(payload.direction, iter_pos, 1)
    -- make sprite at this position
    local tmp_sprite = new_sprite(0, iter_pos.x, iter_pos.y, 4, 4)
    for k, ent in pairs(ent_man.ents) do
      if ent.type != ENT_BEAM then
        if collides(tmp_sprite, ent) then
          tmp.tail.pos.x = iter_pos.x
          tmp.tail.pos.y = iter_pos.y
          collision_found = true
          do_gravity(ent, tmp.head.pos.x, tmp.head.pos.y, payload.direction)
          break
        end
      end
    end
  end

  tmp.update = function()
  end

  tmp.draw = function()
    -- spr(tmp.frames[tmp.frame_index], tmp.pos_x, tmp.pos_y, 1.0, 1.0, tmp.flip_x, tmp.flip_y)
    if tmp.state == "HELD" then
      -- circ(tmp.pos_x+4, tmp.pos_y+4, 22 - tmp.frame_index, CLR_PRP)
      line(tmp.head.pos.x, tmp.head.pos.y, tmp.tail.pos.x, tmp.tail.pos.y, CLR_GRN)
    end
  end

  return tmp

end

function new_projectile(coords, direction)
  local tmp = new_sprite(48, coords.pos_x, coords.pos_y, 6, 6, false, false)
  tmp.mass = 1
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

function ldistance(x0, y0, x1, y1)
  local dist_x = x0 - x1
  local dist_y = y0 - y1
  local dist_x2 = dist_x * dist_x
  local dist_y2 = dist_y * dist_y
  local gdistance = sqrt(dist_x2 + dist_y2)
  local dist_x_component = -(dist_x / gdistance)
  local dist_y_component = -(dist_y / gdistance)
  return {d=gdistance, dxc=dist_x_component, dyc=dist_y_component}
end

function calc_cheat_grav(coords_p, coords_g, mass_p, mass_g)
  local ginfo = ldistance(coords_p.x, coords_p.y, coords_g.x, coords_g.y)
  local new_vel_x = ginfo.dxc * 1.0
  local new_vel_y = ginfo.dyc * 1.0
  if ginfo.d < 0.5 then
    return { gdistance = 0, vel = { x = 0, y = 0 } }
  end
  return { gdistance = ginfo.d, vel = { x = new_vel_x, y = new_vel_y } }
end

