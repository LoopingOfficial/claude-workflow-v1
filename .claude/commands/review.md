# Compare le code à specs/projet.md et specs/audit.md. Audite sécurité, régressions, performance, responsive, maintenabilité. Score /100. En dessous de 95 : renvoie automatiquement à /build.

## Étape 1 — Chargement des sources

Lis dans cet ordre :
1. `specs/projet.md` — référence fonctionnelle absolue, jamais modifiée
2. `specs/audit.md` — référence d'architecture et de dette connue (si présent)
3. `specs/test-report.md` — résultats de tests existants (si présent)
4. `specs/review.md` — **état de la boucle qualité de la review précédente** (si présent)
5. Tous les fichiers de code du projet

**Si `specs/projet.md` est absent :**
> « Pas de spec trouvée. Lance `/spec` pour en créer une. »
> — Stop.

**Si aucun fichier de code n'existe :**
> « Rien n'a encore été construit. Lance `/build` d'abord. »
> — Stop.

**Si le code semble avoir été modifié manuellement depuis le dernier build** (timestamps, commentaires hors-spec, fonctions non référencées dans la spec) : note-le dans le rapport sous « Modifications manuelles détectées » sans bloquer la review.

---

## Étape 1 bis — Compteur de passes (persistant)

La boucle review→build est **stateful**. Son état vit dans `specs/review.md` et ne repart jamais de zéro.

1. **Lis `specs/review.md` s'il existe** et récupère la valeur de `Passe courante : N`.
   - Fichier absent ou première review → la passe précédente vaut `0`. **Cette review est donc la passe `1`.**
   - Fichier présent avec `Passe courante : N` → **cette review est la passe `N+1`.**
2. **Récupère la liste des corrections de la passe précédente** (table « Corrections en cours ») avec leur ID (`SEC-N`, `REG-N`, `PERF-N`, `RESP-N`, `MAINT-N`) et leur statut.
3. Tu compareras les problèmes trouvés dans cette passe à ceux de la passe précédente pour détecter les **récurrences** (même ID / même problème au même endroit) — c'est ce qui déclenche le blocage à 2 passes (Étape 10).

> **N'incrémente jamais à la main et ne réinitialise jamais le compteur.** Il est dérivé mécaniquement de `specs/review.md`. Si le fichier est corrompu ou illisible, signale-le et repars de la passe `1` en le notant explicitement dans le rapport.

---

## Étape 1 ter — Couverture de review

Avant de calculer un score, établis **honnêtement** ce que cette review a réellement pu analyser. Un score élevé obtenu sur une analyse incomplète est trompeur : la couverture conditionne le plafond de score et le droit de valider.

Détermine le statut de couverture :

- **🟢 Couverture complète** — tous les fichiers de code du projet ont été lus et audités sur toutes les dimensions applicables (conformité spec, sécurité, régression, performance, responsive si applicable, maintenabilité). Aucune zone laissée de côté.
- **🟡 Couverture partielle** — au moins une de ces situations est vraie :
  - des fichiers ou dossiers n'ont pas pu être lus (trop volumineux pour le contexte, illisibles, inaccessibles) ;
  - certaines dimensions n'ont pas pu être auditées faute d'information (ex. pas de `git diff` pour les régressions, base de test inaccessible) ;
  - l'analyse a été volontairement restreinte à un sous-ensemble du projet (review ciblée sur les points corrigés d'une passe précédente, par exemple).

Liste explicitement, dans le rapport, **ce qui n'a pas été couvert** et **pourquoi**. Ne présente jamais une review partielle comme complète.

**Conséquences d'une couverture 🟡 partielle (mécaniques, non négociables) :**
- le **score final est plafonné à 90/100** (même si la grille de déduction donne plus) ;
- la **validation finale est interdite**, quel que soit le score — la review ne peut pas conclure « ✅ prêt ».

L'objectif : empêcher qu'une analyse incomplète produise un score de validation.

---

## Étape 2 — Audit de conformité spec (existant, inchangé)

Passe en revue chaque élément de `specs/projet.md` et attribue un statut :

**Fonctionnalités requises**
- ✅ Couverte — implémentation conforme
- ⚠️ Partielle — présente mais incomplète ou incorrecte (précise ce qui manque)
- ❌ Manquante — aucune implémentation trouvée

**Cas limites et gestion d'erreurs**
- ✅ Géré — comportement conforme à la spec
- ⚠️ Mal géré — traité mais comportement diverge de la spec
- ❌ Non géré — cas ignoré

**Critères de complétion**
- ✅ Validé — critère satisfait et vérifiable dans le code
- ❌ Non validé — ne peut pas encore être vérifié

**Contrôle hors-périmètre**
- 🚫 Hors périmètre introduit — fonctionnalité ajoutée non prévue dans la spec

**Comparaison avec specs/audit.md** (si présent)
- Pour chaque incohérence listée dans l'audit (`INC-N`), vérifie si elle a été corrigée dans le code
- ✅ Résolue / ⚠️ Partiellement résolue / ❌ Toujours présente

---

## Étape 3 — Audit sécurité

Examine le code pour chaque vecteur. Chaque problème trouvé est une fiche `SEC-N`.

### 3.1 Injection SQL
- Cherche les requêtes construites par concaténation de chaînes avec des données utilisateur
- Vérifie que toutes les entrées utilisateur passent par des requêtes paramétrées ou un ORM sans raw query dangereuse
- Cas suspects : `f"SELECT ... {user_input}"`, `"WHERE id=" + id`, `.raw(request.GET['q'])`
- Vérifie les filtres de recherche, les tris dynamiques, les clauses `ORDER BY` construites dynamiquement

### 3.2 XSS (Cross-Site Scripting)
- Cherche les endroits où des données utilisateur sont rendues dans le HTML sans échappement
- Vérifie les templates : `{{ var | safe }}` (Django/Jinja), `dangerouslySetInnerHTML` (React), `v-html` (Vue), `innerHTML =` (JS natif)
- Vérifie que les réponses JSON ne sont pas injectées directement dans le HTML
- Cherche les Content-Security-Policy headers

### 3.3 CSRF (Cross-Site Request Forgery)
- Vérifie la présence de tokens CSRF sur toutes les mutations (POST, PUT, PATCH, DELETE)
- Vérifie que les routes d'API authentifiées valident l'origine de la requête
- Cherche les endpoints qui acceptent des requêtes cross-origin sans vérification
- Vérifie les headers `SameSite` sur les cookies de session

### 3.4 Contrôle d'accès
- Identifie toutes les routes et vérifie qu'elles ont un décorateur ou middleware d'authentification approprié
- Cherche les routes qui devraient être protégées mais ne le sont pas (comparaison avec des routes similaires protégées)
- Vérifie les accès directs aux objets (IDOR) : `GET /users/{id}` — l'utilisateur peut-il accéder à l'objet d'un autre ?
- Cherche les vérifications `if user.id == object.owner_id` manquantes

### 3.5 Permissions et autorisation
- Vérifie la séparation des rôles si la spec en mentionne
- Cherche les élévations de privilège possibles
- Vérifie que les données sensibles (mots de passe, tokens) ne sont jamais loguées ni renvoyées dans les réponses API
- Cherche les secrets hardcodés dans le code (clés API, mots de passe, tokens JWT)

**Format de chaque fiche sécurité :**
```
### SEC-[N] — [Titre]
- **Type** : [SQLi / XSS / CSRF / Accès / Permission / Autre]
- **Sévérité** : [Critique / Élevée / Moyenne / Faible]
- **Fichier** : `[chemin:ligne]`
- **Description** : [ce qui est vulnérable et comment]
- **Impact** : [conséquence concrète si exploité]
- **Correction** : [ce qu'il faut faire précisément]
```

---

## Étape 4 — Audit des régressions

### 4.1 Fonctionnalités existantes
- Identifie toutes les fonctionnalités qui existaient avant les dernières modifications (via git diff si disponible, sinon via la spec et les commentaires de code)
- Pour chaque fonctionnalité existante, vérifie que le code modifié ne la casse pas
- Cherche les fonctions supprimées ou renommées qui étaient appelées ailleurs
- Cherche les changements de signature de fonction sans mise à jour des appelants
- Cherche les changements de schéma DB (colonnes renommées/supprimées) sans migration correspondante

### 4.2 Dépendances inter-modules
- Identifie les modules qui importent des fonctions modifiées
- Vérifie que les interfaces publiques (exports, API internes) sont préservées
- Cherche les effets de bord sur des modules non directement modifiés

### 4.3 Données existantes
- Vérifie que les migrations sont rétrocompatibles avec les données existantes
- Identifie les migrations qui pourraient échouer sur une base non vide (ajout de colonne NOT NULL sans valeur par défaut, etc.)

**Format de chaque fiche régression :**
```
### REG-[N] — [Titre]
- **Sévérité** : [Critique / Élevée / Moyenne / Faible]
- **Fonctionnalité impactée** : [nom]
- **Fichier modifié** : `[chemin:ligne]`
- **Fichier impacté** : `[chemin:ligne]`
- **Description** : [ce qui pourrait casser et pourquoi]
- **Correction** : [ce qu'il faut faire]
```

---

## Étape 5 — Audit performance

### 5.1 Requêtes SQL inutiles
- Cherche les requêtes dans des boucles (`for item in list: db.query(...)`)
- Cherche les requêtes qui chargent toute une table sans pagination ni filtre
- Cherche les `SELECT *` quand seules quelques colonnes sont nécessaires
- Cherche les appels `.count()` suivis de `.all()` sur la même queryset (double requête)

### 5.2 Problèmes N+1
- Cherche les accès à des relations dans des boucles sans eager loading
- Exemples suspects :
  - Django : `for post in posts: print(post.author.name)` sans `select_related`
  - Rails : `Post.all.each { |p| p.comments.count }` sans `includes`
  - Prisma : accès à des relations sans `include`
  - SQLAlchemy : accès lazy à des relations dans une boucle
- Vérifie que les `JOIN` sont utilisés quand plusieurs tables sont nécessaires

### 5.3 Chargements inutiles
- Cherche les eager loadings trop larges (charger 10 relations alors qu'une seule est utilisée)
- Cherche les calculs répétés qui pourraient être mis en cache
- Cherche les appels API externes dans des boucles
- Cherche les fichiers ou images chargés entièrement en mémoire sans streaming

**Format de chaque fiche performance :**
```
### PERF-[N] — [Titre]
- **Type** : [N+1 / Requête inutile / Chargement excessif / Calcul répété]
- **Impact estimé** : [Critique / Élevé / Moyen / Faible]
- **Fichier** : `[chemin:ligne]`
- **Description** : [problème exact]
- **Correction** : [solution précise avec exemple si utile]
```

---

## Étape 6 — Audit responsive (si applicable)

**Applicable si** : le projet contient du HTML/CSS/JS frontend, des templates, ou une interface utilisateur.
**Non applicable si** : le projet est une API pure, un script CLI, ou un service backend sans frontend.

Si non applicable : note « Audit responsive : non applicable (projet sans frontend) » et passe à l'Étape 7.

### 6.1 Mobile (< 768px)
- Vérifie que les éléments clés ont des breakpoints mobile
- Cherche les largeurs fixes en `px` qui déborderaient sur petit écran
- Vérifie que les zones cliquables font au moins 44×44px
- Cherche les tableaux sans gestion du défilement horizontal sur mobile
- Vérifie la taille de police (minimum 16px sur les inputs pour éviter le zoom iOS)

### 6.2 Tablette (768px – 1024px)
- Vérifie l'adaptation des grilles (passage de N colonnes à N/2)
- Cherche les éléments qui se chevauchent à cette résolution
- Vérifie les menus de navigation

### 6.3 Desktop (> 1024px)
- Vérifie que le contenu n'est pas trop étiré sur grands écrans (max-width)
- Vérifie la cohérence des espacements

**Format de chaque fiche responsive :**
```
### RESP-[N] — [Titre]
- **Breakpoint** : [Mobile / Tablette / Desktop / Tous]
- **Sévérité** : [Critique / Élevée / Moyenne / Faible]
- **Fichier** : `[chemin:ligne]`
- **Description** : [problème exact]
- **Correction** : [ce qu'il faut modifier]
```

---

## Étape 7 — Audit maintenabilité

### 7.1 Duplication de code
- Identifie les blocs de code identiques ou quasi-identiques (> 10 lignes) présents à plusieurs endroits
- Identifie les fonctions qui font la même chose sous des noms différents
- Signale les constantes dupliquées (même valeur définie à plusieurs endroits)

### 7.2 Fichiers trop volumineux
- Signale les fichiers dépassant 300 lignes (avertissement) ou 500 lignes (problème)
- Signale les fonctions dépassant 50 lignes
- Signale les classes avec plus de 10 méthodes publiques sans séparation claire

### 7.3 Dette technique
- Cherche les `TODO`, `FIXME`, `HACK`, `XXX`, `TEMP` dans le code
- Cherche les magic strings et magic numbers (valeurs hardcodées sans constante nommée)
- Cherche les `except: pass`, `catch(e) {}` (erreurs silencieuses)
- Cherche les `print()`, `console.log()`, `debugger` oubliés en production
- Cherche les imports inutilisés
- Cherche les fonctions ou variables déclarées mais jamais utilisées

**Format de chaque fiche maintenabilité :**
```
### MAINT-[N] — [Titre]
- **Type** : [Duplication / Taille / TODO / Magic value / Erreur silencieuse / Import inutile / Autre]
- **Priorité** : [Haute / Moyenne / Faible]
- **Fichier** : `[chemin:ligne]`
- **Description** : [problème exact]
- **Correction** : [recommandation]
```

---

## Étape 8 — Rapport consolidé

Produis le rapport dans ce format :

---

### 📋 Rapport de review — Passe [N] — [date]

#### Conformité spec (`specs/projet.md`)
| Besoin (libellé exact) | Statut | Fichier | Problème |
|------------------------|--------|---------|----------|
| [Fonctionnalité 1] | ✅ | `f.py:12` | — |
| [Fonctionnalité 2] | ⚠️ | `f.py:34` | [écart] |
| [Cas limite 1] | ❌ | — | Non géré |

#### Conformité audit (`specs/audit.md`)
| Incohérence (INC-N) | Statut | Remarque |
|---------------------|--------|----------|
| [INC-1 libellé] | ✅ Résolue | — |
| [INC-2 libellé] | ❌ Toujours présente | [détail] |

#### Sécurité
| ID | Type | Sévérité | Fichier | Résumé |
|----|------|----------|---------|--------|
| SEC-1 | SQLi | Critique | `views.py:42` | Requête concaténée |

#### Régressions
| ID | Sévérité | Fonctionnalité impactée | Fichier | Résumé |
|----|----------|------------------------|---------|--------|
| REG-1 | Élevée | [Nom] | `module.py:18` | [résumé] |

#### Performance
| ID | Type | Impact | Fichier | Résumé |
|----|------|--------|---------|--------|
| PERF-1 | N+1 | Élevé | `views.py:87` | [résumé] |

#### Responsive
| ID | Breakpoint | Sévérité | Fichier | Résumé |
|----|------------|----------|---------|--------|
| RESP-1 | Mobile | Élevée | `styles.css:23` | [résumé] |

#### Maintenabilité
| ID | Type | Priorité | Fichier | Résumé |
|----|------|----------|---------|--------|
| MAINT-1 | Duplication | Haute | `utils.py:12,89` | [résumé] |

#### Hors périmètre introduit
- [Rien] ou [description + localisation]

#### Modifications manuelles détectées
- [Rien] ou [description]

#### Couverture de review
- **Statut : 🟢 Complète** ou **🟡 Partielle**
- [Si 🟡] Zones / dimensions non couvertes et raison : [liste]
- [Si 🟡] Conséquences appliquées : score plafonné à 90/100 — validation finale interdite

---

## Étape 9 — Score global /100

Calcule le score selon cette grille de déduction à partir de 100 :

### Conformité spec (max -40 pts de pénalité)
- Fonctionnalité ❌ manquante : -8 pts chacune
- Fonctionnalité ⚠️ partielle : -4 pts chacune
- Critère de complétion ❌ : -5 pts chacun
- Cas limite ❌ non géré : -3 pts chacun

### Sécurité (max -30 pts de pénalité)
- Faille Critique : -15 pts chacune
- Faille Élevée : -8 pts chacune
- Faille Moyenne : -3 pts chacune
- Faille Faible : -1 pt chacune

### Régressions (max -15 pts de pénalité)
- Régression Critique : -10 pts chacune
- Régression Élevée : -5 pts chacune
- Régression Moyenne : -2 pts chacune

### Performance (max -8 pts de pénalité)
- Impact Critique : -4 pts chacun
- Impact Élevé : -2 pts chacun
- Impact Moyen : -1 pt chacun

### Responsive (max -5 pts de pénalité, si applicable)
- Sévérité Critique : -3 pts chacune
- Sévérité Élevée : -1 pt chacune

### Maintenabilité (max -5 pts de pénalité)
- Priorité Haute : -1 pt chacune (max -3)
- Priorité Moyenne : -0,5 pt chacune (max -2)

**Score plancher : 0. Score ne peut pas dépasser 100.**

**Plafond de couverture (Étape 1 ter) :** si la couverture est 🟡 **partielle**, applique `score final = min(score calculé, 90)`. Ce plafond s'applique *après* toutes les déductions de la grille. Une couverture 🟢 complète ne plafonne rien.

Présente le score ainsi :

```
## 🎯 Score global : [N]/100

| Dimension | Pénalités | Détail |
|-----------|-----------|--------|
| Conformité spec | -[N] | [N]❌ [N]⚠️ |
| Sécurité | -[N] | [N] Critique, [N] Élevée |
| Régressions | -[N] | [N] Critique, [N] Élevée |
| Performance | -[N] | [N] Élevé |
| Responsive | -[N] | [N] Critique |
| Maintenabilité | -[N] | [N] Haute priorité |
| **Total pénalités** | **-[N]** | |
| Couverture | 🟢 Complète / 🟡 Partielle | [si 🟡 : plafond 90 appliqué] |
| **Score final** | **[N]/100** | |
```

---

## Étape 10 — Corrections et décision

### Si score ≥ 95/100 ET toutes les conditions de validation sont remplies :

Conditions de validation (toutes obligatoires) :
- ✅ Tous les besoins de `specs/projet.md` sont couverts (aucun ❌ sur fonctionnalités ou critères)
- ✅ **Aucune fonctionnalité requise n'est ⚠️ Partielle** — une fonctionnalité requise encore partielle bloque la validation au même titre qu'une fonctionnalité ❌ Manquante
- ✅ Aucune faille de sécurité Critique ou Élevée
- ✅ Aucune régression Critique ou Élevée
- ✅ Aucun bug critique non résolu
- ✅ Couverture de review **complète** (voir Étape 1 ter — une couverture partielle interdit la validation)

> « ✅ Review complète — Score [N]/100 — Passe [N].
>
> Toutes les conditions de validation sont remplies.
> Le projet est conforme à `specs/projet.md` et aux standards de qualité.
>
> Fonctionnalités validées : [liste]
> Points de vigilance (non bloquants) : [liste des Faible/Moyen restants si score entre 95-99] »

### Si score < 95/100 OU une condition de validation n'est pas remplie :

Construis la liste de corrections et transmets-la automatiquement à `/build` :

> « ❌ Score [N]/100 — en dessous du seuil de 95. Transmission automatique des corrections à `/build`.
>
> **Actions transmises à /build — Passe [N] :**
>
> PRIORITÉ 1 — Sécurité Critique
> [SEC-N] [Titre] : `[fichier:ligne]`
> Correction : [description précise]
>
> PRIORITÉ 2 — Conformité spec (❌)
> [Fonctionnalité manquante] : [correction]
>
> PRIORITÉ 3 — Régressions Critiques/Élevées
> [REG-N] [Titre] : [correction]
>
> PRIORITÉ 4 — Performance Élevée
> [PERF-N] [Titre] : [correction]
>
> PRIORITÉ 5 — Responsive Critique
> [RESP-N] [Titre] : [correction]
>
> PRIORITÉ 6 — Maintenabilité Haute
> [MAINT-N] [Titre] : [correction]
>
> Traite dans cet ordre. Relance `/review` après chaque passe de corrections. »

### Décision de boucle automatique

La décision s'appuie sur le compteur persistant de l'Étape 1 bis (passe courante = `N`) et sur la comparaison avec les corrections de la passe précédente.

**Règle des 2 passes — récurrence = blocage humain**
Si un problème (même ID, ou même motif au même `fichier:ligne`) est **encore présent alors qu'il était déjà listé à la passe précédente** — donc non résolu après une tentative de `/build` complète — la validation est **bloquée**, quel que soit le score :
> « ⛔ Blocage — "[ID/problème]" est toujours présent après 2 passes (vu aux passes [X] et [X+1]). Description : [exacte]. Ce que `/build` a tenté : [résumé]. Intervention humaine requise — comment veux-tu procéder ? »
- Marque ce problème `🔁 Récurrent — blocage` dans `specs/review.md`.
- Ne transmets pas ce problème à `/build` pour une nouvelle tentative automatique : il sort de la boucle.

**Plafond de 5 passes — arrêt de la boucle**
Si cette review est la **passe 5** (ou au-delà) et que la validation n'est toujours pas atteinte :
> « 🛑 Arrêt de la boucle automatique — 5 passes atteintes sans validation (score actuel : [N]/100).
> Ce qui bloque encore, précisément :
> - [ID] [Titre] — `[fichier:ligne]` — pourquoi ce n'est pas résolu : [cause exacte, ex : correction tentée mais insuffisante / dépendance externe / contradiction spec]
> - ...
> La boucle ne se relance pas automatiquement. Décision humaine nécessaire sur ces points. »
- N'émets aucune nouvelle transmission automatique à `/build`.

**Sinon (passe < 5, aucun problème récurrent bloquant)**
- Transmets les corrections à `/build` selon le format de priorités ci-dessus.
- À la prochaine review, le compteur passera mécaniquement à `N+1` (Étape 1 bis).
- Relance l'audit depuis l'Étape 2 sur les points corrigés en priorité, sans ignorer une éventuelle régression introduite par la correction.

---

## Étape 11 — Persistance dans `specs/review.md`

**À chaque review — qu'elle valide ou non — écris/mets à jour `specs/review.md`.** C'est ce fichier qui porte le compteur de passes et la liste des corrections que `/build` consommera. Sans cette écriture, la boucle perd la mémoire et repart de zéro.

Crée le dossier `specs/` s'il n'existe pas. Écris `specs/review.md` avec cette structure exacte :

```markdown
# Review — État de la boucle qualité
_Géré automatiquement par /review. Ne pas éditer à la main — relancer /review pour mettre à jour._

## Passe courante : [N]
_Dernière review : [date][ — contre commit [SHA] si git disponible]_

## Score : [N]/100 — [✅ Validé / ❌ Non validé]

## Corrections en cours
| ID | Type | Sévérité | Fichier:ligne | Statut | Vu aux passes |
|----|------|----------|---------------|--------|---------------|
| SEC-1 | SQLi | Critique | `views.py:42` | 🔶 Ouvert | 1, 2 |
| REG-1 | Régression | Élevée | `mod.py:18` | ✅ Résolu (passe 2) | 1 |
| MAINT-3 | Duplication | Haute | `utils.py:12` | 🔁 Récurrent — blocage | 1, 2 |

_Statuts possibles : 🔶 Ouvert · ✅ Résolu (passe N) · 🔁 Récurrent — blocage · 🗑️ Obsolète_

## Problèmes récurrents (présents ≥ 2 passes) — intervention humaine
- [ID] — `[fichier:ligne]` — présent depuis passe [X] — [ce qui a été tenté] — [pourquoi ça bloque]
- [Aucun]

## Historique des passes
- Passe 1 — [date] — score [N]/100 — [N] ouverts, [N] résolus
- Passe 2 — [date] — score [N]/100 — [N] ouverts, [N] résolus
```

Règles d'écriture :
- **Le compteur `Passe courante` reflète la passe que tu viens d'exécuter** (la valeur lue à l'Étape 1 bis + 1, ou 1 si premier passage).
- **Append l'historique** — n'écrase jamais les lignes des passes précédentes dans « Historique des passes ».
- **Conserve la traçabilité** de chaque ID : la colonne « Vu aux passes » s'allonge, elle ne se réinitialise pas.
- **Un problème résolu** passe à `✅ Résolu (passe N)` mais reste listé (mémoire de la boucle) ; il n'est pas re-transmis à `/build`.
- **Si la review valide (score ≥ 95 et conditions remplies)** : écris quand même le fichier, `Score : ✅ Validé`, tous les points en `✅ Résolu` ou `🗑️ Obsolète`. Le fichier devient la trace de clôture de la boucle.

---

## Étape 12 — Contrôle d'intégrité Git (clôture)

`/review` est en lecture seule sur le **code du projet** ; le seul fichier qu'il écrit est `specs/review.md`. Vérifie-le réellement en fin d'exécution :

```bash
git rev-parse --is-inside-work-tree 2>/dev/null && git status --short
```

- Si un dépôt Git existe et que **des fichiers du projet (ou tout fichier autre que `specs/review.md`) apparaissent comme modifiés, créés ou supprimés** → **anomalie critique** : `/review` a dépassé son rôle de lecture seule. Signale-le :
  > « ⛔ ANOMALIE CRITIQUE — `/review` ne doit modifier que `specs/review.md`, mais d'autres fichiers ont changé : [liste depuis `git status`]. Inspecte et restaure ces fichiers (`git checkout -- [fichiers]`) avant toute autre action. »
- Si seul `specs/review.md` apparaît modifié → comportement normal.
- Si aucun dépôt Git n'est présent → note « Contrôle Git non disponible (pas de dépôt) » et continue sans bloquer.

---

## Blocages — interrompre immédiatement si :
- La spec contient une **contradiction** entre deux exigences
- Une faille de sécurité est **impossible à corriger** sans changer l'architecture
- Une correction nécessite de **modifier `specs/projet.md`** :
  > « Pour résoudre "[problème]", il faudrait modifier la spec. Relance `/spec` pour la mettre à jour, puis `/build` et `/review`. »

---

## Règles absolues
- **Validation interdite** si : fonctionnalité ❌, **fonctionnalité requise ⚠️ Partielle**, faille sécurité Critique/Élevée, régression Critique/Élevée, problème **récurrent sur 2 passes**, **couverture de review partielle**, ou score < 95.
- **Compteur de passes persistant** — la passe courante est lue dans `specs/review.md` et incrémentée mécaniquement, jamais réinitialisée à la main. La boucle ne repart pas de zéro.
- **Écrire `specs/review.md` à chaque review** — c'est le seul fichier produit par `/review` ; il porte le compteur, la liste des corrections et l'historique que `/build` consomme.
- **Blocage humain garanti** à la récurrence d'un problème sur 2 passes, et **arrêt de la boucle** à la passe 5 sans validation, avec explication précise de ce qui bloque.
- **Ne jamais modifier `specs/projet.md` ou `specs/audit.md`.** (`specs/review.md` est, lui, écrit par `/review`.)
- **Libellés exacts** — chaque référence à la spec utilise le texte original.
- **Ne supprime pas** de code fonctionnel couvrant un besoin réel.
- **Transmission automatique à `/build`** dès que le score < 95 — pas de demande de confirmation.
- **Maximum 5 passes**, puis escalade humaine.
- **Score honnête** — ne pas arrondir en faveur du projet. Chaque pénalité listée dans la grille s'applique mécaniquement.
