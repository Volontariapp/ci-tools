#!/bin/bash
# Collect what is needed to debug a failed E2E run of the async pipeline:
# container logs, outbox tables of every domain database, Redis stream lengths (DLQs included).
# Usage: ./ci-tools/scripts/e2e-collect-diagnostics.sh <output-dir>
# Never fails: a missing table or a stopped container must not hide the other diagnostics.

OUT_DIR=${1:-e2e-diagnostics}
COMPOSE_FILE=${COMPOSE_FILE:-ci-tools/docker-compose.yml}
COMPOSE=(docker compose -f "$COMPOSE_FILE" --profile e2e)

mkdir -p "$OUT_DIR/logs" "$OUT_DIR/db"

"${COMPOSE[@]}" ps --all > "$OUT_DIR/ps.txt" 2>&1

for svc in $("${COMPOSE[@]}" config --services); do
  "${COMPOSE[@]}" logs --no-color --timestamps "$svc" > "$OUT_DIR/logs/$svc.log" 2>&1
done

# One Postgres container per domain: postgres-<x> holds database ms_<x>.
for pg in $("${COMPOSE[@]}" config --services | grep -E '^postgres-'); do
  db="ms_${pg#postgres-}"
  for table in event_queue jobs_outbox job_audit; do
    "${COMPOSE[@]}" exec -T "$pg" psql -U user -d "$db" -c \
      "SELECT * FROM $table ORDER BY 1 DESC LIMIT 200" > "$OUT_DIR/db/$db.$table.txt" 2>&1
  done
done

# Open Scatter-Gather sagas of ws-service: a row left here means a feedback event never came.
"${COMPOSE[@]}" exec -T postgres-ws psql -U user -d ms_ws -c \
  "SELECT * FROM gather_state ORDER BY 1 DESC LIMIT 200" > "$OUT_DIR/db/ms_ws.gather_state.txt" 2>&1

{
  for key in $("${COMPOSE[@]}" exec -T redis redis-cli -a password --no-auth-warning --scan --type stream); do
    echo "$key $("${COMPOSE[@]}" exec -T redis redis-cli -a password --no-auth-warning XLEN "$key")"
  done
} > "$OUT_DIR/redis-streams.txt" 2>&1

echo "E2E diagnostics written to $OUT_DIR"
exit 0
