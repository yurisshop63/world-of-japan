# PROGRESS.md

> Fichier d'état du projet — mis à jour par l'agent (DeepSeek/OpenCode) à la fin de chaque session de travail.
> Objectif : qu'une nouvelle session (ou un autre worker) puisse reprendre sans que l'humain ait à tout réexpliquer.

**Dernière mise à jour :** 2026-08-21
**Dernier commit poussé :** (en attente du push — voir blocage ci-dessous)

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
      de tour. Pause du monde pendant le dessin (`get_tree().paused`), rendu 3D
      toujours visible derrière. Blocage d'un 2e dessin simultané.
- [x] **Validation headless** (Godot 4.7.1) :
      `--import` OK (cache `class_name` rafraîchi : StrokeScoring + SvgParser).
      Auto-test de scoring OK (parfait 100, aléatoire ~0-15, imprécis 65-85).
      Popup instanciée en headless : invisible par défaut, `open()` → visible avec
      4 traits de référence (水). Jeu complet lancé `--quit-after 5` : aucun
      script error.

## 🚧 En cours
- [ ] **Push sur main** — bloqué : `gh` CLI non installé, pas de token GitHub, repo
      distant `world-of-japan` non encore créé sur GitHub.

## 📋 À faire ensuite (priorité)
1. Créer le repo GitHub `world-of-japan` (owner yurisshop63) puis `git push -u origin main`.
2. Ajouter 2-3 kanji supplémentaires (SVG + effet associé) pour sortir du cas unique 水.
3. Phase 1 : quête simple, loot, inventaire, formule XP liée au score (TODO laissé en
   commentaire dans `skill_bar.gd`).

---

## 🗂️ Fichiers clés
- `kanji/kanji_draw_popup.gd` / `.tscn` — popup de dessin réutilisable (signaux).
- `kanji/stroke_scoring.gd`, `kanji/svg_parser.gd` — modules importés (non modifiés
  sauf le chemin SVG dans `run_auto_test()`).
- `kanji/kanji_data/06c34.svg` — kanji de référence (水, 4 traits).
- `skill_bar.gd` — `use_slot()` branché sur le popup + formule dégâts/score.
- `World_of_Japan_Roadmap.md` — feuille de route (Phase 0 cochée partiellement).

## ⚠️ Décisions / contraintes à ne pas oublier
- **Pause pendant le dessin** : le monde est mis en pause (`get_tree().paused = true`)
  pendant que le popup est ouvert ; le popup tourne en `process_mode = WHEN_PAUSED`.
  Choix Alpha : plus simple et évite que le mob tue le joueur pendant qu'il dessine.
  À reconsidérer pour un "temps réel" en difficulté avancée (ROADMAP §4).
- **Scoring importé tel quel** : normalisation globale par côté, comparaison ordonnée,
  `DISTANCE_TO_SCORE_FACTOR = 2.2`, verdict ≥ 60. Ne pas revenir à une normalisation
  par trait. Ne pas descendre sous 2.0.
- **Un seul popup à la fois** : `_active_popup` dans `skill_bar.gd` refuse un 2e dessin
  si un est déjà ouvert.
- **`--check-only --script skill_bar.gd` seul échoue** : `TargetSystem` est un autoload,
  non résolu hors contexte de jeu (faux positif). Vérifier via lancement headless du jeu.
- Tous les skills utilisent 水 (`DEFAULT_KANJI_SVG`) — la clé `kanji` du skill est prévue
  pour étendre plus tard.
- TODO Phase 1 laissé en commentaire : XP multipliée par le score moyen du combat.

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
instancier `res://kanji/kanji_draw_popup.tscn` puis `open()`.
