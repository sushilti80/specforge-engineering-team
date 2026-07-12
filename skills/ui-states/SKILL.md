---
name: ui-states
description: >
  Require loading, empty, error, and success/optimistic UI for async surfaces.
  Use when building lists, detail pages, dashboards, forms with remote submit,
  infinite scroll, or any screen that fetches or mutates data. Prevents "happy
  path only" UIs that look done but break when the network fails.
---

# UI async states (functional completeness)

If the UI talks to a server (or cache), **four states** exist. Missing one = incomplete.

## State matrix (per async surface in scope)

| State | User sees | Minimum bar |
|-------|-----------|-------------|
| **Loading** | Skeleton/spinner/placeholder matching layout | No blank flash that looks like "empty" |
| **Empty** | Honest empty copy + optional CTA | Not a broken table or infinite spinner |
| **Error** | Message + retry or guidance | Not a white screen / uncaught overlay only |
| **Success / data** | The real content | Matches REQ acceptance criteria |

Mutations (create/update/delete) also need:

| State | Rule |
|-------|------|
| **Pending** | Disable duplicate submit; show progress on the action |
| **Mutation error** | Keep user data; show recoverable error |
| **Optimistic** (optional) | Only if repo already uses it; always define rollback on failure |

## Patterns

1. Reuse the app's existing Skeleton / Alert / Empty / Toast components (**`ui-shadcn`**).
2. Distinguish **empty** vs **error** vs **still loading** — never use the same UI for all three.
3. List + detail: each has its own state machine if they fetch separately.
4. Stale data: if using TanStack Query (or similar), follow existing `isPending` / `isFetching` / `isError` conventions in the repo — don't invent a parallel status enum.

## Anti-patterns

- Happy-path-only mock with `data!` non-null assertions and no branch
- Spinner forever with no timeout/error path
- Toast-only error while the page still looks like it succeeded
- Empty state that says "No data" during the first load

## Checklist before HANDOFF

- [ ] Loading state for every new fetch in scope
- [ ] Empty state when result set can be zero
- [ ] Error + recovery (retry or link) for failed fetch/mutation
- [ ] Pending guard on primary mutating actions
- [ ] No secrets leaked into error strings shown in UI
