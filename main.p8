pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
#include const.lua
#include qico.lua
#include sprite.lua
#include fuel.lua
#include obstacle.lua
#include grav.lua
#include mngr.lua
#include level.lua

--[[
-- GLOBALS
-- qm: qico queue manager
-- fuel_man: fuel manager
-- obs_man: obstacle manager
-- player: player object
-- gravity: gravity well object
-- timers: table of running timers, these might fire events when they expire
-- levels: holds level data
--]]
function _init()
  cls()

  -- Get that kico
  qm = qico()
  qm.at("BUTTON")
  qm.at("FUEL_COLLISION")
  qm.at("OBS_COLLISION")
  qm.at("GRAVITY")

  -- Set up our game manager
  gm = new_manager()
  -- GM subscriptions
  qm.as("FUEL_COLLISION", gm.handle_fuel_collision)
  qm.as("OBS_COLLISION", gm.handle_obs_collision)

  -- Set up our fuel manager
  fuel_man = new_fuel_manager()
  -- Fuel manager subscriptions
  qm.as("FUEL_COLLISION", fuel_man.handle_collision)
  qm.as("GRAVITY", fuel_man.handle_gravity)

  -- Set up our obstacle manager
  obs_man = new_obstacle_manager()
  qm.as("OBS_COLLISION", obs_man.handle_collision)
  qm.as("GRAVITY", obs_man.handle_gravity)

  -- Add sprite
  player = new_player(1, 64, 64, 8, 8)
  -- Player subscriptions
  qm.as("BUTTON", player.handle_button)
  qm.as("OBS_COLLISION", player.handle_obs_collision)

  -- Create gravity entity
  gravity = new_gravity()
  -- Gravity subscriptions
  qm.as("BUTTON", gravity.handle_button)


  -- Load levels
  levels = get_levels()

  for k, fuel in pairs(levels[1].fuels) do
    fuel_man.add_fuel(fuel)
  end

  for k, obs in pairs(levels[1].obstacles) do
    obs_man.add_obstacle(obs)
  end

  -- Set up timers table for later...
  timers = {}
end

-- Sprite -> {pos_x, pos_y}
-- Find coordinates some safe distance away from the player
function find_safe_xy(player_sprite)
  local rnd_x = 0
  local rnd_y = 0
  found = false
  while not found do
    rnd_x = flr(rnd(RESOLUTION_X - 16))
    rnd_y = flr(rnd(RESOLUTION_Y - 16))
    local tmp = new_fuel({pos_x = rnd_x, pos_y = rnd_y})
    if not collides(player_sprite, tmp) then
      found = true
    end
  end

  return {
    pos_x = rnd_x,
    pos_y = rnd_y,
  }
end

function _update60()
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
      qm.ae("FUEL_COLLISION", {index = k})
    end
  end

  for k,obs in pairs(obs_man.obstacles) do
    -- Update pos first
    obs.update()
    
    if (collides(player, obs)) then
      qm.ae("OBS_COLLISION", {index = k})
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

  -- Process queue
  qm.proc()
end

-- Sprite -> Sprite -> Bool
-- Test if two sprites collide
function collides(s0, s1)
  if (
    s0.pos_x < (s1.pos_x) + (s1.size_x)
    and s0.pos_x + s0.size_x > (s1.pos_x)
    and s0.pos_y + s0.size_y > s1.pos_y
    and s0.pos_y < s1.pos_y + s1.size_y
    ) then
    return true
  end

  return false
end

function _draw()
  cls()
  print("space cheerios", 0, 0, CLR_RED)
  print("score: "..gm.score, 0, 8, CLR_IND)

  spr(player.num, player.pos_x, player.pos_y, 1.0, 1.0, player.flip_x, player.flip_y)

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
__gfx__
00000000006660000000000065656566000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000068886000600055506cccc60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700006660006860566006c66660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000600006866666006c66660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000006650006860666006ccc660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700066665000600066606c66660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066665000000000006c66660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000060005000000000066565656000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dd000000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0000000d0000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d00d0000d00dd00d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d00000d0d00d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d00d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44404444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40444044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44544044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04440440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
