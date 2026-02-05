---
phase: 11-status-dropdown-counts
plan: 01
subsystem: ui
tags: [angular, bootstrap5, dropdown, file-filtering, ux]

# Dependency graph
requires:
  - phase: 10-lint-cleanup
    provides: Clean TypeScript codebase with consistent lint rules
provides:
  - Status dropdown displays file counts in format "Status (N)"
  - On-demand count computation triggered by dropdown open event
  - Disabled states for empty statuses with accessibility attributes
  - Thousands separator formatting for large counts
affects: [ui, file-management]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Bootstrap 5 dropdown event listeners (show.bs.dropdown)"
    - "On-demand computation triggered by user interaction (not real-time)"
    - "Intl.NumberFormat for locale-aware thousands separator"

key-files:
  created: []
  modified:
    - src/angular/src/app/pages/files/file-options.component.ts
    - src/angular/src/app/pages/files/file-options.component.html

key-decisions:
  - "Counts refresh on dropdown open (not real-time) per CONTEXT.md"
  - "Single-pass count computation for efficiency"
  - "All statuses always visible with (0) count, disabled states for empty"
  - "All option never disabled even when (0)"

patterns-established:
  - "Event listener pattern: add in ngOnInit runOutsideAngular, remove in ngOnDestroy"
  - "Count computation: store latest data reference, compute on-demand triggered by UI event"
  - "Template access: public formatCount() and getCount() methods"

# Metrics
duration: 2min
completed: 2026-02-04
---

# Phase 11 Plan 01: Status Dropdown Counts Summary

**Status dropdown displays file counts per status with on-demand refresh, thousands separator formatting, and disabled states for empty statuses**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-05T00:12:42Z
- **Completed:** 2026-02-05T00:14:52Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Status dropdown button and menu items show counts in format "Status (N)"
- On-demand count computation triggered by Bootstrap dropdown show event
- Thousands separator formatting using browser default locale
- Empty statuses display "(0)" and are disabled/non-clickable
- "All" option shows total count and remains always enabled

## Task Commits

Each task was committed atomically:

1. **Task 1: Add on-demand count computation triggered by dropdown open** - `711de62` (feat)
2. **Task 2: Update HTML to display counts with disabled states** - `e229a3f` (feat)

## Files Created/Modified
- `src/angular/src/app/pages/files/file-options.component.ts` - Added statusCounts Map, computeStatusCounts() method, formatCount()/getCount() public methods, dropdown event listener for on-demand refresh
- `src/angular/src/app/pages/files/file-options.component.html` - Added count display in button and menu items, aria-disabled attributes, click prevention for disabled items

## Decisions Made

**Count update timing:**
- Counts refresh when dropdown is opened (show.bs.dropdown event), not continuously
- Initial counts computed on component init so button displays count before first dropdown open
- Honors CONTEXT.md decision: "Counts refresh when dropdown is opened (not real-time)"

**Computation efficiency:**
- Single-pass approach: initialize all status counts to 0, then forEach to increment
- Store latest files reference to avoid subscription on every dropdown open

**Disabled state implementation:**
- Keep existing `[class.disabled]` binding using isStatusEnabled (semantic equivalence)
- Add `[attr.aria-disabled]` for accessibility
- Add click prevention using ternary in (click) handler
- "All" option never disabled per CONTEXT.md

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - implementation straightforward, all tests passed first time.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Status dropdown counts feature complete
- Phase 11 complete (single plan phase)
- v1.3.0 Polish & Clarity milestone complete (Phases 10-11)
- Ready for next milestone planning

---
*Phase: 11-status-dropdown-counts*
*Completed: 2026-02-04*
