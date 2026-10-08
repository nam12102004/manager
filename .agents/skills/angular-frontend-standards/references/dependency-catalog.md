# Angular Dependency Catalog

Use the latest stable version compatible with the installed Angular version. Preserve an established compatible library and ask before replacement or migration.

## ASRS Baseline

- Preserve the installed design system. ASRS uses Angular Material/CDK 22, Tailwind CSS 3, and scoped SCSS; reuse these only where the affected feature already follows them.
- Do not add NG-ZORRO, Zod, NgRx, Jest, or another high-level package by default. Ask before first-adopting a dependency or mixing design systems.
- Tailwind is installed and may be used for layout, spacing, and responsive behavior. It does not replace semantic HTML or an installed component's interaction/accessibility behavior.
- If a future repository explicitly selects NG-ZORRO, use its current official setup and supported components for that repository. NG-ZORRO examples below are conditional reference material.

Preserve existing styling and ask before a broad stylesheet or design-system migration.

## Conditional Packages

- **Angular CDK**: already installed in ASRS. Use its framework primitives for drag-and-drop, sortable lists, virtual scrolling, overlays, accessibility, focus management, and other interaction infrastructure when the nearest Material/shared pattern does not provide the required behavior. Prefer CDK DragDrop over native HTML5 drag events or custom pointer/document listeners for Angular Kanban and reorderable UI. Keep CSS/Tailwind limited to layout, containment, presentation, and CDK state/animation hooks.
- Treat a transitive Angular CDK installation as unavailable for direct application imports until `@angular/cdk` is declared in the application's own dependencies. Ask before adding that direct dependency unless the user has already explicitly requested CDK or a library-backed implementation.
- **Three.js**: use when the confirmed feature requires interactive 3D rendering. Reuse it when installed. When absent, explain why 3D is needed and ask before adding it. Do not use Three.js for ordinary charts, decorative effects, or layouts that CSS/SVG/component-library capabilities already cover.
- For charts, state, OIDC, i18n, or test libraries, inventory installed capabilities first. If one option is already canonical in the nearest compliant feature, reuse it. If multiple installed options fit and none is clearly canonical, ask before selecting or mixing them. If a suitable installed option has never been used in the repository, report it and ask before first adoption. If no suitable installed capability exists, present the best compatible option and ask the user which library to add.
