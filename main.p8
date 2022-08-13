pico-8 cartridge // http://www.pico-8.com
version 35
__lua__
#include const.lua
#include qico.lua
#include player.lua
#include entity.lua
#include grav.lua
#include level.lua
#include title.lua
#include countdown.lua

--[[
-- GLOBALS
-- qm: qico queue manager
-- gm: game manager (handles resetting of levels etc)
-- ent_man: entity manager
-- player: player object
-- gravity: gravity well object
-- timers: table of running timers, these might fire events when they expire
-- levels: holds level data
-- level: current level pointer
-- level_index: table index of current level
--]]
--
--
function __draw() end
function __update() end


over_draw = function()
  cls()
  camera()
  print("GAME OVER", 0, 0, CLR_YLW)
end

over_update = function()
  if btnp(BTN_X) or btnp(BTN_O) then
    _init()
  end
end

victory_draw = function()
  cls()
  camera()
  print("VICTORY", 50, 65, CLR_DGN)
  print("VICTORY", 51, 64, CLR_GRN)
end

victory_update = function()
end

game_draw = function()
  cls()

  camera(-64 + player.pos_x,-64 + player.pos_y)
  map(level.start_tile_x, level.start_tile_y, level.map_offset_x, level.map_offset_y, level.map_tile_width, level.map_tile_height)
  -- map(level.map_offset_x, level.map_offset_y, 0, 0, 128, 32)
  print("ps: "..player.state, player.pos_x-64, player.pos_y-64, CLR_PNK)
  print("gs: "..grav_man.state, player.pos_x-64, player.pos_y-56, CLR_PRP)
  -- print("es: "..ent_man.ents[1].state, player.pos_x-64, player.pos_y-48, CLR_GRN)
  print("d: "..player.deaths, player.pos_x+32, player.pos_y-64, CLR_RED)
  print("s: "..player.score, player.pos_x+32, player.pos_y-56, CLR_BLU)
  -- print("ds: "..player.deaths, player.pos_x-64, player.pos_y-56, 14)
  -- print("fo: "..player.frame_offset, player.pos_x-64, player.pos_y-48, 14)
  print("pxy: "..player.pos_x..":"..player.pos_y, player.pos_x+16, player.pos_y-48, CLR_BLU)
  -- printh("v: "..player.vel_x..":"..player.vel_y)

  foreach(ent_man.ents, function(ent)
    if ent.pos_y <= player.pos_y and ent.state != ENT_STATE_HELD then
      ent.draw()
    end
  end)

  player.draw()

  foreach(ent_man.ents, function(ent)
    if ent.pos_y > player.pos_y or ent.state == ENT_STATE_HELD then
      ent.draw()
    end
  end)

  if grav_man.gbeam != nil then
    grav_man.gbeam.draw()
  end

  if grav_man.wormhole != nil then
    grav_man.wormhole.draw()
  end

  -- camera()
  -- print("ps: "..player.state, player.pos_x - 64, player.pos_y - 56, 14)
  -- print("pv: "..player.vel_x..","..player.vel_y, player.pos_x - 64, player.pos_y - 48, 14)
end

game_update = function()
    local input_mask = 0
    if btn(BTN_U) then
      input_mask = input_mask | (1 << BTN_U)
    end

    if btn(BTN_D) then
      input_mask = input_mask | (1 << BTN_D)
    end

    if btn(BTN_L) then
      input_mask = input_mask | (1 << BTN_L)
    end

    if btn(BTN_R) then
      input_mask = input_mask | (1 << BTN_R)
    end

    if btn(BTN_O) then
      input_mask = input_mask | (1 << BTN_O)
    end

    if btnp(BTN_X) then
      input_mask = input_mask | (1 << BTN_X)
    end

    player.update(ent_man, level)

    -- Bit of a hack, but ignore button presses if the player is in a 
    -- state that we consider "DEAD"
    if player.is_dead() == false then
      qm.ae("BUTTON", {
        direction = player.facing,
        -- TODO: will need to refactor this later
        -- gives grav_man too much info about the player
        -- consider chaining the events so the player adds a separate event to the grav_man or s/t
        player_state = player.state,
        pos_x = get_center_x(player),
        pos_y = get_center_y(player),
        input_mask = input_mask,
        projectile = grav_man.wormhole
      })
    end

    grav_man.update(level)
    if grav_man.wormhole != nil and collides(grav_man.wormhole, player) then
      qm.ae("PROJ_PLAYER_COLLISION", { projectile = g })
    end


    for k, ent in pairs(ent_man.ents) do
      -- Use the velocity check to make sure this event only fires once
      if ent.type == ENT_BOX and grav_man.wormhole != nil and (grav_man.wormhole.vel_x !=0 or grav_man.wormhole.vel_y != 0) and collides(ent, grav_man.wormhole) then
        qm.ae("PROJ_BOX_COLLISION", { entity=ent })
      end

      if ent.type == ENT_ITEM and collides(ent, player) then
        qm.ae("PLAYER_ITEM_COLLISION", { entity=ent })
      end

      if ent.type == ENT_BEAM and player.state != PLAYER_STATE_DEAD_ZAPPED and collides(ent, player) then
        qm.ae("BEAM_PLAYER_COLLISION", { entity=ent })
      end

      for j, ent_inner in pairs(ent_man.ents) do
        if ent_inner.type == ENT_BEAM and ent.type == ENT_BOX and collides(ent, ent_inner) then
          qm.ae("BEAM_BOX_COLLISION", { box=ent, beam=ent_inner })
        end

        if ent_inner.type == ENT_BEAM and ent.type == ENT_ITEM and collides(ent, ent_inner) then
          qm.ae("BEAM_ITEM_COLLISION", { item=ent, beam=ent_inner })
        end
      end
    end


    for k,e in pairs(ent_man.ents) do
      -- Update pos first
      e.update(level)
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
  printh("!!!!init")

  -- Set up event queue
  qm = qico()
  -- Add some topics
  qm.ats({
    "BUTTON",
    "FUEL_COLLISION",
    "PROJ_PLAYER_COLLISION",
    "PROJ_BOX_COLLISION",
    "BEAM_BOX_COLLISION",
    "BEAM_PLAYER_COLLISION",
    "BEAM_ITEM_COLLISION",
    "PLAYER_DEATH",
    "PROJ_EXPIRATION",
    "GBEAM_REMOVED",
    "ENTITY_REACHES_TARGET",
    "ENTITY_RELEASED",
    "PLAYER_ROTATION",
    "PLAYER_ITEM_COLLISION",
    "LEVEL_INIT",
    "PLAYER_GOAL",
    "PLAYER_INIT_FLOAT",
    "PLAYER_CANCEL_FLOAT",
    "PLAYER_HOLDS",
  })
  gm = {}
  gm.handle_player_death = function(payload)
    init_level(payload.level)
  end

  gm.handle_player_goal = function(payload)
    level_index += 1 
    if level_index > count(levels) then
      __update = victory_update
      __draw = victory_draw
    else
      level = levels[level_index]
      init_level(level)
      add(timers, {
        ttl = COUNTDOWN_TIMEOUT,
        f = function() end,
        cleanup = function()
          __update = game_update
          __draw = game_draw
        end
      })
      __update = countdown_update
      __draw = countdown_draw
    end
  end
  qm.as("PLAYER_DEATH", gm.handle_player_death)
  qm.as("PLAYER_GOAL", gm.handle_player_goal)

  -- Set up our entity manager
  ent_man = new_entity_manager()
  qm.as("BEAM_BOX_COLLISION", ent_man.handle_beam_box_collision)
  qm.as("BEAM_ITEM_COLLISION", ent_man.handle_beam_item_collision)
  qm.as("GBEAM_REMOVED", ent_man.handle_gbeam_removed)
  qm.as("BUTTON", ent_man.handle_button)
  qm.as("PLAYER_ROTATION", ent_man.handle_player_rotation)
  qm.as("PLAYER_ITEM_COLLISION", ent_man.handle_player_item_collision)
  qm.as("LEVEL_INIT", ent_man.handle_level_init)
  qm.as("PLAYER_HOLDS", ent_man.handle_player_holds)

  -- Create gravity manager
  grav_man = new_gravity_manager()
  -- Gravity subscriptions
  qm.as("BUTTON", grav_man.handle_button)
  qm.as("PROJ_PLAYER_COLLISION", grav_man.handle_proj_player_collision)
  qm.as("PLAYER_DEATH", grav_man.handle_player_death)
  qm.as("ENTITY_REACHES_TARGET", grav_man.handle_entity_reaches_target)
  qm.as("ENTITY_RELEASED", grav_man.handle_entity_released)
  qm.as("PLAYER_INIT_FLOAT", grav_man.handle_player_init_float)
  qm.as("PLAYER_CANCEL_FLOAT", grav_man.handle_player_cancel_float)
  qm.as("PROJ_BOX_COLLISION", grav_man.handle_proj_box_collision)

  -- Add sprite
  player = new_player(1, 64, 64, 6, 6)
  -- Player subscriptions
  qm.as("BUTTON", player.handle_button)
  qm.as("BEAM_PLAYER_COLLISION", player.handle_beam_player_collision)
  qm.as("PROJ_PLAYER_COLLISION", player.handle_proj_player_collision)
  qm.as("PROJ_EXPIRATION", player.handle_proj_expiration)
  qm.as("ENTITY_REACHES_TARGET", player.handle_entity_reaches_target)
  qm.as("PLAYER_ITEM_COLLISION", player.handle_player_item_collision)
  qm.as("LEVEL_INIT", player.handle_level_init)

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
  player.reset(l)
  ent_man.reset()
  grav_man.reset()
  for k, e in pairs(l.ents) do
    if e.type==ENT_ITEM then
      ent_man.add_item(e)
    elseif e.type==ENT_BOX then
      ent_man.add_box(e)
    elseif e.type==ENT_BEAM then
      ent_man.add_beam(e)
    else
      printh("unknown type")
    end
  end

  player.pos_x = l.player_pos_x
  player.pos_y = l.player_pos_y

  qm.ae("LEVEL_INIT", {})
  timers = {}
end

function _update60()
  -- Kinda hacky; but if we're in "game mode" do this stuff
  -- currently unused
  if __update == game_update then
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
    -- and (s0.pos_y + s0.size_y + (0)) > s1.pos_y
    and (s0.pos_y + s0.size_y - ((8 - s0.size_y) \ 2)) > (s1.pos_y + ((8 - s1.size_y) \ 2))
    and s0.pos_y < (s1.pos_y + s1.size_y - (0))
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
000000000a9aa9a000000000000000000a9aa9a000000000000000000a9aa9a000000000000000000a9aa9a00a9aa9a00a9aa9a000a9a9a00a9aa9a00a9a9a00
00000000a959959a0a9aa9a00a9aa9a0a959959a0a9aa9a00a9aa9a0a999999a0a9aa9a00a9aa9a0a9c99c9aa9c99c9aa999999a0a95959aa959959aa95959a0
00700700a5c55c5aa959959aa959959aa5f55c5aa959959aa959959aa599995aa999999aa999999aa5c55c5aa5c55c5aa599995a0a5f5c5aa5c55c5aa5c5f5a0
000770000affffa0a5c55c5aa5c55c5a0affffa0a5f55c5aa5f55c5a0affffa0a599995aa599995afaffffaffaf88faf0affffa000affffa0affffa0affffa00
000770000a7337a00affffa00affffa000a773a00affffa00affffa00a7777a00affffa00affffa0af7337faaf7887fa6a7777f000a7773a0f7337a0a3777a00
007007000f7337f00a7337f00f7337a000a7f3a00f7773a00a7777f00f7777f00f7777a00f7777a00ee33ee00ee33ee00f6777a0606777fa0ee337f6af777606
000000000a7337a00f733ee00ee337f000a777a00a7773e00e7773a00a7777a00ee777f00a777ee00ee33ee00ee33ee06ee777a000ae7eea0ee336a0aee7ea00
000000000eeaaee00aeaaee00eeaaea000eeaee00aeaaee00eeaaea00eeaaee00eeaaea00aeaaee00aaaaaa00aaaaaa006eaa00006aeeaa00aaaae600aaeea60
0c9cc9c00c9ca9a00a9ac9c00a9aa9a00a9aa9a00a9aa9a00a9aa9a0a66a00000000000000000000000000000000000000733000000d2d000077700000ddd000
c9a99a9cc9a99c9ca9c99a9aa999999aa959959aa959959aa959959aa55aa9a00a9aa9a00a9aa9a00a9aa9a00000000007bbb3002000200d078887000d222d00
c5a55a5ca5c55a5ac5a55c5ca599995aa5f5fc5aafc55cfaa5f5fc5aa999999aa959959aa959959aa959959a000000007b7b3b30d200000078787870d2d2d2d0
fcf88fcffaf88fcffcf88faf07ffff700aff7fa0a7ffff7a0aff7fa0a599995aa5f55c5aa5c55c5aa5c55f5a000000003bb3bb300220202078878870d22d22d0
cf7337fccf7337faaf7337fc0777777000a773a00773377000a773a007ffffa00affff560afff5666557ffa0000000003bb3bb300dd0022078878870d22d22d0
e333333ee333333ee333333e0a7777a000a773a00a7337a000a773a00a7777a00a7773560a733566655777a0000000003bb3bb300200022078878870d22d22d0
ee3cc3eeee3aa3eeee3aa3ee0a7777a000a777a00a7337a000a777a00a777ee00e77e3a00f73337a0a7777e00000000003b3b3000d0d020d078787000d2d2d00
ccccccccacacacaccacacaca0eeaaee000eeaee00eeaaee000eeaee00aeaaee00eeaaea00aeaaee00aeaaee0000000000033300000000d000077700000ddd000
00ddd00000ddd00000ddd00000ddd00000000000000000000000000000000000880000008800000080000000e222222e00000000070707070000000000000000
0d222d000d222d000d222d000d222d00000000000000000000000000088aa9a0088aa9a0089aa9a0889aa9a0211111120e2222e07aaaaaa00000000000000000
d2d2d2d0d2d2d2d0d2d2d2d0d2d2d2d0000000000000000000000000a988999aa989959aa989959aa989959ae222222e022112200aaaaaa70000000000000000
d22d22d0d22d22d0d22d22d0d22d22d0000000000000000000000000a598895aa5f85c5aa5885f5aa5885c5a221111220e2222e07aaaaaa00000000000000000
d22d22d0d22d22d0d22d22d0d22d22d00000000000000000000000000aff88a00af88fa00af88fa00aff88a022111122022112200aaaaaa70000000000000000
d22d22d0d22d22d0d22d22d0d22d22d0000000000000000000000000057778a00a778860065588a00a7ee88021111112021111207aaaaaa00000000000000000
0d2d2d000d2d2d000d2d2d000d2d2d000000000000000000000000000a777e800e7778800a3778800f733e8822111122022222200aaaaaa70000000000000000
00ddd00000ddd00000ddd00000ddd0000000000000000000000000000aeaaee00eeaae800aeaae800aeaaee82222222200000000707070700000000000000000
00076655000077775555577700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077665777766675557766700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000766dc666666675556666700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000776dc666666677776666700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000766dc666666677666677700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000776dc666666677666677700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00076665777766677667777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077655000077777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55333333000766555667700000000000555555550000000000000000566770000007766555667000555555555555555500076655000000000000000000000000
53333333000776655566700000000000656565650000000000000000656670000007665656677000556565655656565500077665000000000000000000000000
35333333000766555667700000000000666666660000000000000000666770000007766655667000566666666666666500076655000000000000000000000000
33533333000776655566700077777777767676760000777777770000767670000007676756677777556676766767665577777665000000000000000000000000
33553333000766555667700067676767777777770007676776767000777700000000777755667676566777777777766567676655000000000000000000000000
33333333000776655566700066666666000000000007766666677000000000000000000056666666556670000007665566666665000000000000000000000000
33333333000766555667700056565656000000000007665665667000000000000000000055656565566770000007766556565655000000000000000000000000
33333333000776655566700055555555000000000007766556677000000000000000000055555555556670000007665555555555000000000000000000000000
55555555000000000555555555555550555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555050505055555555555555555055555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550555555555555550555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555555055555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550555555555555550555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555555055555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50505050555555550555555555555550555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555555555555555555555055555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000c000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11666666666677777666666677777777666666656666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
16666666667766667666666666666666655555506666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
65666666676666667666666666666666655555506566666600000000000000000000000000000000000000000000000000000000000000000000000000000000
66566666676666667666666666666666655555506666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
66556666766666667666666666666666655555506665666600000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666766666667666666666666666655555506666566600000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666766666667666666666666666655555506666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666766666667666666666666666500000056666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001010101010101010101010101010101010101010101010101010004040404040404040000000101010110001010000000420000000000000000000000000002000000000000000000000000000000020202020200000000000000000000002202000000000000000000000000000002020202020200000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
555555555555005555555555551a1a1a1a1a0000000000000000000000000000000000000000000000000000000000000000000000000000000000454343434343466060606060434343460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000555555555555554543434343434343434343460000454343434600000000000000000000454343430000000000000000307474747474426060606060747474420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4543434343434343434600555555555555004174747474747474747474420000417474744200000000000000000000417474746060434343000000417474747432426060606060747474420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4174747474747474744200555555555555554174747474747474747474420000417474744200004543434343460000417474746060747474606060417474744a44476060606060747474420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4174747474747474744200000000000055004174747474747474747474420000307474744943434c74747474420000417474746060747474606060417474744260606060606060747474420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4174747474747474744200000000000055004174747474747474747432420000417474747474747474747474420000417474746060747474606060606060606060606060606060747474420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4174747474747474744200000000000055554174747474747474747474420000417474747474747474747474420000484444446060747474606060606060606060606060606060747474420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4174747474747474744200000000000055554174747474747474747474420000417474747474747474747474420060606060606060606060606060417474744260606060606030747474420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4174747474747474744200000000000055554174747474747474747474420000417474744a44444b74747474420060607474746060606060606060307474744260417474747474747474420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4174747474747474744200000000000000004844444444444444444444470000417474744200004844444444470060607474746060747474420000417474744260417474747474747474420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
48747474747474747447000000000000000000000000000000000000000000004174747449434343460000000000606074747460607474324200004174747460606074744a4444444444470000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6074747474747474746000000000000000000000000000000000000000000000417474747474743242000000000060606060606060444444470000417474746060607474420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6074747432747474746000000000000000000000000000000000000000000000417474747474747442000000000000000000000000000000000000484444446060604444470000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6060606060606060606000000000000000000000000000000000000000000000484444444444444447000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
