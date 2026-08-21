extends DraggableButton
## Bouton principal du menu. À attacher au Button existant dans ta scène,
## À LA PLACE de ton script d'origine.
##
## - Un tap (appui court) ouvre/ferme le sous-menu des 6 boutons.
## - Un appui long puis un glissement déplace le bouton entre le coin
##   haut-droit et le coin haut-gauche de l'écran (snap automatique au
##   relâchement selon la moitié d'écran où le doigt/curseur se trouve).

const SLOT_BUTTON_SCRIPT := preload("C:/Users/naomi/OneDrive/Documents/jeu-mmorpg-japanese-learning-ARCHIVE/menu_slot_button.gd")

var menu_window: Control
var slot_buttons: Array = []


func _ready() -> void:
	super._ready()
	z_index = 10
	text = "MENU"
	add_theme_font_size_override("font_size", 18)

	_apply_position_for_side(MenuConfig.side)

	MenuConfig.config_changed.connect(_on_config_changed)
	get_viewport().size_changed.connect(_on_viewport_resized)


func _apply_position_for_side(side: int) -> void:
	var vp := get_viewport_rect().size
	var rect := MenuLayout.menu_button_rect(vp, side)
	position = rect.position
	size = rect.size
	var radius := int(min(size.x, size.y) / 2)
	MenuStyle.apply_round_styles(self, radius, Color(0.05, 0.05, 0.05, 0.95))


func _on_config_changed() -> void:
	_snap_to_side(MenuConfig.side)
	if menu_window:
		_refresh_slots()


func _on_viewport_resized() -> void:
	_apply_position_for_side(MenuConfig.side)
	if menu_window:
		_refresh_slots()


# --- comportements hérités de DraggableButton ---

func _on_tap() -> void:
	toggle_menu()


func _on_drag_start(_global_pos: Vector2) -> void:
	modulate.a = 0.85
	z_index = 30


func _on_drag_move(global_pos: Vector2) -> void:
	var vp := get_viewport_rect().size
	var target := global_pos - size / 2.0
	target.x = clamp(target.x, 0, vp.x - size.x)
	target.y = clamp(target.y, 0, vp.y - size.y)
	global_position = target


func _on_drag_end(global_pos: Vector2) -> void:
	modulate.a = 1.0
	z_index = 10
	var vp := get_viewport_rect().size
	var new_side := MenuConfig.Side.LEFT if global_pos.x < vp.x / 2.0 else MenuConfig.Side.RIGHT
	# snap immédiat (au cas où le côté ne change pas, sinon _on_config_changed
	# s'en charge aussi) + sauvegarde/propagation du nouveau côté.
	_snap_to_side(new_side)
	MenuConfig.set_side(new_side)


func _snap_to_side(side: int) -> void:
	var vp := get_viewport_rect().size
	var rect := MenuLayout.menu_button_rect(vp, side)
	var tween := create_tween()
	tween.tween_property(self, "position", rect.position, 0.15).set_trans(Tween.TRANS_CUBIC)


# --- gestion du sous-menu ---

func toggle_menu() -> void:
	if menu_window:
		_close_menu()
	else:
		_open_menu()


func _open_menu() -> void:
	menu_window = Control.new()
	menu_window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_window.z_index = 9
	get_tree().current_scene.add_child(menu_window)

	slot_buttons.clear()
	for i in range(MenuConfig.slot_actions.size()):
		var btn := _create_slot_button(i)
		slot_buttons.append(btn)


func _close_menu() -> void:
	if menu_window:
		menu_window.queue_free()
		menu_window = null
	slot_buttons.clear()


func _refresh_slots() -> void:
	for i in range(slot_buttons.size()):
		var btn = slot_buttons[i]
		if is_instance_valid(btn):
			btn.setup(i)


func _create_slot_button(slot_index: int) -> Button:
	var btn := Button.new()
	btn.set_script(SLOT_BUTTON_SCRIPT)
	menu_window.add_child(btn)
	btn.menu_root = self
	btn.setup(slot_index)
	return btn
