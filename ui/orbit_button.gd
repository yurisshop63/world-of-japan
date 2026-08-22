class_name OrbitButton
extends DraggableButton
## Bouton déplaçable contraint à un cercle (utilisé par le joystick virtuel
## pour FACE/STICK). Long press puis glissement : le bouton suit le doigt mais
## sa position est projetée sur le cercle de rayon fixe autour du centre donné
## (angle = direction du curseur depuis le centre). Au relâchement, le bouton
## reste à l'angle choisi (persisté par l'appelant via le signal angle_changed).
## Un tap court (sans drag) émet tapped -> l'action du bouton (face/stick).
## Réutilise le pattern tap/drag de DraggableButton.

signal tapped
signal angle_changed(angle: float)

## Centre de l'orbite, en coordonnées locales du parent (ex. centre du joystick).
var orbit_center := Vector2.ZERO
## Rayon fixe de l'orbite (px).
var orbit_radius := 0.0

var _angle := 0.0


## Configure centre/rayon/angle puis place le bouton sur le cercle.
func setup(center: Vector2, radius: float, angle: float) -> void:
	orbit_center = center
	orbit_radius = radius
	_angle = angle
	_place()


func current_angle() -> float:
	return _angle


## Place le bouton à l'angle courant sur le cercle (position locale du parent).
func _place() -> void:
	var pos := orbit_center + Vector2.RIGHT.rotated(_angle) * orbit_radius
	position = pos - size / 2.0


func _on_tap() -> void:
	tapped.emit()


func _on_drag_move(global_pos: Vector2) -> void:
	# Convertit le point global en coordonnées locales du parent (le joystick)
	# via sa transform canvas — Control n'a pas de to_local/to_global.
	var parent := get_parent()
	var local: Vector2 = parent.get_global_transform_with_canvas().affine_inverse() * global_pos
	_angle = (local - orbit_center).angle()
	_place()


func _on_drag_end(_global_pos: Vector2) -> void:
	angle_changed.emit(_angle)
