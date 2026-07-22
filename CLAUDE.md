## CI/CD central du projet

`ci-tools` héberge les Actions composites et workflows réutilisables GitHub Actions appelés par tous les autres repos (`ms-*`, `api-gateway`, `npm-packages`, `nativapp`) — pas de logique métier ici.

- **Workflows par microservice** : `service-ci.yml` (lint/tests/couverture), `service-docker-smoke.yml` (healthcheck en conteneur isolé), `service-docker-build-push.yml` (build + push GHCR).
- **E2E multi-repo** : `e2e-orchestrator.yml` démarre l'écosystème complet (DB + tous les MS) pour exécuter la suite E2E ; `e2e-matrix-checker.yml` bloque une PR qui pointerait sur des images de test/feature sur `main`.
- **`npm-packages`** : pipeline Changesets dédié (`npm-packages-pipeline.yml`, `npm-packages-release.yml`, `npm-packages-emergency-release.yml`).

Toute modification d'un workflow ici a un impact multi-repo immédiat — vérifier quels repos consomment le workflow avant de changer sa signature d'input.

## 🚀 RTK - Rust Token Killer (Optimized)
All shell commands (`git`, `npm`, `jest`, etc.) are automatically proxied via `rtk` for 80% token savings.
- **Direct Usage:** `rtk gain` (analytics), `rtk discover` (missed savings).
- **Files:** Use `rtk read <file>`, `rtk ls`, `rtk find`, `rtk grep` for compressed agent output.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
