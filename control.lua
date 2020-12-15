__rq_debug = true

local eventlib = require('__flib__.event')
local guilib = require('__flib__.gui')
local migrationlib = require('__flib__.migration')
local translationlib = require('__flib__.translation')

local gui = require('scripts.gui')
local queue = require('scripts.queue')

local CURRENT_VERSION = script.active_mods[script.mod_name]

local migrations = {
  ['0.4.0'] = function()
    global.forces = {}

    for _, player in pairs(game.players) do
      global.players[player.index].queue = nil
      global.players[player.index].queue_paused = nil
    end
  end,
}

local queue_saves = {
  {
    version = '0.3.3',
    save = function(force)
      for _, player in pairs(force.players) do
        if global.players[player.index] == nil then return end
        local player_data = global.players[player.index]
        local tech_names = {}
        for _, tech in ipairs(player_data.queue) do
          if tech.valid then
            table.insert(tech_names, tech.name)
          end
        end
        local paused = player_data.queue_paused
        return tech_names, paused
      end
    end,
  },
}

function lookup_queue_save(version)
  log('looking up queue save fn for v'..version)
  -- find the oldest qs that's newer or equal to the map version
  for _, qs in ipairs(queue_saves) do
    if
      qs.version == version or
      migrationlib.is_newer_version(version, qs.version)
    then
      log('using queue save fn v'..(qs.version or CURRENT_VERSION))
      return qs.save
    end
  end
  return function(force)
    if global.forces[force.index] == nil then return end
    local tech_names = {}
    for tech in queue.iter(force) do
      if tech.valid then
        table.insert(tech_names, tech.name)
      end
    end
    local paused = queue.is_paused(force)
    return tech_names, paused
  end
end

function init_player(player)
  global.players[player.index] = {}

  gui.init(player)
end

function deinit_player(player)
  translationlib.cancel(player.index)
  gui.deinit(player)
  guilib.remove_player_filters(player.index)
  global.players[player.index] = nil
end

function init_force(force, saved_queue, queue_paused)
  if global.forces[force.index] ~= nil then return end

  global.forces[force.index] = {}

  if saved_queue == nil then saved_queue = {} end
  if queue_paused == nil then queue_paused = true end

  queue.new(force, queue_paused)
  for _, tech_name in ipairs(saved_queue) do
    local tech = force.technologies[tech_name]
    if tech ~= nil then
      queue.enqueue(force, tech)
    end
  end
end

function deinit_force(force)
  global.forces[force.index] = nil
end

eventlib.on_init(function()
  translationlib.init()
  guilib.init()
  guilib.build_lookup_tables()

  global.forces = {}
  for _, force in pairs(game.forces) do
    init_force(force)
  end

  global.players = {}
  for _, player in pairs(game.players) do
    init_player(player)
  end
end)

eventlib.on_load(function()
  guilib.build_lookup_tables()
end)

eventlib.on_configuration_changed(function(event)
  local saved_queues = {}
  local saved_queue_paused = {}

  local function save_queues(old_version)
    -- get a function to save the queue from the given version,
    -- or default to the current one
    local version = old_version or CURRENT_VERSION
    local queue_save = lookup_queue_save(version)

    for _, force in pairs(game.forces) do
      log('saving queue for '..force.name)
      local saved_queue, paused = queue_save(force)
      log('saved queue for '..force.name..': '..serpent.line({ queue = saved_queue, paused = paused }))
      saved_queues[force.index] = saved_queue
      saved_queue_paused[force.index] = paused
    end
  end

  local init = true
  local changes = event.mod_changes[script.mod_name]
  if changes then
    local old_version = changes.old_version
    if old_version then
      -- save queues before running migrations
      save_queues(old_version)

      migrationlib.run(old_version, migrations)
    else
      save_queues()
      init = false
    end
  else
    save_queues()
  end

  for _, force in pairs(game.forces) do
    deinit_force(force)
    init_force(
      force,
      saved_queues[force.index],
      saved_queue_paused[force.index])
  end

  if init then
    translationlib.init()
  end

  for _, player in pairs(game.players) do
    deinit_player(player)
    init_player(player)
  end

  if init then
    guilib.check_filter_validity()
  end
end)

guilib.register_handlers()

eventlib.on_force_created(function(event)
  local force = event.force
  init_force(force)
end)

eventlib.on_forces_merging(function(event)
  local force = event.source
  deinit_force(force)
end)

eventlib.on_force_reset(function(event)
  local force = event.force
  deinit_force(force)
  init_force(force)
  for _, player in pairs(force.players) do
    gui.update(player)
  end
end)

eventlib.on_player_created(function(event)
  local player = game.players[event.player_index]
  init_player(player)
end)

eventlib.on_pre_player_removed(function(event)
  local player = game.players[event.player_index]
  deinit_player(player)
end)

eventlib.on_player_changed_force(function(event)
  local player = game.players[event.player_index]
  if game.players[player.index] ~= nil then
    gui.update(player)
  end
end)

eventlib.on_lua_shortcut(function(event)
  if event.prototype_name == 'sonaxaton-research-queue' then
    local player = game.players[event.player_index]
    if player ~= nil then
      if player.is_shortcut_toggled('sonaxaton-research-queue') then
        gui.close(player)
      else
        gui.open(player)
      end
    end
  end
end)

eventlib.register('rq-toggle-main-window', function(event)
  local player = game.players[event.player_index]
  if player ~= nil then
    gui.toggle(player)
  end
end)

eventlib.register('rq-focus-search', function(event)
  local player = game.players[event.player_index]
  if player ~= nil then
    if global.players[player.index] ~= nil then
      gui.focus_search(player)
    end
  end
end)

eventlib.on_research_started(function(event)
  local force = event.research.force
  if global.forces[force.index] ~= nil then
    gui.on_research_started(force, event.research, event.last_research)
  end
end)

eventlib.on_research_finished(function(event)
  local force = event.research.force
  if global.forces[force.index] ~= nil then
    gui.on_research_finished(force, event.research)
  end
end)

eventlib.on_string_translated(function(event)
  local player = game.players[event.player_index]
  if player ~= nil then
    if global.players[player.index] ~= nil then
      gui.on_string_translated(player, event)
    end
  end
end)

eventlib.on_gui_opened(function(event)
  if not guilib.dispatch_handlers(event) then
    local player = game.players[event.player_index]
    if player ~= nil then
      if global.players[player.index] ~= nil then
        if event.gui_type == defines.gui_type.research then
          gui.on_technology_gui_opened(player)
        end
      end
    end
  end
end)

eventlib.on_gui_closed(function(event)
  if not guilib.dispatch_handlers(event) then
    local player = game.players[event.player_index]
    if player ~= nil then
      if global.players[player.index] ~= nil then
        if event.gui_type == defines.gui_type.research then
          gui.on_technology_gui_closed(player)
        end
      end
    end
  end
end)

local research_speed_period = 60
local research_progress_sample_count = 3
local research_progress_samples_by_force = {}

eventlib.on_nth_tick(research_speed_period, function(event)
  for _, force in pairs(game.forces) do
    local tech = force.current_research
    local speed_estimate = 0
    if tech ~= nil then
      local progress_samples = research_progress_samples_by_force[force.index]
      if progress_samples == nil then
        progress_samples = {}
        research_progress_samples_by_force[force.index] = progress_samples
      end
      table.insert(progress_samples, {
        tech = tech,
        progress = force.research_progress,
      })
      if #progress_samples > 1+research_progress_sample_count then
        table.remove(progress_samples, 1)
      end
      if #progress_samples > 1 then
        local num_samples = 0
        for i = 2,#progress_samples do
          local prev_sample = progress_samples[i-1]
          local curr_sample = progress_samples[i]
          if prev_sample.tech.name == curr_sample.tech.name then
            local tech = prev_sample.tech
            local diff = curr_sample.progress - prev_sample.progress
            speed_estimate = speed_estimate + diff /
              (research_speed_period/60) *
              (tech.research_unit_energy/60) *
              tech.research_unit_count
            num_samples = num_samples + 1
          end
        end
        if num_samples > 0 then
          speed_estimate = speed_estimate / num_samples
        end
      end
    end
    gui.on_research_speed_estimate(force, speed_estimate)
  end
end)
