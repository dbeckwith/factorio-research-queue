__rq_debug = false

local eventlib = require('__flib__.event')
local guilib = require('__flib__.gui')
local migrationlib = require('__flib__.migration')
local translationlib = require('__flib__.translation')

local gui = require('scripts.gui')
local queue = require('scripts.queue')

local migrations = {
}

local queue_save = {
}

function init_player(player)
  global.players[player.index] = {}
  queue.new(player)
  gui.create_guis(player)
end

function deinit_player(player)
  translationlib.cancel(player.index)
  gui.destroy_guis(player)
  guilib.remove_player_filters(player.index)
  global.players[player.index] = nil
end

eventlib.on_init(function()
  translationlib.init()
  guilib.init()
  guilib.build_lookup_tables()

  global.players = {}
  for _, player in pairs(game.players) do
    init_player(player)
  end
end)

eventlib.on_load(function()
  guilib.build_lookup_tables()
end)

eventlib.on_configuration_changed(function(event)
  local init = true
  local changes = event.mod_changes[script.mod_name]
  if changes then
    local old_version = changes.old_version
    if old_version then
      -- save queue from old version
      local queue_save = queue_save[old_version]
      local saved_queues = {}
      if queue_save ~= nil then
        for _, player in pairs(game.players) do
          saved_queues[player.index] = queue_save[old_version](player)
        end
      end

      migrationlib.run(old_version, migrations)

      for _, player in pairs(game.players) do
        deinit_player(player)
        init_player(player)

        -- rebuild queue from old version
        if queue_save ~= nil then
          for _, tech_name in ipairs(saved_queues[player.index]) do
            local tech = player.force.technologies[tech_name]
            if tech ~= nil then
              queue.enqueue(player, tech)
            end
          end
        end
      end
    else
      init = false
    end
  end

  if init then
    translationlib.init()
    guilib.check_filter_validity()
  end
end)

guilib.register_handlers()

eventlib.on_player_created(function(event)
  local player = game.players[event.player_index]
  init_player(player)
end)

eventlib.on_player_removed(function(event)
  local player = game.players[event.player_index]
  deinit_player(player)
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
    gui.focus_search(player)
  end
end)

eventlib.on_research_started(function(event)
  local force = event.research.force
  for _, player in pairs(force.players) do
    gui.on_research_started(player, event.research, event.last_research)
  end
end)

eventlib.on_research_finished(function(event)
  local force = event.research.force
  for _, player in pairs(force.players) do
    gui.on_research_finished(player, event.research)
  end
end)

eventlib.on_string_translated(function(event)
  local player = game.players[event.player_index]
  if player ~= nil then
    gui.on_string_translated(player, event)
  end
end)

eventlib.on_gui_opened(function(event)
  if not guilib.dispatch_handlers(event) then
    local player = game.players[event.player_index]
    if player ~= nil then
      if event.gui_type == defines.gui_type.research then
        gui.on_technology_gui_opened(player)
      end
    end
  end
end)

eventlib.on_gui_closed(function(event)
  if not guilib.dispatch_handlers(event) then
    local player = game.players[event.player_index]
    if player ~= nil then
      if event.gui_type == defines.gui_type.research then
        gui.on_technology_gui_closed(player)
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
    for _, player in pairs(force.players) do
      gui.on_research_speed_estimate(player, speed_estimate)
    end
  end
end)
