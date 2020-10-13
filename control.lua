local eventlib = require('__flib__.event')
local guilib = require('__flib__.gui')
local migrationlib = require('__flib__.migration')
local translationlib = require('__flib__.translation')

local gui = require('scripts.gui')
local queue = require('scripts.queue')

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
  if migrationlib.on_config_changed(event, {}) then
    translationlib.init()
    guilib.check_filter_validity()

    for _, player in pairs(game.players) do
      deinit_player(player)
      init_player(player)
    end
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
