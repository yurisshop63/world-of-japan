extends Panel

@onready var health_bar = $HealthBar
@onready var power_bar = $PowerBar
@onready var xp_bubbles = $XpBubbles
@onready var xp_bar = $XpBar
@onready var pvp_xp_bubbles = $PvpXpBubbles
@onready var pvp_xp_bar = $PvpXpBar
@onready var target_health_bar = $TargetHealthBar

var dragging = false
var drag_offset = Vector2.ZERO

func _ready():
	_build_bubbles(xp_bubbles)
	_build_bubbles(pvp_xp_bubbles)

	PlayerStats.health_changed.connect(_on_health_changed)
	PlayerStats.power_changed.connect(_on_power_changed)
	PlayerStats.xp_changed.connect(_on_xp_changed)
	PlayerStats.pvp_xp_changed.connect(_on_pvp_xp_changed)

	_on_health_changed()
	_on_power_changed()
	_on_xp_changed()
	_on_pvp_xp_changed()

func _process(_delta):
	var target = TargetSystem.current_target
	if target != null and is_instance_valid(target):
		target_health_bar.visible = true
		target_health_bar.max_value = target.max_health
		target_health_bar.value = target.health
	else:
		target_health_bar.visible = false

func _build_bubbles(container):
	for i in range(10):
		var bubble = ColorRect.new()
		bubble.custom_minimum_size = Vector2(20, 20)
		bubble.color = Color(0.2, 0.2, 0.2)
		container.add_child(bubble)

func _update_bubbles(container, filled_count):
	for i in range(container.get_child_count()):
		var bubble = container.get_child(i)
		bubble.color = Color(0.2, 0.6, 1.0) if i < filled_count else Color(0.2, 0.2, 0.2)

func _on_health_changed():
	health_bar.max_value = PlayerStats.max_health
	health_bar.value = PlayerStats.health

func _on_power_changed():
	power_bar.max_value = PlayerStats.max_power
	power_bar.value = PlayerStats.power

func _on_xp_changed():
	xp_bar.max_value = PlayerStats.xp_per_bubble
	xp_bar.value = PlayerStats.xp_in_bubble
	_update_bubbles(xp_bubbles, PlayerStats.bubbles_filled)

func _on_pvp_xp_changed():
	pvp_xp_bar.max_value = PlayerStats.pvp_xp_per_bubble
	pvp_xp_bar.value = PlayerStats.pvp_xp_in_bubble
	_update_bubbles(pvp_xp_bubbles, PlayerStats.pvp_bubbles_filled)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if dragging:
			drag_offset = get_global_mouse_position() - global_position
	elif event is InputEventMouseMotion and dragging:
		var new_pos = get_global_mouse_position() - drag_offset
		var viewport_size = get_viewport_rect().size
		new_pos.x = clamp(new_pos.x, 0, max(0, viewport_size.x - size.x))
		new_pos.y = clamp(new_pos.y, 0, max(0, viewport_size.y - size.y))
		global_position = new_pos
