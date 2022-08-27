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
  ]]
  return {
    --[[
    {
      label="00",
      start_tile_x = 29,
      start_tile_y = 16,
      player_pos_x = 2,
      player_pos_y = 1,
      map_tile_width = 9,
      map_tile_height = 6,
      ents = {
        ent_at(ENT_BEAM, 1, 3),
      }
    },
    ]]
    {
      label="01",
      start_tile_x = 0,
      start_tile_y = 0,
      player_pos_x = 2,
      player_pos_y = 4,
      map_tile_width = 15,
      map_tile_height = 12,
      ents = {
        ent_at(ENT_BOX, 6, 1),
        ent_at(ENT_BOX, 7, 2),
        ent_at(ENT_BOX, 8, 1),
        ent_at(ENT_GLOVE, 12, 4),
        ent_at(ENT_BOX, 6, 8),
        ent_at(ENT_BOX, 7, 8),
        ent_at(ENT_BOX, 8, 8),
        merge(ent_at(ENT_ITEM, 7, 10), {item_index=1}),
      }
    },
    {
      label="02",
      start_tile_x = 15,
      start_tile_y = 0,
      player_pos_x = 5,
      player_pos_y = 11,
      map_tile_width = 11,
      map_tile_height = 28,
      ents = {
        merge(ent_at(ENT_ITEM, 4, 1), {item_index=2}),
        ent_at(ENT_BOX, 3, 1),
        ent_at(ENT_BEAM, 1, 2),
        ent_at(ENT_BEAM, 1, 3),
        ent_at(ENT_BOX, 3, 14),
        ent_at(ENT_BOX, 4, 15),
        ent_at(ENT_BOX, 5, 15),
        ent_at(ENT_BOX, 6, 15),
        ent_at(ENT_BOX, 7, 14),
        ent_at(ENT_BEAM, 2, 18),
        ent_at(ENT_BOX, 4, 18),
        ent_at(ENT_BEAM, 2, 21),
        ent_at(ENT_BOX, 6, 21),
        ent_at(ENT_BEAM, 2, 24),
        ent_at(ENT_BOX, 6, 26),
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
      ents = {
        merge(ent_at(ENT_ITEM, 2, 8), {item_index=3}),
        ent_at(ENT_WH, 3, 4),
        ent_at(ENT_BOX, 12, 4),
        ent_at(ENT_BEAM, 8, 5),
      }
    },
    {
      label="04",
      start_tile_x = 59,
      start_tile_y = 0,
      player_pos_x = 8,
      player_pos_y = 9,
      map_tile_width = 17,
      map_tile_height = 13,
      ents = {
        merge(ent_at(ENT_ITEM, 13, 4), {item_index=4}),
        ent_at(ENT_BEAM, 12, 7),
        ent_at(ENT_BOX, 13, 1),
        ent_at(ENT_BEAM, 1, 1),
        ent_at(ENT_BEAM, 1, 8),
        ent_at(ENT_BOX, 1, 9),
      }
    },
    --[[
    {
      label="boxplayground",
      start_tile_x = 0, -- x index of the upper-left map tile to draw
      start_tile_y = 1, -- y index of the upper left map tile to draw
      player_pos_x = 1*8,
      player_pos_y = 3*8,
      map_tile_width = 16,
      map_tile_height = 14,
      ents = {
        ent_at(ENT_BOX, 2, 3),
        ent_at(ENT_BOX, 4, 3),
        ent_at(ENT_BOX, 6, 3),
        ent_at(ENT_BOX, 2, 5),
        ent_at(ENT_BOX, 4, 5),
        ent_at(ENT_BOX, 6, 5),
        ent_at(ENT_BOX, 2, 7),
        ent_at(ENT_BOX, 4, 7),
        ent_at(ENT_BOX, 6, 7),
      }
    },
    ]]
  }
end

function ent_at(ent_type, tile_x, tile_y)
  return {type=ent_type, pos_x=tile_x*8, pos_y=tile_y*8}
end
