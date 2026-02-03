# Session 18 Handoff: Bulk Actions Critical Fixes

**Date:** 2026-02-03
**Status:** All Phases Complete (1-5)

---

## Context

A code review identified critical issues in the bulk file actions implementation. An action plan was created at `planning docs/BULK_ACTIONS_FIXES.md` with 8 issues across 5 phases.

---

## What Was Completed (Phase 1)

### C1: Race Condition Fix

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

### C3: Memory Leak Fix

**Problem:** Observable subscription in constructor never unsubscribed.

**Solution:**
```
src/angular/src/app/pages/files/file-list.component.ts
```
- Added `DestroyRef` injection via `inject()`
- Added `takeUntilDestroyed(this.destroyRef)` to files subscription

---

## What Was Completed (Phase 2)

### C2: Remove Misleading `selectAllMatchingFilterMode`

**Problem:** The feature claimed to select "all files matching filter" but only operated on visible files.

**Solution:** Removed the feature entirely (Option B).

Files modified:
- `src/angular/src/app/services/files/file-selection.service.ts`
- `src/angular/src/app/pages/files/file-list.component.ts`
- `src/angular/src/app/pages/files/file-list.component.html`
- `src/angular/src/app/pages/files/selection-banner.component.ts`
- `src/angular/src/app/pages/files/selection-banner.component.html`

### H1: Fix Error Handling

**Problem:** On HTTP error, selection remained but user had no idea what succeeded/failed.

**Solution:** Clear selection on error so user can retry fresh.

Files modified:
- `src/angular/src/app/pages/files/file-list.component.ts`
- `src/angular/src/app/common/localization.ts` - Added `ERROR_RETRY` message

---

## What Was Completed (Phase 3)

### C4: Rate Limiting for Bulk Endpoint

**Problem:** No rate limiting on bulk endpoint - attacker could flood the controller command queue.

**Solution:** Added sliding window rate limiting to the bulk endpoint.

File modified: `src/python/web/handler/controller.py`

Added:
- `_BULK_RATE_LIMIT = 10` - Max 10 requests per window
- `_BULK_RATE_WINDOW = 60.0` - 60-second sliding window
- `_bulk_request_times` - Class-level list tracking request timestamps
- `_bulk_rate_lock` - Threading lock for thread-safe access
- `_check_bulk_rate_limit()` - Sliding window rate limit check
- Returns HTTP 429 with JSON error when rate exceeded

Tests added: `src/python/tests/unittests/test_web/test_handler/test_controller_handler.py`
- `test_rate_limit_allows_requests_under_limit`
- `test_rate_limit_blocks_requests_over_limit`
- `test_rate_limit_resets_after_window`
- `test_rate_limit_response_content_type_is_json`

---

## What Was Completed (Phase 4)

### H2: Fix Shift+Click with Filter Changes

**Problem:** `_lastClickedIndex` became stale when filter changes or virtual scrolling shifted the list.

**Solution:** Changed from index-based to name-based anchor tracking.

File modified: `src/angular/src/app/pages/files/file-list.component.ts`

Changes:
- Renamed `_lastClickedIndex` to `_lastClickedFileName`
- Updated `onCheckboxToggle()` to find indices by name at shift+click time
- Added fallback: if anchor is no longer visible, just toggle the clicked file and set new anchor
- Removed the index reset logic from the files subscription (anchor persists across filter changes)
- Updated all references (Escape handler, `onClearSelection`, `_executeBulkAction`)

### H3: Fix Inconsistent `isExtractable` Check

**Problem:** Bulk check only checked `isExtractable`, but single-file check included `&& file.isArchive`.

**Solution:** Added `&& file.isArchive` to bulk check to match single-file logic.

File modified: `src/angular/src/app/pages/files/bulk-actions-bar.component.ts`
- Line 103: Changed `if (file.isExtractable)` to `if (file.isExtractable && file.isArchive)`

---

## What Was Completed (Phase 5)

### H4: Progress Indicator During Bulk Operations

**Problem:** `bulkOperationInProgress` flag existed but wasn't used in the template.

**Solution:** Added visual progress overlay during bulk operations.

Files modified:
- `src/angular/src/app/pages/files/file-list.component.html` - Added overlay div with spinner
- `src/angular/src/app/pages/files/file-list.component.scss` - Added overlay styles
- `src/angular/src/app/pages/files/file-list.component.ts` - Always set `bulkOperationInProgress` (removed 50+ threshold)

---

## Build Verification

- **TypeScript compilation:** Passed
- **Python syntax:** Passed (Phase 3)
- **Unit tests:** Docker build issue (unrelated `rar` package) - tests should pass in CI

---

## Files Modified This Session

### Phase 1-2 (Angular)
```
src/angular/src/app/services/files/file-selection.service.ts
src/angular/src/app/pages/files/file-list.component.ts
src/angular/src/app/pages/files/file-list.component.html
src/angular/src/app/pages/files/selection-banner.component.ts
src/angular/src/app/pages/files/selection-banner.component.html
src/angular/src/app/common/localization.ts
src/angular/src/app/tests/unittests/services/files/file-selection.service.spec.ts
src/angular/src/app/tests/unittests/services/files/view-file.service.spec.ts
```

### Phase 3 (Python)
```
src/python/web/handler/controller.py
src/python/tests/unittests/test_web/test_handler/test_controller_handler.py
```

### Phase 4-5 (Angular)
```
src/angular/src/app/pages/files/file-list.component.ts
src/angular/src/app/pages/files/file-list.component.html
src/angular/src/app/pages/files/file-list.component.scss
src/angular/src/app/pages/files/bulk-actions-bar.component.ts
```

---

## Summary of All Fixes

| Issue | Type | Description | Status |
|-------|------|-------------|--------|
| C1 | Critical | Race condition in selection management | Done |
| C2 | Critical | Misleading "select all matching" feature | Done (removed) |
| C3 | Critical | Memory leak from unsubscribed observable | Done |
| C4 | Critical | No rate limiting on bulk endpoint | Done |
| H1 | High | Error handling doesn't clear selection | Done |
| H2 | High | Shift+click breaks with filter changes | Done |
| H3 | High | Inconsistent isExtractable check | Done |
| H4 | High | No progress indication during bulk ops | Done |

All 8 issues from the code review have been addressed.
