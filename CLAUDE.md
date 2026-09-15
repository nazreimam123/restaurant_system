# CLAUDE.md
## Claude Code Instructions

Use `AGENTS.md` as the master repository instruction file.

Mandatory before implementation:

```text
Read AGENTS.md.
Read the authoritative specifications referenced by AGENTS.md.
Follow its precedence, architecture, security, implementation phases, and verification rules.
```

Do not:

```text
disable RLS
use service-role keys in Flutter
perform critical order/payment authority updates directly from Flutter
invent API fields that conflict with API_CONTRACTS.md
invent data fields that conflict with DATA_MODELS.md / DATABASE_SCHEMA.sql
```

If a critical backend implementation specification is absent, keep that integration
behind a typed repository/interface, document the blocker, and continue safe work.

`AGENTS.md` overrides this file if there is any conflict.
