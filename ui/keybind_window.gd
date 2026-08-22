extends Control
## Fenêtre de configuration des raccourcis clavier (commandes de combat).
## Instanciée par WindowManager.open_action() via MenuConfig.actions -> "scene".
## Liste les actions configurables de KeybindConfig ; pour chacune un bouton
## "Réassigner" capture la prochaine touche pressée et met à jour + sauvegarde.

@onready var actions_list = $CenterPanel/VBox/ActionsList
@onready var status_label = $CenterPanel/VBox/StatusLabel

var _capturing_action: String = ""
var _capturing_button: Button


func _ready() -> void:
	KeybindConfig.keybinds_changed.connect(_on_keybinds_changed)
	$CenterPanel/VBox/CloseButton.pressed.connect(_on_close_pressed)
	_rebuild()


func _rebuild() -> void:
	for child in actions_list.get_children():
		child.queue_free()

	for action in KeybindConfig.actions:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.custom_minimum_size.y = 40

		var label := Label.new()
		label.text = action.get("label", action.get("id", "?"))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var btn := Button.new()
		btn.text = OS.get_keycode_string(KeybindConfig.get_keycode(action.id))
		btn.custom_minimum_size = Vector2(140, 0)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_reassign_pressed.bind(action.id, btn))
		row.add_child(btn)

		actions_list.add_child(row)


func _on_reassign_pressed(action_id: String, btn: Button) -> void:
	_capturing_action = action_id
	_capturing_button = btn
	btn.text = "... (appuie une touche, Échap = annuler)"
	status_label.text = "Appuie sur la nouvelle touche pour : " + action_id


func _input(event) -> void:
	if _capturing_action == "":
		return
	if not event is InputEventKey or not event.pressed:
		return

	# On consomme la touche pour ne pas déclencher l'action en pleine capture.
	get_viewport().set_input_as_handled()

	if event.keycode == KEY_ESCAPE:
		_cancel_capture("Réassignement annulé.")
		return
	# On ignore les modificateurs seuls (Ctrl/Shift/Alt/Meta) et NumLock.
	if event.keycode in [KEY_CTRL, KEY_SHIFT, KEY_ALT, KEY_META, KEY_NUMLOCK]:
		return

	KeybindConfig.set_keycode(_capturing_action, event.keycode)
	_cancel_capture("Raccourci mis à jour.")
	_rebuild()


func _cancel_capture(msg: String) -> void:
	_capturing_action = ""
	_capturing_button = null
	status_label.text = msg


func _on_keybinds_changed() -> void:
	if _capturing_button:
		_rebuild()


func _on_close_pressed() -> void:
	# Via WindowManager (toggle) pour que rappuyer sur le bouton du menu
	# puisse rouvrir la fenêtre après une fermeture manuelle.
	WindowManager.close_current()
