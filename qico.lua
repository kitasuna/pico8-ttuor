function qico()
  local q = {} -- msg queue, just strings for now
  local t = {} -- topics

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

  function set_subs(event, fns)
    t[event] = fns
  end

  function process_queue()
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
    ae = add_event,
    at = add_topic,
    ats = add_topics,
    add_sub = add_sub,
    set_subs = set_subs,
    proc = process_queue,
    q = q,
    t = t
  }
end
