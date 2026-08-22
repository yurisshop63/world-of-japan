# Menu circulaire déplaçable — mise en place

## 1. Copier les fichiers

Recopie l'arborescence telle quelle dans ton projet Godot. Les scripts du
menu sont à la racine de `res://` (fichiers à plat) :

```
res://menu_config.gd
res://window_manager.gd
res://menu_layout.gd
res://menu_style.gd
res://draggable_button.gd
res://menu_root_button.gd
res://menu_slot_button.gd
```

`menu_root_button.gd` référence `menu_slot_button.gd` via
`preload("res://menu_slot_button.gd")` : si tu déplaces les fichiers, mets à
jour cette ligne.

## 2. Déclarer les deux Autoloads

Project Settings → Autoload :

| Path | Node Name |
|---|---|
| `res://menu_config.gd` | `MenuConfig` |
| `res://window_manager.gd` | `WindowManager` |

L'ordre importe peu, mais garde `MenuConfig` avant `WindowManager`.

## 3. Remplacer ton script actuel

Sur ton `Button` existant (celui qui avait ton script d'origine), remplace
le script attaché par `res://menu_root_button.gd`.
Tu peux supprimer ton ancien script (tout son comportement est repris et
étendu dans les nouveaux fichiers).

`menu_slot_button.gd` n'a rien à attacher à la main : les 6 boutons sont
créés dynamiquement par `menu_root_button.gd`.

## 4. Tester (F5)

- **Tap** sur MENU → ouvre/ferme les 6 boutons.
- **Rester appuyé sur MENU puis glisser** vers la moitié gauche de l'écran
  et relâcher → le bouton se fixe en haut à gauche, et si le sous-menu est
  ouvert, les 6 boutons se repositionnent en miroir automatiquement.
- **Tap sur un des 6 boutons** → ouvre la fenêtre associée à l'action
  (placeholder de test si la scène n'est pas encore branchée).
- **Rester appuyé sur un des 6 boutons puis le glisser sur un autre** →
  échange leurs actions (donc leurs libellés). Chaque bouton revient
  toujours à sa case de grille fixe, seule l'action qu'il déclenche change.

La configuration (côté du menu + ordre des actions) est sauvegardée
automatiquement dans `user://menu_config.cfg` et rechargée au lancement.

## 5. Brancher tes vraies fenêtres

Dans `menu_config.gd`, remplis le champ `"scene"` de chaque action avec le
chemin vers ta scène de fenêtre, par exemple :

```gdscript
{"id": 0, "label": "Inventaire", "scene": "res://ui/inventory_window.tscn"}
```

Tant que `"scene"` est vide, `WindowManager` affiche une fenêtre générique
de test (avec un bouton Fermer), pratique pour valider le menu avant que
tes fenêtres existent. Depuis la session "toggle" : rappuyer sur le même
bouton d'action referme la fenêtre, et en ouvrir une autre ferme la
précédente (une seule fenêtre d'action ouverte à la fois).

## 6. Réglages disponibles

- `MenuLayout.SLOT_LAYOUT` / `MENU_BUTTON_COLS` / `MENU_BUTTON_ROWS` dans
  `menu_layout.gd` : positions dans la grille 24×11 (voir ci-dessous),
  définies uniquement pour le côté droit — le côté gauche est calculé
  automatiquement par miroir.
- `long_press_time` (0.35s par défaut) et `drag_threshold` (14px par
  défaut) : exportés sur `DraggableButton`, réglables par bouton dans
  l'inspecteur si tu veux un seuil différent entre le bouton menu et les
  boutons d'action.
- Dans `menu_slot_button.gd`, `_find_nearest_slot()` : la ligne
  `size.length() * 0.6` définit la distance de "capture" pour valider un
  échange entre deux boutons.

## 7. Convention de grille (GridOverlay)

Le projet positionne son UI sur une grille fixe, dessinée par
`GridOverlay.gd` (`UI/GridOverlay` dans `main.tscn`) :

- **24 colonnes × 11 lignes.**
- Les **lignes sont des lettres A→K de haut en bas** (A = tout en haut,
  K = tout en bas).
- Les **colonnes sont des chiffres 1→24, numérotées de DROITE (1) à
  GAUCHE (24)**.

`MenuLayout` (class_name) centralise les calculs : `cell_size()`,
`rect_from_right()` (plage col/row depuis le bord droit),
`rect_from_grid()` (lignes par lettre + colonnes numérotées), `mirror_rect()`
et `menu_button_rect()` / `slot_rect()`. Réutilise ces helpers plutôt que
de recalculer une grille ailleurs.

## Pistes d'amélioration (non incluses, pour rester simple)

- Icônes au lieu de texte pour les 6 boutons.
- Aperçu animé du swap pendant le glissement (actuellement le swap se
  valide seulement au relâchement).
- Vibration/retour haptique sur mobile au déclenchement du mode glissement.
