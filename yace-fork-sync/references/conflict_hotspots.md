# Conflict Hotspots Reference

Detailed guidance for resolving merge conflicts when syncing with upstream.

## Table of Contents

- [pkg/config/config.go](#pkgconfigconfiggo)
- [pkg/model/model.go](#pkgmodelmodelgo)
- [pkg/job/scrape.go](#pkgjobscrapego)
- [pkg/clients/factory.go](#pkgclientsfactorygo)
- [pkg/job/discovery.go](#pkgjobdiscoverygo)
- [pkg/job/custom.go](#pkgjobcustomgo)
- [pkg/promutil/migrate.go](#pkgpromutilmigratego)

---

## pkg/config/config.go

### Fork Changes

1. **ScrapeConf struct** - Added fields:
   ```go
   LinkedAccounts    LinkedAccountsConfig `yaml:"linkedAccounts"`
   OAMSinkIdentifier string               `yaml:"oamSinkIdentifier"` // deprecated
   OAMRegion         string               `yaml:"oamRegion"`         // deprecated
   ```

2. **New types added**:
   ```go
   type LinkedAccountsOAM struct {
       SinkIdentifier string `yaml:"sinkIdentifier"`
       Region         string `yaml:"region"`
   }

   type LinkedAccountsConfig struct {
       OAM LinkedAccountsOAM `yaml:"oam"`
   }
   ```

3. **Job struct** - Added field:
   ```go
   IncludeLinkedAccounts []string `yaml:"includeLinkedAccounts"`
   ```

4. **CustomNamespace struct** - Added field:
   ```go
   IncludeLinkedAccounts []string `yaml:"includeLinkedAccounts"`
   ```

5. **toModelConfig()** - Added OAM config mapping and `IncludeLinkedAccounts` for discovery and custom namespace jobs

### Resolution Strategy

- Keep all `LinkedAccounts*` fields in structs
- Keep `IncludeLinkedAccounts` field in Job and CustomNamespace
- In `toModelConfig()`: preserve OAM config mapping block and `IncludeLinkedAccounts` assignments
- Watch for: new fields added to same structs by upstream

---

## pkg/model/model.go

### Fork Changes

1. **JobsConfig struct** - Added:
   ```go
   OAMSinkIdentifier string
   OAMRegion         string
   ```

2. **DiscoveryJob struct** - Added:
   ```go
   IncludeLinkedAccounts []string
   ```

3. **CustomNamespaceJob struct** - Added:
   ```go
   IncludeLinkedAccounts []string
   ```

4. **Metric struct** - Added:
   ```go
   LinkedAccountID string
   ```

5. **CloudwatchData struct** - Added:
   ```go
   LinkedAccountID    string
   LinkedAccountAlias string
   ```

### Resolution Strategy

- Keep all added fields in their respective structs
- Watch for: upstream adding fields to same structs (add ours after theirs)
- Watch for: struct field reordering (maintain logical grouping)

---

## pkg/job/scrape.go

### Fork Changes

In `ScrapeAwsData()` function, added OAM resolver initialization blocks:

1. **Discovery jobs section** (~line 86-95):
   ```go
   var linkedAliasResolver *linkedAccountAliasResolver
   if len(discoveryJob.IncludeLinkedAccounts) > 0 && jobsCfg.OAMSinkIdentifier != "" {
       oamRegion := jobsCfg.OAMRegion
       if oamRegion == "" {
           oamRegion = region
       }
       linkedAliasResolver = newLinkedAccountAliasResolver(jobLogger, factory.GetOAMClient(oamRegion, role), jobsCfg.OAMSinkIdentifier)
   }
   ```

2. **runDiscoveryJob call** - Added `linkedAliasResolver` parameter

3. **Custom namespace jobs section** (~line 189-199): Same pattern as discovery jobs

4. **runCustomNamespaceJob call** - Added `linkedAliasResolver` parameter

### Resolution Strategy

- Keep OAM resolver initialization blocks before `runDiscoveryJob` and `runCustomNamespaceJob` calls
- If upstream modifies the job loop structure, adapt the OAM blocks to fit
- Watch for: changes to `runDiscoveryJob`/`runCustomNamespaceJob` signatures

---

## pkg/clients/factory.go

### Fork Changes

Added method to Factory interface:
```go
GetOAMClient(region string, role model.Role) oam.Client
```

### Resolution Strategy

- Keep `GetOAMClient` method in interface
- Watch for: new methods added to Factory interface (add ours alongside)

---

## pkg/job/discovery.go

### Fork Changes

1. **runDiscoveryJob signature** - Added parameter:
   ```go
   linkedAliasResolver *linkedAccountAliasResolver
   ```

2. Internal usage of `linkedAliasResolver` to resolve account aliases

### Resolution Strategy

- Keep the additional parameter in function signature
- Keep internal resolver usage
- Watch for: signature changes or refactoring of this function

---

## pkg/job/custom.go

### Fork Changes

1. **runCustomNamespaceJob signature** - Added parameter:
   ```go
   linkedAliasResolver *linkedAccountAliasResolver
   ```

2. Internal usage of `linkedAliasResolver`

### Resolution Strategy

- Same as discovery.go - keep parameter and internal usage
- Watch for: function signature changes

---

## pkg/promutil/migrate.go

### Fork Changes

Added linked account label handling in metric migration:
- `LinkedAccountID` label
- `LinkedAccountAlias` label

### Resolution Strategy

- Keep linked account label handling code
- Watch for: changes to label processing logic or new labels added

---

## General Conflict Resolution Tips

1. **Accept upstream first, then re-add fork changes**: When in doubt, accept upstream's version and manually re-add fork-specific code

2. **Check function signatures**: If upstream changed a function signature we also modified, update our calls accordingly

3. **Run tests after each conflict resolution**: `go test ./pkg/job/... -run LinkedAccount` to verify linked accounts feature

4. **New upstream fields go first**: When both add fields to same struct, put upstream's fields before ours for cleaner history
