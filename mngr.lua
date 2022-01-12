function new_manager()
  local manager = {
    score = 0,
    draw = function() end,
    update = function() end,
    title = {},
    game = {}
  }

  title = {}

  title.draw = function()
    cls()
    print("ENTROPIST", 0, 0, CLR_YLW)
    print("PRESS () FOR GRAVITY", 0, 6, CLR_YLW)
    print("GET THESE", 23, 24, CLR_GRN)
    print("DON'T TOUCH THESE", 23, 36, CLR_RED)
    spr(3, 15, 22)
    spr(32, 15, 34)
  end

  title.update = function()
    if btn(BTN_X) or btn(BTN_O) then
      manager.update = game.update
      manager.draw = game.draw
    end
  end

  manager.title = title

  game = {}

  game.draw = function()
    cls()
    print("time: "..level.time, 0, 120, 14)

    if player.invincible == false or (frame_counter % 4 == 1) then
      spr(player.num, player.pos_x, player.pos_y, 1.0, 1.0, player.flip_x, player.flip_y)
    end

    foreach(fuel_man.fuels, function(fuel)
      spr(fuel.num, fuel.pos_x, fuel.pos_y)
    end)

    foreach(obs_man.obstacles, function(obs)
      spr(obs.num, obs.pos_x, obs.pos_y)
    end)

    foreach(gravity.sprites, function(grav)
      spr(grav.num, grav.pos_x, grav.pos_y, 1.0, 1.0, grav.flip_x, grav.flip_y)
    end)
  end

  game.update = function()

    if btn(BTN_U) then
      qm.ae("BUTTON", { button = "UP" })
    end

    if btn(BTN_D) then
      qm.ae("BUTTON", { button = "DOWN" })
    end

    if btn(BTN_L) then
      qm.ae("BUTTON", { button = "LEFT" })
    end

    if btn(BTN_R) then
      qm.ae("BUTTON", { button = "RIGHT" })
    end

    if btnp(BTN_O) then
      qm.ae("BUTTON", { button = "O", pos_x = player.pos_x, pos_y = player.pos_y })
    end

    -- See if there's some active gravity
    if gravity.active and not gravity.cooldown then
      qm.ae("GRAVITY", { pos_x = gravity.pos_x, pos_y = gravity.pos_y })
    end

    -- Check collision with fuel
    -- foreach(fuel_man.fuels, function(fuel)
    for k,fuel in pairs(fuel_man.fuels) do
      -- Update pos first
      fuel.update()
      if (collides(player, fuel)) then
        qm.ae("FUEL_COLLISION", fuel)
      end
    end

    for k,obs in pairs(obs_man.obstacles) do
      -- Update pos first
      obs.update()

      if (collides(player, obs)) then
        qm.ae("OBS_COLLISION", { player=player, obstacle=obs})
      end
    end

    for k,timer in pairs(timers) do
      if timer.ttl > 0 then
        timer.ttl -= 1
        timer.f()
      else
        timer.cleanup()
        timers[k] = nil
      end
    end

    frame_counter += 1
    if frame_counter >= 1200 then
      frame_counter = 0
    end

    if level.time > 0 then
      level.time -= 1
    end

    -- Process queue
    qm.proc()
  end

  manager.game = game

  manager.draw = title.draw
  manager.update = title.update

  manager.handle_fuel_collision = function(event_name, event_payload)
    manager.score += 1
  end

  manager.handle_obs_collision = function(event_name, event_payload)
    -- manager.score += 1
  end

  return manager
end
