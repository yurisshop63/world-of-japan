extends Node
## Autoload "MenuConfig"
## Stocke et sauvegarde la configuration persistante du menu :
## - le côté où se trouve le bouton menu (droite / gauche)
## - l'ordre des 6 actions dans les emplacements du sous-menu
##
## À déclarer dans Project Settings > Autoload sous le nom "MenuConfig".

signal config_changed

enum Side { RIGHT, LEFT }

const SAVE_PATH := "user://menu_config.cfg"

var side: int = Side.RIGHT

## Catalogue des actions possibles. "id" ne bouge jamais (sert de référence
## stable), c'est l'ordre dans slot_actions qui change quand on réorganise.
## "scene" : chemin vers une scène de fenêtre (laisser vide -> fenêtre
## générique de test).
var actions: Array = [
	{"id": 0, "label": "1", "scene": ""},
	{"id": 1, "label": "2", "scene": ""},
	{"id": 2, "label": "3", "scene": ""},
	{"id": 3, "label": "4", "scene": ""},
	{"id": 4, "label": "5", "scene": ""},
	{"id": 5, "label": "Raccourcis", "scene": "res://ui/keybind_window.tscn"},
]

## slot_actions[i] = id de l'action affichée à l'emplacement i (0 à 5)
var slot_actions: Array = [0, 1, 2, 3, 4, 5]


func _ready() -> void:
	load_config()


func get_action(action_id: int) -> Dictionary:
	for a in actions:
		if a.id == action_id:
			return a
	return {}


func swap_slots(slot_a: int, slot_b: int) -> void:
	if slot_a == slot_b:
		return
	var tmp = slot_actions[slot_a]
	slot_actions[slot_a] = slot_actions[slot_b]
	slot_actions[slot_b] = tmp
	save_config()
	config_changed.emit()


func set_side(new_side: int) -> void:
	if side == new_side:
		return
	side = new_side
	save_config()
	config_changed.emit()


func save_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("menu", "side", side)
	cfg.set_value("menu", "slot_actions", slot_actions)
	cfg.save(SAVE_PATH)


func load_config() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return
	side = cfg.get_value("menu", "side", Side.RIGHT)
	slot_actions = cfg.get_value("menu", "slot_actions", [0, 1, 2, 3, 4, 5])
