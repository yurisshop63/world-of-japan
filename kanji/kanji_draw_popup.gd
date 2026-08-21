extends CanvasLayer
# -----------------------------------------------------------------------------
# KanjiDrawPopup — Popup de dessin de kanji réutilisable (temps réel), refonte
# session "écran de dessin" :
# - Carré de dessin ancré du MÊME côté que le bouton MENU (MenuConfig.side),
#   dimensions en repère GridOverlay : lignes B..J en hauteur, colonnes 1..9 en
#   largeur (col 1 = bord droit). Bascule en miroir sur MenuConfig.config_changed.
# - 3 références de kanji affichées en même temps, au-dessus et du côté opposé
#   au menu par rapport au carré (vers le centre de l'écran). Le joueur clique
#   sur celle qu'il veut dessiner -> elle devient le kanji actif (scoring).
# - 3 boutons ronds en bas du carré : Valider (vert, bas-droite, plus gros),
#   Retour dernier trait (orange, bas-centre, undo unitaire), Effacer (rouge,
#   bas-gauche). Le bouton "Annuler" global (fermeture, ESC) reste séparé.
# - PAS d'assombrissement de fond : le monde 3D reste entièrement visible
#   pendant le dessin (le carré est en périphérie, le centre reste dégagé).
#
# Le monde ne se met PAS en pause : le mob continue d'attaquer pendant que le
# joueur dessine. La vitesse de réalisation devient donc un second paramètre
# de score, en plus de la précision.
#
# Paramètres (via open()) : candidates = liste de dicts
#   {"svg": chemin, "par_time_ms": temps parfait, "name": libellé}
#   Le premier est sélectionné par défaut ; le joueur peut changer.
#
# Signaux :
#   - drawing_validated(score, elapsed_ms) émis quand le joueur valide un tracé
#   - drawing_cancelled() émis si le joueur ferme sans valider
#
# Le parsing SVG est délégué à SvgParser et le calcul du score à StrokeScoring.
# -----------------------------------------------------------------------------

signal drawing_validated(score: int, elapsed_ms: int)
signal drawing_cancelled

# Temps "parfait" pour le kanji actif (ms) — mis à jour à la sélection.
var par_time_ms: int = 3000

# Les candidats (dicts {"svg", "par_time_ms", "name"}) et le kanji sélectionné.
var _candidates: Array = []
var _selected_index := 0

# Traits dessinés par le joueur (chaque élément = liste de points d'un trait),
# + le Line2D correspondant (pour l'undo unitaire).
var player_strokes: Array = []
var _stroke_lines: Array = []
var current_stroke: PackedVector2Array = PackedVector2Array()
var current_line: Line2D = null
var drawing: bool = false

# Chrono du dessin en cours (Time.get_ticks_msec() au moment de open()).
var _open_time_ms: int = 0

# Mode souris mémorisé avant l'ouverture (restauré à la fermeture).
var _previous_mouse_mode: int = Input.MOUSE_MODE_VISIBLE
var _mouse_switched_to_visible: bool = false

# Nœuds construits en code (pas de .tscn détaillé : positionnement dynamique).
var _root: Control
var _draw_panel: Panel
var _drawing_container: Node2D
var _timer_label: Label
var _result_label: Label
var _validate_button: Button
var _undo_button: Button
var _clear_button: Button
var _cancel_button: Button
var _ref_panels: Array = []   # Panel par candidat (cliquable)

# Couleurs / rendu (contraste lisible : fond clair, tracé sombre).
const DRAW_BG_COLOR := Color(0.941, 0.941, 0.941)   # #F0F0F0
const PLAYER_STROKE_COLOR := Color(0.08, 0.08, 0.15) # quasi noir
const PLAYER_STROKE_WIDTH := 5.0
const REF_STROKE_COLOR := Color(0.12, 0.27, 0.58)    # bleu nuit net (guide lisible)
const REF_STROKE_WIDTH := 4.0

# Couleurs des boutons d'action.
const COLOR_VALIDATE := Color(0.05, 0.55, 0.2, 0.95)  # vert
const COLOR_UNDO := Color(0.9, 0.55, 0.1, 0.95)       # orange/jaune
const COLOR_CLEAR := Color(0.75, 0.15, 0.12, 0.95)    # rouge
const COLOR_CANCEL := Color(0.35, 0.35, 0.35, 0.95)   # gris (séparé)


func _ready() -> void:
	_build_ui()
	# Bascule de côté en miroir avec le menu (même mécanisme que le joystick).
	MenuConfig.config_changed.connect(_apply_layout)
	get_viewport().size_changed.connect(_apply_layout)
	visible = false


# ---------------------------------------------------------------------------
# Construction de l'UI (entièrement en code : position selon MenuConfig.side)
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Racine plein écran en IGNORE : le monde reste visible et cliquable
	# (joystick utilisable pendant le dessin), seuls les enfants STOP captent.
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_draw_panel = Panel.new()
	_draw_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = DRAW_BG_COLOR
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(0.3, 0.3, 0.3, 1)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	_draw_panel.add_theme_stylebox_override("panel", sb)
	_draw_panel.gui_input.connect(_on_draw_input)
	_root.add_child(_draw_panel)

	_drawing_container = Node2D.new()
	_draw_panel.add_child(_drawing_container)

	_timer_label = Label.new()
	_timer_label.add_theme_font_size_override("font_size", 16)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_root.add_child(_timer_label)

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 16)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_result_label)

	_cancel_button = _make_round_button("✕", COLOR_CANCEL)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	_root.add_child(_cancel_button)

	# Valider : vert, plus gros (diamètre ≈ une case de grille).
	_validate_button = _make_round_button("Valider", COLOR_VALIDATE)
	_validate_button.pressed.connect(_on_validate_pressed)
	_root.add_child(_validate_button)

	# Retour dernier trait : orange, undo unitaire.
	_undo_button = _make_round_button("Retour", COLOR_UNDO)
	_undo_button.pressed.connect(_on_undo_pressed)
	_root.add_child(_undo_button)

	# Effacer : rouge, reset complet.
	_clear_button = _make_round_button("Effacer", COLOR_CLEAR)
	_clear_button.pressed.connect(_on_clear_pressed)
	_root.add_child(_clear_button)

	# Panneaux de référence (3) : construits vides, remplis dans _refresh_references().
	for i in range(3):
		var panel := Panel.new()
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		var ref_sb := StyleBoxFlat.new()
		ref_sb.bg_color = Color(0.961, 0.961, 0.961)
		ref_sb.border_width_left = 2
		ref_sb.border_width_top = 2
		ref_sb.border_width_right = 2
		ref_sb.border_width_bottom = 2
		ref_sb.border_color = Color(0.5, 0.5, 0.5, 1)
		ref_sb.corner_radius_top_left = 6
		ref_sb.corner_radius_top_right = 6
		ref_sb.corner_radius_bottom_right = 6
		ref_sb.corner_radius_bottom_left = 6
		panel.add_theme_stylebox_override("panel", ref_sb)
		panel.gui_input.connect(_on_ref_input.bind(i))
		_root.add_child(panel)
		_ref_panels.append(panel)

	_apply_layout()


func _make_round_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	MenuStyle.apply_round_styles(btn, 28, color)
	return btn


# ---------------------------------------------------------------------------
# Positionnement (repère GridOverlay : lignes A..K, colonnes 1..24 depuis la droite)
# ---------------------------------------------------------------------------

## Carré de dessin : mêmes dimensions que le côté du menu (MenuConfig.side),
## lignes B..J (indices 1..9), colonnes 1..9 (depuis le bord droit).
## Le bord bas tombe sur le haut de la ligne K (juste au-dessus du bandeau
## summary), le bord haut juste sous le bouton MENU (lignes 0-1).
func _draw_square_rect(viewport_size: Vector2) -> Rect2:
	var r := MenuLayout.rect_from_right(viewport_size, Vector2i(1, 9), Vector2i(1, 9))
	if MenuConfig.side == MenuConfig.Side.LEFT:
		r = MenuLayout.mirror_rect(viewport_size, r)
	return r


func _apply_layout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var cell := MenuLayout.cell_size(vp)
	var square := _draw_square_rect(vp)

	_draw_panel.position = square.position
	_draw_panel.size = square.size

	# Labels : haut du carré.
	_timer_label.position = square.position + Vector2(16, 10)
	_timer_label.size = Vector2(180, 24)
	_result_label.position = square.position + Vector2(0, 40)
	_result_label.size = Vector2(square.size.x, 24)

	# Bouton Annuler global : séparé des 3 boutons d'action, en haut-droite du
	# carré (proche du bouton MENU, côté opposé aux références).
	_cancel_button.position = square.position + Vector2(square.size.x - 78, 10)
	_cancel_button.size = Vector2(68, 68)

	# 3 boutons d'action en bas du carré : Effacer (gauche), Retour (centre),
	# Valider (droite, plus gros). Valider ≈ une case de grille.
	var validate_d := cell.x
	var action_d := cell.x * 0.72
	var row_y := square.position.y + square.size.y - validate_d - 14
	var cx := square.position.x + square.size.x / 2.0
	_clear_button.size = Vector2(action_d, action_d)
	_clear_button.position = Vector2(cx - validate_d / 2.0 - action_d - 16, row_y + (validate_d - action_d) / 2.0)
	_undo_button.size = Vector2(action_d, action_d)
	_undo_button.position = Vector2(cx - action_d / 2.0, row_y + (validate_d - action_d) / 2.0)
	_validate_button.size = Vector2(validate_d, validate_d)
	_validate_button.position = Vector2(cx + validate_d / 2.0 + 16, row_y)
	# Rayon mis à jour selon la taille réelle.
	MenuStyle.apply_round_styles(_clear_button, int(action_d / 2), COLOR_CLEAR)
	MenuStyle.apply_round_styles(_undo_button, int(action_d / 2), COLOR_UNDO)
	MenuStyle.apply_round_styles(_validate_button, int(validate_d / 2), COLOR_VALIDATE)

	# Références : au-dessus et du côté OPPOSÉ au menu par rapport au carré
	# (donc vers le centre de l'écran). Droiter -> haut-gauche ; gaucher ->
	# haut-droite.
	var ref_count := _ref_panels.size()
	var ref_w := cell.x * 2.4
	var ref_h := cell.y * 1.8
	var gap := cell.x * 0.3
	var refs_total := ref_count * ref_w + (ref_count - 1) * gap
	var ref_y := square.position.y * 0.5
	var ref_start_x: float
	if MenuConfig.side == MenuConfig.Side.RIGHT:
		ref_start_x = vp.x - square.position.x - refs_total - cell.x
	else:
		ref_start_x = square.position.x + square.size.x + cell.x
	for i in range(ref_count):
		var panel: Panel = _ref_panels[i]
		panel.position = Vector2(ref_start_x + i * (ref_w + gap), ref_y)
		panel.size = Vector2(ref_w, ref_h)
		# Redessine les traits de la référence dans son panneau (taille connue).
		_refresh_ref_strokes(panel, i)


# ---------------------------------------------------------------------------
# Ouverture / fermeture
# ---------------------------------------------------------------------------

## Ouvre le popup avec la liste des candidats (dicts {"svg","par_time_ms","name"}).
## Le premier candidat est sélectionné par défaut ; le joueur peut en choisir
## un autre (clic sur la référence). Efface le tracé précédent puis redessine.
## Démarre le chrono et libère la souris pour dessiner.
func open(candidates: Array) -> void:
	_candidates = candidates
	_selected_index = 0
	if _candidates.is_empty():
		# Sécurité : candidat par défaut pour ne jamais avoir de popup vide.
		_candidates = [{"svg": "res://kanji/kanji_data/06c34.svg", "par_time_ms": 3000, "name": "水"}]
	_refresh_references()
	_select_reference(0)
	_clear_drawing()
	_apply_layout()  # repositionne tout + redessine les traits des 3 références
	_result_label.text = "Choisis une référence puis dessine le kanji."
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
	_timer_label.text = "Temps : %.1fs" % (float(elapsed_ms) / 1000.0)


# ---------------------------------------------------------------------------
# Références : 3 kanji au choix, clic pour sélectionner celui à dessiner
# ---------------------------------------------------------------------------

## Remplit les 3 panneaux de référence à partir de _candidates (noms + traits).
func _refresh_references() -> void:
	for i in range(_ref_panels.size()):
		var panel: Panel = _ref_panels[i]
		if i < _candidates.size():
			panel.visible = true
			# Nom du kanji affiché (reconstruit à chaque refresh).
			for child in panel.get_children():
				if child is Label:
					child.queue_free()
			var name_label := Label.new()
			name_label.text = str(_candidates[i].get("name", "?"))
			name_label.add_theme_font_size_override("font_size", 18)
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.position = Vector2(4, panel.size.y - 26)
			name_label.size = Vector2(maxf(panel.size.x - 8, 10), 22)
			panel.add_child(name_label)
		else:
			panel.visible = false


## Redessine les traits du kanji i dans son panneau (échelle pour remplir).
func _refresh_ref_strokes(panel: Panel, index: int) -> void:
	if index >= _candidates.size():
		return
	# Supprime l'ancien conteneur de traits (sauf les Labels de nom).
	for child in panel.get_children():
		if child is Node2D:
			child.queue_free()
	var container := Node2D.new()
	container.name = "RefStrokes"
	panel.add_child(container)

	var strokes: Array = SvgParser.load_strokes(str(_candidates[index].get("svg", "")))
	if strokes.is_empty():
		return
	# Le viewBox du SVG fait 109x109 : on met à l'échelle pour remplir le panneau.
	var scale := minf(panel.size.x, panel.size.y - 26.0) / 109.0
	var offset := Vector2((panel.size.x - 109.0 * scale) / 2.0, 8.0)
	for stroke in strokes:
		var line := Line2D.new()
		for p in stroke:
			line.add_point(p * scale + offset)
		line.width = REF_STROKE_WIDTH
		line.default_color = REF_STROKE_COLOR
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		container.add_child(line)


## Clic/tap sur une référence -> elle devient le kanji actif (scoring).
func _on_ref_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_select_reference(index)


## Sélectionne le kanji index : met à jour par_time_ms + surligne la référence.
func _select_reference(index: int) -> void:
	if index >= _candidates.size():
		return
	_selected_index = index
	par_time_ms = int(_candidates[index].get("par_time_ms", par_time_ms))
	for i in range(_ref_panels.size()):
		var panel: Panel = _ref_panels[i]
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.961, 0.961, 0.961)
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 3
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_right = 6
		sb.corner_radius_bottom_left = 6
		if i == index:
			sb.border_color = Color(0.05, 0.7, 0.2, 1)  # vert : kanji actif
		else:
			sb.border_color = Color(0.5, 0.5, 0.5, 1)
		panel.add_theme_stylebox_override("panel", sb)


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
	_drawing_container.add_child(current_line)


func _add_point(pos: Vector2) -> void:
	current_stroke.append(pos)
	current_line.add_point(pos)


func _end_stroke() -> void:
	if not drawing:
		return
	drawing = false
	# On ne garde que les traits ayant au moins 2 points (un vrai tracé).
	if current_stroke.size() >= 2:
		player_strokes.append(current_stroke)
		_stroke_lines.append(current_line)
	else:
		current_line.queue_free()
	current_stroke = PackedVector2Array()
	current_line = null


func _clear_drawing() -> void:
	_end_stroke()
	# On ne supprime QUE les traits du joueur. Les références ne sont jamais
	# touchées (ce sont des enfants des panneaux de référence, pas ici).
	for child in _drawing_container.get_children():
		child.queue_free()
	player_strokes.clear()
	_stroke_lines.clear()


func _on_clear_pressed() -> void:
	_clear_drawing()
	_result_label.text = "Zone effacée. Dessine le kanji à nouveau."


## Retour : retire le DERNIER trait dessiné (undo unitaire). Ne fait rien si
## aucun trait n'est présent.
func _on_undo_pressed() -> void:
	_end_stroke()
	if player_strokes.is_empty():
		_result_label.text = "Aucun trait à retirer."
		return
	player_strokes.pop_back()
	var line = _stroke_lines.pop_back()
	if is_instance_valid(line):
		line.queue_free()
	_result_label.text = "Dernier trait retiré. (%d trait(s) restant(s))" % player_strokes.size()


# ---------------------------------------------------------------------------
# Validation / annulation
# ---------------------------------------------------------------------------

func _on_validate_pressed() -> void:
	_end_stroke()

	var ref_svg := str(_candidates[_selected_index].get("svg", ""))
	var ref_strokes: Array = SvgParser.load_strokes(ref_svg)
	if ref_strokes.is_empty():
		_result_label.text = "Erreur : impossible de charger le SVG de référence."
		return
	if player_strokes.is_empty():
		_result_label.text = "Dessine d'abord le kanji avant de valider !"
		return

	var elapsed_ms := Time.get_ticks_msec() - _open_time_ms
	var result: Dictionary = StrokeScoring.compute_score(player_strokes, ref_strokes)
	_result_label.text = "Score : %d / 100" % result.score
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
	_draw_panel.add_theme_stylebox_override("panel", sb)
	var target := _score_color(score)
	# Apparition rapide de la couleur, puis retour progressif au fond clair
	var tween := create_tween()
	tween.tween_property(sb, "bg_color", target, 0.15)
	tween.tween_property(sb, "bg_color", DRAW_BG_COLOR, 0.65)
	tween.tween_callback(func() -> void:
		_draw_panel.remove_theme_stylebox_override("panel"))


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
