extends CharacterBody3D

@export var max_health = 20
var health = 20

@export var chase_speed = 10.0
@export var melee_range = 1.5
@export var attack_interval = 2.0
@export var attack_min_damage = 1
@export var attack_max_damage = 5
@export var leash_give_up_range = 25.0
@export var leash_timeout = 12.0
@export var respawn_time = 15.0
@export var regen_rate = 5.0

enum State { IDLE, CHASE, RETURN, DEAD }
var state = State.IDLE

var spawn_position = Vector3.ZERO
var player = null
var attack_timer = 0.0
var leash_timer = 0.0
var gravity = 9.8

@onready var mesh = $MeshInstance3D
@onready var health_fill = $HealthBar/Fill
@onready var collision = $CollisionShape3D
@onready var health_bar = $HealthBar

func _ready():
	spawn_position = global_position
	health_fill.scale.x = 1.0
	player = get_tree().get_root().get_node("Main/Player")

func _physics_process(delta):
	if state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	match state:
		State.IDLE:
			velocity.x = 0
			velocity.z = 0
		State.CHASE:
			_process_chase(delta)
		State.RETURN:
			_process_return(delta)

	move_and_slide()

func _process_chase(delta):
	var dist_to_player = global_position.distance_to(player.global_position)

	if dist_to_player > leash_give_up_range:
		leash_timer += delta
		if leash_timer >= leash_timeout:
			state = State.RETURN
			return
	else:
		leash_timer = 0.0

	if dist_to_player > melee_range:
		var dir = (player.global_position - global_position)
		dir.y = 0
		dir = dir.normalized()
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed
		attack_timer = 0.0
	else:
		velocity.x = 0
		velocity.z = 0
		attack_timer += delta
		if attack_timer >= attack_interval:
			attack_timer = 0.0
			var dmg = randi_range(attack_min_damage, attack_max_damage)
			PlayerStats.take_damage(dmg)
			print("Mob inflige ", dmg, " dégâts.")

func _process_return(delta):
	var dist_to_spawn = global_position.distance_to(spawn_position)
	if dist_to_spawn > 0.5:
		var dir = (spawn_position - global_position)
		dir.y = 0
		dir = dir.normalized()
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed
	else:
		velocity.x = 0
		velocity.z = 0
		state = State.IDLE
		leash_timer = 0.0
		health = clamp(health + regen_rate * delta, 0, max_health)
		health_fill.scale.x = float(health) / float(max_health)

func take_damage(amount):
	if state == State.DEAD:
		return

	health = clamp(health - amount, 0, max_health)
	health_fill.scale.x = float(health) / float(max_health)

	if state == State.IDLE or state == State.RETURN:
		state = State.CHASE
		leash_timer = 0.0

	if health <= 0:
		die()

func die():
	state = State.DEAD
	PlayerStats.add_xp(50)
	if TargetSystem.current_target == self:
		TargetSystem.select(null)

	mesh.visible = false
	health_bar.visible = false
	collision.disabled = true

	await get_tree().create_timer(respawn_time).timeout
	_respawn()

func _respawn():
	health = max_health
	global_position = spawn_position
	mesh.visible = true
	health_bar.visible = true
	collision.disabled = false
	health_fill.scale.x = 1.0
	state = State.IDLE

func set_selected(value):
	var mat = mesh.get_surface_override_material(0)
	if mat:
		mat.albedo_color = Color(1, 1, 0) if value else Color(0.6, 0.2, 0.2)
