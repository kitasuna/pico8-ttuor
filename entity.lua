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

  -- Check if there are any ents at these coordinates
  ent_man.check_collision = function(player)
    for k, e in pairs(ent_man.ents) do
      if collides(player, e) then
        return true
      end
    end
    return false
  end

  -- String -> {pos_x: Int, pos_y: Int, mass: Int }
  ent_man.handle_gravity = function(name, payload)

    -- Find any ents in range
    -- Calculate change in velocity based on distance of entity from payload pos
    for k, e in pairs(ent_man.ents) do
      local grav_result = calc_grav(
      {x=e.pos_x, y=e.pos_y},
      {x=payload.pos_x, y=payload.pos_y},
      {x=e.vel_x, y=e.vel_y},
      1.0,
      payload.mass
      )
      if grav_result.gdistance < 0.5 and fget(e.num, FLAG_ABSORBED_BY_GRAV) == false then
        e.vel_x = 0
        e.vel_y = 0
        e.pos_x = payload.pos_x
        e.pos_y = payload.pos_y
        return
      end

      if grav_result.gdistance < 22*payload.mass then
        e.vel_x = grav_result.vel.x
        e.vel_y = grav_result.vel.y
      end
    end
  end

  ent_man.handle_ent_grav_collision = function(name, payload)
    if fget(payload.entity.num, FLAG_ABSORBED_BY_GRAV) == true then
      del(ent_man.ents, payload.entity)
    end
  end

  -- String -> { box: Box, beam: Beam }
  ent_man.handle_beam_box_collision = function(name, payload)
    payload.beam.blocked_by = payload.box
  end

  return ent_man
end

function new_item(coords)
  local tmp = new_sprite(32, coords.pos_x, coords.pos_y, 8, 6)

  tmp.vel_x = 0
  tmp.vel_y = 0
  tmp.can_travel = 1 << FLAG_FLOOR

  tmp.update = ent_update(tmp)
  tmp.draw = ent_draw(tmp)
  return tmp
end

function new_box(coords)
  local tmp = new_sprite(33, coords.pos_x, coords.pos_y, 8, 8)

  tmp.vel_x = 0
  tmp.vel_y = 0
  tmp.type = ENT_BOX
  tmp.can_travel = 1 << FLAG_FLOOR

  tmp.update = ent_update(tmp)
  tmp.draw = ent_draw(tmp)
  return tmp
end

function new_beam(coords)
  -- Start size at 8x8
  local tmp = new_sprite(50, coords.pos_x, coords.pos_y, 8, 8)
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
        printh("collided!")
        beam.size_x = beam.blocked_by.pos_x - beam.pos_x
        return
      else
        beam.blocked_by = nil
        printh("UNSET BLOCKED_BY!")
      end
    end

    local collision = false
    local map_offset_x = 16
    local map_offset_y = 16
    local curr_map_x = (beam.pos_x - map_offset_x) \ 8
    local curr_map_y = (beam.pos_y - map_offset_y) \ 8
    local beam_max_x = beam.pos_x
    while collision == false do
      local next_map_x = ((beam_max_x + 1) - map_offset_x) \ 8
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
    for i=1,beam.size_x do
      spr(beam.num, beam.pos_x + (i - 1), beam.pos_y)
    end
  end
end

function ent_draw(ent)
  return function()
    spr(ent.num, ent.pos_x, ent.pos_y)
  end
end

function ent_update(tmp)
  return function()
    local map_offset_x = 16
    local map_offset_y = 16
    local next_x = (tmp.pos_x + tmp.vel_x - map_offset_x) + (tmp.vel_x > 0 and 7 or 0)
    local next_y = (tmp.pos_y + tmp.vel_y - map_offset_y) + (tmp.vel_y > 0 and 7 or 0)
    local now_map_x = (tmp.pos_x - map_offset_x) \ 8
    local now_map_y = (tmp.pos_y - map_offset_y) \ 8
    local next_map_x = (next_x) \ 8
    local next_map_y = (next_y) \ 8

    local next_map_tile_x = mget(next_map_x, now_map_y)
    if fget(next_map_tile_x) & tmp.can_travel == 0 then
      tmp.vel_x = 0
      if tmp.vel_y != 0 then
        tmp.vel_y = tmp.vel_y / 3
        add(timers, {
          ttl = 40,
          f = function() end,
          cleanup = function()
            tmp.vel_y = 0
          end
        })
        end
    else
      tmp.pos_x += tmp.vel_x
    end

    local next_map_tile_y = mget(now_map_x, next_map_y)
    if fget(next_map_tile_y) & tmp.can_travel == 0 then
      tmp.vel_y = 0
      if tmp.vel_x != 0 then
        tmp.vel_x = tmp.vel_x / 3
        add(timers, {
          ttl = 40,
          f = function() end,
          cleanup = function()
            tmp.vel_x = 0
          end
        })
      end
    else
      tmp.pos_y += tmp.vel_y
    end
  end
end
