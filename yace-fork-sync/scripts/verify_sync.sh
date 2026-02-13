#!/bin/bash
# Verify YACE fork sync was successful
# Run after completing a rebase or merge with upstream

set -e

echo "=== Post-Sync Verification ==="
echo ""

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "WARNING: Uncommitted changes detected"
    git status --short
    echo ""
fi

# Build
echo "=== Building ==="
if make build; then
    echo "Build: PASSED"
else
    echo "Build: FAILED"
    exit 1
fi
echo ""

# Lint
echo "=== Linting ==="
if make lint; then
    echo "Lint: PASSED"
else
    echo "Lint: FAILED"
    exit 1
fi
echo ""

# Run all tests
echo "=== Running Tests ==="
if make test; then
    echo "Tests: PASSED"
else
    echo "Tests: FAILED"
    exit 1
fi
echo ""

# Verify linked accounts feature specifically
echo "=== Linked Accounts Feature Tests ==="
if go test -v ./pkg/job/... -run LinkedAccount 2>&1 | tail -10; then
    echo "Linked Accounts Tests: PASSED"
else
    echo "Linked Accounts Tests: FAILED"
    exit 1
fi
echo ""

if go test -v ./pkg/clients/oam/... 2>&1 | tail -5; then
    echo "OAM Client Tests: PASSED"
else
    echo "OAM Client Tests: FAILED"
    exit 1
fi
echo ""

# Verify fork-specific files exist
echo "=== Fork-Specific Files Check ==="
FORK_FILES=(
    "cmd/oam-linked-accounts-check/main.go"
    "pkg/clients/oam/client.go"
    "pkg/job/linked_account_alias.go"
    "pkg/config/testdata/include_linked_accounts.ok.yml"
)

ALL_EXIST=1
for file in "${FORK_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "EXISTS: $file"
    else
        echo "MISSING: $file"
        ALL_EXIST=0
    fi
done

if [ "$ALL_EXIST" -eq 1 ]; then
    echo ""
    echo "All fork-specific files present"
fi

echo ""
echo "=== Verification Complete ==="
