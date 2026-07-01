---
name: bootstrap-spec-project
description: Scaffold .specs/, agent memory, AGENTS.md, and rules into the current or target project
---

# Bootstrap spec-driven project

Run from terminal (replace path):

```bash
bash scripts/bootstrap-project.sh /path/to/your/project
```

Optional platform overlay:

```bash
bash scripts/bootstrap-project.sh --platform opencode /path/to/your/project
```

Or from plugin install location:

```bash
bash ~/.cursor/plugins/local/specforge-engineering-team/scripts/bootstrap-project.sh .
```

Then:

1. Enable plugin **specforge-engineering-team** in Cursor Settings → Plugins (Cursor only)
2. Edit `.agents/memory/_project/MEMORY.md`
3. Edit `.specs/requirements/REQ-001-product-scope.md`
4. Start work — see project `AGENTS.md` or `/spec-pipeline` (Cursor/OpenCode)

See `docs/BOOTSTRAP-SPEC-DRIVEN-PROJECT.md` and `docs/MULTI-TOOL.md` for the full guide.
