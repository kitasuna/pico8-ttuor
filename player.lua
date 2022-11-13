player_frame_base = 1
player_frame_offset = 0
player_frame_step = 0
player_state = PLAYER_STATE_GROUNDED
player_facing = DIRECTION_DOWN
player_vel_x = 0
player_vel_y = 0
player_slide_vel_x = 0
player_slide_vel_y = 0
slide_counter = 0

function new_player(sprite_num, pos_x, pos_y)
  local player = new_sprite(
  sprite_num,
  pos_x,
  pos_y,
  6,
  6
  )

  local velocity_max = 0.8
  local walk_init_vel = 0.2
  local walk_step_up = 0.04

  stop_player(player) -- inits vel values anyway
  player.can_travel = (1 << FLAG_FLOOR) | (1 << FLAG_GAP)
  player.gbeam = new_gbeam()
  player.wormhole = nil
  player.inventory = {
    state = inv_state_normal,
    glove = 2,
    wormhole = 2,
    items = {0,0,0,0},
  }

  player.frames_walking = {
    {7, 8, 7, 9},
    {4, 5, 4, 6},
    {1, 2, 1, 3},
    {4, 5, 4, 6},
  }

  player.frames_zapped = { 16, 17, 18 }

  -- API, allows other entities to check on player
  player.is_dead = function()
    if player_state == PLAYER_STATE_DEAD_ZAPPED or
      player_state == PLAYER_STATE_DEAD_FALLING then
      return true
    end

    return false
  end

  player.reset = function(l)
    player_frame_base = 1
    player_frame_offset = 1
    player_facing = DIRECTION_DOWN
    player.can_travel = (1 << FLAG_FLOOR) | (1 << FLAG_GAP)
    player_state = PLAYER_STATE_GROUNDED
    stop_player(player)
    player.pos_x = l.player_pos_x * 8
    player.pos_y = l.player_pos_y * 8
    player.gbeam.disable()
  end

  player.remove_wormhole = function()
    if player_state == PLAYER_STATE_FLOATING then
      sc_sliding(player)
    end
    player.wormhole = nil
    xsfx_wormhole()
  end

  player.handle_proj_box_collision = function()
    if player.wormhole != nil then
      player.wormhole.vel_x = 0
      player.wormhole.vel_y = 0
    end
  end

  player.handle_player_item_collision = function(payload)
      -- set to "1" here (uncommitted)
      -- will be set to "2" (committed) at the end of the level
      player.inventory.items[payload.entity.item_index] = 1
      sfx_get_item()
  end

  player.handle_player_glove_collision = function(payload)
      player.inventory.glove = 1
      player.inventory.state = inv_state_glove
      add(timers, {60, function()
          player.inventory.state = inv_state_normal
        end
      })
      sfx_get_inventory()
  end

  player.handle_player_wh_collision = function(payload)
      player.inventory.wormhole = 1
      player.inventory.state = inv_state_wormhole
      add(timers, {60, function()
          player.inventory.state = inv_state_normal
        end
      })
      sfx_get_inventory()
  end

  player.handle_beam_player_collision = function()
      player.can_move_x = false
      player.can_move_y = false
      stop_player(player)
      player_state = PLAYER_STATE_DEAD_ZAPPED
      sfx_zapped()
      player_frame_step = 0
      player_frame_offset = 0
      add(timers, {60,function()
          unstage_inventory(player.inventory)
          qm.add_event("player_death", {level = level})
        end
      })
  end

  player.handle_entity_reaches_target = function(payload)
    if payload.ent.type == ENT_BOX then
      player_state = PLAYER_STATE_HOLDING
    elseif payload.ent.type == ENT_ITEM then
      qm.add_event("PLAYER_ITEM_COLLISION", { entity=payload.ent })
    end
    player.gbeam.disable()
    qm.add_event("gbeam_removed")
    xsfx_gbeam()
  end

  player.handle_level_init = function()
    stop_player(player)
    player.wormhole = nil
    player.gbeam.disable()
    player_facing = DIRECTION_DOWN
    xsfx_all()
    xsfx_slide() -- not sure why, but this is needed
  end

  player.handle_button = function(payload)
    local mask = payload.input_mask
    -- Change facing for certain states
    if player_state == PLAYER_STATE_SLIDING or
       player_state == PLAYER_STATE_HOLDING or
       player_state == PLAYER_STATE_GROUNDED then
       if is_pressed_u(mask) then
         player_facing = DIRECTION_UP
       elseif is_pressed_d(mask) then
         player_facing = DIRECTION_DOWN
       elseif is_pressed_l(mask) then
         player_facing = DIRECTION_LEFT
       elseif is_pressed_r(mask) then
         player_facing = DIRECTION_RIGHT
       end
     end

    -- If they're sliding, they can tweak the direction of the slide
    if player_state == PLAYER_STATE_SLIDING then
      if is_pressed_u(mask) and player_slide_vel_y > -0.5 then
        player_slide_vel_y -= 0.03
      elseif is_pressed_d(mask) and player_slide_vel_y < 0.5 then
        player_slide_vel_y += 0.03
      elseif is_pressed_l(mask) and player_slide_vel_x > -0.5 then
        player_slide_vel_x -= 0.03
      elseif is_pressed_r(mask) and player_slide_vel_x < 0.5 then
        player_slide_vel_x += 0.03
      end
      return
    end

    -- If they're dying, disable input
    if player.is_dead() then
      return
    end

    -- If they're floating and the press isn't a float toggle, return
    if player_state == PLAYER_STATE_FLOATING and not is_pressed_x(mask) then
      return
    elseif player_state == PLAYER_STATE_FLOATING then
      if player.wormhole != nil then
        player.remove_wormhole()
      end
      return
    end

    -- If they're holding, all they can do is change the facing or release holding
    if player_state == PLAYER_STATE_HOLDING then
      -- TODO do we need this?
      if not is_pressed_o(mask) then
        player_state = PLAYER_STATE_GROUNDED 
        return
      end

      local new_x = player.pos_x
      local new_y = player.pos_y

      if player_facing == DIRECTION_UP then
        new_y -= 8
      elseif player_facing == DIRECTION_DOWN then
        new_y +=8
      elseif player_facing == DIRECTION_LEFT then
        new_x -= 8
      elseif player_facing == DIRECTION_RIGHT then
        new_x += 8
      end
      qm.add_event("player_rotation", {pos_x=new_x, pos_y=new_y})
      -- end
      return
    end

    -- if they're holding the beam, change state
    if is_pressed_o(mask) and player.inventory.glove != 0 then
      player_state = PLAYER_STATE_FIRING
      player_vel_x = 0
      player_vel_y = 0
      if player.gbeam.state == "DISABLED" then
        local gbeam_pos_x = player.pos_x
        local gbeam_pos_y = player.pos_y
        if player_facing == DIRECTION_UP then
          gbeam_pos_y -= 2
          gbeam_pos_x += 1
        elseif player_facing == DIRECTION_DOWN then
          gbeam_pos_y += 8
          gbeam_pos_x += 6
        elseif player_facing == DIRECTION_RIGHT then
          gbeam_pos_x += 7
          gbeam_pos_y += 4
        elseif player_facing == DIRECTION_LEFT then
          gbeam_pos_x -= 3
          gbeam_pos_y += 4
        end
        player.gbeam.enable(gbeam_pos_x, gbeam_pos_y, player_facing)
        sfx_gbeam()
      end
      return
    elseif not is_pressed_o(mask) and player.gbeam != nil then
      -- Remove gbeam
      player.gbeam.disable()
      -- Add event to stop affected items
      qm.add_event("gbeam_removed")
      xsfx_gbeam()
      player_state = PLAYER_STATE_GROUNDED
    end

    if is_pressed_x(mask) and player.wormhole == nil and player.inventory.wormhole != 0 then
      local wh_pos_x, wh_pos_y = player.pos_x, player.pos_y
      if player_facing == DIRECTION_UP then
        wh_pos_y -= 8
      elseif player_facing == DIRECTION_DOWN then
        wh_pos_y += 8
      elseif player_facing == DIRECTION_RIGHT then
        wh_pos_x += 8
      else -- DIRECTION_LEFT
        wh_pos_x -= 8
      end

      player.wormhole = new_wormhole(wh_pos_x, wh_pos_y, player_facing)
    -- If they're grounded, there's a projectile, and the press is a float toggle, make them float!
    elseif is_pressed_x(mask) and player.wormhole != nil and player_state == PLAYER_STATE_GROUNDED then
        player_state = PLAYER_STATE_FLOATING
        player.can_travel = (1 << FLAG_FLOOR) | (1 << FLAG_GAP)
        local grav_result = calc_cheat_grav(
        player.pos_x,
        player.pos_y,
        player.wormhole.pos_x,
        player.wormhole.pos_y
        )

        player_vel_x = grav_result.vel_x
        player_vel_y = grav_result.vel_y
        sfx_floating()

        return
    end

    -- Up
    if is_pressed_u(mask) then
      if player_vel_y >= 0 then
        player_vel_y = -walk_init_vel
      elseif player_vel_y > -velocity_max then
        player_vel_y -= walk_step_up
      end
    -- Down
    elseif is_pressed_d(mask) then
      if player_vel_y <= 0 then
        player_vel_y = walk_init_vel
      elseif player_vel_y < velocity_max then
        player_vel_y += walk_step_up
      end
    else
      player_vel_y = 0
    end

    if is_pressed_l(mask) then
      if player_vel_x >= 0 then
        player_vel_x = -walk_init_vel
      elseif player_vel_x > -velocity_max then
        player_vel_x -= walk_step_up
      end
    elseif is_pressed_r(mask) then
      if player_vel_x <= 0 then
        player_vel_x = walk_init_vel
      elseif player_vel_x < velocity_max then
        player_vel_x += walk_step_up
      end
    else
      player_vel_x = 0
    end

    if player_facing == DIRECTION_DOWN then
      player_frame_base = 1
    elseif player_facing == DIRECTION_UP then
      player_frame_base = 9
    elseif player_facing == DIRECTION_RIGHT then
      player_frame_base = 5
    elseif player_facing == DIRECTION_LEFT then
      player_frame_base = 5
    end

    -- if pressing any direction
    if mask & 15 > 0 then
      player_frame_step = (player_frame_step + 1) % 7
      if player_frame_step == 0 then
        player_frame_offset = (player_frame_offset + 1) % 4
      end
    end
  end

  player.draw = function()
    local flip = false
    if player_facing == DIRECTION_LEFT then
      -- Only used for some states
      flip = true
    end
    if player_state == PLAYER_STATE_GROUNDED then
      -- spr(player_frame_base + player_frame_offset, player.pos_x, player.pos_y, 1.0, 1.0, player.flip_x, player.flip_y)
      local frames = player.frames_walking[player_facing + 1]
      spr(frames[player_frame_offset + 1],player.pos_x, player.pos_y, 1.0, 1.0, flip)
    elseif player_state == PLAYER_STATE_FIRING then
      spr(23 + player_facing, player.pos_x, player.pos_y)
    elseif player_state == PLAYER_STATE_FLOATING then
      spr(10, player.pos_x, player.pos_y)
    elseif player_state == PLAYER_STATE_SLIDING then
      spr(12 + player_facing, player.pos_x, player.pos_y)
    elseif player_state == PLAYER_STATE_DEAD_FALLING then
      local offset = player_frame_offset + 1
      sspr(88, 0, 8, 8, player.pos_x + offset, player.pos_y + offset, 8 \ offset, 8 \ offset)
    elseif player_state == PLAYER_STATE_DEAD_ZAPPED then
      spr(player.frames_zapped[player_frame_offset + 1],player.pos_x, player.pos_y)
    elseif player_state == PLAYER_STATE_HOLDING then
      spr(19+player_facing,player.pos_x, player.pos_y, 1.0, 1.0, flip, false)
    end
  end

  player.update = function(ent_man, level)
    if player.wormhole != nil then
      player.wormhole.update(level)

      if collides(player.wormhole, player) then
        if player_state == PLAYER_STATE_FLOATING then
          sc_sliding(player)
        end
        player.remove_wormhole()
      elseif player.wormhole.ttl < 0 then
        player.remove_wormhole()
      end

    end

    player.gbeam.update()

    local approx_vel_x = player_vel_x + player_slide_vel_x
    if approx_vel_x < 0 then
      approx_vel_x = flr(approx_vel_x)
    elseif approx_vel_x > 0 then
      approx_vel_x = ceil(approx_vel_x)
    end
    local approx_vel_y = player_vel_y + player_slide_vel_y
    if approx_vel_y < 0 then
      approx_vel_y = flr(approx_vel_y)
    elseif approx_vel_y > 0 then
      approx_vel_y = ceil(approx_vel_y)
    end

    local center_x, center_y = get_center(player)
    local player_next_x = center_x + approx_vel_x -- + (player_facing != 3 and 5 or 1)
    local player_next_y = center_y + approx_vel_y -- + (player_facing == 2 and 7 or 0)
    local curr_map_x, curr_map_y = get_tile_from_pos(center_x, center_y, level)
    local next_map_x, next_map_y = get_tile_from_pos(player_next_x, player_next_y, level)
    local can_move_x, can_move_y = true,true


    if player_state == PLAYER_STATE_DEAD_FALLING then
      if player_frame_offset < 3 then
        player_frame_step += 1
        if player_frame_step > 20 then
          player_frame_offset += 1
          player_frame_step = 0
        end
      else
        qm.add_event("player_death", {level = level})
        unstage_inventory(player.inventory)
      end
      return
    end

    if player_state == PLAYER_STATE_DEAD_ZAPPED then
      player_frame_step = (player_frame_step + 1) % 6
      if player_frame_step == 0 then
        player_frame_offset = (player_frame_offset + 1) % #player.frames_zapped
      end
    end

    -- check for gaps
    local over_gaps=0
    if player_state != PLAYER_STATE_FLOATING then
      for i=player.pos_x+1,player.pos_x+6 do
        if fget(mget(get_tile_from_pos(i, player.pos_y+3, level)), FLAG_GAP) then
          over_gaps+=1
        end
        if fget(mget(get_tile_from_pos(i, player.pos_y+4, level)), FLAG_GAP) then
          over_gaps+=1
        end
      end
      for i=player.pos_y+1,player.pos_y+6 do
        if fget(mget(get_tile_from_pos(player.pos_x+3, i, level)), FLAG_GAP) then
          over_gaps+=1
        end
        if fget(mget(get_tile_from_pos(player.pos_x+4, i, level)), FLAG_GAP) then
          over_gaps+=1
        end
      end
      if over_gaps >= 24 then
        player.pos_x = (curr_map_x - level.start_tile_x) * 8
        player.pos_y = (curr_map_y - level.start_tile_y) * 8
        player_state = PLAYER_STATE_DEAD_FALLING
        player_frame_step = 0
        player_frame_offset = 0
        xsfx_slide()
        sfx_falling()
      end
    end


    if fmget(next_map_x, curr_map_y) & player.can_travel == 0 then
      can_move_x = false
    end

    if fmget(curr_map_x, next_map_y) & player.can_travel == 0 then
      can_move_y = false
    end

    if fmget(next_map_x, next_map_y) & player.can_travel == 0 then
      can_move_x = false
      can_move_y = false
    end

    if fget(mget(curr_map_x, curr_map_y), FLAG_STAIRS) then
      commit_inventory(player.inventory)
      xsfx_all()
      qm.add_event("player_goal")
    end

    -- Make a hypothetical player sprite at the next location after update and check for collision
    local player_at_next = new_sprite(
      0, -- sprite num, doesn't matter
      player.pos_x + player_vel_x + player_slide_vel_x,
      player.pos_y + player_vel_y + player_slide_vel_y,
      player.size_x - 1, -- cheat with smaller player size for ents
      player.size_y - 1
    )
    for k, ent in pairs(ent_man.ents) do
      if fget(ent.num, FLAG_COLLIDES_PLAYER) == true then
        if collides(player_at_next, ent) then 
          can_move_x = false
          can_move_y = false
        end
      end
    end

    -- the slide, deceleration and stopping
    if player_state == PLAYER_STATE_SLIDING then
      global_slide_counter += 1
      if global_slide_counter == 20 then
        player_vel_x *= 0.5
        player_vel_y *= 0.5
      end

      if can_move_x == false then
        player_vel_x = 0
      end
      if can_move_y == false then
        player_vel_y = 0
      end

      if global_slide_counter > 30 or (player_vel_x == 0 and player_vel_y == 0 and player_state == PLAYER_STATE_SLIDING) then
        player_state = PLAYER_STATE_GROUNDED
        player_slide_vel_x = 0
        player_slide_vel_y = 0
        xsfx_slide()
        printh("Slid for: "..global_slide_counter)
        global_slide_counter = 0
      end
    end

    if player_state == PLAYER_STATE_SLIDING then

      printh("dx: "..player_vel_x + player_slide_vel_x)
      printh("dy: "..player_vel_y + player_slide_vel_y)
    end
    if can_move_x == true then
      player.pos_x += player_vel_x + player_slide_vel_x
    end

    if can_move_y == true then
      player.pos_y += player_vel_y + player_slide_vel_y
    end

  end

  return player
end

-- { pos :: Coords, direction :: Int }
function new_gbeam()
  local tmp = {
    size_x = 4,
    size_y = 4,
    blocked_by = nil,
    state = "DISABLED",
    can_travel = (1 << FLAG_FLOOR) | (1 << FLAG_GAP),
  }

  tmp.update = function()
    if tmp.particles != nil then
      tmp.particles.update()
    end

    if tmp.state == "DISABLED" then
      return
    end

    if tmp.blocked_by != nil then
      if tmp.blocked_by.num != 99 then
        local junk = nil
        if tmp.direction == DIRECTION_UP or tmp.direction == DIRECTION_DOWN then
          junk, tmp.tail_pos_y = get_center(tmp.blocked_by)
        else
          tmp.tail_pos_x, junk = get_center(tmp.blocked_by)
        end
      end
      tmp.particles.pos_x = tmp.tail_pos_x
      tmp.particles.pos_y = tmp.tail_pos_y
      tmp.particles.addDir(0.8, 0.8, 15)
    end
  end

  tmp.draw = function()
    if tmp.state == "ENABLED" then
      local colors = sort_from({ CLR_PNK, CLR_BLK, CLR_PRP }, (frame_counter % 3) + 1)
      if tmp.direction == DIRECTION_UP or tmp.direction == DIRECTION_DOWN then
        for i=-1,1 do
          line(tmp.head_pos_x - i, tmp.head_pos_y, tmp.tail_pos_x - i, tmp.tail_pos_y, colors[i+2])
        end
        circfill(tmp.head_pos_x, tmp.head_pos_y, 2, colors[1])
        circfill(tmp.head_pos_x, tmp.head_pos_y, frame_counter % 2, colors[2])
      else
        for i=-1,1 do
          line(tmp.head_pos_x, tmp.head_pos_y - i, tmp.tail_pos_x, tmp.tail_pos_y - i, colors[i+2])
        end
        circfill(tmp.head_pos_x + 2, tmp.head_pos_y, 2, colors[1])
        circfill(tmp.head_pos_x + 2, tmp.head_pos_y, frame_counter % 2, colors[2])
      end
    end

    if tmp.particles != nil then
      tmp.particles.draw()
    end
  end

  tmp.enable = function(pos_x, pos_y, direction)
    tmp.state = "ENABLED"
    tmp.head_pos_x = flr(pos_x)
    tmp.head_pos_y = flr(pos_y)
    tmp.pos_x = pos_x
    tmp.pos_y = pos_y
    tmp.direction = direction
    -- Set to max extent, can always pull this in later
    tmp.tail_pos_x, tmp.tail_pos_y = move_in_direction(direction, pos_x, pos_y, 30)

    -- Move in direction until we hit:
    -- 1) a sprite
    -- 2) a bad tile
    -- 3) our max extent
    -- TODO: Add collision with map tiles
    local iter_pos_x = tmp.head_pos_x
    local iter_pos_y = tmp.head_pos_y
    local collision_found = false
    while abs(iter_pos_x - tmp.head_pos_x) < 30 and abs(iter_pos_y - tmp.head_pos_y) < 30 and not collision_found do
      iter_pos_x, iter_pos_y = move_in_direction(direction, iter_pos_x, iter_pos_y, 1)
      local next_map_x, next_map_y = get_tile_from_pos(iter_pos_x, iter_pos_y, level)

      -- check for map collisions
      if fmget(next_map_x, next_map_y) & tmp.can_travel == 0 then
        tmp.tail_pos_x = iter_pos_x
        tmp.tail_pos_y = iter_pos_y
        tmp.particles = flsrc(tmp.tail_pos_x, tmp.tail_pos_y, 0, {2, 13, 14})
        tmp.particles.direction = direction
        -- TODO: total hack, need to treat maps and sprites differently
        tmp.blocked_by = new_sprite(99, tmp.tail_pos_x, tmp.tail_pos_y, 8, 8)
        break
      end

      -- check for sprite collisions
      local tmp_sprite = {}
      if direction == DIRECTION_UP or direction == DIRECTION_DOWN then
        tmp_sprite = new_sprite(0, iter_pos_x - 3, iter_pos_y, 3, 3)
      else
        tmp_sprite = new_sprite(0, iter_pos_x, iter_pos_y - 2, 3, 3)
      end
      for k, ent in pairs(ent_man.ents) do
        if ent.type != ENT_BEAM and collides(tmp_sprite, ent) then
            tmp.tail_pos_x = iter_pos_x
            tmp.tail_pos_y = iter_pos_y
            collision_found = true
            local player_center_x, player_center_y = get_center(player)
            do_gravity(ent, player_center_x, player_center_y, direction)
            tmp.blocked_by = ent
            tmp.particles = flsrc(tmp.tail_pos_x, tmp.tail_pos_y, 0, {2, 13, 14})
            tmp.particles.direction = direction
            break
        end
      end
    end
  end

  tmp.disable = function()
    tmp.state = "DISABLED"
    tmp.blocked_by = nil
  end

  return tmp

end

function new_wormhole(pos_x, pos_y, direction)
  local tmp = new_sprite(48, pos_x, pos_y, 6, 6, false, false)
  tmp.bgcoloridx = 1
  tmp.incoloridx = 2
  tmp.colors = { CLR_PNK, CLR_BLK, CLR_PRP }
  tmp.frame_index = 1
  tmp.frame_half_step = 1
  tmp.can_travel = (1 << FLAG_FLOOR) | (1 << FLAG_GAP)
  tmp.ttl = 180
  local launch_velocity = 2
  local max_velocity = 4
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
    tmp.frame_half_step = (tmp.frame_half_step + 1) % 3
    if tmp.frame_half_step == 0 then
      tmp.bgcoloridx = (tmp.bgcoloridx + 1) % #tmp.colors
      tmp.incoloridx = (tmp.incoloridx + 1) % #tmp.colors
    end

    if tmp.vel_x < max_velocity then
      tmp.vel_x *= 1.1
    end
    if tmp.vel_y < max_velocity then
      tmp.vel_y *= 1.1
    end

    tmp.ttl -= 1

    ent_update(tmp)(level)

  end

  tmp.draw = function()
    circfill(tmp.pos_x+4, tmp.pos_y+4, 3, tmp.colors[tmp.bgcoloridx])
    circfill(tmp.pos_x+4, tmp.pos_y+4, tmp.frame_half_step, tmp.colors[tmp.incoloridx])
  end

  sfx_wormhole()
  return tmp
end

function sc_sliding(player)
    player_state = PLAYER_STATE_SLIDING
    player.can_travel = (1 << FLAG_FLOOR) | (1 << FLAG_GAP)
    sfx_slide()
    global_slide_counter = 0
    player_vel_x *= 0.7
    player_vel_y *= 0.7
    printh("dxdy: "..player_vel_x..","..player_vel_y)
end

function get_center(sprite)
  return _get_center(sprite.pos_x, sprite.size_x), _get_center(sprite.pos_y, sprite.size_y)
end

function _get_center(pos, size)
    return flr(pos + (size \ 2) + ((8 - size) \ 2))
end

function is_pressed(btn)
  return function(mask)
    return (mask & (1 << btn)) > 0
  end
end

is_pressed_l = is_pressed(BTN_L)
is_pressed_r = is_pressed(BTN_R)
is_pressed_u = is_pressed(BTN_U)
is_pressed_d = is_pressed(BTN_D)
is_pressed_x = is_pressed(BTN_X)
is_pressed_o = is_pressed(BTN_O)

function commit_inventory(inventory)
  modify_inventory(inventory, 2)
end

function modify_inventory(inventory, tgt)
  if inventory.glove == 1 then
    inventory.glove = tgt
  end

  if inventory.wormhole == 1 then
    inventory.wormhole = tgt
  end

  for i=1,#inventory.items do
    if inventory.items[i] == 1 then
      inventory.items[i] = tgt
    end
  end
end

function unstage_inventory(inventory)
  modify_inventory(inventory, 0)
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

function calc_cheat_grav(px, py, gx, gy)

  local mass_p, mass_g = 1.0, 128
  local float_velocity = 1.5
  local ginfo = ldistance(px, py, gx, gy)
  local new_vel_x = ginfo.dxc * float_velocity
  local new_vel_y = ginfo.dyc * float_velocity
  if (new_vel_x > 0 and new_vel_x < 0.1) or (new_vel_x < 0 and new_vel_x > -0.1) then
    new_vel_x = 0
  end
  if (new_vel_y > 0 and new_vel_y < 0.1) or (new_vel_y < 0 and new_vel_y > -0.1) then
    new_vel_y = 0
  end
  if ginfo.d < 0.5 then
    return { vel_x = 0, vel_y = 0 }
  end
  return { vel_x = new_vel_x, vel_y = new_vel_y }
end

function stop_player(player)
  player_vel_x, player_vel_y = 0,0 
  player_slide_vel_x, player_slide_vel_y = 0,0 
end
