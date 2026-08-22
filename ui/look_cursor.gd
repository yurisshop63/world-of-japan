extends Control
## Curseur de contrôle de la caméra (regard), type "manche à balai" — position
## neutre sur la grille B13 (ligne B = 2e ligne, colonne 13 sur 24 depuis la
## droite, cf. convention GridOverlay). On le tire et le maintient écarté de sa
## position neutre pour faire tourner la caméra EN CONTINU (vitesse linéaire
## selon l'écart, pas de relation angle=position) :
## - horizontal → yaw (rotation Y du joueur, réutilise l'axe du look souris) ;
## - vertical → pitch (rotation X de camera_pivot, clamp ±90°).
##
## Différence clé avec le joystick de déplacement : au relâchement il NE revient
## PAS au centre — la rotation continue tant que la poignée reste écartée
## (comportement sticky). Seule exception : si on relâche près de la position
## neutre (rayon SNAPBACK_THRESHOLD), la poignée s'aligne dessus (petit tween)
## et la vitesse retombe à 0. Le snapback ne réinitialise QUE la position de la
## poignée/la vitesse — pas l'orientation de la caméra.
##
## La vitesse normalisée est exposée via MobileInput.look_vector (x = yaw,
## y = pitch, chacun dans [-1,1]) et lue par player.gd chaque frame.

const ROWS := 11
const COLS := 24

## Vitesse de rotation max (rad/s) à pleine déflexion — à régler en playtest.
const VITESSE_MAX_RAD_PAR_SEC := 2.0
## Rayon (px) autour de la position neutre : relâcher dedans déclenche le
## snapback automatique (recentrage + arrêt de la rotation).
const SNAPBACK_THRESHOLD := 10.0
## Rayon max de déplacement de la poignée autour de la position neutre.
const HANDLE_TRAVEL := 60.0
## Rayon visuel de la poignée (dessin).
const HANDLE_RADIUS := 16.0

## Position neutre de la poignée, en coordonnées locales du Control (= size/2,
## le Control étant centré sur la case B13).
var _neutral := Vector2.ZERO
## Position courante de la poignée, en coordonnées locales du Control.
var _handle_offset := Vector2.ZERO
var _is_touching := false
var _snapping := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_geometry()
	get_viewport().size_changed.connect(_apply_geometry)
	queue_redraw()


## Positionne le Control sur la case B13 et recentre la poignée (sauf pendant
## un drag). Colonne 13 depuis la droite → index 24 - 13 = 11 depuis la gauche.
func _apply_geometry() -> void:
	var vp := get_viewport_rect().size
	var cell_w := vp.x / COLS
	var cell_h := vp.y / ROWS
	var half := HANDLE_TRAVEL + HANDLE_RADIUS + 4.0
	position = Vector2((24 - 13) * cell_w + cell_w / 2.0, (1) * cell_h + cell_h / 2.0) - Vector2(half, half)
	size = Vector2(half * 2.0, half * 2.0)
	_neutral = Vector2(half, half)
	if not _is_touching:
		_handle_offset = _neutral
	queue_redraw()


# -------------------------------------------------
# Saisie tactile / souris (pattern virtual_joystick.gd)
# -------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_touch(event.position)
		else:
			_end_touch()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_touch(event.position)
		else:
			_end_touch()
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _is_touching:
			_move_handle(event.position)


func _start_touch(local_pos: Vector2) -> void:
	_is_touching = true
	_snapping = false
	MobileInput.look_active = true
	_move_handle(local_pos)


func _move_handle(local_pos: Vector2) -> void:
	# Clamp : la poignée ne s'écarte jamais au-delà de HANDLE_TRAVEL du centre.
	var delta := local_pos - _neutral
	if delta.length() > HANDLE_TRAVEL:
		delta = delta.normalized() * HANDLE_TRAVEL
	_handle_offset = _neutral + delta
	queue_redraw()


func _end_touch() -> void:
	if not _is_touching:
		return
	_is_touching = false
	# Snapback si on relâche près de la position neutre (sinon comportement
	# sticky : la poignée reste où elle est et la rotation continue).
	if _handle_offset.distance_to(_neutral) <= SNAPBACK_THRESHOLD:
		_snapback()


## Recentre la poignée (tween court) et coupe la rotation immédiatement.
## Ne touche PAS à l'orientation de la caméra (seul l'écart/vitesse est remis
## à zéro).
func _snapback() -> void:
	_snapping = true
	MobileInput.look_active = false
	MobileInput.look_vector = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "_handle_offset", _neutral, 0.12).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func() -> void: _snapping = false)


func _process(_delta: float) -> void:
	_update_look()
	queue_redraw()


## Met à jour look_vector selon l'écart de la poignée par rapport au centre.
## Vitesse linéaire : (distance / HANDLE_TRAVEL) * VITESSE_MAX, en continu tant
## que la poignée est écartée (même sans être touchée — comportement sticky).
func _update_look() -> void:
	var delta := _handle_offset - _neutral
	var dist := delta.length()
	if _snapping or dist <= SNAPBACK_THRESHOLD:
		MobileInput.look_vector = Vector2.ZERO
		return
	MobileInput.look_vector = (delta / HANDLE_TRAVEL).limit_length(1.0)


func _draw() -> void:
	# Base : petit cercle discret à la position neutre (repère de centrage).
	draw_circle(_neutral, HANDLE_RADIUS, Color(1, 1, 1, 0.12))
	draw_arc(_neutral, HANDLE_RADIUS, 0, TAU, 32, Color(1, 1, 1, 0.3), 2.0)
	# Poignée : cercle qui suit le doigt / la position relâchée.
	draw_circle(_handle_offset, HANDLE_RADIUS, Color(1, 1, 1, 0.3))
	draw_arc(_handle_offset, HANDLE_RADIUS, 0, TAU, 32, Color(1, 1, 1, 0.7), 2.0)
