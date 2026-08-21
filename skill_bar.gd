extends Node

signal bar_changed
signal skill_used(slot_index, skill)

var slots = []
const MELEE_RANGE = 3.0
# Kanji associé par défaut à tous les skills pour l'instant (水).
# À terme : chaque skill aura son propre kanji (clé "kanji" dans la fiche).
const DEFAULT_KANJI_SVG := "res://kanji/kanji_data/06c34.svg"
# Temps "parfait" par défaut pour dessiner le kanji (ms) — voir kanji_draw_popup.
const DEFAULT_PAR_TIME_MS := 3000

var _active_popup = null
var _pending_target = null
var _pending_skill_index = -1

func _ready():
	for i in range(9):
		slots.append(null)
	equip_skill(0, {"name": "Frappe", "type": "corps-à-corps"})
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
	var kanji_path = skill.get("kanji", DEFAULT_KANJI_SVG)
	var par_time_ms = skill.get("par_time_ms", DEFAULT_PAR_TIME_MS)
	var popup_scene = preload("res://kanji/kanji_draw_popup.tscn")
	_active_popup = popup_scene.instantiate()
	get_tree().get_root().add_child(_active_popup)
	_active_popup.par_time_ms = par_time_ms
	_active_popup.drawing_validated.connect(_on_drawing_validated)
	_active_popup.drawing_cancelled.connect(_on_drawing_cancelled)
	# Temps réel : le monde ne se met PAS en pause. Le mob continue d'attaquer,
	# la vitesse de dessin devient un second facteur de score.
	_active_popup.open(kanji_path)

func _on_drawing_validated(score, elapsed_ms):
	var target = _pending_target
	var skill = slots[_pending_skill_index]
	var par_time_ms = _active_popup.par_time_ms if _active_popup != null else DEFAULT_PAR_TIME_MS
	_reset_pending()
	if target == null or not is_instance_valid(target):
		return
	# TODO Phase 1 : XP finale = produit précision × vitesse (score moyen du
	# combat), au lieu du seul score moyen.
	var damage = _compute_damage(score, elapsed_ms, par_time_ms)
	target.take_damage(damage)
	print(skill["name"], " -> score kanji ", score, " en ", elapsed_ms,
			" ms (par ", par_time_ms, " ms) : ", damage, " dégâts.")

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
