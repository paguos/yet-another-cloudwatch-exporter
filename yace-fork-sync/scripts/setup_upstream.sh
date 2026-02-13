#!/bin/bash
# Setup upstream remote for YACE fork
# Run once to configure the upstream remote

set -e

UPSTREAM_URL="https://github.com/prometheus-community/yet-another-cloudwatch-exporter.git"

if git remote | grep -q "^upstream$"; then
    echo "Upstream remote already exists:"
    git remote get-url upstream
else
    git remote add upstream "$UPSTREAM_URL"
    echo "Added upstream remote: $UPSTREAM_URL"
fi

echo ""
echo "Fetching upstream..."
git fetch upstream

echo ""
echo "Current remotes:"
git remote -v
