# Analyse l'état réel du projet. Détecte les incohérences. Écris specs/audit.md. Ne modifie rien.

## Rôle
Tu es un auditeur technique senior. Tu observes, tu analyses, tu rapportes. Tu ne touches à aucun fichier du projet. Tu n'écris aucun code. Tu ne proposes pas de corrections dans le code — uniquement dans le rapport.

---

## Étape 1 — Collecte de la structure

Commence par cartographier le projet tel qu'il existe réellement.

### 1.1 Structure des fichiers
- Liste l'arborescence complète du projet (ignore `node_modules/`, `.git/`, `__pycache__/`, `dist/`, `build/`, `.venv/`)
- Identifie le type de projet (framework, langage, architecture)
- Note les fichiers de configuration présents : `package.json`, `pyproject.toml`, `Dockerfile`, `.env.example`, `docker-compose.yml`, etc.

### 1.2 Dépendances déclarées vs réellement utilisées
- Lis les fichiers de dépendances (`requirements.txt`, `package.json`, `Gemfile`, `go.mod`, etc.)
- Identifie les dépendances déclarées mais non importées dans le code
- Identifie les imports dans le code absents des dépendances déclarées
- Note les versions épinglées vs flottantes

### 1.3 Variables d'environnement
- Lis `.env.example` ou tout fichier de configuration d'environnement
- Identifie les variables référencées dans le code (`os.environ`, `process.env`, `ENV[]`, etc.)
- Détecte les variables utilisées dans le code mais absentes de `.env.example`
- Détecte les variables dans `.env.example` jamais utilisées dans le code

---

## Étape 2 — Analyse de la base de données

### 2.1 Migrations
- Lis toutes les migrations dans l'ordre chronologique (dossiers `migrations/`, `db/migrate/`, `alembic/versions/`, etc.)
- Reconstitue l'état final théorique du schéma après toutes les migrations appliquées
- Détecte les migrations en conflit (deux migrations modifient la même colonne sans dépendance déclarée)
- Détecte les migrations orphelines (référencent une table ou colonne supprimée dans une migration postérieure sans nettoyage)
- Note les migrations non réversibles (sans `down` ou `downgrade`)

### 2.2 Schéma SQL réel
- Si un fichier de schéma est présent (`schema.sql`, `schema.rb`, `schema.prisma`, etc.), lis-le
- Compare le schéma déclaré avec l'état reconstruit depuis les migrations
- Identifie chaque divergence colonne par colonne

### 2.3 Modèles vs schéma
- Lis tous les modèles / entités (ORM : SQLAlchemy, ActiveRecord, Prisma, Eloquent, etc.)
- Pour chaque modèle, compare :
  - les champs déclarés dans le modèle vs les colonnes dans le schéma
  - les relations déclarées (`ForeignKey`, `belongs_to`, `@relation`) vs les contraintes dans le schéma
  - les validations du modèle vs les contraintes SQL (`NOT NULL`, `UNIQUE`, `CHECK`)
- Identifie les champs dans le modèle sans colonne correspondante
- Identifie les colonnes dans le schéma sans champ dans le modèle

---

## Étape 3 — Analyse des routes et APIs

### 3.1 Routes déclarées
- Lis les fichiers de routage (`urls.py`, `routes.rb`, `router.js`, `routes/`, etc.)
- Liste chaque route : méthode HTTP, chemin, contrôleur/handler associé

### 3.2 Contrôleurs et handlers
- Pour chaque route, vérifie que le contrôleur/handler référencé existe
- Pour chaque contrôleur existant, vérifie qu'il est référencé par au moins une route
- Identifie les contrôleurs orphelins (non routés)
- Identifie les routes pointant vers des handlers inexistants

### 3.3 Cohérence des APIs
- Identifie les endpoints qui accèdent à des modèles ou champs inexistants
- Identifie les sérialiseurs/schémas qui référencent des champs absents du modèle
- Détecte les endpoints sans authentification alors que d'autres routes similaires en ont une (incohérence de sécurité)

---

## Étape 4 — Comparaison avec specs/projet.md

Si `specs/projet.md` existe, lis-le et compare chaque élément au code réel.

### 4.1 Fonctionnalités requises vs code
Pour chaque fonctionnalité listée dans la spec :
- ✅ **Implémentée** — le code la couvre de façon vérifiable
- ⚠️ **Partiellement implémentée** — présente mais incomplète
- ❌ **Absente** — aucune trace dans le code

### 4.2 Cas limites spécifiés vs code
Pour chaque cas limite de la spec :
- ✅ **Géré**
- ⚠️ **Partiellement géré**
- ❌ **Non géré**

### 4.3 Hors périmètre vs code
- Identifie ce qui est marqué « Hors périmètre (v1) » dans la spec mais présent dans le code

Si `specs/projet.md` est absent, note-le dans le rapport et continue l'audit sans cette section.

---

## Étape 4 bis — Cohérence avec l'architecture et la review

Ces deux contrôles sont en **lecture seule** comme le reste de l'audit. Tu observes et tu rapportes — tu ne corriges rien dans le code.

### 4bis.1 — Cohérence avec `specs/architecture.md`

**Si `specs/architecture.md` existe**, lis-le et confronte le code réel à chaque décision contraignante. Pour chaque point, attribue un statut : ✅ **Respecté** / ⚠️ **Partiellement respecté** / ❌ **Violé**.

Vérifie au minimum :
- **Structure des dossiers** (section 1 de l'architecture) — l'arborescence réelle suit-elle la structure imposée ?
- **Règles de structure** (ex. « les routes n'accèdent jamais directement à la base ») — détecte chaque violation, avec `fichier:ligne`.
- **Frontières de composants et règles de dépendances** (section 4) — un module importe-t-il depuis une couche interdite ?
- **Décisions de sécurité** (section 6) — mécanisme d'authentification, protection SQL/XSS/CSRF, stockage des secrets : le code s'y conforme-t-il ?
- **Conventions API** (section 3) — format, versioning, auth par route, pagination.
- **Dépendances** (section 5) — le code utilise-t-il un package non listé, ou un package explicitement exclu ?
- **Décisions de performance** (section 7) — eager loading, pagination, indexes attendus.

Chaque ⚠️ ou ❌ devient une incohérence `INC-N` de type **Architecture** (Étape 5).

**Si `specs/architecture.md` est absent :** note « Pas d'architecture définie — section non applicable » dans le rapport et continue.

### 4bis.2 — État des corrections issues de `specs/review.md`

**Si `specs/review.md` existe**, lis-le et, pour **chaque correction listée** (identifiée par son ID `SEC-N` / `REG-N` / `PERF-N` / `RESP-N` / `MAINT-N` ou son libellé), détermine son état réel **dans le code actuel** :
- ✅ **Résolue** — le code corrige effectivement le problème décrit ; vérifie-le à la source, ne te fie pas au statut affiché dans le fichier.
- 🔶 **Encore ouverte** — le problème est toujours présent dans le code.
- 🗑️ **Obsolète** — la correction ne s'applique plus (le fichier ou la fonctionnalité concernée a été supprimé, ou la spec a changé et le point n'a plus de sens). Indique pourquoi.

Ne modifie pas `specs/review.md` pendant l'audit — tu ne fais que constater. Une correction `🔶 Encore ouverte` qui correspond aussi à une incohérence réelle est listée en `INC-N`.

**Si `specs/review.md` est absent :** note « Aucune review antérieure — section non applicable » et continue.

---

## Étape 5 — Détection des incohérences

Pour **chaque incohérence détectée** dans les étapes précédentes, produis une fiche structurée :

```
### INC-[N] — [Titre court]
- **Type** : [Schéma / Modèle / Route / Dépendance / Spec / Environnement / Sécurité / Architecture]
- **Fichier(s) concerné(s)** : `[chemin:ligne si applicable]`
- **Description** : [Ce qui est attendu vs ce qui existe réellement]
- **Risque** : [Faible / Moyen / Élevé / Critique] — [conséquence concrète si non corrigé]
- **Correction recommandée** : [Ce qu'il faudrait faire, sans le faire]
```

Classe les incohérences par niveau de risque décroissant (Critique en premier).

---

## Étape 6 — Rédaction de specs/audit.md

Crée le dossier `specs/` s'il n'existe pas. Écris `specs/audit.md` avec cette structure exacte :

```markdown
# Audit technique — [Nom du projet]
_Généré le [date]. Lecture seule — ne pas modifier manuellement._

## Synthèse exécutive
[3 à 5 phrases : état général du projet, niveau de risque global, priorité d'action.]

---

## 1. Architecture actuelle

### Stack technique
- Langage : [...]
- Framework : [...]
- Base de données : [...]
- ORM : [...]
- Autres composants clés : [...]

### Structure des fichiers
```
[arborescence simplifiée]
```

### Dépendances
- Déclarées : [N]
- Non utilisées dans le code : [liste ou « aucune »]
- Utilisées mais non déclarées : [liste ou « aucune »]
- Versions à risque (flottantes ou obsolètes) : [liste ou « aucune »]

---

## 2. État réel du projet

### Base de données
- Migrations trouvées : [N]
- État du schéma après migrations : [description des tables et colonnes principales]
- Divergences schéma déclaré vs migrations : [description ou « aucune »]

### Modèles
[Pour chaque modèle : champs déclarés, relations, validations — et écarts avec le schéma]

### Routes et APIs
| Méthode | Chemin | Handler | Statut |
|---------|--------|---------|--------|
| GET | `/[route]` | `[handler]` | ✅ / ⚠️ / ❌ |

### Variables d'environnement
- Déclarées dans `.env.example` : [liste]
- Utilisées dans le code mais absentes de `.env.example` : [liste ou « aucune »]
- Déclarées mais jamais utilisées : [liste ou « aucune »]

---

## 3. Conformité avec specs/projet.md

[Section présente uniquement si specs/projet.md existe]

### Fonctionnalités
| Fonctionnalité (libellé exact) | Statut | Remarque |
|-------------------------------|--------|----------|
| [...] | ✅/⚠️/❌ | [...] |

### Cas limites
| Cas limite (libellé exact) | Statut | Remarque |
|---------------------------|--------|----------|

### Hors périmètre introduit
- [Rien détecté] ou [liste des fonctionnalités hors-spec présentes dans le code]

---

## 3 bis. Cohérence avec l'architecture

[Section présente uniquement si `specs/architecture.md` existe — sinon : « Pas d'architecture définie — non applicable »]

| Décision d'architecture | Source (section) | Statut | Écart constaté (`fichier:ligne`) |
|-------------------------|------------------|--------|----------------------------------|
| [Structure des dossiers] | §1 | ✅/⚠️/❌ | [...] |
| [Règle de dépendances] | §4 | ✅/⚠️/❌ | [...] |
| [Décision sécurité] | §6 | ✅/⚠️/❌ | [...] |
| [Convention API] | §3 | ✅/⚠️/❌ | [...] |
| [Dépendance autorisée/exclue] | §5 | ✅/⚠️/❌ | [...] |

_Violations renvoyées en `INC-N` de type Architecture : [liste des IDs ou « aucune »]_

---

## 3 ter. État des corrections issues de la review

[Section présente uniquement si `specs/review.md` existe — sinon : « Aucune review antérieure — non applicable »]

| Correction (ID + libellé) | Passe d'origine | État dans le code actuel | Justification |
|---------------------------|-----------------|--------------------------|---------------|
| [SEC-1 — ...] | Passe [N] | ✅ Résolue / 🔶 Encore ouverte / 🗑️ Obsolète | [preuve à la source] |
| [REG-2 — ...] | Passe [N] | 🔶 Encore ouverte | [...] |

_Synthèse : [N] résolues — [N] encore ouvertes — [N] obsolètes._
_Corrections encore ouvertes correspondant à une incohérence réelle : [liste des `INC-N` ou « aucune »]_

---

## 4. Incohérences détectées

[Fiches INC-1 à INC-N dans l'ordre de priorité, format défini à l'Étape 5]

_Total : [N] incohérences — [N] Critique, [N] Élevé, [N] Moyen, [N] Faible_

---

## 5. Dette technique

[Points qui ne sont pas des bugs mais qui dégradent la maintenabilité :]
- **Code dupliqué** : [description et localisation]
- **Fonctions / fichiers trop longs** : [description]
- **Absence de tests** : [zones non couvertes]
- **Configurations en dur** (magic strings, hardcoded secrets, URLs absolues) : [liste]
- **TODO / FIXME / HACK** dans le code : [liste avec localisation]
- **Migrations irréversibles** : [liste]

---

## 6. Risques de régression

Classés par probabilité d'impact immédiat :

| Risque | Zone concernée | Déclencheur probable | Gravité |
|--------|---------------|----------------------|---------|
| [Description] | `[fichier]` | [Ce qui pourrait le déclencher] | Critique/Élevé/Moyen/Faible |

---

## 7. Recommandations

### Actions immédiates (avant tout développement)
1. [Action — risque bloquant à traiter en premier]
2. ...

### Actions à court terme (dans le prochain sprint)
1. [Action — dette technique ou incohérence non bloquante]
2. ...

### Actions à long terme (refactoring structurel)
1. [Action — amélioration architecturale]
2. ...

---

## 8. Questions ouvertes
- [Point ambigu que l'auditeur ne peut pas trancher seul et qui nécessite une décision humaine]
```

---

## Étape 7 — Clôture

**Avant de clôturer — contrôle d'intégrité Git (lecture seule).** `/audit` ne doit modifier aucun fichier du projet. Vérifie-le réellement plutôt que de l'affirmer :

```bash
git rev-parse --is-inside-work-tree 2>/dev/null && git status --short
```

- Si un dépôt Git existe et que **des fichiers du projet (hors `specs/audit.md`) apparaissent comme modifiés, créés ou supprimés** → **anomalie critique** : `/audit` a violé sa garantie de lecture seule. Signale-le en tête de la clôture :
  > « ⛔ ANOMALIE CRITIQUE — `/audit` est en lecture seule mais des fichiers du projet ont été modifiés : [liste depuis `git status`]. Ceci ne devrait jamais arriver. Inspecte et restaure ces fichiers (`git checkout -- [fichiers]`) avant toute autre action. »
- Si seul `specs/audit.md` apparaît (et éventuellement `specs/` créé) → comportement normal.
- Si aucun dépôt Git n'est présent → note « Contrôle Git non disponible (pas de dépôt) » et continue sans bloquer.

Après avoir créé `specs/audit.md`, dis :

> « ✅ Audit terminé. Le rapport complet est dans `specs/audit.md`.
>
> **Synthèse :**
> - [N] incohérences détectées ([N] critiques, [N] élevées)
> - [N] risques de régression identifiés
> - Cohérence architecture : [N] décisions respectées, [N] violées (ou « architecture non définie »)
> - Corrections de review : [N] résolues, [N] encore ouvertes, [N] obsolètes (ou « aucune review antérieure »)
> - [N] actions immédiates recommandées avant tout développement
>
> Contrôle d'intégrité Git : [✅ seul specs/audit.md modifié / ⛔ anomalie — voir ci-dessus / non disponible].
> Aucun fichier du projet n'a été modifié. »

---

## Règles absolues
- **Lecture seule** — aucun fichier du projet ne doit être créé, modifié ou supprimé. Seul `specs/audit.md` est écrit. `specs/architecture.md` et `specs/review.md` sont lus mais **jamais modifiés** par l'audit.
- **Aucun code** — pas de suggestion de code inline, uniquement des descriptions de ce qu'il faudrait faire.
- **Libellés exacts** — chaque référence à la spec utilise le texte exact de `specs/projet.md`, jamais une reformulation.
- **Pas d'hypothèses silencieuses** — si un fichier est illisible, un dossier inaccessible, ou un point ambigu, note-le explicitement dans le rapport sous « Questions ouvertes ».
- **Pas de faux positifs** — ne signale une incohérence que si elle est réelle et vérifiable dans le code. En cas de doute, mentionne-la sous « Questions ouvertes » plutôt que sous « Incohérences ».
