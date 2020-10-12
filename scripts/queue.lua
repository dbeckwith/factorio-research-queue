local util = require('.util')

local function new(player)
  local queue = {}
  global.players[player.index].queue = queue
end

local function tech_dependencies(player, queue, tech)
  return util.iter_values(tech.prerequisites)
end

local function tech_dependents(player, queue, tech)
  return util.iter_filter(
    util.iter_values(player.force.technologies),
    function(other_tech)
      return other_tech.prerequisites[tech.name] ~= nil
    end)
end

local function in_queue(player, queue, tech)
  for _, queued_tech in ipairs(queue) do
    if queued_tech.name == tech.name then
      return true
    end
  end
  return false
end

local function enqueue(player, queue, tech)
  if not in_queue(player, queue, tech) then
    for dependency in tech_dependencies(player, queue, tech) do
      enqueue(player, queue, dependency)
    end

    table.insert(queue, tech)
  end
end

local function dequeue(player, queue, tech)
  if in_queue(player, queue, tech) then
    for dependent in tech_dependents(player, queue, tech) do
      dequeue(player, queue, dependent)
    end

    for idx, queued_tech in ipairs(queue) do
      if queued_tech.name == tech.name then
        table.remove(queue, idx)
        break
      end
    end
  end
end

local function iter(player, queue)
  return util.iter_list(queue)
end

return {
  new = new,
  enqueue = function(player, tech)
    local queue = global.players[player.index].queue
    return enqueue(player, queue, tech)
  end,
  dequeue = function(player, tech)
    local queue = global.players[player.index].queue
    return dequeue(player, queue, tech)
  end,
  iter = function(player)
    local queue = global.players[player.index].queue
    return iter(player, queue)
  end,
}
