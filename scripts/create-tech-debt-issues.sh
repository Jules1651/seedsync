#!/bin/bash
# Script to create GitHub Issues for Technical Debt Remediation
#
# Prerequisites:
#   1. Install gh CLI: https://cli.github.com/
#   2. Authenticate: gh auth login
#   3. Run from the seedsync repo directory
#
# Usage: ./scripts/create-tech-debt-issues.sh

set -e

echo "Creating labels for technical debt tracking..."

# Create labels (will skip if they already exist)
gh label create "technical-debt" --description "Technical debt items" --color "d93f0b" 2>/dev/null || echo "Label 'technical-debt' already exists"
gh label create "priority:critical" --description "Critical priority" --color "b60205" 2>/dev/null || echo "Label 'priority:critical' already exists"
gh label create "priority:high" --description "High priority" --color "d93f0b" 2>/dev/null || echo "Label 'priority:high' already exists"
gh label create "priority:medium" --description "Medium priority" --color "fbca04" 2>/dev/null || echo "Label 'priority:medium' already exists"
gh label create "phase:1-cicd" --description "Phase 1: CI/CD" --color "0e8a16" 2>/dev/null || echo "Label 'phase:1-cicd' already exists"
gh label create "phase:2-memory" --description "Phase 2: Memory Leaks" --color "1d76db" 2>/dev/null || echo "Label 'phase:2-memory' already exists"
gh label create "phase:3-tests" --description "Phase 3: Test Modernization" --color "5319e7" 2>/dev/null || echo "Label 'phase:3-tests' already exists"
gh label create "phase:4-rxjs" --description "Phase 4: RxJS Updates" --color "006b75" 2>/dev/null || echo "Label 'phase:4-rxjs' already exists"
gh label create "phase:5-python" --description "Phase 5: Python Refactor" --color "0052cc" 2>/dev/null || echo "Label 'phase:5-python' already exists"
gh label create "phase:6-deps" --description "Phase 6: Dependencies" --color "c5def5" 2>/dev/null || echo "Label 'phase:6-deps' already exists"
gh label create "phase:7-linting" --description "Phase 7: Linting" --color "bfdadc" 2>/dev/null || echo "Label 'phase:7-linting' already exists"
gh label create "phase:8-angular" --description "Phase 8: Angular Upgrade" --color "d4c5f9" 2>/dev/null || echo "Label 'phase:8-angular' already exists"

echo ""
echo "Creating issues..."

# Phase 1: CI/CD Fixes
gh issue create \
  --title "Phase 1: CI/CD Fixes - Update Deprecated GitHub Actions" \
  --label "technical-debt,priority:high,phase:1-cicd" \
  --body "$(cat <<'EOF'
## Overview
Update deprecated GitHub Actions in the CI/CD pipeline.

## Chunks

### Chunk 1.1: Update GitHub Release Actions
**File**: `.github/workflows/master.yml` (lines 254-265)

Replace deprecated actions:
- `actions/create-release@v1`
- `actions/upload-release-asset@v1`

**Replace with**:
```yaml
- name: Create Release and Upload Asset
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    gh release create ${{ github.ref_name }} \
      --title "${{ github.ref_name }}" \
      --generate-notes \
      ./seedsync.deb#seedsync_${{ env.VERSION }}.deb
```

- [ ] Update release action
- [ ] Test with a draft release

### Chunk 1.2: Audit Remaining CI Deprecations
- [ ] Check for deprecated `set-output` commands (use `$GITHUB_OUTPUT`)
- [ ] Check for deprecated `save-state` commands
- [ ] Verify Node.js version is current (20.x)

## Verification
Push a test tag to verify release creation works.

## Test Commands
```bash
# Manually trigger workflow or push a tag
git tag -a v0.0.0-test -m "Test release"
git push origin v0.0.0-test
# Then delete: git push origin --delete v0.0.0-test
```
EOF
)"

echo "Created Phase 1 issue"

# Phase 2: Memory Leak Prevention
gh issue create \
  --title "Phase 2: Memory Leak Prevention - Add OnDestroy/Unsubscribe Patterns" \
  --label "technical-debt,priority:critical,phase:2-memory" \
  --body "$(cat <<'EOF'
## Overview
There are **171 `.subscribe()` calls** across the Angular codebase with **ZERO OnDestroy implementations**. This causes memory leaks when components are destroyed.

## Pattern to Implement
```typescript
import { Injectable, OnDestroy } from '@angular/core';
import { Subject } from 'rxjs/Subject';
import { takeUntil } from 'rxjs/operators';

@Injectable()
export class SomeService implements OnDestroy {
  private destroy$ = new Subject<void>();

  constructor(private otherService: OtherService) {
    this.otherService.data$
      .pipe(takeUntil(this.destroy$))
      .subscribe(data => this.handleData(data));
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
```

## Chunks

### Chunk 2.1: Core File Services
- [ ] `src/angular/src/app/services/files/view-file.service.ts`
- [ ] `src/angular/src/app/services/files/model-file.service.ts`

### Chunk 2.2: AutoQueue and Config Services
- [ ] `src/angular/src/app/services/autoqueue/autoqueue.service.ts`
- [ ] `src/angular/src/app/services/settings/config.service.ts`

### Chunk 2.3: Server Services
- [ ] `src/angular/src/app/services/server/server-status.service.ts`
- [ ] `src/angular/src/app/services/server/server-command.service.ts`

### Chunk 2.4: Utility Services
- [ ] `src/angular/src/app/services/utils/notification.service.ts`
- [ ] `src/angular/src/app/services/utils/connected.service.ts`
- [ ] `src/angular/src/app/services/logs/log.service.ts`

## Verification
```bash
make run-tests-angular
```
EOF
)"

echo "Created Phase 2 issue"

# Phase 3: Test Modernization
gh issue create \
  --title "Phase 3: Test Modernization - Update TestBed.get() to TestBed.inject()" \
  --label "technical-debt,priority:high,phase:3-tests" \
  --body "$(cat <<'EOF'
## Overview
Update deprecated `TestBed.get()` API to `TestBed.inject()` in all test files.

> **Note**: `TestBed.inject()` was added in Angular 9. This phase is **BLOCKED** until Phase 8 (Angular Upgrade) reaches Angular 9+.

## Change Pattern
```typescript
// Before
const service = TestBed.get(ViewFileService);

// After
const service = TestBed.inject(ViewFileService);
```

## Chunks

### Chunk 3.1: File Service Tests
- [ ] `src/angular/src/app/tests/unittests/services/files/view-file-filter.service.spec.ts`
- [ ] `src/angular/src/app/tests/unittests/services/files/model-file.service.spec.ts`
- [ ] `src/angular/src/app/tests/unittests/services/files/view-file-options.service.spec.ts`

### Chunk 3.2: More File Service Tests
- [ ] `src/angular/src/app/tests/unittests/services/files/view-file-sort.service.spec.ts`
- [ ] `src/angular/src/app/tests/unittests/services/autoqueue/autoqueue.service.spec.ts`
- [ ] `src/angular/src/app/tests/unittests/services/server/server-command.service.spec.ts`

### Chunk 3.3: Settings and Utils Tests
- [ ] `src/angular/src/app/tests/unittests/services/settings/config.service.spec.ts`
- [ ] `src/angular/src/app/tests/unittests/services/utils/rest.service.spec.ts`

## Dependencies
- **Blocked by**: Phase 8 (Angular Upgrade to v9+)

## Verification
```bash
make run-tests-angular
```
EOF
)"

echo "Created Phase 3 issue"

# Phase 4: RxJS Import Updates
gh issue create \
  --title "Phase 4: RxJS Import Updates - Modernize Import Patterns" \
  --label "technical-debt,priority:high,phase:4-rxjs" \
  --body "$(cat <<'EOF'
## Overview
Update deprecated RxJS import patterns across 35+ files.

## Change Pattern (Angular 4 Compatible)
```typescript
// Before (deprecated)
import {Observable} from "rxjs/Observable";
import {BehaviorSubject} from "rxjs/Rx";

// After (works in RxJS 5.5+ with Angular 4)
import {Observable} from "rxjs/Observable";
import {BehaviorSubject} from "rxjs/BehaviorSubject";
import {Subject} from "rxjs/Subject";
```

> **Note**: Full modern imports (`from "rxjs"`) require RxJS 6+ which needs Angular 6+.

## Chunks

### Chunk 4.1: File Services
- [ ] `src/angular/src/app/services/files/view-file.service.ts`
- [ ] `src/angular/src/app/services/files/model-file.service.ts`
- [ ] `src/angular/src/app/services/files/view-file-filter.service.ts`
- [ ] `src/angular/src/app/services/files/view-file-options.service.ts`
- [ ] `src/angular/src/app/services/files/view-file-sort.service.ts`

### Chunk 4.2: Server Services
- [ ] `src/angular/src/app/services/server/server-status.service.ts`
- [ ] `src/angular/src/app/services/server/server-command.service.ts`

### Chunk 4.3: Settings/Utils Services
- [ ] `src/angular/src/app/services/settings/config.service.ts`
- [ ] `src/angular/src/app/services/utils/notification.service.ts`
- [ ] `src/angular/src/app/services/utils/connected.service.ts`
- [ ] `src/angular/src/app/services/utils/rest.service.ts`
- [ ] `src/angular/src/app/services/logs/log.service.ts`

### Chunk 4.4: Base Services and Mocks
- [ ] `src/angular/src/app/services/base/base-stream.service.ts`
- [ ] `src/angular/src/app/services/base/base-web.service.ts`
- [ ] `src/angular/src/app/tests/mocks/mock-model-file.service.ts`
- [ ] `src/angular/src/app/tests/mocks/mock-view-file.service.ts`
- [ ] `src/angular/src/app/tests/mocks/mock-rest.service.ts`

## Verification
```bash
make run-tests-angular
```
EOF
)"

echo "Created Phase 4 issue"

# Phase 5: Python Refactoring
gh issue create \
  --title "Phase 5: Python Refactoring - Break Down Large Methods" \
  --label "technical-debt,priority:medium,phase:5-python" \
  --body "$(cat <<'EOF'
## Overview
Refactor large Python methods to improve maintainability and testability.

## Chunks

### Chunk 5.1: Refactor Controller.__process_commands()
**File**: `src/python/controller/controller.py`
**Method**: `__process_commands()` (117 lines)

Extract logical sections into smaller private methods:
```python
def __handle_queue_command(self, command: Controller.Command) -> None:
    """Handle queue-related commands."""
    pass

def __handle_stop_command(self, command: Controller.Command) -> None:
    """Handle stop-related commands."""
    pass

def __handle_extract_command(self, command: Controller.Command) -> None:
    """Handle extraction commands."""
    pass

def __handle_delete_command(self, command: Controller.Command) -> None:
    """Handle deletion commands."""
    pass
```

- [ ] Identify logical sections in __process_commands()
- [ ] Extract into separate methods
- [ ] Update tests

### Chunk 5.2: Refactor Controller.__propagate_exceptions()
**File**: `src/python/controller/controller.py`
**Method**: `__propagate_exceptions()` (114 lines)

- [ ] Extract exception handling for each subprocess type
- [ ] Update tests

### Chunk 5.3: Refactor JobStatusParser (Part 1)
**File**: `src/python/lftp/job_status_parser.py` (567 lines)

- [ ] Extract regex patterns to constants
- [ ] Create separate parser classes for different job types
- [ ] Create a parser factory

### Chunk 5.4: Refactor JobStatusParser (Part 2)
- [ ] Continue refactoring
- [ ] Add unit tests for extracted methods

## Verification
```bash
make run-tests-python
```
EOF
)"

echo "Created Phase 5 issue"

# Phase 6: Dependency Updates
gh issue create \
  --title "Phase 6: Dependency Updates - Update Outdated Packages" \
  --label "technical-debt,priority:medium,phase:6-deps" \
  --body "$(cat <<'EOF'
## Overview
Update outdated dependencies to current versions.

## Chunks

### Chunk 6.1: Update Safe Dependencies
**File**: `src/angular/package.json`

Low-risk updates (same major version):
- [ ] `bootstrap`: 4.2.1 → 4.6.2
- [ ] `immutable`: 3.8.2 → 4.3.4 (API changes, test thoroughly)

### Chunk 6.2: Replace node-sass with sass (dart-sass)
**File**: `src/angular/package.json`

```json
// Before
"node-sass": "^9.0.0"

// After
"sass": "^1.69.0"
```

Also update `src/docker/build/deb/Dockerfile`:
- [ ] Remove CXXFLAGS workaround after switching to dart-sass

### Chunk 6.3: Update Dev Dependencies
**File**: `src/angular/package.json`

- [ ] `@types/jasmine`: → ^5.1.0
- [ ] `@types/node`: → ^20.10.0
- [ ] `jasmine-core`: → ^5.1.0
- [ ] `karma`: → ^6.4.2

> **Note**: TypeScript cannot be updated until Angular is updated.

## Verification
```bash
cd src/angular && npm install
make run-tests-angular
# Check UI for visual regressions
```
EOF
)"

echo "Created Phase 6 issue"

# Phase 7: Linting & Type Safety
gh issue create \
  --title "Phase 7: Linting & Type Safety - Enable Stricter Rules" \
  --label "technical-debt,priority:medium,phase:7-linting" \
  --body "$(cat <<'EOF'
## Overview
Enable stricter TypeScript/ESLint rules to improve code quality.

## Chunks

### Chunk 7.1: Enable Stricter ESLint Rules
**File**: `src/angular/.eslintrc.json`

Change from "off" to "warn":
```json
{
  "rules": {
    "@typescript-eslint/no-explicit-any": "warn",
    "@typescript-eslint/no-empty-function": "warn",
    "@typescript-eslint/explicit-function-return-type": "warn"
  }
}
```

- [ ] Update ESLint config
- [ ] Run lint to see warnings count
- [ ] Document warning count baseline

### Chunk 7.2: Fix `any` Type Usage (Incremental)
Address `any` warnings one file at a time.

Priority files:
- [ ] `src/angular/src/app/services/files/view-file.service.ts`
- [ ] `src/angular/src/app/services/files/model-file.service.ts`
- [ ] `src/angular/src/app/services/base/base-web.service.ts`

Pattern:
```typescript
// Before
private data: any;

// After
private data: ModelFile | null;
```

## Verification
```bash
cd src/angular && npm run lint
```
EOF
)"

echo "Created Phase 7 issue"

# Phase 8: Angular Upgrade
gh issue create \
  --title "Phase 8: Angular Upgrade - Migrate from v4 to v18+" \
  --label "technical-debt,priority:critical,phase:8-angular" \
  --body "$(cat <<'EOF'
## Overview
Upgrade Angular from version 4.2.4 (2017) to the latest LTS version.

> **Warning**: This is a major undertaking. Complete Phases 1-7 first. Create a separate long-lived branch.

## Prerequisites
- [ ] Complete Phase 1 (CI/CD)
- [ ] Complete Phase 2 (Memory Leaks)
- [ ] Complete Phase 4 (RxJS Imports)
- [ ] Complete Phase 5 (Python Refactor)
- [ ] Complete Phase 6 (Dependencies)
- [ ] Complete Phase 7 (Linting)
- [ ] Create comprehensive test coverage
- [ ] Document current behavior
- [ ] Create branch: `upgrade/angular-18`

## Upgrade Path

### Chunk 8.1: Angular 4 → 5
- [ ] Update `@angular/*` packages to 5.x
- [ ] Update `rxjs` to 5.5.x
- [ ] Update `typescript` to 2.4.x
- [ ] Run tests

### Chunk 8.2: Angular 5 → 6
- [ ] Update to Angular CLI 6
- [ ] Update `rxjs` to 6.x
- [ ] Add `rxjs-compat` for backward compatibility
- [ ] Update to new `angular.json` format
- [ ] Run tests

### Chunk 8.3: Remove rxjs-compat
- [ ] Remove `rxjs-compat`
- [ ] Update all imports to `from "rxjs"` format
- [ ] Update operators to pipeable syntax
- [ ] Run tests

### Chunk 8.4: Angular 6 → 7
- [ ] Follow ng update guidance
- [ ] Run tests

### Chunk 8.5: Angular 7 → 8
- [ ] Follow ng update guidance
- [ ] Run tests

### Chunk 8.6: Angular 8 → 9
- [ ] Follow ng update guidance
- [ ] Update TestBed.get() to TestBed.inject()
- [ ] Run tests

### Chunk 8.7: Angular 9 → 10
- [ ] Follow ng update guidance
- [ ] Run tests

### Chunk 8.8: Angular 10 → 11 → 12
- [ ] Follow ng update guidance
- [ ] Run tests

### Chunk 8.9: Angular 12 → 13 → 14 → 15
- [ ] Follow ng update guidance
- [ ] Run tests

### Chunk 8.10: Angular 15 → 16 → 17 → 18
- [ ] Follow ng update guidance
- [ ] Run tests

### Chunk 8.11: Replace ngx-modialog
- [ ] Remove `ngx-modialog`
- [ ] Install `@ng-bootstrap/ng-bootstrap`
- [ ] Update `src/angular/src/app/app.module.ts`
- [ ] Update `src/angular/src/app/pages/files/file.component.ts`
- [ ] Update any other components using Modal service
- [ ] Run tests

## Resources
- [Angular Update Guide](https://update.angular.io/)
- [RxJS Migration Guide](https://rxjs.dev/guide/v6/migration)

## Verification
```bash
ng version
make run-tests-angular
make run-tests-e2e
```
EOF
)"

echo "Created Phase 8 issue"

# Create a tracking/overview issue
gh issue create \
  --title "Technical Debt Remediation - Master Tracking Issue" \
  --label "technical-debt" \
  --body "$(cat <<'EOF'
## Technical Debt Remediation Overview

This issue tracks the overall progress of technical debt remediation for SeedSync.

## Phase Summary

| Phase | Description | Priority | Status |
|-------|-------------|----------|--------|
| 1 | CI/CD Fixes | High | 🔴 Not Started |
| 2 | Memory Leak Prevention | Critical | 🔴 Not Started |
| 3 | Test Modernization | High | ⏸️ Blocked |
| 4 | RxJS Import Updates | High | 🔴 Not Started |
| 5 | Python Refactoring | Medium | 🔴 Not Started |
| 6 | Dependency Updates | Medium | 🔴 Not Started |
| 7 | Linting & Type Safety | Medium | 🔴 Not Started |
| 8 | Angular Upgrade | Critical | 🔴 Not Started |

## Recommended Order
```
Phase 1 → 2 → 4 → 5 → 6 → 7 → 8 → 3
```

## Quick Wins (Start Here)
1. **Phase 1, Chunk 1.1**: Fix deprecated GitHub release actions
2. **Phase 2, Chunk 2.1**: Add OnDestroy to core services

## Related Issues
- #[Phase 1 Issue Number]
- #[Phase 2 Issue Number]
- #[Phase 3 Issue Number]
- #[Phase 4 Issue Number]
- #[Phase 5 Issue Number]
- #[Phase 6 Issue Number]
- #[Phase 7 Issue Number]
- #[Phase 8 Issue Number]

## Test Commands
```bash
# Angular unit tests
make run-tests-angular

# Python unit tests
make run-tests-python

# E2E tests
make run-tests-e2e

# Angular lint
cd src/angular && npm run lint
```

---
*Update this issue as phases are completed.*
EOF
)"

echo "Created Master Tracking issue"

echo ""
echo "✅ All issues created successfully!"
echo ""
echo "Next steps:"
echo "1. Visit your GitHub repo's Issues tab to see all created issues"
echo "2. You can link issues together by editing the Master Tracking issue"
echo "3. Use GitHub Projects to create a Kanban board (optional)"
echo ""
echo "To create a GitHub Project board:"
echo "  gh project create --title 'SeedSync Tech Debt' --owner @me"
