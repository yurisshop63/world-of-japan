extends Control

const ROWS := 11
const COLS := 24

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _draw():
	var cell_width = size.x / COLS
	var cell_height = size.y / ROWS

	# Grille verticale
	for i in range(COLS + 1):
		var x = i * cell_width
		draw_line(
			Vector2(x, 0),
			Vector2(x, size.y),
			Color(1, 1, 1, 0.35),
			2.0
		)

	# Grille horizontale
	for i in range(ROWS + 1):
		var y = i * cell_height
		draw_line(
			Vector2(0, y),
			Vector2(size.x, y),
			Color(1, 1, 1, 0.35),
			2.0
		)

	# Lettres A à K : de haut en bas
	for i in range(ROWS):
		var letter = char(65 + i)
		var y = i * cell_height + cell_height / 2
		draw_string(
			ThemeDB.fallback_font,
			Vector2(5, y + 5),
			letter,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			Color.WHITE
		)

	# Numéros 1 à 24 : de droite à gauche
	for i in range(COLS):
		var number = str(COLS - i)
		var x = i * cell_width + cell_width / 2

		draw_string(
			ThemeDB.fallback_font,
			Vector2(x - 6, 20),
			number,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16,
			Color.WHITE
		)
