local util = require('util')

local styles = data.raw['gui-style'].default

function tech_graphical_set(y)
  return {
    default_graphical_set = {
      base = {position = {296, y}, corner_size = 8},
      shadow = default_shadow
    },
    hovered_graphical_set = {
      base = {position = {312, y}, corner_size = 8},
      shadow = default_shadow
    },
    selected_hovered_graphical_set = {
      base = {position = {312, y}, corner_size = 8},
      shadow = default_shadow
    },
    clicked_graphical_set = {
      base = {position = {312, y}, corner_size = 8},
      shadow = default_shadow
    },
    selected_graphical_set = {
      base = {position = {312, y}, corner_size = 8},
      shadow = default_shadow
    },
    selected_clicked_graphical_set = {
      base = {position = {312, y}, corner_size = 8},
      shadow = default_shadow
    },
    disabled_graphical_set = {
      base = {position = {296, y}, corner_size = 8},
      shadow = default_shadow
    },
  }
end

styles.rq_main_window = {
  type = 'frame_style',
  parent = 'inner_frame_in_outer_frame',
  height = 500,
}

styles.rq_list_box = {
  type = 'scroll_pane_style',
  vertically_stretchable = 'on',
}

styles.rq_tech_queue_list_box = {
  type = 'scroll_pane_style',
  parent = 'rq_list_box',
  width = 104,
}

styles.rq_tech_list_list_box = {
  type = 'scroll_pane_style',
  parent = 'rq_list_box',
  width = 516,
}

styles.rq_tech_ingredient_filter_buttons_scroll_box = {
  type = 'scroll_pane_style',
  horizontally_stretchable = 'on',
  vertical_flow_style = {
    type = 'vertical_flow_style',
    vertical_align = 'center',
  },
}

styles.rq_tech_list_filter_container = {
  type = 'horizontal_flow_style',
  vertical_align = 'center',
}

styles.rq_filter_researched_button_enabled = {
  type = 'button_style',
  parent = 'green_slot',
  size = 28,
  padding = 2,
}

styles.rq_filter_researched_button_disabled = {
  type = 'button_style',
  parent = 'slot',
  size = 28,
  padding = 2,
}

styles.rq_tech_ingredient_filter_button_enabled = {
  type = 'button_style',
  parent = 'green_slot',
}

styles.rq_tech_ingredient_filter_button_disabled = {
  type = 'button_style',
  parent = 'slot',
}

styles.rq_tech_list_table = {
  type = 'table_style',
  horizontally_stretchable = 'off',
}

styles.rq_tech_list_item = {
  type = 'vertical_flow_style',
  vertical_spacing = 0,
}

styles.rq_tech_list_item_tool_bar = {
  type = 'frame_style',
  padding = 0,
  top_padding = 4,
  bottom_padding = 4,
  horizontal_flow_style = {
    type = 'horizontal_flow_style',
    horizontally_stretchable = 'on',
    horizontal_align = 'center',
  },
  graphical_set = {
    base = {position = {347, 204}, corner_size = 8},
  },
}

styles.rq_tech_list_item_queued_tool_bar = {
  type = 'frame_style',
  parent = 'rq_tech_list_item_tool_bar',
  graphical_set = {
    base = {position = {347, 136}, corner_size = 8},
  },
}

styles.rq_tech_list_item_researched_tool_bar = {
  type = 'frame_style',
  parent = 'rq_tech_list_item_tool_bar',
  graphical_set = {
    base = {position = {347, 187}, corner_size = 8},
  },
}

styles.rq_tech_list_item_tech_button = util.merge{
  {
    type = 'button_style',
    size = 96,
  },
  tech_graphical_set(204),
}

styles.rq_tech_list_item_queued_tech_button = util.merge{
  {
    type = 'button_style',
    size = 96,
  },
  tech_graphical_set(136),
}

styles.rq_tech_list_item_researched_tech_button = util.merge{
  {
    type = 'button_style',
    size = 96,
  },
  tech_graphical_set(187),
}

styles.rq_tech_list_item_tool_button = {
  type = 'button_style',
  parent = 'tool_button',
  size = 24,
  padding = 0,
}

styles.rq_tech_queue_item = {
  type = 'frame_style',
  parent = 'subpanel_frame',
  top_padding = 2,
  bottom_padding = 2,
  left_padding = 2,
  right_padding = 2,
  horizontal_flow_style = {
    type = 'horizontal_flow_style',
    vertically_stretchable = 'off',
    vertical_align = 'center',
  },
}

styles.rq_tech_queue_item_tech_button = util.merge{
  {
    type = 'button_style',
    -- TODO: resize tech buttons so icons end up being nice sizes
    size = 48,
    padding = 0,
  },
  tech_graphical_set(136),
}

styles.rq_tech_queue_head_item_tech_button = util.merge{
  {
    type = 'button_style',
    size = 48,
    padding = 0,
  },
  tech_graphical_set(153),
}

styles.rq_tech_queue_item_buttons = {
  type = 'vertical_flow_style',
  horizontal_align = 'center',
  vertical_spacing = 0,
}

styles.rq_tech_queue_item_close_button = {
  type = 'button_style',
  parent = 'mini_button',
}

styles.rq_tech_queue_item_shift_up_button = {
  type = 'button_style',
  size = {8, 8},
  padding = 0,
  default_graphical_set = {
    filename = '__core__/graphics/arrows/table-header-sort-arrow-up-active.png',
    size = {16, 16},
    scale = 0.5
  },
  hovered_graphical_set = {
    filename = '__core__/graphics/arrows/table-header-sort-arrow-up-hover.png',
    size = {16, 16},
    scale = 0.5
  },
  clicked_graphical_set = {
    filename = '__core__/graphics/arrows/table-header-sort-arrow-up-active.png',
    size = {16, 16},
    scale = 0.5
  },
  disabled_graphical_set = {
    filename = '__core__/graphics/arrows/table-header-sort-arrow-up-white.png',
    size = {16, 16},
    scale = 0.5
  }
}

styles.rq_tech_queue_item_shift_down_button = {
  type = 'button_style',
  size = {8, 8},
  padding = 0,
  default_graphical_set = {
    filename = '__core__/graphics/arrows/table-header-sort-arrow-down-active.png',
    size = {16, 16},
    scale = 0.5
  },
  hovered_graphical_set = {
    filename = '__core__/graphics/arrows/table-header-sort-arrow-down-hover.png',
    size = {16, 16},
    scale = 0.5
  },
  clicked_graphical_set = {
    filename = '__core__/graphics/arrows/table-header-sort-arrow-down-active.png',
    size = {16, 16},
    scale = 0.5
  },
  disabled_graphical_set = {
    filename = '__core__/graphics/arrows/table-header-sort-arrow-down-white.png',
    size = {16, 16},
    scale = 0.5
  }
}
