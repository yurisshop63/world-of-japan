extends Node
## Autoload "MobileInput"
## Source de vérité de l'input tactile/joystick pour le déplacement et le
## regard (curseur caméra B13).
## Le joystick virtuel (res://ui/virtual_joystick.gd) écrit move_vector ici ;
## le curseur caméra (res://ui/look_cursor.gd) écrit look_vector ; player.gd
## lit les deux chaque frame dans _physics_process et les combine à l'input
## clavier (ne le remplace pas).
##
## À déclarer dans Project Settings > Autoload sous le nom "MobileInput".

## Direction/intensité normalisée du stick de déplacement (repère écran :
## x = droite (+), y = bas (+)). (0,0) = relâché, magnitude 1 = poussé au max.
var move_vector := Vector2.ZERO

## vrai quand l'utilisateur est en train de toucher le joystick
var active := false

## Vitesse de rotation normalisée du curseur caméra (repère écran, chacun dans
## [-1,1]) : x = yaw (rotation Y du joueur, gauche/droite), y = pitch (rotation
## X de camera_pivot, haut/bas). (0,0) = curseur au centre. Contrairement à
## move_vector, look_vector PERSISTE au relâchement tant que le curseur reste
## écarté de sa position neutre (comportement "manche à balai").
var look_vector := Vector2.ZERO

## vrai quand le curseur caméra est engagé (touché ou maintenu écarté).
var look_active := false
