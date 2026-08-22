class_name MenuLayout
extends RefCounted
## Grille de référence (pensée pour un écran en paysage) utilisée pour
## positionner le bouton menu et les 6 boutons du sous-menu.
## Toutes les coordonnées de base (SLOT_LAYOUT, MENU_BUTTON_*) sont définies
## pour le cas "bouton menu à droite". Le cas "à gauche" est obtenu par un
## simple miroir horizontal (mirror_rect), donc tu n'as qu'à régler la
## disposition "droite" ci-dessous pour changer l'ergonomie des deux côtés.

const ROWS := 11
const COLS := 24

## Position du bouton menu principal (col1, col2 / row1, row2), mesurée
## depuis le bord DROIT de l'écran, comme dans ton script d'origine.
const MENU_BUTTON_COLS := Vector2i(1, 2)
const MENU_BUTTON_ROWS := Vector2i(0, 1)

## Position des 6 boutons du sous-menu -> modifie ces valeurs pour ajuster
## l'ergonomie. Reprend exactement tes coordonnées d'origine.
const SLOT_LAYOUT := [
	{"cols": Vector2i(4, 5), "rows": Vector2i(0, 1)},  # 1
	{"cols": Vector2i(7, 8), "rows": Vector2i(0, 1)},  # 2
	{"cols": Vector2i(7, 8), "rows": Vector2i(2, 3)},  # 3
	{"cols": Vector2i(6, 7), "rows": Vector2i(4, 5)},  # 4
	{"cols": Vector2i(4, 5), "rows": Vector2i(5, 6)},  # 5
	{"cols": Vector2i(2, 3), "rows": Vector2i(7, 8)},  # 6
]


static func cell_size(viewport_size: Vector2) -> Vector2:
	return Vector2(viewport_size.x / COLS, viewport_size.y / ROWS)


## Calcule le rect (position + taille) pour une plage col/row, mesurée
## depuis le bord DROIT de l'écran (même logique que le script d'origine :
## x = largeur_écran - col2 * largeur_case).
static func rect_from_right(viewport_size: Vector2, cols: Vector2i, rows: Vector2i) -> Rect2:
	var cell := cell_size(viewport_size)
	var w: float = (cols.y - cols.x + 1) * cell.x
	var h: float = (rows.y - rows.x + 1) * cell.y
	var x: float = viewport_size.x - cols.y * cell.x
	var y: float = rows.x * cell.y
	return Rect2(Vector2(x, y), Vector2(w, h))


## Rect pour une plage de grille exprimée en lettres de lignes (A→K, de haut en
## bas) et en numéros de colonnes (1→24, depuis la droite). Ex. la fenêtre
## Statistiques : rect_from_grid(vp, "A", "I", 3, 11) = case A11 → case I3.
static func rect_from_grid(viewport_size: Vector2, row_from: String, row_to: String, col_from: int, col_to: int) -> Rect2:
	return rect_from_right(viewport_size, Vector2i(col_from, col_to), Vector2i(_row_index(row_from), _row_index(row_to)))


## Convertit une lettre de ligne ("A" → 0 ... "K" → 10) en index, clampé pour
## rester dans la grille.
static func _row_index(letter: String) -> int:
	var index := int(letter.to_upper().unicode_at(0)) - 65
	return clampi(index, 0, ROWS - 1)


## Miroir horizontal d'un rect par rapport à la largeur de l'écran.
## C'est cette fonction qui transforme automatiquement la disposition
## "à droite" en disposition "à gauche".
static func mirror_rect(viewport_size: Vector2, rect: Rect2) -> Rect2:
	var mirrored_x: float = viewport_size.x - rect.position.x - rect.size.x
	return Rect2(Vector2(mirrored_x, rect.position.y), rect.size)


static func menu_button_rect(viewport_size: Vector2, side: int) -> Rect2:
	var r := rect_from_right(viewport_size, MENU_BUTTON_COLS, MENU_BUTTON_ROWS)
	if side == MenuConfig.Side.LEFT:
		r = mirror_rect(viewport_size, r)
	return r


static func slot_rect(viewport_size: Vector2, slot_index: int, side: int) -> Rect2:
	var def: Dictionary = SLOT_LAYOUT[slot_index]
	var r := rect_from_right(viewport_size, def.cols, def.rows)
	if side == MenuConfig.Side.LEFT:
		r = mirror_rect(viewport_size, r)
	return r
