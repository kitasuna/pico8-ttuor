function qico()
  local q = {} -- msg queue
  local t = {} -- topics and subscriptions

  function split_events(events)
    local tbl = {}
    local tmp = "" -- for accumulating chars
    for i=1,#events do
      if events[i] != "|" then
        tmp = tmp..events[i]
      else
        tbl[tmp] = {}
        tmp = "" 
      end
    end
    -- account for the last element
    if tmp != "" then
      tbl[tmp] = {}
    end
    return tbl
  end

  function add_topics(events)
    t = split_events(events)
  end

  function add_event(name, payload)
    add(q, { name=name, payload=payload })
  end

  function add_sub(event, fn)
    add(t[event], fn)
  end

  function add_subs(event, fns)
    for i=1,#fns do
      add(t[event], fns[i])
    end
  end

  function proc()
    for k,v in pairs(q) do
      if t[v.name] != nil then
        for ik,iv in pairs(t[v.name]) do
          iv(v.payload)
        end
      end
    end
    q = {}
  end

  return {
    add_event = add_event,
    add_topics = add_topics,
    add_sub = add_sub,
    add_subs = add_subs,
    proc = proc,
    q = q,
    t = t
  }
end
