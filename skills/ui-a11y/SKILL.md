---
name: ui-a11y
description: >
  Accessibility checklist for interactive UI: labels, keyboard, focus, contrast,
  and ARIA for overlays. Use when building or changing components, pages, dialogs,
  menus, forms, or any user-facing control. Apply WCAG 2.1 AA intent without
  turning the task into a full audit unless REQ asks for it.
---

# UI accessibility (functional a11y)

Ship controls that work with **keyboard + screen reader basics**. Pair with **`ui-shadcn`** (Radix primitives already help) and **`ui-forms`** (labels/errors).

## Non-negotiables for every interactive change

1. **Name:** Icon-only buttons need `aria-label` (or visible text).
2. **Label:** Inputs have associated labels — placeholder is not a label.
3. **Keyboard:** Tab order reaches new controls; Enter/Space activate buttons; Esc closes overlays when the kit supports it.
4. **Focus:** Opening a dialog/sheet moves focus inside; closing returns focus to the trigger.
5. **Hit target:** Don't shrink clickable areas below ~44px on primary mobile actions unless the design system already defines smaller compact controls.

## Overlays (Dialog / Sheet / Drawer / AlertDialog)

- Always include **Title** (visually or `sr-only`).
- Include **Description** (or `sr-only`) when the primitive requires it — silence console a11y warnings.
- Trap focus while open; do not leave focus on a hidden background control.

## Content & semantics

| Prefer | Avoid |
|--------|--------|
| `<button>` for actions | `<div onClick>` for primary actions |
| `<a href>` for navigation | Button that only `router.push` without a real link when crawl/open-in-new-tab matters |
| Lists / headings in order | Random bold text as fake headings |
| `alt` on meaningful images | Empty alt on decorative only |

## Color & state

- Don't convey meaning by color alone (add text/icon).
- Keep focus rings visible; don't `outline-none` without a replacement focus style from the design system.
- Error text must be readable (contrast) and tied to the field.

## Scope control

- In scope: controls you add/change + their immediate container.
- Out of scope unless REQ says: full-site WCAG audit, axe CI setup, redesign of unrelated pages.

## Done check

- [ ] Can complete the primary path keyboard-only
- [ ] Icon buttons named
- [ ] Overlay titles present; focus not lost
- [ ] Form errors associated with fields (if forms in scope)
