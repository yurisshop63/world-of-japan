class_name DraggableButton
extends Button
## Composant réutilisable : distingue un tap (clic/tap court) d'un appui
## long suivi d'un glissement. Compatible souris (test PC / F5) et tactile
## (Android), en s'appuyant sur get_global_mouse_position(), que Godot met
## à jour automatiquement pour le tactile via l'option projet
## "Input Devices > Pointing > Emulate Mouse From Touch" (activée par
## défaut).
##
## À hériter : surcharge _on_tap(), _on_drag_start(pos), _on_drag_move(pos)
## et _on_drag_end(pos) dans la classe fille. Si tu surcharges aussi
## _ready(), pense à appeler super._ready().

@export var long_press_time: float = 0.35
@export var drag_threshold: float = 14.0

var _is_pressed := false
var _is_dragging := false
var _press_pos := Vector2.ZERO
var _long_press_timer: Timer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

	_long_press_timer = Timer.new()
	_long_press_timer.one_shot = true
	_long_press_timer.wait_time = long_press_time
	add_child(_long_press_timer)
	_long_press_timer.timeout.connect(_on_long_press_timeout)

	gui_input.connect(_on_gui_input)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_press()
		else:
			_end_press()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_press()
		else:
			_end_press()
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _is_pressed:
			_update_press()


func _start_press() -> void:
	_is_pressed = true
	_is_dragging = false
	_press_pos = get_global_mouse_position()
	_long_press_timer.start()


func _update_press() -> void:
	var current := get_global_mouse_position()
	if not _is_dragging and current.distance_to(_press_pos) > drag_threshold:
		_begin_drag()
	if _is_dragging:
		_on_drag_move(current)


func _on_long_press_timeout() -> void:
	# L'appui a duré assez longtemps sans être relâché -> on entre en mode
	# glissement, même si le doigt/curseur n'a pas encore bougé.
	if _is_pressed and not _is_dragging:
		_begin_drag()


func _begin_drag() -> void:
	_is_dragging = true
	_long_press_timer.stop()
	_on_drag_start(get_global_mouse_position())


func _end_press() -> void:
	if not _is_pressed:
		return
	_is_pressed = false
	_long_press_timer.stop()

	var current := get_global_mouse_position()
	if _is_dragging:
		_is_dragging = false
		_on_drag_end(current)
	else:
		_on_tap()


# --- à surcharger dans les classes filles ---

func _on_tap() -> void:
	pass


func _on_drag_start(_global_pos: Vector2) -> void:
	pass


func _on_drag_move(_global_pos: Vector2) -> void:
	pass


func _on_drag_end(_global_pos: Vector2) -> void:
	pass
