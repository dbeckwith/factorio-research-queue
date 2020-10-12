local guilib = require('__flib__.gui')

local queue = require('.queue')

local function create_guis(player)
  local gui_data = guilib.build(player.gui.screen, {
    {type='frame', style='rq_main_window', direction='vertical', save_as='window', children={
      {type='flow', save_as='titlebar', children={
        {template='frame_title', caption='Research Queue'},
        {template='titlebar_drag_handle'},
        {template='frame_action_button', sprite='rq-enqueue-first', handlers='research_button'},
        {template='frame_action_button', sprite='utility/refresh', handlers='refresh_button'},
        {template='frame_action_button', sprite='utility/close_white', hovered_sprite='utility/close_black', clicked_sprite='utility/close_black', handlers='close_button'},
      }},
      {type='flow', style='horizontal_flow', style_mods={horizontal_spacing=12}, children={
        {type='scroll-pane', vertical_scroll_policy='auto-and-reserve-space', style='rq_tech_queue_list_box', save_as='queue'},
        {type='scroll-pane', vertical_scroll_policy='auto-and-reserve-space', style='rq_tech_list_list_box', children={
          {type='table', column_count=4, save_as='techs'},
        }},
      }},
    }},
  })

  gui_data.window.force_auto_center()
  gui_data.titlebar.drag_target = gui_data.window

  local force = player.force
  gui_data.techs.clear()
  for _, tech in pairs(force.technologies) do
    guilib.build(gui_data.techs, {
      guilib.templates.tech_list_item(tech),
    })
  end

  global.players[player.index].gui = gui_data
end

local function destroy_guis(player)
  local player_data = global.players[player.index]
  player_data.gui.window.destroy()
  player_data.gui = nil
end

local function open(player)
  local player_data = global.players[player.index]
  player_data.gui.window.visible = true
end

local function close(player)
  local player_data = global.players[player.index]
  player_data.gui.window.visible = false
end

local function update_queue(player)
  local player_data = global.players[player.index]
  local gui_data = player_data.gui
  gui_data.queue.clear()
  for tech in queue.iter(player) do
    guilib.build(gui_data.queue, {
      guilib.templates.tech_queue_item(tech),
    })
  end
end

guilib.add_templates{
  frame_action_button = {type='sprite-button', style='frame_action_button', mouse_button_filter={'left'}},
  tool_button = {type='sprite-button', style='tool_button', mouse_button_filter={'left'}},
  frame_title = {type='label', style='frame_title', elem_mods={ignored_by_interaction=true}},
  titlebar_drag_handle = {type='empty-widget', style='flib_titlebar_drag_handle', elem_mods={ignored_by_interaction=true}},
  tech_queue_item = function(tech)
    return
      {type='frame', style='rq_tech_queue_item', children={
        {type='flow', direction='horizontal', style='rq_tech_queue_item_content', children={
          {type='label', caption=tech.name},
          {type='empty-widget', style='flib_horizontal_pusher'},
          {template='tool_button', sprite='utility/close_black', handlers='dequeue_button', name='dequeue_button.'..tech.name, tooltip={'sonaxaton-research-queue.dequeue-button-tooltip', tech.localised_name}},
        }}
      }}
  end,
  tech_list_item = function(tech)
    return
      {type='frame', style='rq_tech_list_item', children={
        {type='flow', direction='vertical', children={
          {type='sprite-button', sprite='technology/'..tech.name, style='rq_tech_list_item_button', handlers='tech_button', name='tech_button.'..tech.name, tooltip={'sonaxaton-research-queue.tech-button-tooltip', tech.localised_name}},
          {type='flow', direction='horizontal', style='rq_tech_list_item_tool_bar', children={
            {template='tool_button', sprite='rq-enqueue-last', handlers='enqueue_last_button', name='enqueue_last_button.'..tech.name, tooltip={'sonaxaton-research-queue.enqueue-last-button-tooltip', tech.localised_name}},
            {template='tool_button', sprite='rq-enqueue-second', handlers='enqueue_second_button', name='enqueue_second_button.'..tech.name, tooltip={'sonaxaton-research-queue.enqueue-second-button-tooltip', tech.localised_name}},
            {template='tool_button', sprite='rq-enqueue-first', handlers='enqueue_first_button', name='enqueue_first_button.'..tech.name, tooltip={'sonaxaton-research-queue.enqueue-first-button-tooltip', tech.localised_name}},
          }},
        }},
      }}
  end,
}

guilib.add_handlers{
  close_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      close(player)
    end,
  },
  refresh_button = {
    on_gui_click = function(event)
      log('refresh_button')
      local player = game.players[event.player_index]
    end,
  },
  research_button = {
    on_gui_click = function(event)
      log('research_button')
      local player = game.players[event.player_index]
    end,
  },
  tech_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      local _, _, tech_name = string.find(event.element.name, '^tech_button%.(.+)$')
      player.open_technology_gui(tech_name)
    end,
  },
  enqueue_last_button = {
    on_gui_click = function(event)
      log('enqueue_last_button')
      local player = game.players[event.player_index]
      local _, _, tech_name = string.find(event.element.name, '^enqueue_last_button%.(.+)$')
      local force = player.force
      local tech = force.technologies[tech_name]
      log('enqueue last '..tech.name)
      queue.enqueue(player, tech)
      log('queue:')
      for tech in queue.iter(player) do
        log('\t'..tech.name)
      end
      update_queue(player)
    end,
  },
  enqueue_second_button = {
    on_gui_click = function(event)
      log('enqueue_second_button')
      local player = game.players[event.player_index]
    end,
  },
  enqueue_first_button = {
    on_gui_click = function(event)
      log('enqueue_first_button')
      local player = game.players[event.player_index]
      local _, _, tech_name = string.find(event.element.name, '^enqueue_first_button%.(.+)$')
      local force = player.force
      local tech = force.technologies[tech_name]
      log('enqueue first '..tech.name)
      queue.enqueue_head(player, tech)
      log('queue:')
      for tech in queue.iter(player) do
        log('\t'..tech.name)
      end
      update_queue(player)
    end,
  },
  dequeue_button = {
    on_gui_click = function(event)
      log('dequeue_button')
      local player = game.players[event.player_index]
      local _, _, tech_name = string.find(event.element.name, '^dequeue_button%.(.+)$')
      local force = player.force
      local tech = force.technologies[tech_name]
      log('dequeue '..tech.name)
      queue.dequeue(player, tech)
      log('queue:')
      for tech in queue.iter(player) do
        log('\t'..tech.name)
      end
      update_queue(player)
    end,
  },
}

return {
  create_guis = create_guis,
  destroy_guis = destroy_guis,
  open = open,
  close = close,
}
