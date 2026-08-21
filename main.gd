extends Node3D

@onready var camera = $Player/CameraPivot/Camera3D

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_select(event.position)

func _try_select(mouse_pos):
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result and result.collider.has_method("take_damage"):
		TargetSystem.select(result.collider)
	else:
		TargetSystem.select(null)
