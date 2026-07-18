#!/bin/bash

echo "Nuking ms_event database..."
docker exec postgres-event psql -U user -d ms_event -c 'TRUNCATE TABLE events CASCADE;'

echo "Nuking ms_social neo4j database..."
docker exec neo4j-social cypher-shell -u neo4j -p password "MATCH (n) DETACH DELETE n"

echo "Nuking ms_user database..."
docker exec postgres-user psql -U user -d ms_user -c 'TRUNCATE TABLE users CASCADE;' || true

echo "Nuking ms_post database..."
docker exec postgres-post psql -U user -d ms_post -c 'TRUNCATE TABLE posts CASCADE;' || true

echo "All databases wiped successfully."
