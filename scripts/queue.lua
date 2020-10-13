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

local function is_researchable(player, queue, tech)
  return tech.enabled and not tech.researched
end

local function is_dependency(player, queue, dependency, tech)
  return is_researchable(player, queue, dependency) and tech.prerequisites[dependency.name] ~= nil
end

local function is_dependent(player, queue, dependent, tech)
  return is_researchable(player, queue, dependent) and is_dependency(player, queue, tech, dependent)
end

local function tech_dependencies(player, queue, tech)
  return util.iter_filter(
    util.iter_values(tech.prerequisites),
    function(dependency)
      return is_researchable(player, queue, dependency)
    end)
end

local function tech_dependents(player, queue, tech)
  return util.iter_filter(
    util.iter_values(player.force.technologies),
    function(depdendent)
      return is_dependent(player, queue, depdendent, tech)
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

local function try_shift_later(player, queue, tech)
  local tech_pos = queue_pos(player, queue, tech)
  local pivot_pos = tech_pos + 1
  if pivot_pos > #queue then
    return nil
  end
  while is_depdendent_of_any(player, queue, queue[pivot_pos], tech_pos, pivot_pos) do
    pivot_pos = pivot_pos + 1
    if pivot_pos > #queue then
      return nil
    end
  end
  return pivot_pos, tech_pos
end

local function shift_later(player, queue, tech)
  local pivot_pos, tech_pos = try_shift_later(player, queue, tech)
  if pivot_pos ~= nil then
    rotate(player, queue, pivot_pos, tech_pos)
    return true
  end
  return false
end

local function try_shift_earlier(player, queue, tech)
  local tech_pos = queue_pos(player, queue, tech)
  local pivot_pos = tech_pos - 1
  if pivot_pos < 1 then
    return nil
  end
  while is_depdendency_of_any(player, queue, queue[pivot_pos], pivot_pos, tech_pos) do
    pivot_pos = pivot_pos - 1
    if pivot_pos < 1 then
      return nil
    end
  end
  return pivot_pos, tech_pos
end

local function shift_earlier(player, queue, tech)
  local pivot_pos, tech_pos = try_shift_earlier(player, queue, tech)
  if pivot_pos ~= nil then
    rotate(player, queue, pivot_pos, tech_pos)
    return true
  end
  return false
end

local function shift_latest(player, queue, tech)
  while shift_later(player, queue, tech) do end
end

local function shift_earliest(player, queue, tech)
  while shift_earlier(player, queue, tech) do end
end

local function shift_before_earliest(player, queue, tech)
  while shift_earlier(player, queue, tech) do end
  local tech_pos = queue_pos(player, queue, tech)
  if tech_pos == 1 then
    shift_later(player, queue, tech)
  end
end

local function enqueue_tail(player, queue, tech)
  enqueue(player, queue, tech)
  shift_latest(player, queue, tech)
end

local function enqueue_head(player, queue, tech)
  enqueue(player, queue, tech)
  shift_earliest(player, queue, tech)
end

local function enqueue_before_head(player, queue, tech)
  enqueue(player, queue, tech)
  shift_before_earliest(player, queue, tech)
end

local function iter(player, queue)
  return util.iter_list(queue)
end

local function update(player, queue)
  local to_dequeue = {}
  for _, tech in ipairs(queue) do
    if not is_researchable(player, queue, tech) then
      table.insert(to_dequeue, tech)
    end
  end
  for _, tech in ipairs(to_dequeue) do
    dequeue(player, queue, tech)
  end

  local force = player.force
  if next(queue) ~= nil then
    force.research_queue = {queue[1]}
  else
    force.research_queue = {}
  end
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
  enqueue_before_head = function(player, tech)
    local queue = global.players[player.index].queue
    return enqueue_before_head(player, queue, tech)
  end,
  shift_earlier = function(player, tech)
    local queue = global.players[player.index].queue
    return shift_earlier(player, queue, tech)
  end,
  shift_earliest = function(player, tech)
    local queue = global.players[player.index].queue
    return shift_earliest(player, queue, tech)
  end,
  can_shift_earlier = function(player, tech)
    local queue = global.players[player.index].queue
    return try_shift_earlier(player, queue, tech) ~= nil
  end,
  shift_later = function(player, tech)
    local queue = global.players[player.index].queue
    return shift_later(player, queue, tech)
  end,
  shift_latest = function(player, tech)
    local queue = global.players[player.index].queue
    return shift_latest(player, queue, tech)
  end,
  can_shift_later = function(player, tech)
    local queue = global.players[player.index].queue
    return try_shift_later(player, queue, tech) ~= nil
  end,
  dequeue = function(player, tech)
    local queue = global.players[player.index].queue
    return dequeue(player, queue, tech)
  end,
  iter = function(player)
    local queue = global.players[player.index].queue
    return iter(player, queue)
  end,
  update = function(player)
    local queue = global.players[player.index].queue
    return update(player, queue)
  end
}
