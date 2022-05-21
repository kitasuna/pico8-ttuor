function get_levels()
  return {
    {
      label="01",
      critical_mass=1,
      map_offset_x = 16,
      map_offset_y = 16,
      player_pos_x = ((1*8) + 16),
      player_pos_y = ((4*8) + 16),
      ents = {
        {type=ENT_BOX, pos_x= (8*8)+16, pos_y = (6*8)+15},
        {type=ENT_BOX, pos_x= (11*8)+16, pos_y = (11*8)+16},
        {type=ENT_ITEM, pos_x= (14*8)+16, pos_y = (11*8)+16},
        -- {type=ENT_ITEM, pos_x= 40, pos_y = 86},
        {type=ENT_BEAM, pos_x = (8*11)+16, pos_y = (9*8)+16},
      }
    },
  }
end
