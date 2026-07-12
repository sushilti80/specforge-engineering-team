---
name: ui-shadcn
description: >
  Reuse existing design-system / shadcn/ui (or project UI kit) components before
  inventing raw markup. Use when building or changing React/Next UI, forms,
  dialogs, tables, navigation, or any screen that should match the app's
  component library. Also when the user mentions shadcn, Radix, components.json,
  or design-system components. Do NOT invent a new UI kit unless ARCH requires it.
---

# UI component reuse (shadcn / design system)

Prefer **compose existing primitives** over custom Tailwind soup. Ponytail still applies: reuse beats rewrite.

## Before writing UI

1. Detect the kit: `components.json`, `components/ui/`, ARCH design-system section, Storybook, or package imports (`@/components/ui/*`).
2. If shadcn/Radix-style kit exists → **use it**. Do not add MUI/Ant/Chakra unless ARCH says so.
3. List candidates for the screen (Button, Input, Dialog, Sheet, Table, Tabs, Form, Select, Toast, Skeleton, …) then implement with those only.
4. Match existing variants, sizes, spacing tokens, and icon set already in the repo (e.g. Lucide).

## Composition rules

| Need | Prefer |
|------|--------|
| Actions | Existing `Button` variants |
| Text input | Kit `Input` / `Textarea` / `Select` / `Checkbox` / `Switch` |
| Modal / drawer | `Dialog` / `Sheet` / `Drawer` (always include Title; Description or `sr-only`) |
| Feedback | Existing toast/alert/skeleton patterns |
| Data | Existing `Table` / `Card` / list patterns in the app |
| Nav | Existing sidebar/tabs/breadcrumb patterns |

- **Install missing shadcn pieces via CLI** when the project already uses shadcn (`npx shadcn@latest add …`). Do not hand-roll equivalents.
- No one-off color hexes when theme tokens / CSS variables exist (`bg-primary`, `--muted-foreground`).
- Dark mode: use the project's token-aware classes; don't hardcode light-only colors.

## Do not

- Scaffold a parallel component library "for consistency later"
- Copy paste large third-party examples that ignore local primitives
- Wrap every control in a new abstraction with one caller

## Done check

- [ ] No new base primitive that duplicates `components/ui` (or ARCH kit)
- [ ] Interactive overlays have accessible titles
- [ ] Visual density matches neighboring screens in the same app
