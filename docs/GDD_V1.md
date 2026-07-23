# GDD — Ninja Arena v1

## Vision

Duel d'arène side-view, rythme **souls-like** (télégraphes, punition), fantasy **ninja** (chakra, mudras, substitution).

## Scope v1 (ce prototype)

- Local 1v1 uniquement
- 1 arène horizontale
- 1 mannequin (Zegley), teintes P1/P2
- Actions : move, jump, light, heavy, kunai, roll, substitute (téléport **court latéral**), 1 spéciale (↑↓←→ puis bouton)
- Ressource : chakra
- Victoire : KO (PV à 0), restart R

## Hors v1

- Capture the Flag
- Online
- Parchemin explosif
- Marche sur l'eau
- Roster / skins finalisés

## Valeurs de départ (tuning)

| Élément | Valeur |
|---------|--------|
| PV | 100 |
| Chakra | 100, regen ~8/s |
| Light | 10 dmg, startup court |
| Heavy | 22 dmg, startup long |
| Spéciale | 36 dmg, coût 40 |
| Kunai | 8 dmg, coût 12 |
| Roll | i-frames ~0.22s, coût 8 |
| Sub | 56 px latéral, coût 22, i-frames courte |

## Mudra

Recette spéciale v1 : `up, down, left, right` puis touche spéciale sous 3 s.
