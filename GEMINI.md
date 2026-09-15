# GEMINI.md
## Gemini CLI Instructions

This repository uses `AGENTS.md` as the master implementation instruction file.

Before making any code change:

1. Read `AGENTS.md` completely.
2. Read the authoritative specification files listed inside it.
3. Follow the specification precedence defined in `AGENTS.md`.
4. Do not weaken RLS, payment security, tenant isolation, or repository boundaries to make implementation easier.
5. Follow the implementation phase order in `AGENTS.md`.
6. Run format/analyze/tests for changed areas before reporting completion.

If this file conflicts with `AGENTS.md`, `AGENTS.md` wins.

Important current constraint:

```text
The existing project specifications are sufficient to START implementation.

Do not declare the production backend complete until the repository also contains
and validates the required security/business implementation such as:

RLS_POLICIES.sql
RPC_FUNCTIONS.sql
Storage policies
Realtime setup
Payment Edge Functions
```

Do not invent permissive security behavior when those files are absent.
