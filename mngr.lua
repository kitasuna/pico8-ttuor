function new_manager()
  local manager = {
    score = 0,
  }

  manager.handle_fuel_collision = function(event_name, event_payload)
    manager.score += 1
  end

  manager.handle_obs_collision = function(event_name, event_payload)
    -- manager.score += 1
  end

  return manager
end
