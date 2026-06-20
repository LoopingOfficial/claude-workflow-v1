# Claude Code Workflow — v1 Stable

Un système de commandes (slash-commands) pour Claude Code qui structure le développement en quatre étapes traçables : **auditer → spécifier → construire → relire**. Chaque commande communique avec les autres uniquement via des fichiers `specs/`, ce qui rend le travail reprenable, vérifiable et difficile à valider à tort.

Ce dépôt est un **conteneur de sauvegarde et de réutilisation** de la version figée `v1.0.0`. Il n'est pas destiné à évoluer de façon spéculative : toute amélioration future doit être motivée par un problème réel rencontré sur un projet concret.

---

## Commandes disponibles

| Commande | Rôle | Produit |
|----------|------|---------|
| `/audit` | Photographie l'état réel du projet en lecture seule (structure, dépendances, schéma/migrations, routes, conformité spec, cohérence architecture, état des corrections de review). Ne modifie rien. | `specs/audit.md` |
| `/spec` | Interview de cadrage, une question à la fois, puis formalise le besoin. Aucun code. | `specs/projet.md` |
| `/build` | Construit exactement ce qui est prévu. Checkpoint Git préalable, garde-fous sécurité bloquants, validation à trois états (✅ réussi / ❌ échoué / ⏭️ non exécuté) après chaque fichier. | `specs/test-report.md` + le code |
| `/review` | Audit complet (conformité, sécurité, régression, performance, responsive, maintenabilité), score /100, couverture, compteur de passes persistant. Reboucle vers `/build` sous 95. | `specs/review.md` |
| `/architect` | *(avancé)* Compare plusieurs architectures, en choisit une, fixe les contraintes structurantes. Réservé aux gros modules. | `specs/architecture.md` |

### Flux des fichiers

| Fichier | Produit par | Consommé par |
|---------|-------------|--------------|
| `specs/projet.md` | `/spec` | `/build`, `/review`, `/audit`, `/architect` |
| `specs/audit.md` | `/audit` | `/build`, `/review`, `/architect` |
| `specs/architecture.md` | `/architect` | `/build`, `/review`, `/audit` |
| `specs/test-report.md` | `/build` | `/review` |
| `specs/review.md` | `/review` | `/build`, `/audit`, `/review` |

---

## Workflow principal

```
/audit → /spec → /build → /review
```

À utiliser pour toute fonctionnalité nouvelle sur un projet existant.

1. `/audit` — photographie l'état réel avant de toucher quoi que ce soit.
2. `/spec` — formalise exactement ce qu'on veut construire.
3. `/build` — construit + valide (syntaxe, imports, tests, critères), avec checkpoint Git.
4. `/review` — audit complet, score /100, boucle jusqu'à validation.

**Variante correctif** (bug ou ajustement ciblé clairement identifié par l'audit) :

```
/audit → /build → /review
```

---

## Workflow avancé

```
/audit → /spec → /architect → /build → /review
```

À réserver aux **gros modules structurants** : nouveau module majeur, refactoring architectural, composant à fortes dépendances, ou risque élevé de dette structurelle. `specs/architecture.md` devient alors contraignant pour `/build` et vérifié par `/audit` et `/review`.

Règle de décision : utiliser `/architect` si au moins deux de ces conditions sont vraies — plus de 5 fichiers interdépendants, d'autres parties du projet en dépendront, la structure sera difficile à changer plus tard, la spec mentionne des contraintes de performance ou de sécurité non triviales. Dans le doute, ne pas l'utiliser.

---

## Installation

Les commandes se déposent dans le dossier `.claude/commands/` lu par Claude Code.

**Pour un projet spécifique** (commandes disponibles dans ce projet uniquement) :

```bash
# Depuis la racine de votre projet
mkdir -p .claude/commands
cp /chemin/vers/claude-workflow-v1/.claude/commands/*.md .claude/commands/
```

**En global** (commandes disponibles dans tous les projets) :

```bash
mkdir -p ~/.claude/commands
cp /chemin/vers/claude-workflow-v1/.claude/commands/*.md ~/.claude/commands/
```

Les cinq commandes (`audit`, `spec`, `build`, `review`, `architect`) sont copiées. `/architect` reste réservé à l'usage avancé décrit ci-dessus ; il ne fait pas partie du workflow quotidien.

Vérification rapide après installation : ouvrez Claude Code dans le projet et tapez `/audit` — la commande doit être proposée.

---

## Mise à jour

Ce dépôt est figé en `v1.0.0`. Pour récupérer cette version de référence ou la réappliquer :

```bash
# Récupérer la version figée
git clone /chemin/vers/claude-workflow-v1
cd claude-workflow-v1
git checkout v1.0.0

# Réinstaller les commandes dans un projet
cp .claude/commands/*.md /chemin/vers/projet/.claude/commands/
```

Pour mettre à jour un projet déjà équipé, écrasez simplement les fichiers de `.claude/commands/` par ceux de la version voulue. Les fichiers `specs/` de votre projet ne sont pas touchés par cette opération.

> Politique d'évolution : aucune modification spéculative. Une nouvelle version (`v1.1.0`, etc.) ne sera créée que pour répondre à un problème réel observé en usage, documenté dans `CHANGELOG.md`.

---

## Exemple d'utilisation

Ajouter une fonctionnalité « export CSV des commandes » à une application existante :

```
1. /audit
   → Claude cartographie le projet, repère les modèles et routes existants,
     et écrit specs/audit.md. Aucun fichier du projet n'est modifié
     (contrôle git status en clôture).

2. /spec
   → Claude pose les questions une à une (objectif, format du CSV, cas limites,
     critères de succès…), confirme sa compréhension, puis écrit specs/projet.md.

3. /build
   → Claude crée d'abord un checkpoint Git (commit ou stash nommé),
     annonce son plan, implémente l'export, teste après chaque fichier,
     applique les garde-fous sécurité, puis écrit specs/test-report.md.
     Le récapitulatif indique comment annuler le build et si /audit doit être relancé.

4. /review
   → Claude audite le code, calcule un score /100 et la couverture,
     incrémente le compteur de passes dans specs/review.md.
     Si le score est ≥ 95 et toutes les conditions remplies → validé.
     Sinon, les corrections sont transmises à /build et la boucle reprend
     (blocage humain si un problème récurre sur 2 passes, arrêt à 5 passes).
```

En cas de build problématique, le checkpoint Git permet un retour arrière immédiat :

```bash
git reset --hard <SHA-du-checkpoint>   # ou : git stash pop
```

---

_Claude Code Workflow v1 Stable — référence officielle figée. Voir `CHANGELOG.md` pour le détail de la version._
