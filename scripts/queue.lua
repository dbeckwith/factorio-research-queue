local util = require('.util')

local function new(player)
  local queue = {}
  global.players[player.index].queue = queue
end

local function rotate(player, queue, i, j)
  if i == j then return end
  local dir = i < j and 1 or -1
  local tmp = queue[i]
  local k = i
  while k*dir < j*dir do
    queue[k] = queue[k+dir]
    k = k+dir
  end
  queue[j] = tmp
end

local function is_dependency(player, queue, dependency, tech)
  return tech.prerequisites[dependency.name] ~= nil
end

local function is_dependent(player, queue, dependent, tech)
  return is_dependency(player, queue, tech, dependent)
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

local function queue_pos(player, queue, tech)
  for idx, queued_tech in ipairs(queue) do
    if queued_tech.name == tech.name then
      return idx
    end
  end
  return nil
end

local function queue_prev(player, queue, tech)
  for idx, queued_tech in ipairs(queue) do
    if queued_tech.name == tech.name then
      return idx
    end
  end
  return nil
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

local function is_depdendency_of_any(player, queue, tech, from_pos, to_pos)
  for i = from_pos,to_pos do
    if is_dependency(player, queue, tech, queue[i]) then
      return true
    end
  end
  return false
end

local function is_depdendent_of_any(player, queue, tech, from_pos, to_pos)
  for i = from_pos,to_pos do
    if is_dependent(player, queue, tech, queue[i]) then
      return true
    end
  end
  return false
end

local function shift_later(player, queue, tech)
  local tech_pos = queue_pos(player, queue, tech)
  local pivot_pos = tech_pos + 1
  if pivot_pos > #queue then
    return false
  end
  while is_depdendent_of_any(player, queue, queue[pivot_pos], tech_pos, pivot_pos) do
    pivot_pos = pivot_pos + 1
    if pivot_pos > #queue then
      return false
    end
  end
  rotate(player, queue, pivot_pos, tech_pos)
  return true
end

local function shift_earlier(player, queue, tech)
  local tech_pos = queue_pos(player, queue, tech)
  local pivot_pos = tech_pos - 1
  if pivot_pos < 1 then
    return false
  end
  while is_depdendency_of_any(player, queue, queue[pivot_pos], pivot_pos, tech_pos) do
    pivot_pos = pivot_pos - 1
    if pivot_pos < 1 then
      return false
    end
  end
  rotate(player, queue, pivot_pos, tech_pos)
  return true
end

local function shift_latest(player, queue, tech)
  while shift_later(player, queue, tech) do end
end

local function shift_earliest(player, queue, tech)
  while shift_earlier(player, queue, tech) do end
end

local function enqueue_tail(player, queue, tech)
  enqueue(player, queue, tech)
  shift_latest(player, queue, tech)
end

local function enqueue_head(player, queue, tech)
  enqueue(player, queue, tech)
  shift_earliest(player, queue, tech)
end

local function iter(player, queue)
  return util.iter_list(queue)
end

return {
  new = new,
  enqueue_tail = function(player, tech)
    local queue = global.players[player.index].queue
    return enqueue_tail(player, queue, tech)
  end,
  enqueue_head = function(player, tech)
    local queue = global.players[player.index].queue
    return enqueue_head(player, queue, tech)
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
