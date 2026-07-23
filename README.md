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

## Contenu v1

- 1 arène (sol, plateformes, murs)
- Combat mêlée : coup (jab) / katana
- Kunai, roll, substitution latérale + bout de bois
- Spéciale mudras → **boule de feu** (Katon)
- Chakra (coûts + régénération)
- HUD vie / chakra / mudras
- Manette : P1 pad0 / P2 pad1

## Assets

Mannequin **Zegley** (CC BY 4.0) — voir `CREDITS.md`.  
Sources brutes : `assets/zegley/source/`  
Copies gameplay : `game/assets/player/`

## Suite prévue

Parchemin explosif, marche sur l'eau, online hôte, Capture the Flag, skins habillés.
