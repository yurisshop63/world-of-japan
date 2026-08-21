extends CanvasLayer
# -----------------------------------------------------------------------------
# KanjiDrawPopup — Popup de dessin de kanji réutilisable.
# S'affiche en overlay par-dessus la scène 3D (CanvasLayer layer élevé) sans
# bloquer le rendu derrière. Fonctionne pendant la pause du monde
# (process_mode = WHEN_PAUSED) : la scène 3D est figée mais reste visible.
#
# Paramètre : kanji_svg_path (chemin du SVG de référence, passé via open()).
# Signaux :
#   - drawing_validated(score) émis quand le joueur valide un tracé
#   - drawing_cancelled() émis si le joueur ferme sans valider
#
# Le parsing SVG est délégué à SvgParser et le calcul du score à StrokeScoring
# (modules importés du repo kanji-game).
# -----------------------------------------------------------------------------

signal drawing_validated(score: int)
signal drawing_cancelled

@export var kanji_svg_path: String = "res://kanji/kanji_data/06c34.svg"

@onready var backdrop: ColorRect = $Backdrop
@onready var draw_bg: Panel = $Backdrop/CenterPanel/DrawBackground
@onready var drawing_container: Node2D = $Backdrop/CenterPanel/DrawBackground/DrawingContainer
@onready var reference_container: Node2D = $Backdrop/CenterPanel/ReferencePanel/ReferenceContainer
@onready var result_label: Label = $Backdrop/CenterPanel/ResultLabel
@onready var validate_button: Button = $Backdrop/CenterPanel/ValidateButton
@onready var clear_button: Button = $Backdrop/CenterPanel/ClearButton
@onready var cancel_button: Button = $Backdrop/CenterPanel/CancelButton

# Traits dessinés par le joueur (chaque élément = liste de points d'un trait)
var player_strokes: Array = []
var current_stroke: PackedVector2Array = PackedVector2Array()
var current_line: Line2D = null
var drawing: bool = false


func _ready() -> void:
	validate_button.pressed.connect(_on_validate_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	draw_bg.gui_input.connect(_on_draw_input)
	visible = false
	_draw_reference()


# Ouvre le popup pour un kanji donné (efface le tracé précédent puis redessine
# la référence). Le monde reste en pause tant que le popup est ouvert.
func open(svg_path: String) -> void:
	kanji_svg_path = svg_path
	_clear_drawing()
	_draw_reference()
	result_label.text = "Dessine le kanji puis clique sur Valider."
	visible = true


# Ferme le popup (le monde est dé-pausé par l'appelant via les signaux).
func close() -> void:
	visible = false


# ---------------------------------------------------------------------------
# Dessin du tracé joueur (événements reçus sur le panneau de dessin)
# ---------------------------------------------------------------------------

func _on_draw_input(event: InputEvent) -> void:
	var pos: Vector2 = event.position
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_stroke(pos)
		else:
			_end_stroke()
	elif event is InputEventMouseMotion and drawing:
		_add_point(pos)


func _start_stroke(pos: Vector2) -> void:
	drawing = true
	current_stroke = PackedVector2Array([pos])
	current_line = Line2D.new()
	current_line.width = 8.0
	current_line.default_color = Color(0.1, 0.1, 0.2)
	current_line.joint_mode = Line2D.LINE_JOINT_ROUND
	current_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	current_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	current_line.add_point(pos)
	drawing_container.add_child(current_line)


func _add_point(pos: Vector2) -> void:
	current_stroke.append(pos)
	current_line.add_point(pos)


func _end_stroke() -> void:
	if not drawing:
		return
	drawing = false
	# On ne garde que les traits ayant au moins 2 points (un vrai tracé)
	if current_stroke.size() >= 2:
		player_strokes.append(current_stroke)
	current_stroke = PackedVector2Array()
	current_line = null


func _clear_drawing() -> void:
	_end_stroke()
	# On ne supprime QUE les traits du joueur. La référence n'est jamais touchée.
	for child in drawing_container.get_children():
		child.queue_free()
	player_strokes.clear()


func _on_clear_pressed() -> void:
	_clear_drawing()
	result_label.text = "Zone effacée. Dessine le kanji à nouveau."


# ---------------------------------------------------------------------------
# Affichage du kanji de référence (fixe, jamais effacé)
# ---------------------------------------------------------------------------

# Dessine le kanji de référence dans le panneau de gauche à partir du SVG.
func _draw_reference() -> void:
	for child in reference_container.get_children():
		child.queue_free()
	var ref_strokes: Array = SvgParser.load_strokes(kanji_svg_path)
	if ref_strokes.is_empty():
		return
	# Le viewBox du SVG fait 109x109 : on met à l'échelle pour remplir le panneau
	var ref_scale := 130.0 / 109.0
	var offset := Vector2(10.0, 10.0)
	for i in range(ref_strokes.size()):
		var line := Line2D.new()
		for p in ref_strokes[i]:
			line.add_point(p * ref_scale + offset)
		line.width = 5.0
		line.default_color = Color(0.2, 0.4, 0.9)
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		reference_container.add_child(line)


# ---------------------------------------------------------------------------
# Validation / annulation
# ---------------------------------------------------------------------------

func _on_validate_pressed() -> void:
	_end_stroke()

	var ref_strokes: Array = SvgParser.load_strokes(kanji_svg_path)
	if ref_strokes.is_empty():
		result_label.text = "Erreur : impossible de charger le SVG de référence."
		return
	if player_strokes.is_empty():
		result_label.text = "Dessine d'abord le kanji avant de valider !"
		return

	var result: Dictionary = StrokeScoring.compute_score(player_strokes, ref_strokes)
	result_label.text = "Score : %d / 100" % result.score
	_flash_background(result.score)
	# Le verdict de combat est décidé par l'appelant (signal), pas ici.
	drawing_validated.emit(result.score)
	close()


func _on_cancel_pressed() -> void:
	drawing_cancelled.emit()
	close()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_ESCAPE:
		_on_cancel_pressed()


# ---------------------------------------------------------------------------
# Retour visuel coloré (vert -> jaune -> orange -> rouge selon le score)
# ---------------------------------------------------------------------------

# Fait brièvement changer la couleur de fond de la zone de dessin selon le
# score, puis revient en douceur au blanc via un Tween.
func _flash_background(score: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(0, 0, 0, 1)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	draw_bg.add_theme_stylebox_override("panel", sb)
	var target := _score_color(score)
	# Apparition rapide de la couleur, puis retour progressif au blanc
	var tween := create_tween()
	tween.tween_property(sb, "bg_color", target, 0.15)
	tween.tween_property(sb, "bg_color", Color.WHITE, 0.65)
	tween.tween_callback(func() -> void:
		draw_bg.remove_theme_stylebox_override("panel"))


# Couleur continue entre le vert (score 100) et le rouge (score 0), en passant
# par le jaune et l'orange, via un dégradé.
func _score_color(score: int) -> Color:
	var g := Gradient.new()
	g.set_color(0.0, Color(0.9, 0.1, 0.1))     # rouge
	g.set_color(0.4, Color(1.0, 0.55, 0.1))    # orange
	g.set_color(0.7, Color(1.0, 0.9, 0.2))     # jaune
	g.set_color(1.0, Color(0.2, 0.8, 0.2))     # vert franc
	return g.sample(clampf(float(score) / 100.0, 0.0, 1.0))
