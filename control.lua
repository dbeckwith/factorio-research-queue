local eventlib = require('__flib__.event')
local guilib = require('__flib__.gui')
local migrationlib = require('__flib__.migration')

local gui = require('scripts.gui')
local queue = require('scripts.queue')

eventlib.on_init(function()
  guilib.init()
  guilib.build_lookup_tables()

  global.players = {}

  global.tech_ingredients = {}
  for _, item in pairs(game.get_filtered_item_prototypes{{filter='tool'}}) do
    local is_tech_ingredient = (function()
      for _, tech in pairs(game.technology_prototypes) do
        for _, ingredient in pairs(tech.research_unit_ingredients) do
          if ingredient.type == 'item' and ingredient.name == item.name then
            return true
          end
        end
      end
      return false
    end)()
    if is_tech_ingredient then
      table.insert(global.tech_ingredients, item)
    end
  end
  table.sort(global.tech_ingredients, function(a, b) return a.order < b.order end)

  for _, player in pairs(game.players) do
    global.players[player.index] = {}
    queue.new(player)
    gui.create_guis(player)
  end
end)

eventlib.on_load(function()
  guilib.build_lookup_tables()
end)

eventlib.on_configuration_changed(function(event)
  -- TODO: rebuild research ingredients list

  if migrationlib.on_config_changed(event, {}) then
    guilib.check_filter_validity()

    for _, player in pairs(game.players) do
      gui.destroy_guis(player)
      global.players[player.index] = {}
      gui.create_guis(player)
    end
  end
end)

guilib.register_handlers()

-- TODO: test that this gets fired when adding the mod to an existing save
eventlib.on_player_created(function(event)
  local player = game.players[event.player_index]
  global.players[player.index] = {}
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
      if player.is_shortcut_toggled('sonaxaton-research-queue') then
        gui.close(player)
      else
        gui.open(player)
      end
    end
  end
end)

eventlib.register('sonaxaton-research-queue', function(event)
  local player = game.players[event.player_index]
  if player ~= nil then
    if player.is_shortcut_toggled('sonaxaton-research-queue') then
      gui.close(player)
    else
      gui.open(player)
    end
  end
end)

eventlib.register(defines.events.on_research_finished, function(event)
  local force = event.research.force
  for _, player in pairs(force.players) do
    gui.on_research_finished(player, event.research)
  end
end)

eventlib.register(defines.events.on_string_translated, function(event)
  if event.translated then
    local player = game.players[event.player_index]
    if player ~= nil then
      gui.on_string_translated(player, event.localised_string, event.result)
    end
  end
end)
