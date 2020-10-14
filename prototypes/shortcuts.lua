local data_util = require('__flib__.data-util')

local path = '__sonaxaton-research-queue__/graphics/icons.png'

data:extend{
  {
    type = 'shortcut',
    name = 'sonaxaton-research-queue',
    order = 'r[research-queue]',
    associated_control_input = 'sonaxaton-research-queue',
    action = 'lua',
    toggleable = true,
    icon = {
      filename = '__sonaxaton-research-queue__/graphics/icons.png',
      position = {0, 64},
      size = 32,
      flags = {'icon'},
    },
  },
}
