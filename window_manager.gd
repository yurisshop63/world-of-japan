extends CanvasLayer
## Autoload "WindowManager"
## Ouvre/ferme les fenêtres associées aux actions du menu circulaire (toggle) :
## - appuyer sur le même bouton d'action referme sa fenêtre ;
## - ouvrir une autre fenêtre ferme automatiquement la précédente (une seule
##   fenêtre d'action ouverte à la fois).
## Si aucune scène n'est renseignée dans MenuConfig.actions, une fenêtre
## générique de test (placeholder) est créée, pour valider le comportement du
## menu avant d'avoir les vraies fenêtres.
##
## Couche canvas 1 (même couche que le HUD) : le bouton MENU (z_index 10) et le
## sous-menu (z_index 9) restent au-dessus des fenêtres (z_index par défaut 0).
## La fenêtre Statistiques se met elle-même à z_index 8 (au-dessus des fenêtres
## d'action, sous le menu). Fermer une fenêtre (bouton "Fermer") doit passer
## par close_current() pour remettre à jour l'état du toggle.
##
## À déclarer dans Project Settings > Autoload sous le nom "WindowManager".

var _current_action_id: int = -1
var _current_window: Control = null


func _ready() -> void:
	layer = 1


func open_action(action_id: int) -> void:
	# Toggle : rappuyer sur le même bouton referme sa fenêtre.
	if action_id == _current_action_id and _current_window != null and is_instance_valid(_current_window):
		close_current()
		return

	# Une seule fenêtre ouverte à la fois : on ferme la précédente.
	close_current()

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
	_current_action_id = action_id
	_current_window = window


## Ferme (et libère) la fenêtre d'action courante, si ouverte. Appelé par le
## toggle mais aussi par les boutons "Fermer" des fenêtres (au lieu d'un
## queue_free() direct), pour que rappuyer sur le bouton du menu rouvre bien
## la fenêtre après une fermeture manuelle.
func close_current() -> void:
	if _current_window != null and is_instance_valid(_current_window):
		_current_window.queue_free()
	_current_window = null
	_current_action_id = -1


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
	close_btn.pressed.connect(close_current)
	vbox.add_child(close_btn)

	return overlay
