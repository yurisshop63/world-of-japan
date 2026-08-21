extends Node3D

@export var radius: float = 50.0          # Rayon total du terrain (hexagone)
@export var wall_height: float = 20.0
@export var wall_thickness: float = 3.0
@export var hex_size: float = 5.0         # Taille d'un petit hexagone du sol
@export var noise_frequency: float = 0.04
@export var noise_seed: int = 1337

# Palette du sol (interpolée selon le bruit) : roche / terre brune / herbe.
const COLOR_ROCK := Color(0.52, 0.48, 0.42)
const COLOR_EARTH := Color(0.47, 0.37, 0.22)
const COLOR_GRASS := Color(0.3, 0.52, 0.25)

var _noise: FastNoiseLite

func _ready():
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 3
	_noise.frequency = noise_frequency
	_noise.seed = noise_seed
	create_hex_map()

func create_hex_map():
	# -------------------------------------------------
	# 1. SOL VISUEL (grille de petits hexagones colorés par le bruit)
	# -------------------------------------------------
	_create_hex_tiles()

	# -------------------------------------------------
	# 2. COLLISION DU SOL (très fiable)
	# -------------------------------------------------
	_create_floor_collision()

	# -------------------------------------------------
	# 3. 6 MURS SOLIDES
	# -------------------------------------------------
	_create_walls()

# Grille hexagonale de petits hexagones couvrant le disque de rayon `radius`.
# Chaque hexagone reçoit une couleur dérivée du bruit FastNoiseLite (position
# du centre) interpolée entre roche / terre / herbe → aspect naturel, sans
# texture externe. C'est le choix "noise-based vertex/tile color" : le plus
# simple à intégrer dans le code existant (une boucle par tuile, un matériau
# StandardMaterial3D par tuile).
func _create_hex_tiles():
	var hex_h := hex_size                     # distance centre→sommet
	var step_x := sqrt(3.0) * hex_h           # espacement horizontal
	var step_z := 1.5 * hex_h                 # espacement vertical
	var rows := int(ceil(radius / step_z)) + 2
	var cols := int(ceil(radius / step_x)) + 2

	for r in range(-rows, rows + 1):
		for q in range(-cols, cols + 1):
			var z := r * step_z
			var x := q * step_x
			if r % 2 != 0:
				x += step_x * 0.5
			if Vector2(x, z).length() > radius:
				continue
			_create_hex_tile(Vector2(x, z))

func _create_hex_tile(center: Vector2):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Hexagone "pointy-top" : sommet à angle 30°+60°*i
	for i in range(6):
		var angle = deg_to_rad(30.0 + 60.0 * i)
		var px = cos(angle) * hex_size
		var pz = sin(angle) * hex_size
		st.add_vertex(Vector3(center.x, 0.0, center.y))
		st.add_vertex(Vector3(center.x + px, 0.0, center.y + pz))
		var angle2 = deg_to_rad(30.0 + 60.0 * ((i + 1) % 6))
		var qx = cos(angle2) * hex_size
		var qz = sin(angle2) * hex_size
		st.add_vertex(Vector3(center.x + qx, 0.0, center.y + qz))

	st.generate_normals()

	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	mesh_instance.mesh = st.commit()

	var mat = StandardMaterial3D.new()
	mat.albedo_color = _color_at(center)
	mat.roughness = 0.9
	mesh_instance.material_override = mat

# Couleur du sol à une position : bruit [-1,1] → mélange roche/terre/herbe.
func _color_at(pos: Vector2) -> Color:
	var n := _noise.get_noise_2d(pos.x, pos.y)  # -1..1
	# n < -0.25 → roche ; -0.25..0.15 → terre ; > 0.15 → herbe
	var t := clampf((n + 1.0) * 0.5, 0.0, 1.0)
	if t < 0.35:
		return COLOR_ROCK.lerp(COLOR_EARTH, t / 0.35)
	elif t < 0.6:
		return COLOR_EARTH.lerp(COLOR_GRASS, (t - 0.35) / 0.25)
	else:
		return COLOR_GRASS.lerp(COLOR_ROCK.lerp(COLOR_GRASS, 0.5), (t - 0.6) / 0.4)

func _create_floor_collision():
	var floor_body = StaticBody3D.new()
	add_child(floor_body)

	var floor_col = CollisionShape3D.new()
	floor_body.add_child(floor_col)

	var floor_shape = BoxShape3D.new()
	floor_shape.size = Vector3(radius * 2.3, 1.0, radius * 2.3)
	floor_col.shape = floor_shape
	floor_body.position.y = -0.5   # le dessus du sol est à Y = 0

func _create_walls():
	for i in range(6):
		var angle1 = i * TAU / 6.0
		var angle2 = (i + 1) * TAU / 6.0

		var p1 = Vector3(cos(angle1) * radius, 0, sin(angle1) * radius)
		var p2 = Vector3(cos(angle2) * radius, 0, sin(angle2) * radius)

		var mid = (p1 + p2) * 0.5
		var edge_dir = (p2 - p1).normalized()
		var outward = Vector3(mid.x, 0, mid.z).normalized()

		var wall_body = StaticBody3D.new()
		add_child(wall_body)

		var wall_col = CollisionShape3D.new()
		wall_body.add_child(wall_col)

		var wall_shape = BoxShape3D.new()
		var length = p1.distance_to(p2) + 2.0
		wall_shape.size = Vector3(length, wall_height, wall_thickness)
		wall_col.shape = wall_shape

		# Position : légèrement à l’extérieur de l’hexagone
		wall_body.position = mid + outward * (wall_thickness * 0.5)
		wall_body.position.y = wall_height * 0.5

		# Orientation correcte (la plus fiable)
		var wall_basis = Basis()
		wall_basis.x = edge_dir
		wall_basis.y = Vector3.UP
		wall_basis.z = outward
		wall_body.transform.basis = wall_basis.orthonormalized()
