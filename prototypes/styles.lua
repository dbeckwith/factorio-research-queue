local styles = data.raw['gui-style'].default

styles.flib_titlebar_drag_handle = {
  type = 'empty_widget_style',
  parent = 'draggable_space',
  left_margin = 4,
  right_margin = 4,
  height = 24,
  horizontally_stretchable = 'on',
}

styles.rq_tech_button = {
  type = 'button_style',
  parent = 'tool_button',
  size = 64,
}
