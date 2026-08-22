extends Control
## QuestTracker — petit panneau affichant la quête active (nom + progression).
## Ajouté au CanvasLayer UI dans main.tscn. Écoute QuestSystem (autoload) :
## quest_progress / quest_completed pour rester à jour. Construit en code.

var _name_label: Label
var _progress_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.05, 0.75)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.45, 0.45, 0.5, 1)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12
	vbox.offset_top = 8
	vbox.offset_right = -12
	vbox.offset_bottom = -8
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 15)
	_name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.6))
	vbox.add_child(_name_label)

	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 14)
	_progress_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	vbox.add_child(_progress_label)

	QuestSystem.quest_progress.connect(_on_progress)
	QuestSystem.quest_completed.connect(_on_completed)
	_refresh()


func _on_progress(quest_id: int, current: int, required: int) -> void:
	_refresh()


func _on_completed(quest_id: int) -> void:
	_refresh()


func _refresh() -> void:
	var quest := QuestSystem.get_quest(QuestSystem.active_quest_id)
	if quest.is_empty():
		_name_label.text = ""
		_progress_label.text = ""
		return
	_name_label.text = str(quest.get("name", "?"))
	_progress_label.text = "%s : %d / %d" % [
		QuestSystem.objective_text(), QuestSystem.progress, QuestSystem.required_count(),
	]
