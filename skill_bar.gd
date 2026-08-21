extends Node

signal bar_changed
signal skill_used(slot_index, skill)

var slots = []
const MELEE_RANGE = 3.0

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
	var damage = randi_range(2, 6)
	target.take_damage(damage)
	print(skill["name"], " inflige ", damage, " dégâts.")
