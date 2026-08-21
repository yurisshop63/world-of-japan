class_name SvgParser
# -----------------------------------------------------------------------------
# SvgParser — Chargement et décodage des traits de référence d'un SVG KanjiVG.
# Lit le fichier, extrait chaque balise <path> puis échantillonne les courbes de
# Bézier (commandes C/Q/...) en une polyligne détaillée de points.
# -----------------------------------------------------------------------------


# Lit un fichier SVG et retourne un tableau de PackedVector2Array (un par trait).
static func load_strokes(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var text: String = file.get_as_text()
	var strokes: Array = []
	var re := RegEx.new()
	re.compile("<path[^>]*\\sd=\"([^\"]+)\"")
	for m in re.search_all(text):
		strokes.append(parse_path(m.get_string(1)))
	return strokes


# Décode un attribut d="..." en une polyligne de points (courbes échantillonnées)
static func parse_path(d: String) -> PackedVector2Array:
	var points := PackedVector2Array()
	var tokens: Array = tokenize_path(d)
	var i := 0
	var cmd := "M"
	var current := Vector2.ZERO
	var start := Vector2.ZERO
	var last_control := Vector2.ZERO
	var has_last_control := false

	while i < tokens.size():
		var tok: String = tokens[i]
		# Nouvelle commande (lettre)
		if tok.length() == 1 and tok in "MmLlCcSsQqTtZz":
			cmd = tok
			i += 1
			continue
		var rel := cmd == cmd.to_lower()
		var c: String = cmd.to_lower()
		match c:
			"m":
				var p := _next_vec2(tokens, i, current if rel else Vector2.ZERO)
				i += 2
				points.append(p)
				current = p
				start = p
				# Les paires de nombres suivantes implicites deviennent des lineto
				cmd = "l" if rel else "L"
				has_last_control = false
			"l":
				var p := _next_vec2(tokens, i, current if rel else Vector2.ZERO)
				i += 2
				points.append(p)
				current = p
				has_last_control = false
			"c":
				var base := current if rel else Vector2.ZERO
				var c1 := _next_vec2(tokens, i, base)
				var c2 := _next_vec2(tokens, i + 2, base)
				var p := _next_vec2(tokens, i + 4, base)
				i += 6
				append_cubic(points, current, c1, c2, p)
				last_control = c2
				has_last_control = true
				current = p
			"s":
				var base := current if rel else Vector2.ZERO
				var c1: Vector2 = current + (current - last_control) if has_last_control else current
				var c2 := _next_vec2(tokens, i, base)
				var p := _next_vec2(tokens, i + 2, base)
				i += 4
				append_cubic(points, current, c1, c2, p)
				last_control = c2
				has_last_control = true
				current = p
			"q":
				var base := current if rel else Vector2.ZERO
				var qc := _next_vec2(tokens, i, base)
				var p := _next_vec2(tokens, i + 2, base)
				i += 4
				append_quad(points, current, qc, p)
				last_control = qc
				has_last_control = true
				current = p
			"t":
				var tc: Vector2 = current + (current - last_control) if has_last_control else current
				var p := _next_vec2(tokens, i, current if rel else Vector2.ZERO)
				i += 2
				append_quad(points, current, tc, p)
				last_control = tc
				has_last_control = true
				current = p
			"z":
				points.append(start)
				current = start
				i += 1
				has_last_control = false
			_:
				i += 1
	return points


static func _next_vec2(tokens: Array, i: int, base: Vector2) -> Vector2:
	return Vector2(tokens[i].to_float(), tokens[i + 1].to_float()) + base


static func tokenize_path(d: String) -> Array:
	var re := RegEx.new()
	re.compile("[MmLlCcSsQqTtZz]|-?\\d+\\.?\\d*|-?\\d*\\.\\d+")
	var tokens: Array = []
	for m in re.search_all(d):
		tokens.append(m.get_string())
	return tokens


# Échantillonne une courbe de Bézier cubique en une série de points
static func append_cubic(points: PackedVector2Array, p0: Vector2, c1: Vector2, c2: Vector2, p: Vector2) -> void:
	for k in range(1, 17):
		var t := float(k) / 16.0
		var u := 1.0 - t
		points.append(u * u * u * p0 + 3.0 * u * u * t * c1 + 3.0 * u * t * t * c2 + t * t * t * p)


# Échantillonne une courbe de Bézier quadratique
static func append_quad(points: PackedVector2Array, p0: Vector2, c: Vector2, p: Vector2) -> void:
	for k in range(1, 13):
		var t := float(k) / 12.0
		var u := 1.0 - t
		points.append(u * u * p0 + 2.0 * u * t * c + t * t * p)
