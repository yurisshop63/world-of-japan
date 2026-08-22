extends Node

signal bar_changed
signal skill_used(slot_index, skill)

var slots = []
const MELEE_RANGE = 3.0
# Kanji de repli si un skill n'en précise pas (ne devrait plus arriver).
const DEFAULT_KANJI_SVG := "res://kanji/kanji_data/06c34.svg"
# Temps "parfait" par défaut pour dessiner le kanji (ms) — voir kanji_draw_popup.
const DEFAULT_PAR_TIME_MS := 3000
# Kanji disponibles (base étendue session "écran de dessin" : 4 + 10 KanjiVG).
# Chaque skill référence le sien via sa fiche :
# {"name", "kanji", "par_time_ms"}. Le par_time_ms est le temps "parfait" pour
# dessiner ce kanji — plus le kanji est complexe (nb de traits), plus il est
# long. Extrapolation depuis 水=4 traits→3000, 土=3→2000, 火=4→2800, 風=9→5500
# (~base 700 + ~500-550 ms/trait).
const KANJI_DATA := {
	"mizu": {"name": "Frappe Eau", "kanji": "res://kanji/kanji_data/06c34.svg", "par_time_ms": 3000},
	"tsuchi": {"name": "Frappe Terre", "kanji": "res://kanji/kanji_data/0571f.svg", "par_time_ms": 2000},
	"hi": {"name": "Frappe Feu", "kanji": "res://kanji/kanji_data/0706b.svg", "par_time_ms": 2800},
	"kaze": {"name": "Frappe Vent", "kanji": "res://kanji/kanji_data/098a8.svg", "par_time_ms": 5500},
	"ki": {"name": "Frappe Bois", "kanji": "res://kanji/kanji_data/06728.svg", "par_time_ms": 2800},
	"kin": {"name": "Frappe Or", "kanji": "res://kanji/kanji_data/091d1.svg", "par_time_ms": 5000},
	"tsuki": {"name": "Frappe Lune", "kanji": "res://kanji/kanji_data/06708.svg", "par_time_ms": 2800},
	"nichi": {"name": "Frappe Soleil", "kanji": "res://kanji/kanji_data/065e5.svg", "par_time_ms": 2800},
	"yama": {"name": "Frappe Montagne", "kanji": "res://kanji/kanji_data/05c71.svg", "par_time_ms": 2000},
	"kawa": {"name": "Frappe Rivière", "kanji": "res://kanji/kanji_data/05ddd.svg", "par_time_ms": 2000},
	"kaminari": {"name": "Frappe Tonnerre", "kanji": "res://kanji/kanji_data/096f7.svg", "par_time_ms": 8000},
	"ame": {"name": "Frappe Pluie", "kanji": "res://kanji/kanji_data/096e8.svg", "par_time_ms": 5000},
	"mori": {"name": "Frappe Forêt", "kanji": "res://kanji/kanji_data/068ee.svg", "par_time_ms": 7200},
	"hana": {"name": "Frappe Fleur", "kanji": "res://kanji/kanji_data/082b1.svg", "par_time_ms": 4300},
}

var _active_popup = null
var _pending_target = null
var _pending_skill_index = -1

# Multiplicateurs de performance (précision × vitesse) accumulés pendant le
# combat en cours. Consommés à la mort d'un mob (mob.gd -> SkillBar.xp_multiplier
# puis reset_combat) pour calculer l'XP du kill. Un échec (score < 40) compte 0.
var _combat_multipliers: Array = []

func _ready():
	for i in range(9):
		slots.append(null)
	# Alpha : slots 1-4 = les 4 kanji élémentaires, slots 5-9 vides.
	# Pas de différenciation de puissance entre éléments (dégâts base 2-6,
	# portée 3.0 identiques) — seul le kanji à dessiner change.
	equip_skill(0, KANJI_DATA["mizu"].duplicate())
	equip_skill(1, KANJI_DATA["tsuchi"].duplicate())
	equip_skill(2, KANJI_DATA["hi"].duplicate())
	equip_skill(3, KANJI_DATA["kaze"].duplicate())
	# Si le joueur meurt pendant qu'il dessine, on ferme le popup sans dégâts.
	PlayerStats.player_died.connect(_on_player_died)

func equip_skill(slot_index, skill):
	slots[slot_index] = skill
	bar_changed.emit()

func use_slot(slot_index):
	var skill = slots[slot_index]
	if skill == null:
		return
	if _active_popup != null:
		print("Un dessin de kanji est déjà en cours.")
		return
	var target = TargetSystem.current_target
	if target == null:
		print("Aucune cible sélectionnée.")
		return
	var player = get_tree().get_root().get_node("Main/Player")
	var dist = player.global_position.distance_to(target.global_position)
	if dist > MELEE_RANGE:
		print("Cible trop loin.")
		return
	skill_used.emit(slot_index, skill)
	_pending_target = target
	_pending_skill_index = slot_index
	_open_kanji_draw(skill)

func _open_kanji_draw(skill):
	var candidates := _build_candidates(skill)
	var popup_scene = preload("res://kanji/kanji_draw_popup.tscn")
	_active_popup = popup_scene.instantiate()
	get_tree().get_root().add_child(_active_popup)
	_active_popup.par_time_ms = skill.get("par_time_ms", DEFAULT_PAR_TIME_MS)
	_active_popup.drawing_validated.connect(_on_drawing_validated)
	_active_popup.drawing_cancelled.connect(_on_drawing_cancelled)
	# Temps réel : le monde ne se met PAS en pause. Le mob continue d'attaquer,
	# la vitesse de dessin devient un second facteur de score.
	_active_popup.open(candidates)

## Construit la liste des 3 références proposées au joueur : le kanji du skill
## déclenché en premier + 2 autres kanji tirés au hasard dans la base étendue.
## Chaque candidat : {"svg", "par_time_ms", "name"}. Le joueur choisit lequel
## il dessine (le popup score contre le kanji sélectionné, pas un kanji fixe).
## TODO (ROADMAP point 2) : affiner la pertinence "élémentaire" (ex: proposer
## en priorité des kanji du même élément que le skill déclenché).
func _build_candidates(skill) -> Array:
	var candidates := [{
		"svg": skill.get("kanji", DEFAULT_KANJI_SVG),
		"par_time_ms": skill.get("par_time_ms", DEFAULT_PAR_TIME_MS),
		"name": skill.get("name", "?"),
	}]
	var pool := []
	for key in KANJI_DATA:
		var other = KANJI_DATA[key]
		if other["kanji"] != candidates[0]["svg"]:
			pool.append(other)
	pool.shuffle()
	var wanted := mini(2, pool.size())
	for i in range(wanted):
		candidates.append({
			"svg": pool[i]["kanji"],
			"par_time_ms": pool[i]["par_time_ms"],
			"name": pool[i]["name"],
		})
	return candidates

func _on_drawing_validated(score, elapsed_ms):
	var target = _pending_target
	var skill = slots[_pending_skill_index]
	var par_time_ms = _active_popup.par_time_ms if _active_popup != null else DEFAULT_PAR_TIME_MS
	_reset_pending()
	if target == null or not is_instance_valid(target):
		return
	# TODO Phase 1 (fait) : l'XP du kill est multipliée par la performance
	# moyenne du combat (précision × vitesse) — voir xp_multiplier().
	var damage = _compute_damage(score, elapsed_ms, par_time_ms)
	_combat_multipliers.append(_performance_multiplier(score, elapsed_ms, par_time_ms))
	target.take_damage(damage)
	print(skill["name"], " -> score kanji ", score, " en ", elapsed_ms,
			" ms (par ", par_time_ms, " ms) : ", damage, " dégâts.")

## Moyenne des multiplicateurs précision × vitesse du combat en cours.
## 1.0 si aucun kanji dessiné (kill sans skill -> XP de base non bonus).
func xp_multiplier() -> float:
	if _combat_multipliers.is_empty():
		return 1.0
	var total := 0.0
	for mult in _combat_multipliers:
		total += float(mult)
	return total / float(_combat_multipliers.size())

## Remet à zéro l'accumulateur de performance (appelé à la mort d'un mob).
func reset_combat() -> void:
	_combat_multipliers.clear()

func _on_drawing_cancelled():
	_reset_pending()
	print("Dessin annulé : aucune action.")

func _on_player_died():
	if _active_popup == null:
		return
	print("Le joueur est mort pendant le dessin : le kanji est annulé.")
	# Ferme le popup comme un drawing_cancelled : aucune action, pas de dégâts.
	_active_popup.close()
	_reset_pending()

func _reset_pending():
	if _active_popup != null and is_instance_valid(_active_popup):
		_active_popup.queue_free()
	_active_popup = null
	_pending_target = null
	_pending_skill_index = -1

# Formule score kanji -> dégâts (précision × vitesse, temps réel).
# Précision : <40 → 0 ; 40-70 → base ; 70-90 → ×1.5 ; >90 → ×2.
# Vitesse (elapsed_ms vs par_time_ms) : ≤0.6×par → ×1.3 ; ≤par → ×1.0 ;
# ≤1.5×par → ×0.8 ; au-delà → ×0.6.
# Dégâts = base × précision × vitesse, arrondi, min 1 si score ≥ 40.
func _compute_damage(score, elapsed_ms, par_time_ms):
	if score < 40:
		return 0
	var base = randi_range(2, 6)
	var precision_mult = 1.0
	if score >= 70 and score <= 90:
		precision_mult = 1.5
	elif score > 90:
		precision_mult = 2.0
	var speed_mult = 1.0
	if elapsed_ms <= par_time_ms * 0.6:
		speed_mult = 1.3
	elif elapsed_ms <= par_time_ms:
		speed_mult = 1.0
	elif elapsed_ms <= par_time_ms * 1.5:
		speed_mult = 0.8
	else:
		speed_mult = 0.6
	return max(int(round(base * precision_mult * speed_mult)), 1)

# Multiplicateur précision × vitesse du kanji (0 si échec < 40). Utilisé pour
# l'XP du kill (moyenne du combat) et factorisé avec _compute_damage.
func _performance_multiplier(score, elapsed_ms, par_time_ms):
	if score < 40:
		return 0.0
	var precision_mult = 1.0
	if score >= 70 and score <= 90:
		precision_mult = 1.5
	elif score > 90:
		precision_mult = 2.0
	var speed_mult = 1.0
	if elapsed_ms <= par_time_ms * 0.6:
		speed_mult = 1.3
	elif elapsed_ms <= par_time_ms:
		speed_mult = 1.0
	elif elapsed_ms <= par_time_ms * 1.5:
		speed_mult = 0.8
	else:
		speed_mult = 0.6
	return precision_mult * speed_mult
