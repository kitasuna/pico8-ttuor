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
  print("VICTORY", 65, 65, CLR_DGN)
  print("VICTORY", 64, 64, CLR_GRN)
end

victory_update = function()
end

game_draw = function()
  cls()

  camera(-64 + player.pos_x,-64 + player.pos_y)
  map(0, 0, level.map_offset.pos_x, level.map_offset.pos_y, 128, 32)
  print("ps: "..player.state, player.pos_x-64, player.pos_y-64, CLR_PNK)
  print("gs: "..grav_man.state, player.pos_x-64, player.pos_y-56, CLR_PRP)
  print("es: "..ent_man.ents[1].state, player.pos_x-64, player.pos_y-48, CLR_GRN)
  print("d: "..player.deaths, player.pos_x+32, player.pos_y-64, CLR_RED)
  print("s: "..player.score, player.pos_x+32, player.pos_y-56, CLR_BLU)
  -- print("ds: "..player.deaths, player.pos_x-64, player.pos_y-56, 14)
  -- print("fo: "..player.frame_offset, player.pos_x-64, player.pos_y-48, 14)
  -- print("v: "..player.vel_x..":"..player.vel_y, 15)
  -- printh("v: "..player.vel_x..":"..player.vel_y)
  if player.invincible == false or (frame_counter % 4 == 1) then
    player.draw()
  end

  foreach(ent_man.ents, function(ent)
    ent.draw()
  end)

  foreach(grav_man.gravities, function(grav)
    grav.draw()
  end)

  if grav_man.gbeam != nil then
    grav_man.gbeam.draw()
  end

  foreach(grav_man.projectiles, function(grav)
    grav.draw()
  end)

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

    player.update(ent_man)

    qm.ae("BUTTON", {
      pos_x = player.pos_x + (player.size_x \ 2),
      pos_y = player.pos_y + (player.size_y \ 2),
      input_mask = input_mask,
      direction = player.facing,
      projectile = (count(grav_man.projectiles) > 0) and grav_man.projectiles[1] or nil
    })

    grav_man.update()
    for k, g in pairs(grav_man.projectiles) do
      if collides(g, player) then
        qm.ae("PROJ_PLAYER_COLLISION", { projectile = g })
      end
    end


    for k, ent in pairs(ent_man.ents) do
      if ent.type == ENT_ITEM and collides(ent, player) then
        qm.ae("PLAYER_ITEM_COLLISION", { entity=ent })
      end

      if ent.type == ENT_BEAM and player.state != PLAYER_STATE_DEAD_ZAPPED and collides(ent, player) then
        qm.ae("BEAM_PLAYER_COLLISION", { entity=ent })
      end

      for j, grav in pairs(grav_man.gravities) do
        if collides(grav, ent) then
          qm.ae("ENTITY_GRAV_COLLISION", { entity=ent, grav=grav })
        end
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

    -- if gravity.mass > level.critical_mass then
    if false then
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

    for k,e in pairs(ent_man.ents) do
      -- Update pos first
      e.update()
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

  -- Set up event queue
  qm = qico()
  qm.at("BUTTON")
  qm.at("FUEL_COLLISION")
  qm.at("ENTITY_GRAV_COLLISION")
  qm.at("PROJ_PLAYER_COLLISION")
  qm.at("BEAM_BOX_COLLISION")
  qm.at("BEAM_PLAYER_COLLISION")
  qm.at("BEAM_ITEM_COLLISION")
  qm.at("PLAYER_DEATH")
  qm.at("PROJ_EXPIRATION")
  qm.at("GBEAM_REMOVED")
  qm.at("ENTITY_REACHES_TARGET")
  qm.at("ENTITY_REACHES_TARGET")
  qm.at("PLAYER_ROTATION")
  qm.at("PLAYER_ITEM_COLLISION")

  gm = {}
  gm.handle_player_death = function(name, payload)
    init_level(payload.level)
  end
  qm.as("PLAYER_DEATH", gm.handle_player_death)

  -- Set up our entity manager
  ent_man = new_entity_manager()
  qm.as("ENTITY_GRAV_COLLISION", ent_man.handle_ent_grav_collision)
  qm.as("BEAM_BOX_COLLISION", ent_man.handle_beam_box_collision)
  qm.as("BEAM_ITEM_COLLISION", ent_man.handle_beam_item_collision)
  qm.as("GBEAM_REMOVED", ent_man.handle_gbeam_removed)
  qm.as("BUTTON", ent_man.handle_button)
  qm.as("PLAYER_ROTATION", ent_man.handle_player_rotation)
  qm.as("PLAYER_ITEM_COLLISION", ent_man.handle_player_item_collision)

  -- Create gravity manager
  grav_man = new_gravity_manager()
  -- Gravity subscriptions
  qm.as("BUTTON", grav_man.handle_button)
  qm.as("ENTITY_GRAV_COLLISION", grav_man.handle_ent_grav_collision)
  qm.as("PROJ_PLAYER_COLLISION", grav_man.handle_proj_player_collision)
  qm.as("PLAYER_DEATH", grav_man.handle_player_death)
  qm.as("ENTITY_REACHES_TARGET", grav_man.handle_entity_reaches_target)

  -- Add sprite
  player = new_player(1, 64, 64, 6, 6)
  -- Player subscriptions
  qm.as("BUTTON", player.handle_button)
  qm.as("BEAM_PLAYER_COLLISION", player.handle_beam_player_collision)
  qm.as("PROJ_PLAYER_COLLISION", player.handle_proj_player_collision)
  qm.as("PROJ_EXPIRATION", player.handle_proj_expiration)
  qm.as("ENTITY_REACHES_TARGET", player.handle_entity_reaches_target)
  qm.as("PLAYER_ITEM_COLLISION", player.handle_player_item_collision)

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
  printh("init level")
  player.reset(l)
  ent_man.reset()
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

  player.pos_x = l.player.pos_x
  player.pos_y = l.player.pos_y

  timers = {}
end

function _update60()
  -- Kinda hacky; but if we're in "game mode" do this stuff
  if __update == game_update then
    if false then -- TODO: Add game over condition here
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
000770000a7ee7a00affffa00affffa000a77ea00affffa00affffa00a7777a00affffa00affffa0af7ee7faaf7887fa6a7777f000a7773a0f7ee7a0a3777a00
007007000f7337f00a6ee7f00f7ee6a000a7f3a00f777ea00a7777f00f7777f00f7777a00f7777a00ee33ee00ee33ee00f6777a0606777fa0ee337f6af777606
000000000a7337a00f633ee00ee336f000a777a00a7773e00e7773a00a7777a00ee777f00a777ee00ee33ee00ee33ee06ee777a000ae7eea0ee336a0aee7ea00
000000000eeaaee00aeaaee00eeaaea000eeaee00aeaaee00eeaaea00eeaaee00eeaaea00aeaaee00aaaaaa00aaaaaa006eaa00006aeeaa00aaaae600aaeea60
0c9cc9c00c9ca9a00a9ac9c000000000000000000000000000000000000000000000000053555335000000000000000000ddd000000d2d0000ddd00000ddd000
c9a99a9cc9a99c9ca9c99a9a0000000000000000000000000000000000000000000000003555355300000000000000000d222d002000200d0d222d000d222d00
c5a55a5ca5c55a5ac5a55c5c000000000000000000000000000000000000000000000000353535530000000000000000d2d2d2d0d2000000d2d2d2d0d2d2d2d0
fcf88fcffaf88fcffcf88faf0000000000000000000000000000000000000000000c0000533553350000000000000000d22d22d002202020d22d22d0d22d22d0
cf7ee7fccf7ee7faaf7ee7fc000000000000000000000000000000000000000000000000555555550000000000000000d22d22d00dd00220d22d22d0d22d22d0
e333333ee333333ee333333e000000000000000000000000000000000000000000000000535535550000000000000000d22d22d002000220d22d22d0d22d22d0
ee3cc3eeee3aa3eeee3aa3ee0000000000000000000000000000000000000000000000003335355500000000000000000d2d2d000d0d020d0d2d2d000d2d2d00
ccccccccacacacaccacacaca00000000000000000000000000000000000000000000000035353335000000000000000000ddd00000000d0000ddd00000ddd000
00ddd00000ddd00000ddd00000ddd000000000000000e000000e000000777700007777000077770000e7e7007777777700000000000000000000000000000000
0d222d000d222d000d222d000d222d000000000007777e700777e770072e227007e222700e222270072e22707666666700000000000000000000000000000000
d2d2d2d0d2d2d2d0d2d2d2d0d2d2d2d0000000007211e127721e1127e2e11127721e1127e711117007e1117e7766667700000000000000000000000000000000
d22d22d0d22d22d0d22d22d0d22d22d00000000072111e27721e1e277e11112772e111e70e111e700e1111707777777700000000000000000000000000000000
d22d22d0d22d22d0d22d22d0d22d22d000000000721e112772111e27721111277e111e2e0e11e1e007e11e7e7766667700000000000000000000000000000000
d22d22d0d22d22d0d22d22d0d22d22d00000000072e111277211e1277211e1eee2111e2707e1117e071e11e07666666700000000000000000000000000000000
0d2d2d000d2d2d000d2d2d000d2d2d0000000000077e77700777e770072e2e70072222e00e2222e007222e707766667700000000000000000000000000000000
00ddd00000ddd00000ddd00000ddd0000000000000e000000000e0000077e7000077770e00e7770e0077e7007777777700000000000000000000000000000000
00000766000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000766777766670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000007dc666666670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000007dc666666670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000007dc666666670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000007dc666666670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000766777766670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000766000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000007666670000000000000666666660000000000000000667000000000076666700000556666666666665500000766000000000000000000000000
55555555000007666670000000000000666666660000000000000000667000000000076666700000566666666666666500000766000000000000000000000000
55555555000007666670000000000000777777770000000000000000770000000000007766700000666777777777766600000766000000000000000000000000
55555555000007666670000000000000000000000000000000000000000000000000000066700000667000000000076600000766000000000000000000000000
55555555000007666670000000000000000000000000000000000000000000000000000066700000667000000000076600000766000000000000000000000000
55555555000007666670000077777777000000000000007777000000000000000000000066677777667000000000076677777666000000000000000000000000
55555555000007666670000066666666000000000000076666700000000000000000000056666666667000000000076666666665000000000000000000000000
55555555000007666670000066666666000000000000076666700000000000000000000055666666667000000000076666666655000000000000000000000000
55555555000000000555555555555550555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555050505055555555555555555055555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550555555555555550555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555555055555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550555555555555550555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555555055555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50505050555555550555555555555550555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555555555555555555555055555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0001010101010101010101010101010101010100000000002002020004040404040404040000000000000010000000001010100000000000000000000000000002000000000000000000000000000000020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
555555555555005555555555551a1a1a1a1a1a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5555555555550055555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5555555555555555555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4543434343434343465555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040425555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040494343434343434655555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040404255555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
41404040404040404a444b404040404255555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040421841404040404255555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4844444444444444471830404040404200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5555551818181818181841404040404200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
454343181843434318184c404040404200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140531818524053181852404040404200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4119531818524053181852404040404200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4844441818444444181844444444444700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
