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
  horizontal_align = 'left',
}
