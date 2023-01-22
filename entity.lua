item_particles = flsrc(0, 0, 0.05, {CLR_DGN, CLR_GRN, CLR_GRN})
sec_item_particles = flsrc(0, 0, 0, {CLR_PNK, CLR_PNK, CLR_PRP})
function new_entity_manager()
  local ent_man = {
    ents = {},
  }

  ent_man.collision = function()
    for ent in all(ent_man.ents) do
      for ent_inner in all(ent_man.ents) do
        if ent.type == ENT_ITEM and ent_inner.type == ENT_BEAM and ent.state != ENT_STATE_BROKEN and collides(ent, ent_inner) then
          qm.add_event("beam_item_collision", ent)
        end
      end
    end
  end

  ent_man.handle_beam_item_collision = function(item)
    if item.state == ENT_STATE_NORMAL then
      item.state = ENT_STATE_BROKEN
      item.feels_grav = false
      item.vel_x,item.vel_y = 0,0
      sfx(5)
      add(timers, {120, function()
        del(ent_man.ents, item)
      end
    })
    local p = nil
    if item.item_index == #player_items then
      p = sec_item_particles
    else
      p = item_particles
    end
    p.pos_x = item.pos_x + 4
    p.pos_y = item.pos_y + 4
    for i=0,40 do
      p.add(4, 4, true, true, 30) 
    end
  end

end

  -- {type, pos_x, pos_y, sprite_num}
  ent_add_powerup = function(info)
    local tmp = new_sprite(info[4], info[2], info[3], 8, 6)

    tmp.vel_x,tmp.vel_y = 0,0
    tmp.type = info[1]
    tmp.can_travel = 1 << FLAG_FLOOR
    tmp.state = nil

    tmp.update = ent_update(tmp)
    tmp.draw = function()
      palt(0, false)
      palt(15, true)
      ent_draw(tmp)
      pal()
    end
    add(ent_man.ents, tmp)
  end

  ent_man.add_box = function(info)
    local tmp = new_sprite(43, info[2], info[3], 8, 8)

    tmp.vel_x,tmp.vel_y = 0,0
    tmp.type = ENT_BOX
    tmp.can_travel = 1 << FLAG_FLOOR
    tmp.state = ENT_STATE_NORMAL
    tmp.frames = { NORMAL={frames={43}} }
    tmp.frame_offset = 1
    tmp.feels_grav = true
    tmp.future_x,tmp.future_y = 0,0

    tmp.update = ent_update(tmp)
    tmp.draw = function()
      palt(0, false)
      palt(10, true)
      if tmp.vel_x != 0 or tmp.vel_y != 0 then
        pal(0, GRAV_COLORS[frame_counter % 3])
      end
      if tmp.state == ENT_STATE_HELD then
        spr(44, tmp.pos_x - 4, tmp.pos_y - 8)  
        if frame_counter % 10 < 5 then
          pal(7, 0)
          pal(0, 7)
          spr(45, tmp.future_x, tmp.future_y)
          pal()
        else
          spr(45, tmp.future_x, tmp.future_y)
        end
        palt()
        return
      end
      ent_draw(tmp)
      pal()
    end
    add(ent_man.ents, tmp)
  end

  ent_man.add_beam = function(info, max_y)
    local tmp = new_sprite(50, info[2], info[3], 8, 6)
    tmp.min_y = tmp.pos_y
    tmp.vel_x,tmp.vel_y = 0,0
    if max_y != nil then
      tmp.max_y = max_y
      tmp.vel_y = 0.3
    else
      tmp.max_y = tmp.pos_y
    end
    tmp.type = ENT_BEAM
    tmp.blocked_by = nil
    tmp.can_travel = 1 << FLAG_FLOOR | 1 << FLAG_GAP
    tmp.sprites0 = {}
    tmp.sprites1 = {}

    tmp.update = beam_update(tmp)
    tmp.draw = beam_draw(tmp)
    add(ent_man.ents, tmp)
  end

  ent_man.reset = function()
    ent_man.ents = {}
  end

  ent_man.handle_entity_reaches_target = function(payload)
    -- unblock any blocked beams
    if payload.ent.type != ENT_BOX then
      return
    end
    for ent in all(ent_man.ents) do
      if ent.type == ENT_BEAM and ent.blocked_by == payload.ent then
        ent.blocked_by = nil
        return
      end
    end
  end

  ent_man.handle_player_item_collision = function(payload)
      payload.state = ENT_STATE_HELD
      local p = nil
      if payload.item_index == #player_items then
        p = sec_item_particles
      elseif payload.item_index != nil then
        p = item_particles
      end
      if p != nil then
        p.pos_x = payload.pos_x
        p.pos_y = payload.pos_y + 4
        p.direction = DIRECTION_UP
        for i=0,20 do
          p.addDir(2, 2, 30) 
        end
      end
      del(ent_man.ents, payload)
  end

  ent_man.handle_gbeam_removed = function(payload)
    for ent in all(ent_man.ents) do
      if ent.tgt_x != nil or ent.tgt_y != nil then
        ent.vel_x,ent.vel_y = 0,0
        ent.tgt_x,ent.tgt_y = nil,nil
      end
    end
  end

  ent_man.handle_button = function(payload)
    for ent in all(ent_man.ents) do
      if ent.state == ENT_STATE_HELD then
        if not is_pressed_o(payload.input_mask) then
          -- unhand that item!
          ent.state = ENT_STATE_NORMAL
          ent.pos_x,ent.pos_y = ent.future_x,ent.future_y
        end
      end
    end
  end

  -- String -> { rotation: Rotation, pos_x: Int, pos_y Int }
  ent_man.handle_player_rotation = function(payload)
    for ent in all(ent_man.ents) do
      if ent.state == ENT_STATE_HELD then
        ent.future_x,ent.future_y = payload.pos_x,payload.pos_y
        --ent.future_y = payload.pos_y
        -- we only need to do this for one ent, so return
        return
      end
    end
  end

  return ent_man
end

-- Entity -> XPos -> YPos -> Direction -> Entity
function do_gravity(ent, pos_x, pos_y, direction)
  local ent_vel = 1
  ent.tgt_x,ent.tgt_y = pos_x, pos_y
  ent.vel_x, ent.vel_y = (function()
    if direction == DIRECTION_UP then
      -- vel should be downwards
      return 0, ent_vel
    elseif direction == DIRECTION_DOWN then
      -- vel should be upwards
      return 0, -ent_vel
    elseif direction == DIRECTION_RIGHT then
      --vel should be to the left
      return -ent_vel, 0
    elseif direction == DIRECTION_LEFT then
      --vel should be to the right
      return ent_vel, 0
    end
  end)()
end

-- {pos_x: Int, pos_y: Int, item_index: Int}
function ent_add_item(info)
  local tmp = {
    vel_x = 0,
    vel_y = 0,
    item_index = info[4],
    type = ENT_ITEM,
    can_travel = 1 << FLAG_FLOOR | 1 << FLAG_GAP,
    state = ENT_STATE_NORMAL,
    frame_step = 0,
    frame_offset = 1,
    feels_grav = true,
  }
  tmp = merge(tmp, new_sprite(28, info[2], info[3], 8, 8)) 

  tmp.update = function(level)
    ent_update(tmp)(level)
  end
  tmp.draw = function()
    if tmp.state == ENT_STATE_NORMAL then
      palt(0, false)
      palt(15, true)
      if tmp.item_index == #player_items then
        pal(3, 2)
        pal(11, 14)
      end
      if tmp.vel_x != 0 or tmp.vel_y != 0 then
        pal(0, GRAV_COLORS[frame_counter % 3])
      end
      local pos_offsets = {0, 1, 1, 1, 0, -1, -1, -1}
      tmp.frame_step = (tmp.frame_step + 1) % 10
      if tmp.frame_step == 0 then
        tmp.frame_offset = (tmp.frame_offset + 1) % #pos_offsets
      end
      local y_offset = pos_offsets[tmp.frame_offset + 1]
      spr(tmp.num, tmp.pos_x, tmp.pos_y + y_offset)  
      pal()
    end
  end

  add(ent_man.ents, tmp)
  return tmp
end

function beam_update(beam)
  return function(level)
    -- This bit controls the beam moving back and forth
    if beam.vel_y != 0 then
      beam.pos_y += beam.vel_y
      if beam.pos_y > beam.max_y or beam.pos_y < beam.min_y then
        beam.vel_y = - beam.vel_y
      end
    end
    beam.size_x = 128
    local curr_map_x, curr_map_y = get_tile_from_pos(beam.pos_x, beam.pos_y + 3)
    local beam_max_x = beam.pos_x
    while true do
      local next_map_x, next_map_y = get_tile_from_pos(beam_max_x, beam.pos_y + 3)
      if fmget(next_map_x, curr_map_y) & beam.can_travel == 0 then
        break;
      end

      beam_max_x += 8
    end
    beam.size_x = beam_max_x - beam.pos_x

    for ent_other in all(ent_man.ents) do
      -- Try cheating size here to make boxes more protective
      if ent_other.type == ENT_BOX and ent_other.state != ENT_STATE_HELD and collides(beam, ent_other) then
        beam.blocked_by = ent_other
        -- Duplicating this next line to allow for boxes to 
        -- block beams on level load
        beam.size_x = ent_other.pos_x - beam.pos_x + 1
        break
      end
    end

    if beam.blocked_by != nil then
      if not collides(beam.blocked_by, beam) then
        beam.blocked_by = nil
      else
        return
      end
    end
  end
end

function beam_draw(beam)
  return function()
    
    palt(0, false)
    palt(15, true)
    spr(48, beam.pos_x-8, beam.pos_y)
    local length = beam.size_x
    if length <= 0 then
      -- don't bother drawing anything here
      return
    end

    if frame_counter % 3 == 0 then
      -- Reset length of state tables
      beam.sprites0 = {}
      beam.sprites1 = {}

      -- Handle all full 8-pixel blocks
      for i=1,length \ 8 do
        beam.sprites0[i] = 104 + flr(rnd(4))
        beam.sprites1[i] = 108 + flr(rnd(4))
      end

      -- Add one more if length is not a multiple of 8
      if length % 8 > 0 then
        beam.sprites0[#beam.sprites0 + 1] = 104 + flr(rnd(4))
        beam.sprites1[#beam.sprites1 + 1] = 108 + flr(rnd(4))
      end
    end

    local y_offset = beam.pos_y + 2
      -- Draw all full 8-pixel blocks, except the last one
      for i=1,#beam.sprites0 - 1 do
        spr(beam.sprites1[i],beam.pos_x + i*8-8,beam.pos_y) -- White beam
        spr(beam.sprites0[i],beam.pos_x + i*8-8,beam.pos_y) -- Blue beam
      end

      local overflow = length % 8
      if overflow == 0 then
        -- No overflow, draw last sprite normally
        spr(beam.sprites1[#beam.sprites1],beam.pos_x + length-8,beam.pos_y) -- White beam
        spr(beam.sprites0[#beam.sprites0],beam.pos_x + length-8,beam.pos_y) -- Blue beam
      else
        -- Some overflow, draw partial sprite
        spr(beam.sprites1[#beam.sprites1], beam.pos_x + length-overflow, beam.pos_y, overflow/8, 1.0) -- White beam
        spr(beam.sprites0[#beam.sprites0], beam.pos_x + length-overflow, beam.pos_y, overflow/8, 1.0) -- Blue beam
      end
    pal()
    end
  end

function ent_draw(ent)
  if ent.state != nil then
    if ent.frames[ent.state] != nil then
      spr(ent.frames[ent.state].frames[ent.frame_offset], ent.pos_x, ent.pos_y)  
    else
      spr(ent.sprite_num, ent.pos_x, ent.pos_y)  
    end
  end

  spr(ent.num, ent.pos_x, ent.pos_y)
end


function ent_update(tmp)
  return function(level)
    local ent_center_x, ent_center_y = get_center(tmp)
    local ent_next_x = ent_center_x + tmp.vel_x
    local ent_next_y = ent_center_y + tmp.vel_y
    local curr_map_x, curr_map_y = get_tile_from_pos(ent_center_x, ent_center_y)
    local next_map_x, next_map_y = get_tile_from_pos(ent_next_x, ent_next_y)

    if fmget(next_map_x, curr_map_y) & tmp.can_travel == 0 then
      tmp.vel_x = 0
    else
      tmp.pos_x += tmp.vel_x
    end

    if fmget(curr_map_x, next_map_y) & tmp.can_travel == 0 then
      tmp.vel_y = 0
    else
      tmp.pos_y += tmp.vel_y
    end

    -- stop if we've reached the target
    if tmp.tgt_x != nil and tmp.tgt_y != nil then
      local ginfo = ldistance(tmp.pos_x + 4, tmp.pos_y + 4, tmp.tgt_x, tmp.tgt_y)
      if ginfo.d < 8.1 then
        -- Center on the target
        tmp.vel_x, tmp.vel_y = 0,0
        if tmp.type == ENT_BOX then
          tmp.state = ENT_STATE_HELD
        end
        tmp.future_x,tmp.future_y = tmp.pos_x,tmp.pos_y
        tmp.pos_x,tmp.pos_y = tmp.tgt_x,tmp.tgt_y
        tmp.tgt_x, tmp.tgt_y = nil,nil
        qm.add_event("entity_reaches_target", {ent=tmp})
      end
    end
  end
end
