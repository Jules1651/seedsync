# Bulk Actions - Critical Fixes Action Plan

**Created:** 2026-02-03
**Priority:** Critical/High items from code review
**Status:** Planning

---

## Executive Summary

The bulk file actions implementation has several critical issues that could cause data inconsistency, poor UX at scale, and potential DoS vulnerabilities. This plan addresses the top 8 issues in priority order.

---

## Critical Issues

### C1: Race Conditions in Selection Management

**Problem:** `pruneSelection()` can run concurrently with bulk operations, causing selection state to become inconsistent. The `bulkOperationInProgress` flag exists but isn't checked before pruning.

**Impact:** User selects 100 files, triggers delete, file list refreshes mid-operation, selection gets pruned, user sees partial results with no way to know what happened.

**Fix:**

```typescript
// file-selection.service.ts - Add operation lock
private _operationInProgress = signal<boolean>(false);

readonly operationInProgress = this._operationInProgress.asReadonly();

beginOperation(): void {
    this._operationInProgress.set(true);
}

endOperation(): void {
    this._operationInProgress.set(false);
}

pruneSelection(existingFileNames: Set<string>): void {
    // Skip pruning during bulk operations
    if (this._operationInProgress()) {
        return;
    }
    // ... existing logic
}
```

```typescript
// file-list.component.ts - Use the lock
private _executeBulkAction(...): void {
    this.fileSelectionService.beginOperation();

    this.bulkCommandService.executeBulkAction(action, fileNames).subscribe({
        next: (result) => {
            this.fileSelectionService.endOperation();
            // ... existing logic
        },
        error: (err) => {
            this.fileSelectionService.endOperation();
            // ... existing logic
        }
    });
}
```

**Files to modify:**
- `src/angular/src/app/services/files/file-selection.service.ts`
- `src/angular/src/app/pages/files/file-list.component.ts`

**Tests to add:**
- Verify pruneSelection is skipped during bulk operation
- Verify lock is released on success and error

---

### C2: `selectAllMatchingFilterMode` Doesn't Actually Select All

**Problem:** The flag claims to represent "all files matching filter" but bulk actions only send visible file names. With 10,000 files and 50 visible, only 50 get processed.

**Impact:** User thinks they're operating on all matching files but only affects visible subset. Data inconsistency.

**Fix Options:**

**Option A: Backend-driven select all (Recommended)**

Add a new bulk endpoint parameter to let the backend handle "all matching":

```python
# controller.py
def __handle_bulk_command(self):
    body = request.json

    # New parameter: apply to all files matching filter
    select_all_matching = body.get("select_all_matching", False)
    filter_criteria = body.get("filter", None)  # e.g., {"status": "Default"}

    if select_all_matching:
        # Get all matching files from model
        files = self._get_files_matching_filter(filter_criteria)
    else:
        files = body.get("files", [])
```

```typescript
// bulk-command.service.ts
executeBulkAction(
    action: BulkAction,
    fileNames: string[],
    selectAllMatching?: { enabled: boolean; filter?: FilterCriteria }
): Observable<BulkActionResult>
```

**Option B: Remove the misleading feature**

Remove `selectAllMatchingFilterMode` entirely. Only support explicit selection of visible files. Update UI to not show "Select all matching" link.

**Recommendation:** Option B for now (simpler, honest UX), Option A as future enhancement.

**Files to modify:**
- `src/angular/src/app/services/files/file-selection.service.ts` - Remove `selectAllMatchingFilterMode`
- `src/angular/src/app/pages/files/file-list.component.ts` - Remove `onSelectAllMatchingFilter`
- `src/angular/src/app/pages/files/file-list.component.html` - Remove banner link
- `src/angular/src/app/pages/files/selection-banner.component.ts` - Remove related UI

**Tests to update:**
- Remove tests for "select all matching" feature
- Add test verifying selection is limited to visible files

---

### C3: Memory Leak - Unsubscribed Observable

**Problem:** `FileListComponent` subscribes to `this.files` without cleanup.

**Impact:** Memory leak on navigation, potential for stale callbacks firing.

**Fix:**

```typescript
// file-list.component.ts
import { DestroyRef, inject } from "@angular/core";
import { takeUntilDestroyed } from "@angular/core/rxjs-interop";

export class FileListComponent {
    private destroyRef = inject(DestroyRef);

    constructor(...) {
        // ...

        this.files.pipe(
            takeUntilDestroyed(this.destroyRef)
        ).subscribe(files => {
            this._currentFiles = files;
            if (this._lastClickedIndex !== null && this._lastClickedIndex >= files.size) {
                this._lastClickedIndex = null;
            }
        });
    }
}
```

**Files to modify:**
- `src/angular/src/app/pages/files/file-list.component.ts`

**Tests to add:**
- Verify component cleanup on destroy (can use Angular TestBed)

---

### C4: Backend Rate Limiting / DoS Prevention

**Problem:** No rate limiting on bulk endpoint. Attacker can queue unlimited commands.

**Impact:** Trivial DoS - flood the controller command queue, block legitimate operations.

**Fix:**

```python
# controller.py
import time
from threading import Lock

class ControllerHandler(IHandler):
    # Rate limiting state
    _bulk_request_times: list = []
    _bulk_rate_lock = Lock()
    _BULK_RATE_LIMIT = 5  # Max 5 bulk requests per minute
    _BULK_RATE_WINDOW = 60.0  # seconds

    def __handle_bulk_command(self):
        # Rate limiting check
        if not self._check_rate_limit():
            return HTTPResponse(
                body=json.dumps({"error": "Rate limit exceeded. Try again later."}),
                status=429,
                content_type="application/json"
            )
        # ... existing logic

    def _check_rate_limit(self) -> bool:
        """Returns True if request is allowed, False if rate limited."""
        now = time.time()
        with self._bulk_rate_lock:
            # Remove old entries
            self._bulk_request_times = [
                t for t in self._bulk_request_times
                if now - t < self._BULK_RATE_WINDOW
            ]
            # Check limit
            if len(self._bulk_request_times) >= self._BULK_RATE_LIMIT:
                return False
            # Record this request
            self._bulk_request_times.append(now)
            return True
```

**Files to modify:**
- `src/python/web/handler/controller.py`

**Tests to add:**
- Verify 429 response after exceeding rate limit
- Verify rate limit resets after window expires

---

## High Priority Issues

### H1: Error Handling Doesn't Clear Selection Properly

**Problem:** On HTTP error, selection remains but user has no idea what succeeded/failed. Retry will duplicate operations.

**Impact:** User confusion, potential duplicate deletes.

**Fix:**

```typescript
// file-list.component.ts
private _executeBulkAction(...): void {
    this.fileSelectionService.beginOperation();

    this.bulkCommandService.executeBulkAction(action, fileNames).subscribe({
        next: (result) => {
            this.fileSelectionService.endOperation();
            this._handleBulkResult(result, messages);
            // Clear selection after ANY completion (success or partial)
            this.fileSelectionService.clearSelection();
            this._lastClickedIndex = null;
        },
        error: (err) => {
            this.fileSelectionService.endOperation();
            this._logger.error("Bulk action error:", err);

            // ALSO clear selection on error - user should retry fresh
            this.fileSelectionService.clearSelection();
            this._lastClickedIndex = null;

            this._showNotification(
                Notification.Level.DANGER,
                Localization.Bulk.ERROR_RETRY("Request failed. Please re-select files and try again.")
            );
        }
    });
}
```

Also add a new localization string:
```typescript
// localization.ts
ERROR_RETRY: (msg: string) => `${msg}`,
```

**Files to modify:**
- `src/angular/src/app/pages/files/file-list.component.ts`
- `src/angular/src/app/common/localization.ts`

**Tests to add:**
- Verify selection cleared on network error
- Verify appropriate error message shown

---

### H2: Shift+Click Breaks with Filter Changes

**Problem:** `_lastClickedIndex` becomes stale when filter changes or virtual scrolling shifts the list.

**Impact:** Shift+click selects wrong files or crashes.

**Fix:**

```typescript
// file-list.component.ts

// Change from index-based to name-based tracking
private _lastClickedFileName: string | null = null;

onCheckboxToggle(event: {file: ViewFile, shiftKey: boolean}): void {
    if (event.shiftKey && this._lastClickedFileName !== null) {
        // Find current indices by name (handles filter/scroll changes)
        const lastIndex = this._currentFiles.findIndex(f => f.name === this._lastClickedFileName);
        const currentIndex = this._currentFiles.findIndex(f => f.name === event.file.name);

        if (lastIndex !== -1 && currentIndex !== -1) {
            const start = Math.min(lastIndex, currentIndex);
            const end = Math.max(lastIndex, currentIndex);

            const rangeNames: string[] = [];
            for (let i = start; i <= end; i++) {
                const file = this._currentFiles.get(i);
                if (file) {
                    rangeNames.push(file.name);
                }
            }
            this.fileSelectionService.setSelection(rangeNames);
        } else {
            // Anchor no longer visible - just toggle the clicked file
            this.fileSelectionService.toggle(event.file.name);
            this._lastClickedFileName = event.file.name;
        }
    } else {
        this.fileSelectionService.toggle(event.file.name);
        this._lastClickedFileName = event.file.name;
    }
}

// Also update the files subscription to NOT reset anchor
this.files.pipe(takeUntilDestroyed(this.destroyRef)).subscribe(files => {
    this._currentFiles = files;
    // DON'T reset _lastClickedFileName - keep anchor even if temporarily not visible
});

// Reset anchor on explicit clear
onClearSelection(): void {
    this.fileSelectionService.clearSelection();
    this._lastClickedFileName = null;
}
```

**Files to modify:**
- `src/angular/src/app/pages/files/file-list.component.ts`

**Tests to add:**
- Shift+click after filter change
- Shift+click when anchor file is scrolled out of view
- Shift+click when anchor file is deleted

---

### H3: Inconsistent `isExtractable` Check

**Problem:** Single-file check includes `&& this.file.isArchive`, bulk check only checks `isExtractable`.

**Impact:** Files may appear extractable in bulk but fail, or vice versa.

**Fix:**

```typescript
// bulk-actions-bar.component.ts
private _recomputeCachedValues(): void {
    // ...
    for (const file of this._cachedSelectedViewFiles) {
        // ...
        // Match single-file logic: isExtractable AND isArchive
        if (file.isExtractable && file.isArchive) {
            extractable.push(file.name);
        }
        // ...
    }
}
```

**Files to modify:**
- `src/angular/src/app/pages/files/bulk-actions-bar.component.ts`

**Tests to add:**
- Verify non-archive files excluded from bulk extract count
- Verify consistency between single-file and bulk extract eligibility

---

### H4: No Progress Indication During Bulk Operations

**Problem:** `bulkOperationInProgress` flag exists but isn't used in the template. Users see nothing during long operations.

**Impact:** User thinks app is frozen, may retry or navigate away.

**Fix:**

```html
<!-- file-list.component.html - Add progress overlay -->
<div class="bulk-progress-overlay" *ngIf="bulkOperationInProgress">
    <div class="spinner-border text-primary" role="status">
        <span class="visually-hidden">Processing...</span>
    </div>
    <div class="progress-text">Processing files...</div>
</div>
```

```scss
// file-list.component.scss
.bulk-progress-overlay {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(255, 255, 255, 0.8);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    z-index: 100;

    .progress-text {
        margin-top: 1rem;
        font-weight: 500;
    }
}
```

```typescript
// file-list.component.ts - Lower threshold for showing progress
private _executeBulkAction(...): void {
    // Show progress for any bulk operation (not just 50+)
    this.bulkOperationInProgress = true;
    // ...
}
```

**Files to modify:**
- `src/angular/src/app/pages/files/file-list.component.html`
- `src/angular/src/app/pages/files/file-list.component.scss`
- `src/angular/src/app/pages/files/file-list.component.ts`

**Tests to add:**
- Verify progress overlay shown during bulk operation
- Verify overlay hidden after completion

---

## Implementation Order

| Phase | Items | Effort | Risk if Deferred |
|-------|-------|--------|------------------|
| 1 | C1 (Race conditions), C3 (Memory leak) | 2-3 hours | High - data corruption |
| 2 | C2 (Select all lie), H1 (Error handling) | 2-3 hours | High - user confusion |
| 3 | C4 (Rate limiting) | 1-2 hours | Medium - DoS vector |
| 4 | H2 (Shift+click), H3 (Extract check) | 2-3 hours | Medium - broken features |
| 5 | H4 (Progress indication) | 1 hour | Low - UX polish |

**Total estimated effort:** 8-12 hours

---

## Testing Strategy

After implementing fixes:

1. **Unit tests** for each changed service method
2. **E2E tests** for:
   - Bulk operation during file list refresh
   - Network failure scenarios
   - Rate limiting (mock slow responses)
   - Shift+click edge cases
3. **Manual testing** with:
   - 1000+ files
   - Slow network (Chrome DevTools throttling)
   - Concurrent operations from multiple browser tabs

---

## Out of Scope (Future)

- Signal performance optimization (O(1) per-file selection)
- True "select all matching" with backend support
- Cancellable bulk operations
- Per-file progress reporting
- Ctrl+Shift+Click additive range selection
