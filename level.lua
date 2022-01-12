function get_levels()
  return {
    -- { label="01", fuels = {{pos_x = 32, pos_y = 32}}, obstacles = {{pos_x= 48, pos_y = 48}} }
    {
      label="01",
      time=12<<6,
      fuels = {
        {pos_x = 1, pos_y = 1},
        {pos_x = 1, pos_y = RESOLUTION_Y - 10},
        {pos_x = RESOLUTION_X - 8, pos_y = 1},
        {pos_x = RESOLUTION_X - 8, pos_y = RESOLUTION_Y - 10},
      },
      obstacles = {
        {pos_x= 10, pos_y = 1},
        {pos_x= 10, pos_y = 10},
        {pos_x= 1, pos_y = 10},
        {pos_x= RESOLUTION_X - 17, pos_y = 1},
        {pos_x= RESOLUTION_X - 17, pos_y = 10},
        {pos_x= RESOLUTION_X - 8, pos_y = 10},
        {pos_x= 1, pos_y = RESOLUTION_Y - 19},
        {pos_x= 10, pos_y = RESOLUTION_Y - 19},
        {pos_x= 10, pos_y = RESOLUTION_Y - 10},
        {pos_x= RESOLUTION_X - 17, pos_y = RESOLUTION_Y - 20},
        {pos_x= RESOLUTION_X - 17, pos_y = RESOLUTION_Y - 10},
        {pos_x= RESOLUTION_X - 8, pos_y = RESOLUTION_Y - 20},
      }
    }
  }
end
