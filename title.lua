title_draw = function()
  cls()
  spr(196,16,32,12,4)
  print("press x or o to start", 24, 96, CLR_WHT)
end

fadeout_0 = function()
  cls()
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
  cls()
  for i=0,15 do
    pal(i, 0)
  end
  pal(14, 1)
  pal(7, 1)
  title_draw()
  pal()
end

-- for levels
fadeout_2 = function()
  cls()
  for i=0,15 do
    pal(i, 0)
  end
  pal(5, 1)
  pal(6, 2)
  game_draw()
  pal()
end

-- for levels
fadeout_3 = function()
  cls()
  for i=0,15 do
    pal(i, 0)
  end
  pal(7, 2)
  pal(6, 1)
  game_draw()
  pal()
end

fadein_0 = function()
  for i=0,15 do
    pal(i, 0)
  end
  pal(7, 2)
  pal(6, 1)
  game_draw()
  pal()
end

fadein_1 = function()
  for i=0,15 do
    pal(i, 0)
  end
  pal(5, 1)
  pal(6, 2)
  game_draw()
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

timers_and_q = function()
    qm.proc()
    timers_only()
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

      -- complete black
      add(timers, {
        ttl = 60,
        cleanup = function()
          __draw = function() cls() end
        end
      })

      -- first fadein
      add(timers, {
        ttl = 90,
        cleanup = function()
          __draw = fadein_0
        end
      })

      -- second fadein
      add(timers, {
        ttl = 120,
        cleanup = function()
          __draw = fadein_1
        end
      })

      -- start (fade in) game
      add(timers, {
        ttl = 150,
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

function fofi()
  ent_man.reset()
  __update = timers_and_q
  __draw = fadeout_2

  -- second fadeout
  add(timers, {
    ttl = 15,
    cleanup = function()
      printh("fadeout3")
      __draw = fadeout_3
    end
  })

  -- first fadein
  add(timers, {
    ttl = 30,
    cleanup = function()
      printh("level init, fadein_0")
      level = levels[level_index]
      init_level(level)
      __draw = fadein_0
    end
  })

  -- second fadein
  add(timers, {
    ttl = 45,
    cleanup = function()
      printh("fadein_1")
      __draw = fadein_1
    end
  })

  -- start (fade in) game
  add(timers, {
    ttl = 60,
    cleanup = function()
      timers = {}
      __update = game_update
      __draw = game_draw
    end
  })
end
