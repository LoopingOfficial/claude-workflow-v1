# Analyse la spec et l'audit. Propose plusieurs architectures. Sélectionne la meilleure. Écrit specs/architecture.md. /build devra s'y conformer.

> ⚠️ **Usage restreint — ne pas utiliser en workflow quotidien.**
> `/architect` est réservé aux gros modules structurants uniquement : nouveau module majeur, refactoring architectural, composant avec de nombreuses dépendances, ou risque élevé de dette structurelle.
>
> **Workflow standard :** `/audit → /spec → /build → /review`
> **Workflow correctif :** `/audit → /build → /review`
> **Workflow structurant (ce workflow) :** `/audit → /spec → /architect → /build → /review`
>
> Si tu n'es pas certain que `/architect` est nécessaire, il ne l'est pas.

## Rôle
Tu es un architecte logiciel senior. Tu ne codes pas — tu conçois. Chaque décision est justifiée, chaque compromis est nommé. Le livrable est `specs/architecture.md`, qui devient la référence obligatoire pour tous les `/build` suivants.

---

## Étape 1 — Lecture et extraction des contraintes

### 1.1 Lecture de specs/projet.md
Lis l'intégralité de `specs/projet.md`.

**Si absent :**
> « Aucune spec trouvée. Lance `/spec` d'abord pour définir le projet. »
> — Stop.

Extrait et note :
- **Type de projet** : web app, API, CLI, service, librairie, mobile…
- **Fonctionnalités requises** : liste complète
- **Cas limites** : contraintes fonctionnelles
- **Critères de complétion** : ce qui définit "terminé"
- **Contraintes techniques déclarées** : stack, dépendances, performances
- **Hors périmètre v1** : ce qui ne sera pas construit maintenant mais devra pouvoir l'être plus tard

### 1.2 Lecture de specs/audit.md
Si `specs/audit.md` existe, lis-le et extrais :
- **Dette technique existante** à ne pas reproduire
- **Incohérences connues** à corriger par l'architecture
- **Risques de régression** identifiés
- **Stack actuelle** si le projet est en cours

Si absent : note « Pas d'audit disponible — projet nouveau ou audit non encore effectué. » et continue.

### 1.3 Inférences architecturales
À partir de la spec, déduis les contraintes implicites :
- Nombre d'utilisateurs attendus (si mentionné) → besoins de scalabilité
- Types de données manipulées → SQL vs NoSQL vs fichiers
- Besoins temps-réel (si mentionnés) → WebSocket vs polling
- Sensibilité des données → niveau de sécurité requis
- Fréquence des mises à jour → couplage vs découplage des modules

---

## Étape 2 — Proposition de 3 architectures candidates

Pour chaque architecture, présente une vue complète et honnête.

### Format de chaque architecture candidate :

```
## Architecture [N] — [Nom court / Pattern]
_Ex : "Monolithe MVC", "API REST + SPA", "Microservices", "Serverless", "Modulaire hexagonale"_

### Principe
[2-3 phrases : philosophie générale et pourquoi ce pattern existe]

### Structure des couches
[Description des couches et de leurs responsabilités]

### Stack recommandée
- Backend : [...]
- Frontend : [...] ou N/A
- Base de données : [...]
- Infrastructure : [...]

### Flux principal
[Description du flux de données pour la fonctionnalité centrale du projet]

### Forces
- [Force 1 — avec lien direct à un besoin de la spec]
- [Force 2]
- ...

### Faiblesses
- [Faiblesse 1 — avec impact concret sur le projet]
- [Faiblesse 2]
- ...

### Inadaptations spécifiques à CE projet
- [Ce que cette architecture gère mal par rapport aux besoins identifiés]
```

---

## Étape 3 — Matrice de comparaison

Compare les 3 architectures sur 5 dimensions. Chaque note est sur 10 avec justification.

```
## Matrice de comparaison

| Dimension | Architecture 1 | Architecture 2 | Architecture 3 |
|-----------|---------------|---------------|---------------|
| Maintenabilité | [N]/10 | [N]/10 | [N]/10 |
| Sécurité | [N]/10 | [N]/10 | [N]/10 |
| Performance | [N]/10 | [N]/10 | [N]/10 |
| Évolutivité | [N]/10 | [N]/10 | [N]/10 |
| Coût de développement | [N]/10 | [N]/10 | [N]/10 |
| **Total** | **[N]/50** | **[N]/50** | **[N]/50** |
```

### Grille de notation — ce que chaque dimension évalue :

**Maintenabilité**
- 9-10 : séparation claire des responsabilités, chaque module modifiable indépendamment, conventions explicites
- 6-8 : quelques couplages mais gérables, conventions implicites mais cohérentes
- 3-5 : couplages forts, modifications risquées, onboarding difficile
- 1-2 : code spaghetti structurel, dette garantie

**Sécurité**
- 9-10 : isolation des couches, authentification centralisée, surface d'attaque minimale, secrets externalisés
- 6-8 : sécurité présente mais quelques points d'entrée à surveiller
- 3-5 : sécurité à implémenter manuellement sur chaque endpoint, risque d'oubli
- 1-2 : architecture qui expose structurellement des données sensibles

**Performance**
- 9-10 : adapté à la charge prévue, pas de goulot d'étranglement structurel, caching possible
- 6-8 : performant dans les cas normaux, quelques ajustements nécessaires à l'échelle
- 3-5 : limitations connues qui deviendront problématiques à volume réel
- 1-2 : architecture inadaptée à la charge prévue dès le départ

**Évolutivité**
- 9-10 : les fonctionnalités "hors périmètre v1" s'ajoutent sans refactoring majeur
- 6-8 : évolutions possibles avec refactoring modéré
- 3-5 : évolutions nécessitent des changements architecturaux importants
- 1-2 : toute évolution majeure nécessite une réécriture

**Coût de développement**
- 9-10 : rapide à mettre en place, peu de boilerplate, équipe opérationnelle vite
- 6-8 : setup modéré, quelques abstractions à construire
- 3-5 : setup significatif avant la première fonctionnalité utile
- 1-2 : complexité accidentelle élevée, temps de setup majeur

### Justifications par dimension
Pour chaque note, une phrase de justification spécifique au projet :

```
### Justifications Architecture 1
- Maintenabilité [N]/10 : [raison spécifique au projet]
- Sécurité [N]/10 : [raison]
- Performance [N]/10 : [raison]
- Évolutivité [N]/10 : [raison — lien avec le hors-périmètre v1]
- Coût dev [N]/10 : [raison]

### Justifications Architecture 2
[...]

### Justifications Architecture 3
[...]
```

---

## Étape 4 — Sélection et décision

```
## Architecture retenue : Architecture [N] — [Nom]

### Raison principale
[1-2 phrases : pourquoi cette architecture gagne sur les autres pour CE projet spécifique]

### Compromis acceptés
- [Ce qu'on sacrifie et pourquoi c'est acceptable]
- [...]

### Hypothèses critiques
- [Ce qui doit être vrai pour que cette architecture reste valide]
- [Ex : "Moins de 10 000 utilisateurs en v1", "Pas de temps-réel nécessaire", etc.]
- Si une hypothèse est invalidée, relancer /architect.
```

---

## Étape 5 — Rédaction de specs/architecture.md

Crée `specs/` si absent. Écris `specs/architecture.md` :

```markdown
# Architecture — [Nom du projet]
_Générée le [date]. Référence obligatoire pour /build. Ne pas modifier sans relancer /architect._

## Décision architecturale
**Pattern retenu :** [Nom]
**Raison :** [justification principale]
**Alternatives considérées :** [Architecture 2] (écarté : [raison]) — [Architecture 3] (écarté : [raison])

---

## 1. Structure des dossiers

```
[nom-du-projet]/
├── [dossier]/
│   ├── [sous-dossier]/     # [rôle]
│   └── [fichier.ext]       # [rôle]
├── [dossier]/
│   └── ...
└── [fichier de config]     # [rôle]
```

### Règles de structure
- [Règle 1 : ex "Les routes ne doivent jamais accéder directement à la base de données"]
- [Règle 2 : ex "Toute logique métier vit dans services/, jamais dans les controllers"]
- [Règle 3]
- ...

---

## 2. Modèles de données

### [Modèle 1]
```
[NomModèle]
├── id            : [type] — clé primaire
├── [champ]       : [type] — [contrainte] — [raison]
├── [champ]       : [type] — [contrainte]
├── created_at    : timestamp
└── updated_at    : timestamp
```
Relations :
- [NomModèle] a plusieurs [AutreModèle] via [champ clé étrangère]
- [...]

### [Modèle 2]
[...]

### Schéma de relations
```
[NomModèle] ──< [AutreModèle]   (one-to-many)
[NomModèle] >──< [AutreModèle]  (many-to-many via [TableJonction])
[NomModèle] ──║ [AutreModèle]   (one-to-one)
```

### Décisions sur les données
- [Décision 1 : ex "Soft delete sur [Modèle] — raison"]
- [Décision 2 : ex "Index sur [champ] de [Modèle] — raison de performance"]
- [...]

---

## 3. APIs et interfaces

### Convention générale
- Format : [REST / GraphQL / tRPC / autre]
- Authentification : [JWT / Session / OAuth / autre] — appliquée sur [quelles routes]
- Versioning : [ex "/api/v1/..." ou "aucun en v1"]
- Format des réponses : [structure JSON standard]
- Gestion des erreurs : [codes HTTP utilisés et format des erreurs]

### Endpoints

#### [Ressource 1]
| Méthode | Route | Auth | Description | Corps | Réponse |
|---------|-------|------|-------------|-------|---------|
| GET | `/api/[ressource]` | [Oui/Non] | [description] | — | `[structure]` |
| POST | `/api/[ressource]` | [Oui/Non] | [description] | `[structure]` | `[structure]` |
| GET | `/api/[ressource]/:id` | [Oui/Non] | [description] | — | `[structure]` |
| PUT | `/api/[ressource]/:id` | [Oui/Non] | [description] | `[structure]` | `[structure]` |
| DELETE | `/api/[ressource]/:id` | [Oui/Non] | [description] | — | `204` |

#### [Ressource 2]
[...]

### Règles API
- [Règle 1 : ex "Toute route mutant des données requiert un token CSRF"]
- [Règle 2 : ex "Les listes sont toujours paginées — max 100 items par page"]
- [...]

---

## 4. Composants et modules

### Vue d'ensemble
```
[Composant A] ──→ [Composant B]   (dépend de)
[Composant B] ──→ [Composant C]
[Composant A] ──→ [Composant C]
```

### [Composant / Module 1]
- **Responsabilité unique :** [ce qu'il fait et seulement ça]
- **Fichiers :** `[chemin/]`
- **Interface publique :** [fonctions/classes exposées]
- **Ne doit pas :** [ce qu'il ne fait pas — frontières explicites]
- **Dépend de :** [autres composants] ou « aucun »

### [Composant / Module 2]
[...]

### Règles de dépendances
- [Règle 1 : ex "Les composants UI ne peuvent pas importer depuis services/ directement"]
- [Règle 2 : ex "Les modèles ne contiennent pas de logique métier"]
- [...]

---

## 5. Dépendances

### Production
| Package | Version | Rôle | Justification du choix |
|---------|---------|------|------------------------|
| [package] | [^x.y] | [rôle] | [pourquoi ce package plutôt qu'un autre] |

### Développement
| Package | Version | Rôle |
|---------|---------|------|
| [package] | [^x.y] | [rôle] |

### Dépendances explicitement exclues
| Package | Raison de l'exclusion |
|---------|----------------------|
| [package] | [pourquoi on ne l'utilise pas malgré sa popularité] |

---

## 6. Sécurité — décisions architecturales

- **Authentification :** [mécanisme choisi — JWT, session, OAuth — et pourquoi]
- **Autorisation :** [RBAC, ABAC, simple check — et implémentation]
- **Stockage des secrets :** [variables d'environnement, vault — jamais hardcodés]
- **Protection SQL :** [ORM utilisé + règle : jamais de raw query avec entrée utilisateur]
- **Protection XSS :** [template engine avec échappement auto + règle sur dangerouslySetInnerHTML]
- **Protection CSRF :** [mécanisme choisi]
- **Headers de sécurité :** [liste des headers à configurer]
- **Données sensibles :** [règles de non-log, non-exposition dans les réponses]

---

## 7. Performance — décisions architecturales

- **Stratégie de caching :** [où, quoi, durée — ou "aucun en v1"]
- **Requêtes N+1 :** [stratégie d'eager loading selon l'ORM]
- **Pagination :** [stratégie et taille par défaut]
- **Indexes DB :** [champs indexés et raison]
- **Assets statiques :** [stratégie de serving]
- **Limites connues :** [ce qui ne tiendra pas à l'échelle et le seuil estimé]

---

## 8. Risques techniques

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| [Risque 1] | Élevée/Moyenne/Faible | Élevé/Moyen/Faible | [comment le réduire] |
| [Risque 2] | [...] | [...] | [...] |

### Décisions à réévaluer si :
- [Condition 1 : ex "Le nombre d'utilisateurs dépasse 50 000 → réévaluer la stratégie de caching"]
- [Condition 2 : ex "Un besoin temps-réel émerge → réévaluer le transport HTTP"]
- [...]

---

## 9. Contraintes pour /build

Ces règles sont obligatoires pour toute implémentation. `/build` et `/review` les vérifient.

### Obligatoire
- [ ] Respecter la structure de dossiers définie en section 1
- [ ] Respecter les règles de structure (section 1 — Règles)
- [ ] Respecter les modèles de données définis en section 2
- [ ] Respecter les conventions API définies en section 3
- [ ] Respecter les frontières de composants définies en section 4
- [ ] Utiliser uniquement les dépendances listées en section 5 (ou justifier toute addition)
- [ ] Appliquer les décisions de sécurité de la section 6 sans exception
- [ ] Appliquer les décisions de performance de la section 7

### Interdit
- [ ] Ajouter des dépendances non listées en section 5 sans modifier d'abord architecture.md
- [ ] Créer des couches de dépendances interdites (section 4 — Règles)
- [ ] Contourner le mécanisme d'authentification défini en section 6
- [ ] Écrire des raw queries avec des entrées utilisateur non paramétrées
- [ ] Placer de la logique métier dans les couches interdites par section 4

### Modification de cette architecture
Toute déviation par rapport à ce document requiert de relancer `/architect` avant `/build`.
Ne pas modifier `specs/architecture.md` manuellement.
```

---

## Étape 6 — Clôture

Après avoir créé `specs/architecture.md`, affiche :

> « ✅ Architecture définie — `specs/architecture.md` créé.
>
> **Décision :** [Architecture retenue — nom]
> **Alternatives écartées :** [Architecture 2] ([raison courte]) — [Architecture 3] ([raison courte])
>
> **Score de comparaison :**
> - [Architecture 1] : [N]/50
> - [Architecture 2] : [N]/50
> - [Architecture 3] : [N]/50
>
> **Hypothèses critiques à surveiller :**
> - [Hypothèse 1]
> - [...]
>
> `/build` devra respecter `specs/architecture.md`. `/review` le vérifiera à chaque passe.
>
> Prochaine étape : lance `/build` pour implémenter selon cette architecture. »

---

## Règles absolues
- **Ne pas coder.** Aucun fichier de code créé ou modifié. Seul `specs/architecture.md` est écrit.
- **Toujours proposer 3 architectures** avant de choisir — même si une semble évidente. La comparaison force l'honnêteté.
- **Justifications spécifiques au projet** — les scores de la matrice doivent être justifiés par des caractéristiques réelles de la spec, pas des généralités.
- **Nommer les compromis** — toute architecture a des faiblesses. Les cacher crée de la dette cachée.
- **Hypothèses explicites** — si l'architecture repose sur une hypothèse (charge, périmètre, stack), la nommer. Une hypothèse non nommée est un risque invisible.
- **Pas de sur-ingénierie** — l'architecture choisie doit être adaptée à la taille réelle du projet, pas à la version hypothétique à 10M d'utilisateurs.
