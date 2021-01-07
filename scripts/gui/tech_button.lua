local guilib = require('__flib__.gui-beta')

local rqtech = require('scripts.rqtech')

local function build(player, parent, tech, list_type)
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

  local tooltip = {'',
    '[font=heading-2]', tech.tech.localised_name, '[/font]', '\n',
    tech.tech.localised_description, '\n',
    cost, '\n',
    {'sonaxaton-research-queue.tech-button-enqueue-last'}, '\n',
    {'sonaxaton-research-queue.tech-button-enqueue-second'}, '\n',
    {'sonaxaton-research-queue.tech-button-dequeue'}, '\n',
    {'sonaxaton-research-queue.tech-button-open'}}

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
}
