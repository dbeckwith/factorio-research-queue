local function new(player)
  local queue = {}
  global.players[player.index].queue = queue
end

local function in_queue(queue, tech)
  for _, t in ipairs(queue) do
    if t.name == tech.name then
      return true
    end
  end
  return false
end

local function enqueue(queue, tech)
  if not in_queue(queue, tech) then
    for _, dependency in pairs(tech.prerequisites) do
      enqueue(queue, dependency)
    end

    table.insert(queue, tech)
  end
end

local function iter(queue)
  local i = 0
  local n = #queue
  return function()
    i = i + 1
    if i <= n then
      return queue[i]
    end
  end
end

return {
  new = new,
  enqueue = function(player, tech)
    local queue = global.players[player.index].queue
    return enqueue(queue, tech)
  end,
  iter = function(player)
    local queue = global.players[player.index].queue
    return iter(queue)
  end,
}
