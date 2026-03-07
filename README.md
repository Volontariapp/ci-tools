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

#### 🗄️ Databases

We use a dedicated pair of PostgreSQL and Neo4j for each microservice to ensure complete isolation:

| Service    | Postgres Port | Neo4j (HTTP/Bolt) |
| ---------- | ------------- | ----------------- |
| `ms-user`  | `5432`        | `7474` / `7687`   |
| `ms-post`  | `5433`        | `7475` / `7688`   |
| `ms-event` | `5434`        | `7476` / `7689`   |

#### 📊 Observability Stack

The monitoring stack includes **Grafana**, **Prometheus**, **OpenTelemetry Collector**, and **Jaeger**.
These services are placed behind a Docker Compose **profile** called `monitoring`.

##### Starting the stack

```bash
# Start only databases
docker compose up -d

# Start databases + monitoring stack
docker compose --profile monitoring up -d
```

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
