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

local function for_each(queue, action)
  for _, tech in pairs(queue) do
    action(tech)
  end
end

return {
  new = new,
  enqueue = function(player, tech)
    local queue = global.players[player.index].queue
    enqueue(queue, tech)
  end,
  for_each = function(player, action)
    local queue = global.players[player.index].queue
    for_each(queue, action)
  end,
}
