extends Node

signal target_changed

var current_target = null

func select(mob):
	if current_target != null and is_instance_valid(current_target):
		current_target.set_selected(false)
	current_target = mob
	if current_target != null:
		current_target.set_selected(true)
	target_changed.emit()
