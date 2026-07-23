# Volontariapp - CI Tools & Orchestration

Ce dépôt agit comme le **centre névralgique** de l'Intégration et du Déploiement Continus (CI/CD) de Volontariapp.

Dans une architecture distribuée (Microservices, API Gateway, Monorepo NPM partagé, Mobile App), la duplication des pipelines GitHub Actions devient rapidement ingérable. Ce repository résout ce problème en hébergeant une suite d'**Actions Composites**, de **Workflows Réutilisables** et de **Scripts de validation** qui sont appelés dynamiquement par tous les autres dépôts de l'écosystème.

---

## Architecture des Pipelines CI/CD

Le dossier `.github/workflows/` contient l'ensemble des orchestrateurs et pipelines standardisés de Volontariapp. Chaque microservice s'appuie sur ces fichiers pour garantir des règles strictes de build et de déploiement.

### 1. Workflows de Microservices (Services CI)
Ces workflows garantissent qu'un microservice est fonctionnel, packagé et disponible :
- **`service-ci.yml`** : Pipeline d'intégration continu standard pour un microservice (Lint, Tests Unitaires, Couverture de code).
- **`service-docker-smoke.yml`** : Valide qu'un microservice démarre correctement et répond à ses sondes de vitalité (Health Checks) dans un environnement Docker isolé, avant tout déploiement.
- **`service-docker-build-push.yml`** : Compile l'image Docker finale (optimisée pour la production) et la pousse vers le registre **GitHub Container Registry (GHCR)**.

### 2. Validation de l'Écosystème (E2E & Matrix)
L'architecture de tests bout-en-bout (E2E) est capable de tester dynamiquement une branche spécifique d'un microservice contre les branches `main` de tous les autres services.
- **`e2e-orchestrator.yml`** : Orchestre le démarrage des bases de données et des microservices, puis exécute la suite de tests E2E centralisée.
- **`e2e-matrix-checker.yml`** : Protège la branche `main` en vérifiant qu'aucune PR ne tente de fusionner une configuration pointant vers des images de test ou de feature (validation de la matrice de déploiement).

### 3. Usine Logicielle NPM (`npm-packages`)
Le monorepo des librairies partagées possède un cycle de vie complexe géré via *Changesets* :
- **`npm-packages-pipeline.yml` / `npm-packages-test-build.yml`** : Isole les tests et les builds pour chaque librairie modifiée.
- **`npm-packages-orchestrate.yml` / `npm-packages-release.yml`** : Automatise la publication des librairies sur le registre NPM privé, gère le bump sémantique des versions et génère les changelogs automatiquement.
- **`npm-packages-emergency-release.yml`** : Pipeline spécifique pour les correctifs critiques hors du cycle standard.

### 4. Synchronisation Globale (GitOps)
- **`proto-sync.yml` & `proto-reset.yml`** : Maintient la stricte cohérence des contrats gRPC (Protobuf). Lorsqu'un `.proto` est modifié, ce workflow génère les typages TypeScript et les synchronise automatiquement à travers les dépôts (via Pull Requests automatisées).
- **`sync-all.yml`** : Clone l'intégralité des dépôts de l'organisation pour propager massivement une mise à jour des pointeurs de configuration CI.

---

## Actions Composites Réutilisables

Situées dans `.github/actions/`, ces actions encapsulent de la logique de bas niveau pour rendre les workflows principaux plus propres.

### `setup-node-yarn`
Action composite sur-optimisée qui configure le contexte Node.js et Yarn de manière déterministe. Elle masque la complexité de l'activation de `corepack`, la gestion du cache des dépendances et de la version stricte de Node.

**Exemple d'utilisation dans un autre repo :**
```yaml
- name: Setup Node & Yarn
  uses: Volontariapp/ci-tools/.github/actions/setup-node-yarn@main
  with:
    node-version: 24.14.0
```

---

## Outils & Scripts de Validation (`scripts/`)

### `e2e-matrix-parsing.sh`
Ce script Bash est le cœur du routage dynamique des images Docker. Il lit le fichier `e2e-matrix.json` et convertit les branches Git en Tags Docker pour préparer l'environnement (`main` devient `latest`, `feat/auth` devient `feat-auth`). Il crache un fichier `.env` parfaitement formaté pour `docker-compose`.

### `validate-matrix-main.sh`
Il s'agit d'un script de gouvernance. Il parse la matrice des versions et retourne un code d'erreur (Fail CI) si un service est configuré pour dépendre d'une branche autre que `main`. Ce script est systématiquement appelé avant d'autoriser une fusion (Merge) vers la branche principale.

---

## Infrastructure d'Intégration & Développement (`docker-compose.yml`)

Ce dépôt fournit également le **Docker Compose** maître utilisé par la CI (et localement par les développeurs) pour orchestrer l'intégralité de la plateforme sur le `volontariapp-network`.

### Stratégie Hybride (GHCR)
Par défaut, ce fichier de composition ne "build" aucun code source. Il va chercher les images précompilées (tag `latest`) sur le **GHCR**. Cela permet de lever l'intégralité du cluster applicatif en quelques secondes.

| Service       | Variable d'Environnement | Tag par défaut |
| ------------- | ------------------------ | -------------- |
| `api-gateway` | `API_GATEWAY_TAG`        | `latest`       |
| `ms-user`     | `MS_USER_TAG`            | `latest`       |
| `ms-post`     | `MS_POST_TAG`            | `latest`       |
| `ms-event`    | `MS_EVENT_TAG`           | `latest`       |
| `ms-social`   | `MS_SOCIAL_TAG`          | `latest`       |

### Profils Docker & Développement Local
Pour construire un service spécifique localement (depuis les sources), nous utilisons le fichier `docker-compose.override.yml` combiné aux **Profils Docker**.

```bash
# Lancer uniquement les bases de données (PostgreSQL, Neo4j, Redis)
docker compose up -d

# Lancer l'infrastructure complète pour les tests End-to-End
docker compose --profile e2e up -d

# Remplacer l'image distante de ms-user par un build local à chaud
docker compose -f docker-compose.yml -f docker-compose.override.yml --profile local-ms-user up -d --build
```

