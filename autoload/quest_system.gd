extends Node
## Autoload "QuestSystem"
## Quête ultra simple façon Alpha : "élimine N mobs de type X". Données avant
## code : la quête est une fiche dans QUESTS (objectif + récompenses). La
## progression est comptée par mob.gd qui appelle on_mob_killed(mob_type) à
## chaque mort. À la complétion : récompenses (XP + items) puis la quête
## recommence (boucle jouable minimale : le combat a toujours un but).
## À déclarer dans Project Settings > Autoload sous le nom "QuestSystem".

signal quest_progress(quest_id: int, current: int, required: int)
signal quest_completed(quest_id: int)

## Type de mob visé par une quête (mêmes valeurs que mob.gd:MobType) :
## 0=火 Feu, 1=水 Eau, 2=土 Terre, 3=月 Lune, 4=木 Bois, 5=金 Or, 6=日 Soleil.
const MOB_FEU := 0
const MOB_EAU := 1

## Fiches de quêtes (objectifs). Pour l'Alpha : une seule quête active.
const QUESTS := [
	{
		"id": 0,
		"name": "Pêche aux esprits d'eau",
		"description": "Élimine 5 esprits d'eau (水) pour purifier la rivière.",
		"objective": {"type": "kill_mobs", "mob_type": MOB_EAU, "count": 5},
		"reward_xp": 300,
		"reward_items": [{"id": "pepite_or", "count": 1}],
	},
]

var active_quest_id: int = 0
var progress: int = 0


func _ready() -> void:
	start_quest(0)


## Démarre (ou redémarre) une quête depuis sa fiche.
func start_quest(quest_id: int) -> void:
	active_quest_id = quest_id
	progress = 0
	quest_progress.emit(active_quest_id, progress, required_count())


## Appelé par mob.gd à chaque mort de mob. Comptabilise les kills correspondant
## à la quête active ; déclenche la complétion (récompenses) quand le compte
## est atteint.
func on_mob_killed(mob_type: int) -> void:
	var quest := get_quest(active_quest_id)
	if quest.is_empty():
		return
	var objective: Dictionary = quest.get("objective", {})
	if objective.get("type", "") != "kill_mobs":
		return
	if int(objective.get("mob_type", -1)) != mob_type:
		return
	progress += 1
	quest_progress.emit(active_quest_id, progress, required_count())
	if progress >= int(objective.get("count", 0)):
		_complete_quest(quest)


## Nombre d'objectifs requis pour la quête active (utilisé par l'UI).
func required_count() -> int:
	var quest := get_quest(active_quest_id)
	var objective: Dictionary = quest.get("objective", {})
	return int(objective.get("count", 0))


func _complete_quest(quest: Dictionary) -> void:
	PlayerStats.add_xp(int(quest.get("reward_xp", 0)))
	for reward in quest.get("reward_items", []):
		Inventory.add_item(str(reward.get("id", "")), int(reward.get("count", 1)))
	print("Quête terminée : ", quest.get("name", "?"),
			" -> +", quest.get("reward_xp", 0), " XP.")
	quest_completed.emit(active_quest_id)
	# Boucle jouable : la quête recommence aussitôt (le combat garde un but).
	start_quest(active_quest_id)


func get_quest(quest_id: int) -> Dictionary:
	for q in QUESTS:
		if int(q.get("id", -1)) == quest_id:
			return q
	return {}
