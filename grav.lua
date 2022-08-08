function new_gravity_manager()
  local gm = {
    wormhole = nil,
    gbeam = nil,
    state = "ENABLED",
  }

  gm.reset = function()
    gm.wormhole = nil
    gm.gbeam = nil
  end

  -- String -> { projectile: Projectile }
  gm.handle_proj_player_collision = function(payload)
    gm.wormhole = nil
  end

  gm.handle_proj_box_collision = function(payload)
    gm.wormhole.vel_x = 0
    gm.wormhole.vel_y = 0
  end

  gm.handle_player_death = function(payload)
    gm.wormhole = nil
    gm.gbeam = nil
  end

  -- String -> { pos_x: Int, pos_y: Int, direction: Int, input_mask: Int }
  gm.handle_button = function(payload)
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
        pos_x -= 1
      elseif payload.direction == DIRECTION_DOWN then
        pos_y += 6
        pos_x += 2
      elseif payload.direction == DIRECTION_RIGHT then
        pos_x += 6
        pos_y += 1
      elseif payload.direction == DIRECTION_LEFT then
        pos_x -= 6
        pos_y += 1
      end
      local tmp = new_gbeam({pos= {x=pos_x, y=pos_y}, direction=payload.direction})

      gm.gbeam = tmp
    elseif (payload.input_mask & (1 << BTN_O)) == 0 and gm.gbeam != nil then
      -- Remove gbeam
      gm.gbeam = nil 
      -- Add event to stop affected items
      qm.ae("GBEAM_REMOVED", {})
    end
        
    if (payload.input_mask & (1 << BTN_X)) > 0 and gm.wormhole == nil then
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
      gm.wormhole = new_projectile({pos_x=pos_x, pos_y=pos_y}, payload.direction)
    end
  end

  gm.handle_entity_reaches_target = function(payload)
    gm.state = "DISABLED"
    gm.gbeam = nil 
  end

  gm.handle_player_cancel_float = function(payload)
    if gm.wormhole != nil then
      gm.wormhole = nil
    end
  end

  gm.update = function(level)
    if gm.gbeam != nil then
      gm.gbeam.update()
    end

    if gm.wormhole != nil then
      gm.wormhole.update(level)
      if gm.wormhole.ttl < 0 then
        gm.wormhole = nil
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
  tmp.head_pos_x = payload.pos.x
  tmp.head_pos_y = payload.pos.y
  tmp.tail_pos_x = payload.pos.y
  tmp.tail_pos_y = payload.pos.y
  tmp.direction = payload.direction
  -- Set to max extent, can always pull this in later
  local new_tail = move_in_direction(payload.direction, payload.pos, 30)
  -- tmp.tail = { pos = move_in_direction(payload.direction, payload.pos, 30) }
  tmp.tail_pos_x = new_tail.x
  tmp.tail_pos_y = new_tail.y
  tmp.state = "HELD"

  -- Move in direction until we hit:
  -- 1) a sprite
  -- 2) a bad tile
  -- 3) our max extent
  -- TODO: Add collision with map tiles
  local iter_pos = { x=flr(tmp.head_pos_x), y=flr(tmp.head_pos_y) }
  local collision_found = false
  while (iter_pos.x != flr(tmp.tail_pos_x) or iter_pos.y != flr(tmp.tail_pos_y)) and not collision_found do
    iter_pos = move_in_direction(payload.direction, iter_pos, 1)
    -- make sprite at this position
    local tmp_sprite = new_sprite(0, iter_pos.x, iter_pos.y, 4, 4)
    for k, ent in pairs(ent_man.ents) do
      if ent.type != ENT_BEAM then
        if collides(tmp_sprite, ent) then
          tmp.tail_pos_x = iter_pos.x
          tmp.tail_pos_y = iter_pos.y
          collision_found = true
          do_gravity(ent, tmp.head_pos_x, tmp.head_pos_y, payload.direction)
          break
        end
      end
    end
  end

  tmp.update = function()
  end

  tmp.draw = function()
    if tmp.state == "HELD" then
      local colors = sort_from({ CLR_PNK, CLR_WHT, CLR_PRP }, (frame_counter % 3) + 1)
      if tmp.direction == DIRECTION_UP or tmp.direction == DIRECTION_DOWN then
        line(tmp.head_pos_x - 1, tmp.head_pos_y, tmp.tail_pos_x - 1, tmp.tail_pos_y, colors[1])
        line(tmp.head_pos_x, tmp.head_pos_y, tmp.tail_pos_x, tmp.tail_pos_y, colors[2])
        line(tmp.head_pos_x + 1, tmp.head_pos_y, tmp.tail_pos_x + 1, tmp.tail_pos_y, colors[3])
        circfill(tmp.head_pos_x, tmp.head_pos_y, 3, colors[1])
        circfill(tmp.head_pos_x, tmp.head_pos_y, frame_counter % 3, colors[2])
      else
        line(tmp.head_pos_x, tmp.head_pos_y - 1, tmp.tail_pos_x, tmp.tail_pos_y - 1, colors[1])
        line(tmp.head_pos_x, tmp.head_pos_y, tmp.tail_pos_x, tmp.tail_pos_y, colors[2])
        line(tmp.head_pos_x, tmp.head_pos_y + 1 , tmp.tail_pos_x, tmp.tail_pos_y + 1, colors[3])
        circfill(tmp.head_pos_x + 2, tmp.head_pos_y, 3, colors[1])
        circfill(tmp.head_pos_x + 2, tmp.head_pos_y, frame_counter % 3, colors[2])
      end
    end
  end

  return tmp

end

function sort_from(arr, start_idx)
  local new_arr = {}
  local new_idx = 1
  local curr_idx = start_idx
  while count(new_arr) < count(arr) do
    new_arr[new_idx] = arr[curr_idx]
    new_idx += 1
    curr_idx += 1
    if curr_idx > count(arr) then
      curr_idx = 1
    end
  end
  return new_arr
end
function new_projectile(coords, direction)
  local tmp = new_sprite(48, coords.pos_x, coords.pos_y, 6, 6, false, false)
  tmp.bgcoloridx = 1
  tmp.incoloridx = 2
  tmp.colors = { CLR_PNK, CLR_WHT, CLR_PRP }
  tmp.frame_index = 1
  tmp.frame_half_step = 1
  tmp.frame_step = 3
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

  tmp.update = function(level)
    tmp.frame_half_step += 1
    if tmp.frame_half_step > tmp.frame_step then
      tmp.frame_half_step = 1
      tmp.bgcoloridx += 1
      tmp.incoloridx += 1
      if tmp.bgcoloridx > count(tmp.colors) then
        tmp.bgcoloridx = 1
      end
      if tmp.incoloridx > count(tmp.colors) then
        tmp.incoloridx = 1
      end
    end

    tmp.ttl -= 1

    ent_update(tmp)(level)

  end

  tmp.draw = function()
    circfill(tmp.pos_x+4, tmp.pos_y+4, 3, tmp.colors[tmp.bgcoloridx])
    circfill(tmp.pos_x+4, tmp.pos_y+4, tmp.frame_half_step, tmp.colors[tmp.incoloridx])
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
  local new_vel_x = ginfo.dxc * 1.3
  local new_vel_y = ginfo.dyc * 1.3
  if (new_vel_x > 0 and new_vel_x < 0.1) or (new_vel_x < 0 and new_vel_x > -0.1) then
    new_vel_x = 0
  end
  if (new_vel_y > 0 and new_vel_y < 0.1) or (new_vel_y < 0 and new_vel_y > -0.1) then
    new_vel_y = 0
  end
  if ginfo.d < 0.5 then
    return { gdistance = 0, vel = { x = 0, y = 0 } }
  end
  return { gdistance = ginfo.d, vel = { x = new_vel_x, y = new_vel_y } }
end

