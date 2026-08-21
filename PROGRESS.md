# PROGRESS.md

> Fichier d'état du projet — mis à jour par l'agent (DeepSeek/OpenCode) à la fin de chaque session de travail.
> Objectif : qu'une nouvelle session (ou un autre worker) puisse reprendre sans que l'humain ait à tout réexpliquer.

**Dernière mise à jour :** 2026-08-21
**Dernier commit poussé :** `d51b232`

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

## 🚧 En cours
- [ ] _(aucun blocage actif)_

## 📋 À faire ensuite (priorité)
1. Phase 1 : quête simple, loot, inventaire, XP = précision × vitesse moyen du combat
   (TODO laissé en commentaire dans `skill_bar.gd`).
2. Associer un effet élémentaire aux kanji/mobs (Feu/Terre/Vent/Eau) — actuellement
   pas de différenciation de puissance entre éléments (uniquement visuelle).
3. **Macros textuelles (Étape 3 de la session raccourcis, optionnelle)** : champ de
   saisie simple façon chat MMO pour taper `/face` ou `/stick` et déclencher la même
   action. NON implémenté cette session (les raccourcis clavier directs suffisent
   pour l'Alpha). TODO clair : ajouter un LineEdit + parser les commandes `/...`
   qui appellent `Player.face()` / `Player.toggle_stick()` (les fonctions sont déjà
   publiques et prêtes à être réutilisées par les boutons mobiles aussi).
4. Contrôle mobile (joystick + boutons) — session séparée prévue : réutiliser
   `face()`, `toggle_stick()` et `KeybindConfig` pour les boutons à l'écran.

---

## 🗂️ Fichiers clés
- `kanji/kanji_draw_popup.gd` / `.tscn` — popup de dessin réutilisable (signaux).
- `kanji/stroke_scoring.gd`, `kanji/svg_parser.gd` — modules importés
  (score kanji ; `run_auto_test_all()` pour valider les 4 kanji).
- `kanji/kanji_data/*.svg` — 4 kanji de référence : `06c34.svg` (水, 4 traits),
  `0571f.svg` (土, 3), `0706b.svg` (火, 4), `098a8.svg` (風, 9). Source KanjiVG.
- `skill_bar.gd` — `KANJI_DATA` (4 skills élémentaires) + `use_slot()` branché
  sur le popup + formule dégâts/score.
- `HexagonalGround.gd` — terrain : grille de tuiles hexagonales colorées par
  FastNoiseLite (roche/terre/herbe), collision + murs.
- `mob.gd` / `mob.tscn` — mob paramétré par `mob_type` (7 types 曜日, modèles en
  primitives low-poly). `main.tscn` — 21 instances (3 par type).
- `autoload/keybind_config.gd` — autoload KeybindConfig : actions face/stick,
  touches par défaut C/V, `user://keybinds.cfg`.
- `ui/keybind_window.gd` / `.tscn` — fenêtre de réassignement des touches
  (ouverte via le menu circulaire, action id=5 "Raccourcis").
- `player.gd` — `face()`, `toggle_stick()`/`_process_stick()` (état `sticking`).
- `CREDITS.md` — attribution KanjiVG (licence CC BY-SA 3.0).
- `World_of_Japan_Roadmap.md` — feuille de route (Phase 0 cochée partiellement).

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
- TODO Phase 1 laissé en commentaire : XP finale = produit précision × vitesse du
  combat (score moyen des kanji utilisés).

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
via `StrokeScoring.run_auto_test()` (attendu : parfait 100, aléatoire ~0-15, humain
imprécis 65-85). Compiler un script avec `--check-only --script <fichier.gd>`
(piège : échoue sur les autoloads hors contexte de jeu). Pour tester le popup :
instancier `res://kanji/kanji_draw_popup.tscn` puis `open()`. Pour tester les mobs :
instancier `mob.tscn`, régler `mob_type`, appeler `take_damage()`. Pour tester les
commandes : `Player.face()`, `Player.toggle_stick()` (avec `TargetSystem.select(mob)`
au préalable). Fenêtre raccourcis : ouvrir le menu circulaire (bouton MENU) puis
l'action "Raccourcis", ou appeler `WindowManager.open_action(5)`. Pour la console :
lancer `chcp 65001` avant (sinon kanji mal affichés, codepage 850).

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
