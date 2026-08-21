extends Node3D

@export var radius: float = 50.0          # Tu as mis 50 pour tester, c’est parfait
@export var wall_height: float = 20.0
@export var wall_thickness: float = 3.0
@export var material_color: Color = Color(0.35, 0.55, 0.25)

func _ready():
	create_hex_map()

func create_hex_map():
	# -------------------------------------------------
	# 1. SOL VISUEL (hexagone plat)
	# -------------------------------------------------
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var verts = []
	for i in range(6):
		var angle = i * TAU / 6.0
		verts.append(Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))

	var center = Vector3.ZERO

	for i in range(6):
		var next = (i + 1) % 6
		st.add_vertex(center)
		st.add_vertex(verts[i])
		st.add_vertex(verts[next])

	st.generate_normals()
	mesh_instance.mesh = st.commit()

	var mat = StandardMaterial3D.new()
	mat.albedo_color = material_color
	mat.roughness = 0.9
	mesh_instance.material_override = mat

	# -------------------------------------------------
	# 2. COLLISION DU SOL (très fiable)
	# -------------------------------------------------
	var floor_body = StaticBody3D.new()
	add_child(floor_body)

	var floor_col = CollisionShape3D.new()
	floor_body.add_child(floor_col)

	var floor_shape = BoxShape3D.new()
	floor_shape.size = Vector3(radius * 2.3, 1.0, radius * 2.3)
	floor_col.shape = floor_shape
	floor_body.position.y = -0.5   # le dessus du sol est à Y = 0

	# -------------------------------------------------
	# 3. 6 MURS SOLIDES (inspirés de la méthode CSG)
	# -------------------------------------------------
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
