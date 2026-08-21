class_name StrokeScoring
# -----------------------------------------------------------------------------
# StrokeScoring — Moteur de comparaison des tracés de kanji.
# Compare les traits dessinés par le joueur aux traits de référence :
# - UNE SEULE normalisation par côté, basée sur la boîte englobante de TOUS
#   les traits réunis (même centre, même échelle pour tous les traits) : les
#   proportions ET l'espacement relatif entre les traits comptent vraiment.
# - Comparaison trait par trait, dans l'ORDRE de dessin (trait 1 vs trait 1...).
# - SENS de tracé (départ -> arrivée) avec forte pénalité si inversé.
# - NOMBRE de traits avec pénalité proportionnelle.
# Retourne un score final de 0 à 100 via compute_score().
# -----------------------------------------------------------------------------

# Nombre de points utilisés pour ré-échantillonner un tracé avant comparaison
const SAMPLE_COUNT := 20
# Taille de référence de la boîte englobante globale après normalisation
const NORMAL_SIZE := 100.0
# Coefficient de conversion distance -> score (distance faible = score élevé)
# Calibré avec le cas "tracé humain imprécis" (rotation +-15° + décalage +-8) :
# score moyen 70-85 avec une discrimination aléatoire/croix acceptable.
const DISTANCE_TO_SCORE_FACTOR := 2.2


# Calcule le score complet. Retourne un dictionnaire avec les composantes.
# Le joueur peut dessiner n'importe où et à n'importe quelle taille : chaque
# côté est normalisé par SA propre boîte englobante globale, donc seules les
# proportions et la disposition RELATIVE des traits sont comparées.
static func compute_score(player: Array, reference: Array) -> Dictionary:
	var n := mini(player.size(), reference.size())
	if n == 0:
		return {"score": 0, "shape": 0.0, "count_ratio": 1.0, "per_stroke": []}
	# Cadre global de CHAQUE côté (boîte englobante de tous les traits réunis)
	var player_frame: Dictionary = compute_stroke_frame(player)
	var ref_frame: Dictionary = compute_stroke_frame(reference)
	var per_stroke: Array = []
	var total := 0.0
	for i in range(n):
		# La MÊME transformation est appliquée à chaque trait d'un côté :
		# les positions et proportions relatives entre traits sont conservées.
		var na := normalize_stroke_in_frame(player[i], player_frame, SAMPLE_COUNT)
		var nb := normalize_stroke_in_frame(reference[i], ref_frame, SAMPLE_COUNT)
		var d := avg_distance(na, nb)
		var s := distance_score(na, nb)
		total += s
		per_stroke.append({"distance": d, "shape": s, "score": s})
	var shape: float = total / float(n)
	var count_ratio := float(n) / float(maxi(player.size(), reference.size()))
	return {
		"score": int(round(shape * count_ratio)),
		"shape": shape,
		"count_ratio": count_ratio,
		"per_stroke": per_stroke,
	}


# Auto-test sans interface graphique : vérifie le scoring avec un tracé
# "parfait" (points de référence), un tracé aléatoire et un tracé "humain
# imprécis mais reconnaissable" (calibration). Affiche les scores.
static func run_auto_test() -> void:
	run_auto_test_for("res://kanji/kanji_data/06c34.svg", "水")


# Version étendue : boucle sur TOUS les kanji de la base (4 + 10 ajoutés lors
# de la session "écran de dessin") pour valider que le scoring généralise.
# Pour chaque kanji : tracé parfait → proche de 100 ; tracé aléatoire → faible ;
# tracé "humain imprécis" → ~65-89.
static func run_auto_test_all() -> void:
	var kanjis := [
		["res://kanji/kanji_data/06c34.svg", "水"],
		["res://kanji/kanji_data/0571f.svg", "土"],
		["res://kanji/kanji_data/0706b.svg", "火"],
		["res://kanji/kanji_data/098a8.svg", "風"],
		["res://kanji/kanji_data/06728.svg", "木"],
		["res://kanji/kanji_data/091d1.svg", "金"],
		["res://kanji/kanji_data/06708.svg", "月"],
		["res://kanji/kanji_data/065e5.svg", "日"],
		["res://kanji/kanji_data/05c71.svg", "山"],
		["res://kanji/kanji_data/05ddd.svg", "川"],
		["res://kanji/kanji_data/096f7.svg", "雷"],
		["res://kanji/kanji_data/096e8.svg", "雨"],
		["res://kanji/kanji_data/068ee.svg", "森"],
		["res://kanji/kanji_data/082b1.svg", "花"],
	]
	for k in kanjis:
		run_auto_test_for(k[0], k[1])


static func run_auto_test_for(svg_path: String, kanji_label: String) -> void:
	var ref_strokes: Array = SvgParser.load_strokes(svg_path)
	if ref_strokes.is_empty():
		print("AUTO-TEST [", kanji_label, "] : impossible de charger le SVG.")
		return

	# Cas 1 : tracé "parfait" = les points de référence eux-mêmes servent de
	# tracé joueur (forme, ordre et sens identiques, position parfaite).
	var perfect: Dictionary = compute_score(ref_strokes, ref_strokes)
	print("=== AUTO-TEST [", kanji_label, "] : tracé parfait -> ", perfect.score, " / 100 ===")

	# Cas 2 : tracé aléatoire = autant de traits que la référence, aux points
	# complètement aléatoires, sans rapport avec la référence.
	var random_strokes: Array = []
	for i in range(ref_strokes.size()):
		var stroke := PackedVector2Array()
		var origin := Vector2(randf() * 400.0, randf() * 400.0)
		for k in range(12):
			stroke.append(origin + Vector2(randf() * 150.0 - 75.0, randf() * 150.0 - 75.0))
		random_strokes.append(stroke)
	var random_result: Dictionary = compute_score(random_strokes, ref_strokes)
	print("=== AUTO-TEST [", kanji_label, "] : tracé aléatoire -> ", random_result.score, " / 100 ===")

	# Cas 3 : tracé "humain imprécis mais reconnaissable" : chaque trait de la
	# référence subit une petite rotation (autour du centre du trait) et un
	# petit décalage de position aléatoires.
	var noisy_strokes: Array = []
	for stroke in ref_strokes:
		var noisy := PackedVector2Array()
		var angle := deg_to_rad(randf_range(-15.0, 15.0))
		var offset := Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
		var center := Vector2.ZERO
		for p in stroke:
			center += p
		center /= float(stroke.size())
		for p in stroke:
			noisy.append((p - center).rotated(angle) + center + offset)
		noisy_strokes.append(noisy)
	var noisy_result: Dictionary = compute_score(noisy_strokes, ref_strokes)
	print("=== AUTO-TEST [", kanji_label, "] : tracé humain imprécis -> ", noisy_result.score, " / 100 ===")


# Rééchantillonne une polyligne en N points équidistants (par longueur d'arc)
static func sample_path(points: PackedVector2Array, n: int) -> PackedVector2Array:
	var res := PackedVector2Array()
	if points.size() == 0:
		return res
	if points.size() == 1:
		for k in range(n):
			res.append(points[0])
		return res
	# Longueurs cumulées entre les points
	var cum := PackedFloat32Array([0.0])
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i].distance_to(points[i - 1])
		cum.append(total)
	if total <= 0.0:
		for k in range(n):
			res.append(points[0])
		return res
	for k in range(n):
		var target := total * float(k) / float(n - 1)
		res.append(point_at_length(points, cum, target))
	return res


static func point_at_length(points: PackedVector2Array, cum: PackedFloat32Array, target: float) -> Vector2:
	if target <= 0.0:
		return points[0]
	if target >= cum[cum.size() - 1]:
		return points[points.size() - 1]
	for i in range(1, cum.size()):
		if cum[i] >= target:
			var seg_len: float = cum[i] - cum[i - 1]
			if seg_len <= 0.0:
				return points[i]
			var t: float = (target - cum[i - 1]) / seg_len
			return points[i - 1].lerp(points[i], t)
	return points[points.size() - 1]


# Cadre global : boîte englobante de TOUS les traits réunis, avec échelle
# uniforme. Invariant à la translation et à l'échelle globales du kanji entier.
static func compute_stroke_frame(strokes: Array) -> Dictionary:
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	for stroke in strokes:
		for p in stroke:
			min_p = min_p.min(p)
			max_p = max_p.max(p)
	var stroke_size: Vector2 = max_p - min_p
	var scale_factor := maxf(stroke_size.x, stroke_size.y)
	if scale_factor <= 0.0:
		scale_factor = 1.0
	return {"min": min_p, "scale": scale_factor}


# Ré-échantillonne un trait puis lui applique LA transformation du cadre global
# (même transformation pour tous les traits d'un même côté).
static func normalize_stroke_in_frame(points: PackedVector2Array, frame: Dictionary, n: int) -> PackedVector2Array:
	var sampled := sample_path(points, n)
	var res := PackedVector2Array()
	for p in sampled:
		res.append((p - frame["min"]) / float(frame["scale"]) * NORMAL_SIZE)
	return res


# Distance moyenne entre deux tracés échantillonnés et normalisés
static func avg_distance(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(a.size()):
		total += a[i].distance_to(b[i])
	return total / float(a.size())


# Score de ressemblance entre deux tracés DÉJÀ normalisés dans leur cadre
# global (0 = très différent, 100 = identique). Les points sont comparés dans
# l'ORDRE de tracé ; la direction générale (départ -> arrivée) est vérifiée :
# seul un sens réellement inversé est fortement pénalisé (un angle simplement
# décalé est déjà sanctionné par la distance moyenne).
static func distance_score(na: PackedVector2Array, nb: PackedVector2Array) -> float:
	var d := avg_distance(na, nb)
	# Conversion en score : distance faible = score élevé
	var score := maxf(0.0, 100.0 - d * DISTANCE_TO_SCORE_FACTOR)
	# Direction générale du trait (de son point de départ vers son point d'arrivée)
	var dir_a: Vector2 = na[na.size() - 1] - na[0]
	var dir_b: Vector2 = nb[nb.size() - 1] - nb[0]
	if dir_a.length() > 1.0 and dir_b.length() > 1.0:
		var dot: float = dir_a.normalized().dot(dir_b.normalized())
		if dot < -0.3:
			# Sens vraiment inversé : forte pénalité
			score *= 0.6
	return score
