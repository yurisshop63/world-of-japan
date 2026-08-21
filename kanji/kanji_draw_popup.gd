extends CanvasLayer
# -----------------------------------------------------------------------------
# KanjiDrawPopup — Popup de dessin de kanji réutilisable (temps réel).
# S'affiche en overlay par-dessus la scène 3D (CanvasLayer layer élevé) sans
# bloquer le rendu derrière. Le monde ne se met PAS en pause : le mob continue
# d'attaquer pendant que le joueur dessine. La vitesse de réalisation devient
# donc un second paramètre de score, en plus de la précision.
#
# Paramètre : kanji_svg_path (chemin du SVG de référence, passé via open()).
# par_time_ms : temps "parfait" (en ms) pour dessiner le kanji — sert au calcul
# du multiplicateur de vitesse côté combat. Facilement ajustable par kanji.
#
# Signaux :
#   - drawing_validated(score, elapsed_ms) émis quand le joueur valide un tracé
#   - drawing_cancelled() émis si le joueur ferme sans valider
#
# Le parsing SVG est délégué à SvgParser et le calcul du score à StrokeScoring
# (modules importés du repo kanji-game).
# -----------------------------------------------------------------------------

signal drawing_validated(score: int, elapsed_ms: int)
signal drawing_cancelled

# Temps "parfait" pour dessiner le kanji (ms). Pour l'instant 水 : 3000 ms.
@export var par_time_ms: int = 3000

@export var kanji_svg_path: String = "res://kanji/kanji_data/06c34.svg"

@onready var backdrop: ColorRect = $Backdrop
@onready var draw_bg: Panel = $Backdrop/CenterPanel/DrawBackground
@onready var drawing_container: Node2D = $Backdrop/CenterPanel/DrawBackground/DrawingContainer
@onready var reference_container: Node2D = $Backdrop/CenterPanel/ReferencePanel/ReferenceContainer
@onready var result_label: Label = $Backdrop/CenterPanel/ResultLabel
@onready var timer_label: Label = $Backdrop/CenterPanel/TimerLabel
@onready var validate_button: Button = $Backdrop/CenterPanel/ValidateButton
@onready var clear_button: Button = $Backdrop/CenterPanel/ClearButton
@onready var cancel_button: Button = $Backdrop/CenterPanel/CancelButton

# Traits dessinés par le joueur (chaque élément = liste de points d'un trait)
var player_strokes: Array = []
var current_stroke: PackedVector2Array = PackedVector2Array()
var current_line: Line2D = null
var drawing: bool = false

# Chrono du dessin en cours (Time.get_ticks_msec() au moment de open()).
var _open_time_ms: int = 0

# Mode souris mémorisé avant l'ouverture (restauré à la fermeture).
var _previous_mouse_mode: int = Input.MOUSE_MODE_VISIBLE
var _mouse_switched_to_visible: bool = false

# Couleurs / rendu (contraste lisible : fond clair, tracé sombre).
const DRAW_BG_COLOR := Color(0.941, 0.941, 0.941)   # #F0F0F0
const REF_BG_COLOR := Color(0.961, 0.961, 0.961)    # #F5F5F5 (fond du panneau référence)
const PLAYER_STROKE_COLOR := Color(0.08, 0.08, 0.15) # quasi noir
const PLAYER_STROKE_WIDTH := 5.0
const REF_STROKE_COLOR := Color(0.12, 0.27, 0.58)    # bleu nuit net (guide lisible)
const REF_STROKE_WIDTH := 4.0


func _ready() -> void:
	validate_button.pressed.connect(_on_validate_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	draw_bg.gui_input.connect(_on_draw_input)
	visible = false
	_draw_reference()


# Ouvre le popup pour un kanji donné (efface le tracé précédent puis redessine
# la référence). Démarre le chrono et libère la souris pour dessiner.
func open(svg_path: String) -> void:
	kanji_svg_path = svg_path
	_clear_drawing()
	_draw_reference()
	result_label.text = "Dessine le kanji puis clique sur Valider."
	_open_time_ms = Time.get_ticks_msec()
	_previous_mouse_mode = Input.get_mouse_mode()
	if _previous_mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_mouse_switched_to_visible = true
	visible = true


# Ferme le popup et restaure le mode souris précédent (validé, annulé ou mort).
func close() -> void:
	visible = false
	_restore_mouse_mode()


# Restaure aussi la souris en cas de fermeture forcée (queue_free sans close()).
func _exit_tree() -> void:
	_restore_mouse_mode()


func _restore_mouse_mode() -> void:
	if _mouse_switched_to_visible:
		Input.set_mouse_mode(_previous_mouse_mode)
		_mouse_switched_to_visible = false


# ---------------------------------------------------------------------------
# Chrono affiché pendant le dessin (pression temps réel)
# ---------------------------------------------------------------------------

func _process(_delta: float) -> void:
	if not visible:
		return
	var elapsed_ms := Time.get_ticks_msec() - _open_time_ms
	timer_label.text = "Temps : %.1fs" % (float(elapsed_ms) / 1000.0)


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
	current_line.width = PLAYER_STROKE_WIDTH
	current_line.default_color = PLAYER_STROKE_COLOR
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
# Trait continu bleu nuit net sur fond clair (contraste) : le guide est lisible
# d'un coup d'œil tout en restant distinct du tracé joueur (quasi noir).
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
		line.width = REF_STROKE_WIDTH
		line.default_color = REF_STROKE_COLOR
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

	var elapsed_ms := Time.get_ticks_msec() - _open_time_ms
	var result: Dictionary = StrokeScoring.compute_score(player_strokes, ref_strokes)
	result_label.text = "Score : %d / 100" % result.score
	_flash_background(result.score)
	# Le verdict de combat est décidé par l'appelant (signal), pas ici.
	drawing_validated.emit(result.score, elapsed_ms)
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
# score, puis revient en douceur à la couleur de fond claire via un Tween.
func _flash_background(score: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = DRAW_BG_COLOR
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(0.3, 0.3, 0.3, 1)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	draw_bg.add_theme_stylebox_override("panel", sb)
	var target := _score_color(score)
	# Apparition rapide de la couleur, puis retour progressif au fond clair
	var tween := create_tween()
	tween.tween_property(sb, "bg_color", target, 0.15)
	tween.tween_property(sb, "bg_color", DRAW_BG_COLOR, 0.65)
	tween.tween_callback(func() -> void:
		draw_bg.remove_theme_stylebox_override("panel"))


# Couleur continue entre le vert (score 100) et le rouge (score 0), en passant
# par le jaune et l'orange, via un dégradé. Nuances foncées pour rester
# lisibles sur le fond clair.
func _score_color(score: int) -> Color:
	var g := Gradient.new()
	g.set_color(0.0, Color(0.85, 0.1, 0.1))     # rouge
	g.set_color(0.4, Color(0.95, 0.5, 0.08))    # orange
	g.set_color(0.7, Color(0.9, 0.8, 0.15))     # jaune foncé
	g.set_color(1.0, Color(0.15, 0.7, 0.15))    # vert franc
	return g.sample(clampf(float(score) / 100.0, 0.0, 1.0))
