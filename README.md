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

- Solo clavier/souris **ou** duel 2 manettes (pas de 2 joueurs clavier)
- Stance spéciale type Helldivers (Ctrl/LB + combo + confirm)
- Techniques : sphère (↑↓←→) / mur défensif (↑↑)
- Munitions kunai/shuriken ramassables
- Viseur discret (arc + flèche)


## Assets

Mannequin **Zegley** (CC BY 4.0) — voir `CREDITS.md`.  
Sources brutes : `assets/zegley/source/`  
Copies gameplay : `game/assets/player/`

## Suite prévue

Parchemin explosif, marche sur l'eau, online hôte, Capture the Flag, skins habillés.
