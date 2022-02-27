countdown_update = function()
    for k,timer in pairs(timers) do
      if timer.ttl > 0 then
        timer.ttl -= 1
        timer.f()
      else
        timer.cleanup()
        timers[k] = nil
      end
    end
end

countdown_draw = function()
  game_draw()
  rectfill(32-32, 36-32, 98-32, 64-32, CLR_PRP)
  print("level "..level_index, 49-32, 41-32, CLR_BLK)
  print("level "..level_index, 50-32, 40-32, CLR_RED)
  print("countdown", 46-32, 49-32, CLR_DGN)
  print("countdown", 47-32, 48-32, CLR_GRN)
  print(timers[1].ttl \ 60 + 1, 62-32, 55-32, CLR_DGN)
  print(timers[1].ttl \ 60 + 1, 63-32, 56-32, CLR_GRN)
end
