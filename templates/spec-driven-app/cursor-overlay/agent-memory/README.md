# Project agent memory

Persistent notes for Cursor engineering subagents. **Commit this folder** so the team shares institutional knowledge.

## Structure

```
.cursor/agent-memory/
├── README.md
├── _project/
│   ├── MEMORY.md
│   ├── specs-index.md
│   └── learning-journal.md   ← auto-append by plugin hooks
├── eng-orchestrator/
│   └── MEMORY.md
└── …
```

## Usage

1. **Start:** Read `_project/MEMORY.md` + your agent `MEMORY.md` + recent `learning-journal.md`
2. **End:** Update memory (skill: `spec-agent-memory`)
3. **Specs** in `.specs/` remain source of truth

Plugin: `specforge-engineering-team`
