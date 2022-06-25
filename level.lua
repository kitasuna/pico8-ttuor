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
      player_pos_y = ((3*8) + 16),
      map_tile_width = 5,
      map_tile_height = 10,
      ents = {
        {type=ENT_BOX, pos_x= (8*8)+16, pos_y = (5*8)+16},
      }
    },
  }
end
