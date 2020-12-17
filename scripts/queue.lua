local rqtech = require('.rqtech')
local util = require('.util')

local function new(force, paused)
  local queue = {}
  global.forces[force.index].queue = queue
  global.forces[force.index].queue_paused = paused
end

local function rotate(force, queue, i, j)
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

local function is_researchable(force, queue, tech)
  return
    not tech.tech.prototype.hidden and
    tech.tech.enabled and
    not rqtech.is_researched(tech)
end

local function is_dependency(force, queue, dependency, tech)
  return is_researchable(force, queue, dependency) and tech.prerequisites[dependency.tech.name] ~= nil
end

local function is_dependent(force, queue, dependent, tech)
  return is_researchable(force, queue, dependent) and is_dependency(force, queue, tech, dependent)
end

local function tech_dependencies(force, queue, tech)
  return util.iter_filter(
    util.iter_values(tech.prerequisites),
    function(dependency)
      return is_researchable(force, queue, dependency)
    end)
end

local function tech_dependents(force, queue, tech)
  local deps
  if tech.infinite and tech.level < tech.tech.prototype.max_level then
    deps = util.iter_once(rqtech.new(tech.tech, tech.level + 1))
  else
    deps = rqtech.iter(force)
  end
  return util.iter_filter(
    deps,
    function(depdendent)
      return is_dependent(force, queue, depdendent, tech)
    end)
end

local function queue_pos(force, queue, tech)
  for idx, queued_tech in ipairs(queue) do
    if queued_tech.id == tech.id then
      return idx
    end
  end
  return nil
end

local function is_head(force, queue, tech, ignore_level)
  if queue[1] == nil then
    return false
  end
  if ignore_level then
    return queue[1].tech.name == tech.tech.name
  else
    return queue[1].id == tech.id
  end
end

local function get_head(force, queue)
  return queue[1]
end

local function queue_prev(force, queue, tech)
  for idx, queued_tech in ipairs(queue) do
    if queued_tech.id == tech.id then
      return idx
    end
  end
  return nil
end

local function in_queue(force, queue, tech)
  for _, queued_tech in ipairs(queue) do
    if queued_tech.id == tech.id then
      return true
    end
  end
  return false
end

local function enqueue(force, queue, tech)
  if not in_queue(force, queue, tech) then
    for dependency in tech_dependencies(force, queue, tech) do
      enqueue(force, queue, dependency)
    end

    table.insert(queue, tech)
  end
end

local function dequeue(force, queue, tech)
  if in_queue(force, queue, tech) then
    for dependent in tech_dependents(force, queue, tech) do
      dequeue(force, queue, dependent)
    end

    for idx, queued_tech in ipairs(queue) do
      if queued_tech.id == tech.id then
        table.remove(queue, idx)
        break
      end
    end
  end
end

local function is_depdendency_of_any(force, queue, tech, from_pos, to_pos)
  for i = from_pos,to_pos do
    if is_dependency(force, queue, tech, queue[i]) then
      return true
    end
  end
  return false
end

local function is_depdendent_of_any(force, queue, tech, from_pos, to_pos)
  for i = from_pos,to_pos do
    if is_dependent(force, queue, tech, queue[i]) then
      return true
    end
  end
  return false
end

local function try_shift_later(force, queue, tech)
  local tech_pos = queue_pos(force, queue, tech)
  local pivot_pos = tech_pos + 1
  if pivot_pos > #queue then
    return nil
  end
  while is_depdendent_of_any(force, queue, queue[pivot_pos], tech_pos, pivot_pos) do
    pivot_pos = pivot_pos + 1
    if pivot_pos > #queue then
      return nil
    end
  end
  return pivot_pos, tech_pos
end

local function shift_later(force, queue, tech)
  local pivot_pos, tech_pos = try_shift_later(force, queue, tech)
  if pivot_pos ~= nil then
    rotate(force, queue, pivot_pos, tech_pos)
    return true
  end
  return false
end

local function try_shift_earlier(force, queue, tech, head)
  head = head or 1
  local tech_pos = queue_pos(force, queue, tech)
  local pivot_pos = tech_pos - 1
  if pivot_pos < head then
    return nil
  end
  while is_depdendency_of_any(force, queue, queue[pivot_pos], pivot_pos, tech_pos) do
    pivot_pos = pivot_pos - 1
    if pivot_pos < head then
      return nil
    end
  end
  return pivot_pos, tech_pos
end

local function shift_earlier(force, queue, tech, head)
  local pivot_pos, tech_pos = try_shift_earlier(force, queue, tech, head)
  if pivot_pos ~= nil then
    rotate(force, queue, pivot_pos, tech_pos)
    return true
  end
  return false
end

local function shift_latest(force, queue, tech)
  while shift_later(force, queue, tech) do end
end

local function shift_earliest(force, queue, tech)
  while shift_earlier(force, queue, tech) do end
end

local function shift_before_earliest(force, queue, paused, tech)
  while shift_earlier(force, queue, tech, paused and 1 or 2) do end
end

local function enqueue_tail(force, queue, tech)
  enqueue(force, queue, tech)
  shift_latest(force, queue, tech)
end

local function enqueue_head(force, queue, tech)
  enqueue(force, queue, tech)
  shift_earliest(force, queue, tech)
end

local function enqueue_before_head(force, queue, paused, tech)
  enqueue(force, queue, tech)
  shift_before_earliest(force, queue, paused, tech)
end

local function iter(force, queue)
  return util.iter_list(queue)
end

local function clear(force, force_data)
  if force_data.queue_paused then
    force_data.queue = {}
  else
    local head = force_data.queue[1]
    force_data.queue = {head}
  end
end

local function update(force, queue, paused)
  local to_dequeue = {}
  for _, tech in ipairs(queue) do
    if not is_researchable(force, queue, tech) then
      table.insert(to_dequeue, tech)
    end
  end
  for _, tech in ipairs(to_dequeue) do
    dequeue(force, queue, tech)
  end

  if force.research_queue_enabled then
    force.print{'',
      '[[color=150,206,130]',
      {'mod-name.sonaxaton-research-queue'},
      '[/color]] ',
      {'sonaxaton-research-queue.vanilla-queue-overwritten-warning'}}
    force.research_queue_enabled = false
  end
  if not paused and next(queue) ~= nil then
    force.research_queue = {queue[1].tech}
  else
    force.research_queue = {}
  end
end

return {
  new = new,
  is_paused = function(force)
    local force_data = global.forces[force.index]
    local paused = force_data.queue_paused
    return paused
  end,
  set_paused = function(force, paused)
    local force_data = global.forces[force.index]
    force_data.queue_paused = paused
  end,
  toggle_paused = function(force, paused)
    local force_data = global.forces[force.index]
    force_data.queue_paused = not force_data.queue_paused
  end,
  is_researchable = function(force, tech)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    return is_researchable(force, queue, tech)
  end,
  in_queue = function(force, tech)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    return in_queue(force, queue, tech)
  end,
  is_head = function(force, tech, ignore_level)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    return is_head(force, queue, tech, ignore_level)
  end,
  get_head = function(force)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    return get_head(force, queue)
  end,
  queue_pos = function(force, tech)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    return queue_pos(force, queue, tech)
  end,
  enqueue = function(force, tech)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    return enqueue(force, queue, tech)
  end,
  enqueue_tail = function(force, tech)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    return enqueue_tail(force, queue, tech)
  end,
  enqueue_head = function(force, tech)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    force_data.queue_paused = false
    return enqueue_head(force, queue, tech)
  end,
  enqueue_before_head = function(force, tech)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    local paused = force_data.queue_paused
    return enqueue_before_head(force, queue, paused, tech)
  end,
  shift_earlier = function(force, tech)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    return shift_earlier(force, queue, tech)
  end,
  shift_earliest = function(force, tech)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    return shift_earliest(force, queue, tech)
  end,
  can_shift_earlier = function(force, tech)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    return try_shift_earlier(force, queue, tech) ~= nil
  end,
  shift_before_earliest = function(force, tech)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    local paused = force_data.queue_paused
    return shift_before_earliest(force, queue, paused, tech)
  end,
  shift_later = function(force, tech)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    return shift_later(force, queue, tech)
  end,
  shift_latest = function(force, tech)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    return shift_latest(force, queue, tech)
  end,
  can_shift_later = function(force, tech)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    return try_shift_later(force, queue, tech) ~= nil
  end,
  dequeue = function(force, tech)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    return dequeue(force, queue, tech)
  end,
  clear = function(force)
    local force_data = global.forces[force.index]
    return clear(force, force_data)
  end,
  iter = function(force)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    return iter(force, queue)
  end,
  update = function(force)
    local force_data = global.forces[force.index]
    local queue = force_data.queue
    local paused = force_data.queue_paused
    return update(force, queue, paused)
  end
}
