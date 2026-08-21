extends CanvasLayer
## Autoload "WindowManager"
## Ouvre la fenêtre associée à une action du menu.
## Si aucune scène n'est renseignée dans MenuConfig.actions, une fenêtre
## générique de test (placeholder) est créée, pour que tu puisses valider
## le comportement du menu avant d'avoir tes vraies fenêtres.
##
## À déclarer dans Project Settings > Autoload sous le nom "WindowManager".

func _ready() -> void:
	layer = 20


func open_action(action_id: int) -> void:
	var action := MenuConfig.get_action(action_id)
	if action.is_empty():
		return

	var scene_path: String = action.get("scene", "")
	var window: Control

	if scene_path != "" and ResourceLoader.exists(scene_path):
		var packed: PackedScene = load(scene_path)
		window = packed.instantiate()
	else:
		window = _make_placeholder(action)

	add_child(window)


func _make_placeholder(action: Dictionary) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.modulate = Color(1, 1, 1, 1)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.45)
	overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(420, 280)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Fenêtre : " + str(action.get("label", "?"))
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "(fenêtre de test, remplace-la par ta vraie scène\ndans MenuConfig.actions -> \"scene\")"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	var close_btn := Button.new()
	close_btn.text = "Fermer"
	close_btn.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(close_btn)

	return overlay
