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
    if player.is_shortcut_toggled('sonaxaton-research-queue') then
      gui.close(player)
    else
      gui.open(player)
    end
  end
end)

eventlib.register('rq-focus-search', function(event)
  local player = game.players[event.player_index]
  if player ~= nil then
    if player.is_shortcut_toggled('sonaxaton-research-queue') then
      gui.focus_search(player)
    end
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
