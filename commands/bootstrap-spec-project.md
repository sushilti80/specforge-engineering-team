---
name: bootstrap-spec-project
description: Scaffold .specs/, agent memory, and rules into the current or target project
---

# Bootstrap spec-driven project

Run from terminal (replace path):

```bash
bash scripts/bootstrap-project.sh /path/to/your/project
```

Or from plugin install location:

```bash
bash ~/.cursor/plugins/local/specforge-engineering-team/scripts/bootstrap-project.sh .
```

Then:

1. Enable plugin **specforge-engineering-team** in Cursor Settings → Plugins
2. Edit `.cursor/agent-memory/_project/MEMORY.md`
3. Edit `.specs/requirements/REQ-001-product-scope.md`
4. Start Agent chat: `/spec-pipeline` with Tier 1 `new-application`

See `docs/BOOTSTRAP-SPEC-DRIVEN-PROJECT.md` for the full guide.
