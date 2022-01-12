function qico()
  local q = {} -- msg queue, just strings for now
  local t = {} -- topics

  function add_event(name, payload)
    local tmp = {
      name = name,
      payload = payload,
    }
    add(q, tmp)
  end

  function add_topic(name)
    t[name] = {}

    local topic_str = ""
    for k,v in pairs(t) do
      topic_str = topic_str.." "..k
    end
  end

  function add_subscriber(name, fn)
    add(t[name], fn)
  end

  function process_queue()
    for k,v in pairs(q) do
      if t[v.name] != nil then
        for ik,iv in pairs(t[v.name]) do
          iv(v.name, v.payload)
        end
      end
      q[k] = nil
    end
  end

  return {
    ae = add_event,
    at = add_topic,
    as = add_subscriber,
    proc = process_queue,
    q = q,
    t = t
  }
end
