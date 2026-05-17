# CI Tools

This repository acts as the central hub for Volontariapp's Continuous Integration (CI) and Continuous Deployment (CD) workflows.
It houses all the reusable GitHub Actions, workflows, and global synchronized logic for our microservices and shared libraries.

## 🎯 Purpose

In an umbrella architecture containing several microservices (e.g. `api-gateway`, `ms-user`, `npm-packages`), duplicating GitHub workflow files generates an immense amount of technical debt.
This `ci-tools` repository solves this by extracting the common CI configuration into a single place. All other repositories within the project merely reference the workflows stored here.

## 📦 What's Inside?

### Reusable Workflows (`.github/workflows/`)

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

### Infrastructure & Monitoring (`docker-compose.yml`)

This repository includes a complete local development infrastructure and observability stack.

#### 🗄️ Databases & Services

All services share a unified `volontariapp-network` for seamless local development and database inspection. Each microservice is configured via discrete environment variables (`DB_HOST`, `DB_PORT`, etc.) rather than a single URL.

| Service       | Postgres Port | Neo4j (HTTP/Bolt) |
| ------------- | ------------- | ----------------- |
| `ms-user`     | `5432`        | -                 |
| `ms-post`     | `5433`        | -                 |
| `ms-event`    | `5434`        | -                 |
| `ms-social`   | `5435`        | `7474` / `7687`   |

#### 🚀 Getting Started

To start the entire ecosystem:

```bash
docker compose up -d
```

#### 🌿 Hybrid CI / Development Strategy

This stack uses a **Hybrid Strategy** designed for high-performance CI/CD. By default, all services pull their `latest` image from **GHCR** (representing the `main` branch). This allows you to test a single service without building the entire ecosystem.

To build a specific service from source (local or remote), you can override its **Build Context**.

| Variable               | Description                                           | Default (GHCR Image) |
| ---------------------- | ----------------------------------------------------- | -------------------- |
| `API_GATEWAY_CONTEXT`  | Build context for `api-gateway`                       | `latest` image       |
| `MS_USER_CONTEXT`      | Build context for `ms-user`                           | `latest` image       |
| `MS_POST_CONTEXT`      | Build context for `ms-post`                           | `latest` image       |
| `MS_EVENT_CONTEXT`     | Build context for `ms-event`                          | `latest` image       |
| `MS_SOCIAL_CONTEXT`    | Build context for `ms-social`                         | `latest` image       |

**Example: Build a service locally**

In a microservice repository, you can build it from local code while pulling others from GHCR:

```bash
MS_POST_CONTEXT=. docker compose up -d --build --wait
```

**Example: Build from a specific remote branch**

```bash
MS_USER_CONTEXT=https://github.com/Volontariapp/ms-user.git#feat/new-auth docker compose up -d --build --wait
```

#### 📊 Observability Stack

##### Available UIs

| Service        | URL                                              | Description                                       |
| -------------- | ------------------------------------------------ | ------------------------------------------------- |
| **Grafana**    | [http://localhost:3000](http://localhost:3000)   | Dashboards & Status Page (Admin: `admin`/`admin`) |
| **Jaeger UI**  | [http://localhost:16686](http://localhost:16686) | Trace visualization and search                    |
| **Prometheus** | [http://localhost:9090](http://localhost:9090)   | Metrics exploration & scraping                    |

#### 🩺 Health Checks & Status Page

Every service is equipped with automated health checks (`healthcheck`).
A pre-configured **Grafana Status Page** is available at startup, providing:

- **Real-time Status**: UP/DOWN detection for all databases and core services.
- **Uptime History**: State timeline bands showing availability over time.

#### 🏗️ Architecture

```
Your App ──OTLP──▶ OTel Collector ──OTLP──▶ Jaeger
    │               (localhost:4317)          (localhost:16686)
    │
    └─▶ Databases ◀──Prometheus (Scraping) ◀──Grafana (Dashboard)
        (PG/Neo4j)      (localhost:9090)        (localhost:3000)
```

The **OTel Collector** receives traces via OTLP and forwards them to **Jaeger**. **Prometheus** monitors service connectivity via **Blackbox Exporter** (TCP probes) and direct metrics scraping, which are then visualized in **Grafana**.
