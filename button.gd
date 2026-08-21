extends Button

const ROWS := 11
const COLS := 24

var menu_window: Control


func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 10

	# Taille d'une case
	var cell_width = get_viewport_rect().size.x / COLS
	var cell_height = get_viewport_rect().size.y / ROWS

	# MENU = A1 A2 B1 B2
	position = Vector2(
		get_viewport_rect().size.x - cell_width * 2,
		0
	)

	size = Vector2(
		cell_width * 2,
		cell_height * 2
	)

	var radius = int(min(size.x, size.y) / 2)
	apply_round_styles(self, radius, Color(0.05, 0.05, 0.05, 0.95))

	text = "MENU"
	add_theme_font_size_override("font_size", 18)

	pressed.connect(toggle_menu)


func toggle_menu():
	if menu_window:
		menu_window.queue_free()
		menu_window = null
		return

	menu_window = Control.new()
	menu_window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_window.z_index = 9

	get_tree().current_scene.add_child(menu_window)

	create_menu_button("1", 4, 5, 0, 1)
	create_menu_button("2", 7, 8, 0, 1)
	create_menu_button("3", 7, 8, 2, 3)
	create_menu_button("4", 6, 7, 4, 5)
	create_menu_button("5", 4, 5, 5, 6)
	create_menu_button("6", 2, 3, 7, 8)


func create_menu_button(label_text: String, col1: int, col2: int, row1: int, row2: int):
	var button = Button.new()

	var cell_width = get_viewport_rect().size.x / COLS
	var cell_height = get_viewport_rect().size.y / ROWS

	# Colonnes : 1 est à droite, 24 à gauche
	var x = get_viewport_rect().size.x - (col2 * cell_width)

	# Lignes : A = 0, B = 1, etc.
	var y = row1 * cell_height

	button.position = Vector2(x, y)
	button.size = Vector2(
		(col2 - col1 + 1) * cell_width,
		(row2 - row1 + 1) * cell_height
	)

	var radius = int(min(button.size.x, button.size.y) / 2)
	apply_round_styles(button, radius, Color(0.05, 0.05, 0.05, 0.90))

	button.text = label_text
	button.add_theme_font_size_override("font_size", 18)

	button.mouse_filter = Control.MOUSE_FILTER_STOP

	menu_window.add_child(button)


# Applique un style rond identique sur tous les états du bouton
# (normal, hover, pressed, focus), pour éviter que Godot retombe
# sur le style carré par défaut du thème quand la souris passe dessus.
func apply_round_styles(btn: Button, radius: int, base_color: Color) -> void:
	var normal_style = _make_round_stylebox(base_color, radius)
	var hover_style = _make_round_stylebox(base_color.lightened(0.15), radius)
	var pressed_style = _make_round_stylebox(base_color.lightened(0.3), radius)
	var focus_style = _make_round_stylebox(base_color, radius)

	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("focus", focus_style)

	# Évite le contour de focus carré qui apparaît par-dessus le style rond
	btn.focus_mode = Control.FOCUS_NONE


func _make_round_stylebox(color: Color, radius: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
