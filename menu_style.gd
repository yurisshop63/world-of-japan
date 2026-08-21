class_name MenuStyle
extends RefCounted
## Applique un style rond identique sur tous les états d'un bouton
## (normal, hover, pressed, focus), pour éviter que Godot retombe
## sur le style carré par défaut du thème quand la souris passe dessus.

static func apply_round_styles(btn: Button, radius: int, base_color: Color) -> void:
	var normal_style := make_round_stylebox(base_color, radius)
	var hover_style := make_round_stylebox(base_color.lightened(0.15), radius)
	var pressed_style := make_round_stylebox(base_color.lightened(0.3), radius)
	var focus_style := make_round_stylebox(base_color, radius)
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("focus", focus_style)
	btn.focus_mode = Control.FOCUS_NONE


static func make_round_stylebox(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
