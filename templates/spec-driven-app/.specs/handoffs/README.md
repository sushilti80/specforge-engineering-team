# Handoffs (checkpoints)

Ephemeral chat, durable specs (**Principle 8**).

At each **gate boundary**, the orchestrator may write a checkpoint file here before delegating to a fresh subagent or starting a new parent chat.

Naming: `GATE-<slug>.md` (e.g. `GATE-REQ-001-approved.md`, `GATE-implement-complete.md`)

Template: see `ENGINEERING-PLAYBOOK.md` §5 — Checkpoint and reset policy.

Do not duplicate spec content—link to `.specs/requirements/`, `.specs/architecture/`, etc.
