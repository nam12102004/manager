# Tests, Browser Checks, Tooling, And Completion

## Required Gate

Unless the user explicitly narrows verification, run the configured gates in this order:

1. format check;
2. ESLint, if an ESLint command is configured;
3. TypeScript application typecheck;
4. focused unit tests for changed behavior;
5. the repository's CI unit-test command;
6. production build.

Run browser/Playwright verification when the change depends on viewport, DOM geometry, overlays, table containment, scrolling, focus, keyboard interaction, drag/drop, or another browser-only behavior.

## Test Standard

- Test observable behavior, ownership boundaries, requests, state transitions, error states, and user intents rather than private implementation details.
- Cover success, authoritative failure, stale/cancelled async responses, empty data, and retry where relevant.
- Component tests verify typed inputs/outputs and meaningful rendering states.
- Facade tests verify query semantics, cancellation/paging, state ownership, and API coordination without requiring a page fixture.
- Browser tests verify behavior that compilation and jsdom cannot prove.

## Convention Audit

Run:

```powershell
node .agents/skills/angular-frontend-standards/scripts/audit-frontend-conventions.mjs src/Aubot.WCS.WebApp/src/app
```

Use `--changed --strict` to fail release-blocking findings in changed files. Heuristic findings remain review items until a human or agent confirms their semantics.

## Completion Evidence

- Compare every changed component output with all parent bindings.
- Confirm every tab body follows the installed tabs implementation's component boundary and tabular collections use the current repository's accessible table pattern.
- Inventory changed files above the 300-line TypeScript or 250-line template review thresholds and record why any remains cohesive.
- Report every command and result. Do not claim browser behavior passed unless it was exercised.

ASRS does not configure ESLint or a dedicated `format:check`, `typecheck`, or CI test script. Use the installed Prettier and TypeScript CLI commands from the repository profile, Angular's Vitest test command, and the production build; report any missing package script as unconfigured rather than PASS.
