# Session 18 Handoff: Bulk Actions Critical Fixes

**Date:** 2026-02-03
**Status:** Phase 1 Complete, Phases 2-5 Remaining

---

## Context

A code review identified critical issues in the bulk file actions implementation. An action plan was created at `planning docs/BULK_ACTIONS_FIXES.md` with 8 issues across 5 phases.

---

## What Was Completed (Phase 1)

### C1: Race Condition Fix ✓

**Problem:** `pruneSelection()` could run during bulk operations, corrupting selection state.

**Solution:** Added operation lock to `FileSelectionService`:

```
src/angular/src/app/services/files/file-selection.service.ts
```
- Added `_operationInProgress` private signal
- Added `operationInProgress` readonly signal
- Added `beginOperation()` / `endOperation()` methods
- `pruneSelection()` now returns early if operation in progress

```
src/angular/src/app/pages/files/file-list.component.ts
```
- `_executeBulkAction()` calls `beginOperation()` before HTTP request
- Calls `endOperation()` in both success and error handlers

### C3: Memory Leak Fix ✓

**Problem:** Observable subscription in constructor never unsubscribed.

**Solution:**
```
src/angular/src/app/pages/files/file-list.component.ts
```
- Added `DestroyRef` injection via `inject()`
- Added `takeUntilDestroyed(this.destroyRef)` to files subscription

### Tests Added ✓

```
src/angular/src/app/tests/unittests/services/files/file-selection.service.spec.ts
```
- 8 new tests in "Operation lock for race condition prevention" describe block
- Tests verify lock behavior, skipped pruning, and multiple cycles

### Build Verification
- TypeScript compilation: **Passed**
- Unit tests: Could not run locally (ARM64/Chrome Docker issue - CI should work)

---

## What Remains

### Phase 2: C2 + H1 (2-3 hours)

**C2: Remove misleading `selectAllMatchingFilterMode`**

The feature claims to select "all files matching filter" but only operates on visible files. Options:
- **Option A:** Implement backend support (complex)
- **Option B (Recommended):** Remove the feature entirely

Files to modify:
- `src/angular/src/app/services/files/file-selection.service.ts` - Remove `selectAllMatchingFilterMode` signal
- `src/angular/src/app/pages/files/file-list.component.ts` - Remove `onSelectAllMatchingFilter()`
- `src/angular/src/app/pages/files/file-list.component.html` - Remove banner link
- `src/angular/src/app/pages/files/selection-banner.component.ts` - Remove related UI

**H1: Fix error handling**

On HTTP error, selection should be cleared so user can retry fresh.

Files to modify:
- `src/angular/src/app/pages/files/file-list.component.ts` - Add `clearSelection()` in error handler
- `src/angular/src/app/common/localization.ts` - Add `ERROR_RETRY` message

### Phase 3: C4 - Rate Limiting (1-2 hours)

Add rate limiting to bulk endpoint to prevent DoS.

File to modify:
- `src/python/web/handler/controller.py`

Add:
- `_bulk_request_times` list
- `_bulk_rate_lock` threading lock
- `_check_rate_limit()` method
- Return 429 if rate exceeded

### Phase 4: H2 + H3 (2-3 hours)

**H2: Fix shift+click with filter changes**

Change from index-based to name-based anchor tracking.

File to modify:
- `src/angular/src/app/pages/files/file-list.component.ts`
- Change `_lastClickedIndex` to `_lastClickedFileName`

**H3: Fix inconsistent `isExtractable` check**

Bulk check missing `&& file.isArchive`.

File to modify:
- `src/angular/src/app/pages/files/bulk-actions-bar.component.ts` line ~103

### Phase 5: H4 - Progress Indicator (1 hour)

Show progress overlay during bulk operations.

Files to modify:
- `src/angular/src/app/pages/files/file-list.component.html` - Add overlay div
- `src/angular/src/app/pages/files/file-list.component.scss` - Add overlay styles
- `src/angular/src/app/pages/files/file-list.component.ts` - Always set `bulkOperationInProgress`

---

## Files Modified This Session

```
src/angular/src/app/services/files/file-selection.service.ts
src/angular/src/app/pages/files/file-list.component.ts
src/angular/src/app/tests/unittests/services/files/file-selection.service.spec.ts
planning docs/BULK_ACTIONS_FIXES.md (created)
planning docs/SESSION_18_HANDOFF.md (this file)
```

---

## How to Resume

1. Read this handoff note
2. Read `planning docs/BULK_ACTIONS_FIXES.md` for full technical details
3. Start with Phase 2 (C2 + H1)
4. Run `make run-tests-angular` after each phase (may need CI for ARM64 Macs)

---

## Known Issues

- **Test infrastructure:** `make run-tests-angular` fails on ARM64 Macs due to Chrome package architecture mismatch. Tests should pass in CI (GitHub Actions uses AMD64 runners). TypeScript compilation can verify syntax locally.

---

## Quick Test Commands

```bash
# Verify TypeScript compiles
cd /Users/julianamacbook/seedsync
docker run --rm -v "$(pwd)/src/angular:/app/src" -w /app seedsync/test/angular:latest npx tsc --noEmit --project /app/tsconfig.json

# Run all Angular tests (needs CI or AMD64 machine)
make run-tests-angular

# Run Python tests
make run-tests-python
```
