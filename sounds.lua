sound_man = {
handle_entity_reaches_target = function()
  sfx(0)
end,
handle_player_death = function()
  sfx(3, -2)
end,
handle_beam_item_collision = function()
  sfx(5)
end,
}
function sfx_wormhole()
  sfx(6)
end
function xsfx_wormhole()
  sfx(6,-2)
end
function sfx_gbeam()
  sfx(2)
end
function xsfx_gbeam()
  sfx(2, -2)
end
function sfx_slide()
  sfx(1)
end
function xsfx_slide()
  sfx(1, -2)
end
function sfx_get_item()
  sfx(4)
end
function sfx_zapped()
  sfx(1,-2)
  sfx(3)
end
function xsfx_all()
  sfx(-1,1)
  sfx(-1,2)
  sfx(-1,3)
  sfx(-1,4)
end
