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

  local velocity_max = 1.2
  -- local velocity_step_up = 0.08
  -- local velocity_step_down = 0.08
  local velocity_step_up = 0.3
  local velocity_step_down = 0.3

  player.vel_x = 0
  player.vel_y = 0
  player.invincible = false

  player.handle_obs_collision = function(name, payload)
    -- ignore if player is invincible
    if payload.player.invincible then
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
      if payload.input_mask & (1 << 5) > 0 and abs(player.vel_y) < velocity_max then
        player.vel_y -= velocity_step_up
        player.flip_x = false
        player.flip_y = false
        player.num = 1
      elseif payload.input_mask & (1 << 4) > 0 and abs(player.vel_y) < velocity_max then
        player.vel_y += velocity_step_up
        player.flip_x = true
        player.flip_y = true
        player.num = 1
      elseif player.vel_y > 0 then
        player.vel_y -= velocity_step_down
      elseif player.vel_y < 0 then
        player.vel_y += velocity_step_down
      end

      if payload.input_mask & (1 << 3) > 0 and abs(player.vel_x) < velocity_max then
        player.vel_x -= velocity_step_up
        player.num = 2
        player.flip_x = false
        player.flip_y = false

      elseif payload.input_mask & (1 << 2) > 0 and abs(player.vel_x) < velocity_max then
        player.vel_x += velocity_step_up
        player.num = 2
        player.flip_x = true
        player.flip_y = true
      elseif player.vel_x > 0 then
        player.vel_x -= velocity_step_down
      elseif player.vel_x < 0 then
        player.vel_x += velocity_step_down
      end
  end

  player.move = function(obs_man)
    player.pos_x += player.vel_x

    player.pos_y += player.vel_y

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
