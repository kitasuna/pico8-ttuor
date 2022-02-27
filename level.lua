function get_levels()
  return {
    {
      label="01",
      critical_mass=1,
      map_offset = { -- starting offset for map()
        pos_x = 16,
        pos_y = 16,
      },
      time=22<<8,
      player = {
        pos_x = 32,
        pos_y = 32,
      },
      ents = {
        {type=ENT_BOX, pos_x= 48, pos_y = 56},
        -- {type=ENT_ITEM, pos_x= 40, pos_y = 86},
      }
    },
  }
end
