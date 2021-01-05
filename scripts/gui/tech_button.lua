local guilib = require('__flib__.gui-beta')

local rqtech = require('__sonaxaton-research-queue__.scripts.rqtech')

local function create_tooltip(tech, researched)
  local lines = {
    {'', '[font=heading-2]', tech.tech.localised_name, '[/font]'},
    tech.tech.localised_description}

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
  table.insert(lines, cost)

  if not researched then
    table.insert(lines, {'sonaxaton-research-queue.tech-button-enqueue-last'})
    table.insert(lines, {'sonaxaton-research-queue.tech-button-enqueue-second'})
    table.insert(lines, {'sonaxaton-research-queue.tech-button-dequeue'})
  end
  table.insert(lines, {'sonaxaton-research-queue.tech-button-open'})
  local tooltip = {}
  local first = true
  for _, line in ipairs(lines) do
    if first then
      table.insert(tooltip, '')
    else
      table.insert(tooltip, '\n')
    end
    table.insert(tooltip, line)
    first = false
  end
  return tooltip
end

local function build(player, parent, tech, list_type)
  local tooltip = create_tooltip(tech, false)
  return guilib.build(parent, {
    {
      type = 'flow',
      style = 'rq_tech_button_container_'..list_type,
      direction = 'vertical',
      children = {
        {
          ref = {'button'},
          type = 'sprite-button',
          actions = {
            on_click = { type = 'on_click_tech_button', tech = tech.id },
          },
          sprite = 'technology/'..tech.tech.name,
          tooltip = tooltip,
          number = tech.level,
          mouse_button_filter = {'left', 'right'},
        },
        {
          ref = {'progressbar'},
          type = 'progressbar',
          style = 'rq_tech_button_progressbar_'..list_type,
        },
      },
    },
  })
end

return {
  build = build,
  create_tooltip = create_tooltip,
}
