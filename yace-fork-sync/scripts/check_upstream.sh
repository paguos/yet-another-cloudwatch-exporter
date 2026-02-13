#!/bin/bash
# Check upstream changes before syncing YACE fork
# Shows commits and file changes since last sync

set -e

# Ensure upstream is fetched
git fetch upstream 2>/dev/null || {
    echo "Error: upstream remote not found. Run setup_upstream.sh first."
    exit 1
}

CURRENT_BRANCH=$(git branch --show-current)
BASE_BRANCH="${1:-master}"

echo "=== Upstream Changes Analysis ==="
echo "Current branch: $CURRENT_BRANCH"
echo "Comparing: $BASE_BRANCH..upstream/master"
echo ""

# Count commits
COMMIT_COUNT=$(git rev-list --count "$BASE_BRANCH..upstream/master" 2>/dev/null || echo "0")
echo "Commits to sync: $COMMIT_COUNT"
echo ""

if [ "$COMMIT_COUNT" -eq 0 ]; then
    echo "Already up to date with upstream."
    exit 0
fi

# Show commits
echo "=== New Upstream Commits ==="
git log "$BASE_BRANCH..upstream/master" --oneline | head -30
echo ""

# Check for conflicts in hotspot files
echo "=== Hotspot Files Analysis ==="
HOTSPOTS=(
    "pkg/config/config.go"
    "pkg/job/scrape.go"
    "pkg/model/model.go"
    "pkg/clients/factory.go"
    "pkg/job/discovery.go"
    "pkg/job/custom.go"
    "pkg/promutil/migrate.go"
)

CONFLICTS_LIKELY=0
for file in "${HOTSPOTS[@]}"; do
    if git diff "$BASE_BRANCH..upstream/master" --stat | grep -q "$file"; then
        echo "WARNING: $file modified upstream (potential conflict)"
        CONFLICTS_LIKELY=1
    fi
done

if [ "$CONFLICTS_LIKELY" -eq 0 ]; then
    echo "No hotspot files modified - sync should be clean"
fi

echo ""
echo "=== Full Diff Stats ==="
git diff "$BASE_BRANCH..upstream/master" --stat | tail -20
