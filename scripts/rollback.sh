
#!/bin/bash
set -euo pipefail

ACTIVE=$(python3 -c '
import json
import urllib.request

with urllib.request.urlopen("http://localhost:8080/", timeout=5) as response:
    print(json.load(response)["environment"])
')

if [[ "$ACTIVE" == "green" ]]; then
    TARGET="blue"
elif [[ "$ACTIVE" == "blue" ]]; then
    TARGET="green"
else
    echo "Error: Unknown production environment: $ACTIVE"
    exit 1
fi

echo "Current production environment: $ACTIVE"
echo "Rollback target: $TARGET"

echo "Checking $TARGET health..."

docker compose exec -T "$TARGET" \
    python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=5)"

echo "Rolling back production traffic..."

./scripts/switch.sh "$TARGET"

echo "Verifying rollback..."

TARGET="$TARGET" python3 -c '
import json
import os
import urllib.request

with urllib.request.urlopen("http://localhost:8080/", timeout=5) as response:
    data = json.load(response)

assert data["environment"] == os.environ["TARGET"], (
    f"Rollback verification failed: {data}"
)

print(f"Rollback successful: {data}")
'

echo "Rollback completed successfully."

