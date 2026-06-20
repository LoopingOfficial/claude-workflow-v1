# Commandes Claude Code — Référence des workflows

## Commandes disponibles

| Commande | Fichier | Usage |
|----------|---------|-------|
| `/audit` | `.claude/commands/audit.md` | Analyse l'état réel du projet sans rien modifier → `specs/audit.md` |
| `/spec` | `.claude/commands/spec.md` | Interview une question à la fois → `specs/projet.md` |
| `/build` | `.claude/commands/build.md` | Implémente + valide (syntaxe, imports, tests complets, critères) |
| `/review` | `.claude/commands/review.md` | Audit complet → score /100 → `/build` si < 95 |

> ⚠️ `/test` et `/architect` sont retirés du workflow quotidien.
> — `/test` est intégré directement dans `/build` (étape 4.5).
> — `/architect` est réservé aux gros modules structurants uniquement (voir ci-dessous).

---

## Workflow standard — nouvelle fonctionnalité

```
/audit → /spec → /build → /review
```

À utiliser pour : toute fonctionnalité nouvelle sur un projet existant.

1. `/audit` — photographie l'état réel avant de toucher quoi que ce soit
2. `/spec` — formalise exactement ce qu'on veut construire
3. `/build` — construit + valide syntaxe/imports/tests/critères (tests intégrés)
4. `/review` — audit complet sécurité/perf/maintenabilité, score /100, boucle jusqu'à ✅

---

## Workflow correctif — petit fix

```
/audit → /build → /review
```

À utiliser pour : correction de bug, ajustement mineur, refactoring ciblé.

- `/spec` n'est pas nécessaire si le problème est clairement identifié par `/audit`
- `/build` reçoit les corrections issues de `specs/audit.md` directement

---

## Workflow structurant — gros module complexe uniquement

```
/audit → /spec → /architect → /build → /review
```

À utiliser **uniquement** quand : nouveau module majeur, refactoring architectural, composant avec de nombreuses dépendances, ou risque élevé de dette structurelle.

- `/architect` n'est justifié que si les décisions d'architecture ont un impact durable sur l'ensemble du projet
- `specs/architecture.md` devient contraignant pour `/build` et est vérifié par `/review`

---

## Fichiers produits par les commandes

| Fichier | Produit par | Consommé par |
|---------|-------------|--------------|
| `specs/audit.md` | `/audit` | `/build`, `/review` |
| `specs/projet.md` | `/spec` | `/build`, `/review` |
| `specs/architecture.md` | `/architect` | `/build`, `/review` |
| `specs/test-report.md` | `/build` (étape 4.5) | `/review` |
| `specs/review.md` | `/review` (étape 11) | `/build`, `/audit`, `/review` |

> **`specs/review.md`** est le fichier d'état de la boucle qualité. Il porte :
> - le **compteur de passes** (`Passe courante : N`) — incrémenté à chaque review, jamais réinitialisé ;
> - l'**état de la boucle qualité** (score de la dernière passe, validé ou non) ;
> - les **corrections en cours** (avec leur ID, leur sévérité et leur statut) ;
> - l'**historique des reviews** (une ligne par passe, en append).
>
> Il est écrit par `/review`, puis relu par `/build` (pour traiter les corrections), par `/audit` (pour vérifier quelles corrections sont résolues, encore ouvertes ou obsolètes) et par `/review` lui-même (pour récupérer le compteur de passes). Il n'est jamais édité à la main.

---

## Règle de décision : `/architect` ou pas ?

Utilise `/architect` si au moins deux de ces conditions sont vraies :
- Le module aura plus de 5 fichiers interdépendants
- D'autres parties du projet en dépendront
- La structure choisie sera difficile à changer plus tard
- La spec mentionne des contraintes de performance ou de sécurité non triviales

Dans tous les autres cas : `/audit → /spec → /build → /review` suffit.

---

## Installation

```bash
# Dans un projet spécifique
mkdir -p .claude/commands
cp audit.md spec.md build.md review.md .claude/commands/

# Global (tous les projets)
mkdir -p ~/.claude/commands
cp audit.md spec.md build.md review.md ~/.claude/commands/
```

> Note : `test.md` et `architect.md` ne sont pas copiés dans les commandes actives.
> `architect.md` est disponible séparément pour les cas qui le justifient.
