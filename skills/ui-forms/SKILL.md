---
name: ui-forms
description: >
  Build working forms: schema validation, field errors, submit/pending/disabled
  states, and accessible labels. Use when adding or changing forms, wizards,
  settings panels, login/signup, filters with submit, or any user input that
  posts/patches data. Prefer the project's existing form stack (Zod, React Hook
  Form, Server Actions, Formik, etc.). Do NOT invent a new form library.
---

# UI forms (functional validation + submit UX)

A form is not done when fields render — it is done when **invalid input is blocked**, **errors are visible**, and **submit cannot double-fire**.

## Stack detection (pick what the repo already uses)

1. Zod / Valibot / Yup schemas near forms or `lib/validations`
2. React Hook Form, Formik, or uncontrolled native + Server Actions
3. Next.js: Server Actions + `useActionState` / `useFormStatus` when already the pattern
4. shadcn `Form` / `FormField` if present → compose with **`ui-shadcn`**

Do not add a form library if native + schema (or existing stack) covers the REQ.

## Required behaviors

| Behavior | Rule |
|----------|------|
| Schema | One source of truth for client (± server) validation |
| Field errors | Shown next to the field (or announced); not only a toast |
| Labels | Every control has a visible `<label>` or `aria-label` |
| Submit | Disabled / pending while in-flight; prevent double submit |
| Success | Clear outcome (navigate, toast, reset) per REQ |
| Server errors | Map API/field errors back onto fields when shape allows |
| Defaults | Prefill from props/loader data; don't wipe user edits on re-render |

## Implementation ladder (ponytail-aligned)

1. Reuse an existing form pattern in the same feature area.
2. Else: schema + existing form helpers in the repo.
3. Else: minimal controlled inputs + schema parse on submit (no new deps).
4. Only then introduce a helper — and only if ARCH/REQ justifies it.

## Checklist before HANDOFF

- [ ] Empty submit shows validation (not a blank request)
- [ ] Invalid fields are keyboard-reachable and errors are associated (`aria-describedby` / FormMessage)
- [ ] Pending state on primary action
- [ ] Network/API failure has a user-visible path (inline or page-level — see **`ui-states`**)
- [ ] No secrets in client-visible defaults
