
#!/bin/bash
set -euo pipefail


TARGET="${1:-}"

if [[ "$TARGET" != "blue" && "$TARGET" != "green" ]]; then
    echo "Usage: ./scripts/switch.sh [blue|green]"
    exit 1
fi


CADDY_ID=$(docker compose ps -q caddy)

if [[ -z "$CADDY_ID" ]]; then
    echo "Error: Caddy is not running."
    exit 1
fi

echo "Checking $TARGET health..."

docker compose exec -T "$TARGET" \
    python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=5)"

echo "Switching traffic to $TARGET..."

docker run --rm \
    --network "container:$CADDY_ID" \
    curlimages/curl:latest \
    -fsS -X PATCH \
    -H "Content-Type: application/json" \
    -d "{\"dial\":\"$TARGET:8000\"}" \
    "http://localhost:2019/config/apps/http/servers/srv0/routes/0/handle/0/upstreams/0"

echo "Verifying production traffic..."

TARGET="$TARGET" python3 -c '
import json
import os
import urllib.request

with urllib.request.urlopen("http://localhost:8080/", timeout=5) as response:
    data = json.load(response)

assert data["environment"] == os.environ["TARGET"], (
    f"Unexpected environment: {data}"
)

print(f"Production is now routing to {data["environment"]}, version {data["version"]}")
'
