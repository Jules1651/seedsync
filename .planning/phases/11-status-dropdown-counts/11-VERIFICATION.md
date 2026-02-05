---
phase: 11-status-dropdown-counts
verified: 2026-02-05T00:17:20Z
status: passed
score: 5/5 must-haves verified
---

# Phase 11: Status Dropdown Counts Verification Report

**Phase Goal:** Users can see at a glance how many files are in each status category

**Verified:** 2026-02-05T00:17:20Z

**Status:** PASSED

**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Each status option displays count in parentheses (e.g., "Downloaded (5)") | ✓ VERIFIED | Template shows `"Extracted ({{ formatCount(ViewFile.Status.EXTRACTED) }})"` pattern for all 6 statuses in both button and dropdown menu (lines 24-111 in HTML) |
| 2 | "All" option shows total file count across all statuses | ✓ VERIFIED | Template shows `"All ({{ formatCount(null) }})"` (lines 24, 63). TypeScript sets `counts.set(null, files.size)` (line 172) |
| 3 | Counts refresh when dropdown is opened (not real-time) | ✓ VERIFIED | Event listener `show.bs.dropdown` triggers `statusDropdownShowHandler` which calls `computeStatusCounts` (lines 64-67, 120 in TS). Also computes on initial load (line 85) so button shows count before first open |
| 4 | Empty statuses show "(0)" count and are disabled | ✓ VERIFIED | `formatCount` returns formatted count including "0" (lines 159-162 in TS). Empty statuses have `[attr.aria-disabled]="getCount(status) === 0 ? true : null"` and click prevention `getCount(status) > 0 ? onFilterByStatus(status) : null` (lines 68-109 in HTML) |
| 5 | Counts use thousands separator for large numbers | ✓ VERIFIED | `numberFormatter = new Intl.NumberFormat()` (line 48 in TS) formats counts with browser locale thousands separator in `formatCount` method (line 161) |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `src/angular/src/app/pages/files/file-options.component.ts` | Status count computation and formatting | ✓ VERIFIED | 191 lines, contains `computeStatusCounts` (line 168), `formatCount` (line 159), `getCount` (line 151), `statusCounts` Map (line 47), `numberFormatter` (line 48), event handler (line 64) |
| `src/angular/src/app/pages/files/file-options.component.html` | Count display in dropdown button and items | ✓ VERIFIED | 163 lines, contains `formatCount()` calls on all 14 instances (7 in button selection, 7 in dropdown menu - lines 24-111), `getCount()` for disabled states on 6 status items (lines 68-109) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| file-options.component.ts | _viewFileService.files | on-demand computation triggered by dropdown show event | ✓ WIRED | Event listener registered at line 120: `statusDropdown.addEventListener("show.bs.dropdown", this.statusDropdownShowHandler)`. Handler at lines 64-67 calls `computeStatusCounts(this._latestFiles)`. Files subscription at lines 80-106 stores `this._latestFiles = files` and computes initial counts |
| file-options.component.html | file-options.component.ts | formatCount() method called in template interpolation | ✓ WIRED | Template calls `formatCount(null)` and `formatCount(ViewFile.Status.X)` 14 times (grep shows lines 24, 29, 34, 39, 44, 49, 54, 63, 71, 79, 87, 95, 103, 111) |
| file-options.component.html | file-options.component.ts | getCount() method for click prevention and aria-disabled | ✓ WIRED | Template calls `getCount(status)` for aria-disabled and click ternaries on all 6 status items (lines 68-109) |

### Requirements Coverage

No explicit requirements mapped to Phase 11 in REQUIREMENTS.md. Phase goal from ROADMAP.md fully achieved.

### Anti-Patterns Found

No anti-patterns found:
- No TODO/FIXME/placeholder comments
- No stub patterns (empty returns, console.log-only)
- No orphaned code
- Proper event listener cleanup in ngOnDestroy (line 129)
- Proper zone handling (runOutsideAngular) for performance (line 117)

### Human Verification Required

1. **Visual Count Display**
   - **Test:** Open the app, view the status dropdown button and menu
   - **Expected:** 
     - Button shows selected status with count: "All (42)" or "Downloaded (5)"
     - Dropdown menu shows all 7 options with counts: "All (42)", "Extracted (3)", etc.
     - Zero-count statuses show "(0)" and are grayed out
   - **Why human:** Visual rendering requires human inspection

2. **On-Demand Refresh Behavior**
   - **Test:** 
     1. Note current "All" count in button
     2. Trigger a file change (queue a download or delete a file)
     3. Open status dropdown
     4. Check if counts updated
   - **Expected:** Counts should update when dropdown is opened, not continuously in real-time
   - **Why human:** Testing timing behavior requires observing actual app state changes

3. **Empty Status Interaction**
   - **Test:**
     1. Find a status with (0) count
     2. Try clicking that status
     3. Check if filter changes
   - **Expected:** Clicking empty status should do nothing (no filter change)
   - **Why human:** Click interaction requires human testing

4. **All Option Never Disabled**
   - **Test:**
     1. When no files exist (All shows "(0)")
     2. Try clicking "All"
   - **Expected:** "All" should be clickable even when count is 0
   - **Why human:** Edge case requires specific app state

5. **Thousands Separator Formatting**
   - **Test:** Use test data with >1000 files, view counts
   - **Expected:** Counts show comma separator like "1,234"
   - **Why human:** Requires specific data volume to test

## Verification Details

### Truth 1: Each status option displays count in parentheses

**Status:** ✓ VERIFIED

**Evidence:**
```html
<!-- Button selection displays (lines 24-54) -->
<span class="text">All ({{ formatCount(null) }})</span>
<span class="text">Extracted ({{ formatCount(ViewFile.Status.EXTRACTED) }})</span>
<span class="text">Extracting ({{ formatCount(ViewFile.Status.EXTRACTING) }})</span>
<span class="text">Downloaded ({{ formatCount(ViewFile.Status.DOWNLOADED) }})</span>
<span class="text">Downloading ({{ formatCount(ViewFile.Status.DOWNLOADING) }})</span>
<span class="text">Queued ({{ formatCount(ViewFile.Status.QUEUED) }})</span>
<span class="text">Stopped ({{ formatCount(ViewFile.Status.STOPPED) }})</span>

<!-- Dropdown menu displays (lines 63-111) -->
<!-- Same pattern for all 7 options -->
```

All 6 ViewFile.Status values (EXTRACTED, EXTRACTING, DOWNLOADED, DOWNLOADING, QUEUED, STOPPED) are covered in both button and dropdown menu.

### Truth 2: "All" option shows total file count

**Status:** ✓ VERIFIED

**Evidence:**
```typescript
// TypeScript (line 172)
counts.set(null, files.size);  // null key = "All" count

// HTML (lines 24, 63)
<span class="text">All ({{ formatCount(null) }})</span>
```

The computeStatusCounts method sets the null key to total file count, and the template displays it.

### Truth 3: Counts refresh when dropdown is opened

**Status:** ✓ VERIFIED

**Evidence:**
```typescript
// Event handler (lines 64-67)
private statusDropdownShowHandler = (): void => {
    this.statusCounts = this.computeStatusCounts(this._latestFiles);
    this._changeDetector.detectChanges();
};

// Event listener registration (lines 117-122)
this._ngZone.runOutsideAngular(() => {
    const statusDropdown = document.getElementById("filter-status");
    if (statusDropdown) {
        statusDropdown.addEventListener("show.bs.dropdown", this.statusDropdownShowHandler);
    }
});

// Initial computation (line 85)
this.statusCounts = this.computeStatusCounts(files);
```

The implementation:
1. Computes counts once on initial load (so button displays count)
2. Re-computes counts when dropdown opens (show.bs.dropdown event)
3. Does NOT continuously update in the subscription (line 82 stores files reference but doesn't recompute)

This honors the user decision for on-demand refresh, not real-time.

### Truth 4: Empty statuses show "(0)" count and are disabled

**Status:** ✓ VERIFIED

**Evidence:**
```typescript
// formatCount always returns formatted number (lines 159-162)
public formatCount(status: ViewFile.Status | null): string {
    const count = this.getCount(status);
    return this.numberFormatter.format(count);  // Formats "0" as "0"
}

// getCount returns 0 for missing entries (lines 151-153)
public getCount(status: ViewFile.Status | null): number {
    return this.statusCounts.get(status) ?? 0;
}
```

```html
<!-- Disabled state example (lines 68-69) -->
[attr.aria-disabled]="getCount(ViewFile.Status.EXTRACTED) === 0 ? true : null"
(click)="getCount(ViewFile.Status.EXTRACTED) > 0 ? onFilterByStatus(ViewFile.Status.EXTRACTED) : null"
```

All 6 status dropdown items have:
1. `[attr.aria-disabled]` for accessibility when count is 0
2. Click prevention using ternary `getCount(status) > 0 ? action : null`
3. Existing `[class.disabled]` binding for visual styling

Important: "All" option (lines 59-64) has NO aria-disabled or click prevention, so it remains clickable even when "(0)".

### Truth 5: Counts use thousands separator

**Status:** ✓ VERIFIED

**Evidence:**
```typescript
// NumberFormatter initialized with browser default locale (line 48)
private numberFormatter = new Intl.NumberFormat();

// formatCount uses formatter (lines 159-162)
public formatCount(status: ViewFile.Status | null): string {
    const count = this.getCount(status);
    return this.numberFormatter.format(count);  // e.g., "1,234"
}
```

The Intl.NumberFormat() with no parameters uses browser default locale, which includes thousands separator for English locales (comma) and other appropriate separators for other locales.

## Implementation Quality

### Strengths

1. **Clean separation of concerns:**
   - `computeStatusCounts`: Pure function for counting
   - `getCount`: Simple accessor for template logic
   - `formatCount`: Display formatting
   - `statusDropdownShowHandler`: Event handling

2. **Performance optimizations:**
   - Single-pass counting algorithm (lines 180-183)
   - Event listener runs outside Angular zone (line 117)
   - On-demand computation instead of real-time

3. **Proper lifecycle management:**
   - Event listener added in ngOnInit
   - Event listener removed in ngOnDestroy (line 129)
   - Prevents memory leaks

4. **Accessibility:**
   - `[attr.aria-disabled]` on empty statuses
   - Click prevention for disabled items
   - "All" remains accessible even when empty

5. **Type safety:**
   - Map<ViewFile.Status | null, number> for counts
   - Null represents "All" option semantically

### Edge Cases Handled

1. **Empty file list:** computeStatusCounts returns Map with all statuses at 0, "All" at 0
2. **Missing status in Map:** getCount returns 0 via `?? 0` fallback (line 152)
3. **Dropdown element not found:** Graceful handling with `if (statusDropdown)` checks (lines 119, 127)
4. **All option when empty:** Explicitly NOT disabled (line 61 has simple click handler)

## Success Criteria Assessment

From PLAN.md success criteria:

| Criterion | Status | Evidence |
|-----------|--------|----------|
| UX-01: Status dropdown shows file count per status (e.g., "Downloaded (5)") | ✓ SATISFIED | All status options display formatted counts in parentheses |
| UX-02: "All" option shows total file count | ✓ SATISFIED | "All" displays total via `formatCount(null)` showing `files.size` |
| UX-03: Counts refresh when dropdown is opened (per CONTEXT.md decision) | ✓ SATISFIED | show.bs.dropdown event triggers computation, not real-time subscription |

All Phase 11 success criteria from ROADMAP.md are met.

---

_Verified: 2026-02-05T00:17:20Z_
_Verifier: Claude (gsd-verifier)_
