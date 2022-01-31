pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
#include const.lua
#include qico.lua
#include player.lua
#include fuel.lua
#include obstacle.lua
#include grav.lua
#include score.lua
#include level.lua
#include title.lua
#include countdown.lua

--[[
-- GLOBALS
-- qm: qico queue manager
-- gm: game manager (score etc)
-- fuel_man: fuel manager
-- obs_man: obstacle manager
-- player: player object
-- gravity: gravity well object
-- timers: table of running timers, these might fire events when they expire
-- levels: holds level data
-- level: current level pointer
-- level_index: table index of current level
--]]
--
function __draw() end
function __update() end


over_draw = function()
  cls()
  print("GAME OVER", 0, 0, CLR_YLW)
end

over_update = function()
  if btnp(BTN_X) or btnp(BTN_O) then
    _init()
  end
end

victory_draw = function()
  cls()
  print("VICTORY", 65, 65, CLR_DGN)
  print("VICTORY", 64, 64, CLR_GRN)
end

victory_update = function()
end

game_draw = function()
  cls()
  print("time: "..level.time, 0, 120, 14)

  if player.invincible == false or (frame_counter % 4 == 1) then
    player.draw()
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

game_update = function()
    local input_mask = 0
    -- UDLROX
    if btn(BTN_U) then
      input_mask = input_mask | (1 << 5)
    end

    if btn(BTN_D) then
      input_mask = input_mask | (1 << 4)
    end

    if btn(BTN_L) then
      input_mask = input_mask | (1 << 3)
    end

    if btn(BTN_R) then
      input_mask = input_mask | (1 << 2)
    end

    if btnp(BTN_O) then
      input_mask = input_mask | (1 << 1)
    end

    qm.ae("BUTTON", { pos_x = player.pos_x, pos_y = player.pos_y, input_mask = input_mask })

    -- Move stuff around
    player.move(obs_man)

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

    if count(fuel_man.fuels) == 0 then
      level_index += 1
      if level_index > count(levels) then
        __update = victory_update
        __draw = victory_draw
      else
        gravity.reset()
        level = levels[level_index]
        init_level(level)
        __update = countdown_update
        __draw = countdown_draw
        add(timers, {
          ttl = COUNTDOWN_TIMEOUT,
          f = function() end,
          cleanup = function()
            __update = game_update
            __draw = game_draw
          end
        })
        return
      end

      return
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

    -- Process queue
    qm.proc()
end

function _init()
  cls()

  -- Get that kico
  qm = qico()
  qm.at("BUTTON")
  qm.at("FUEL_COLLISION")
  qm.at("OBS_COLLISION")
  qm.at("GRAVITY")

  -- Set up our score manager
  score_man = new_score_manager()
  -- Score manager subscriptions
  qm.as("FUEL_COLLISION", score_man.handle_fuel_collision)
  qm.as("OBS_COLLISION", score_man.handle_obs_collision)

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

  level_index = 1

  -- Set up timers table for later...
  timers = {}

  -- Frame counter, used for animation flashing and maybe other things eventually?
  frame_counter = 0

  __draw = title_draw
  __update = title_update
end

function init_level(l)
  fuel_man.reset()
  for k, fuel in pairs(l.fuels) do
    fuel_man.add_fuel(fuel)
  end

  obs_man.reset()
  for k, obs in pairs(l.obstacles) do
    obs_man.add_obstacle(obs)
  end

  player.pos_x = l.player.pos_x
  player.pos_y = l.player.pos_y

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
  -- Kinda hacky; but if we're in "game mode" do this stuff
  if __update == game_update then
    if level.time > 0 then
      level.time -= 1
    elseif level.time <= 0 then
      __update = over_update
      __draw = over_draw
    end
  end

  __update()
end

function _draw()
  __draw()
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

function new_sprite(sprite_num, pos_x, pos_y, size_x, size_y, flip_x, flip_y)
  return {
    num = sprite_num,
    pos_x = pos_x,
    pos_y = pos_y,
    size_x = size_x,
    size_y = size_y,
    flip_x = flip_x,
    flip_y = flip_y,
  }
end

__gfx__
0000000000222000000000000995959909959599099595990099999500999995009999950999a9990999a9990999a99900000000000000000000000000000000
000000000288820002000555055c5c55055c5c55055c5c550055555c0055555c0055555c0599a99505999a95059a999500000000000000000000000000000000
0070070000222000282052200f5c5c5f0f5c5c5f0f5c5c5f009fff5c009fff5c009fff5c0f99999f0f99999f0f99999f00000000000000000000000000000000
00077000000200002822222000fffff000fffff000fffff0000777ff000777ff000777ff00fffff000fffff000fffff000000000000000000000000000000000
0007700000225000282022200733e3370f33e3370733e33f00776733007767330077673307777777067777770777777600000000000000000000000000000000
0070070002222500020002220f73e37f0773e37f0f73e3770077f773007f777300777f7306777776077777770777777700000000000000000000000000000000
00000000022225000000000007733377077333110113337700177777007777170017777707777777077777760677777700000000000000000000000000000000
00000000020005000000000001100011010000110110000100110011010000110100001101100011011000010100001100000000000000000000000000000000
00dd000000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0000000d0000d00003338000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d00d0000d00dd00d0033333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d00000d0d00d0d0353353000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d00000000000000335533000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d00d0000000000000335533000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d000000000000000353353000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dd0000000000000333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00650600006666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06656000056656600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66506666066656650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56666055666606560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06665660605666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00656000006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
