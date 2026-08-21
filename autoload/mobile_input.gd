extends Node
## Autoload "MobileInput"
## Source de vérité de l'input tactile/joystick pour le déplacement.
## Le joystick virtuel (res://ui/virtual_joystick.gd) écrit move_vector ici ;
## player.gd le lit chaque frame dans _physics_process et le combine à l'input
## clavier (ne le remplace pas).
##
## À déclarer dans Project Settings > Autoload sous le nom "MobileInput".

## Direction/intensité normalisée du stick (repère écran : x = droite (+),
## y = bas (+)). (0,0) = relâché, magnitude 1 = poussé au maximum.
var move_vector := Vector2.ZERO

## vrai quand l'utilisateur est en train de toucher le joystick
var active := false
