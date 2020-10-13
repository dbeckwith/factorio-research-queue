local data_util = require('__flib__.data-util')

local path = '__sonaxaton-research-queue__/graphics/icons.png'

data:extend{
  data_util.build_sprite('rq-enqueue-last-black', {0, 0}, path, 32),
  data_util.build_sprite('rq-enqueue-last-white', {32, 0}, path, 32),
  data_util.build_sprite('rq-enqueue-second-black', {0, 32}, path, 32),
  data_util.build_sprite('rq-enqueue-second-white', {32, 32}, path, 32),
  data_util.build_sprite('rq-enqueue-first-black', {0, 64}, path, 32),
  data_util.build_sprite('rq-enqueue-first-white', {32, 64}, path, 32),
  data_util.build_sprite('rq-refresh', {0, 0}, '__core__/graphics/refresh-white-animation.png', 32),
}
