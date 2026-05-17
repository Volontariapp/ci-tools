# CI Tools

This repository acts as the central hub for Volontariapp's Continuous Integration (CI) and Continuous Deployment (CD) workflows.
It houses all the reusable GitHub Actions, workflows, and global synchronized logic for our microservices and shared libraries.

## 🎯 Purpose

In an umbrella architecture containing several microservices (e.g. `api-gateway`, `ms-user`, `npm-packages`), duplicating GitHub workflow files generates an immense amount of technical debt.
This `ci-tools` repository solves this by extracting the common CI configuration into a single place. All other repositories within the project merely reference the workflows stored here.

## 📦 What's Inside?

### Reusable Workflows (`.github/workflows/`)

- **`validate-compose.yml`**: Automatically validates the syntax and configuration of all Docker Compose files in this repository.
- **`build-changelog-checker.yml`**: A reusable workflow that builds and tests the `changelog-checker` Go binary, and updates the `npm-packages` `tools/` folder.
- **`npm-packages-ci.yml`**: A complete, optimized CI sequence for the monorepo `npm-packages`. It isolates tests per library and checks changelogs smartly against modifications.
- **`sync-all.yml`**: A powerful synchronization workflow. When pushed to `ci-tools`, it clones every single microservice repository and runs an automated script to commit and push the updated CI configuration pointer everywhere.

### Composite Actions (`.github/actions/`)

- **`setup-node-yarn`**:
  An optimized, reusable composite action setting up the precise Node.js context required by Volontariapp.
  It abstracts away the complexity of configuring Corepack and specific `node-version` rules.

  **Usage example**:

  ```yaml
  - name: Setup Node & Yarn
    uses: Volontariapp/ci-tools/.github/actions/setup-node-yarn@main
    with:
      node-version: 24.14.0
  ```

## 🗄️ Infrastructure & Services (`docker-compose.yml`)

This repository provides a unified local development environment. All services share a `volontariapp-network` for seamless communication.

| Service       | Postgres Port | Neo4j (HTTP/Bolt) |
| ------------- | ------------- | ----------------- |
| `ms-user`     | `5432`        | -                 |
| `ms-post`     | `5433`        | -                 |
| `ms-event`    | `5434`        | -                 |
| `ms-social`   | `5435`        | `7474` / `7687`   |

### 🌿 Hybrid CI / Development Strategy

By default, all services pull their `latest` image from **GHCR**. This allows you to run the full stack without building everything locally. You can use environment variables to target specific versions or branches.

| Variable             | Description                                | Default  |
| -------------------- | ------------------------------------------ | -------- |
| `API_GATEWAY_TAG`    | Tag for `api-gateway` and `api-gateway-e2e`| `latest` |
| `MS_USER_TAG`        | Tag for `ms-user`                          | `latest` |
| `MS_POST_TAG`        | Tag for `ms-post`                          | `latest` |
| `MS_EVENT_TAG`       | Tag for `ms-event`                         | `latest` |
| `MS_SOCIAL_TAG`      | Tag for `ms-social`                        | `latest` |

**Example: Run with a specific branch image**
```bash
MS_USER_TAG=feat-new-auth docker compose up -d
```

### 🛠️ Local Development & Overrides

For local development (building from source), use a `docker-compose.override.yml` file. This is the only stable way to swap an image for a local build.

#### Using Profiles

We use **Docker Compose Profiles** to keep the environment lean:

- **(Default)**: Starts only databases and core infrastructure.
- **`monitoring`**: Starts the full observability stack (Grafana, Prometheus, etc.).
- **`e2e`**: Starts the API Gateway and its dedicated test runner.
- **`local-xxx`**: Reserved for local build overrides (e.g., `local-ms-user`, `local-api-gateway`).

**Example: Launch E2E tests locally**
```bash
# In api-gateway folder
docker compose -f ../ci-tools/docker-compose.yml -f docker-compose.override.yml --profile e2e up --build
```

**Example: Local development of two services**
```bash
# Mix local builds and specific remote versions
MS_USER_TAG=develop docker compose -f ../ci-tools/docker-compose.yml -f docker-compose.override.yml --profile local-ms-post up --build
```

## 📊 Observability Stack

### Available UIs

| Service        | URL                                              | Description                                       |
| -------------- | ------------------------------------------------ | ------------------------------------------------- |
| **Grafana**    | [http://localhost:3000](http://localhost:3000)   | Dashboards & Status Page (Admin: `admin`/`admin`) |
| **Jaeger UI**  | [http://localhost:16686](http://localhost:16686) | Trace visualization and search                    |
| **Prometheus** | [http://localhost:9090](http://localhost:9090)   | Metrics exploration & scraping                    |

### 🏗️ Architecture

```
Your App ──OTLP──▶ OTel Collector ──OTLP──▶ Jaeger
    │               (localhost:4317)          (localhost:16686)
    │
    └─▶ Databases ◀──Prometheus (Scraping) ◀──Grafana (Dashboard)
        (PG/Neo4j)      (localhost:9090)        (localhost:3000)
```

The **OTel Collector** receives traces via OTLP and forwards them to **Jaeger**. **Prometheus** monitors service connectivity via **Blackbox Exporter** (TCP probes) and direct metrics scraping, which are then visualized in **Grafana**.

### 🩺 Health Checks & Status Page

Every service is equipped with automated health checks (`healthcheck`).
A pre-configured **Grafana Status Page** is available at startup, providing:

- **Real-time Status**: UP/DOWN detection for all databases and core services.
- **Uptime History**: State timeline bands showing availability over time.
