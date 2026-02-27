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

### Monitoring (`docker-compose.yml`)

The repository includes a pre-configured observability stack using **OpenTelemetry Collector** and **Jaeger v2**.
Both services are placed behind a Docker Compose **profile** called `monitoring`, meaning they will **not** start with a regular `docker compose up`.

#### Starting the monitoring stack

```bash
docker compose --profile monitoring up -d
```

#### Stopping the monitoring stack

```bash
docker compose --profile monitoring down
```

#### Available UIs

| Service | URL | Description |
|---------|-----|-------------|
| Jaeger UI | [http://localhost:16686](http://localhost:16686) | Trace visualization and search |

#### Architecture

```
Your App ──OTLP──▶ OTel Collector ──OTLP──▶ Jaeger
                   (localhost:4317)          (localhost:16686)
```

The **OTel Collector** receives traces, metrics, and logs via OTLP (gRPC `:4317` / HTTP `:4318`), then forwards traces to **Jaeger** for visualization. The collector configuration lives in `monitoring/otel-collector-config.yaml`.