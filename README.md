# Ninja Arena — Prototype v1

Duel d'arène 2D local (souls-like + techniques ninja).  
Moteur : **Godot 4.3+** — ouvrir le dossier `game/`.

## Lancer

1. Installer [Godot 4.3+](https://godotengine.org/download)
2. Importer le projet `game/project.godot`
3. F5 / Play (scène `scenes/arena.tscn`)

## Contrôles

| Action | Joueur 1 | Joueur 2 |
|--------|----------|----------|
| Déplacer | A / D | ← / → |
| Mudra (directions) | W S A D | Flèches |
| Saut | Espace | Ctrl |
| Attaque légère | J | Z |
| Attaque lourde | K | X |
| Kunai | L | C |
| Roll (i-frames) | Shift | Numpad 0 |
| Substitution (téléport latéral court) | I | V |
| Spéciale | U (après ↑ ↓ ← →) | B |
| Restart | R | R |

Spéciale : enchaîner **haut, bas, gauche, droite**, puis la touche spéciale dans les **3 secondes** (coût chakra).

## Modes

- **0 manette** → solo **clavier / souris**
- **1 manette** → solo **manette**
- **2 manettes** → duel (P1 + P2)
- Pas de 2 joueurs sur le même clavier


## Assets

Mannequin **Zegley** (CC BY 4.0) — voir `CREDITS.md`.  
Sources brutes : `assets/zegley/source/`  
Copies gameplay : `game/assets/player/`

## Suite prévue

Parchemin explosif, marche sur l'eau, online hôte, Capture the Flag, skins habillés.
