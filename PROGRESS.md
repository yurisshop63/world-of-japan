# PROGRESS.md

> Fichier d'état du projet — mis à jour par l'agent (DeepSeek/OpenCode) à la fin de chaque session de travail.
> Objectif : qu'une nouvelle session (ou un autre worker) puisse reprendre sans que l'humain ait à tout réexpliquer.

**Dernière mise à jour :** 2026-08-21
**Dernier commit poussé :** `6dbb3db`

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

## 🚧 En cours
- [ ] _(aucun blocage actif)_

## 📋 À faire ensuite (priorité)
1. Ajouter 2-3 kanji supplémentaires (SVG + effet associé + `par_time_ms` par kanji)
   pour sortir du cas unique 水.
2. Phase 1 : quête simple, loot, inventaire, XP = précision × vitesse moyen du combat
   (TODO laissé en commentaire dans `skill_bar.gd`).

---

## 🗂️ Fichiers clés
- `kanji/kanji_draw_popup.gd` / `.tscn` — popup de dessin réutilisable (signaux).
- `kanji/stroke_scoring.gd`, `kanji/svg_parser.gd` — modules importés (non modifiés
  sauf le chemin SVG dans `run_auto_test()`).
- `kanji/kanji_data/06c34.svg` — kanji de référence (水, 4 traits).
- `skill_bar.gd` — `use_slot()` branché sur le popup + formule dégâts/score.
- `World_of_Japan_Roadmap.md` — feuille de route (Phase 0 cochée partiellement).

## ⚠️ Décisions / contraintes à ne pas oublier
- **Temps réel pendant le dessin** : le monde ne se met PLUS en pause. Le mob
  continue d'attaquer ; la vitesse devient un facteur de score. Le popup tourne
  en mode normal (pas de `process_mode` spécial). Choix de design assumé : le
  joueur est laissé sous pression, il doit dessiner vite et juste.
- **PAR_TIME_MS = 3000** pour 水 (exporté `par_time_ms` sur le popup, surchargeable
  par skill via `skill.get("par_time_ms")`). Ajuster kanji par kanji.
- **Formule dégâts** : base 2-6 (aléatoire) × précision × vitesse, arrondi, min 1
  si score ≥ 40. Détails paliers dans `skill_bar.gd` / PROGRESS ci-dessus.
- **Scoring importé tel quel** : normalisation globale par côté, comparaison ordonnée,
  `DISTANCE_TO_SCORE_FACTOR = 2.2`, verdict ≥ 60. Ne pas revenir à une normalisation
  par trait. Ne pas descendre sous 2.0.
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
- Tous les skills utilisent 水 (`DEFAULT_KANJI_SVG`) — la clé `kanji` du skill est prévue
  pour étendre plus tard.
- TODO Phase 1 laissé en commentaire : XP finale = produit précision × vitesse du
  combat (score moyen des kanji utilisés).

## 🔗 Dépendances / éléments externes
- Godot 4.7.1 : `C:\Program Files (x86)\Godot\Godot_v4.7.1-stable_win64_console.exe`.
- Push GitHub : `$env:GCM_INTERACTIVE="Never"; git -c credential.username=yurisshop63 push origin main`
  (crédentials Windows — sinon push bloqué).
- Création du repo (gh non installé) :
  `gh repo create world-of-japan --public --source . --remote origin --push` ou
  créer manuellement puis `git remote add origin https://github.com/yurisshop63/world-of-japan.git`.

---

## 🧭 Pour reprendre cette session
Projet Godot dans `jeu-mmorpg-japanese-learning-ARCHIVE/` (le dossier EST le projet).
Tester : lancer la scène `main.tscn` headless (`--headless --path . --quit-after 5`) —
pas d'erreur attendue au démarrage. Le scoring se vérifie via
`StrokeScoring.run_auto_test()` (attendu : parfait 100, aléatoire ~0-15, humain
imprécis 65-85). Compiler un script avec `--check-only --script <fichier.gd>`
(piège : échoue sur les autoloads hors contexte de jeu). Pour tester le popup :
instancier `res://kanji/kanji_draw_popup.tscn` puis `open()`. Pour tester la
formule combinée en contexte réel : ajouter un autoload temporaire qui appelle
`SkillBar._compute_damage(score, elapsed_ms, par_time_ms)`, puis le retirer.
