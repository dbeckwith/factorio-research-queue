local util = require('.util')

local rqtech = {}

function rqtech.init()
  global.rqtechs = {}
end

function rqtech.init_force(force)
  global.rqtechs[force.index] = {}
end

function rqtech.deinit_force(force)
  global.rqtechs[force.index] = nil
end

function rqtech.new(tech, level)
  local id = string.format('%s.%s', tech.name, level)

  local cached_rqtech = global.rqtechs[tech.force.index][id]
  if cached_rqtech ~= nil then
    return cached_rqtech
  end

  local level_from_name = string.match(tech.name, '-(%d+)$')
  if level_from_name ~= nil then
    level_from_name = tonumber(level_from_name)
    assert(level_from_name >= 1)
  end
  if level == nil then
    level = level_from_name
  end
  if level ~= nil then
    assert(level_from_name ~= nil)
    assert(level >= level_from_name)
    assert(level <= tech.max_level)
  else
    assert(level_from_name == nil)
  end

  local upgrade_group
  do
    local level_tail = string.find(tech.name, '-%d+$')
    if level_tail ~= nil then
      upgrade_group = string.sub(tech.name, 1, level_tail - 1)
    else
      upgrade_group = tech.name
    end
  end

  local research_unit_count
  if tech.research_unit_count_formula ~= nil then
    research_unit_count = game.evaluate_expression(tech.research_unit_count_formula, { L = level, l = level })
  else
    research_unit_count = tech.research_unit_count
  end

  local prerequisites
  if level ~= level_from_name then
    prerequisites = { [tech.name] = rqtech.new(tech, level - 1) }
  else
    prerequisites = {}
    for name, prerequisite in pairs(tech.prerequisites) do
      prerequisites[name] = rqtech.new(prerequisite)
    end
  end

  return {
    id = id,
    tech = tech,
    level = level,
    upgrade_group = upgrade_group,
    infinite = tech.research_unit_count_formula ~= nil,
    research_unit_count = research_unit_count,
    prerequisites = prerequisites,
  }
end

function rqtech.iter(force)
  return util.iter_map(
    util.iter_values(force.technologies),
    rqtech.new)
end

return rqtech
