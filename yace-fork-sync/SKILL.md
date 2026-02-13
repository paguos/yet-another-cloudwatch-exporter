---
name: yace-fork-sync
description: Maintain and sync this YACE fork with upstream prometheus-community/yet-another-cloudwatch-exporter. Use when syncing with upstream, resolving merge conflicts, verifying fork integrity after sync, checking upstream changes, or setting up fork maintenance. Triggers on requests about upstream sync, rebase, merge conflicts, or fork maintenance.
---

# YACE Fork Sync

Maintain this fork that adds Linked Accounts (OAM) support on top of upstream.

## Fork Overview

| | |
|---|---|
| **Upstream** | https://github.com/prometheus-community/yet-another-cloudwatch-exporter |
| **Feature** | AWS Linked Accounts via OAM (Organization Account Manager) |
| **Changes** | ~1300 lines, 3 commits |

Fork adds:
- `IncludeLinkedAccounts` config for discovery/custom namespace jobs
- OAM client for linked account alias resolution (`pkg/clients/oam/`)
- `linkedAccounts` top-level config block
- `cmd/oam-linked-accounts-check` utility CLI

## Quick Commands

```bash
# First-time setup
./yace-fork-sync/scripts/setup_upstream.sh

# Check what changed upstream
./yace-fork-sync/scripts/check_upstream.sh

# Verify after sync
./yace-fork-sync/scripts/verify_sync.sh
```

## Sync Workflow

### 1. Check Upstream

```bash
./yace-fork-sync/scripts/check_upstream.sh
```

Shows commit count, new commits, and warnings if hotspot files were modified.

### 2. Sync (Rebase - Preferred)

```bash
git fetch upstream
git checkout master
git rebase upstream/master
# Resolve conflicts - see references/conflict_hotspots.md
git push origin master --force-with-lease
```

### 3. Sync (Merge - Alternative)

```bash
git fetch upstream
git checkout master
git merge upstream/master
# Resolve conflicts
git push origin master
```

### 4. Verify

```bash
./yace-fork-sync/scripts/verify_sync.sh
```

## Conflict Hotspots

Files likely to conflict. See `references/conflict_hotspots.md` for detailed resolution guidance.

| File | Fork Changes |
|------|--------------|
| `pkg/config/config.go` | `LinkedAccountsConfig`, `IncludeLinkedAccounts` fields, `toModelConfig()` |
| `pkg/model/model.go` | `OAMSinkIdentifier`, `LinkedAccountID`, `LinkedAccountAlias` fields |
| `pkg/job/scrape.go` | OAM resolver initialization in `ScrapeAwsData()` |
| `pkg/clients/factory.go` | `GetOAMClient()` interface method |
| `pkg/job/discovery.go` | `linkedAliasResolver` parameter added |
| `pkg/job/custom.go` | `linkedAliasResolver` parameter added |
| `pkg/promutil/migrate.go` | Linked account label handling |

**Fork-only files (no conflicts):** `pkg/clients/oam/`, `pkg/job/linked_account_alias.go`, `cmd/oam-linked-accounts-check/`

## Post-Conflict Checks

```bash
# Build and test
make build && make test

# Feature-specific tests
go test -v ./pkg/job/... -run LinkedAccount
go test -v ./pkg/clients/oam/...
```

## Resources

- `scripts/setup_upstream.sh` - Add upstream remote (run once)
- `scripts/check_upstream.sh` - Preview upstream changes before sync
- `scripts/verify_sync.sh` - Full verification after sync
- `references/conflict_hotspots.md` - Detailed conflict resolution for each file
