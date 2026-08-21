extends CharacterBody3D

# Type élémentaire du mob — détermine la silhouette (assemblage de primitives),
# la palette et l'échelle. Un seul mob.tscn, paramétré par ce champ (choix :
# une scène unique plutôt que 7 scènes séparées, plus simple à maintenir).
enum MobType {
	FEU,      # 火 — flamme rouge/orange
	EAU,      # 水 — sphère bleue arrondie
	TERRE,    # 土 — bloc brun rocheux
	LUNE,     # 月 (lundi) — bleu pâle/argenté, arrondi, cratères
	BOIS,     # 木 (jeudi) — tronc + feuillage
	OR,       # 金 (vendredi) — lingot doré + pépites
	SOLEIL,   # 日 (dimanche) — jaune/orange rayonnant
}

@export var mob_type: MobType = MobType.FEU
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

var _visual_parts: Array = []
var _base_colors := {}

func _ready():
	spawn_position = global_position
	health_fill.scale.x = 1.0
	player = get_tree().get_root().get_node("Main/Player")
	_build_visual()
	health_bar.position.y = _bar_height()

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
	var target_color = Color(1, 1, 0) if value else Color(0.6, 0.2, 0.2)
	for mi in _visual_parts:
		var mat = mi.material_override
		if mat == null:
			continue
		if value:
			_base_colors[mat] = mat.albedo_color
			mat.albedo_color = Color(1, 1, 0)
		else:
			mat.albedo_color = _base_colors.get(mat, Color(0.6, 0.2, 0.2))

# -------------------------------------------------
# Construction du modèle (primitives low-poly)
# -------------------------------------------------

func _build_visual():
	# Vide le conteneur si la scène a été réinstanciée
	for child in mesh.get_children():
		child.queue_free()
	_visual_parts.clear()
	_base_colors.clear()

	match mob_type:
		MobType.FEU:
			_build_feu()
		MobType.EAU:
			_build_eau()
		MobType.TERRE:
			_build_terre()
		MobType.LUNE:
			_build_lune()
		MobType.BOIS:
			_build_bois()
		MobType.OR:
			_build_or()
		MobType.SOLEIL:
			_build_soleil()

func _add_part(pmesh: PrimitiveMesh, pos: Vector3, color: Color,
		rot_deg := Vector3.ZERO, pscale := Vector3.ONE,
		metallic := 0.0, roughness := 0.8):
	var mi = MeshInstance3D.new()
	mi.mesh = pmesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = pscale
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	mi.material_override = mat
	mesh.add_child(mi)
	_visual_parts.append(mi)

func _sphere(radius: float) -> SphereMesh:
	var s = SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 16
	s.rings = 8
	return s

func _box(size: Vector3) -> BoxMesh:
	var b = BoxMesh.new()
	b.size = size
	return b

func _cyl(bottom: float, top: float, height: float) -> CylinderMesh:
	var c = CylinderMesh.new()
	c.bottom_radius = bottom
	c.top_radius = top
	c.height = height
	c.radial_segments = 10
	return c

func _bar_height() -> float:
	match mob_type:
		MobType.BOIS:
			return 1.8
		MobType.OR:
			return 1.3
		MobType.SOLEIL:
			return 1.4
	return 1.4

func _build_feu():
	# Corps de flamme : sphère rouge + deux flammes orange/jaune au-dessus.
	_add_part(_sphere(0.35), Vector3(0, 0.35, 0), Color(0.85, 0.15, 0.1))
	_add_part(_sphere(0.28), Vector3(0, 0.72, 0), Color(1, 0.5, 0.1))
	_add_part(_sphere(0.18), Vector3(0, 1.05, 0), Color(1, 0.85, 0.3))

func _build_eau():
	# Sphère arrondie aplatie + vaguelettes à la base.
	_add_part(_sphere(0.4), Vector3(0, 0.38, 0), Color(0.2, 0.5, 0.9),
			Vector3.ZERO, Vector3(1.0, 0.75, 1.0))
	_add_part(_cyl(0.3, 0.3, 0.05), Vector3(0, 0.08, 0), Color(0.6, 0.82, 1))
	_add_part(_cyl(0.22, 0.22, 0.04), Vector3(0, 0.0, 0), Color(0.5, 0.75, 0.95))

func _build_terre():
	# Bloc rocheux brun + petit sommet clair.
	_add_part(_box(Vector3(0.6, 0.6, 0.6)), Vector3(0, 0.38, 0), Color(0.5, 0.36, 0.2))
	_add_part(_box(Vector3(0.38, 0.22, 0.38)), Vector3(0, 0.76, 0), Color(0.62, 0.46, 0.28))
	_add_part(_box(Vector3(0.2, 0.14, 0.2)), Vector3(0.28, 0.6, 0.14), Color(0.66, 0.5, 0.32))

func _build_lune():
	# Sphère bleu pâle/argentée + cratères gris à la surface.
	_add_part(_sphere(0.4), Vector3(0, 0.4, 0), Color(0.8, 0.85, 0.92))
	_add_part(_sphere(0.07), Vector3(0.2, 0.55, 0.15), Color(0.5, 0.52, 0.58))
	_add_part(_sphere(0.06), Vector3(-0.16, 0.5, -0.22), Color(0.5, 0.52, 0.58))
	_add_part(_sphere(0.05), Vector3(0.05, 0.68, -0.1), Color(0.55, 0.58, 0.64))
	_add_part(_sphere(0.06), Vector3(-0.05, 0.28, 0.28), Color(0.5, 0.52, 0.58))

func _build_bois():
	# Tronc cylindrique brun + branches horizontales + feuillage.
	_add_part(_cyl(0.16, 0.12, 0.8), Vector3(0, 0.4, 0), Color(0.42, 0.3, 0.16))
	_add_part(_cyl(0.05, 0.05, 0.45), Vector3(-0.12, 0.85, 0), Color(0.45, 0.33, 0.18),
			Vector3(0, 0, -90))
	_add_part(_cyl(0.05, 0.05, 0.45), Vector3(0.12, 0.85, 0), Color(0.45, 0.33, 0.18),
			Vector3(0, 0, -90))
	_add_part(_sphere(0.3), Vector3(0, 1.05, 0), Color(0.2, 0.55, 0.25))
	_add_part(_sphere(0.2), Vector3(0.16, 1.28, 0.1), Color(0.32, 0.65, 0.3))
	_add_part(_sphere(0.18), Vector3(-0.14, 1.2, -0.12), Color(0.24, 0.58, 0.27))

func _build_or():
	# Lingot doré métallique + pépites.
	_add_part(_box(Vector3(0.6, 0.26, 0.26)), Vector3(0, 0.28, 0), Color(0.9, 0.72, 0.15),
			Vector3.ZERO, Vector3.ONE, 0.7, 0.25)
	_add_part(_box(Vector3(0.42, 0.18, 0.18)), Vector3(0, 0.5, 0), Color(1, 0.85, 0.3),
			Vector3.ZERO, Vector3.ONE, 0.7, 0.2)
	_add_part(_sphere(0.07), Vector3(0.32, 0.1, 0.1), Color(1, 0.88, 0.35),
			Vector3.ZERO, Vector3.ONE, 0.6, 0.3)
	_add_part(_sphere(0.06), Vector3(-0.3, 0.08, -0.12), Color(0.95, 0.8, 0.28),
			Vector3.ZERO, Vector3.ONE, 0.6, 0.3)

func _build_soleil():
	# Sphère jaune/orange + 8 rayons radiaux.
	_add_part(_sphere(0.35), Vector3(0, 0.35, 0), Color(1, 0.8, 0.15))
	for i in range(8):
		var angle = TAU * i / 8.0
		var dir = Vector3(cos(angle), 0, sin(angle))
		_add_part(_box(Vector3(0.1, 0.12, 0.32)),
				dir * 0.52 + Vector3(0, 0.35, 0),
				Color(1, 0.9, 0.4),
				Vector3(0, -rad_to_deg(angle), 0))
