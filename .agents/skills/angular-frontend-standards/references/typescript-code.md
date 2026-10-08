# TypeScript, Naming, Types, And Imports

## MUST-AUTO

- Keep TypeScript and Angular template strictness enabled. Do not weaken project compiler options to land a feature.
- Do not introduce explicit `any`. Use a concrete contract or `unknown` plus narrowing at an untrusted boundary.
- Follow the nearest ASRS feature's Angular DI convention; use `inject()` for new or materially changed code when it fits that established pattern.
- Remove unused imports and variables. Import only the component-library modules actually used.
- Use `readonly` for immutable component dependencies, signal handles, inputs, outputs, and constant collections.

## MUST-REVIEW

- Name files after their primary exported symbol using repository casing: kebab-case files, PascalCase types/classes, camelCase values and methods.
- Use business and UI intent in names. Avoid generic state names such as `data`, `items`, `flag`, or `handle` when the owning scope contains more than one concept.
- Keep functions cohesive. Extract a named operation when a method mixes query construction, state transitions, mapping, and UI side effects.
- Do not use casts to silence a known contract mismatch. A boundary cast must sit beside runtime narrowing or an explicit invariant.
- Feature folders may import core/shared and their own feature. Cross-feature imports require an intentional public contract; relative-path convenience is not a boundary.
- Use configured aliases when they exist. Do not introduce aliases as part of an unrelated feature.

## SHOULD

- Prefer discriminated unions to coupled booleans for mutually exclusive UI state.
- Prefer small pure mapping functions for DTO-to-view-model conversion.
- Keep exports narrow; do not add barrels that expose feature internals.
