function new_gravity()
  local tmp = {
    active = false,
    cooldown = false,
    pos_x = 0,
    pos_y = 0,
    sprites = {}
  }

  -- String -> { pos_x: Int, pos_y: Int, input_mask: Int }
  tmp.handle_button = function(name, payload)
    if count(tmp.sprites) > 0 then
      return
    end

    if (payload.input_mask & (1 << 1)) > 0 then
      if tmp.active == true or tmp.cooldown == true then
        return
      end

      tmp.active = true
      tmp.pos_x = payload.pos_x
      tmp.pos_y = payload.pos_y
      add(tmp.sprites, new_sprite(16, payload.pos_x - 4, payload.pos_y, 4, 8, false, false))
      add(tmp.sprites, new_sprite(16, payload.pos_x + 3, payload.pos_y, 4, 8, true, false))
      -- Display sprite for 30 frames
      add(timers, {
        ttl = 30,
        f = function() end,
        cleanup = function()
          tmp.active = false
          tmp.cooldown = true
          tmp.sprites = {}
        end
      })
      -- Have an add'l 30 frames of cooldown
      add(timers, {
        ttl = 60,
        f = function() end,
        cleanup = function()
          tmp.active = false
          tmp.cooldown = false
          tmp.sprites = {}
        end
      })
    end
  end

  tmp.reset = function()
    tmp.active = false
    tmp.cooldown = false
    tmp.pos_x = 256
    tmp.pos_y = 256
    tmp.sprites = {}
  end

  return tmp
end

