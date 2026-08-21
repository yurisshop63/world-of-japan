extends Control
## Joystick virtuel mobile : base (cercle fixe) + stick (cercle qui suit le
## doigt dans un rayon limité). Émet un Vector2 normalisé via l'autoload
## MobileInput.move_vector (0,0 = relâché, magnitude 1 = poussé au max).
##
## Deux petits boutons FACE/STICK en arc à droite du cercle (hors du rayon de
## déplacement pour ne pas gêner le pouce) : FACE appelle Player.face(),
## STICK appelle Player.toggle_stick() et affiche un état visuel actif/inactif
## selon Player.sticking.
##
## Repositionnement : appui long (long_press_time) puis glissement, comme
## draggable_button.gd. Synchronisation croisée avec le menu circulaire :
## menu et joystick sont TOUJOURS sur des côtés opposés (source de vérité :
## MenuConfig.side, voir PROGRESS.md étape 1).

@export var long_press_time: float = 0.35
@export var drag_threshold: float = 14.0

const RADIUS_BASE := 60.0
const RADIUS_STICK := 32.0
const MAX_OFFSET := 36.0
# Zone morte du stick (fraction de MAX_OFFSET) : tant que le doigt/curseur
# reste dans cette zone autour du centre, move_vector reste à ZERO (évite
# qu'un tremblement ou un résidu de position au relâchement fasse dériver
# le déplacement). 12% ≈ 4.3 px sur MAX_OFFSET=36.
const DEAD_ZONE := 0.12

const BUTTON_SIZE := 52.0
const BUTTON_GAP := 14.0

## Taille totale du Control (contient base + boutons à droite).
const WIDTH := 260.0
const HEIGHT := 160.0

var _stick_offset := Vector2.ZERO
var _is_touching := false
var _is_dragging := false
var _press_pos := Vector2.ZERO
var _long_press_timer: Timer
var _ignore_next_config := false

var _face_button: Button
var _stick_button: Button
var _player_ref: Node3D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

	_apply_opposite_side()

	MenuConfig.config_changed.connect(_on_menu_config_changed)
	get_viewport().size_changed.connect(_on_viewport_resized)

	_long_press_timer = Timer.new()
	_long_press_timer.one_shot = true
	_long_press_timer.wait_time = long_press_time
	add_child(_long_press_timer)
	_long_press_timer.timeout.connect(_on_long_press_timeout)

	_build_buttons()


func _build_buttons() -> void:
	# Position en arc à droite du cercle, hors du rayon du stick.
	var face_pos := Vector2(RADIUS_BASE + 40, -BUTTON_SIZE / 2.0 - BUTTON_GAP)
	var stick_pos := Vector2(RADIUS_BASE + 40, BUTTON_SIZE / 2.0 + BUTTON_GAP)

	_face_button = _make_round_button(face_pos, "FACE")
	_face_button.name = "FaceButton"
	_face_button.pressed.connect(_on_face_pressed)

	_stick_button = _make_round_button(stick_pos, "STICK")
	_stick_button.name = "StickButton"
	_stick_button.pressed.connect(_on_stick_pressed)


func _make_round_button(pos: Vector2, text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	btn.add_theme_font_size_override("font_size", 11)
	btn.focus_mode = Control.FOCUS_NONE
	MenuStyle.apply_round_styles(btn, int(BUTTON_SIZE / 2), Color(0.05, 0.05, 0.05, 0.9))
	add_child(btn)
	return btn


func _player() -> Node3D:
	if _player_ref == null or not is_instance_valid(_player_ref):
		_player_ref = get_tree().get_root().get_node_or_null("Main/Player")
	return _player_ref


func _on_face_pressed() -> void:
	var p := _player()
	if p:
		p.face()


func _on_stick_pressed() -> void:
	var p := _player()
	if p:
		p.toggle_stick()


# -------------------------------------------------
# Côté / position (Étape 4) — miroir du menu
# -------------------------------------------------

## Côté opposé au menu : la source de vérité est MenuConfig.side.
func _opposite_side() -> int:
	return _opposite(MenuConfig.side)


func _opposite(side: int) -> int:
	return MenuConfig.Side.LEFT if side == MenuConfig.Side.RIGHT else MenuConfig.Side.RIGHT


func _apply_opposite_side() -> void:
	_apply_position_for_side(_opposite_side())


## Positionne le joystick du côté donné (repositionnement immédiat à chaque
## bascule ; le joueur peut ensuite le redragger librement).
func _apply_position_for_side(side: int) -> void:
	var vp := get_viewport_rect().size
	var margin := 24.0
	var pos := Vector2.ZERO
	if side == MenuConfig.Side.RIGHT:
		pos = Vector2(vp.x - WIDTH - margin, vp.y - HEIGHT - margin)
	else:
		pos = Vector2(margin, vp.y - HEIGHT - margin)
	position = pos
	size = Vector2(WIDTH, HEIGHT)


func _on_menu_config_changed() -> void:
	if _ignore_next_config:
		_ignore_next_config = false
		return
	_apply_opposite_side()


func _on_viewport_resized() -> void:
	_apply_opposite_side()


# -------------------------------------------------
# Saisie tactile / souris (pattern draggable_button.gd)
# -------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_press(event.position)
		else:
			_end_press()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_press(event.position)
		else:
			_end_press()
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _is_touching:
			_update_press(event.position)


func _start_press(local_pos: Vector2) -> void:
	_is_touching = true
	_is_dragging = false
	_press_pos = get_global_mouse_position()
	_long_press_timer.start()
	_update_stick(local_pos)


func _update_press(local_pos: Vector2) -> void:
	if not _is_dragging:
		# Le doigt bouge significativement avant le long press : usage normal du
		# stick (pas un repositionnement) -> on annule le timer de drag.
		if get_global_mouse_position().distance_to(_press_pos) > drag_threshold:
			_long_press_timer.stop()
		_update_stick(local_pos)
	else:
		# Mode drag : le joystick entier suit le doigt.
		var vp := get_viewport_rect().size
		var target := get_global_mouse_position() - size / 2.0
		target.x = clamp(target.x, 0, vp.x - size.x)
		target.y = clamp(target.y, 0, vp.y - size.y)
		global_position = target


func _end_press() -> void:
	if not _is_touching:
		return
	_is_touching = false
	_long_press_timer.stop()

	if _is_dragging:
		_is_dragging = false
		# Le drag a fini : le stick revient au centre, l'input est coupé.
		_reset_stick()
		_on_drag_end()
	else:
		_reset_stick()


## Remet le stick au centre exact de sa base et coupe l'input : offset visuel
## = centre, move_vector = ZERO, active = false. Sans délai ni interpolation.
func _reset_stick() -> void:
	_stick_offset = _center()
	MobileInput.move_vector = Vector2.ZERO
	MobileInput.active = false
	queue_redraw()


func _on_long_press_timeout() -> void:
	if _is_touching and not _is_dragging:
		_is_dragging = true
		_reset_stick()
		modulate.a = 0.85


# -------------------------------------------------
# Stick : dessin + vector normalisé
# -------------------------------------------------

## Centre de la base du stick dans les coordonnées locales du Control.
func _center() -> Vector2:
	return Vector2(RADIUS_BASE, HEIGHT / 2.0)


func _update_stick(local_pos: Vector2) -> void:
	var center := _center()
	var delta := local_pos - center
	if delta.length() > MAX_OFFSET:
		delta = delta.normalized() * MAX_OFFSET
	_stick_offset = center + delta

	# Zone morte : tant que le doigt reste dans un rayon ~12% de MAX_OFFSET
	# autour du centre, move_vector reste à ZERO. Le stick visuel peut bouger,
	# mais l'input ne dérive pas (anti-tremblement / anti-résidu).
	if delta.length() <= MAX_OFFSET * DEAD_ZONE:
		MobileInput.move_vector = Vector2.ZERO
	else:
		MobileInput.move_vector = delta / MAX_OFFSET
	MobileInput.active = _is_touching
	queue_redraw()


func _draw() -> void:
	var center := _center()

	# Base : cercle fixe semi-transparent
	draw_circle(center, RADIUS_BASE, Color(1, 1, 1, 0.12))
	draw_arc(center, RADIUS_BASE, 0, TAU, 40, Color(1, 1, 1, 0.35), 2.0)

	# Stick : cercle plus petit qui suit le doigt
	draw_circle(_stick_offset, RADIUS_STICK, Color(1, 1, 1, 0.25))
	draw_arc(_stick_offset, RADIUS_STICK, 0, TAU, 32, Color(1, 1, 1, 0.6), 2.0)


# -------------------------------------------------
# Drag du joystick (repositionnement) + synchro croisée
# -------------------------------------------------

func _on_drag_end() -> void:
	modulate.a = 1.0

	var vp := get_viewport_rect().size
	var center_x := get_global_rect().get_center().x
	var released_side := MenuConfig.Side.LEFT if center_x < vp.x / 2.0 else MenuConfig.Side.RIGHT

	# Si le joystick a franchi la moitié opposée à sa position actuelle -> le
	# menu bascule de l'autre côté (même API que le drag du menu : set_side).
	# Le menu prend le côté OPPOSÉ au relâchement du joystick, pour que les
	# deux restent sur des côtés opposés.
	if released_side != _opposite_side():
		_ignore_next_config = true
		MenuConfig.set_side(_opposite(released_side))
	# Sinon : repositionnement libre du joystick (il reste où il est).


# -------------------------------------------------
# État du bouton STICK (visuel actif/inactif)
# -------------------------------------------------

func _process(_delta: float) -> void:
	var p := _player()
	if p == null:
		return
	var active: bool = p.sticking
	if _stick_button.get_meta("sticking", false) != active:
		_stick_button.set_meta("sticking", active)
		var color := Color(0.05, 0.55, 0.15, 0.9) if active else Color(0.05, 0.05, 0.05, 0.9)
		MenuStyle.apply_round_styles(_stick_button, int(BUTTON_SIZE / 2), color)
