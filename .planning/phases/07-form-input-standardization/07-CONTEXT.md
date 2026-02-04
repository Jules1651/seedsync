# Phase 7: Form Input Standardization - Context

**Gathered:** 2026-02-04
**Status:** Ready for planning

<domain>
## Phase Boundary

All form inputs (text fields, checkboxes) get consistent Bootstrap styling with app-appropriate focus states. Covers Settings, AutoQueue, and any modal forms. New form functionality or additional form types belong in other phases.

</domain>

<decisions>
## Implementation Decisions

### Focus state styling
- Focus rings use teal (app accent color) for consistency with buttons and selection
- Standard visible ring prominence — clear focus indicator when tabbing through controls
- Same focus treatment for both mouse click and keyboard tab (not focus-visible only)
- Ring includes outer glow/shadow effect (Bootstrap's box-shadow approach)

### Input appearance
- Subtle thin border that defines the input area without being prominent
- Background slightly lighter than page background on dark theme (visible field area)
- Slightly rounded corners (Bootstrap default ~4px border-radius)

### Checkbox style
- Standard checkboxes (not toggle switches)
- Checked state uses teal (app accent) to match focus rings and buttons
- Bootstrap's custom checkbox appearance with filled background when checked
- Disabled checkboxes are grayed out (reduced opacity, muted colors)

### Claude's Discretion
- Placeholder text color (appropriate contrast for dark theme readability)
- Error/invalid state color choice (red vs orange, appropriate for dark theme)
- Validation error message positioning (below input or inline)
- Invalid field visual indicators (border only vs border + icon)
- Validation timing (on blur/submit vs real-time, based on existing app patterns)

</decisions>

<specifics>
## Specific Ideas

- Teal accent color should be consistent with existing app buttons and selection states
- Focus ring should include the outer glow that Bootstrap adds by default

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-form-input-standardization*
*Context gathered: 2026-02-04*
