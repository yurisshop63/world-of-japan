extends DraggableButton
## Un des 6 boutons du sous-menu. Créé dynamiquement par menu_root_button.gd
## (pas besoin de l'attacher à la main dans l'éditeur).
##
## - Tap : ouvre la fenêtre associée à l'action de cet emplacement.
## - Appui long puis glissement : permet d'échanger sa place avec un autre
##   emplacement -> réorganisation libre du menu par le joueur.

var slot_index: int = -1
var menu_root: Node  # référence vers menu_root_button.gd (assignée à la création)

var _home_position := Vector2.ZERO


func _ready() -> void:
	super._ready()
	add_theme_font_size_override("font_size", 18)


## Positionne ce bouton à l'emplacement "slot_index" et met à jour son
## libellé selon l'action qui y est actuellement assignée.
## Appelé à la création, après un swap, un changement de côté, ou un
## redimensionnement de la fenêtre.
func setup(index: int) -> void:
	slot_index = index
	_reposition()
	_refresh_label()


func _reposition() -> void:
	var vp := get_viewport_rect().size
	var rect := MenuLayout.slot_rect(vp, slot_index, MenuConfig.side)
	_home_position = rect.position
	position = rect.position
	size = rect.size
	var radius := int(min(size.x, size.y) / 2)
	MenuStyle.apply_round_styles(self, radius, Color(0.05, 0.05, 0.05, 0.90))


func _refresh_label() -> void:
	var action_id = MenuConfig.slot_actions[slot_index]
	var action := MenuConfig.get_action(action_id)
	text = action.get("label", "?")


# --- comportements hérités de DraggableButton ---

func _on_tap() -> void:
	var action_id = MenuConfig.slot_actions[slot_index]
	WindowManager.open_action(action_id)


func _on_drag_start(_global_pos: Vector2) -> void:
	z_index = 20
	modulate.a = 0.85


func _on_drag_move(global_pos: Vector2) -> void:
	global_position = global_pos - size / 2.0


func _on_drag_end(global_pos: Vector2) -> void:
	z_index = 0
	modulate.a = 1.0

	var target_slot := _find_nearest_slot(global_pos)
	if target_slot != -1 and target_slot != slot_index:
		# swap_slots déclenche config_changed -> menu_root rappelle setup()
		# sur tous les boutons, qui se replacent chacun sur leur case fixe
		# (avec, désormais, leurs libellés/actions échangés).
		MenuConfig.swap_slots(slot_index, target_slot)
	else:
		_snap_home()


func _snap_home() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", _home_position, 0.15).set_trans(Tween.TRANS_CUBIC)


## Cherche le bouton le plus proche du point de relâchement, parmi les
## autres emplacements du sous-menu. Renvoie -1 si aucun n'est assez proche
## (évite un swap accidentel si le joueur relâche loin de tout bouton).
func _find_nearest_slot(global_pos: Vector2) -> int:
	if menu_root == null:
		return -1

	var best_index := -1
	var best_dist := INF
	for i in range(menu_root.slot_buttons.size()):
		var other = menu_root.slot_buttons[i]
		if other == self or not is_instance_valid(other):
			continue
		var center: Vector2 = other.global_position + other.size / 2.0
		var d := center.distance_to(global_pos)
		if d < best_dist:
			best_dist = d
			best_index = i

	var threshold: float = size.length() * 0.6
	if best_dist > threshold:
		return -1
	return best_index
