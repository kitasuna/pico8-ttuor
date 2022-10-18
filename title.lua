title_draw = function()
  cls()
  spr(196,16,32,12,4)
  print("press x or o to start", 24, 96, CLR_WHT)
end

fadeout_0 = function()
  for i=0,15 do
    pal(i, 0)
  end
  pal(2, 1)
  pal(7, 2)
  pal(14, 2)
  title_draw()
  pal()
end

fadeout_1 = function()
  for i=0,15 do
    pal(i, 0)
  end
  pal(14, 1)
  pal(7, 1)
  title_draw()
  pal()
end

timers_only = function()
  for k,timer in pairs(timers) do
    if timer.ttl > 0 then
      timer.ttl -= 1
    else
      timer.cleanup()
      timers[k] = nil
    end
  end
end

title_update = function()
    if btnp(BTN_X) or btnp(BTN_O) then
      sfx_start_game()
      level = levels[level_index]
      init_level(level)
      -- second stage fade
      add(timers, {
        ttl = 30,
        cleanup = function()
          __draw = fadeout_1
        end
      })

      -- start (fade in) game
      add(timers, {
        ttl = COUNTDOWN_TIMEOUT,
        cleanup = function()
          music(2)
          __update = game_update
          __draw = game_draw
        end
      })
      __update = timers_only
      __draw = fadeout_0
    end
end
