extends Control


# =========================================================
# RÉFÉRENCES
# =========================================================

@onready var menu_button = $MenuButton
@onready var menu_panel = $MenuPanel


# =========================================================
# CONFIGURATION
# =========================================================

var categories = [
	"Stats",
	"Inventaire",
	"RA",
	"Combat",
	"Magie",
	"Groupe"
]

const GRID_ROWS = 11
const BUTTON_SIZE_IN_CELLS = 2


# =========================================================
# POSITION DES BOUTONS
#
# colonne = numéro du quadrillage
# ligne   = A=0, B=1, C=2, etc.
#
# 1 est à DROITE
# =========================================================

var button_positions = [
	Vector2(7, 0), # Stats      → A7 A8 / B7 B8
	Vector2(6, 2), # Inventaire → C6 C7 / D6 D7
	Vector2(6, 3), # RA         → D6 D7 / E6 E7
	Vector2(4, 0), # Combat     → A4 A5 / B4 B5

	# Les deux suivants seront placés plus tard
	Vector2(0, 0), # Magie
	Vector2(0, 0)  # Groupe
]


# =========================================================
# INITIALISATION
# =========================================================

func _ready():

	# Le panneau est fermé au démarrage
	menu_panel.visible = false

	# Le bouton principal
	menu_button.focus_mode = Control.FOCUS_NONE
	menu_button.pressed.connect(_on_menu_button_pressed)

	# Création des 6 boutons
	for i in range(categories.size()):

		create_category_button(
			categories[i],
			button_positions[i]
		)


# =========================================================
# CRÉATION D'UN BOUTON
# =========================================================

func create_category_button(category_name, grid_position):

	var button = Button.new()

	button.text = category_name

	button.focus_mode = Control.FOCUS_NONE


	# -----------------------------------------------------
	# Taille :
	# 2 cases x 2 cases
	# -----------------------------------------------------

	var cell_size = get_grid_cell_size()

	button.custom_minimum_size = Vector2(
		cell_size * BUTTON_SIZE_IN_CELLS,
		cell_size * BUTTON_SIZE_IN_CELLS
	)


	# -----------------------------------------------------
	# Position :
	# grid_position.x = colonne
	# grid_position.y = ligne
	# -----------------------------------------------------

	button.position = Vector2(
		get_grid_x(grid_position.x),
		get_grid_y(grid_position.y)
	)


	# -----------------------------------------------------
	# Action du bouton
	# -----------------------------------------------------

	button.pressed.connect(
		_on_category_pressed.bind(category_name)
	)


	menu_panel.add_child(button)


# =========================================================
# TAILLE D'UNE CASE
# =========================================================

func get_grid_cell_size():

	var screen_size = get_viewport_rect().size

	return screen_size.y / float(GRID_ROWS)


# =========================================================
# POSITION HORIZONTALE
#
# La colonne 1 est à DROITE.
# =========================================================

func get_grid_x(column):

	var cell_size = get_grid_cell_size()

	var screen_width = get_viewport_rect().size.x

	var columns = int(
		floor(screen_width / cell_size)
	)

	var grid_width = columns * cell_size

	var offset_x = (
		screen_width - grid_width
	) / 2.0

	return offset_x + (
		columns - column - 1
	) * cell_size


# =========================================================
# POSITION VERTICALE
#
# A = 0
# B = 1
# C = 2
# ...
# K = 10
# =========================================================

func get_grid_y(row):

	var cell_size = get_grid_cell_size()

	return row * cell_size


# =========================================================
# OUVERTURE / FERMETURE DU MENU
# =========================================================

func _on_menu_button_pressed():

	menu_panel.visible = not menu_panel.visible


# =========================================================
# ACTION DES CATÉGORIES
# =========================================================

func _on_category_pressed(category_name):

	print("Onglet ouvert : ", category_name)
