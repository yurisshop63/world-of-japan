extends Control
## Fenêtre d'inventaire minimal (liste). Instanciée par WindowManager.open_action()
## via MenuConfig.actions -> "scene". Lit l'autoload Inventory (liste de dicts
## {"id", "count"}) et affiche nom × quantité, coloré selon la rareté.
## Reconstruite à chaque signal inventory_changed.

@onready var items_list = $CenterPanel/VBox/ItemsList
@onready var status_label = $CenterPanel/VBox/StatusLabel


func _ready() -> void:
	Inventory.inventory_changed.connect(_rebuild)
	$CenterPanel/VBox/CloseButton.pressed.connect(_on_close_pressed)
	_rebuild()


func _rebuild() -> void:
	for child in items_list.get_children():
		child.queue_free()

	if Inventory.items.is_empty():
		status_label.text = "Inventaire vide. Élimine des mobs pour récolter du loot."
	else:
		status_label.text = "%d type(s) d'objet(s)" % Inventory.items.size()

	for entry in Inventory.items:
		var item_id := str(entry.get("id", ""))
		var count := int(entry.get("count", 0))
		var def := Inventory.item_def(item_id)
		var row := Label.new()
		row.add_theme_font_size_override("font_size", 16)
		row.text = "%s  ×%d" % [def.get("name", item_id), count]
		row.add_theme_color_override("font_color",
				Inventory.rarity_color(str(def.get("rarity", ""))))
		items_list.add_child(row)


func _on_close_pressed() -> void:
	# Via WindowManager (toggle) pour que rappuyer sur le bouton du menu
	# puisse rouvrir la fenêtre après une fermeture manuelle.
	WindowManager.close_current()
