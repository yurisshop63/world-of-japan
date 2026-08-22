# Structure du projet — World of Japan (Godot)

> Ce fichier décrit l'architecture du projet. Il change rarement.
> Mets-le à jour seulement quand tu ajoutes/renommes/déplaces des scènes ou systèmes majeurs.
> À l'inverse de `etat_actuel.md`, ce n'est PAS un journal — c'est une carte du projet.

## Infos générales
- Version de Godot : 4.7.1
- Type de jeu / genre : MMORPG (apprentissage du japonais — thème 曜日)
- Résolution / orientation cible : paysage (viewport 2400×1080, stretch canvas_items)
- Langages utilisés (GDScript / C# / autre) : GDScript

## Arborescence des scènes principales
> Liste les scènes clés et à quoi elles servent. Pas besoin d'exhaustivité, juste les points d'entrée.

```
res://
├── main.tscn / main.gd          — scène racine (terrain + 21 mobs + joueur + UI)
├── mob.tscn / mob.gd            — mob paramétré par mob_type (7 types 曜日)
├── HexagonalGround.gd           — terrain en tuiles hexagonales (FastNoiseLite)
├── player.gd                    — contrôle du joueur (3D, look, /face, /stick)
├── player_stats.gd              — autoload PlayerStats (vie/pouvoir/XP/niveau)
├── summary_panel.gd             — HUD bas-droite (barres + cible + bannière level up)
├── skill_bar.gd                 — autoload SkillBar (compétences + KANJI_DATA)
├── target_system.gd             — autoload TargetSystem (cible actuelle)
├── macro_bar.gd                 — barre de macros
├── title_bar_drag.gd            — panel déplaçable (pattern drag simple)
├── GridOverlay.gd               — affiche la grille 24×11 (lignes A→K, colonnes 1→24)
├── menu_config.gd               — autoload MenuConfig (côté menu, actions, persistance)
├── window_manager.gd            — autoload WindowManager (fenêtres d'action, toggle)
├── menu_layout.gd               — helpers de grille (class_name MenuLayout)
├── menu_style.gd                — styles ronds des boutons (class_name MenuStyle)
├── draggable_button.gd          — base tap/drag long (class_name DraggableButton)
├── menu_root_button.gd          — bouton MENU du menu circulaire
├── menu_slot_button.gd          — boutons du sous-menu (créés dynamiquement)
├── button.gd                    — [SUPPRIMÉ] ancien prototype de menu orphelin
├── top_right_menu.gd            — [SUPPRIMÉ] ancien menu "Petit Menu" (haut-droite)
├── autoload/
│   ├── inventory.gd             — autoload Inventory (liste d'items + drops)
│   ├── quest_system.gd          — autoload QuestSystem (quête "élimine 5 Eau")
│   ├── keybind_config.gd        — autoload KeybindConfig (raccourcis /face /stick)
│   └── mobile_input.gd          — autoload MobileInput (move_vector + look_vector)
├── ui/
│   ├── virtual_joystick.gd/.tscn — joystick virtuel + boutons FACE/STICK orbitaux
│   ├── look_cursor.gd           — curseur caméra "manche à balai" (grille B13)
│   ├── quest_tracker.gd         — panneau de quête déplaçable
│   ├── stats_window.gd/.tscn    — fenêtre Statistiques (grille A11→I3)
│   ├── inventory_window.gd/.tscn— fenêtre Inventaire
│   ├── keybind_window.gd/.tscn  — fenêtre Raccourcis clavier
│   └── orbit_button.gd          — bouton déplaçable contraint à un cercle
└── kanji/
	├── kanji_draw_popup.gd/.tscn — popup de dessin de kanji (scoring temps réel)
	├── stroke_scoring.gd        — calcul du score de tracé
	├── svg_parser.gd            — parsing des SVGs de référence
	└── kanji_data/              — SVG des kanji (attribution KanjiVG, cf. CREDITS.md)
```

## Scripts clés et leur rôle
> Un script = une ligne. Utile pour que Claude sache où chercher sans tout relire.

| Script | Rôle | Attaché à |
|---|---|---|
| `main.gd` | rayon de sélection de cible au clic | `Main` (Node3D) |
| `player.gd` | déplacement, look souris, /face, /stick, lecture de `MobileInput.look_vector` | `Player` |
| `mob.gd` | IA, `DROP_TABLE`, `MOB_NAMES`, XP/loot à la mort | `mob.tscn` |
| `summary_panel.gd` | HUD bas-droite, barres, cible, bannière "Niveau X !" | `UI/SummaryPanel` |
| `menu_root_button.gd` | bouton MENU (drag entre côtés, ouvre le sous-menu) | `UI/Button` |
| `menu_slot_button.gd` | boutons du sous-menu (tap → fenêtre, drag → swap) | dynamique |
| `window_manager.gd` | ouvre/ferme les fenêtres d'action (toggle) | autoload |
| `menu_layout.gd` | grille 24×11 : `rect_from_right`, `rect_from_grid`, miroir | class_name |
| `ui/virtual_joystick.gd` | joystick de déplacement + boutons FACE/STICK orbitaux | `UI/VirtualJoystick` |
| `ui/look_cursor.gd` | curseur caméra (rotation continue, sticky, snapback B13) | `UI/LookCursor` |
| `ui/quest_tracker.gd` | panneau de quête déplaçable | `UI/QuestTracker` |
| `ui/stats_window.gd` | fenêtre Statistiques (stats joueur + toggle Quête) | scène ouverte par le menu |
| `ui/orbit_button.gd` | bouton contraint à un cercle (position angulaire persistée) | dynamique |
| `autoload/inventory.gd` | inventaire (add/remove/get_count), `ITEM_DEFS` | autoload |
| `autoload/quest_system.gd` | quête "élimine 5 Eau (水)", récompenses, relance auto | autoload |
| `autoload/mobile_input.gd` | source de vérité input tactile : `move_vector`, `look_vector` | autoload |
| `kanji/kanji_draw_popup.gd` | popup de dessin, scoring + chrono | dynamique |

## Autoloads / Singletons
> Les scripts globaux déclarés dans Project Settings > Autoload (ordre dans project.godot)

- `PlayerStats` → `res://player_stats.gd`
- `SkillBar` → `res://skill_bar.gd`
- `TargetSystem` → `res://target_system.gd`
- `KeybindConfig` → `res://autoload/keybind_config.gd`
- `MobileInput` → `res://autoload/mobile_input.gd`
- `MenuConfig` → `res://menu_config.gd`
- `WindowManager` → `res://window_manager.gd`
- `Inventory` → `res://autoload/inventory.gd`
- `QuestSystem` → `res://autoload/quest_system.gd`

## Conventions
- Scènes : `snake_case` (ex. `inventory_window.tscn`)
- Scripts : `snake_case.gd`
- Nœuds : PascalCase (ex. `TargetNameLabel`)
- Groupes (`add_to_group`) : pas de groupe critique pour l'instant
- Commentaires des fonctions non triviales : en français, au-dessus de la fonction
- GDScript typé (`-> void:`) dans les fichiers qui le sont déjà

## Systèmes principaux (vue d'ensemble)
> Pour chaque grand système du jeu, une phrase sur comment il est architecturé.

- **Menu circulaire** : `menu_root_button.gd` + `menu_slot_button.gd` sur la grille
  `MenuLayout` (24×11), fenêtres ouvertes par `WindowManager` (toggle, une à la fois).
- **Inventaire** : autoload `Inventory` (liste de `{"id","count"}`), fenêtre `ui/inventory_window`.
- **Quête** : autoload `QuestSystem` (une fiche `QUESTS`, kills comptés par `mob.gd`), panneau `ui/quest_tracker`.
- **Combat / interactions** : skills (kanji) via `skill_bar.gd`, cible via `target_system.gd`, dégâts/scoring kanji.
- **Input mobile** : `MobileInput` reçoit `move_vector` (joystick) + `look_vector` (curseur caméra), lus par `player.gd`.
- **Sauvegarde** : `ConfigFile` (`user://*.cfg`) pour menu (`menu_config.gd`), raccourcis (`keybind_config.gd`).

## Dépendances externes
- Plugins/addons utilisés : aucun
- Assets tiers (packs, polices, sons) : SVGs kanji — KanjiVG (voir `CREDITS.md`, licence CC BY-SA 3.0)

## Points connus de dette technique / zones fragiles
> Ce que tu sais déjà être bancal, dupliqué, ou à refactorer un jour.

- Le look souris existant (`player.gd::_input`) semble avoir le pitch inversé
  (souris vers le haut → la caméra descend) — à confirmer en playtest. Le
  curseur caméra B13 suit la spec (haut → caméra monte). Détail dans `etat_actuel.md`.
- Le pitch a deux limites : 70° pour le look souris, 90° pour le curseur B13.
- `debug_grid.gd.uid` orphelin dans le repo (aucun fichier `.gd` associé).
