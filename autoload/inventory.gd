extends Node
## Autoload "Inventory"
## Inventaire minimal (liste, pas de grille sophistiquée — Phase 1 Alpha).
## Données avant code : chaque item est défini par une fiche dans ITEM_DEFS
## ({"name", "rarity", "color"}), et l'inventaire ne stocke que des références
## {"id", "count"}. Les drops de mob y écrivent, la fenêtre Inventaire le lit.
## À déclarer dans Project Settings > Autoload sous le nom "Inventory".

signal inventory_changed

## Rareté -> couleur (affichée dans la fenêtre Inventaire).
const RARITY_COLOR := {
	"Commun": Color(0.8, 0.8, 0.8),
	"Rare": Color(0.3, 0.7, 1.0),
	"Épique": Color(0.8, 0.3, 1.0),
	"Légendaire": Color(1.0, 0.7, 0.2),
}

## Fiches d'items (thème 曜日, cohérent avec les 7 types de mobs).
## Un item = une fiche ici + éventuellement une entrée de drop dans mob.gd.
const ITEM_DEFS := {
	"essence_feu":  {"name": "Essence de Feu",  "rarity": "Commun"},
	"essence_eau":  {"name": "Essence d'Eau",   "rarity": "Commun"},
	"essence_terre":{"name": "Essence de Terre","rarity": "Commun"},
	"eclat_lune":   {"name": "Éclat de Lune",   "rarity": "Rare"},
	"bois_sacre":   {"name": "Bois Sacré",      "rarity": "Rare"},
	"pepite_or":    {"name": "Pépite d'Or",     "rarity": "Rare"},
	"rayon_soleil": {"name": "Rayon de Soleil", "rarity": "Rare"},
}

## Contenu réel : liste de dicts {"id", "count"} (pas de doublons d'id).
var items: Array = []


func add_item(item_id: String, count: int = 1) -> void:
	if not ITEM_DEFS.has(item_id):
		print("Inventory : item inconnu '", item_id, "'.")
		return
	for entry in items:
		if entry["id"] == item_id:
			entry["count"] = int(entry["count"]) + count
			inventory_changed.emit()
			return
	items.append({"id": item_id, "count": count})
	inventory_changed.emit()


## Retire "count" exemplaires. Si count <= 0, retire TOUTE la pile (renvoie
## true si l'item existait avec au moins 1 exemplaire, false sinon).
## Pour count > 0 : renvoie false si la quantité demandée n'était pas
## disponible (aucun retrait partiel).
func remove_item(item_id: String, count: int = 1) -> bool:
	for i in range(items.size()):
		var entry: Dictionary = items[i]
		if entry["id"] != item_id:
			continue
		var have: int = int(entry["count"])
		if count <= 0:
			items.remove_at(i)
			inventory_changed.emit()
			return true
		if have < count:
			return false
		have -= count
		if have <= 0:
			items.remove_at(i)
		else:
			entry["count"] = have
		inventory_changed.emit()
		return true
	return false


func get_count(item_id: String) -> int:
	for entry in items:
		if entry["id"] == item_id:
			return int(entry["count"])
	return 0


func has(item_id: String, count: int = 1) -> bool:
	return get_count(item_id) >= count


## Renvoie la fiche de définition d'un item ({"name","rarity"}), vide si inconnu.
func item_def(item_id: String) -> Dictionary:
	return ITEM_DEFS.get(item_id, {})


func rarity_color(rarity: String) -> Color:
	return RARITY_COLOR.get(rarity, Color(1, 1, 1))
