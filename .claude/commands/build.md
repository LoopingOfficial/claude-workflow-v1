# Construis exactement ce qui est prévu. Teste immédiatement après chaque modification. Ne déclare jamais terminé tant qu'un échec critique subsiste.

---

## Étape 1 — Lecture obligatoire de toutes les sources

Lis chaque fichier dans cet ordre. Tous sont contraignants s'ils existent.

### specs/projet.md
Ce que le projet doit faire. Référence fonctionnelle principale.

**Si absent et que la tâche est une nouvelle fonctionnalité :**
> « Aucune spec trouvée. Lance `/spec` pour définir ce qui doit être construit. »
> — Stop.

**Si absent et que la tâche est un correctif ciblé :** continue — `specs/audit.md` ou `specs/review.md` suffisent comme référence.

**Si les Critères de complétion sont vides :**
> « Spec présente mais sans critères de complétion. Lance `/spec` pour les ajouter, ou confirme que tu veux continuer sans eux. »
> — Attends confirmation.

**Si contradiction interne détectée :**
> « Contradiction dans la spec : [A] et [B] sont incompatibles. Laquelle prime ? »
> — Stop, attends arbitrage.

### specs/audit.md
État réel du projet. Incohérences connues (`INC-N`), dette technique, risques de régression.
- Respecte l'état réel détecté : ne reproduis pas les incohérences signalées
- Si une `INC-N` est dans le périmètre du build en cours : corrige-la
- Si hors périmètre : ne la touche pas, note-la dans le récapitulatif

### specs/architecture.md
Si présent : contraignant sans exception.
- Structure des dossiers : obligatoire
- Frontières de composants et règles de dépendances : obligatoires
- Décisions de sécurité (auth, CSRF, raw queries…) : obligatoires
- Conventions API : obligatoires
- Toute déviation doit être signalée et justifiée dans le récapitulatif

### specs/review.md
Corrections issues de la dernière review. Si présent :
- Lis chaque point listé
- Traite chaque correction dans le périmètre du build en cours
- Note explicitement dans le récapitulatif chaque point de review traité

**Synthèse de lecture obligatoire** — avant de coder, pose ce résumé en 3-5 lignes :
> « Lu : [sources disponibles]. Périmètre du build : [ce qui sera construit/corrigé]. Contraintes actives : [architecture / audit / review]. »

---

## Étape 1 ter — Checkpoint Git de sécurité (avant toute modification)

**Avant d'écrire ou de modifier le moindre fichier du projet**, crée un point de retour pour que tout build puisse être annulé proprement s'il échoue ou modifie le projet de façon incorrecte.

1. **Vérifie si le projet est dans un dépôt Git :**

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

2. **Si un dépôt Git est présent :**
   - Affiche l'état courant **avant** toute modification :

```bash
git status --short
git rev-parse --short HEAD 2>/dev/null   # commit de référence du checkpoint
```

   - Crée un **checkpoint de sécurité**, dans cet ordre de préférence :
     - **Commit automatique** si l'arbre contient des changements à préserver et que c'est possible :

```bash
git add -A && git commit -m "checkpoint(build): avant build [date/heure]" 2>&1
```

     - **Sinon, stash nommé** (si commiter n'est pas souhaitable ou échoue) :

```bash
git stash push -u -m "checkpoint-build-[date/heure]" 2>&1
```

     - **Sinon**, à défaut, note le SHA courant comme point de retour manuel (`git rev-parse HEAD`) et signale que la restauration se fera par `git reset`/`git checkout` sur ce SHA.
   - Retiens la **référence exacte du checkpoint** (SHA du commit, nom du stash, ou SHA de référence) — elle sera documentée dans le récapitulatif final.

3. **Si aucun dépôt Git n'est présent :**
   - Affiche un avertissement clair :
     > « ⚠️ Aucun dépôt Git détecté. Aucun checkpoint de sécurité ne peut être créé : un échec de build ne sera pas annulable automatiquement. Je continue. »
   - **Continue sans bloquer.**

> Ce checkpoint ne modifie aucune autre règle du build : il s'exécute une seule fois, avant l'Étape 2, et n'a d'effet que sur le dépôt Git local.

---

## Étape 2 — Plan d'implémentation

Annonce le plan complet **avant d'écrire la moindre ligne de code** :

> **Plan d'implémentation :**
> 1. `[fichier]` — [ce qu'il contient, pourquoi, lien avec la spec ou la review]
> 2. ...
>
> **Corrections specs/review.md incluses :** [liste ou « aucune »]
> **Corrections specs/audit.md incluses :** [liste des INC-N traitées ou « aucune »]
> **Dépendances à installer :** [liste ou « aucune »]
> **Ordre de création :** [si des fichiers dépendent d'autres]
> **Conformité architecture :** [points clés respectés, ou « architecture.md absent »]

Commence immédiatement après. **Exception unique :** si un point du plan est ambigu au point de bloquer le premier fichier, pose une seule question précise avant de démarrer.

---

## Étape 3 — Règles d'implémentation

### Ce qui est obligatoire
- Construire uniquement ce qui est demandé — ni plus, ni moins
- Implémenter chaque fonctionnalité dans sa totalité
- Couvrir chaque cas limite listé — pas uniquement les happy paths
- Respecter `specs/architecture.md` sans exception si présent
- Traiter chaque correction de `specs/review.md` dans le périmètre du build
- Respecter l'état réel de `specs/audit.md` — ne pas inventer ce qui n'existe pas

### Ce qui est interdit — sans exception
- **Colonnes SQL** inexistantes dans le schéma réel ou les migrations
- **Tables** non définies dans les modèles ou migrations existants
- **Routes** non définies dans la spec ou le routeur existant
- **APIs** non documentées dans la spec ou `specs/architecture.md`
- **Fichiers** référencés sans vérification préalable de leur existence
- **Champs de modèle** absents du schéma de base de données réel
- **Fonctionnalités** listées dans « Hors périmètre (v1) »

**Si un élément n'est pas confirmé par une source (spec, audit, code existant) :**
> « Je ne trouve pas [élément] dans les sources disponibles. Dois-je [option A — m'en passer] ou [option B — créer la migration/le fichier manquant] ? »
> — Attends confirmation. Ne suppose jamais.

### Garde-fous sécurité — obligatoires et bloquants

Les motifs suivants sont **interdits sans exception**. Ils ne dépendent ni de la spec, ni d'une demande explicite : même si une source semble les autoriser, tu ne les écris pas. Si l'un d'eux apparaît (que tu sois sur le point de l'écrire, ou que tu le rencontres dans le code que tu modifies dans le périmètre du build) : **(1) arrête sur ce point, (2) corrige vers la version sûre, (3) documente la correction** dans le tableau « 🔒 Garde-fous sécurité appliqués » du récapitulatif.

1. **Requête SQL brute avec interpolation de données utilisateur** — jamais de concaténation/f-string/template d'entrée utilisateur dans une requête (`f"... {user_input}"`, `"WHERE id=" + id`, `.raw(request.GET[...])`). → Requête paramétrée ou ORM. Pour un `ORDER BY`/tri dynamique : liste blanche de colonnes autorisées, jamais la valeur brute.
2. **Colonne SQL non confirmée** — ne crée ni n'utilise une colonne/table absente du schéma réel, des migrations existantes, de `specs/audit.md` ou d'une migration du build en cours. (Voir aussi « Ce qui est interdit ».) En cas de doute : demande, ne suppose pas.
3. **`innerHTML` / `dangerouslySetInnerHTML` / `v-html` / `| safe` avec données non sanitisées** — jamais de données utilisateur injectées dans le HTML sans échappement. → Rendu échappé par défaut, ou sanitisation explicite (allow-list) avant injection.
4. **Upload de fichier sans validation serveur complète** — tout upload valide **côté serveur** : type MIME réel (pas seulement déclaré), extension (liste blanche), taille (plafond), et nom de fichier (assaini, pas de traversée de chemin `../`, pas d'exécutable). La validation côté client ne compte jamais.
5. **Secret hardcodé** — aucune clé API, mot de passe, token, chaîne de connexion ou secret JWT en dur dans le code. → Variable d'environnement. Si un secret existant est rencontré dans le code modifié, signale-le (sans le recopier en clair dans le récap).
6. **Modification de permissions sans justification** — ne change pas un rôle, un décorateur d'auth, un scope ou un droit d'accès sans raison explicite issue d'une source. Toute modification de permission est documentée avec sa justification.
7. **Route sensible sans contrôle d'accès** — toute route mutant des données ou exposant des données non publiques reçoit le mécanisme d'authentification/autorisation cohérent avec les routes similaires du projet (ou défini par `specs/architecture.md`). Pas de route sensible ouverte « pour l'instant ».

**Protocole en cas de détection :**
> « 🔒 Garde-fou sécurité déclenché sur [point] dans `[fichier:ligne]` : [motif N]. Je corrige en [version sûre] avant de continuer. »
> — Corrige, puis documente. Ne déclare jamais le build terminé avec un de ces motifs présent dans le code du build en cours.

### Ambiguïtés
Si la spec est floue sur un point non bloquant : choisis l'interprétation la plus conservative (la moins invasive), note-la dans le récapitulatif, et continue.

### Erreurs pendant le build
Si une erreur survient (dépendance introuvable, conflit de fichier, échec d'installation) :
- Tente de la résoudre une fois de façon autonome
- Si elle persiste : signale précisément sans bloquer les autres points
> « Erreur sur [point] : [message exact]. Je continue les autres points et reviens sur celui-ci. »

---

## Étape 4 — Validation après chaque modification

**Règle fondamentale : tester immédiatement après chaque fichier modifié ou créé — pas seulement à la fin.**

### Convention d'état des vérifications — trois états distincts

Chaque vérification (syntaxe, imports, SQL, routes, tests, non-régression) se trouve dans **exactement un** de ces trois états. Ne les confonds jamais :

- **✅ Exécuté et réussi** — la commande a réellement tourné et son résultat est conforme.
- **❌ Exécuté et échoué** — la commande a réellement tourné et a échoué (code de sortie non nul, assertion fausse).
- **⏭️ Non exécuté** — la commande n'a **pas** pu tourner : outil absent, dépendance manquante, base de test inaccessible, runtime indisponible, ou validation seulement « manuelle » (relecture de code sans exécution réelle).

**Règles strictes :**
- Un `⏭️ Non exécuté` **n'est jamais** comptabilisé comme `✅`. Une relecture manuelle, une validation « par lecture », un dry-run non concluant → restent `⏭️`, pas `✅`.
- L'ancien marqueur `[VALIDATION MANUELLE]` est un cas de `⏭️ Non exécuté` : la dimension n'a pas été prouvée par exécution. L'ancien `[NON EXÉCUTABLES]` est également `⏭️`.
- Une **vérification critique** (syntaxe, imports, SQL si la DB est touchée, routes si des routes sont touchées, tests couvrant un critère de complétion) laissée en `⏭️` **bloque la déclaration « terminé »** de la fonctionnalité concernée (voir Étape 6).

### 4.1 Vérification syntaxique immédiate
Après chaque fichier écrit :

```bash
# PHP
php -l [fichier.php]

# Python
python -m py_compile [fichier.py]
python -c "import [module]"   # pour chaque import critique

# JavaScript / TypeScript
node --check [fichier.js]
npx tsc --noEmit              # TypeScript — après chaque modification

# Ruby
ruby -c [fichier.rb]

# Go
go build ./...
```

**Si erreur syntaxique :** corrige immédiatement dans le même fichier avant de passer au suivant. Ne jamais laisser un fichier en erreur syntaxique et continuer.

### 4.2 Vérification des imports et dépendances
Après avoir créé tous les fichiers d'une fonctionnalité :

```bash
# Python
pip check
python -c "from [module] import [symbol]"   # chaque import non trivial

# Node
npm ls 2>&1 | grep -i "missing\|invalid"

# PHP
composer check-platform-reqs 2>/dev/null || true
php -r "require '[fichier.php]';"

# Ruby
bundle check
```

Si dépendance manquante : installe-la avant de continuer. Note l'ajout dans le récapitulatif.

### 4.3 Vérification SQL
Pour chaque modification touchant la base de données (modèles, migrations, requêtes) :

```bash
# Django
python manage.py migrate --check 2>&1
python manage.py sqlmigrate [app] [migration] 2>&1

# Rails
rails db:migrate:status 2>&1

# Alembic
alembic check 2>&1
alembic upgrade head --sql 2>&1   # dry-run

# Prisma
npx prisma migrate status 2>&1
npx prisma validate 2>&1
```

Vérifications manuelles systématiques :
- Chaque colonne référencée dans le code existe dans le schéma réel ou dans une migration du build en cours
- Chaque table référencée est définie
- Les clés étrangères pointent vers des colonnes qui existent
- Les contraintes NOT NULL ont une valeur par défaut ou sont alimentées partout

**Si une colonne ou table n'existe pas :**
> « [colonne/table] référencée dans [fichier:ligne] n'existe pas dans le schéma. Dois-je créer la migration, ou s'agit-il d'une erreur ? »

### 4.4 Vérification des routes
Pour chaque route créée ou modifiée :

```bash
# Django
python manage.py show_urls 2>&1 | grep [pattern]
python manage.py check 2>&1

# Rails
rails routes | grep [pattern] 2>&1

# Express / Node
node -e "require('./app')" 2>&1

# Laravel
php artisan route:list 2>&1 | grep [pattern]

# FastAPI / Flask
python -c "from [app] import app; print([r.path for r in app.routes])" 2>&1
```

Vérifie pour chaque route :
- Le handler/contrôleur référencé existe
- Les middlewares référencés existent
- La route ne duplique pas une route existante

### 4.5 Exécution des tests

**Un code qui compile n'est pas un code qui fonctionne. Une fonctionnalité n'est validée que si les tests passent.**

#### Détection de l'environnement de test
Avant d'exécuter quoi que ce soit, identifie ce qui existe :

- **Python** : `pytest.ini`, `pyproject.toml [tool.pytest]`, fichiers `test_*.py` ou `*_test.py`
- **JS/TS** : `jest.config.*`, `vitest.config.*`, scripts `test` dans `package.json`
- **Ruby** : `spec/`, `test/`, `.rspec`
- **Go** : fichiers `*_test.go`
- **PHP** : `phpunit.xml`
- **CI/CD** : `.github/workflows/`, `.gitlab-ci.yml`

**Si aucun test trouvé :**
> « Aucun test trouvé. Je procède à une validation manuelle (imports, routes, schéma, runtime). Les résultats seront marqués [VALIDATION MANUELLE] dans le récapitulatif — état `⏭️ Non exécuté`, jamais ✅. »

Vérifie aussi avant de lancer : dépendances installées, variables d'environnement présentes (`.env` ou `.env.test`), base de données de test accessible. Si la base de test est inaccessible : marque les tests DB-dépendants comme [NON EXÉCUTABLES] — état `⏭️ Non exécuté`, jamais ✅.

#### Exécution dans l'ordre

```bash
# Tests unitaires
pytest tests/unit/ -v 2>&1
npm test -- --testPathPattern=unit 2>&1
rspec spec/models/ --format documentation 2>&1
go test ./... -v 2>&1

# Tests d'intégration
pytest tests/integration/ -v 2>&1
rspec spec/requests/ --format documentation 2>&1

# Tests end-to-end (si configurés)
npx playwright test 2>&1
npx cypress run 2>&1
```

Pour chaque commande : note le code de sortie, stdout, stderr.

#### Si un test échoue

1. Détermine la cause : build en cours ou préexistant ?
2. **Si causé par le build en cours :**
   - Corrige immédiatement
   - Relance le test
   - Si l'échec persiste après deux tentatives :
     > « Blocage sur [test] après 2 tentatives : [description exacte]. Comment procéder ? »
3. **Si préexistant (hors périmètre) :** note dans le récapitulatif, ne corrige pas.

**Ne jamais déclarer le build terminé si un test échoue pour une raison causée par le build en cours.**

#### Couverture de la spec

Pour chaque critère de complétion de `specs/projet.md` :

| Besoin (libellé exact) | Tests qui le couvrent | Résultat | Validé ? |
|------------------------|----------------------|----------|----------|
| [Fonctionnalité 1] | `test_x.py::test_create` | ✅ PASS | ✅ Oui |
| [Fonctionnalité 2] | `test_y.py::test_update` | ❌ FAIL | ❌ Non |
| [Cas limite 1] | Aucun test dédié | ⚠️ Non testé | ⚠️ Inconnu |

`⚠️ Non testé` n'est jamais converti en ✅.

#### Rapport — specs/test-report.md

Crée ou met à jour `specs/test-report.md` avec :
- Synthèse (exécutés / réussis / échoués, fonctionnalités validées / non testées)
- Résultats par catégorie (unitaires, intégration, routes, e2e, runtime)
- Fiches d'échecs : message exact, fichier:ligne, besoin impacté, correction appliquée
- Couverture de la spec (✅ / ❌ / ⚠️)
- Ligne d'historique ajoutée sans écraser les précédentes

### 4.6 Vérification de non-régression
Pour chaque fichier modifié (pas seulement créé) :

```bash
grep -r "from [module] import\|require('[module]')\|include '[module]'" \
  --include="*.py" --include="*.js" --include="*.rb" . 2>&1
```

- Identifie tous les fichiers qui importent ou dépendent du fichier modifié
- Vérifie que les interfaces publiques (signatures, exports, structure de retour) sont préservées
- Si une interface a changé : mets à jour tous les appelants dans le même build

---

## Étape 5 — Récapitulatif final

```markdown
## Résumé du build — [date]

### 🧷 Checkpoint Git
| Élément | Valeur |
|---------|--------|
| Dépôt Git détecté | Oui / Non |
| Mécanisme du checkpoint | Commit `[SHA]` / Stash `[nom]` / SHA de référence `[SHA]` / Aucun (pas de dépôt) |
| Comment annuler ce build | [`git reset --hard [SHA]` / `git stash pop` / « non disponible — pas de dépôt Git »] |

### 📁 Fichiers modifiés / créés
| Fichier | Action | Raison |
|---------|--------|--------|
| `[chemin]` | Créé / Modifié | [lien avec spec ou review] |

### ✅ Fonctionnalités construites
| Besoin (libellé exact de la source) | Source | Statut |
|-------------------------------------|--------|--------|
| [Fonctionnalité 1] | specs/projet.md | ✅ Implémenté |
| [Correction review-N] | specs/review.md | ✅ Corrigé |
| [INC-N — incohérence audit] | specs/audit.md | ✅ Corrigé |

### 🧪 Vérifications exécutées
_Chaque ligne porte un seul état : ✅ Exécuté et réussi · ❌ Exécuté et échoué · ⏭️ Non exécuté (jamais comptée comme ✅)._

| Vérification | Commande | Critique ? | État |
|-------------|----------|------------|------|
| Syntaxe | `[commande]` | Oui | ✅ / ❌ / ⏭️ |
| Imports / dépendances | `[commande]` | Oui | ✅ / ❌ / ⏭️ |
| Migrations SQL | `[commande]` | Oui si DB touchée | ✅ / ❌ / ⏭️ |
| Routes | `[commande]` | Oui si routes touchées | ✅ / ❌ / ⏭️ |
| Tests | `[commande]` | Oui (critères de complétion) | ✅ [N] pass / ❌ [N] fail / ⏭️ |
| Non-régression | `[commande]` | Oui | ✅ / ❌ / ⏭️ |

_Toute vérification critique en `⏭️ Non exécuté` interdit de déclarer terminée la fonctionnalité concernée (Étape 6)._

### 🔧 Erreurs détectées et corrigées
| Erreur | Fichier | Correction appliquée |
|--------|---------|----------------------|
| [Description exacte] | `[chemin:ligne]` | [ce qui a été fait] |

### ⚠️ Points à vérifier par /review
| Point | Raison | Priorité |
|-------|--------|----------|
| [Description] | [Pourquoi /review doit l'examiner] | Haute / Moyenne / Faible |

### ⚠️ Interprétations faites
| Point ambigu | Choix retenu | Raison |
|--------------|--------------|--------|
| [Description] | [Décision] | [Justification] |

### 🚫 Hors périmètre (non touché)
- [Ce qui était exclu — confirmé non modifié]

### ⚠️ Tests préexistants échoués (non causés par ce build)
- [Aucun] ou [liste avec description]

### 📦 Dépendances ajoutées
- [Aucune] ou [package@version — raison]

### 🔒 Garde-fous sécurité appliqués
| Motif déclenché | Fichier:ligne | Version sûre appliquée |
|-----------------|---------------|------------------------|
| [SQL brut / colonne non confirmée / innerHTML / upload / secret / permission / route] | `[chemin:ligne]` | [ce qui a été fait] |

_Si aucun : « Aucun garde-fou déclenché — aucun motif interdit rencontré. »_

### 🔄 Audit à relancer ?
**[OUI / NON]**

Relancer `/audit` est recommandé dès que ce build a touché une zone à fort impact structurel. Coche ce qui a été modifié :
- [ ] Migrations
- [ ] Modèles / entités
- [ ] Routes
- [ ] APIs / contrats d'interface
- [ ] Permissions / contrôle d'accès
- [ ] Configuration (env, settings, build)
- [ ] Dépendances

→ **Si au moins une case est cochée : OUI** — « L'état réel du projet a changé sur [zones cochées]. Relance `/audit` avant la prochaine `/spec` ou `/build` pour que `specs/audit.md` reflète la réalité. »
→ **Si aucune : NON** — « Aucune zone structurelle modifiée. `specs/audit.md` reste valide. »
```

---

## Étape 6 — Décision finale

**Règle préalable — état `⏭️` bloquant :** une fonctionnalité ne peut être déclarée **terminée** que si **toutes ses vérifications critiques sont `✅ Exécuté et réussi`**. Une vérification critique en `❌` ou en `⏭️ Non exécuté` interdit la déclaration « terminé » pour cette fonctionnalité — un `⏭️` n'est pas un succès, c'est une preuve manquante.

### Si toutes les vérifications critiques sont ✅ (réellement exécutées et réussies) :
> « ✅ Build terminé et validé.
>
> [N] fonctionnalité(s) construite(s) — [N] correction(s) de review appliquée(s) — [N] test(s) passent.
> 🔒 Garde-fous sécurité : [N] déclenché(s) et corrigé(s) (ou « aucun »).
> 🔄 Audit à relancer : [OUI — zones : ... / NON].
>
> Lance `/review` pour l'audit complet (sécurité, performance, maintenabilité, score /100). »

### Si une ou plusieurs vérifications critiques sont en ⏭️ Non exécuté :
> Ne pas déclarer terminé. Signale précisément :
> « ⚠️ Build non validable en l'état — [N] vérification(s) critique(s) en ⏭️ Non exécuté :
> 1. [Vérification — fonctionnalité concernée — pourquoi non exécutée : outil/dépendance/DB absente]
> Ces points ne sont pas des échecs mais des preuves manquantes : la ou les fonctionnalités concernées ne peuvent pas être déclarées terminées tant que la vérification n'a pas réellement tourné. Comment veux-tu procéder (rendre l'environnement exécutable, ou acter le report) ? »

### Si des échecs critiques subsistent après tentatives de correction :
> Ne pas déclarer terminé. Signale précisément :
> « ⛔ Build incomplet — [N] échec(s) critique(s) non résolu(s) :
> 1. [Description — fichier — ce qui a été tenté]
> Comment veux-tu procéder ? »

### Si des points non critiques restent ouverts :
> « ✅ Build terminé. [N] point(s) non critique(s) transmis à `/review` :
> - [liste]
> Lance `/review` pour l'audit complet. »

---

## Règles absolues

- **Lire toutes les sources avant de coder** — specs/projet.md, specs/audit.md, specs/architecture.md, specs/review.md.
- **Checkpoint Git avant toute modification** — si un dépôt Git existe, créer un point de retour (commit, sinon stash nommé, sinon SHA de référence) et le documenter dans le récapitulatif ; si aucun dépôt, avertir et continuer sans bloquer.
- **Construire uniquement ce qui est demandé** — ni plus, ni moins.
- **Ne jamais inventer** colonnes SQL, tables, routes, APIs, fichiers ou champs de modèle non confirmés par une source.
- **Tester immédiatement après chaque fichier modifié** — syntaxe au fichier, tests complets à la fonctionnalité.
- **Corriger avant de continuer** — toute erreur syntaxique est bloquante pour le fichier en cours.
- **Ne jamais déclarer terminé** si un test échoue pour une raison causée par le build en cours.
- **Trois états de vérification distincts** — ✅ Exécuté et réussi / ❌ Exécuté et échoué / ⏭️ Non exécuté. Un `⏭️` (y compris validation manuelle ou DB inaccessible) n'est jamais compté comme ✅, et une vérification critique en `⏭️` interdit de déclarer terminée la fonctionnalité concernée.
- **Ne pas modifier** specs/projet.md, specs/audit.md, specs/architecture.md. Seul specs/review.md peut être marqué comme traité.
- **Libellés exacts** de la spec dans le récapitulatif — jamais de reformulations.
- **Toute déviation** — même mineure — est documentée dans « Interprétations faites », jamais silencieuse.
- **Garde-fous sécurité bloquants** — les 7 motifs interdits (SQL brut, colonne non confirmée, `innerHTML`/`dangerouslySetInnerHTML` non sanitisé, upload non validé côté serveur, secret hardcodé, permission modifiée sans justification, route sensible sans contrôle d'accès) sont corrigés et documentés ; jamais de build déclaré terminé avec l'un d'eux présent.
- **Signaler si `/audit` doit être relancé** — toute modification de migrations, modèles, routes, APIs, permissions, configuration ou dépendances impose le drapeau « 🔄 Audit à relancer : OUI » dans le récapitulatif.
