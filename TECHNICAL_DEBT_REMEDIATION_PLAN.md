# SeedSync Technical Debt Remediation Plan

> **Purpose**: Step-by-step plan to address technical debt, organized into small chunks suitable for Claude Code sessions (to manage context limitations).

## Overview

| Phase | Focus Area | Priority | Estimated Chunks |
|-------|-----------|----------|------------------|
| 1 | CI/CD Fixes | High | 2 |
| 2 | Memory Leak Prevention | Critical | 4 |
| 3 | Test Modernization | High | 3 |
| 4 | RxJS Import Updates | High | 4 |
| 5 | Python Refactoring | Medium | 4 |
| 6 | Dependency Updates | Medium | 3 |
| 7 | Linting & Type Safety | Medium | 2 |
| 8 | Angular Upgrade (Long-term) | Critical | 10+ |

---

## Phase 1: CI/CD Fixes (2 chunks)

### Chunk 1.1: Update GitHub Release Actions
**Files to modify**: `.github/workflows/master.yml`
**Lines**: 254-265

**Task**: Replace deprecated `actions/create-release@v1` and `actions/upload-release-asset@v1`

**Current code**:
```yaml
- name: Create Release
  id: create_release
  uses: actions/create-release@v1
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  with:
    tag_name: ${{ github.ref }}
    release_name: ${{ github.ref }}
    draft: false
    prerelease: false

- name: Upload Release Asset
  uses: actions/upload-release-asset@v1
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  with:
    upload_url: ${{ steps.create_release.outputs.upload_url }}
    asset_path: ./seedsync.deb
    asset_name: seedsync_${{ env.VERSION }}.deb
    asset_content_type: application/vnd.debian.binary-package
```

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

**Verification**: Push a test tag to verify release creation works.

---

### Chunk 1.2: Audit Remaining CI Deprecations
**Files to review**: `.github/workflows/master.yml`

**Task**: Scan for any other deprecated patterns or actions

**Checklist**:
- [ ] Verify all actions are on latest major versions
- [ ] Check for deprecated `set-output` commands (use `$GITHUB_OUTPUT` instead)
- [ ] Check for deprecated `save-state` commands
- [ ] Ensure Node.js version in CI is current (20.x)

---

## Phase 2: Memory Leak Prevention (4 chunks)

### Chunk 2.1: Add OnDestroy to Core Services (Part 1)
**Files to modify**:
- `src/angular/src/app/services/files/view-file.service.ts`
- `src/angular/src/app/services/files/model-file.service.ts`

**Pattern to implement**:
```typescript
import { Injectable, OnDestroy } from '@angular/core';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

@Injectable()
export class ViewFileService implements OnDestroy {
  private destroy$ = new Subject<void>();

  constructor() {
    this.someObservable$
      .pipe(takeUntil(this.destroy$))
      .subscribe(/* ... */);
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
```

**Verification**: Run `npm test` to ensure tests pass.

---

### Chunk 2.2: Add OnDestroy to Core Services (Part 2)
**Files to modify**:
- `src/angular/src/app/services/autoqueue/autoqueue.service.ts`
- `src/angular/src/app/services/settings/config.service.ts`

**Same pattern as Chunk 2.1**

---

### Chunk 2.3: Add OnDestroy to Server Services
**Files to modify**:
- `src/angular/src/app/services/server/server-status.service.ts`
- `src/angular/src/app/services/server/server-command.service.ts`

**Same pattern as Chunk 2.1**

---

### Chunk 2.4: Add OnDestroy to Utility Services
**Files to modify**:
- `src/angular/src/app/services/utils/notification.service.ts`
- `src/angular/src/app/services/utils/connected.service.ts`
- `src/angular/src/app/services/logs/log.service.ts`

**Same pattern as Chunk 2.1**

**Final verification**: Run full test suite `make run-tests-angular`

---

## Phase 3: Test Modernization (3 chunks)

### Chunk 3.1: Update TestBed.get() to TestBed.inject() (Part 1)
**Files to modify**:
- `src/angular/src/app/tests/unittests/services/files/view-file-filter.service.spec.ts`
- `src/angular/src/app/tests/unittests/services/files/model-file.service.spec.ts`
- `src/angular/src/app/tests/unittests/services/files/view-file-options.service.spec.ts`

**Change pattern**:
```typescript
// Before
const service = TestBed.get(ViewFileService);

// After
const service = TestBed.inject(ViewFileService);
```

**Note**: `TestBed.inject()` was added in Angular 9, so this requires Angular upgrade first. Mark as blocked until Phase 8.

**Alternative for Angular 4**: Add `// TODO: Update to TestBed.inject() after Angular upgrade` comments.

---

### Chunk 3.2: Update TestBed.get() to TestBed.inject() (Part 2)
**Files to modify**:
- `src/angular/src/app/tests/unittests/services/files/view-file-sort.service.spec.ts`
- `src/angular/src/app/tests/unittests/services/autoqueue/autoqueue.service.spec.ts`
- `src/angular/src/app/tests/unittests/services/server/server-command.service.spec.ts`

---

### Chunk 3.3: Update TestBed.get() to TestBed.inject() (Part 3)
**Files to modify**:
- `src/angular/src/app/tests/unittests/services/settings/config.service.spec.ts`
- `src/angular/src/app/tests/unittests/services/utils/rest.service.spec.ts`
- Any remaining test files with `TestBed.get()`

---

## Phase 4: RxJS Import Updates (4 chunks)

### Chunk 4.1: Update RxJS Imports in File Services
**Files to modify**:
- `src/angular/src/app/services/files/view-file.service.ts`
- `src/angular/src/app/services/files/model-file.service.ts`
- `src/angular/src/app/services/files/view-file-filter.service.ts`
- `src/angular/src/app/services/files/view-file-options.service.ts`
- `src/angular/src/app/services/files/view-file-sort.service.ts`

**Change pattern**:
```typescript
// Before
import {Observable} from "rxjs/Observable";
import {BehaviorSubject} from "rxjs/Rx";

// After (works in RxJS 5.5+ with Angular 4)
import {Observable} from "rxjs/Observable";
import {BehaviorSubject} from "rxjs/BehaviorSubject";
```

**Note**: Full modern imports (`from "rxjs"`) require RxJS 6+ which needs Angular 6+.

---

### Chunk 4.2: Update RxJS Imports in Server Services
**Files to modify**:
- `src/angular/src/app/services/server/server-status.service.ts`
- `src/angular/src/app/services/server/server-command.service.ts`

---

### Chunk 4.3: Update RxJS Imports in Settings/Utils Services
**Files to modify**:
- `src/angular/src/app/services/settings/config.service.ts`
- `src/angular/src/app/services/utils/notification.service.ts`
- `src/angular/src/app/services/utils/connected.service.ts`
- `src/angular/src/app/services/utils/rest.service.ts`
- `src/angular/src/app/services/logs/log.service.ts`

---

### Chunk 4.4: Update RxJS Imports in Base Services and Mocks
**Files to modify**:
- `src/angular/src/app/services/base/base-stream.service.ts`
- `src/angular/src/app/services/base/base-web.service.ts`
- `src/angular/src/app/tests/mocks/mock-model-file.service.ts`
- `src/angular/src/app/tests/mocks/mock-view-file.service.ts`
- `src/angular/src/app/tests/mocks/mock-rest.service.ts`

---

## Phase 5: Python Refactoring (4 chunks)

### Chunk 5.1: Refactor Controller.__process_commands() - Extract Methods
**File**: `src/python/controller/controller.py`
**Method**: `__process_commands()` (117 lines)

**Task**: Extract logical sections into smaller private methods

**Suggested extraction**:
```python
# Extract these as separate methods:
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

**Verification**: Run `make run-tests-python`

---

### Chunk 5.2: Refactor Controller.__propagate_exceptions()
**File**: `src/python/controller/controller.py`
**Method**: `__propagate_exceptions()` (114 lines)

**Task**: Extract exception handling for each subprocess type

---

### Chunk 5.3: Refactor JobStatusParser (Part 1)
**File**: `src/python/lftp/job_status_parser.py` (567 lines)

**Task**: Extract parsing logic into smaller classes/functions

**Suggested approach**:
- Create separate parser classes for different job types
- Extract regex patterns to constants
- Create a parser factory

---

### Chunk 5.4: Refactor JobStatusParser (Part 2)
**File**: `src/python/lftp/job_status_parser.py`

**Task**: Continue refactoring, add unit tests for extracted methods

---

## Phase 6: Dependency Updates (3 chunks)

### Chunk 6.1: Update Safe Dependencies
**File**: `src/angular/package.json`

**Dependencies to update** (low risk):
```json
{
  "bootstrap": "^4.6.2",      // 4.2.1 -> 4.6.2 (minor update, same major)
  "immutable": "^4.3.4",      // 3.8.2 -> 4.3.4 (API changes, test thoroughly)
  "jquery": "^3.7.1"          // Already current
}
```

**Verification**: Run tests, check UI for visual regressions

---

### Chunk 6.2: Replace node-sass with sass (dart-sass)
**File**: `src/angular/package.json`

**Change**:
```json
// Before
"node-sass": "^9.0.0"

// After
"sass": "^1.69.0"
```

**Also update**: `src/docker/build/deb/Dockerfile` - remove CXXFLAGS workaround

**Verification**: Build Angular app, check styling

---

### Chunk 6.3: Update Dev Dependencies
**File**: `src/angular/package.json`

**Dependencies to update**:
```json
{
  "@types/jasmine": "^5.1.0",
  "@types/node": "^20.10.0",
  "jasmine-core": "^5.1.0",
  "karma": "^6.4.2",
  "typescript": "~2.4.2"  // Keep for Angular 4 compatibility
}
```

**Note**: TypeScript cannot be updated until Angular is updated.

---

## Phase 7: Linting & Type Safety (2 chunks)

### Chunk 7.1: Enable Stricter ESLint Rules
**File**: `src/angular/.eslintrc.json`

**Changes**:
```json
{
  "rules": {
    "@typescript-eslint/no-explicit-any": "warn",  // Change from "off"
    "@typescript-eslint/no-empty-function": "warn", // Change from "off"
    "@typescript-eslint/explicit-function-return-type": "warn"
  }
}
```

**Note**: Start with "warn" to identify issues without breaking build.

---

### Chunk 7.2: Fix `any` Type Usage (Incremental)
**Task**: Address `any` warnings one file at a time

**Priority files**:
1. `src/angular/src/app/services/files/view-file.service.ts`
2. `src/angular/src/app/services/files/model-file.service.ts`
3. `src/angular/src/app/services/base/base-web.service.ts`

**Pattern**:
```typescript
// Before
private data: any;

// After
private data: ModelFile | null;
```

---

## Phase 8: Angular Upgrade (Long-term, 10+ chunks)

> **Warning**: This is a major undertaking. Consider creating a separate branch.

### Pre-requisites
- Complete Phases 1-7 first
- Create comprehensive test coverage
- Document current behavior

### Chunk 8.1: Upgrade Angular 4 -> 5
**Key changes**:
- Update `@angular/*` packages to 5.x
- Update `rxjs` to 5.5.x
- Update `typescript` to 2.4.x
- Add `rxjs-compat` for backward compatibility

### Chunk 8.2: Upgrade Angular 5 -> 6
**Key changes**:
- Update to Angular CLI 6
- Update `rxjs` to 6.x
- Use `rxjs-compat` migration package
- Update to new `angular.json` format

### Chunk 8.3: Remove rxjs-compat, Update Imports
**Task**:
- Remove `rxjs-compat`
- Update all imports to `from "rxjs"` format
- Update operators to pipeable syntax

### Chunks 8.4-8.10: Continue Incremental Upgrades
- Angular 6 -> 7 -> 8 -> 9 -> 10 -> ... -> 18/19
- Each version may require specific migrations
- Use `ng update` guidance for each version

### Chunk 8.11: Replace ngx-modialog
**Task**: Replace abandoned `ngx-modialog` with `@ng-bootstrap/ng-bootstrap`

**Files affected**:
- `src/angular/src/app/app.module.ts`
- `src/angular/src/app/pages/files/file.component.ts`
- Any component using Modal service

---

## Execution Guidelines

### For Each Chunk:

1. **Start**: Read relevant files to understand current state
2. **Plan**: Identify specific changes needed
3. **Implement**: Make changes incrementally
4. **Test**: Run relevant tests after each change
5. **Commit**: Create focused commit with clear message
6. **Verify**: Run full test suite before moving to next chunk

### Claude Code Session Template:

```
Session Goal: Complete Chunk X.Y - [Description]

1. Read the files listed for this chunk
2. Make the specified changes
3. Run tests: [specific test command]
4. Commit changes with message: "refactor: [chunk description]"
5. Push to branch
```

### Branch Strategy:

- **Small fixes (Phases 1-2)**: Work on `main` or `develop`
- **Larger refactors (Phases 3-7)**: Create feature branch `refactor/phase-X`
- **Angular upgrade (Phase 8)**: Create long-lived branch `upgrade/angular-18`

---

## Progress Tracking

| Chunk | Status | Date | Notes |
|-------|--------|------|-------|
| 1.1 | Not Started | | |
| 1.2 | Not Started | | |
| 2.1 | Not Started | | |
| 2.2 | Not Started | | |
| 2.3 | Not Started | | |
| 2.4 | Not Started | | |
| ... | | | |

---

## Quick Reference: Test Commands

```bash
# Angular unit tests
make run-tests-angular

# Python unit tests
make run-tests-python

# E2E tests (requires built artifacts)
make run-tests-e2e

# Angular lint
cd src/angular && npm run lint

# Build everything
make
```

---

## Dependencies Between Chunks

```
Phase 1 (CI/CD) ────────────────────────────────────────────────┐
                                                                │
Phase 2 (Memory Leaks) ─────────────────────────────────────────┤
                                                                │
Phase 3 (Test Modernization) ──── BLOCKED by Phase 8 ──────────┤
                                                                │
Phase 4 (RxJS Imports) ─────────────────────────────────────────┤
                                                                │
Phase 5 (Python Refactor) ──────────────────────────────────────┤
                                                                │
Phase 6 (Dependencies) ─────────────────────────────────────────┤
                                                                │
Phase 7 (Linting) ──────────────────────────────────────────────┤
                                                                │
Phase 8 (Angular Upgrade) ◄─────────────────────────────────────┘
         Requires all above completed first
```

**Recommended Order**: 1 → 2 → 4 → 5 → 6 → 7 → 8 → 3
