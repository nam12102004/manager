# ASRS Angular Repository Profile

This file records repository facts. Topic references own the conventions.

## Runtime And Libraries

- Application root: `src/Aubot.WCS.WebApp`.
- Angular 22 standalone components with strict TypeScript and strict templates.
- Angular Material/CDK 22 are installed. Tailwind CSS 3.4 and scoped SCSS provide layout and styling.
- Signals own local UI state; RxJS owns HTTP and event streams. SignalR 10 provides warehouse realtime updates.
- Pixi.js 8 and Three.js 0.185 support warehouse visualization features.
- `TranslationService`, `I18N_KEYS`, and the shared `TranslatePipe` own localization.
- Vitest 4 runs unit tests through Angular's unit-test builder.

## Repository Shape

- `core`: app-wide API configuration, auth, guards, models, interceptors, and utilities.
- `shared`: feature-agnostic components and directives.
- `features`: feature-local pages, components, schemas, state, and workflows.
- `layout`: authenticated application shell.
- Feature API services own transport; use the nearest existing OMC/RCS service and facade patterns.
- Protected routes are lazy-loaded and permission guarded.

## UI And Canonical Evidence

- `src/styles.scss` and component `.scss` files own the current SCSS design system; Tailwind 3 utilities are available for layout.
- Use Angular Material/CDK only where its installed components or primitives fit the surface; preserve the established native semantic table and custom warehouse visualization patterns where they are canonical.
- Do not introduce NG-ZORRO, Zod, NgRx, or Jest by default. No frontend ESLint/lint script is configured.

## Commands

Run from `src/Aubot.WCS.WebApp`:

- `npx.cmd prettier --check <changed-files>`
- `npx.cmd tsc -p tsconfig.app.json --noEmit`
- `npm.cmd test -- --watch=false`
- `npm.cmd run build -- --configuration=production`

Run the convention-audit test and the ASRS frontend audit from the repository root. Review heuristic findings; they are not configured lint rules. If Angular cache produces a native crash or locked output, retry with `CI=true` and report the locking process rather than changing source code.
