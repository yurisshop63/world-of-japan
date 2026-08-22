extends Control
## Fenêtre Statistiques : panneau sur la grille A11→I3 (MenuLayout.rect_from_grid),
## coins arrondis, z_index 8 — au-dessus des fenêtres d'action du WindowManager
## (z 0) mais sous le bouton MENU (z 10) et le sous-menu (z 9), donc le menu
## reste visible/cliquable par-dessus.
## PAS d'overlay plein écran : seul le panneau capture les clics
## (mouse_filter STOP), le reste de l'écran laisse passer les clics (sélection
## de cible, autres UI). Affiche les stats du joueur (PlayerStats) et un bouton
## "Quête" qui toggle le panneau de quête (QuestTracker) indépendamment de la
## fenêtre Statistiques elle-même.
##
## Instanciée par WindowManager.open_action() via MenuConfig.actions -> "scene".

var _panel: Panel
var _stats_labels: Dictionary = {}

const COLOR_BG := Color(0.13, 0.13, 0.15, 0.97)
const COLOR_BORDER := Color(0.4, 0.4, 0.45, 1)


func _ready() -> void:
	z_index = 8
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_panel()
	_apply_layout()
	_refresh()
	PlayerStats.health_changed.connect(_refresh)
	PlayerStats.power_changed.connect(_refresh)
	PlayerStats.xp_changed.connect(_refresh)
	PlayerStats.pvp_xp_changed.connect(_refresh)
	PlayerStats.leveled_up.connect(_refresh)
	get_viewport().size_changed.connect(_apply_layout)


func _build_panel() -> void:
	_panel = Panel.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_BG
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = COLOR_BORDER
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 18
	vbox.offset_top = 14
	vbox.offset_right = -18
	vbox.offset_bottom = -14
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Statistiques"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_stats_labels["level"] = _make_stat_row(vbox, "Niveau", "")
	_stats_labels["health"] = _make_stat_row(vbox, "Vie", "")
	_stats_labels["power"] = _make_stat_row(vbox, "Pouvoir", "")
	_stats_labels["xp"] = _make_stat_row(vbox, "XP", "")
	_stats_labels["pvp_xp"] = _make_stat_row(vbox, "PVP XP", "")

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var quest_btn := Button.new()
	quest_btn.text = "Quête"
	quest_btn.focus_mode = Control.FOCUS_NONE
	quest_btn.custom_minimum_size = Vector2(0, 44)
	MenuStyle.apply_round_styles(quest_btn, 12, Color(0.05, 0.05, 0.05, 0.95))
	quest_btn.pressed.connect(_on_quest_pressed)
	vbox.add_child(quest_btn)


## Construit une ligne "label : valeur" et renvoie le Label de valeur pour
## mise à jour ultérieure.
func _make_stat_row(vbox: VBoxContainer, label_text: String, value_text: String) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 16)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 16)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	return value


## Positionne le panneau sur la grille : case A11 (haut-gauche) → case I3
## (bas-droite), via MenuLayout.rect_from_grid.
func _apply_layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	var rect := MenuLayout.rect_from_grid(vp, "A", "I", 3, 11)
	_panel.position = rect.position
	_panel.size = rect.size


func _refresh() -> void:
	_stats_labels["level"].text = str(PlayerStats.level)
	_stats_labels["health"].text = "%d / %d" % [PlayerStats.health, PlayerStats.max_health]
	_stats_labels["power"].text = "%d / %d" % [PlayerStats.power, PlayerStats.max_power]
	_stats_labels["xp"].text = "%d / %d" % [PlayerStats.xp_in_bubble, PlayerStats.xp_per_bubble]
	_stats_labels["pvp_xp"].text = "%d / %d" % [PlayerStats.pvp_xp_in_bubble, PlayerStats.pvp_xp_per_bubble]


## Toggle du panneau de quête — indépendant de la fenêtre Statistiques.
func _on_quest_pressed() -> void:
	var tracker := get_tree().root.get_node_or_null("Main/UI/QuestTracker")
	if tracker != null and tracker.has_method("toggle_visible"):
		tracker.toggle_visible()
