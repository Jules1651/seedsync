# Project Milestones: Unify UI Styling

## v1.1 Dropdown & Form Migration (Shipped: 2026-02-04)

**Delivered:** Complete UI styling unification with Bootstrap-native dropdowns, consistent form inputs with teal focus states, and dark theme across all components.

**Phases completed:** 6-8 (4 plans total)

**Key accomplishments:**

- Migrated file dropdowns to Bootstrap's native component with dark theme styling
- Unified form inputs with teal focus rings across Settings, AutoQueue, and Files pages
- Implemented close-on-scroll behavior preventing orphaned dropdown menus
- Removed 150+ lines of custom SCSS placeholders in favor of CSS variable theming
- Verified 387 unit tests pass with visual QA approval at desktop and tablet widths
- Zero unused SCSS code confirmed via comprehensive audit

**Stats:**

- 24 files created/modified
- ~2,900 lines changed (mostly .planning documentation)
- 3 phases, 4 plans, 11 tasks
- 1 day (same-day completion)

**Git range:** `8d57357` → `03b3315`

**What's next:** Project styling unification complete. Future work could include dark mode toggle or full @use migration.

---

## v1.0 Unify UI Styling (Shipped: 2026-02-03)

**Delivered:** Unified Bootstrap 5 SCSS architecture across SeedSync's Angular frontend with consistent colors, selection highlighting, and button styling.

**Phases completed:** 1-5 (8 plans total)

**Key accomplishments:**

- Established Bootstrap SCSS infrastructure with two-layer customization system
- Consolidated all colors to Bootstrap variables with zero hardcoded hex values
- Unified selection highlighting using teal (secondary) color palette with visual hierarchy
- Standardized all buttons to Bootstrap semantic variants with 40px sizing
- Removed legacy custom %button SCSS placeholder entirely

**Stats:**

- 18 files created/modified
- 282 lines added, 234 deleted
- 5 phases, 8 plans, ~20 tasks
- 1 day from start to ship

**Git range:** `feat(01-01)` → `refactor(05-02)`

**What's next:** v1.1 Dropdown & Form Migration

---
