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
  rectfill(32, 36, 98, 64, CLR_DGY)
  print("level "..level_index, 49, 41, CLR_BLK)
  print("level "..level_index, 50, 40, CLR_RED)
  print("countdown", 46, 49, CLR_DGN)
  print("countdown", 47, 48, CLR_GRN)
  print(timers[1].ttl \ 60 + 1, 62, 55, CLR_DGN)
  print(timers[1].ttl \ 60 + 1, 63, 56, CLR_GRN)
end
