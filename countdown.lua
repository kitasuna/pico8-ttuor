countdown_update = function()
    for k,timer in pairs(timers) do
      if timer.ttl > 0 then
        timer.ttl -= 1
      else
        timer.cleanup()
        timers[k] = nil
      end
    end
end

countdown_draw = function()
  game_draw()
  camera()
  rectfill(42, 56, 86, 72, CLR_PRP)
  print("level "..level_index, 50, 62, CLR_DGN)
  print("level "..level_index, 51, 61, CLR_GRN)
end
