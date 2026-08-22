# État actuel — World of Japan

> Ce fichier est un journal de bord. Tu le REMPLACES (pas besoin de garder l'historique)
> à chaque fin de session de travail. But : qu'une nouvelle conversation Claude
> comprenne en 10 secondes où tu en es et puisse proposer la suite logique.

**Dernière mise à jour :** 22/08/2026 — fin de session "Tickets 1→11" (brief chef de projet).

## Ce sur quoi je travaillais en dernier
Session de tickets (brief chef de projet) : correction de bugs bloquants
(chemin Windows codé en dur, doc incohérente, menus dupliqués, script fantôme,
`remove_item`) + nouvelles fonctionnalités (toggle fenêtres, QuestTracker
déplaçable, fenêtre Statistiques, joystick ×1.5, boutons FACE/STICK orbitaux,
curseur caméra B13). Tout est validé en headless (47 assertions TOUT OK) et
commité/poussé sur `origin/main`.

## Ce qui fonctionne actuellement
- Boot headless propre : `godot4 --headless --path . --quit-after 6` → aucun
  error/warning. Terrain + 21 mobs + joueur + HUD.
- **Menu circulaire unique** (déplaçable) — `top_right_menu.gd` et `button.gd`
  supprimés. Chemin absolu corrigé → projet portable.
- **Toggle fenêtres d'action** (WindowManager, couche canvas 1) : re-tap sur le
  même bouton ferme, nouvelle ouverture remplace l'ancienne ; MENU (z10) et
  sous-menu (z9) restent cliquables au-dessus des fenêtres (z0).
- **Fenêtre Statistiques** (grille A11→I3, z8, pas d'overlay) avec bouton
  "Quête" qui toggle le QuestTracker.
- **QuestTracker déplaçable** (drag sur tout le panneau, clamp écran).
- **Joystick ×1.5** avec **boutons FACE/STICK orbitaux** (OrbitButton), angles
  persistés dans `user://menu_config.cfg` (section `[joystick]`).
- **Curseur caméra B13** : rotation continue "manche à balai" (sticky), snapback
  au relâchement près du centre, yaw libre 360°, pitch ±90°, via
  `MobileInput.look_vector` lu par `player.gd`.
- Phase 1 (quête/loot/inventaire/XP) + noms de mobs → UI target : OK (sessions
  précédentes).

## Ce qui est en cours / à moitié fait
- Rien de bloquant. Tous les tickets 1→11 sont faits et validés en headless.

## Bugs connus / points de vigilance
- **Pitch du look souris probablement inversé** (`player.gd::_input`) : dans
  Godot, `camera_pivot.rotation.x` positif = la caméra regarde VERS LE HAUT ; or
  le code fait `pitch += event.relative.y * sens` (souris vers le bas → regard
  vers le haut). À confirmer en playtest réel — le **curseur B13, lui, suit la
  spec** (haut → caméra monte). Les deux contrôles sont donc INCOHÉRENTS entre
  eux tant que ce n'est pas tranché (une seule correction de signe à choisir).
- **Pitch : deux limites différentes** — look souris `max_pitch = 70°`, curseur
  B13 clamp ±90° (spec). Cohérence à arbitrer en playtest.
- Le look curseur B13 capture les clics souris dans sa zone (~160×160 px autour
  de B13) : un clic de sélection de mob y est intercepté. Acceptable pour
  l'Alpha, à revoir si gênant sur desktop.
- `debug_grid.gd.uid` orphelin dans le repo (aucun `.gd` associé) — à nettoyer
  éventuellement.

## Prochaines étapes prévues
1. **Playtest réel** (F5 sur PC + idéalement Android) pour régler :
   - `VITESSE_MAX_RAD_PAR_SEC` (2.0 par défaut) et `SNAPBACK_THRESHOLD` (10px)
     du curseur caméra ;
   - le signe du pitch (souris vs curseur B13) et les limites 70° vs 90°.
2. Boutons de skills mobiles (slots 1-4, réutiliser SkillBar) — TODO annoncé
   plus tôt.
3. Macros textuelles `/face` `/stick` (LineEdit façon chat MMO) — optionnel.
4. Différenciation élémentaire des kanji/mobs (puissance par élément) — la base
   (14 kanji, 7 types de mobs) est prête.

## Décisions prises récemment (et pourquoi)
- **WindowManager passé en couche canvas 1** (au lieu de 20) : sinon les
  fenêtres d'action recouvraient le MENU et le sous-menu (impossible de re-taper
  un bouton pour fermer la fenêtre — c'était le bug que le toggle devait régler).
  Le z-ordering voulu est : fenêtres (z0) < Statistiques (z8) < sous-menu (z9) <
  MENU (z10), tout dans la couche 1.
- **Sous-menu (menu_window) ajouté au CanvasLayer UI** (au lieu du root de la
  scène) pour les mêmes raisons de couche.
- **Fenêtre Statistiques SANS overlay plein écran** : root IGNORE, seul le panel
  est STOP → le MENU reste cliquable même sous la fenêtre.
- **Boutons FACE/STICK = OrbitButton** (long press → drag projeté sur un cercle
  de rayon fixe `RADIUS_BASE + 40`), angles persistés dans MenuConfig (défauts =
  positions d'origine). `Control` n'a pas de `to_local`/`to_global` → projection
  via `get_global_transform_with_canvas()` du parent.
- **Curseur B13 = "manche à balai" sticky** : pas de retour au centre au
  relâchement (contrairement au joystick), snapback seulement si relâché à
  ≤ SNAPBACK_THRESHOLD du centre.
- **Les scripts du menu restent à la racine** (`res://menu_root_button.gd`, ...) :
  la doc a été corrigée pour décrire la structure réelle plutôt que de déplacer
  les fichiers (risque de casser les `.uid`/`preload`).

## Questions ouvertes / hésitations
- Signe du pitch du look souris + cohérence avec le curseur B13 (voir Bugs connus).
- Limite de pitch : 70° (souris) vs 90° (curseur B13) — à unifier ?
- `VITESSE_MAX_RAD_PAR_SEC` / `SNAPBACK_THRESHOLD` du curseur caméra → valeurs
  définitives à fixer au playtest (2.0 rad/s / 10 px par défaut).
