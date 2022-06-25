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
  print("level "..level_index, 49-32, 48-32, CLR_DGN)
  print("level "..level_index, 50-32, 47-32, CLR_GRN)
end
