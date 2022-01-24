title_draw = function()
  cls()
  print("ENTROPIST", 0, 0, CLR_YLW)
  print("GET THESE", 24, 24, CLR_GRN)
  print("DON'T TOUCH THESE", 24, 36, CLR_RED)
  print("PRESS (X) FOR GRAVITY", 25, 48, CLR_IND)
  spr(3, 15, 22)
  spr(32, 15, 34)
  spr(16, 15, 47, 1.0, 1.0)
  spr(16, 15, 47, 1.0, 1.0, true, false)
end

title_update = function()
    if btnp(BTN_X) or btnp(BTN_O) then
      level = levels[level_index]
      init_level(level)
      add(timers, {
        ttl = COUNTDOWN_TIMEOUT,
        f = function() end,
        cleanup = function()
          __update = game_update
          __draw = game_draw
        end
      })
      __update = countdown_update
      __draw = countdown_draw
    end
end
