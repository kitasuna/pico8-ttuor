function get_levels()
  return {
    {
      label="01",
      critical_mass=1,
      time=22<<8,
      fuels = {},
      player = {
        pos_x = 32,
        pos_y = 32,
      },
      obstacles = {
        {pos_x= 32, pos_y = 28},
        {pos_x= 32, pos_y = 85},
      }
    },
  }
end
