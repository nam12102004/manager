---
name: modular-dotnet-standards
description: Strict architecture profile for an established .NET modular monolith using module-owned persistence, explicit module registration, Repository + Unit of Work, versioned authenticated APIs, validation, mapping, reliability patterns, and focused tests. Use only when the user explicitly requests modular-monolith work or repository evidence proves independently owned bounded-context modules. Do not use for a single-project layered monolith, ordinary layered application, vertical slice, or independent service.
---

# Modular .NET Standards

Apply `dotnet-backend-standards` together with this architecture profile. Adapt names to the repository; do not copy examples literally.

## Activation Gate

Apply this profile only when either:

- the user explicitly scopes the task to a modular monolith or a named module; or
- repository evidence shows independently registered bounded-context modules plus enforced ownership boundaries, such as module projects and module-owned DbContexts/migrations.

Business-area folders, multiple controllers, or a Repository + Unit of Work alone do not satisfy the gate. If the gate fails, stop applying this profile and use `dotnet-backend-standards`. Never migrate an application to modular monolith as an incidental feature change.

## First Move

1. Read repo-local instructions, solution files, existing modules, and nearest tests before editing.
2. Detect the actual host project, module naming pattern, and whether canonical modules use an optional minimal shared kernel.
3. Before writing a new authorization/scoping check, aggregation, or calculation, grep for an existing implementation of the same rule across controllers, services, and repositories (for example, a "can this user access that record" check). Call the existing one. Do not re-derive the same business rule independently in a second location — that is exactly how one rule ends up implemented three different, inconsistent ways.
4. Keep module boundaries stronger than convenience.

## Reference Routing

- Read `references/architecture.md` when placing code, wiring host startup, touching module communication, or changing persistence boundaries.
- Read `references/csharp-style.md` before writing entities, DTOs, services, validators, mappings, logs, exceptions, or names.
- Read `references/api-testing.md` when adding endpoints, response contracts, validation, or tests.

## Non-Negotiables

- Each module owns its DbContext. Do not access another module's DbContext directly.
- Host project wires modules, aggregates read models, configures middleware, and exposes host-level hubs/snapshots. It does not own module business logic.
- Cross-module communication uses an established mechanism such as confirmed MediatR notifications, integration events, or narrowly owned contracts. Adding MediatR still requires the base dependency activation gate and v13+ license confirmation.
- Each controller action binds transport input, calls exactly one use-case/query service, and returns its result. Permission is declarative through an attribute or equivalent metadata. Controllers do not read claims, map DTOs, construct response payloads, execute business rules, or access persistence.
- Application services do not inject DbContext directly. They use `IUnitOfWork` or repositories.
- If a service needs to execute complex query logic (joins, eager loading, custom filters, pagination) or bulk operations (AddRange, RemoveRange), this logic MUST be placed inside custom repository methods, not written directly in service methods.
- Generic repositories do not return `IQueryable<T>`.
- A business operation that performs more than one logical write (update an entity, then insert a related record, then log an audit entry) runs inside one explicit transaction (`BeginTransactionAsync`/`CommitTransactionAsync`, or the DbContext execution strategy's transaction) — never as separate, independently-committed `SaveChangesAsync`/`CompleteAsync` calls that leave partial state on failure.
- A shared side-effect helper invoked from inside a larger operation (an audit logger, a notification dispatcher) does not call `SaveChangesAsync`/`CompleteAsync` itself. It stages changes on the ambient `DbContext`/`IUnitOfWork` and lets the caller's transaction commit them — otherwise calling it inside a loop silently turns one bulk operation into N independent partial commits.
- An entity whose state can be changed by two different actors racing on the same transition (a lock/approval flag plus the data that flag protects) carries an optimistic concurrency token (`RowVersion`/`[Timestamp]`). The write path that can race re-checks the flag inside the same transaction, and the nearest persistence boundary translates `DbUpdateConcurrencyException` to `ConcurrencyConflictException` for the global 409 mapping — do not rely on an earlier pre-transaction check.
- A service class is split along responsibility boundaries as soon as it takes on a second unrelated concern (e.g. entity CRUD plus file import/export plus unrelated side effects on another entity) — not after it has grown to cover five or six.
- APIs are authenticated by default, versioned, and every use-case/query service returns the repository's standard result/envelope. Controllers return that result without constructing a bare DTO, collection, anonymous response, success code, or message.
- Anonymous or credential-exchange endpoints (login, token exchange, password reset, public lookups) carry an explicit rate-limiting policy — never ship one with no throttle at all. Apply a default rate-limit policy globally for authenticated endpoints too.
- A global exception handler (`IExceptionHandler` + `UseExceptionHandler()`, or the framework's equivalent) is mandatory and registered from the commit that adds the first controller. It is the only path by which an unhandled exception reaches the client. New APIs return Problem Details plus stable error code and trace ID; established public custom error envelopes remain until migration is explicitly approved. Never expose a stack trace or framework development page.
- Every list endpoint whose row count can grow past what a UI reasonably renders at once (paged tables, audit logs, growing entity lists) returns a paged envelope (e.g. `PagedResponse<T>` with `Items`/`TotalCount`/`PageNumber`/`PageSize`) built from repository-level `Skip`/`Take` — never a full in-memory collection the client slices or filters itself. Reserve unpaged "return everything" endpoints for genuine lookups/dropdowns with a small, bounded row count. Do not make one endpoint serve both a paginated table and an unpaginated dropdown; give the dropdown its own route so paginating the table later can't break it.
- Reusable values and shared vocabularies such as success/error codes, audit action/entity names, role/permission names, statuses, and business thresholds are named constants. Truly local internal one-off strings may remain inline.
- Dates use UTC. Logs use structured logging.
- Behavior changes update nearest focused tests.

These requirements are release-blocking only after the activation gate passes. Repository-specific choices inside an established module outrank example technologies in this skill; for example, do not introduce MediatR or AutoMapper if the module deliberately uses another mechanism.

## Exception Protocol

Do not silently cross a module boundary or weaken an atomicity, authorization, concurrency, or contract rule. Report the violated rule, repository evidence, concrete risk, and smallest safe alternative. Request direction when the alternative changes ownership or public contracts.

## Default Verification

- Run the solution build, for example `dotnet build <SolutionName>.sln` or `.slnx`.
- Do not execute focused/full tests, migrations, application startup, runtime checks, or browser tooling unless explicitly requested. Keep required tests updated and hand their commands to the user.
- If migrations changed, inspect generation and startup wiring statically; generate a migration only when it is a required implementation artifact, never apply it merely as verification.
- Review every touched controller/endpoint for claims access, imperative permission checks, mapping, response construction, business logic, and persistence dependencies. Any hit is a release-blocking violation.
- If a client (SPA, mobile app) calls the changed endpoints, confirm it unwraps the envelope in one shared place (an HTTP client/service layer), not per call site — changing the envelope shape should require editing one file on the client, not every component that calls the API.
- Report the build command/result and all test/runtime/browser checks left to the user. Do not claim the profile is satisfied while the required build is failing or that an unexecuted check passed.
