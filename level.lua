function get_levels()
  --[[
  Level Template:
    {
      label="01",
      start_tile_x = 0, -- x index of the upper-left map tile to draw
      start_tile_y = 19, -- y index of the upper left map tile to draw
      player_pos_x = 2*8,
      player_pos_y = 4*8,
      -- Map tile width / height is the total number of tiles to draw
      map_tile_width = 15,
      map_tile_height = 9,
      ents = { -- x/y tile indexes, from the starting tile, at which to place the entity
        ent_at(ENT_BOX, 6, 2),
        ent_at(ENT_BOX, 7, 3),
        ent_at(ENT_BOX, 8, 2),
      }
    },
  --]]
  return {
    --[[
    {
      label="00",
      start_tile_x = 114, -- x index of the upper-left map tile to draw
      start_tile_y = 35, -- y index of the upper left map tile to draw
      player_pos_x = 2,
      player_pos_y = 4,
      -- Map tile width / height is the total number of tiles to draw
      map_tile_width = 15,
      map_tile_height = 15,
      boxes = "0303:0403:0503",
      beams = "",
      mbeams = "",
      ents = { -- x/y tile indexes, from the starting tile, at which to place the entity
      }
    },
    -]]
    {
      label="01",
      start_tile_x = 0,
      start_tile_y = 0,
      player_pos_x = 2,
      player_pos_y = 4,
      map_tile_width = 17,
      map_tile_height = 13,
      boxes = "0103:0203:0303:0403:0503:1303:1403:1503",
      beams = "",
      mbeams="0707/11",
      -- mbeams="",
      ents = {
        {ENT_GLOVE, 112, 48},
        {ENT_ITEM, 24, 8, 1}
      }
    },
    {
      label="02",
      start_tile_x = 29,
      start_tile_y = 0,
      player_pos_x = 5,
      player_pos_y = 10,
      map_tile_width = 11,
      map_tile_height = 29,
      boxes = "0313:0414:0514:0614:0713:0518:0621:0724",
      beams = "0217:0220:0223",
      mbeams = "0101/06",
      ents = {
        {ENT_ITEM, 40, 48, 2}
      }
    },
    {
      label="03",
      start_tile_x = 41,
      start_tile_y = 0,
      player_pos_x = 3,
      player_pos_y = 1,
      map_tile_width = 15,
      map_tile_height = 13,
      boxes = "1001",
      beams = "0805",
      mbeams="",
      ents = {
        {ENT_ITEM, 16, 64, 3},
        ent_at(ENT_WH, 3, 4),
      }
    },
    {
      label="04",
      start_tile_x = 58,
      start_tile_y = 0,
      player_pos_x = 9,
      player_pos_y = 11,
      map_tile_width = 17,
      map_tile_height = 15,
      boxes = "1304:0109",
      beams = "1308:0201:0108",
      mbeams="",
      ents = { 
        {ENT_ITEM, 104, 16, 4}
      }
    },
    {
      label="05",
      start_tile_x = 17,
      start_tile_y = 0,
      player_pos_x = 9,
      player_pos_y = 1,
      map_tile_width = 11,
      map_tile_height = 22,
      boxes = "0401:0402:0403:0409:0410:0411:0915",
      beams = "0102",
      mbeams = "0107/12:0113/17",
      ents = {
        {ENT_ITEM, 40, 16, 5},
        {ENT_ITEM, 16, 152, 6}
      }
    },
    {
      label="06",
      start_tile_x = 0,
      start_tile_y = 29,
      player_pos_x = 8,
      player_pos_y = 5,
      map_tile_width = 14,
      map_tile_height = 26,
      beams = "",
      mbeams = "0202/20",
      boxes = "",
      ents = {
        {ENT_ITEM, 87, 140, 7}
      }
    },
    {
      label="07",
      start_tile_x = 76,
      start_tile_y = 0,
      player_pos_x = 1,
      player_pos_y = 11,
      map_tile_width = 11,
      map_tile_height = 12,
      boxes = "",
      beams = "",
      mbeams = "",
      ents = {
        {ENT_ITEM, 48, 32, 8}
      }
    },
  }
end

function ent_at(ent_type, tile_x, tile_y)
  return {ent_type, tile_x*8, tile_y*8}
end

function init_level(l)
  player.reset(l)
  ent_man.reset()
  item_particles.reset()
  sec_item_particles.reset()

  camera_x = -64 + player.pos_x
  camera_y = -64 + player.pos_y
  local i=1
  while i<#l.boxes do
    ent_man.add_box(ent_at(ENT_BOX,sub(l.boxes,i,i+1),sub(l.boxes,i+2,i+3)))
    i += 5 -- 5 because we want to skip over the separator
  end
  local i=1
  while i<#l.beams do
    ent_man.add_beam(ent_at(ENT_BEAM,sub(l.beams,i,i+1),sub(l.beams,i+2,i+3)))
    i += 5 -- 5 because we want to skip over the separator
  end
  local i=1
  while i<#l.mbeams do
    ent_man.add_beam(
      ent_at(
        ENT_BEAM,
        sub(l.mbeams,i,i+1),
        sub(l.mbeams,i+2,i+3)
      ),
      sub(l.mbeams,i+5,i+6) * 8
      )
    i += 8 -- skip over this chunk + separator
  end
  -- check player's inventory
  local last_item = nil
  for k, e in pairs(l.ents) do
    if e[1]==ENT_ITEM then
      if e[4] < #player_items or (e[4] == #player_items and player.gems_count == #player_items - 1 and timer_minutes < 2) then
        last_item = ent_add_item(e)
        if e[4] == #player_items then
          add(timers, {
            180, function()
              qm.add_event("beam_item_collision", last_item)
            end
          })
        end
      end
    elseif e[1]==ENT_GLOVE then
      add(e, 38)
      ent_add_powerup(e)
    elseif e[1]==ENT_WH then
      add(e, 40)
      ent_add_powerup(e)
    else
      printh("unknown type")
    end
  end

  qm.add_event"level_init"
  -- reset timers
  -- timers = {}
end
