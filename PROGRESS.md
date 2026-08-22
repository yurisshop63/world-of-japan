# PROGRESS.md

> Fichier d'état du projet — mis à jour par l'agent (DeepSeek/OpenCode) à la fin de chaque session de travail.
> Objectif : qu'une nouvelle session (ou un autre worker) puisse reprendre sans que l'humain ait à tout réexpliquer.

**Dernière mise à jour :** 2026-08-22
**Dernier commit poussé :** `7ffbc4a`

---

## 🎯 Objectif du projet
Jeu Godot 4.7 (3D) style MMORPG "World of Japan" : combat basé sur le dessin de
kanji. Le joueur dessine un kanji pour déclencher un skill, la qualité du tracé
(score 0-100) détermine dégâts/critique. Objectif Alpha : une boucle jouable
minimale (1 perso, 1 zone, mobs, combat kanji).

---

## ✅ Fait
- [x] **Repo Git** : `git init` dans `jeu-mmorpg-japanese-learning-ARCHIVE`, branche
	  `main`, `.gitignore` Godot 4 (`.godot/`, `*.tmp`, `/android/`, `/exports/`,
	  `*.rar`), remote `origin` → `https://github.com/yurisshop63/world-of-japan.git`.
- [x] **Commit initial** : `f6346cc` — tout le projet existant + `World_of_Japan_Roadmap.md`.
- [x] **Import système kanji** depuis kanji-game vers `res://kanji/` :
	  `stroke_scoring.gd` (module `StrokeScoring`), `svg_parser.gd` (module
	  `SvgParser`), `kanji_data/06c34.svg` (+ `.import`, `.uid`). Chemin SVG dans
	  `run_auto_test()` adapté → `res://kanji/kanji_data/06c34.svg`. Pas de conflit
	  de `class_name` (aucun autre script ne les portait).
- [x] **Popup réutilisable** `res://kanji/kanji_draw_popup.tscn` + `.gd` (CanvasLayer,
	  layer 10, overlay par-dessus le 3D) : zone de dessin (Panel + Line2D), référence
	  SVG, boutons Valider/Effacer/Annuler, ESC = annuler. Généralisé :
	  `kanji_svg_path` passé via `open()`, signaux `drawing_validated(score)` et
	  `drawing_cancelled()`. Flash couleur + score label repris de `test_trace.gd`.
- [x] **Branchement combat** dans `skill_bar.gd` (`use_slot()`) : instancie le popup
	  avec le kanji du skill (tous les skills → 水 pour l'instant), attend le signal,
      applique la formule ROADMAP : <40 → 0 dégât ; 40-70 → base 2-6 ;
      70-90 → ×1.5 ; >90 → ×2 (critique). Annulation → aucune action, pas de perte
	  de tour. Blocage d'un 2e dessin simultané.
- [x] **Correctif contraste popup** : fond de la zone de dessin clair (`#F0F0F0`,
	  StyleBoxFlat dans le `.tscn`), tracé joueur quasi noir 5px, flash de score
	  assombri pour rester lisible sur fond clair (retour à `#F0F0F0`).
- [x] **Correctif lisibilité référence** : le panneau de référence a maintenant
	  un fond clair (`#F5F5F5`, StyleBoxFlat bordé) et le kanji guide est dessiné
	  en **trait continu bleu nuit net** (4px) au lieu des pointillés orange clair
	  fins illisibles. Contraste fort avec le tracé joueur (quasi noir) tout en
	  restant parfaitement lisible.
- [x] **Suppression de la pause (temps réel)** : le monde ne se met plus en pause
	  pendant le dessin ; le popup tourne en mode normal. La vitesse devient un
	  second facteur de score. Souris forcée en `MOUSE_MODE_VISIBLE` à `open()`
	  et restaurée à la fermeture (validé, annulé ou fermeture forcée via
	  `_exit_tree`).
- [x] **Chronométrage** : `Time.get_ticks_msec()` à `open()`, `elapsed_ms` calculé
	  à la validation. `par_time_ms` (exporté, défaut 3000 pour 水) lisible depuis
	  le skill (`skill.get("par_time_ms")`). Label "Temps : X.Xs" affiché et
	  mis à jour en `_process`.
- [x] **Formule combinée précision × vitesse** dans `skill_bar._compute_damage()` :
	  score < 40 → 0 dégât ; sinon précision (base / ×1.5 / ×2 aux paliers
	  40-70 / 70-90 / >90) × vitesse (elapsed ≤ 0.6×par → ×1.3 ; ≤ par → ×1.0 ;
	  ≤ 1.5×par → ×0.8 ; au-delà → ×0.6). Dégâts = base × précision × vitesse,
	  arrondi, min 1 si score ≥ 40.
- [x] **Mort pendant le dessin** : `SkillBar` connecte `PlayerStats.player_died` ;
	  si un popup est ouvert, il est fermé (comme un `drawing_cancelled`), le mode
	  souris est restauré, `_active_popup` est libéré, aucun dégât appliqué. Le mob
	  peut continuer à frapper tant que le joueur est vivant (pression voulue).
- [x] **Validation headless** (Godot 4.7.1) :
	  `--import` OK (cache `class_name` rafraîchi : StrokeScoring + SvgParser).
	  Auto-test de scoring OK (parfait 100, aléatoire ~0-15, imprécis 65-85).
	  Popup instanciée en headless : invisible par défaut, `open()` → visible avec
	  4 traits de référence (水). Jeu complet lancé `--quit-after 5` : aucun
	  script error. Tests simulés (via autoload temporaire, retiré ensuite) :
	  formule combinée vérifiée sur 8 cas, `drawing_validated(score=100,
	  elapsed_ms≈1)` émis dans le vrai contexte de jeu, monde non pausé, mort du
	  joueur → popup libéré sans dégâts.

- [x] **Push sur main** — repo distant `world-of-japan` créé (vide, sans README)
	  et branché. Poussé : `f6346cc` → `a631476` → `6dbb3db` (HEAD = `main`).
	  Remote : `https://github.com/yurisshop63/world-of-japan.git`
	  (origin, tracking `origin/main`).
- [x] **Ajout de 3 kanji (土/火/風)** pour sortir du cas unique 水 :
	  - SVG récupérés depuis **KanjiVG** (`github.com/KanjiVG/kanjivg`, licence
		CC BY-SA 3.0 — attribué dans `CREDITS.md` et en-tête de chaque SVG) :
		`0571f.svg` (土, 3 traits), `0706b.svg` (火, 4 traits), `098a8.svg`
		(風, 9 traits). Codepoints vérifiés : 土=U+571F, 火=U+706B, 風=U+98A8.
		Note : la consigne initiale donnait U+5730 (=地) pour 土, corrigé.
		Fichiers `.import` générés par Godot (`--import`).
	  - **Skills associés** dans `skill_bar.gd` via `KANJI_DATA` (structure
		dédiée : dict nom→{name, kanji, par_time_ms}, dupliqué par slot) :
		slot 1 = Frappe Eau (水, 3000ms), slot 2 = Frappe Terre (土, 2000ms),
		slot 3 = Frappe Feu (火, 2800ms), slot 4 = Frappe Vent (風, 5500ms).
		Slots 5-9 vides. Pas de différenciation de puissance (base 2-6, portée 3.0).
	  - **`run_auto_test_all()`** ajouté à `stroke_scoring.gd` (boucle sur les
		4 kanji) ; `run_auto_test()` reste pour 水 seul.
	  - **Validation headless OK** : parfait = 100 pour les 4 kanji ; aléatoire
		= 14 (水), 10 (土), 26 (火), 5 (風) ; humain imprécis = 79-89. Le 26 de
		火 reste très en dessous du seuil de réussite (60) : artefact statistique
		(traits aléatoires qui recoupent le cadre), pas un défaut de scoring.
		Slots vérifiés (4 équipés, 5-9 vides), popup ouverte avec chacun des
		4 kanji (traits affichés 4/3/4/9), jeu complet lancé sans erreur.
- [x] **Terrain procédural** (`HexagonalGround.gd`) : le sol n'est plus un unique
	  hexagone monochrome. Grille de petits hexagones (tuiles, `hex_size = 5`)
	  couvrant le disque de rayon 50, chacun coloré par **FastNoiseLite**
	  (Simplex + FBM 3 octaves, fréquence 0.04) interpolé entre 3 teintes —
	  roche / terre brune / herbe. Choix technique : **noise-based per-tile
	  color** (un `StandardMaterial3D` par tuile, couleur dérivée du bruit à la
	  position de la tuile), pas de texture externe, léger. Collision (box
	  `radius*2.3`) et 6 murs inchangés. `material_color` retiré (était forcé en
	  cyan dans main.tscn).
- [x] **7 types de mobs élémentaires** (thème 曜日, jours de la semaine) dans
	  `mob.gd`/`mob.tscn` : un seul `mob.tscn` paramétré par `mob_type` (enum
	  `MobType`), silhouette construite par script en **primitives low-poly**
	  (Sphere/Box/CylinderMesh) — pas d'assets externes, cohérent avec le joueur
	  (BoxMesh). Chaque type : couleur (albedo), forme, échelle, hauteur de
	  health bar. Les 7 : 火 Feu (flamme rouge/orange), 水 Eau (sphère bleue
	  aplatie + vaguelettes), 土 Terre (bloc brun), 月 Lune/lundi (bleu pâle +
	  cratères), 木 Bois/jeudi (tronc + feuillage), 金 Or/vendredi (lingot doré +
	  pépites), 日 Soleil/dimanche (sphère jaune + 8 rayons). IA, `take_damage`,
	  états IDLE/CHASE/RETURN/DEAD, respawn et health_bar **inchangés** — seul le
	  visuel diffère.
- [x] **Placement mobs** dans `main.tscn` : 21 instances (3 par type) réparties
	  sur 3 anneaux concentriques (rayons ~18 / ~30 / ~42, angles décalés) pour
	  éviter les amas et l'aggro en chaîne (un mob de chaque type par anneau).
	  Joueur spawn au centre (0,3,0) : aucun mob à moins de ~18 unités.
- [x] **Validation mobs** (headless, autoload temporaire retiré ensuite) : 21
	  mobs présents (3 par type), modèle construit pour chaque type (3 à 9
	  primitives), `take_damage(5)` décrémente et passe en CHASE, mise à 0 →
	  DEAD, respawn programmé. Lancement complet `--quit-after 8` : aucun script
	  error ni warning.
- [x] **Commandes de combat façon DAoC** (`player.gd`) :
	  - **FACE** (`face()`) : oriente instantanément le joueur vers
	    `TargetSystem.current_target` (rotation Y seule via `look_at`, pas
		d'animation). Ne fait rien si aucune cible (log discret, pas d'erreur).
	  - **STICK** (`toggle_stick()` / état `sticking`, logique dans
	    `_physics_process` → `_process_stick()`) : suit automatiquement la cible
	    en maintenant la portée de mêlée `MELEE_RANGE = 1.5` (même valeur que
	    `mob.gd: melee_range`) et en restant face à elle. Désactivation
		automatique si la cible meurt / devient nulle (via le check d'invalidité),
		ou si le joueur rappuie (toggle). Respecte la gravité/collision existante
		de `player.gd` (n'écrase que la vélocité XZ, comme `_process_chase` de
	    mob.gd). Implémenté comme **état sur player.gd** (pas de script séparé qui
	    dupliquerait le mouvement).
- [x] **Autoload KeybindConfig** (`res://autoload/keybind_config.gd`, déclaré dans
	  `project.godot`) : dictionnaire `action -> keycode` avec `DEFAULT_KEYBINDS`
	  (face → **C**, stick → **V** — touches vérifiées libres : flèches, A/Z,
	  T/Y/U/I/O, 1-9, Ctrl, NumLock déjà pris). API : `get_keycode(action)`,
	  `set_keycode(action, keycode)` (sauvegarde + émet `keybinds_changed`),
	  `actions` (liste pour l'UI), `load_config()/save_config()` sur
	  `user://keybinds.cfg` (même pattern ConfigFile que `MenuConfig`).
- [x] **Câblage clavier** dans `player.gd::_unhandled_key_input` : les touches
	  face/stick sont lues depuis `KeybindConfig.get_keycode()` (pas de touche en
	  dur) — réassignables sans retoucher au code.
- [x] **Fenêtre de configuration** (`res://ui/keybind_window.gd/.tscn`) : liste
	  les actions de `KeybindConfig.actions` (label + bouton affichant la touche
	  actuelle), bouton "Réassigner" qui capture la prochaine touche pressée
	  (Échap = annuler, modificateurs seuls ignorés, événement consommé pendant
	  la capture), met à jour KeybindConfig + sauvegarde. Intégrée au menu
	  circulaire existant : action id=5 "Raccourcis" dans `menu_config.gd` avec
	  `scene: "res://ui/keybind_window.tscn"` (même champ "scene" que les autres
	  actions, ouverte par `WindowManager.open_action()`) — pas de nouveau point
	  d'entrée UI parallèle.
- [x] **Validation raccourcis** (headless, autoload temporaire retiré ensuite) :
	  KeybindConfig (défauts C/V, set_keycode OK), `face()` oriente vers la cible
	  (rotation Y), `toggle_stick()` active puis se désactive quand la cible
	  devient nulle, fenêtre instanciée avec 2 actions listées. Lancement complet
	  `--quit-after 6` : aucun script error ni warning.
- [x] **Autoload MobileInput** (`res://autoload/mobile_input.gd`, déclaré dans
	  `project.godot`) : source de vérité de l'input tactile. API : variable
	  publique `move_vector: Vector2` (repère écran : x = droite +, y = bas + ;
	  (0,0) = relâché, magnitude 1 = poussé au max) et `active: bool`. Écrit par
	  le joystick, lu par `player.gd` chaque frame.
- [x] **Joystick virtuel** (`res://ui/virtual_joystick.gd/.tscn`) : Control avec
	  base (cercle fixe, `_draw()`) + stick (cercle qui suit le doigt, rayon
	  limité `MAX_OFFSET = 36`). Écrit `MobileInput.move_vector` (clampé +
	  normalisé) à chaque mouvement. Gère souris (PC) et tactile (Android).
- [x] **Combinaison d'input dans `player.gd::_physics_process`** : le
	  `MobileInput.move_vector` est ADDITIONNÉ à l'input clavier existant
	  (`input_dir.x += mv.x`, `input_dir.z += mv.y`) puis le tout est normalisé —
	  le clavier reste fonctionnel, les deux sources se combinent.
- [x] **Boutons FACE/STICK** autour du joystick (en arc à droite du cercle, hors
	  du rayon du stick) : FACE → `Player.face()`, STICK → `Player.toggle_stick()`
	  (récupération du Player via `get_node_or_null("Main/Player")`, même pattern
	  que macro_bar.gd/skill_bar.gd). Le bouton STICK affiche un état visuel
	  (vert = actif, sombre = inactif) reflétant `Player.sticking` (mis à jour en
	  `_process`, style réappliqué seulement si l'état change).
- [x] **Positionnement opposé au menu + synchronisation croisée** (étape la plus
	  délicate, testée dans les deux sens) :
	  - Le joystick est TOUJOURS positionné du côté opposé à `MenuConfig.side`
	    (source de vérité unique, voir section "Étape 1" ci-dessous).
	  - Il écoute `MenuConfig.config_changed` → `_apply_opposite_side()`.
	  - Drag du joystick (long-press-then-drag, mêmes `long_press_time = 0.35` /
	    `drag_threshold = 14.0` que draggable_button.gd) : si le joystick relâché
		est de l'autre côté de la moitié d'écran, il appelle
	    `MenuConfig.set_side(_opposite(released_side))` — même API que le drag du
	    menu lui-même, pas de logique dupliquée. Un flag `_ignore_next_config`
	    empêche le joystick de se re-repositionner aussitôt après son propre drag.
	  - Réciproque : si le MENU est dragué (menu_root_button.gd existant → 
	    `MenuConfig.set_side`), `config_changed` est émis → le joystick bascule
	    automatiquement de côté. Résultat : menu et joystick TOUJOURS opposés,
		quel que soit celui qu'on déplace.
	  - **Choix (étape 4.4)** : PAS de position fine persistante du joystick.
		Position = côté opposé au menu (recalculée à chaque bascule/redim),
		repositionnement libre du drag temporaire (perdu au prochain basculement).
		Cohérent avec le menu (qui n'a pas de position fine non plus). Pas de
	    nouveau fichier de config : la source de vérité reste `MenuConfig.side`
	    (déjà persisté dans `user://menu_config.cfg`).
- [x] **Intégration `main.tscn`** : instance `VirtualJoystick` ajoutée comme
	  enfant du CanvasLayer `UI` (à côté de MacroBar, TopRightMenu, GridOverlay,
	  bouton MENU), positionnée par défaut à l'opposé du bouton MENU.
- [x] **Validation joystick** (headless, autoload temporaire retiré ensuite) :
	  joystick instancié dans UI ; `move_vector(0,-1)` → vélocité XZ du joueur ≠ 0,
	  reset → immobile ; `MenuConfig.set_side` → joystick bascule côté opposé ;
	  drag simulé du joystick de l'autre côté → `MenuConfig.side` bascule (sens
	  joystick→menu) ; boutons FACE/STICK présents. Lancement complet
	  `--quit-after 6` : aucun script error ni warning.

### 🕹️ Session "écran de dessin + joystick fix" (3 chantiers)
- [x] **Chantier 1 — Correctif joystick (course diagonale permanente)** :
	  bug trouvé : au relâchement d'un appui simple, `_end_press()` appelait
	  `_update_stick(Vector2.ZERO)` qui calculait `delta = (0,0)-(60,80)` →
	  `move_vector` restait à (-0.6, -0.8) sans jamais être remis à zéro, et
	  `player.gd` additionnait `mv` sans vérifier `MobileInput.active` → le joueur
	  courait en permanence en diagonale avant-gauche. Corrigé :
	  - `_reset_stick()` : stick visuel **instantanément au centre** (`_center()`),
		`move_vector = ZERO`, `active = false`, sans interpolation (appelé à
		`_end_press()` et au passage en mode drag).
	  - **Dead zone** `DEAD_ZONE = 0.12` (12% de `MAX_OFFSET` = 36, soit ~4.3px) :
		tant que le doigt/curseur reste dans cette zone, `move_vector` reste à
		ZERO (le stick visuel peut bouger, l'input non). Anti-tremblement et
	    anti-résidu au relâchement.
	  - **Garde double** dans `player.gd::_physics_process` :
		`if MobileInput.active and mv.length() > 0.01:` — l'input mobile n'est
	    jamais additionné quand `active == false`.
	  - Helper `_center()` centralisé (base du stick en coords locales).
	  - Validation headless (autoload temporaire retiré) : dead zone au centre /
	    à 2px → ZERO ; à 10px → non nul ; relâchement simple et après drag →
	    move_vector=ZERO, active=false, stick au centre, menu inchangé ;
	    `active=false` → le joueur ne bouge pas. 6/6 OK.
- [x] **Chantier 2 — Refonte complète de l'écran de dessin de kanji** :
	  `kanji/kanji_draw_popup.gd/.tscn` réécrits — l'UI est **entièrement
	  construite en code** (le `.tscn` est réduit au CanvasLayer racine) pour un
	  positionnement dynamique selon `MenuConfig.side` :
	  - **Position/taille en repère GridOverlay** (`MenuLayout.rect_from_right`,
	    même grille 24×11 que `GridOverlay`/`menu_layout.gd`) : carré de dessin
	    ancré du **même côté que le bouton MENU** (`MenuConfig.side`), lignes
	    **B..J** en hauteur (indices 1..9), colonnes **1..9** en largeur (col 1 =
	    bord droit). Le bord bas tombe sur le haut de la ligne K (juste au-dessus
	    du bandeau summary), le bord haut juste sous le bouton MENU. Bascule en
	    miroir sur `MenuConfig.config_changed` (pattern `_apply_layout`, pas de
	    logique dupliquée). Le joystick reste toujours côté opposé (inchangé).
	  - **3 boutons d'action circulaires** en bas du carré, centrés verticalement
		(le gros Valider fixe la ligne) : **Valider** (vert, bas-droite, plus gros
		≈ une case de grille → `drawing_validated(score, elapsed_ms)`) ;
		**Retour dernier trait** (orange, bas-centre, **undo unitaire** — retire
		UN trait de la pile `player_strokes` + son Line2D, ne fait rien si vide) ;
		**Effacer** (rouge, bas-gauche, reset complet). Le bouton **Annuler**
		global (fermeture, ESC) reste **séparé** (haut-droite du carré, gris).
	  - **3 références de kanji au choix**, affichées **au-dessus et du côté
		opposé au menu** par rapport au carré (vers le centre de l'écran) :
	    droitier → haut-gauche ; gaucher → haut-droite. Clic/tap sur une référence
	    → elle devient le kanji actif (`_selected_index`), son `par_time_ms` est
	    appliqué, et le scoring (`StrokeScoring`) se fait contre ELLE (pas contre
	    un kanji fixe imposé). Surlignage vert de la référence sélectionnée.
	    Le premier candidat (kanji du skill) est sélectionné par défaut.
	  - **Suppression de l'assombrissement de fond** : plus aucun `ColorRect`
		semi-transparent. La racine est en `MOUSE_FILTER_IGNORE` (le monde 3D et
		le joystick restent visibles/interactifs, seuls les enfants STOP captent).
	  - `open(candidates)` : nouvel argument = liste de dicts
		`{"svg","par_time_ms","name"}` (3 références). `skill_bar.gd` a gagné
		`_build_candidates(skill)` : kanji du skill + 2 autres tirés au hasard
		dans `KANJI_DATA` (TODO commenté : affiner la pertinence élémentaire,
		cf. ROADMAP point 2).
	  - Validation headless (autoload temporaire retiré) : carré droitier en
		B-J/1-9 (9×9 cases, bord droit, haut = ligne B, bas = haut de ligne K) ;
		3 références en haut-gauche avec traits dessinés ; 3 boutons positionnés
		(Effacer/Retour/Valider, Valider plus gros) ; bascule `set_side(LEFT)` →
		carré à gauche + références en haut-droite ; aucun ColorRect dans l'arbre ;
	    undo unitaire retire un trait à la fois ; sélection de référence change
	    le kanji de scoring (parfait = 100) + `par_time_ms`. 7/7 OK.
- [x] **Chantier 3 — Base de données de kanji étendue (4 → 14)** :
	  - 10 nouveaux SVG depuis **KanjiVG** (`github.com/KanjiVG/kanjivg`, licence
	    CC BY-SA 3.0 — `CREDITS.md` mis à jour) : `06728.svg` (木, 4 traits),
	    `091d1.svg` (金, 8), `06708.svg` (月, 4), `065e5.svg` (日, 4),
	    `05c71.svg` (山, 3), `05ddd.svg` (川, 3), `096f7.svg` (雷, 13),
	    `096e8.svg` (雨, 8), `068ee.svg` (森, 12), `082b1.svg` (花, 7).
	    **Codepoints vérifiés** (piège U+5730/U+571F de la session précédente) :
	    木=U+6728, 金=U+91D1, 月=U+6708, 日=U+65E5, 山=U+5C71, 川=U+5DDD,
	    雷=U+96F7, 雨=U+96E8, 森=U+68EE, 花=U+82B1. `kvg:element` = kanji attendu
	    (vérifié par script). `.import` générés par `godot --import`.
	  - `KANJI_DATA` dans `skill_bar.gd` : 14 entrées (4 originaux + 10 nouveaux
	    : Bois/Or/Lune/Soleil/Montagne/Rivière/Tonnerre/Pluie/Forêt/Fleur).
	    `par_time_ms` extrapolé (~base 700 + ~500-550 ms/trait, cohérent avec
	    水=3000/4 traits, 土=2000/3, 火=2800/4, 風=5500/9) : ex 雷=8000 (13 traits),
	    森=7200 (12), 金/雨=5000 (8), 花=4300 (7), 木/月/日=2800 (4), 山/川=2000 (3).
	  - `run_auto_test_all()` étendu aux 14 kanji (perfect/random/noisy).
	    **Constantes de scoring intactes** (`DISTANCE_TO_SCORE_FACTOR = 2.2`,
	    verdict ≥ 60, normalisation globale par côté — décisions actées non
	    touchées).
	  - Validation headless (autoload temporaire retiré) : les 14 SVG chargent
	    le bon nombre de traits ; parfait = 100 partout ; imprécis = 74-88 ;
	    aléatoire faible ; `KANJI_DATA` = 14 entrées ; popup ouvrable avec
	    chacun des 14 kanji. Lancement complet : aucun script error ni warning.

### 🕹️ Session "boucle de jeu minimale" — quête, loot, inventaire, XP, level up (Phase 1)
- [x] **Autoload Inventory** (`res://autoload/inventory.gd`, déclaré dans
	  `project.godot`) : inventaire **minimal en liste** (pas de grille). Données
	  avant code : `ITEM_DEFS` = fiches d'items (thème 曜日, cohérent avec les 7
	  types de mobs) — `{"name", "rarity"}` + `RARITY_COLOR` (Commun/Rare).
	  7 items : Essence de Feu/Eau/Terre (Commun), Éclat de Lune, Bois Sacré,
	  Pépite d'Or, Rayon de Soleil (Rare). API : `add_item(id, count)` (merge),
	  `remove_item(id, count) -> bool` (pas de retrait partiel), `get_count`,
	  `has`, `item_def`, `rarity_color` ; signal `inventory_changed`.
- [x] **Loot basique dans `mob.gd`** : `DROP_TABLE` (const, 1 ligne par type de
	  mob `MobType` → `{"item_id", "chance"}` ; Commun ~60%, Rare 25-30%). Un seul
	  lancer par mort dans `_drop_loot()` (appelé depuis `die()`), réussite →
	  `Inventory.add_item`. Données avant code : ajouter un loot = ligne dans
	  `DROP_TABLE` + fiche dans `Inventory.ITEM_DEFS`.
- [x] **Autoload QuestSystem** (`res://autoload/quest_system.gd`) : quête ultra
	  simple façon Alpha. Données avant code : `QUESTS` = fiches
	  `{"id","name","description","objective": {"type":"kill_mobs","mob_type","count"},
	  "reward_xp","reward_items"}`. La quête active par défaut : **"Élimine 5
	  esprits d'eau (水)"** → récompense 300 XP + 1 Pépite d'Or. `mob.gd::die()`
	  appelle `QuestSystem.on_mob_killed(mob_type)` (les kills d'un autre type ne
	  comptent pas). À la complétion : récompenses puis **la quête recommence**
	  (boucle jouable minimale : le combat garde un but). Signaux
	  `quest_progress(quest_id,current,required)` et `quest_completed(quest_id)`.
- [x] **XP = précision × vitesse moyen du combat** (TODO Phase 1 fermé) :
	  `skill_bar.gd` accumule `_combat_multipliers` (un multiplicateur précision ×
	  vitesse par kanji dessiné, `_performance_multiplier()` ; échec <40 = 0).
	  `mob.gd::die()` : `SkillBar.xp_multiplier()` (moyenne, 1.0 si aucun kanji)
	  puis `reset_combat()`, XP du kill = `50 × moyenne`. Factorisé : `_compute_damage`
	  et `_performance_multiplier` partagent les mêmes paliers (pas de divergence).
- [x] **Feedback de level up** : `PlayerStats` émet `leveled_up(level)` (élevé
	  dans `add_xp`). `summary_panel.gd` affiche une **bannière centrée "Niveau X !"**
	  (Label construit en code, ajouté au CanvasLayer UI en `call_deferred` — piège
	  : `add_child` direct pendant le `_ready` de la construction de main.tscn →
	  "Parent node is busy", corrigé), disparaît après ~2s (tween).
- [x] **UI QuestTracker** (`res://ui/quest_tracker.gd`, nœud `UI/QuestTracker` dans
	  `main.tscn`, en-dessous de MacroBar) : petit panneau translucide (StyleBoxFlat,
	  construit en code) affichant le nom de la quête + "Élimine N mobs : x / N".
	  Écoute `quest_progress`/`quest_completed` ; `mouse_filter = IGNORE` (ne bloque
	  pas le clic sur le monde).
- [x] **Fenêtre Inventaire** (`res://ui/inventory_window.gd/.tscn`, même structure
	  que `keybind_window` : Backdrop + CenterPanel + VBox) : liste des items
	  "Nom ×quantité", coloré selon la rareté, reconstruite sur
	  `inventory_changed`. Accessible via le menu circulaire : action id=0
	  (placeholder "1") remplacée par **"Inventaire"** → scene
	  `res://ui/inventory_window.tscn` (`MenuConfig.actions`). Les 5 autres
	  placeholders inchangés.
- [x] **Validation headless** (autoload temporaire `temp_session_test.gd`, retiré
	  ensuite) : merge/remove/get_count d'inventaire (6 cas), quête (démarrage
	  0/5, kills du mauvais type ignorés, complétion → +1 Pépite d'Or + 3 bulles
	  DAoC de 300 XP, relance auto), multiplicateur XP (parfait rapide 2.6, échec 0,
	  moyenne (2.6+0)/2 = 1.3, reset), tables de drop complètes pour les 7 types +
	  items existants, 300 drops réels de FEU → essence_feu (attendu ~180), level up
	  (niveau 2 + signal), fenêtre inventaire liste non vide, QuestTracker présent,
	  action 0 = Inventaire. **TOUT OK.** Lancement complet `--quit-after 6` : aucun
	  script error ni warning. Piège test : `xp_in_bubble` reboucle par bulles
	  (vérifier `bubbles_filled`, pas `xp_in_bubble`) et les lambdas capturent les
	  locals par valeur (compter via une méthode membre).
- [x] **Session "noms de mobs → UI target + quête"** : le cadre de target
	  affiche le nom du mob et le QuestTracker précise quel mob tuer.
	  - `mob.gd` : const `MOB_NAMES` (`MobType` → String, ex "Feu (火)",
		"Eau (水)"...) — **kanji réutilisés de `KANJI_DATA` (skill_bar.gd)** pour
	    la cohérence pédagogique (火水±月木金日, thème 曜日). API :
	    `get_display_name()` (instance, lu par l'UI de target) + `mob_name(mob_type)`
	    (statique, utilisable sans instance par la quête).
	  - UI target (`summary_panel.gd` + nouveau nœud `TargetNameLabel` sous
	    `UI/SummaryPanel` dans main.tscn, au-dessus de TargetHealthBar) :
	    `_process()` affiche `target.get_display_name()` + masque le label sans
	    cible (même visibilité que la barre de vie).
	  - `quest_system.gd` : `objective_target_name()` (via `mob.gd::mob_name`,
		preload `MobScript`) + `objective_text()` → "Élimine 5 Eau (水)". Plus
	    AUCUN entier brut de `mob_type` n'est exposé à l'UI.
	  - `quest_tracker.gd::_refresh()` : `_progress_label` = `objective_text()`
		+ " : x / N" (précise le mob à tuer).
	  - Validation headless (autoload temporaire retiré) : display name des 7
	    types (Feu (火)…Soleil (日)), statique sans instance, `objective_text()`
		= "Élimine 5 Eau (水)", label de target rempli ("Feu (火)") puis masqué à
	    la désélection. **TOUT OK.** Lancement complet `--quit-after 6` : aucun
	    script error ni warning. Ni DROP_TABLE, ni scoring kanji, ni formule de
	    dégâts touchés.
- [x] **Session "Tickets 1→11" (brief chef de projet)** — corrections + nouvelles
	  fonctionnalités. Validation headless complète (47 assertions TOUT OK).
	  - **[T1, CRITIQUE] chemin Windows codé en dur** : `menu_root_button.gd:10`
	    préloadait `C:/Users/naomi/.../menu_slot_button.gd` → remplacé par
	    `res://menu_slot_button.gd`. Le projet se lance sur n'importe quelle
	    machine.
	  - **[T2] documentation** : `README.md` et `project_structure.md` décrivaient
	    une arborescence `res://autoload/menu_config.gd` / `res://ui/menu/...`
	    qui n'existe pas (scripts à plat à la racine). Corrigés avec les vrais
	    chemins ; convention de grille documentée (24×11, lignes A→K de haut en
	    bas, colonnes 1→24 **de droite à gauche**) + helpers `MenuLayout`.
	  - **[T3] un seul menu** : suppression de `top_right_menu.gd` (+.uid) et du
	    node `UI/TopRightMenu` (MenuButton/MenuPanel) dans main.tscn, et de
	    `button.gd` (+.uid), **troisième prototype orphelin non référencé** (vérifié
	    par grep). Reste uniquement le menu circulaire déplaçable (`UI/Button`).
	    `draggable_button.gd` (class_name DraggableButton) conservé.
	  - **[T4] `Inventory.remove_item()`** : le docstring promettait "toute la pile
	    si count <= 0" mais rien n'était retiré → désormais count <= 0 retire
	    toute la pile (true si ≥1 exemplaire, false sinon) ; count > 0 inchangé.
	  - **[T5] script fantôme** : le node `UI` (CanvasLayer) portait un
	    `GDScript_kek77` vide (résidu d'éditeur) → retiré (sub_resource + `script=`
	    du node), sans toucher à `GridOverlay` (id `9_kek77`).
	  - **[T6] toggle des fenêtres du menu** : `window_manager.gd` réécrit —
	    re-tap sur le même bouton referme, ouvrir une autre fenêtre ferme la
	    précédente (`_current_action_id`/`_current_window`, `close_current()`).
	    **Couche passée de 20 à 1** pour que le MENU (z10) et le sous-menu (z9,
	    désormais ajouté au CanvasLayer UI) restent au-dessus des fenêtres (z0) —
	    sinon impossible de re-taper un bouton au-dessus d'une fenêtre ouverte.
	    Boutons "Fermer" d'Inventaire/Raccourcis/placeholder → `close_current()`.
	  - **[T7] QuestTracker déplaçable** : le Panel passe en `mouse_filter = STOP`
	    (root Control reste IGNORE), drag de `self` clampé à l'écran (pattern
	    title_bar_drag.gd) ; + `toggle_visible()` pour T8.
	  - **[T8] fenêtre Statistiques** : action `id:1` du menu (placeholder "2") →
	    `"Statistiques"` + scène `res://ui/stats_window.tscn`. Nouveau helper
	    `MenuLayout.rect_from_grid(vp, row_from, row_to, col_from, col_to)` (aile
	    des helpers de grille existants) ; panneau A11→I3 (9×9 cases), coins
	    arrondis, `z_index = 8` (au-dessus des fenêtres d'action z0, sous le MENU
	    z10), **pas d'overlay plein écran** (root IGNORE, seul le panel STOP).
	    Affiche les stats de `PlayerStats` (rafraîchi par signaux) + bouton
	    "Quête" qui toggle le QuestTracker indépendamment.
	  - **[T9] joystick ×1.5** : `RADIUS_BASE` 60→90, `RADIUS_STICK` 32→48,
	    `MAX_OFFSET` 36→54, `WIDTH` 260→390, `HEIGHT` 160→240. `DEAD_ZONE`
	    inchangé (fraction). BUTTON_SIZE/GAP traités au T10 (boutons orbitaux).
	  - **[T10] boutons FACE/STICK orbitaux** : nouveau `res://ui/orbit_button.gd`
	    (`class_name OrbitButton extends DraggableButton`) — drag long projeté sur
	    le cercle de rayon `BUTTON_ORBIT_RADIUS = RADIUS_BASE + 40`, tap = action
	    (signaux `tapped`/`angle_changed`). Projection via transform canvas du
	    parent (Control n'a pas `to_local`/`to_global`). Angles persistés dans
	    `MenuConfig` (`face_angle`/`stick_angle`, section `[joystick]` de
	    `user://menu_config.cfg`) — défauts = positions d'origine.
	  - **[T11] curseur caméra B13** : nouveau `res://ui/look_cursor.gd`
	    (`UI/LookCursor` dans main.tscn) — "manche à balai" STICKY : la poignée
	    ne revient PAS au centre au relâchement, la rotation continue tant que
	    l'écart persiste (vitesse linéaire distance/`HANDLE_TRAVEL` ×
	    `VITESSE_MAX_RAD_PAR_SEC`) ; relâcher dans `SNAPBACK_THRESHOLD` = snapback
	    animé (0.12s) qui remet la vitesse à 0 **sans toucher à l'orientation**.
	    Yaw via `player.gd::rotate_y` (axe du look souris), pitch via
	    `camera_pivot.rotation.x` clampé **±90°** (propre limite, plus large que
	    le look souris 70°). Exposé par `MobileInput.look_vector`/`look_active`,
	    lu chaque frame par player.gd. `MenuLayout.rect_from_grid(vp,"B","B",13,13)`
	    pour la position neutre.
	  - **Question ouverte notée (etat_actuel.md)** : le look souris existant
	    semble avoir le pitch inversé (souris vers le haut → caméra descend, car
	    `pitch = +rotation.x` fait monter la caméra) ; le curseur B13 suit la
	    spec (haut → caméra monte). À trancher en playtest — cf. etat_actuel.md.

## 🚧 En cours
- [ ] _(aucun blocage actif)_

### 🕹️ Session mobile (joystick virtuel) — source de vérité du "côté" (Étape 1)
Identifié AVANT de coder le joystick. Le "côté" du menu circulaire (gauche/droite)
est stocké et exposé UNIQUEMENT par l'autoload `MenuConfig` :
- **Variable** : `MenuConfig.side` (int, `enum Side { RIGHT, LEFT }`, défaut `RIGHT`).
- **Méthode pour le lire** : accès direct `MenuConfig.side` (pas de getter).
- **Méthode pour le changer** : `MenuConfig.set_side(new_side)` — idempotent,
  sauvegarde dans `user://menu_config.cfg` + émet `config_changed`.
- **Signal émis au changement** : `MenuConfig.config_changed`.
- Le menu se repositionne sur ce signal (`menu_root_button.gd::_on_config_changed` →
  `_snap_to_side`).
Toute cette session RÉUTILISE cette source de vérité (le joystick lit
`MenuConfig.side`, appelle `MenuConfig.set_side()` pour basculer, écoute
`config_changed`). AUCUNE seconde source de vérité créée.

## 📋 À faire ensuite (priorité)
1. **Phase 1 — quête, loot, inventaire, XP = précision × vitesse, level up FAITS**
   (session "boucle de jeu minimale"). Objectif Alpha quasi complet : reste le
   premier test réel "est-ce fun ?". Points d'ouverture naturels : affiner la
   quête (plusieurs quêtes, récompenses), meilleure diversité de loot (raretés,
   équipement), prêrequis de niveau.
2. Associer un effet élémentaire aux kanji/mobs (Feu/Terre/Vent/Eau...) — actuellement
   pas de différenciation de puissance entre éléments (uniquement visuelle). La base
   est maintenant assez riche (14 kanji) pour ça. Idem : `_build_candidates()` propose
   un kanji de skill + 2 au hasard — affiner la pertinence "élémentaire" (proposer en
   priorité des kanji du même élément) reste un TODO (commenté dans `skill_bar.gd`).
3. **Macros textuelles (Étape 3 de la session raccourcis, optionnelle)** : champ de
   saisie simple façon chat MMO pour taper `/face` ou `/stick` et déclencher la même
   action. NON implémenté cette session (les raccourcis clavier directs suffisent
   pour l'Alpha). TODO clair : ajouter un LineEdit + parser les commandes `/...`
   qui appellent `Player.face()` / `Player.toggle_stick()` (les fonctions sont déjà
   publiques et prêtes à être réutilisées par les boutons mobiles aussi).
4. Contrôle mobile — joystick + boutons FACE/STICK FAITS. Reste éventuel :
   boutons de skills mobiles (slots 1-4, réutiliser SkillBar), test réel sur
   Android.

---

## 🗂️ Fichiers clés
- `kanji/kanji_draw_popup.gd` / `.tscn` — popup de dessin réutilisable (signaux),
  UI construite en code : carré ancré côté menu (repère GridOverlay B-J/1-9),
  3 références au choix, 3 boutons (Valider/Retour/Effacer), pas d'assombrissement.
- `kanji/stroke_scoring.gd`, `kanji/svg_parser.gd` — modules importés
  (score kanji ; `run_auto_test_all()` pour valider les 14 kanji).
- `kanji/kanji_data/*.svg` — **14 kanji de référence** : `06c34.svg` (水, 4),
  `0571f.svg` (土, 3), `0706b.svg` (火, 4), `098a8.svg` (風, 9), `06728.svg`
  (木, 4), `091d1.svg` (金, 8), `06708.svg` (月, 4), `065e5.svg` (日, 4),
  `05c71.svg` (山, 3), `05ddd.svg` (川, 3), `096f7.svg` (雷, 13), `096e8.svg`
  (雨, 8), `068ee.svg` (森, 12), `082b1.svg` (花, 7). Source KanjiVG.
- `skill_bar.gd` — `KANJI_DATA` (14 skills élémentaires) + `use_slot()` branché
  sur le popup + `_build_candidates()` (kanji du skill + 2 au hasard) +
  formule dégâts/score.
- `HexagonalGround.gd` — terrain : grille de tuiles hexagonales colorées par
  FastNoiseLite (roche/terre/herbe), collision + murs.
- `mob.gd` / `mob.tscn` — mob paramétré par `mob_type` (7 types 曜日, modèles en
  primitives low-poly). `MOB_NAMES` (`MobType` → "Feu (火)"...), `get_display_name()`
  (instance) + `mob_name(mob_type)` (statique). `main.tscn` — 21 instances (3 par type).
- `autoload/keybind_config.gd` — autoload KeybindConfig : actions face/stick,
  touches par défaut C/V, `user://keybinds.cfg`.
- `autoload/mobile_input.gd` — autoload MobileInput : `move_vector` (input
  tactile) lu par player.gd, écrit par le joystick ; `look_vector`/`look_active`
  écrits par le curseur caméra (look_cursor.gd).
- `ui/keybind_window.gd` / `.tscn` — fenêtre de réassignement des touches
  (ouverte via le menu circulaire, action id=5 "Raccourcis").
- `ui/virtual_joystick.gd` / `.tscn` — joystick virtuel mobile (×1.5 : base 90,
  stick 48, offset max 54) + boutons FACE/STICK orbitaux (OrbitButton), posé à
  l'opposé du menu (synchro croisée).
- `ui/orbit_button.gd` — `class_name OrbitButton extends DraggableButton` :
  bouton contraint à un cercle (projection sur l'orbite pendant le drag),
  angle persisté via `MenuConfig.set_face_angle()`/`set_stick_angle()`.
- `ui/look_cursor.gd` — curseur caméra B13 "manche à balai" (sticky, snapback,
  vitesse linéaire) → `MobileInput.look_vector`, lu par player.gd.
- `ui/stats_window.gd` / `.tscn` — fenêtre Statistiques (grille A11→I3,
  z_index 8, bouton "Quête" → `QuestTracker.toggle_visible()`).
- `window_manager.gd` — autoload WindowManager : fenêtres d'action en **couche
  canvas 1** + toggle (re-tap ferme, nouvelle ouverture remplace),
  `close_current()` appelé par les boutons "Fermer".
- `menu_layout.gd` — helpers de grille (class_name MenuLayout) : `rect_from_right`,
  **`rect_from_grid(vp, "A", "I", 3, 11)`** (lignes par lettre + colonnes 1→24
  depuis la droite), miroir, rects menu/slots.
- `autoload/inventory.gd` — autoload Inventory : inventaire minimal (liste),
  `ITEM_DEFS` (7 items 曜日), add/remove/get_count (`remove_item` retire toute
  la pile si count <= 0), signal `inventory_changed`.
- `autoload/quest_system.gd` — autoload QuestSystem : quête "élimine 5 Eau",
  `on_mob_killed(mob_type)`, récompenses (XP + items), relance automatique.
  `objective_text()` → "Élimine 5 Eau (水)" (nom via `mob.gd::mob_name`, plus
  d'int brut exposé à l'UI).
- `ui/quest_tracker.gd` — panneau de progression de quête (UI/QuestTracker dans
  main.tscn), affiche `objective_text()` + " : x / N". **Déplaçable** (Panel
  STOP, drag de `self`) + `toggle_visible()` (bouton "Quête" des Statistiques).
- `ui/inventory_window.gd` / `.tscn` — fenêtre Inventaire (liste colorée par
  rareté), ouverte via le menu circulaire (action id=0 "Inventaire").
- `summary_panel.gd` — UI du cadre de target : `TargetNameLabel` (nom du mob,
  `get_display_name()`) au-dessus de `TargetHealthBar`, masqués sans cible.
- `player.gd` — `face()`, `toggle_stick()`/`_process_stick()` (état `sticking`),
  combinaison input clavier + `MobileInput.move_vector` + look curseur B13
  (`MobileInput.look_vector` → yaw joueur / pitch `camera_pivot`, clamp ±90°).
- `CREDITS.md` — attribution KanjiVG (licence CC BY-SA 3.0).
- `World_of_Japan_Roadmap.md` — feuille de route (Phase 0 cochée partiellement).
- _Supprimés (session tickets 1→11)_ : `top_right_menu.gd` (+.uid) — ancien menu
  "Petit Menu" ; `button.gd` (+.uid) — prototype orphelin non référencé.

## ⚠️ Décisions / contraintes à ne pas oublier
- **Temps réel pendant le dessin** : le monde ne se met PLUS en pause. Le mob
  continue d'attaquer ; la vitesse devient un facteur de score. Le popup tourne
  en mode normal (pas de `process_mode` spécial). Choix de design assumé : le
  joueur est laissé sous pression, il doit dessiner vite et juste.
- **PAR_TIME_MS par kanji** (clé `par_time_ms` du skill, via `KANJI_DATA` dans
  `skill_bar.gd`) : 水=3000, 土=2000, 火=2800, 風=5500. Temps "parfait" de dessin.
- **4 skills Alpha** (slots 1-4, `KANJI_DATA`) : Frappe Eau/Terre/Feu/Vent.
  Pas de différenciation de puissance — seul le kanji change. Slots 5-9 vides.
- **SVG = format KanjiVG 1.0** (voir section "Format des SVG" ci-dessous) :
  1 `<path>` par trait, ordre = ordre de dessin, `d=` C/S/Q/T/L/Z, repère
  109×109. Les 4 fichiers proviennent de KanjiVG (CC BY-SA 3.0, `CREDITS.md`).
- **Formule dégâts** : base 2-6 (aléatoire) × précision × vitesse, arrondi, min 1
  si score ≥ 40. Détails paliers dans `skill_bar.gd` / PROGRESS ci-dessus.
- **Scoring importé tel quel** : normalisation globale par côté, comparaison ordonnée,
  `DISTANCE_TO_SCORE_FACTOR = 2.2`, verdict ≥ 60. Ne pas revenir à une normalisation
  par trait. Ne pas descendre sous 2.0. **Non touché lors de la session mobs/terrain**.
- **Un seul popup à la fois** : `_active_popup` dans `skill_bar.gd` refuse un 2e dessin
  si un est déjà ouvert.
- **Mort pendant le dessin** : `PlayerStats.player_died` → popup fermé comme un
  `drawing_cancelled`, aucune action, `_active_popup` libéré. Le mob peut frapper
  tant que le joueur vit (le popup reste ouvert et utilisable).
- **Souris pendant le dessin** : forcée `MOUSE_MODE_VISIBLE` à l'ouverture,
  restaurée à la fermeture (close() et _exit_tree pour les fermetures forcées).
- **`--check-only --script skill_bar.gd` seul échoue** : `TargetSystem`/`PlayerStats`
  sont des autoloads, non résolus hors contexte de jeu (faux positif). Vérifier via
  lancement headless du jeu, ou via un autoload temporaire.
- **Terrain — noise-based per-tile color** (choix de session) : grille de tuiles
  hexagonales, chaque tuile = 1 `StandardMaterial3D` coloré par `FastNoiseLite`.
  Pour un rendu "zones naturelles" (pas un dégradé continu), préférer des paliers
  de couleurs (roche/terre/herbe) plutôt qu'un `lerp` lisse sur tout l'intervalle.
  Ajuster `noise_frequency`/`noise_seed`/`hex_size` (exports) si besoin.
- **Mobs — un seul template paramétré** (choix de session) : `mob.gd` construit le
  modèle en primitives selon `mob_type`. Ajouter un type = ajouter un `_build_*` +
  une entrée enum + le placement dans `main.tscn`. Pas de 7 scènes séparées.
- **Commandes de combat = états/méthodes de `player.gd`** (choix de session) :
  `face()` et `toggle_stick()` sont publiques et appelables par script — c'est
  volontaire pour la réutilisation future par les boutons mobiles et les macros
  texte. Ne pas recréer de logique de déplacement dupliquée ailleurs.
- **Touches par défaut FACE/STICK = C / V** (défaut, réassignables via
  KeybindConfig → `user://keybinds.cfg`) : vérifiées libres face aux touches
  déjà utilisées (flèches, A/Z, T/Y/U/I/O, 1-9, Ctrl, NumLock). Toujours vérifier
  les conflits avant d'ajouter une nouvelle touche en dur.
- **STICK : portée = `MELEE_RANGE = 1.5`** en dur dans `player.gd` (même valeur
  que `mob.gd: melee_range`). Si la portée de mêlée des mobs change un jour,
  penser à synchroniser les deux.
- **Macros texte (/face, /stick) NON implémentées** (étape 3 optionnelle) — voir
  "À faire ensuite" pour le TODO. Les raccourcis clavier directs suffisent pour
  l'Alpha.
- **Source de vérité du "côté" = `MenuConfig.side` SEULE** (identifié étape 1 de
  la session joystick) : variable `side` (enum `Side { RIGHT, LEFT }`),
  `set_side()` pour changer (sauvegarde + émet `config_changed`), signal
  `config_changed` pour écouter. Le menu ET le joystick s'y branchent. Ne pas
  créer de second champ "side" ailleurs (ex: joystick doit TOUJOURS lire
  `MenuConfig.side`, jamais sa propre variable de côté persistée).
- **Synchro croisée menu/joystick** (mécanisme) : le joystick est à
  `_opposite_side()` de `MenuConfig.side`. Drag joystick qui franchit la moitié
  d'écran → `MenuConfig.set_side(_opposite(released_side))` (même API que le
  drag du menu, pas de logique dupliquée) + flag `_ignore_next_config` pour ne
  pas se re-positionner soi-même. Drag du menu → `config_changed` → le joystick
  bascule automatiquement. Les deux restent TOUJOURS opposés.
- **Joystick : pas de position fine persistante** (choix étape 4.4) : la position
  est recalculée à chaque bascule/redimensionnement (côté opposé au menu, bas de
  l'écran). Le drag libre est temporaire. Si un jour on veut une position fine
  persistante, l'ajouter dans un `user://mobile_ui.cfg` (nouveau) et la relier à
  la synchro croisée (miroir lors d'un basculement de côté).
- **Input mobile combiné, pas remplacé** : `player.gd` ADDITIONNE
  `MobileInput.move_vector` à l'input clavier puis normalise. Le mapping écran →
  monde : `x` (écran) → axe X (strafe), `y` (écran, bas=+) → `z` (avant = -z) ;
  `mv.y < -0.5` = pousser vers l'avant (active le multiplicateur de vitesse).
- TODO Phase 1 laissé en commentaire : XP finale = produit précision × vitesse du
  combat (score moyen des kanji utilisés).
- **Joystick : dead zone 12% de MAX_OFFSET + reset au centre** (choix de session) :
  `_reset_stick()` remet stick visuel au centre exact + `move_vector=ZERO` +
  `active=false` au relâchement ET au passage en mode drag. `DEAD_ZONE = 0.12`
  garde `move_vector` à ZERO tant que le doigt est dans ~4.3px du centre.
  `player.gd` ne lit l'input mobile que si `MobileInput.active` (garde double).
- **Écran de dessin : géométrie en repère GridOverlay** (choix de session) :
  le carré de dessin suit `MenuConfig.side` (MÊME côté que le menu) avec
  `MenuLayout.rect_from_right(vp, Vector2i(1,9), Vector2i(1,9))` (lignes B-J,
  colonnes 1-9). Ne PAS dupliquer ce calcul ailleurs — utiliser `_draw_square_rect()`
  du popup ou `MenuLayout` directement. La racine du popup est en
  `MOUSE_FILTER_IGNORE` : monde + joystick restent interactifs pendant le dessin.
- **3 références au choix + scoring contre le kanji sélectionné** : le popup
  reçoit `open(candidates)` (3 dicts `{"svg","par_time_ms","name"}`), le joueur
  clique la référence à dessiner. `par_time_ms` suit la sélection (le temps
  imparti dépend du kanji réellement dessiné). Premier candidat = kanji du skill.
- **Undo unitaire (Retour)** : retire UN trait (`player_strokes` + son `Line2D`
  via `_stroke_lines` parallèle). Ne touche jamais la référence. Ne fait rien si
  vide. Effacer = reset complet de la pile.
- **Base kanji : 14 kanji, par_time_ms extrapolé** (choix de session) : ~base
  700 + ~500-550 ms/trait (cohérent avec les 4 valeurs d'origine). Ajouter un
  kanji = SVG KanjiVG dans `kanji/kanji_data/` + vérifier le codepoint
  (`kvg:element`) + `--import` + entrée `KANJI_DATA` + ligne dans
  `run_auto_test_all()` + `CREDITS.md`. Constantes de scoring intactes.
- **XP du kill = 50 × (précision × vitesse) moyen du combat** (session Phase 1) :
  `skill_bar.gd` accumule `_combat_multipliers` (1 par kanji dessiné,
  `_performance_multiplier`, échec <40 = 0), `mob.gd::die()` lit `xp_multiplier()`
  (1.0 si aucun kanji) puis `reset_combat()`. Ne pas dupliquer les paliers
  (dégâts et XP partagent `_performance_multiplier`).
- **Loot = DROP_TABLE dans mob.gd + fiches dans Inventory.ITEM_DEFS** (choix de
  session, données avant code) : 1 ligne par type de mob (`MobType` → item_id +
  chance), 1 seul lancer par mort. Ajouter un loot = 2 modifs de données, pas de
  logique. Rareté = info d'affichage (pas de stats d'équipement pour l'Alpha).
- **Quête = fiche dans QuestSystem.QUESTS** (choix de session) : objectif
  `kill_mobs{mob_type, count}` (valeurs `MobType` de mob.gd, hardcodées en ints
  avec commentaires — pas de class_name partagé), récompenses XP + items.
  La quête **recommence automatiquement** à la complétion (boucle Alpha).
  `mob.gd` appelle `on_mob_killed` ; l'UI QuestTracker écoute les signaux.
- **Feedback level up** : `PlayerStats.leveled_up(level)` émis dans `add_xp` ;
  bannière "Niveau X !" construite en code par `summary_panel.gd`, ajoutée au
  CanvasLayer UI **en `call_deferred`** (add_child direct pendant le _ready de
  main.tscn → erreur "Parent node is busy").
- **Fenêtre Inventaire dans le menu** : action id=0 de `MenuConfig.actions`
  (placeholder "1") remplacée par "Inventaire". L'id d'action ne bouge pas
  (référence stable pour slot_actions) ; les autres placeholders inchangés.

## 🔗 Dépendances / éléments externes
- Godot 4.7.1 : `C:\Program Files (x86)\Godot\Godot_v4.7.1-stable_win64_console.exe`.
- **Terminal Windows — affichage des kanji en console** (investigué le 21/08) :
  les caractères japonais sortent en échappement/s’affichent mal parce que le
  terminal Windows est en codepage **850 (DOS Western European)** au lieu de
  l’UTF-8. C’est un réglage d’environnement, pas un bug des scripts (les
  `print()` du projet sortent bien de l’UTF-8 — vérifié). Avant toute session :
  lancer `chcp 65001` (et `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`
  dans PowerShell) pour que 水/火/土/風/etc. s’affichent correctement.
- Push GitHub : `$env:GCM_INTERACTIVE="Never"; git -c credential.username=yurisshop63 push origin main`
  (crédentials Windows — sinon push bloqué).
- Création du repo (gh non installé) :
  `gh repo create world-of-japan --public --source . --remote origin --push` ou
  créer manuellement puis `git remote add origin https://github.com/yurisshop63/world-of-japan.git`.

---

## 🧭 Pour reprendre cette session
Projet Godot dans `jeu-mmorpg-japanese-learning-ARCHIVE/` (le dossier EST le projet).
Tester : lancer la scène `main.tscn` headless (`--headless --path . --quit-after 5`) —
pas d'erreur attendue au démarrage (terrain + 21 mobs + joueur). Le scoring se vérifie
via `StrokeScoring.run_auto_test_all()` (attendu : parfait 100, aléatoire faible,
humain imprécis 65-89, sur les 14 kanji). Compiler un script avec
`--check-only --script <fichier.gd>` (piège : échoue sur les autoloads hors contexte
de jeu). Pour tester le popup : instancier `res://kanji/kanji_draw_popup.tscn` puis
`open(candidates)` avec une liste de dicts `{"svg","par_time_ms","name"}`. Pour tester
les mobs : instancier `mob.tscn`, régler `mob_type`, appeler `take_damage()`. Pour
tester les commandes : `Player.face()`, `Player.toggle_stick()` (avec
`TargetSystem.select(mob)` au préalable). Fenêtre raccourcis : ouvrir le menu
circulaire (bouton MENU) puis l'action "Raccourcis", ou appeler
`WindowManager.open_action(5)`. Joystick : présent dans `main.tscn` (enfant UI),
utiliser la souris pour le stick ; dead zone 12% + reset au centre au relâchement ;
`MobileInput.move_vector` est lu par player.gd (garde `active`). Écran de dessin :
le carré suit le côté du menu (bascule avec lui), 3 références cliquables en haut
du côté opposé, boutons Valider/Retour/Effacer en bas, Annuler (ESC) en haut-droite.
**Quête/loot/inventaire (Phase 1)** : la quête active "Élimine 5 Eau" est affichée
par `UI/QuestTracker` (sous MacroBar) ; tuer 5 mobs Eau → +300 XP + 1 Pépite d'Or
puis relance. Les mobs droppent selon `mob.DROP_TABLE` (essences/raretés) →
`Inventory` (lire via la fenêtre "Inventaire" du menu circulaire, action 0).
XP du kill = 50 × moyenne des précision×vitesse du combat. Level up → bannière
centrée "Niveau X !". Tests rapides : `Inventory.add_item/remove_item`,
`QuestSystem.on_mob_killed(mob_type)`, `SkillBar._performance_multiplier(...)`.
Pour la console : lancer `chcp 65001` avant (sinon kanji mal affichés, codepage 850).

---

## 📐 Format des SVG de référence (KanjiVG) — IMPORTANT
Chaque fichier `kanji/kanji_data/<hex>.svg` est un SVG KanjiVG **1.0** (licence
CC BY-SA 3.0, copyright Ulrich Apel, en-tête présent dans le fichier) :
- `<svg width=109 height=109 viewBox="0 0 109 109">`, style de groupe racine
  `fill:none;stroke:#000000;stroke-width:3`.
- Un `<g kvg:element="X">` contient UN `<path>` PAR TRAIT (ordre de dessin =
  ordre des traits, `id="kvg:<hex>-s<N>"`).
- Chaque trait est un seul `d="..."` de commandes **cubiques/quadratiques**
  (`M`, `C`, `S`, `Q`, `T`, `L`, `Z`) ; le parseur (`SvgParser`) extrait tous
  les `d=` de tous les `<path>` (regex `d="..."`), échantillonne les Bézier
  (17 pts/cubique, 13 pts/quad) en une polyligne par trait.
- Pas de `transform` par trait (les coordonnées sont déjà dans le repère 109×109).
- `SvgParser` ignore les `<text>` (numéros de traits) et les attributs `kvg:*`.
