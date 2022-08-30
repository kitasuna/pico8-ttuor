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
sound_man.handle_player_dead = function()
sfx(1, -2)
end
