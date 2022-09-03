sound_man = {}
sound_man.handle_entity_reaches_target = function()
  sfx(0)
end
sound_man.handle_gbeam_added = function()
  sfx(2)
end
sound_man.handle_gbeam_removed = function()
  sfx(2, -2)
end
sound_man.handle_player_state_sliding = function()
  sfx(1)
end
sound_man.handle_player_state_grounded = function()
  sfx(1, -2)
end
sound_man.handle_player_state_zapped = function()
  sfx(1,-2)
  sfx(3)
end
sound_man.handle_player_state_falling = function()
  sfx(1, -2)
end
sound_man.handle_player_death = function()
  sfx(3, -2)
end
sound_man.handle_player_item_collision = function()
  sfx(4)
end
sound_man.handle_beam_item_collision = function()
  sfx(5)
end
sound_man.handle_wormhole_added = function()
  sfx(6)
end
sound_man.handle_wormhole_removed = function()
  sfx(6,-2)
end
