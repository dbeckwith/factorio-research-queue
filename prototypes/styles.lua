local styles = data.raw['gui-style'].default

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
  width = 200,
}

styles.rq_tech_list_list_box = {
  type = 'scroll_pane_style',
  parent = 'rq_list_box',
  width = 480,
}

styles.rq_tech_list_item = {
  type = 'frame_style',
  padding = 4,
}

styles.rq_tech_list_item_tool_bar = {
  type = 'horizontal_flow_style',
  horizontally_stretchable = 'on',
  horizontal_align = 'center',
}

styles.rq_tech_list_item_button = {
  type = 'button_style',
  parent = 'tool_button',
  size = 96,
}

styles.rq_tech_queue_item = {
  type = 'frame_style',
  padding = 4,
}

styles.rq_tech_queue_item_content = {
  type = 'horizontal_flow_style',
  horizontally_stretchable = 'on',
}

styles.rq_tech_queue_item_shift_buttons = {
  type = 'vertical_flow_style',
  vertically_stretchable = 'on',
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
