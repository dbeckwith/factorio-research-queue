local futil = require('__core__/lualib/util')

local eventlib = require('__flib__.event')
local guilib = require('__flib__.gui')
local translationlib = require('__flib__.translation')

local queue = require('.queue')
local rqtech = require('.rqtech')
local util = require('.util')

local function can_pause_game(player)
  if not settings.get_player_settings(player)['rq-pause-game'].value then
    return false
  end
  if game.is_multiplayer() then
    return false
  end
  if player.controller_type == defines.controllers.editor then
    return false
  end
  return true
end

local function update_etcs(player)
  local player_data = global.players[player.index]
  local gui_data = player_data.gui
  local force = player.force

  if not gui_data.window.valid then return end

  local speed = player_data.last_research_speed_estimate or 0
  local etc = 0
  local tech_ingredient_totals = {}
  for tech in queue.iter(force) do
    local progress = rqtech.progress(tech)

    local etc_text = ''
    if speed == 0 then
      etc_text = etc_text..'[img=infinity]'
    else
      etc = etc +
        (1-progress) *
        (tech.tech.research_unit_energy/60) *
        tech.research_unit_count /
        speed
      etc_text = etc_text..util.format_duration(etc)
    end
    gui_data.etc_labels[tech.id].caption = etc_text

    for _, ingredient in ipairs(tech.tech.research_unit_ingredients) do
      tech_ingredient_totals[ingredient.name] =
        (tech_ingredient_totals[ingredient.name] or 0) +
        (1-progress) *
        tech.research_unit_count *
        ingredient.amount
    end

    local tech_ingredient_totals_text = '[font=count-font]'
    for _, ingredient in ipairs(player_data.tech_ingredients) do
      amount = tech_ingredient_totals[ingredient.name]
      if amount ~= nil and amount ~= 0 then
        tech_ingredient_totals_text = tech_ingredient_totals_text ..
          string.format(
            '[img=%s/%s]%d ',
            'item',
            ingredient.name,
            amount)
      end
    end
    tech_ingredient_totals_text = tech_ingredient_totals_text..'[/font]'
    gui_data.etc_labels[tech.id].tooltip = {'',
      {'sonaxaton-research-queue.etc-label-tooltip', etc_text},
      '\n',
      {'sonaxaton-research-queue.tech-ingredient-totals-tooltip',
        tech_ingredient_totals_text}}
  end
end

local function update_progressbars(player)
  local player_data = global.players[player.index]
  local gui_data = player_data.gui
  local force = player.force

  if not gui_data.window.valid then return end

  for _, progressbars in ipairs{
    gui_data.tech_list_progressbars,
    gui_data.tech_queue_progressbars,
  } do
    for tech_id, progressbar in pairs(progressbars) do
      local tech = rqtech.from_id(force, tech_id)
      local progress = rqtech.progress(tech)
      progressbar.value = progress
      progressbar.visible = progress > 0
    end
  end
end

local function update_queue(player, new_tech)
  local player_data = global.players[player.index]
  local gui_data = player_data.gui
  local force = player.force

  if not gui_data.window.valid then return end

  gui_data.queue_head.clear()
  gui_data.queue.clear()
  gui_data.etc_labels = nil
  gui_data.tech_queue_progressbars = nil
  local is_head = true
  if queue.is_paused(force) then
    gui_data.queue_pause_toggle_button.style = 'rq_frame_action_button_green'
    gui_data.queue_pause_toggle_button.sprite = 'rq-play-white'
    gui_data.queue_pause_toggle_button.hovered_sprite = 'rq-play-black'
    gui_data.queue_pause_toggle_button.clicked_sprite = 'rq-play-black'
    gui_data.queue_pause_toggle_button.tooltip = {'sonaxaton-research-queue.queue-play-button-tooltip'}
    guilib.build(gui_data.queue_head, {
      {
        type = 'flow',
        style = 'rq_tech_queue_item_paused',
        children = {
          {
            type = 'sprite-button',
            style = 'rq_tech_queue_item_paused_unpause_button',
            handlers = 'queue_pause_toggle_button',
            sprite = 'rq-play-black',
            tooltip = {'sonaxaton-research-queue.queue-play-button-tooltip'},
            mouse_button_filter = {'left'},
          },
        },
      },
    })
    is_head = false
  else
    gui_data.queue_pause_toggle_button.style = 'rq_frame_action_button_red'
    gui_data.queue_pause_toggle_button.sprite = 'rq-pause-white'
    gui_data.queue_pause_toggle_button.hovered_sprite = 'rq-pause-black'
    gui_data.queue_pause_toggle_button.clicked_sprite = 'rq-pause-black'
    gui_data.queue_pause_toggle_button.tooltip = {'sonaxaton-research-queue.queue-pause-button-tooltip'}
  end
  local new_tech_element = nil
  local items_gui_data = {}
  for tech in queue.iter(force) do
    local item_gui_data = guilib.build(gui_data[is_head and 'queue_head' or 'queue'], {
      guilib.templates.tech_queue_item(player, tech, is_head),
    })
    items_gui_data = futil.merge{items_gui_data, item_gui_data}
    if new_tech ~= nil and new_tech.id == tech.id then
      if not is_head then
        new_tech_element = gui_data.queue.children[#gui_data.queue.children]
      else
        new_tech_element = 'head'
      end
    end
    is_head = false
  end
  player_data.gui = futil.merge{player_data.gui, items_gui_data}
  gui_data = player_data.gui

  if new_tech_element ~= nil then
    if new_tech_element == 'head' then
      gui_data.queue.scroll_to_top()
    else
      gui_data.queue.scroll_to_element(new_tech_element, 'top-third')
    end
  end

  update_etcs(player)
end

local function get_localised_string_key(player, localised_string)
  return translationlib.serialise_localised_string(localised_string)
end

local function on_tick_translation_handler(event)
  if translationlib.translating_players_count() > 0 then
    translationlib.iterate_batch(event)
  else
    eventlib.on_tick(nil)
  end
end

local function register_translation_handler()
  if translationlib.translating_players_count() > 0 then
    eventlib.on_tick(on_tick_translation_handler)
  end
end

local function update_techs(player)
  local player_data = global.players[player.index]
  local gui_data = player_data.gui
  local filter_data = player_data.filter
  local tech_ingredients = player_data.tech_ingredients
  local force = player.force

  if not gui_data.window.valid then return end

  do
    local enabled = filter_data.researched
    gui_data.researched_techs_checkbox.state = enabled
  end

  gui_data.tech_ingredient_filter_table.clear()
  for _, tech_ingredient in ipairs(tech_ingredients) do
    local enabled = filter_data.ingredients[tech_ingredient.name]
    guilib.build(gui_data.tech_ingredient_filter_table, {
      {
        name = 'tech_ingredient_filter_button.'..tech_ingredient.name,
        type = 'sprite-button',
        style =
          'rq_tech_ingredient_filter_button_' ..
            (enabled and 'enabled' or 'disabled'),
        handlers = 'tech_ingredient_filter_button',
        sprite = string.format('%s/%s', 'item', tech_ingredient.name),
        tooltip = {
          'sonaxaton-research-queue.tech-ingredient-filter-button-' ..
            (enabled and 'enabled' or 'disabled'),
          tech_ingredient.localised_name,
        },
        mouse_button_filter = {'left'},
      },
    })
  end

  local techs_list = {}
  local techs_set = {}
  for tech in rqtech.iter(force) do
    local function is_tech_visible(tech)
      if tech.tech.prototype.hidden or not tech.tech.enabled then
        return false
      end

      if not filter_data.researched and rqtech.is_researched(tech) then
        return false
      end

      if tech.tech.upgrade or tech.infinite then
        -- only include upgrade techs if they have a "significant" dependency
        local has_significant_dependency = (function()
          for _, dependency in pairs(tech.prerequisites) do
            local is_significant_dependency = (function()
              -- significant if not an upgrade or infinite
              if not (dependency.tech.upgrade or dependency.infinite) then
                return true
              end

              -- is an upgrade
              -- significant if not in the same group
              if tech.upgrade_group ~= dependency.upgrade_group then
                return true
              end

              -- is an upgrade and in the same group
              -- significant if researched
              if rqtech.is_researched(dependency) then
                return true
              end

              -- is an upgrade, in the same group, and not researched
              -- significant if in the queue
              if queue.in_queue(force, dependency) then
                return true
              end

              return false
            end)()
            if is_significant_dependency then return true end
          end
          return false
        end)()
        if not has_significant_dependency then
          -- if upgrades are hidden
          if not filter_data.upgrades then
            -- hide
            return false
          end

          -- upgrades are not hidden
          -- if the tech is infinite, still hide
          if tech.infinite then
            return false
          end
        end
      end

      local ingredients_filter = filter_data.ingredients
      for _, ingredient in pairs(tech.tech.research_unit_ingredients) do
        if not ingredients_filter[ingredient.name] then
          return false
        end
      end

      local search_terms = filter_data.search_terms
      local search_matches = (function()
        if #search_terms == 0 then
          return true
        end

        local strings = player_data.translations[tech.tech.name] or {}

        if next(strings) == nil then
          -- nothing translated yet, just call it a match
          return true
        end

        for _, s in pairs(strings) do
          if util.fuzzy_search(s, search_terms) then
            return true
          end
        end

        return false
      end)()
      if not search_matches then
        return false
      end

      return true
    end

    local function add_tech(tech)
      local visible = is_tech_visible(tech)
      if visible then
        table.insert(techs_list, tech)
        techs_set[tech.id] = true
      end

      if
        (visible or rqtech.is_researched(tech)) and
        tech.infinite and
        tech.level + 1 <= tech.tech.prototype.max_level
      then
        local next_level_tech = rqtech.new(tech.tech, tech.level + 1)
        add_tech(next_level_tech)
      end
    end

    add_tech(tech)
  end
  util.sort_by_key(techs_list, function(tech)
    local ingredients = {}
    for i, tech_ingredient in ipairs(tech_ingredients) do
      local has = false
      for _, ingredient in ipairs(tech.tech.research_unit_ingredients) do
        if tech_ingredient.name == ingredient.name then
          has = true
          break
        end
      end
      ingredients[#tech_ingredients+1-i] = has
    end
    return {
      ingredients,
      tech.research_unit_count,
      tech.tech.order,
      tech.tech.name,
      tech.level,
    }
  end)
  do
    local topo_set = {}
    local topo_list = {}
    local function add(tech)
      if topo_set[tech.id] then return end
      if not techs_set[tech.id] then return end
      for _, dep in pairs(tech.prerequisites) do
        add(dep)
      end
      table.insert(topo_list, tech)
      topo_set[tech.id] = true
    end
    for _, tech in ipairs(techs_list) do
      add(tech)
    end
    tech_list = topo_list
  end
  gui_data.techs.clear()
  gui_data.tech_list_progressbars = nil
  local items_gui_data = {}
  for _, tech in ipairs(techs_list) do
    local item_gui_data = guilib.build(gui_data.techs, {
      guilib.templates.tech_list_item(player, tech),
    })
    items_gui_data = futil.merge{items_gui_data, item_gui_data}
  end
  player_data.gui = futil.merge{player_data.gui, items_gui_data}
end

local function update_search(player)
  local player_data = global.players[player.index]
  local gui_data = player_data.gui
  local filter_data = player_data.filter

  if not gui_data.window.valid then return end

  local search_text = gui_data.search.text
  filter_data.search_terms = util.prepare_search_terms(search_text)
end

local function toggle_researched_filter(player)
  local player_data = global.players[player.index]
  local filter_data = player_data.filter

  local enabled = filter_data.researched
  enabled = not enabled
  filter_data.researched = enabled
end

local function toggle_upgrade_filter(player)
  local player_data = global.players[player.index]
  local filter_data = player_data.filter

  local enabled = filter_data.upgrades
  enabled = not enabled
  filter_data.upgrades = enabled
end

local function toggle_ingredient_filter(player, item)
  local player_data = global.players[player.index]
  local filter_data = player_data.filter

  local enabled = filter_data.ingredients[item.name]
  enabled = not enabled
  filter_data.ingredients[item.name] = enabled
end

local function auto_select_tech_ingredients(player)
  local player_data = global.players[player.index]
  local filter_data = player_data.filter
  local tech_ingredients = player_data.tech_ingredients

  for _, tech_ingredient in ipairs(tech_ingredients) do
    filter_data.ingredients[tech_ingredient.name] = util.is_item_available(player.force, tech_ingredient.name)
  end
end

local function create_guis(player)
  local gui_data = guilib.build(player.gui.screen, {
    {
      save_as = 'window',
      type = 'frame',
      style = 'outer_frame',
      handlers = 'window',
      elem_mods = {
        visible = false,
      },
      children = {
        {
          type = 'frame',
          style = 'rq_main_window',
          direction = 'vertical',
          children = {
            {
              save_as = 'main_titlebar',
              type = 'flow',
              children = {
                {
                  template = 'frame_title',
                  caption = {'sonaxaton-research-queue.window-title'},
                },
                {
                  template = 'titlebar_drag_handle',
                },
                {
                  save_as = 'search',
                  type = 'textfield',
                  handlers = 'search',
                  clear_and_focus_on_right_click = true,
                  elem_mods = {
                    visible = false,
                  },
                  tooltip = {'sonaxaton-research-queue.search-tooltip'},
                },
                {
                  save_as = 'search_toggle_button',
                  template = 'frame_action_button',
                  handlers = 'search_toggle_button',
                  sprite = 'utility/search_white',
                  hovered_sprite = 'utility/search_black',
                  clicked_sprite = 'utility/search_black',
                  tooltip = {'sonaxaton-research-queue.search-tooltip'},
                },
                {
                  save_as = 'queue_pause_toggle_button',
                  template = 'frame_action_button',
                  handlers = 'queue_pause_toggle_button',
                },
                {
                  save_as = 'queue_clear_button',
                  template = 'frame_action_button',
                  style = 'rq_frame_action_button_red',
                  handlers = 'queue_clear_button',
                  sprite = 'utility/trash_white',
                  hovered_sprite = 'utility/trash',
                  clicked_sprite = 'utility/trash',
                  tooltip = {'sonaxaton-research-queue.clear-tooltip'},
                },
                {
                  template = 'frame_action_button',
                  handlers = 'research_button',
                  sprite = 'rq-enqueue-first-white',
                  tooltip = '[[color=red]Cheat[/color]] Research current technology',
                  elem_mods = {
                    visible = __rq_debug,
                  },
                },
                {
                  template = 'frame_action_button',
                  handlers = 'refresh_button',
                  sprite = 'rq-refresh',
                  tooltip = '[[color=purple]Debug[/color]] Refresh data',
                  elem_mods = {
                    visible = __rq_debug,
                  },
                },
                {
                  template = 'frame_action_button',
                  handlers = 'close_button',
                  sprite = 'utility/close_white',
                  hovered_sprite = 'utility/close_black',
                  clicked_sprite = 'utility/close_black',
                  tooltip = {'sonaxaton-research-queue.close-tooltip'},
                },
              },
            },
            {
              type = 'flow',
              style = 'horizontal_flow',
              style_mods = {
                horizontal_spacing = 12,
              },
              direction = 'horizontal',
              children = {
                {
                  type = 'flow',
                  style = 'vertical_flow',
                  style_mods = {
                    vertical_spacing = 8,
                  },
                  direction = 'vertical',
                  children = {
                    {
                      save_as = 'queue_head',
                      type = 'frame',
                      style = 'rq_tech_queue_head_frame',
                    },
                    {
                      save_as = 'queue',
                      type = 'scroll-pane',
                      style = 'rq_tech_queue_list_box',
                      vertical_scroll_policy = 'always',
                    },
                  },
                },
                {
                  type = 'scroll-pane',
                  style = 'rq_tech_list_list_box',
                  vertical_scroll_policy = 'always',
                  children = {
                    {
                      save_as = 'techs',
                      type = 'table',
                      style = 'rq_tech_list_table',
                      column_count = 7,
                    },
                  },
                },
              },
            },
          },
        },
        {
          type = 'frame',
          style = 'rq_settings_window',
          direction = 'vertical',
          children = {
            {
              save_as = 'settings_titlebar',
              type = 'flow',
              children = {
                {
                  template = 'frame_title',
                  caption = {'sonaxaton-research-queue.settings-title'},
                },
                {
                  template = 'titlebar_drag_handle',
                },
              },
            },
            {
              type = 'flow',
              style = 'vertical_flow',
              style_mods = {
                vertical_spacing = 12,
              },
              direction = 'vertical',
              children = {
                {
                  save_as = 'researched_techs_checkbox',
                  type = 'checkbox',
                  handlers = 'researched_techs_checkbox',
                  caption = {'sonaxaton-research-queue.researched-techs-checkbox'},
                  state = false,
                },
                {
                  save_as = 'upgrade_techs_checkbox',
                  type = 'checkbox',
                  handlers = 'upgrade_techs_checkbox',
                  caption = {'sonaxaton-research-queue.upgrade-techs-checkbox'},
                  state = false,
                },
                {
                  type = 'frame',
                  style = 'rq_settings_section',
                  direction = 'vertical',
                  children = {
                    {
                      type = 'label',
                      style = 'caption_label',
                      caption = {'sonaxaton-research-queue.tech-ingredient-filter-table'},
                    },
                    {
                      type = 'scroll-pane',
                      style = 'rq_tech_ingredient_filter_table_scroll_box',
                      children = {
                        {
                          save_as = 'tech_ingredient_filter_table',
                          type = 'table',
                          column_count = 4,
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  })

  gui_data.window.force_auto_center()
  gui_data.main_titlebar.drag_target = gui_data.window
  gui_data.settings_titlebar.drag_target = gui_data.window

  local player_data = global.players[player.index]
  player_data.gui = gui_data
end

local function init(player)
  create_guis(player)

  local force = player.force

  local tech_ingredients = {}
  for _, item in pairs(game.get_filtered_item_prototypes{{filter='tool'}}) do
    local is_tech_ingredient = (function()
      for _, tech in pairs(force.technologies) do
        if tech.enabled then
          for _, ingredient in pairs(tech.research_unit_ingredients) do
            if ingredient.type == 'item' and ingredient.name == item.name then
              return true
            end
          end
        end
      end
      return false
    end)()
    if is_tech_ingredient then
      table.insert(tech_ingredients, item)
    end
  end
  table.sort(tech_ingredients, function(a, b) return a.order < b.order end)

  local filter_data = {
    researched = false,
    upgrades = false,
    ingredients = {},
    search_terms = {},
  }

  local player_data = global.players[player.index]
  player_data.filter = filter_data
  player_data.tech_ingredients = tech_ingredients
  player_data.translations = {}

  do
    local requests = {}

    for _, tech in pairs(force.technologies) do
      local function add_request(localised_string)
        local key = get_localised_string_key(player, localised_string)
        local request = {
          dictionary = tech.name,
          internal = key,
          localised = localised_string,
        }
        table.insert(requests, request)
      end

      add_request(tech.localised_name)
      add_request(tech.localised_description)
      for _, effect in ipairs(tech.effects) do
        if effect.type == 'nothing' then
          add_request(effect.effect_description)
        elseif effect.type == 'give-item' then
          local item = game.item_prototypes[effect.item]
          add_request(item.localised_name)
          -- add_request(item.localised_description)
        elseif effect.type == 'unlock-recipe' then
          local recipe = game.recipe_prototypes[effect.recipe]
          add_request(recipe.localised_name)
          -- add_request(recipe.localised_description)
        elseif effect.type == 'gun-speed' then
          local ammo_category = game.ammo_category_prototypes[effect.ammo_category]
          add_request(ammo_category.localised_name)
          -- add_request(ammo_category.localised_description)
        elseif effect.type == 'turret-attack' then
          local entity = game.entity_prototypes[effect.turret_id]
          add_request(entity.localised_name)
          -- add_request(entity.localised_description)
        else
          add_request{'modifier-description.'..effect.type, effect.modifier}
        end
      end
    end

    translationlib.add_requests(player.index, requests)
    register_translation_handler()
  end

  auto_select_tech_ingredients(player)
  update_queue(player)
  update_techs(player)
end

local function deinit(player)
  local player_data = global.players[player.index]
  local gui_data = player_data.gui

  if gui_data.window.valid then
    if gui_data.window.visible and can_pause_game(player) then
      game.tick_paused = false
    end

    gui_data.window.destroy()
  end

  player_data.gui = nil
  player_data.filter = nil
  player_data.translations = nil
  player_data.tech_ingredients = nil
  player_data.closed_tick = nil
  player_data.last_research_speed_estimate = nil
end

local function focus_search(player)
  local player_data = global.players[player.index]
  local gui_data = player_data.gui

  if not gui_data.window.valid then return end

  if gui_data.window.visible then
    if not gui_data.search.visible then
      gui_data.search_toggle_button.style = 'flib_selected_frame_action_button'
      gui_data.search.visible = true
      gui_data.search.focus()
      gui_data.search.select_all()
    else
      gui_data.search.focus()
      gui_data.search.select_all()
    end
  end
end

local function toggle_search(player)
  local player_data = global.players[player.index]
  local gui_data = player_data.gui

  if not gui_data.window.valid then return end

  if gui_data.window.visible then
    if not gui_data.search.visible then
      gui_data.search_toggle_button.style = 'flib_selected_frame_action_button'
      gui_data.search.visible = true
      gui_data.search.focus()
      gui_data.search.select_all()
    else
      gui_data.search_toggle_button.style = 'frame_action_button'
      gui_data.search.visible = false
      gui_data.search.text = ''
      update_search(player)
      update_techs(player)
    end
  end
end

local function open(player)
  local player_data = global.players[player.index]
  local gui_data = player_data.gui

  if not gui_data.window.valid then
    create_guis(player)
    gui_data = player_data.gui
  end

  gui_data.window.visible = true
  player.opened = gui_data.window
  player.set_shortcut_toggled('sonaxaton-research-queue', true)
  if gui_data.search.visible then
    gui_data.search.focus()
    gui_data.search.select_all()
  end
  if can_pause_game(player) then
    game.tick_paused = true
  end

  update_search(player)
  update_queue(player)
  update_techs(player)
end

local function close(player)
  local player_data = global.players[player.index]
  local gui_data = player_data.gui

  if gui_data.window.valid then
    gui_data.window.visible = false
    if player.opened == gui_data.window then
      player.opened = nil
    end
    player_data.closed_tick = game.tick
    if can_pause_game(player) then
      game.tick_paused = false
    end
  end
  player.set_shortcut_toggled('sonaxaton-research-queue', false)
end

local function toggle(player)
  local player_data = global.players[player.index]
  local gui_data = player_data.gui

  if gui_data.window.valid and gui_data.window.visible then
    close(player)
  else
    open(player)
  end
end

local function on_technology_gui_opened(player)
  local player_data = global.players[player.index]
  local gui_data = player_data.gui

  if gui_data.window.valid and player_data.closed_tick == game.tick then
    -- if the window was closed in the same tick that the tech gui was opened,
    -- keep the window visible in the background
    -- when the tech gui is closed, the window will be officially opened and
    -- made the opened gui of the player
    gui_data.window.visible = true
  end
end

local function on_technology_gui_closed(player)
  local player_data = global.players[player.index]
  local gui_data = player_data.gui
  local force = player.force

  queue.set_paused(force, force.current_research == nil)
  queue.update(force)
  for _, player in pairs(force.players) do
    update_queue(player)
    update_techs(player)
  end

  if gui_data.window.valid and gui_data.window.visible then
    -- after the tech gui is closed, if the window was still visible, make it
    -- the official opened gui of the player
    open(player)
  end
end

local function on_research_started(force, tech, last_tech)
  tech = rqtech.new(tech, 'current')
  if not queue.is_head(force, tech, true) then
    queue.set_paused(force, false)
    queue.enqueue_head(force, tech)
    queue.update(force)
    for _, player in pairs(force.players) do
      update_queue(player, tech)
    end
  end
end

local function on_research_finished(force, tech)
  tech = rqtech.new(tech, 'previous')
  queue.update(force)
  for _, player in pairs(force.players) do
    local player_data = global.players[player.index]
    local filter_data = player_data.filter
    local tech_ingredients = player_data.tech_ingredients

    if settings.get_player_settings(player)['rq-notifications'].value then
      player.print{'sonaxaton-research-queue.notification', tech.tech.name}
    end

    for _, tech_ingredient in ipairs(tech_ingredients) do
      if not filter_data.ingredients[tech_ingredient.name] then
        local newly_available = (function()
          for _, effect in pairs(tech.tech.effects) do
            if effect.type == 'unlock-recipe' then
              if util.is_item_available(force, tech_ingredient.name, effect.recipe) then
                return true
              end
            end
          end
          return false
        end)()
        if newly_available then
          filter_data.ingredients[tech_ingredient.name] = true
        end
      end
    end

    update_queue(player)
    update_techs(player)
  end
end

local function on_research_speed_estimate(force, speed)
  for _, player in pairs(force.players) do
    local player_data = global.players[player.index]
    local gui_data = player_data.gui

    player_data.last_research_speed_estimate = speed

    if gui_data.window.valid and gui_data.window.visible then
      update_etcs(player)
      update_progressbars(player)
    end
  end
end

local function on_string_translated(player, event)
  local player_data = global.players[player.index]
  local translation_data = player_data.translations

  local sort_data, finished = translationlib.process_result(event)

  if sort_data then
    local player_data = global.players[player.index]
    local translation_data = player_data.translations

    if event.translated then
      for tech_name, keys in pairs(sort_data) do
        for _, key in ipairs(keys) do
          local result = event.result
          if translation_data[tech_name] == nil then
            translation_data[tech_name] = {}
          end
          translation_data[tech_name][key] = result
        end
      end
    end

    if finished then
      update_techs(player)
    end
  end
end

local function update(player)
  update_queue(player)
  update_techs(player)
end

guilib.add_templates{
  frame_action_button = {
    type = 'sprite-button',
    style = 'frame_action_button',
    mouse_button_filter = {'left'},
  },
  tool_button = {
    type = 'sprite-button',
    style = 'tool_button',
    mouse_button_filter = {'left'},
  },
  frame_title = {
    type = 'label',
    style = 'frame_title',
    elem_mods = {
      ignored_by_interaction = true,
    },
  },
  titlebar_drag_handle = {
    type = 'empty-widget',
    style = 'flib_titlebar_drag_handle',
    elem_mods = {
      ignored_by_interaction = true,
    },
  },
  tech_button = function(tech, style)
    local researched = rqtech.is_researched(tech)
    local progress = rqtech.progress(tech)
    if researched then progress = 0 end
    local list_type =
      string.find(style, '^rq_tech_list') and
        'tech_list' or
        'tech_queue'

    local cost = '[[font=count-font]'
    for _, ingredient in ipairs(tech.tech.research_unit_ingredients) do
      cost = cost .. string.format(
        '[img=%s/%s]%d ',
        ingredient.type,
        ingredient.name,
        ingredient.amount)
    end
    cost = cost .. string.format(
      '[img=quantity-time]%d[/font]][font=count-font][img=quantity-multiplier]%d[/font]',
      tech.tech.research_unit_energy / 60,
      tech.research_unit_count)

    local tooltip_lines = {
      {'', '[font=heading-2]', tech.tech.localised_name, '[/font]'},
      tech.tech.localised_description,
      cost}
    if not researched then
      table.insert(tooltip_lines, {'sonaxaton-research-queue.tech-button-enqueue-last'})
      table.insert(tooltip_lines, {'sonaxaton-research-queue.tech-button-enqueue-second'})
      table.insert(tooltip_lines, {'sonaxaton-research-queue.tech-button-dequeue'})
    end
    table.insert(tooltip_lines, {'sonaxaton-research-queue.tech-button-open'})
    local tooltip = {}
    local first = true
    for _, line in ipairs(tooltip_lines) do
      if first then
        table.insert(tooltip, '')
      else
        table.insert(tooltip, '\n')
      end
      table.insert(tooltip, line)
      first = false
    end

    local level = tech.level

    return {
      type = 'flow',
      style = 'rq_tech_button_container_'..list_type,
      direction = 'vertical',
      children = {
        {
          name = 'tech_button.'..tech.id,
          type = 'sprite-button',
          style = style,
          handlers = 'tech_button',
          sprite = 'technology/'..tech.tech.name,
          tooltip = tooltip,
          number = level,
          mouse_button_filter = {'left', 'right'},
        },
        {
          save_as = list_type..'_progressbars.'..tech.id,
          type = 'progressbar',
          style = 'rq_tech_button_progressbar_'..list_type,
          value = progress,
          visible = progress > 0,
        },
      },
    }
  end,
  tech_queue_item = function(player, tech, is_head)
    local force = player.force
    local shift_up_enabled = queue.can_shift_earlier(force, tech)
    local shift_down_enabled = queue.can_shift_later(force, tech)
    return
      {
        type = 'frame',
        style = 'rq_tech_queue_item',
        direction = 'horizontal',
        children = {
          {
            type = 'flow',
            style = 'rq_tech_queue_item_inner_flow',
            direction = 'vertical',
            children = {
              guilib.templates.tech_button(
                tech,
                'rq_tech_queue'..(is_head and '_head' or '')..'_item_tech_button'),
              {
                save_as = 'etc_labels.'..tech.id,
                type = 'label',
                style = 'rq_etc_label',
                caption = '[img=quantity-time][img=infinity]',
                tooltip = {'sonaxaton-research-queue.etc-label-tooltip'},
              },
            },
          },
          {
            type = 'flow',
            style = 'rq_tech_queue_item_buttons',
            direction = 'vertical',
            children = {
              {
                name = 'shift_up_button.'..tech.id,
                type = 'button',
                style = 'rq_tech_queue_item_shift_up_button',
                handlers = 'shift_up_button',
                tooltip =
                  shift_up_enabled and
                    {'sonaxaton-research-queue.shift-up-button-tooltip', tech.tech.localised_name} or
                    nil,
                enabled = shift_up_enabled,
                mouse_button_filter = {'left'},
              },
              {
                type = 'empty-widget',
                style = 'flib_vertical_pusher',
              },
              {
                name = 'dequeue_button.'..tech.id,
                template = 'tool_button',
                style = 'rq_tech_queue_item_close_button',
                handlers = 'dequeue_button',
                sprite = 'utility/close_black',
                tooltip = {'sonaxaton-research-queue.dequeue-button-tooltip', tech.tech.localised_name},
              },
              {
                type = 'empty-widget',
                style = 'flib_vertical_pusher',
              },
              {
                name = 'shift_down_button.'..tech.id,
                type = 'button',
                style = 'rq_tech_queue_item_shift_down_button',
                handlers = 'shift_down_button',
                tooltip =
                  shift_down_enabled and
                    {'sonaxaton-research-queue.shift-down-button-tooltip', tech.tech.localised_name} or
                    nil,
                enabled = shift_down_enabled,
                mouse_button_filter = {'left'},
              },
            },
          },
        },
      }
  end,
  tech_list_item = function(player, tech)
    local force = player.force
    local researchable = queue.is_researchable(force, tech)
    local queued = queue.in_queue(force, tech)
    local queued_head = not queue.is_paused(force) and queue.is_head(force, tech)
    local researched = rqtech.is_researched(tech)
    local available = (function()
      for _, prereq in pairs(tech.prerequisites) do
        if not rqtech.is_researched(prereq) then
          return false
        end
      end
      return true
    end)()
    local style_prefix =
      'rq_tech_list_item' ..
        (queued_head and '_queued_head' or
        queued and '_queued' or
        researched and '_researched' or
        available and '_available' or
        '_unavailable')
    local tech_list_tech_button_size = 64+8*2+8
    local ingredient_width = 16
    local ingredients = {}
    for _, ingredient in ipairs(tech.tech.research_unit_ingredients) do
      table.insert(ingredients, {
        type = 'sprite',
        style = 'rq_tech_list_item_ingredient',
        sprite = string.format('%s/%s', ingredient.type, ingredient.name),
      })
    end
    local ingredients_spacing = nil
    if #ingredients >= 2 then
      ingredients_spacing =
        (tech_list_tech_button_size - 8 - #ingredients*ingredient_width) /
          (#ingredients - 1)
      if ingredients_spacing > 0 then
        ingredients_spacing = 0
      end
    end
    return
      {
        type = 'flow',
        style = 'rq_tech_list_item',
        direction = 'vertical',
        children = {
          guilib.templates.tech_button(tech, style_prefix..'_tech_button'),
          {
            type = 'frame',
            style = style_prefix..'_ingredients_bar',
            direction = 'horizontal',
            children = {
              {
                type = 'flow',
                style = 'horizontal_flow',
                style_mods = {
                  horizontal_spacing = ingredients_spacing,
                },
                direction = 'horizontal',
                children = ingredients,
              },
            },
          },
          {
            type = 'frame',
            style = style_prefix..'_tool_bar',
            direction = 'horizontal',
            children = {
              {
                name = 'enqueue_last_button.'..tech.id,
                template = 'tool_button',
                style = 'rq_tech_list_item_tool_button',
                handlers = 'enqueue_last_button',
                sprite = 'rq-enqueue-last-black',
                tooltip = {'sonaxaton-research-queue.enqueue-last-button-tooltip', tech.tech.localised_name},
                enabled = researchable,
              },
              {
                name = 'enqueue_second_button.'..tech.id,
                template = 'tool_button',
                style = 'rq_tech_list_item_tool_button',
                handlers = 'enqueue_second_button',
                sprite = 'rq-enqueue-second-black',
                tooltip = {'sonaxaton-research-queue.enqueue-second-button-tooltip', tech.tech.localised_name},
                enabled = researchable,
              },
              {
                name = 'enqueue_first_button.'..tech.id,
                template = 'tool_button',
                style = 'rq_tech_list_item_tool_button',
                handlers = 'enqueue_first_button',
                sprite = 'rq-enqueue-first-black',
                tooltip = {'sonaxaton-research-queue.enqueue-first-button-tooltip', tech.tech.localised_name},
                enabled = researchable,
              },
            },
          },
        },
      }
  end,
}

guilib.add_handlers{
  window = {
    on_gui_closed = function(event)
      local player = game.players[event.player_index]
      close(player)
    end,
  },
  close_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      close(player)
    end,
  },
  refresh_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      update_search(player)
      update_queue(player)
      update_techs(player)
    end,
  },
  research_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      local force = player.force
      if force.current_research ~= nil then
        force.research_progress = 1
      end
    end,
  },
  researched_techs_checkbox = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      toggle_researched_filter(player)
      update_techs(player)
    end
  },
  upgrade_techs_checkbox = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      toggle_upgrade_filter(player)
      update_techs(player)
    end
  },
  tech_ingredient_filter_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      local item_name = string.match(event.element.name, '^tech_ingredient_filter_button%.(.+)$')
      local item = game.item_prototypes[item_name]
      toggle_ingredient_filter(player, item)
      update_techs(player)
    end,
  },
  search = {
    on_gui_text_changed = function(event)
      local player = game.players[event.player_index]
      update_search(player)
      update_techs(player)
    end,
  },
  search_toggle_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      toggle_search(player)
    end,
  },
  tech_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      local force = player.force
      local tech_id = string.match(event.element.name, '^tech_button%.(.+)$')
      local tech = rqtech.from_id(force, tech_id)
      if event.button == defines.mouse_button_type.left then
        if not event.shift and not event.control and not event.alt then
          if not rqtech.is_researched(tech) then
            queue.enqueue_tail(force, tech)
            queue.update(force)
            for _, player in pairs(force.players) do
              update_queue(player, tech)
              update_techs(player)
            end
          end
        elseif event.shift and not event.control and not event.alt then
          if not rqtech.is_researched(tech) then
            queue.enqueue_before_head(force, tech)
            queue.update(force)
            for _, player in pairs(force.players) do
              update_queue(player, tech)
              update_techs(player)
            end
          end
        elseif not event.shift and not event.control and event.alt then
          player.open_technology_gui(tech.tech.name)
        end
      elseif event.button == defines.mouse_button_type.right then
        if not event.shift and not event.control and not event.alt then
          if not rqtech.is_researched(tech) then
            queue.dequeue(force, tech)
            queue.update(force)
            for _, player in pairs(force.players) do
              update_queue(player)
              update_techs(player)
            end
          end
        end
      end
    end,
  },
  enqueue_last_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      local force = player.force
      local tech_id = string.match(event.element.name, '^enqueue_last_button%.(.+)$')
      local tech = rqtech.from_id(force, tech_id)
      queue.enqueue_tail(force, tech)
      queue.update(force)
      for _, player in pairs(force.players) do
        update_queue(player, tech)
        update_techs(player)
      end
    end,
  },
  enqueue_second_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      local force = player.force
      local tech_id = string.match(event.element.name, '^enqueue_second_button%.(.+)$')
      local tech = rqtech.from_id(force, tech_id)
      queue.enqueue_before_head(force, tech)
      queue.update(force)
      for _, player in pairs(force.players) do
        update_queue(player, tech)
        update_techs(player)
      end
    end,
  },
  enqueue_first_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      local force = player.force
      local tech_id = string.match(event.element.name, '^enqueue_first_button%.(.+)$')
      local tech = rqtech.from_id(force, tech_id)
      queue.enqueue_head(force, tech)
      queue.update(force)
      for _, player in pairs(force.players) do
        update_queue(player, tech)
        update_techs(player)
      end
    end,
  },
  shift_up_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      local force = player.force
      local tech_id = string.match(event.element.name, '^shift_up_button%.(.+)$')
      local tech = rqtech.from_id(force, tech_id)
      queue[event.shift and 'shift_before_earliest' or 'shift_earlier'](force, tech)
      queue.update(force)
      for _, player in pairs(force.players) do
        update_queue(player)
      end
    end,
  },
  shift_down_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      local force = player.force
      local tech_id = string.match(event.element.name, '^shift_down_button%.(.+)$')
      local tech = rqtech.from_id(force, tech_id)
      queue[event.shift and 'shift_latest' or 'shift_later'](force, tech)
      queue.update(force)
      for _, player in pairs(force.players) do
        update_queue(player)
      end
    end,
  },
  dequeue_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      local force = player.force
      local tech_id = string.match(event.element.name, '^dequeue_button%.(.+)$')
      local tech = rqtech.from_id(force, tech_id)
      queue.dequeue(force, tech)
      queue.update(force)
      for _, player in pairs(force.players) do
        update_queue(player)
        update_techs(player)
      end
    end,
  },
  queue_pause_toggle_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      local force = player.force
      queue.toggle_paused(force)
      queue.update(force)
      for _, player in pairs(force.players) do
        update_queue(player)
        update_techs(player)
      end
    end,
  },
  queue_clear_button = {
    on_gui_click = function(event)
      local player = game.players[event.player_index]
      local force = player.force
      queue.clear(force)
      queue.update(force)
      for _, player in pairs(force.players) do
        update_queue(player)
        update_techs(player)
      end
    end,
  },
}

return {
  init = init,
  deinit = deinit,
  on_research_started = on_research_started,
  on_research_finished = on_research_finished,
  on_string_translated = on_string_translated,
  on_technology_gui_opened = on_technology_gui_opened,
  on_technology_gui_closed = on_technology_gui_closed,
  on_research_speed_estimate = on_research_speed_estimate,
  update = update,
  open = open,
  close = close,
  toggle = toggle,
  focus_search = focus_search,
  register_translation_handler = register_translation_handler,
}
