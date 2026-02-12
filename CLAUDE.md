# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

YACE (Yet Another CloudWatch Exporter) is a Prometheus exporter for AWS CloudWatch metrics, written in Go. It auto-discovers AWS resources via tags and exports their CloudWatch metrics in Prometheus format. Part of prometheus-community since November 2024.

## Build and Development Commands

```bash
# Build the binary
make build

# Run linting (uses golangci-lint)
make lint

# Run all tests (includes race detection on amd64)
make test

# Run a single test
go test -v -run TestName ./path/to/package

# Format code
make format

# Verify go.mod is tidy
make unused

# Build Docker image (multi-arch: amd64, armv7, arm64)
make docker

# Run locally after building
./yace -config.file=config.yml
```

## Architecture

### Data Flow

```
HTTP GET /metrics → Scraper → Prometheus Registry (pre-computed)
                         ↑
              Background scraping (every 300s default)
                         ↓
         exporter.UpdateMetrics() → job.ScrapeAwsData()
                                          ↓
              ┌──────────────────────────────────────────┐
              │  Discovery Jobs: ListMetrics → Tags →   │
              │                  GetMetricData          │
              │  Static Jobs: GetMetricData             │
              │  Custom Namespace Jobs: ListMetrics →   │
              │                         GetMetricData   │
              │  Enhanced Metrics: DynamoDB, RDS,       │
              │                    Lambda, ElastiCache  │
              └──────────────────────────────────────────┘
```

### Key Packages

- **cmd/yace**: Entry point, HTTP server, CLI (urfave/cli), scraper with atomic registry swap
- **pkg/exporter.go**: Main orchestrator `UpdateMetrics()` - transforms CloudWatch data to Prometheus metrics
- **pkg/job/**: Job execution engine - discovery, static, custom namespace jobs run in parallel
- **pkg/clients/**: AWS client abstractions with Factory pattern; supports both AWS SDK v1 and v2 (v2 default)
- **pkg/config/**: YAML configuration parsing and validation
- **pkg/model/**: Domain data structures (jobs, metrics, tags, dimensions)
- **pkg/promutil/**: CloudWatch to Prometheus metric conversion and collector implementation

### AWS SDK Versions

YACE uses AWS SDK v2 by default (since 2021). SDK v1 available via `-enable-feature=aws-sdk-v1` flag for backward compatibility. Implementations are in `pkg/clients/v1/` and `pkg/clients/v2/`.

### Configuration Types

Three job types in YAML config (`-config.file`):
1. **discovery**: Auto-discover resources via tags, fetch metrics dynamically
2. **static**: Pre-defined resources with explicit dimensions
3. **customNamespace**: Custom CloudWatch namespaces

### Concurrency Model

- Decoupled scraping runs in background at configurable interval (default 300s)
- Semaphore prevents concurrent scrapes
- AWS API concurrency: `-cloudwatch-concurrency` (default 5), `-tag-concurrency` (default 5)
- Per-API limits available via `-cloudwatch-concurrency.per-api-limit-enabled`

## Code Patterns

- **Factory Pattern**: `clients.Factory` creates AWS clients with lazy initialization
- **Options Pattern**: `OptionsFunc` for configuring exporter behavior
- **Atomic Registry Swap**: Zero-downtime metric updates via `go.uber.org/atomic`
- **Goroutines + WaitGroups**: Parallel job execution across regions and accounts

## Testing

Tests use `testify/assert`. AWS clients are mocked for unit tests. Test files are co-located with source files.

```bash
# Run tests for a specific package
go test -v ./pkg/job/...

# Run with race detection
go test -race ./...
```

## Import Ordering

Local imports should use the prefix: `github.com/prometheus-community/yet-another-cloudwatch-exporter`
