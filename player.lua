function new_player(sprite_num, pos_x, pos_y)
  local player = new_sprite(
  sprite_num,
  pos_x,
  pos_y,
  6,
  6
  )

  local velocity_max = 1.0
  local slide_step_down = 0.05

  player.state = PLAYER_STATE_GROUNDED
  player.deaths = 0
  player.score = 0
  player.vel_x = 0
  player.vel_y = 0
  player.invincible = false
  player.frame_base = 1
  player.frame_offset = 0
  player.frame_step = 0
  player.facing = DIRECTION_DOWN
  player.can_travel = (1 << FLAG_FLOOR)

  player.frames_walking = {
    { anim={7, 8, 7, 9}, flip=false },
    { anim={4, 5, 4, 6}, flip=false },
    { anim={1, 2, 1, 3}, flip=false },
    { anim={4, 5, 4, 6}, flip=true }
  }

  player.frames_zapped = { 16, 17, 18, 16, 17, 18, 16, 17, 18 }

  -- API, allows other entities to check on player
  player.is_dead = function()
    if player.state == PLAYER_STATE_DEAD_ZAPPED or
      player.state == PLAYER_STATE_DEAD_FALLING then
      return true
    end

    return false
  end

  player.reset = function(l)
    player.frame_base = 1
    player.frame_offset = 1
    player.facing = DIRECTION_DOWN
    player.can_travel = (1 << FLAG_FLOOR)
    player.state = PLAYER_STATE_GROUNDED
    player.vel_x = 0
    player.vel_y = 0
    player.pos_x = l.player_pos_x
    player.pos_y = l.player_pos_y
  end

  player.handle_proj_player_collision = function(payload)
    if player.state == PLAYER_STATE_FLOATING then
      sc_sliding(player)
    end
  end

  player.handle_player_item_collision = function(payload)
      player.score += 1
  end

  player.handle_beam_player_collision = function(payload)
      player.deaths += 1
      player.can_move_x = false
      player.can_move_y = false
      player.vel_x = 0
      player.vel_y = 0
      player.state = PLAYER_STATE_DEAD_ZAPPED
      player.frame_step = 0
      player.frame_offset = 0
  end

  player.handle_proj_expiration = function(payload)
    if player.state == PLAYER_STATE_FLOATING then
      sc_sliding(player) 
    end
  end

  player.handle_entity_reaches_target = function(payload)
    player.state = PLAYER_STATE_HOLDING
  end

  player.handle_level_init = function(payload)
    -- TODO: We probably want more happening in here, like position etc
  end

  player.handle_button = function(payload)
    -- If they're sliding, they can't do much
    if player.state == PLAYER_STATE_SLIDING then
      return
    end

    -- If they're dying, disable input
    if player.state == PLAYER_STATE_DEAD_FALLING or player.state == PLAYER_STATE_DEAD_ZAPPED then
      return
    end

    -- If they're floating and the press isn't a float toggle, return
    if player.state == PLAYER_STATE_FLOATING and (payload.input_mask & (1 << BTN_X) == 0) then
      return
    end

    -- If they're floating and the press IS a float toggle, ground them and return
    -- also fire off a sliding event here
    if player.state == PLAYER_STATE_FLOATING and (payload.input_mask & (1 << BTN_X) > 0) then
        qm.ae("PLAYER_CANCEL_FLOAT", {})
        sc_sliding(player)
        return
    end

    -- If they're holding, all they can do is change the facing or release holding
    if player.state == PLAYER_STATE_HOLDING then
      if payload.input_mask & (1 << BTN_O) == 0 then
        player.state = PLAYER_STATE_GROUNDED 
        return
      end

      if payload.input_mask & (1 << BTN_U) > 0 then
        player.facing = DIRECTION_UP
      end

      if payload.input_mask & (1 << BTN_D) > 0 then
        player.facing = DIRECTION_DOWN
      end

      if payload.input_mask & (1 << BTN_L) > 0 then
        player.facing = DIRECTION_LEFT
      end

      if payload.input_mask & (1 << BTN_R) > 0 then
        player.facing = DIRECTION_RIGHT
      end

      local new_x = player.pos_x
      local new_y = player.pos_y
      if player.facing == DIRECTION_UP then
        new_y -= 8
      elseif player.facing == DIRECTION_DOWN then
        new_y +=8
      elseif player.facing == DIRECTION_LEFT then
        new_x -= 8
      elseif player.facing == DIRECTION_RIGHT then
        new_x += 8
      end
      qm.ae("PLAYER_ROTATION", {pos_x=new_x, pos_y=new_y})
      -- end
      return
    end

    -- If they're grounded, there's a projectile, and the press is a float toggle, make them float!
    if (payload.input_mask & (1 << BTN_X) > 0) and (payload.projectile != nil) and (player.state == PLAYER_STATE_GROUNDED) then
        player.state = PLAYER_STATE_FLOATING
        player.can_travel = (1 << FLAG_FLOOR) | (1 << FLAG_GAP)
        local grav_result = calc_cheat_grav(
        {x=player.pos_x, y=player.pos_y},
        {x=payload.projectile.pos_x, y=payload.projectile.pos_y},
        1.0,
        128.0
        )

        player.vel_x = grav_result.vel.x
        player.vel_y = grav_result.vel.y

        return
    end

    -- Try returning if grav button is being held down
    if payload.input_mask & (1 << BTN_O) > 0 then
      player.vel_x = 0
      player.vel_y = 0
      return
    end


    -- Up
    if payload.input_mask & (1 << BTN_U) > 0 then
      player.facing = DIRECTION_UP
      player.vel_y = -velocity_max
    -- Down
    elseif payload.input_mask & (1 << BTN_D) > 0 then
      player.facing = DIRECTION_DOWN
      player.vel_y = velocity_max
    end

    if payload.input_mask & (1 << BTN_U) == 0 and
      payload.input_mask & (1 << BTN_D) == 0 then
      player.vel_y = 0
    end

    if payload.input_mask & (1 << BTN_L) > 0 then
      player.facing = DIRECTION_LEFT
      player.vel_x = -velocity_max
    elseif payload.input_mask & (1 << BTN_R) > 0 then
      player.facing = DIRECTION_RIGHT
      player.vel_x = velocity_max
    end

    if payload.input_mask & (1 << BTN_L) == 0 and
      payload.input_mask & (1 << BTN_R) == 0 then
      player.vel_x = 0
    end

    if player.facing == DIRECTION_DOWN then
      player.frame_base = 1
    elseif player.facing == DIRECTION_UP then
      player.frame_base = 9
    elseif player.facing == DIRECTION_RIGHT then
      player.frame_base = 5
    elseif player.facing == DIRECTION_LEFT then
      player.frame_base = 5
    end

    if payload.input_mask > 0 then
      player.frame_step += 1
      if player.frame_step > 6 then
        player.frame_offset += 1
        player.frame_step = 0
        if player.frame_offset > 3 then
          player.frame_offset = 0
        end
      end
    end
  end

  player.draw = function()
    if player.state == PLAYER_STATE_GROUNDED or player.state == PLAYER_STATE_HOLDING then
      -- spr(player.frame_base + player.frame_offset, player.pos_x, player.pos_y, 1.0, 1.0, player.flip_x, player.flip_y)
      local frames = player.frames_walking[player.facing + 1]
      spr(frames.anim[player.frame_offset + 1],player.pos_x, player.pos_y, 1.0, 1.0, frames.flip, false)
    elseif player.state == PLAYER_STATE_FLOATING then
      spr(10, player.pos_x, player.pos_y, 1.0, 1.0, false, false)
    elseif player.state == PLAYER_STATE_SLIDING then
      spr(12 + player.facing, player.pos_x, player.pos_y, 1.0, 1.0, false, false)
    elseif player.state == PLAYER_STATE_DEAD_FALLING then
      sspr(88, 0, 8, 8, get_center_x(player), get_center_y(player), 8 \ (player.frame_offset + 1), 8 \ (player.frame_offset + 1))
    elseif player.state == PLAYER_STATE_DEAD_ZAPPED then
      local frames = player.frames_zapped
      spr(frames[player.frame_offset + 1],player.pos_x, player.pos_y, 1.0, 1.0, false, false)
    end
  end

  player.update = function(ent_man, level)
    local center_x = get_center_x(player)
    local center_y = get_center_y(player)
    if player.state == PLAYER_STATE_HOLDING then
      qm.ae("PLAYER_HOLDS", {x=player.pos_x,y=player.pos_y})
      return
    end

    local approx_vel_x = player.vel_x
    if approx_vel_x < 0 then
      approx_vel_x = flr(approx_vel_x)
    elseif approx_vel_x > 0 then
      approx_vel_x = ceil(approx_vel_x)
    end
    local approx_vel_y = player.vel_y
    if approx_vel_y < 0 then
      approx_vel_y = flr(approx_vel_y)
    elseif approx_vel_y > 0 then
      approx_vel_y = ceil(approx_vel_y)
    end
    local player_next_x = center_x + approx_vel_x -- + (player.facing != 3 and 5 or 1)
    local player_next_y = center_y + approx_vel_y -- + (player.facing == 2 and 7 or 0)
    local curr_map_x = (center_x \ 8) + level.start_tile_x
    local next_map_x = (player_next_x \ 8) + level.start_tile_x
    local curr_map_y = (center_y \ 8) + level.start_tile_y
    local next_map_y = (player_next_y \ 8) + level.start_tile_y
    local can_move_x = true
    local can_move_y = true


    if player.state == PLAYER_STATE_DEAD_FALLING then
      if player.frame_offset < 3 then
        player.frame_step += 1
        if player.frame_step > 20 then
          player.frame_offset += 1
          player.frame_step = 0
        end
      else
        qm.ae("PLAYER_DEATH", {level = level})
      end
      return
    end

    if player.state == PLAYER_STATE_DEAD_ZAPPED then
      if player.frame_offset < 9 then
        player.frame_step += 1
        if player.frame_step > 5 then
          player.frame_offset += 1
          player.frame_step = 0
        end
      else
        qm.ae("PLAYER_DEATH", {level = level})
        return
      end
    end

    -- if centered over a gap, and not floating, increment deaths (and probably trigger some event?)
    if fget(mget(curr_map_x, curr_map_y), FLAG_GAP) and (player.state != PLAYER_STATE_FLOATING and player.state != PLAYER_STATE_DEAD_FALLING) then
      player.deaths += 1
      player.can_move_x = false
      player.can_move_y = false
      player.pos_x += player.vel_x
      player.pos_y += player.vel_y
      player.state = PLAYER_STATE_DEAD_FALLING
      player.frame_step = 0
      player.frame_offset = 0
      return
    end

    if fget(mget(next_map_x, curr_map_y)) & player.can_travel == 0 then
      can_move_x = false
    end

    if fget(mget(curr_map_x, next_map_y)) & player.can_travel == 0 then
      can_move_y = false
    end

    if fget(mget(next_map_x, next_map_y)) & player.can_travel == 0 then
      can_move_x = false
      can_move_y = false
    end

    if fget(mget(curr_map_x, curr_map_y), FLAG_STAIRS) then
      qm.ae("PLAYER_GOAL", {})
    end

    -- Make a hypothetical player sprite at the next location after update and check for collision
    local player_at_next = new_sprite(
      0, -- sprite num, doesn't matter
      player_next_x,
      player_next_y,
      player.size_x - 1, -- cheat with smaller player size for ents
      player.size_y - 1
    )
    for k, ent in pairs(ent_man.ents) do
      if fget(ent.num, FLAG_COLLIDES_PLAYER) == true then
      local cheat_ent = new_sprite(
        0, -- sprite num, doesn't matter
        ent.pos_x,
        ent.pos_y,
        ent.size_x, 
        ent.size_y
      )
        if collides(player_at_next, cheat_ent) then 
          can_move_x = false
          can_move_y = false
        end
      end
    end

    -- the slide, deceleration and stopping
    if player.state == PLAYER_STATE_SLIDING then
      if player.vel_x > 0 then
        player.vel_x -= slide_step_down
      elseif player.vel_x < 0 then
        player.vel_x += slide_step_down
      end

      if player.vel_y > 0 then
        player.vel_y -= slide_step_down
      elseif player.vel_y < 0 then
        player.vel_y += slide_step_down
      end

      if (player.vel_x <= slide_step_down and player.vel_x >= -slide_step_down) or can_move_x == false then
        player.vel_x = 0
      end
      if (player.vel_y <= slide_step_down and player.vel_y >= -slide_step_down) or can_move_y == false then
        player.vel_y = 0
      end

      if player.vel_x == 0 and player.vel_y == 0 and player.state == PLAYER_STATE_SLIDING then
        player.state = PLAYER_STATE_GROUNDED
      end
    end

    if can_move_x == true then
      player.pos_x += player.vel_x
    end

    if can_move_y == true then
      player.pos_y += player.vel_y
    end

  end

  return player
end

function sc_sliding(player)
    player.state = PLAYER_STATE_SLIDING
    player.can_travel = (1 << FLAG_FLOOR) | (1 << FLAG_GAP)
end

function get_center_x(sprite)
    return flr(sprite.pos_x + (sprite.size_x \ 2))
end

function get_center_y(sprite)
    return flr(sprite.pos_y + (sprite.size_y \ 2))
end
