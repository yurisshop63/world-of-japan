# Structure du projet — World of Japan (Godot)

> Ce fichier décrit l'architecture du projet. Il change rarement.
> Mets-le à jour seulement quand tu ajoutes/renommes/déplaces des scènes ou systèmes majeurs.
> À l'inverse de `etat_actuel.md`, ce n'est PAS un journal — c'est une carte du projet.

## Infos générales
- Version de Godot : 4.7.1	
- Type de jeu / genre : MMORPG
- Résolution / orientation cible : 
- Langages utilisés (GDScript / C# / autre) : 

## Arborescence des scènes principales
> Liste les scènes clés et à quoi elles servent. Pas besoin d'exhaustivité, juste les points d'entrée.

- `res://scenes/main/Main.tscn` — scène racine, charge le menu / le jeu
- `res://scenes/player/Player.tscn` — 
- `res://scenes/levels/...` — 
- `res://scenes/ui/...` — 
```
res://autoload/menu_config.gd
res://autoload/window_manager.gd
res://ui/menu/menu_layout.gd
res://ui/menu/menu_style.gd
res://ui/menu/draggable_button.gd
res://ui/menu/menu_root_button.gd
res://ui/menu/menu_slot_button.gd
```	

## Scripts clés et leur rôle
> Un script = une ligne. Utile pour que Claude sache où chercher sans tout relire.

| Script | Rôle | Attaché à |
|---|---|---|
| `player.gd` | contrôle du joueur | Player.tscn |
| `game_manager.gd` | état global du jeu | autoload |
| ... | ... | ... |

## Autoloads / Singletons
> Les scripts globaux déclarés dans Project Settings > Autoload

- `GameManager` → `res://scripts/game_manager.gd`
- ...

## Conventions de nommage
- Scènes : 
- Scripts : 
- Nœuds : 
- Groupes (`add_to_group`) : 

## Systèmes principaux (vue d'ensemble)
> Pour chaque grand système du jeu, une phrase sur comment il est architecturé.

- **Dialogue** : 
- **Inventaire** : 
- **Sauvegarde** : 
- **IA ennemis** : 
- **Combat / interactions** : 

## Dépendances externes
- Plugins/addons utilisés : 
- Assets tiers (packs, polices, sons) : 

## Points connus de dette technique / zones fragiles
> Ce que tu sais déjà être bancal, dupliqué, ou à refactorer un jour.

- 
