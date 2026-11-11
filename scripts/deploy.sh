
#!/bin/bash
set -euo pipefail


TARGET="${1:-}"

if [[ "$TARGET" != "blue" && "$TARGET" != "green" ]]; then
    echo "Usage: ./scripts/deploy.sh [blue|green]"
    exit 1
fi

ACTIVE=$(python3 -c '
import json
import urllib.request

with urllib.request.urlopen("http://localhost:8080/", timeout=5) as response:
    print(json.load(response)["environment"])
')

if [[ "$TARGET" == "$ACTIVE" ]]; then
    echo "Error: Cannot deploy to active production ($ACTIVE)."
    exit 1
fi

echo "Active environment: $ACTIVE"
echo "Deploying to inactive environment: $TARGET"

docker compose build "$TARGET"

docker compose up -d --no-deps --force-recreate "$TARGET"

echo "Waiting for $TARGET to become healthy..."

HEALTHY=false

for attempt in {1..15}; do
    if docker compose exec -T "$TARGET" \
        python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=3)" \
        >/dev/null 2>&1; then
        HEALTHY=true
        break
    fi

    echo "Health check $attempt/15 failed. Retrying..."
    sleep 2
done

if [[ "$HEALTHY" != "true" ]]; then
    echo "Error: $TARGET failed health checks."
    exit 1
fi

echo "Deployment to $TARGET completed successfully."
echo "The production environment is still $ACTIVE."
echo "Run ./scripts/switch.sh $TARGET after approval."
