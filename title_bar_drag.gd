extends Panel

var dragging = false
var drag_offset = Vector2.ZERO

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if dragging:
			drag_offset = get_global_mouse_position() - get_parent().global_position
	elif event is InputEventMouseMotion and dragging:
		var parent = get_parent()
		var new_pos = get_global_mouse_position() - drag_offset
		var viewport_size = get_viewport_rect().size
		new_pos.x = clamp(new_pos.x, 0, max(0, viewport_size.x - parent.size.x))
		new_pos.y = clamp(new_pos.y, 0, max(0, viewport_size.y - parent.size.y))
		parent.global_position = new_pos
