#!/usr/bin/env bash
# docker.sh — Docker utility functions for tests

# Get container status
container_status() {
  local name="$1"
  docker inspect -f '{{.State.Status}}' "$name" 2>/dev/null || echo "not-found"
}

# Get container health
container_health() {
  local name="$1"
  docker inspect -f '{{.State.Health.Status}}' "$name" 2>/dev/null || echo "none"
}

# Wait for container to be healthy
wait_for_healthy() {
  local name="$1"
  local timeout="${2:-60}"
  local elapsed=0
  
  while [[ $elapsed -lt $timeout ]]; do
    local health=$(container_health "$name")
    if [[ "$health" == "healthy" ]]; then
      return 0
    fi
    sleep 2
    ((elapsed += 2)) || true
  done
  
  return 1
}

# Get container logs
container_logs() {
  local name="$1"
  local lines="${2:-20}"
  docker logs --tail "$lines" "$name" 2>&1
}

# Check if port is listening
port_listening() {
  local port="$1"
  docker exec root-test sh -c "nc -z localhost $port" 2>/dev/null || \
    docker run --rm --network container:root-test alpine nc -z localhost "$port" 2>/dev/null || \
    echo "not-listening"
}

# Get all container names for a stack
stack_containers() {
  local compose_file="$1"
  docker compose -f "$compose_file" ps --format json 2>/dev/null | \
    jq -r '.[].Name' 2>/dev/null || echo ""
}