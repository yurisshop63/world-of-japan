extends Node
## Autoload "KeybindConfig"
## Stocke et sauvegarde la configuration des touches clavier (action -> keycode).
## Même pattern que MenuConfig (user://menu_config.cfg) : ConfigFile + _ready ->
## load_config() + save_config() à chaque modification.
##
## À déclarer dans Project Settings > Autoload sous le nom "KeybindConfig".

signal keybinds_changed

const SAVE_PATH := "user://keybinds.cfg"

## Touches par défaut. Vérifié libre : flèches, A, Z, T/Y/U/I/O, 1-9, Ctrl,
## NumLock sont déjà utilisés ailleurs. C et V sont libres.
const DEFAULT_KEYBINDS := {
	"face": KEY_C,
	"stick": KEY_V,
}

## Config courante (copie modifiable des défauts).
var keybinds := DEFAULT_KEYBINDS.duplicate()

## Liste des actions configurables (ordre d'affichage dans la fenêtre UI).
var actions: Array = [
	{"id": "face", "label": "FACE — s'orienter vers la cible"},
	{"id": "stick", "label": "STICK — suivre la cible"},
]


func _ready() -> void:
	load_config()


## Retourne le keycode actuel d'une action (défaut si jamais absent).
func get_keycode(action: String) -> int:
	return keybinds.get(action, DEFAULT_KEYBINDS.get(action, KEY_NONE))


## Remplace la touche d'une action puis sauvegarde immédiatement.
func set_keycode(action: String, keycode: int) -> void:
	keybinds[action] = keycode
	save_config()
	keybinds_changed.emit()


func save_config() -> void:
	var cfg := ConfigFile.new()
	for action in keybinds:
		cfg.set_value("keybinds", action, keybinds[action])
	cfg.save(SAVE_PATH)


func load_config() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return
	for action in DEFAULT_KEYBINDS:
		var value = cfg.get_value("keybinds", action, DEFAULT_KEYBINDS[action])
		if typeof(value) == TYPE_INT:
			keybinds[action] = value
