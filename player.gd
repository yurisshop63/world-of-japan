extends CharacterBody3D

var speed = 10.0
var speed_multiplier_forward = 2.0
var rotation_speed = 2.5
var gravity = 9.8

var walk_time = 0.0
var walk_speed_visual = 8.0
var swing_amplitude = 0.6

var mouse_sensitivity = 0.003
var pitch = 0.0
var max_pitch = deg_to_rad(70.0)
var auto_run = false

# --- Commandes de combat façon DAoC (/face, /stick) ------------------------
const MELEE_RANGE := 1.5  # portée de mêlée des mobs (mob.gd: melee_range)
var sticking := false     # mode "collé à la cible" (toggle)

@onready var left_arm_pivot = $Model/LeftArmPivot
@onready var right_arm_pivot = $Model/RightArmPivot
@onready var left_leg_pivot = $Model/LeftLegPivot
@onready var right_leg_pivot = $Model/RightLegPivot
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

func _ready():
	PlayerStats.player_died.connect(_on_player_died)
	PlayerStats.bind_position = Vector3(0, 1.5, 0)
	global_position = PlayerStats.bind_position

func _physics_process(delta):
	if global_position.y < -10:
		_on_player_died()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	# Rotation clavier uniquement quand on n’est pas en mode souris
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if Input.is_key_pressed(KEY_LEFT):
			rotate_y(rotation_speed * delta)
		if Input.is_key_pressed(KEY_RIGHT):
			rotate_y(-rotation_speed * delta)

	var input_dir = Vector3.ZERO
	var going_forward = auto_run

	if Input.is_key_pressed(KEY_UP) or auto_run:
		input_dir.z -= 1
		going_forward = true
	if Input.is_key_pressed(KEY_DOWN):
		input_dir.z += 1
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_Z):
		input_dir.x += 1

	# Input mobile (joystick virtuel) — combiné au clavier, pas de remplacement.
	# MobileInput.move_vector est en repère écran : x = droite (+), y = bas (+).
	var mv := MobileInput.move_vector
	if mv.length() > 0.01:
		input_dir.x += mv.x
		input_dir.z += mv.y
		if mv.y < -0.5:
			going_forward = true

	var is_moving = input_dir.length() > 0.01
	input_dir = input_dir.normalized()

	var current_speed = speed
	if going_forward:
		current_speed = speed * speed_multiplier_forward

	var direction = (transform.basis * input_dir).normalized()
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	# Mode STICK : la vélocité est écrasée pour suivre la cible (comme mob.gd
	# dans _process_chase). La gravité / collision de ce script reste active.
	if sticking:
		_process_stick()

	move_and_slide()

	# Animation de marche
	if is_moving:
		walk_time += delta * walk_speed_visual * (current_speed / speed)
		left_leg_pivot.rotation.x = sin(walk_time) * swing_amplitude
		right_leg_pivot.rotation.x = -sin(walk_time) * swing_amplitude
		left_arm_pivot.rotation.x = -sin(walk_time) * swing_amplitude
		right_arm_pivot.rotation.x = sin(walk_time) * swing_amplitude
	else:
		left_leg_pivot.rotation.x = lerp(left_leg_pivot.rotation.x, 0.0, delta * 5.0)
		right_leg_pivot.rotation.x = lerp(right_leg_pivot.rotation.x, 0.0, delta * 5.0)
		left_arm_pivot.rotation.x = lerp(left_arm_pivot.rotation.x, 0.0, delta * 5.0)
		right_arm_pivot.rotation.x = lerp(right_arm_pivot.rotation.x, 0.0, delta * 5.0)

func _input(event):
	# Mode souris (Ctrl)
	if event is InputEventKey and event.keycode == KEY_CTRL:
		if event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Regard souris → pivote autour de la tête
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Yaw (gauche/droite) → on tourne le personnage
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Pitch (haut/bas) → on tourne uniquement le pivot de la caméra
		pitch = clamp(pitch + event.relative.y * mouse_sensitivity, -max_pitch, max_pitch)
		camera_pivot.rotation.x = pitch

	# Course automatique
	if event is InputEventKey and event.pressed and event.keycode == KEY_NUMLOCK:
		auto_run = not auto_run
		print("Course automatique : ", "ON" if auto_run else "OFF")

func _on_player_died():
	global_position = PlayerStats.bind_position
	velocity = Vector3.ZERO
	sticking = false
	PlayerStats.health = PlayerStats.max_health
	PlayerStats.health_changed.emit()

# -------------------------------------------------
# Commandes de combat façon DAoC (appelables par script
# pour réutilisation future par les boutons mobiles)
# -------------------------------------------------

## /face — oriente instantanément le joueur vers la cible (rotation Y seule).
## Ne fait rien si aucune cible (log discret, pas d'erreur).
func face():
	var target = TargetSystem.current_target
	if target == null or not is_instance_valid(target):
		print("FACE : aucune cible sélectionnée.")
		return
	var dir = target.global_position - global_position
	dir.y = 0
	if dir.length() < 0.01:
		return
	look_at(global_position + dir, Vector3.UP)

## /stick — toggle du mode "collé à la cible" (suit + reste face à elle).
func toggle_stick():
	sticking = not sticking
	print("STICK : ", "activé" if sticking else "désactivé")

func _process_stick():
	var target = TargetSystem.current_target
	if target == null or not is_instance_valid(target):
		sticking = false
		print("STICK : cible invalide, désactivé.")
		return

	var dir = target.global_position - global_position
	dir.y = 0
	var dist = dir.length()
	if dist > 0.01:
		look_at(global_position + dir, Vector3.UP)

	if dist > MELEE_RANGE:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = 0
		velocity.z = 0

func _unhandled_key_input(event):
	if event.pressed and not event.echo:
		match event.keycode:
			KEY_T:
				PlayerStats.take_damage(10)
			KEY_Y:
				PlayerStats.heal(10)
			KEY_U:
				PlayerStats.add_power(15)
			KEY_I:
				PlayerStats.add_xp(37)
			KEY_O:
				PlayerStats.add_pvp_xp(20)
		# Commandes de combat /face /stick — touches configurables (KeybindConfig)
		if event.keycode == KeybindConfig.get_keycode("face"):
			face()
		elif event.keycode == KeybindConfig.get_keycode("stick"):
			toggle_stick()
