function get_levels()
  return {
    {
      label="01",
      start_tile_x = 0, -- x index of the upper-left map tile to draw
      start_tile_y = 0, -- y index of the upper left map tile to draw
      map_offset_x = 0, -- use these values (in pixels) to offset the coordinates of entities and player
      map_offset_y = 0, -- ... relative to the starting offset coordinate?
      player_pos_x = ((1*8) + 0),
      player_pos_y = ((3*8) + 0),
      map_tile_width = 16,
      map_tile_height = 14,
      ents = {
        {type=ENT_BOX, pos_x= (8*8)+0, pos_y = (5*8)+0},
        {type=ENT_BOX, pos_x= (12*8)+0, pos_y = (10*8)+0},
        {type=ENT_ITEM, pos_x= (14*8)+0, pos_y = (10*8)+0},
        {type=ENT_BEAM, pos_x = (11*8)+0, pos_y = (8*8)+0},
      }
    },
    {
      label="02",
      start_tile_x = 18, -- x index of the upper-left map tile to draw
      start_tile_y = 0, -- y index of the upper left map tile to draw
      map_offset_x = 16, -- use these values (in pixels) to offset the coordinates of entities and player
      map_offset_y = 16,
      player_pos_x = ((1*8) + 16),
      player_pos_y = ((7*8) + 16),
      -- Map tile width / height is the total number of tiles to draw
      map_tile_width = 12,
      map_tile_height = 10,
      ents = {
        -- Assuming that (start_tile_x, start_tile_y) is the origin tile
        -- given the expression:
        -- (TILE_NUMBER*8) + MAP_OFFSET
        -- update TILE_NUMBER to be the starting tile for the entity
        {type=ENT_ITEM, pos_x= (5*8)+16, pos_y = (5*8)+16},
        {type=ENT_BOX, pos_x= (4*8)+16, pos_y = (5*8)+16},
        {type=ENT_BOX, pos_x= (6*8)+16, pos_y = (5*8)+16},
        {type=ENT_BOX, pos_x= (5*8)+16, pos_y = (4*8)+16},
        {type=ENT_BOX, pos_x= (5*8)+16, pos_y = (6*8)+16},
      }
    },
    {
      label="03",
      start_tile_x = 32, -- x index of the upper-left map tile to draw
      start_tile_y = 0, -- y index of the upper left map tile to draw
      map_offset_x = 16, -- use these values (in pixels) to offset the coordinates of entities and player
      map_offset_y = 16,
      player_pos_x = ((10*8) + 16),
      player_pos_y = ((6*8) + 16),
      -- Map tile width / height is the total number of tiles to draw
      map_tile_width = 13,
      map_tile_height = 14,
      ents = {
        -- Assuming that (start_tile_x, start_tile_y) is the origin tile
        -- given the expression:
        -- (TILE_NUMBER*8) + MAP_OFFSET
        -- update TILE_NUMBER to be the starting tile for the entity
        ent_at(ENT_BOX, 6, 5),
        ent_at(ENT_BOX, 6, 6),
        ent_at(ENT_BOX, 6, 7),
        ent_at(ENT_BEAM, 1, 4),
        ent_at(ENT_BOX, 2, 2),
        ent_at(ENT_ITEM, 3, 2),
      }
    },
    {
      label="04",
      start_tile_x = 46, -- x index of the upper-left map tile to draw
      start_tile_y = 0, -- y index of the upper left map tile to draw
      map_offset_x = 16, -- use these values (in pixels) to offset the coordinates of entities and player
      map_offset_y = 16,
      player_pos_x = ((2*8) + 16),
      player_pos_y = ((2*8) + 16),
      -- Map tile width / height is the total number of tiles to draw
      map_tile_width = 12,
      map_tile_height = 13,
      ents = {
        -- Assuming that (start_tile_x, start_tile_y) is the origin tile
        -- given the expression:
        -- (TILE_NUMBER*8) + MAP_OFFSET
        -- update TILE_NUMBER to be the starting tile for the entity
        ent_at(ENT_BOX, 9, 3),
        ent_at(ENT_BOX, 9, 4),
        ent_at(ENT_ITEM, 3, 9),
      }
    },
  }
end

function ent_at(ent_type, tile_x, tile_y)
  return {type=ent_type, pos_x=(tile_x*8)+16, pos_y=(tile_y*8)+16}
end
