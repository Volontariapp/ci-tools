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

This repository includes a complete local development infrastructure and observability stack, optimized for modular testing using **Docker Compose Profiles**.

#### 🗄️ Databases & Services

All services share a unified `volontariapp-network` for seamless local development and database inspection. Each microservice is configured via discrete environment variables (`DB_HOST`, `DB_PORT`, etc.) rather than a single URL.

| Service       | Postgres Port | Neo4j (HTTP/Bolt) | Profile     |
| ------------- | ------------- | ----------------- | ----------- |
| `ms-user`     | `5432`        | -                 | `ms-user`   |
| `ms-post`     | `5433`        | -                 | `ms-post`   |
| `ms-event`    | `5434`        | -                 | `ms-event`  |
| `ms-social`   | `5435`        | `7474` / `7687`   | `ms-social` |

#### 🚀 Modular Startup (Profiles)

The stack is designed to be modular. You can start only the services you need to save resources and focus on a specific microservice.

##### Examples

```bash
# Start a specific microservice stack (includes its DB + Redis + Gateway)
docker compose --profile ms-user up -d

# Start the whole ecosystem
docker compose --profile all up -d

# Start databases + monitoring stack
docker compose --profile all --profile monitoring up -d
```

##### Available Profiles

- **`ms-user`**: Starts `api-gateway`, `ms-user`, `postgres-user`, and `redis`.
- **`ms-post`**: Starts `api-gateway`, `ms-post`, `postgres-post`, and `redis`.
- **`ms-event`**: Starts `api-gateway`, `ms-event`, `postgres-event`, and `redis`.
- **`ms-social`**: Starts `api-gateway`, `ms-social`, `postgres-social`, `neo4j-social`, and `redis`.
- **`all`**: Starts every microservice and its respective database.
- **`monitoring`**: Starts the observability stack (Grafana, Jaeger, OTel, Prometheus).

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
