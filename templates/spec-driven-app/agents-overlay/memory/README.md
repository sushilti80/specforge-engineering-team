# SpecForge — project agent memory

Persistent notes for engineering subagents. **Commit this folder** so the team shares institutional knowledge.

Canonical path: **`.agents/memory/`** (tool-neutral). Cursor also resolves via `.cursor/agent-memory` symlink.

## Structure

```
.agents/memory/
├── README.md
├── _project/
│   ├── MEMORY.md
│   ├── specs-index.md
│   └── learning-journal.md   ← auto-append by Cursor plugin hooks
├── eng-orchestrator/
│   └── MEMORY.md
└── …
```

## Usage

1. **Start:** Read `_project/MEMORY.md` + your agent `MEMORY.md` + recent `learning-journal.md`
2. **End:** Update memory (skill: `spec-agent-memory`)
3. **Specs** in `.specs/` remain source of truth

Harness: `specforge-engineering-team`
