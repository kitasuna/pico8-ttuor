function title_draw()
  cls()
  spr(196,16,32,12,4)
  print("press x or o to start", 22, 96, CLR_DGY)
  print("press x or o to start", 23, 96, CLR_WHT)
end

function title_fadeout_0()
  cls()
  pal(2, 1)
  pal(7, 2)
  pal(14, 2)
  title_draw()
  pal()
end

function title_fadeout_1()
  cls()
  pal(2, 0)
  pal(7, 1)
  pal(14, 1)
  title_draw()
  pal()
end

-- for levels
function fade1()
  level_fade({5,1,6,2})
end

-- for levels
function fade0()
  level_fade({7,2,6,1})
end

function level_fade(seq)
  cls()
  for i=0,15 do
    pal(i, 0)
  end
  pal(seq[1], seq[2])
  pal(seq[3], seq[4])
  game_draw()
  pal()
end

timers_and_q = function()
    qm.proc()
    do_timers()
end

title_update = function()
    if btnp(BTN_X) or btnp(BTN_O) then
      sfx_start_game()
      level = levels[level_index]
      init_level(level)
      -- second stage fade
      add(timers, {15, function()
        __draw = title_fadeout_1
      end
    })

      -- complete black
      add(timers, {30, function()
          __draw = function() cls() end
        end
      })

      -- first fadein
      add(timers, {45, function()
          __draw = fade0
        end
      })

      -- second fadein
      add(timers, {60,function()
          __draw = fade1
        end
      })

      -- start (fade in) game
      add(timers, {75,function()
          music(2)
          __update = game_update
          __draw = game_draw
        end
      })
      __update = do_timers
      __draw = title_fadeout_0
    end
end

function fofi()
  ent_man.reset()
  __update = timers_and_q
  __draw = fade1

  -- second fadeout
  add(timers, {5, function()
      printh("fadeout3")
      __draw = fade0
    end
  })

  -- first fadein
  add(timers, {10, function()
      printh("level init, fade0")
      level = levels[level_index]
      init_level(level)
      __draw = fade0
    end
  })

  -- second fadein
  add(timers, {15, function()
      printh("fade1")
      __draw = fade1
    end
  })

  -- start (fade in) game
  add(timers, {20, function()
      timers = {}
      __update = game_update
      __draw = game_draw
    end
  })
end
