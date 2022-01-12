function new_sprite(sprite_num, pos_x, pos_y, size_x, size_y, flip_x, flip_y)
  return {
    num = sprite_num,
    pos_x = pos_x,
    pos_y = pos_y,
    size_x = size_x,
    size_y = size_y,
    flip_x = flip_x,
    flip_y = flip_y,
  }

end

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

  player.handle_obs_collision = function(obs_index)
    rnd_x = flr(rnd(RESOLUTION_X - 16))
    rnd_y = flr(rnd(RESOLUTION_Y - 16))
    player.pos_x = rnd_x
    player.pos_y = rnd_y
  end

  player.handle_button = function(name, payload)
    local velocity = 1.2
      if payload.button == "UP" then
        player.pos_y -= velocity
        if player.pos_y < 0 then
          player.pos_y = 0
        end
        player.flip_x = false
        player.flip_y = false
        player.num = 1
      elseif payload.button == "DOWN" then
        player.pos_y += velocity
        if player.pos_y + player.size_y > RESOLUTION_Y then
          player.pos_y = RESOLUTION_Y - player.size_y
        end
        player.flip_x = true
        player.flip_y = true
        player.num = 1
      elseif payload.button == "LEFT" then
        player.pos_x -= velocity
        if player.pos_x < 0 then
          player.pos_x = 0
        end
        player.num = 2
        player.flip_x = false
        player.flip_y = false
      elseif payload.button == "RIGHT" then
        player.pos_x += velocity
        if player.pos_x + player.size_x > RESOLUTION_X then
          player.pos_x = RESOLUTION_X - player.size_x
        end
        player.num = 2
        player.flip_x = true
        player.flip_y = true
      end
  end

  return player
end
