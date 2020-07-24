-- https://factoriolib.github.io/flib/modules/gui.html
-- https://github.com/factoriolib/flib
-- https://github.com/raiguard/Factorio-RecipeBook/blob/master/src/scripts/gui/main/base.lua
-- https://github.com/raiguard/Factorio-RecipeBook/blob/master/src/scripts/gui/main/pages/recipe.lua
-- https://github.com/raiguard/Factorio-RecipeBook/blob/master/src/prototypes/style.lua
-- https://forums.factorio.com/viewtopic.php?p=495184#p495184

local gui = require('__flib__.gui')

local gui_data = nil

gui.register_handlers()

local function open_gui(player)
  player.force.research_queue_enabled = true

  gui_data = gui.build(player.gui.screen, {
    {type='frame', style='rq_main_window', direction='vertical', save_as='window', children={
      {type='flow', save_as='titlebar', children={
        {template='frame_title', caption='Research Queue'},
        {template='titlebar_drag_handle'},
        {template='frame_action_button', sprite='utility/refresh', handlers='refresh_button'},
        {template='frame_action_button', sprite='utility/close_white', hovered_sprite='utility/close_black', clicked_sprite='utility/close_black', handlers='close_button'},
      }},
      {type='flow', style='horizontal_flow', style_mods={horizontal_spacing=12}, children={
        {type='scroll-pane', vertical_scroll_policy='auto-and-reserve-space', style='rq_queue_list_box', save_as='queue'},
        {type='scroll-pane', vertical_scroll_policy='auto-and-reserve-space', style='rq_techs_list_box', children={
          {type='table', column_count=4, save_as='techs'},
        }},
      }},
    }},
  })

  gui_data.window.force_auto_center()
  gui_data.titlebar.drag_target = gui_data.window
end

local function close_gui(player)
  gui_data.window.visible = false
end

local function update_queue(player)
  gui_data.queue.clear()
  for idx, tech in pairs(player.force.research_queue) do
    gui.build(gui_data.queue, {
      gui.templates.tech_queue_item(idx, tech),
    })
  end
end

local function update_techs(player)
  gui_data.techs.clear()
  for _, tech in pairs(game.technology_prototypes) do
    gui.build(gui_data.techs, {
      gui.templates.tech_list_item(tech),
    })
  end
end

gui.add_templates{
  frame_action_button = {type='sprite-button', style='frame_action_button', mouse_button_filter={'left'}},
  tool_button = {type='sprite-button', style='tool_button', mouse_button_filter={'left'}},
  frame_title = {type='label', style='frame_title', elem_mods={ignored_by_interaction=true}},
  titlebar_drag_handle = {type='empty-widget', style='flib_titlebar_drag_handle', elem_mods={ignored_by_interaction=true}},
  tech_queue_item = function(idx, tech)
    return {type='label', caption=tech.name}
  end,
  tech_list_item = function(tech)
    return
      {type='frame', style='rq_tech_list_item', children={
        {type='flow', direction='vertical', children={
          {type='sprite-button', sprite='technology/'..tech.name, style='rq_tech_button'},
          {type='flow', direction='horizontal', style='rq_tech_item_tool_bar', children={
            {template='tool_button', sprite='rq-enqueue-last', handlers='enqueue_last_button', name='enqueue_last_button.'..tech.name},
            {template='tool_button', sprite='rq-enqueue-second', handlers='enqueue_second_button', name='enqueue_second_button.'..tech.name},
            {template='tool_button', sprite='rq-enqueue-first', handlers='enqueue_first_button', name='enqueue_first_button.'..tech.name},
          }},
        }},
      }}
  end,
}

gui.add_handlers{
  close_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      close_gui(player)
    end,
  },
  refresh_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      update_queue(player)
      update_techs(player)
    end,
  },
  enqueue_last_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      local _, _, tech_name = string.find(event.element.name, '^enqueue_last_button%.(.+)$')
      local tech = game.technology_prototypes[tech_name]
      player.print('enqueue last '..tech.name)
    end,
  },
  enqueue_second_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      local _, _, tech_name = string.find(event.element.name, '^enqueue_second_button%.(.+)$')
      local tech = game.technology_prototypes[tech_name]
      player.print('enqueue second '..tech.name)
    end,
  },
  enqueue_first_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      local _, _, tech_name = string.find(event.element.name, '^enqueue_first_button%.(.+)$')
      local tech = game.technology_prototypes[tech_name]
      player.print('enqueue first '..tech.name)
    end,
  },
}

script.on_init(function()
  gui.init()
  gui.build_lookup_tables()
end)

script.on_load(function()
  gui.build_lookup_tables()
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name == 'sonaxaton-research-queue' then
    local player = game.players[event.player_index]
    if player ~= nil then
      open_gui(player)
    end
  end
end)

script.on_event('sonaxaton-research-queue', function(event)
  local player = game.players[event.player_index]
  if player ~= nil then
    open_gui(player)
  end
end)
