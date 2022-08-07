function new_entity_manager()
  local ent_man = {
    ents = {},
  }

  ent_man.add_item = function(coords)
    local tmp = new_item(coords)
    add(ent_man.ents, tmp)
  end

  ent_man.add_box = function(coords)
    local tmp = new_box(coords)
    add(ent_man.ents, tmp)
  end

  ent_man.add_beam = function(coords)
    local tmp = new_beam(coords)
    add(ent_man.ents, tmp)
  end

  ent_man.reset = function()
    ent_man.ents = {}
  end

  ent_man.handle_player_item_collision = function(payload)
      del(ent_man.ents, payload.entity)
  end

  ent_man.handle_level_init = function(payload)
  end

  -- String -> { box: Box, beam: Beam }
  ent_man.handle_beam_box_collision = function(payload)
    payload.beam.blocked_by = payload.box
  end

  -- String -> { item: Item, beam: Beam }
  ent_man.handle_beam_item_collision = function(payload)
    payload.item.state = ENT_STATE_BROKEN
    payload.item.feels_grav = false
    payload.item.vel_x = 0
    payload.item.vel_y = 0
    add(timers, {
      ttl = 120,
      f = function() end,
      cleanup = function()
        del(ent_man.ents, payload.item)
      end
    })
  end

  ent_man.handle_gbeam_removed = function(payload)
    for k, ent in pairs(ent_man.ents) do
      if ent.tgt_x != nil or ent.tgt_y != nil then
        ent.vel_x = 0
        ent.vel_y = 0
        ent.tgt_x = nil
        ent.tgt_y = nil
      end
    end
  end

  ent_man.handle_button = function(payload)
    for k, ent in pairs(ent_man.ents) do
      if ent.state == ENT_STATE_HELD then
        if (payload.input_mask & (1 << BTN_O)) == 0 then
          -- unhand that item!
          ent.state = ENT_STATE_NORMAL
          ent.pos_x = ent.future_x
          ent.pos_y = ent.future_y
        end
      end
    end
  end

  ent_man.handle_player_holds = function(payload)
    for k, ent in pairs(ent_man.ents) do
      if ent.state == ENT_STATE_HELD then
        ent.pos_x = payload.x
        ent.pos_y = payload.y
        break
      end
    end
  end

  -- String -> { rotation: Rotation, pos_x: Int, pos_y Int }
  ent_man.handle_player_rotation = function(payload)
    for k, ent in pairs(ent_man.ents) do
      if ent.state == ENT_STATE_HELD then
        ent.future_x = payload.pos_x
        ent.future_y = payload.pos_y
        -- we only need to do this for one ent, so return
        return
      end
    end
  end

  return ent_man
end

-- Entity -> XPos -> YPos -> Direction -> Entity
function do_gravity(ent, pos_x, pos_y, direction)
  if ent.feels_grav == true then
    local ent_vel = 1
    if direction == DIRECTION_UP then
      -- vel should be downwards
      ent.vel_x = 0
      ent.vel_y = ent_vel
      ent.tgt_x = ent.pos_x
      ent.tgt_y = pos_y
      elseif direction == DIRECTION_DOWN then
      -- vel should be upwards
      ent.vel_x = 0
      ent.vel_y = -ent_vel
      ent.tgt_x = ent.pos_x
      ent.tgt_y = pos_y
      elseif direction == DIRECTION_RIGHT then
        --vel should be to the left
      ent.vel_x = -ent_vel
      ent.vel_y = 0
      ent.tgt_x = pos_x
      ent.tgt_y = ent.pos_y
      elseif direction == DIRECTION_LEFT then
      --vel should be to the right
      ent.vel_x = ent_vel
      ent.vel_y = 0
      ent.tgt_x = pos_x
      ent.tgt_y = ent.pos_y
    end
  end

  return ent
end

function new_item(coords)
  local tmp = new_sprite(32, coords.pos_x, coords.pos_y, 8, 6)

  tmp.vel_x = 0
  tmp.vel_y = 0
  tmp.type = ENT_ITEM
  tmp.can_travel = 1 << FLAG_FLOOR
  tmp.state = ENT_STATE_NORMAL
  tmp.frames = { NORMAL={frames={28}, len=20}, BROKEN={frames={29}, len=20}, HELD={frames={28}, len=10} }
  tmp.frame_half_step = 0
  tmp.frame_offset = 1
  tmp.feels_grav = true

  tmp.update = ent_update(tmp)
  tmp.draw = ent_draw(tmp)
  return tmp
end

function new_box(coords)
  local tmp = new_sprite(43, coords.pos_x, coords.pos_y, 8, 8)

  tmp.vel_x = 0
  tmp.vel_y = 0
  tmp.type = ENT_BOX
  tmp.can_travel = 1 << FLAG_FLOOR
  tmp.state = ENT_STATE_NORMAL
  tmp.frames = { NORMAL={frames={43},len=10}, HELD={frames={43},len=10} }
  tmp.frame_half_step = 0
  tmp.frame_offset = 1
  tmp.feels_grav = true
  tmp.future_x = 0
  tmp.future_y = 0

  tmp.update = ent_update(tmp)
  tmp.draw = function()
    if tmp.state == ENT_STATE_HELD then
      spr(44, tmp.pos_x, tmp.pos_y-5)  
      return
    end
    ent_draw(tmp)()
  end
  return tmp
end

function new_beam(coords)
  -- Start size at 8x8
  local tmp = new_sprite(50, coords.pos_x, coords.pos_y, 8, 6)
  tmp.vel_x = 0
  tmp.vel_y = 0
  tmp.type = ENT_BEAM
  tmp.blocked_by = nil
  tmp.can_travel = 1 << FLAG_FLOOR -- maybe need to add gaps here later

  tmp.update = beam_update(tmp)
  tmp.draw = beam_draw(tmp)
  return tmp
end

function beam_update(beam)
  return function()
    -- Check for horizonal, increasing case
    -- Maybe add a "facing" prop to this later
    if beam.blocked_by != nil then
      -- Update blocked_by if necessary
      beam.size_x = 128
      if collides(beam.blocked_by, beam) == true then
        beam.size_x = beam.blocked_by.pos_x - beam.pos_x
        return
      else
        beam.blocked_by = nil
      end
    end
    local collision = false
    local curr_map_x = (beam.pos_x \ 8) + level.start_tile_x
    local curr_map_y = (beam.pos_y \ 8) + level.start_tile_y
    local beam_max_x = beam.pos_x
    while collision == false do
      local next_map_x = ((beam_max_x + 1) \ 8) + level.start_tile_x
      local flag = fget(mget(next_map_x, curr_map_y))
      if (fget(mget(next_map_x, curr_map_y)) & beam.can_travel) == 0 then
        collision = true
        break;
      end

      beam_max_x += 8
    end
    beam.size_x = beam_max_x - beam.pos_x
  end
end

function beam_draw(beam)
  return function()
    if frame_counter % 4 == 1 then
      return
    end
    local y_offset = beam.pos_y + 2
    local x_max = beam.pos_x + beam.size_x - 1
    for i=1,beam.size_x do
      line(beam.pos_x, y_offset, x_max, y_offset, CLR_BLU)
      line(beam.pos_x, y_offset + 1, x_max, y_offset + 1)
      line(beam.pos_x, y_offset + 2, x_max, y_offset + 2)
      line(beam.pos_x, y_offset + 3, x_max, y_offset + 3)
    end
  end
end

function ent_draw(ent)
  if ent.state != nil then
    return function()
      spr(ent.frames[ent.state].frames[ent.frame_offset], ent.pos_x, ent.pos_y)  
    end
  end
  return function()
    spr(ent.num, ent.pos_x, ent.pos_y)
  end
end

function ent_update(tmp)
  return function(level)
    local ent_center_x = get_center_x(tmp)
    local ent_center_y = get_center_y(tmp)
    local ent_next_x = (ent_center_x + tmp.vel_x)--  + (tmp.vel_x > 0 and 7 or 0)
    local ent_next_y = (ent_center_y + tmp.vel_y)--  + (tmp.vel_y > 0 and 7 or 0)
    local curr_map_x = (ent_center_x \ 8) + level.start_tile_x
    local next_map_x = (ent_next_x \ 8) + level.start_tile_x
    local curr_map_y = (ent_center_y \ 8) + level.start_tile_y
    local next_map_y = (ent_next_y \ 8) + level.start_tile_y

    local next_map_tile_x = mget(next_map_x, curr_map_y)
    if fget(next_map_tile_x) & tmp.can_travel == 0 then
      tmp.vel_x = 0
    else
      tmp.pos_x += tmp.vel_x
    end

    local next_map_tile_y = mget(curr_map_x, next_map_y)
    if fget(next_map_tile_y) & tmp.can_travel == 0 then
      tmp.vel_y = 0
    else
      tmp.pos_y += tmp.vel_y
    end

    -- stop if we've reached the target
    if tmp.tgt_x != nil and tmp.tgt_y != nil then
      local ginfo = ldistance(tmp.pos_x + 4, tmp.pos_y + 4, tmp.tgt_x, tmp.tgt_y)
      if ginfo.d < 5 then
        -- Center on the target
        tmp.vel_x = 0
        tmp.vel_y = 0
        tmp.tgt_x = nil
        tmp.tgt_y = nil
        tmp.state = ENT_STATE_HELD
        tmp.future_x = tmp.pos_x
        tmp.future_y = tmp.pos_y
        qm.ae("ENTITY_REACHES_TARGET", {ent=tmp})
      end
    end
  end
end
