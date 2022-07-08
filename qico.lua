function qico()
  local q = {} -- msg queue, just strings for now
  local t = {} -- topics

  function add_event(name, payload)
    add(q, { name=name, payload=payload })
  end

  function add_topic(name)
    t[name] = {}
  end

  function add_topics(names)
    for k,name in pairs(names) do
      t[name] = {}
    end
  end

  function add_subscriber(name, fn)
    add(t[name], fn)
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
    as = add_subscriber,
    proc = process_queue,
    q = q,
    t = t
  }
end
