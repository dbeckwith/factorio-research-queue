-- https://factoriolib.github.io/flib/modules/gui.html
-- https://github.com/factoriolib/flib
-- https://github.com/raiguard/Factorio-RecipeBook/blob/master/src/scripts/gui/main/base.lua
-- https://github.com/raiguard/Factorio-RecipeBook/blob/master/src/scripts/gui/main/pages/recipe.lua
-- https://github.com/raiguard/Factorio-RecipeBook/blob/master/src/prototypes/style.lua
-- https://forums.factorio.com/viewtopic.php?p=495184#p495184

local eventlib = require('__flib__.event')
local guilib = require('__flib__.gui')

local gui = require('scripts.gui')
local queue = require('scripts.queue')

eventlib.on_init(function()
  guilib.init()
  guilib.build_lookup_tables()

  global.players = {}
  for i, player in pairs(game.players) do
    global.players[i] = {}
    gui.create_guis(player)
  end
end)

eventlib.on_load(function()
  guilib.build_lookup_tables()
end)

eventlib.on_configuration_changed(function(event)
  if migration.on_config_changed(event, {}) then
    guilib.check_filter_validity()

    for i, player in pairs(game.players) do
      gui.destroy_guis(player)
      gui.create_guis(player)
    end
  end
end)

guilib.register_handlers()

eventlib.on_player_created(function(event)
  global.players[event.player_index] = {}
  local player = game.get_player(event.player_index)
  queue.new(player)
  gui.create_guis(player)
end)

eventlib.on_player_removed(function(event)
  global.players[event.player_index] = nil
  guilib.remove_player_filters(event.player_index)
end)

eventlib.register(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name == 'sonaxaton-research-queue' then
    local player = game.players[event.player_index]
    if player ~= nil then
      gui.open(player)
    end
  end
end)

eventlib.register('sonaxaton-research-queue', function(event)
  local player = game.players[event.player_index]
  if player ~= nil then
    gui.open(player)
  end
end)

eventlib.register(defines.events.on_research_finished, function(event)
  local force = event.research.force
  for _, player in pairs(force.players) do
    gui.update_techs(player)
    gui.update_queue(player)
  end
end)
