# World of Japan — Feuille de route & Architecture de projet

## 0. Règles d'or (à relire à chaque fois que tu es perdu)

1. **Systèmes avant contenu.** Tu ne crées jamais "un mob" ou "un donjon" à la main. Tu crées d'abord la *règle* qui permet d'en générer des centaines.
2. **Données avant code/asset.** Chaque élément du jeu (perso, mob, item, skill, kanji) doit d'abord exister comme une fiche de données (tableau/JSON), pas comme un dessin ou une fonction.
3. **Templates avant instances.** Une "famille" = un template avec des paramètres. Une instance = le template + des valeurs (niveau, zone...).
4. **Un nœud de cet arbre = une conversation Claude.** Jamais deux sujets dans la même fenêtre.
5. **Tu ne codes/dessines JAMAIS avant que la fiche de données correspondante soit validée.**

---

## 1. Arborescence complète du projet

```
WORLD OF JAPAN
│
├── 00_VISION
│   ├── Pitch / fantasme du jeu (1 page)
│   ├── Piliers de gameplay (3-5 max)
│   └── Références (DAoC + quoi d'autre, et pourquoi)
│
├── 01_PERSONNAGE
│   ├── Races (liste + bonus/malus)
│   ├── Familles/Rôles (Tank / Support / Distance) + sous-archétypes
│   ├── Statistiques de base (STR, DEX, INT, etc. — à toi de nommer)
│   ├── Progression
│   │   ├── Courbe d'XP (paliers, niveau max)
│   │   ├── Courbe de RP (Realm Points, façon DAoC)
│   │   └── Courbe de Kanji (niveau de maîtrise du dessin)
│   └── Création de personnage (règles, pas encore l'UI)
│
├── 02_COMBAT & COMPÉTENCES
│   ├── Boucle de combat générale (comment une action se résout)
│   ├── Realm Abilities (façon DAoC)
│   ├── Compétences de spécialité (par archétype)
│   ├── Compétences magiques
│   └── SYSTÈME KANJI (voir section 4 du présent doc — c'est LE système central)
│
├── 03_ÉQUIPEMENT & LOOT
│   ├── Slots d'équipement
│   ├── Stats & paliers d'objets (commun/rare/épique/légendaire...)
│   ├── Prérequis (niveau/stat pour équiper)
│   ├── Tables de drop (taux par rareté, par type de mob)
│   └── Génération procédurale d'items (affixes + valeurs par palier)
│
├── 04_BESTIAIRE (MOBS)
│   ├── Familles élémentaires (Feu, Eau, Vent, Terre, Foudre, Bois...)
│   │   └── Matrice de résistances/faiblesses (voir section 3)
│   ├── Familles comportementales (indépendantes de l'élément)
│   │   ├── Passif / Neutre
│   │   ├── Agressif (distance de aggro X)
│   │   ├── Social (appelle à l'aide, linké à un groupe)
│   │   └── Patrouille / statique / fuyard
│   ├── Paliers de niveau (1-5, 6-10, 11-15... jusqu'au cap)
│   ├── Templates de stats par palier (HP, dégâts, résistances scalés)
│   ├── Sons/cris (voir 06_AUDIO)
│   └── Règles de spawn (voir 05_MONDE)
│
├── 05_MONDE / DONJONS
│   ├── Découpage des zones (overland, donjons, capitales...)
│   ├── Système de "spots" de spawn (zones nommées dans une map)
│   ├── Règles de peuplement automatique
│   │   (ex: "remplis ce donjon avec X% agressif distance, Y% neutre couloir,
│   │    niveaux dégressifs vers le fond, boss au fond")
│   └── Générateur de donjon (commande unique → placement auto des mobs)
│
├── 06_AUDIO
│   ├── Table état/action du personnage → son
│   ├── Table famille de mob → cris/bruits
│   ├── Musique par zone / par état de combat
│   └── Système de déclenchement (quel événement joue quel son)
│
├── 07_VISUEL / VFX
│   ├── Charte artistique (style, palette, référence visuelle)
│   ├── Effets de skills (par élément, par kanji)
│   ├── Animations liées aux familles de mobs
│   └── UI graphique du dessin de kanji
│
├── 08_UI/UX
│   ├── Hors-jeu (écran complet, souris/clavier)
│   │   ├── Création de personnage
│   │   ├── Fiche de stats / XP / RP / Kanji
│   │   ├── Inventaire (paperdoll + grille)
│   │   ├── Fenêtres de compétences (RA / spécialité / magie)
│   │   └── Fenêtre de groupe
│   └── In-game (mobile/overlay, compact)
│       ├── Barres de vie/mana/endurance
│       ├── Macros + raccourcis
│       └── Popup de dessin de kanji (le plus critique en UX)
│
└── 09_TECH / OUTILS DE PROD
	├── Choix moteur (Unity / Godot / autre) — décision à prendre tôt
	├── Format des données (JSON/CSV/Excel) pour perso/mob/item/skill
	├── Générateurs (scripts qui lisent les templates et créent le contenu)
	└── Pipeline (comment une fiche de donnée devient un objet en jeu)
```

---

## 2. Ordre de travail recommandé (les phases)

Tu ne dois **jamais** faire de l'UI ou de l'art avant que la donnée derrière existe. Voici l'ordre logique :

| Phase | Contenu | Pourquoi maintenant |
|---|---|---|
| **A. Vision** | 00_VISION complet | Sans ça, chaque décision suivante sera remise en question |
| **B. Squelette de données** | 01, 02, 03, 04 — uniquement les **règles et formules**, aucun contenu final | C'est le cœur du jeu, tout en dépend |
| **C. Choix technique** | 09_TECH | Une fois que tu sais QUOI stocker, tu choisis COMMENT (moteur, format) |
| **D. Prototype vertical** | 1 perso, 1 famille de mob, 1 sort kanji, 1 mini-zone, UI minimale | Tu dois VALIDER que le kanji-drawing est fun avant de construire 200 sorts autour |
| **E. Générateurs** | Scripts de génération de mobs/items/donjons à partir des templates | C'est ce qui va te faire gagner 90% du temps ensuite |
| **F. Contenu à l'échelle** | Remplissage massif via les générateurs (bestiaire, donjons, loot) | Rapide une fois D et E faits |
| **G. Audio/Visuel** | 06, 07 | Vient enrichir un système qui fonctionne déjà, pas l'inverse |
| **H. UI complète & polish** | 08 en entier | En dernier, sur une base de gameplay déjà stable |

**Règle pratique pour toi :** une session de travail (4-6h) = **une seule case** de ce tableau, jamais deux.

---

## 3. Comment tout rendre scalable (mobs, donjons, items)

### 3.1 Le principe : Famille = Template + Paramètres

Une **famille de mob** n'est pas un mob, c'est une fonction :

```
Famille "Feu" = {
  éléments: { faible: [eau, froid, étouffement], neutre: [terre, électricité], résistant: [bois, feu, vent] },
  comportement_par_défaut: agressif_courte_distance,
  palette_sons: "feu_grognement_01-05",
  courbe_stats: (niveau) => { hp: niveau*40, dégâts: niveau*3, ... }
}
```

Une **instance** = Famille "Feu" + niveau 12 + variante "Braise" → générée automatiquement, jamais créée à la main.

### 3.2 Exemple concret : matrice élémentaire

| Élément mob | Faible à | Neutre à | Résistant à |
|---|---|---|---|
| Feu | Eau, Froid, Étouffement | Terre, Électricité | Bois, Feu, Vent |
| Eau | Électricité, Froid extrême | Feu léger | Eau, Terre |
| Vent | Terre, Feu | Eau | Vent, Foudre |

→ Une seule matrice comme celle-ci, remplie une fois, gouverne **tous** les mobs de toutes les familles, à tous les niveaux. Tu ne la retouches jamais mob par mob.

### 3.3 Sous-variantes automatiques d'une famille

Au lieu de créer "étincelle, bougie, feu de paille, braise, feu de bois, incendie, balrog" un par un, tu définis une **table de paliers** :

| Palier niveau | Nom auto-généré | Multiplicateur stats | Tag spécial |
|---|---|---|---|
| 1-5 | Étincelle | x1 | — |
| 6-10 | Bougie | x2 | — |
| 11-15 | Feu de paille | x3.5 | — |
| 16-20 | Braise | x5 | résiste +10% |
| 21-30 | Feu de bois | x8 | — |
| 31-40 | Incendie | x13 | aggro zone |
| 51-55+ | Balrog (boss) | x40 | unique, comportement spécial |

Une commande de génération ("crée la famille Feu niveaux 1 à 55") applique automatiquement cette table + la matrice élémentaire + le comportement par défaut. **Zéro travail manuel par mob.**

### 3.4 Peuplement de donjon = une commande

Une fois 3.1-3.3 en place, ta phrase :

> "Dans le donjon X, mets des agressifs distance en early, neutres dans les couloirs, mixe niveau 35-45, boss lvl 51-55+ au fond"

devient littéralement une **commande de génération** que tu donnes à un script (ou à Claude dans une session dédiée aux donjons), avec des règles de répartition (% par zone, dégressif/progressif par profondeur). Tu ne places plus jamais un mob à la main.

### 3.5 Items : même logique

Un item n'est pas créé, il est **tiré** : `Type d'objet + Palier de rareté + Niveau requis → stats générées par formule + affixes aléatoires piochés dans une table`. Tu configures les formules et les tables une fois, tu génères ensuite des centaines d'objets sans y toucher.

---

## 4. Le système Kanji (le cœur unique de ton jeu)

C'est ton mécanisme le plus original — il mérite sa propre conversation dédiée (`02b_Systeme_Kanji`), mais voici l'ossature :

1. **Déclenchement** : macro/sort → popup de dessin s'ouvre (pause ou temps réel selon ton choix de difficulté).
2. **Modèle de référence** : chaque kanji/sort a un tracé de référence (ordre des traits, direction, forme).
3. **Scoring** : comparaison forme + vitesse + précision de traits → score de 0 à 100%.
4. **Effet en jeu** : score → probabilité de coup critique / puissance de l'effet / réussite ou échec total en dessous d'un seuil.
5. **Portée sémantique** : un même effet (ex: "étouffer un feu") peut être obtenu par plusieurs kanji différents (couverture, pot, brouette) — donc chaque kanji doit être tagué avec l'**effet** qu'il produit, pas l'inverse. Ça te permet d'ajouter des kanji sans retoucher le système d'effets.
6. **Progression** : plus le joueur maîtrise un kanji (répétitions réussies), plus son "niveau de kanji" augmente → débloque tracés plus complexes / bonus de vitesse.

**Point clé de scalabilité** : construis d'abord *un* kanji fonctionnel de bout en bout (reconnaissance + effet en combat) avant d'en dessiner 50. C'est ta phase D (prototype vertical).

---

## 5. Comment organiser tes conversations Claude

### 5.1 Convention de nommage des chats dans le Projet

Utilise systématiquement le numéro de l'arborescence en préfixe, ex :
- `01 - Personnage - Races et stats`
- `02b - Combat - Systeme Kanji`
- `04 - Bestiaire - Familles elementaires`
- `04a - Bestiaire - Famille Feu (paliers)`
- `05 - Monde - Generateur de donjon`

### 5.2 Project Instructions (à coller dans les paramètres du Projet)

```
Projet : World of Japan, MMORPG solo-dev façon DAoC avec système de combat 
basé sur le dessin de kanji.
Je travaille par modules (voir arborescence dans la knowledge base).
Dans chaque conversation, je ne travaille QUE sur le sujet annoncé dans le titre.
Priorise toujours : règles/données d'abord, UI/art ensuite.
Sois concis, propose des tableaux de données structurées (JSON ou markdown),
pas de prose inutile.
```

### 5.3 Le "Master Index"

Crée UN document (à uploader et remettre à jour dans la Knowledge Base) qui liste, pour chaque nœud de l'arborescence : statut (☐ à faire / 🔶 en cours / ✅ fait) + un résumé de 2-3 lignes des décisions prises. À chaque fin de session, tu mets à jour ce fichier. C'est ta mémoire persistante entre les fenêtres.

---

## 6. Estimation de temps réaliste

Il faut être honnête : tu es en train de spécifier un MMORPG complet, seul, avec des IA gratuites limitées en tokens. C'est un projet qu'une équipe de plusieurs personnes met généralement 2-4 ans à sortir, même en réutilisant beaucoup d'outils existants. Voici une estimation par phase, à raison de 4-6h/jour :

| Phase | Temps estimé | Remarque |
|---|---|---|
| A. Vision | 5-10h | Rapide si tu es clair sur tes envies |
| B. Squelette de données (systèmes) | 80-150h (~4-6 semaines) | La partie la plus intellectuellement dense, mais 100% faisable seul avec l'IA |
| C. Choix technique | 10-20h | Décision + prise en main de base du moteur |
| D. Prototype vertical (1 perso, 1 mob, 1 kanji, mini-UI) | 150-300h (~6-12 semaines) | Ici tu codes/assembles vraiment, pas que du texte — l'IA aide mais tu dois exécuter, tester, corriger |
| E. Générateurs de contenu | 100-200h | Gros levier de scalabilité, rentabilisé ensuite |
| F. Contenu à l'échelle (bestiaire, donjons, loot) | 200-400h | Rapide par mob grâce aux générateurs, mais volume important |
| G. Audio/Visuel (recherche, intégration, pas la création d'assets eux-mêmes) | 150-300h+ | Dépend énormément si tu crées les assets toi-même ou pas |
| H. UI complète & polish | 200-400h | Toujours plus long que prévu |

**Total ordre de grandeur pour un jeu "complet" jouable en solo avec IA limitée : entre 900 et 1800h**, soit, à 5h/jour en moyenne (25h/semaine) : **environ 36 à 72 semaines de travail effectif, donc réalistement 1,5 à 3 ans** en tenant compte des pauses, imprévus, et de l'apprentissage technique en cours de route.

**Ce chiffre ne compte pas** la création d'assets graphiques/sonores originaux si tu ne les fais pas toi-même ou via IA générative — ça peut doubler le temps.

**Conseil concret** : ne vise pas "le MMO complet" comme premier objectif. Vise la phase D (prototype vertical) comme ton vrai jalon à 2-3 mois. Si ce prototype est fun, tu sais que le concept marche et tu scales avec confiance (phases E-H). Si ce n'est pas fun, tu as économisé 1000h en le découvrant tôt.

---

## 7. Ta toute première session (à faire maintenant)

1. Ouvre une conversation `00 - Vision` dans le Projet.
2. Écris en 1 page : le pitch, les 3-5 piliers de gameplay, pourquoi le kanji est central.
3. Valide/fige ce document (c'est ta boussole pour tout le reste).
4. Session suivante : `01 - Personnage - Races et Familles` — et RIEN d'autre ce jour-là.




# ROADMAP — World of Japan (nom provisoire)

> Fichier consultable dans le dock FileSystem de Godot. À ouvrir en tout premier
> avant de reprendre une session de travail (humain ou agent OpenCode/DeepSeek).
> Coche les cases au fur et à mesure. Ne supprime jamais l'historique des
> phases déjà faites (contrairement à `etat_actuel.md`, qui lui est un
> scratchpad remplacé à chaque session).

## 🎯 Objectif Alpha (jalon unique — pas de MMORPG complet pour l'instant)

Une boucle jouable minimale : 1 perso, 1 zone, quelques mobs, 1 quête, un
loot simple, XP/niveau — et surtout : **le tracé de kanji doit influencer le
combat** (dégâts, vitesse, XP). Le but est de juger si c'est fun avant
d'investir dans le contenu à l'échelle.

---

## 📸 État constaté (diagnostic du 21/08)

**Projet A — `jeu-mmorpg-japanese-learning-ARCHIVE`** (Godot 4.7, 3D)
- ✅ Joueur 3D (déplacement, caméra souris, animation de marche)
- ✅ Mob avec IA (idle → chase → attaque → return → respawn, leash) + 7 types
      élémentaires 曜日 (火水±月木金日) en primitives low-poly
- ✅ Terrain procédural (tuiles hex FastNoiseLite, roche/terre/herbe) + murs
- ✅ Système de cible (clic = raycast + sélection)
- ✅ `SkillBar` (9 slots, kanji 水/土/火/風, dégâts précision × vitesse) + `MacroBar` UI
- ✅ `PlayerStats` (vie, mana, XP par bulles façon DAoC, XP PvP séparée)
- ✅ Menu circulaire complet, déplaçable, sauvegardé
- ✅ Contrôle mobile de base : joystick virtuel + boutons FACE/STICK,
      synchro croisée avec le menu (opposés en permanence)
- ❌ Pas de quête, pas de loot, pas d'inventaire
- ⚠️ Pas de dépôt git détecté dans l'archive — à confirmer/créer

**Projet B — `kanji-game`** (Godot 4.7, dépôt git déjà poussé sur GitHub)
- ✅ Dessin souris → parsing SVG (`SvgParser`) → scoring 0-100 (`StrokeScoring`)
- ✅ Scoring validé par tests automatisés (parfait=100, aléatoire≈0, imprécis=70-97)
- ✅ Feedback visuel (flash couleur selon score)
- ✅ 4 kanji intégrés au combat (水土火風, popup temps réel)
- ❌ Scène isolée `test_trace.tscn` conservée comme référence — l'Alpha vit dans le
	  projet A (fusion faite en Phase 0)

---

## Phase 0 — Fusion technique (prochaine étape immédiate)
- [x] Décider du dépôt hôte GitHub (fusion en un seul repo)
- [x] Importer `stroke_scoring.gd`, `svg_parser.gd`, `kanji_data/` dans le
	  projet mmorpg (sous `res://kanji/`)
- [x] Créer une scène popup `KanjiDraw` réutilisable (généraliser
	  `test_trace.gd`, qui est aujourd'hui figé sur 水)
- [x] Brancher `SkillBar.use_slot()` : au lieu de dégâts fixes aléatoires,
      ouvrir le popup kanji, récupérer le score, en déduire dégâts/vitesse/XP
      (formule combinée précision × vitesse implémentée — voir section formule)
- [x] Ajouter 2-3 kanji supplémentaires (SVG + effet associé + `par_time_ms`)
      pour sortir du cas unique et valider que le système généralise — **fait** :
      土 (0571f.svg, 3 traits), 火 (0706b.svg, 4), 風 (098a8.svg, 9) depuis
      KanjiVG (CC BY-SA), skills slots 1-4 équipés, scoring validé (parfait=100
      sur les 4)

## Phase 1 — Boucle de jeu minimale (Alpha)
- [x] Diversité visuelle du monde (pré-requis jugement "fun") — **fait** :
      terrain procédural (tuiles hexagonales FastNoiseLite, roche/terre/herbe)
      + 7 types de mobs élémentaires thème 曜日 (火水±月木金日) en primitives
      low-poly, 21 instances réparties sur le terrain
- [x] Commandes de combat façon DAoC — **fait** : `/face` (orienter vers la
      cible) et `/stick` (suivre la cible en gardant la portée de mêlée),
      touches par défaut **C** / **V**, réassignables via la fenêtre Raccourcis
      du menu (KeybindConfig, `user://keybinds.cfg`). Macros texte `/...` tapées
      en chat : TODO (étape 3 optionnelle, non prioritaire)
- [ ] Quête ultra simple ("élimine 5 Mob X" ou "récupère 3 items Y")
- [ ] Loot basique (drop d'item au décès du mob, probabilité simple)
- [ ] Inventaire minimal (liste, pas de grille sophistiquée)
- [ ] Formule dégâts/XP liée au score kanji — **dégâts fait** (précision × vitesse),
	  **XP restant** (précision × vitesse moyen du combat, TODO commenté)
- [ ] Feedback de level up visible (le système de bulles existe déjà)

## Phase 2 — Test utilisateur / confort
- [x] Contrôle mobile de base — **fait** : joystick virtuel de déplacement
      (`ui/virtual_joystick.gd/.tscn`) + boutons FACE/STICK, autoload
      MobileInput, positionné à l'opposé du menu circulaire avec synchronisation
      croisée (menu ↔ joystick toujours opposés, drag du joystick pour le
      repositionner + basculer le menu). Test réel Android : reste à faire.
- [ ] Boutons de skills mobiles (slots 1-4) à l'écran (réutiliser SkillBar)
- [ ] Onboarding minimal (comment dessiner, comment viser)
- [ ] Ajustement de la difficulté du scoring (seuil de réussite, tolérance)
- [ ] Export buildable (Android ou Web selon préférence) pour tester hors éditeur

## Phase 3+ — hors scope immédiat, après validation de l'Alpha
Bestiaire élargi, familles élémentaires, donjons, contenu à l'échelle, UI
polish… → voir `World_of_Japan_Roadmap.md` pour la vision long terme
(volontairement mise de côté tant que l'Alpha n'est pas validée fun).

---

## 🎲 Formule proposée : score kanji → combat (précision × vitesse, temps réel)

Le monde ne se met **plus** en pause pendant le dessin : le mob continue
d'attaquer. La vitesse de réalisation devient un second facteur de score, en
plus de la précision. Dégâts = base (2-6) × précision × vitesse, arrondi, min 1.

| Facteur | Paliers | Multiplicateur |
|---|---|---|
| **Précision** (score) | < 40 | Échec : 0 dégât |
| | 40–70 | ×1.0 (base) |
| | 70–90 | ×1.5 |
| | > 90 | ×2.0 (coup critique) |
| **Vitesse** (elapsed vs PAR_TIME_MS du kanji) | ≤ 0.6 × par | ×1.3 (très rapide) |
| | ≤ par | ×1.0 (parfait) |
| | ≤ 1.5 × par | ×0.8 (lent) |
| | > 1.5 × par | ×0.6 (très lent) |

`PAR_TIME_MS = 3000` pour 水 (exporté sur la popup, surchargeable par skill via
`skill.get("par_time_ms")`). La popup affiche un chrono ("Temps : X.Xs") pour
que le joueur sente la pression.

L'XP gagnée à la mort du mob (Phase 1) sera multipliée par le produit
précision × vitesse **moyen** des kanji utilisés durant ce combat (récompense la
rapidité ET la précision). TODO laissé en commentaire dans `skill_bar.gd`.

---

## Convention de suivi
- Ce fichier = vue d'ensemble, mis à jour à chaque fin de phase.
- Le détail session par session reste dans `PROGRESS.md` (règles définies
  dans `AGENTS.md` du repo kanji-game — à réappliquer telles quelles une fois
  les repos fusionnés).
- Avant chaque session : lire `ROADMAP.md` puis `PROGRESS.md`.
