function new_player(sprite_num, pos_x, pos_y, size_x, size_y, flip_x, flip_y)
  local player = new_sprite(
  sprite_num,
  pos_x,
  pos_y,
  size_x,
  size_y,
  flip_x,
  flip_y
  )

  local velocity_max = 1.0
  -- local velocity_step_up = 0.08
  -- local velocity_step_down = 0.08
  local velocity_step_up = 0.2
  local velocity_step_down = 0.2

  player.vel_x = 0
  player.vel_y = 0
  player.invincible = false
  player.frame_base = 1
  player.frame_offset = 0
  player.frame_step = 0
  player.facing = 2 -- 0: up, 1: right, 2: down, 3: left

  player.handle_obs_collision = function(name, payload)
    -- ignore if player is invincible
    if true or payload.player.invincible then
      return 
    end
    player.pos_x = 64
    player.pos_y = 64
    player.invincible = true
    add(timers, {
      ttl = 120,
      f = function() end,
      cleanup = function()
        player.invincible = false
      end
    })
  end

  player.handle_button = function(name, payload)
    -- Try returning if grav button is being held down
    if payload.input_mask & (1 << 1) > 0 then
      player.vel_x = 0
      player.vel_y = 0
      if payload.input_mask & (1 << 5) > 0 then
        player.facing = 0
        player.frame_base = 9
      elseif payload.input_mask & (1 << 4) > 0 then
        player.facing = 2
        player.frame_base = 1
      elseif payload.input_mask & (1 << 2) > 0 then
        player.facing = 1
        player.frame_base = 5
        player.flip_x = false
      elseif payload.input_mask & (1 << 3) > 0 then
        player.facing = 3
        player.frame_base = 5
        player.flip_x = true
      end
      return
    end

    -- Up
    if payload.input_mask & (1 << 5) > 0 then
      player.facing = 0
      if abs(player.vel_y) < velocity_max then
        player.vel_y -= velocity_step_up
      end
    -- Down
    elseif payload.input_mask & (1 << 4) > 0 then
      player.facing = 2
      if abs(player.vel_y) < velocity_max then
        player.vel_y += velocity_step_up
      end
    elseif player.vel_y < 0 then
      player.facing = 0
      player.vel_y += velocity_step_down
    elseif player.vel_y > 0 then
      player.facing = 2
      player.vel_y -= velocity_step_down
    end

    -- Left
    if payload.input_mask & (1 << 3) > 0 then
      player.facing = 3
      if abs(player.vel_x) < velocity_max then
        player.vel_x -= velocity_step_up
      end
    -- Right
    elseif payload.input_mask & (1 << 2) > 0 then
      player.facing = 1
      if abs(player.vel_x) < velocity_max  then
        player.vel_x += velocity_step_up
      end
    elseif player.vel_x > 0 then
      player.vel_x -= velocity_step_down
    elseif player.vel_x < 0 then
      player.vel_x += velocity_step_down
    end

    if player.facing == 2 then
      player.frame_base = 1
    elseif player.facing == 0 then
      player.frame_base = 9
    elseif player.facing == 1 then
      player.frame_base = 5
      player.flip_x = false
    elseif player.facing == 3 then
      player.frame_base = 5
      player.flip_x = true
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
    spr(player.frame_base + player.frame_offset, player.pos_x, player.pos_y, 1.0, 1.0, player.flip_x, player.flip_y)
  end

  player.move = function(obs_man)
    -- Get player x/y map cell
    local map_offset_x = 40
    local map_offset_y = 32
    local player_next_x = (player.pos_x + player.vel_x - map_offset_x) + (player.vel_x > 0 and 7 or 0)
    local player_next_y = (player.pos_y + player.vel_y - map_offset_y) + (player.vel_y > 0 and 7 or 0)
    local map_x = (player_next_x) \ 8
    local map_y = (player_next_y) \ 8
    if fget(mget(map_x, map_y), 1) == false then
      player.pos_x += player.vel_x
    end

    if fget(mget(map_x, map_y), 1) == false then
      player.pos_y += player.vel_y
    end

    -- prevent players from sneaking past obstacles while invincible
    if player.invincible == true and obs_man.check_collision(player) then
      player.pos_x -= player.vel_x
      player.pos_y -= player.vel_y
    end

    if player.pos_x < 0 then
      player.pos_x = 0
    elseif player.pos_x + player.size_x > RESOLUTION_X then
      player.pos_x = RESOLUTION_X - player.size_x
    end

    if player.pos_y + player.size_y > RESOLUTION_Y then
      player.pos_y = RESOLUTION_Y - player.size_y
    elseif player.pos_y < 0 then
      player.pos_y = 0
    end
  end

  return player
end
