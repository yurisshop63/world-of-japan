extends Node

signal bar_changed
signal skill_used(slot_index, skill)

var slots = []
const MELEE_RANGE = 3.0
# Kanji associé par défaut à tous les skills pour l'instant (水).
# À terme : chaque skill aura son propre kanji (clé "kanji" dans la fiche).
const DEFAULT_KANJI_SVG := "res://kanji/kanji_data/06c34.svg"

var _active_popup = null
var _pending_target = null
var _pending_skill_index = -1

func _ready():
	for i in range(9):
		slots.append(null)
	equip_skill(0, {"name": "Frappe", "type": "corps-à-corps"})

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
	var popup_scene = preload("res://kanji/kanji_draw_popup.tscn")
	_active_popup = popup_scene.instantiate()
	get_tree().get_root().add_child(_active_popup)
	_active_popup.drawing_validated.connect(_on_drawing_validated)
	_active_popup.drawing_cancelled.connect(_on_drawing_cancelled)
	_active_popup.open(kanji_path)
	# Pause du monde pendant le dessin (le rendu 3D reste affiché derrière)
	get_tree().paused = true

func _on_drawing_validated(score):
	get_tree().paused = false
	var target = _pending_target
	var skill = slots[_pending_skill_index]
	_reset_pending()
	if target == null or not is_instance_valid(target):
		return
	# TODO Phase 1 : XP multipliée par le score (score moyen du combat).
	var damage = _apply_score_to_damage(score)
	target.take_damage(damage)
	print(skill["name"], " -> score kanji ", score, " : ", damage, " dégâts.")

func _on_drawing_cancelled():
	get_tree().paused = false
	_reset_pending()
	print("Dessin annulé : aucune action.")

func _reset_pending():
	if _active_popup != null and is_instance_valid(_active_popup):
		_active_popup.queue_free()
	_active_popup = null
	_pending_target = null
	_pending_skill_index = -1

# Formule score kanji -> dégâts (ROADMAP, tableau "score kanji -> combat").
func _apply_score_to_damage(score):
	var base = randi_range(2, 6)
	if score < 40:
		return 0
	if score < 70:
		return base
	if score <= 90:
		return int(round(base * 1.5))
	# score > 90 : coup critique
	return int(round(base * 2.0))
