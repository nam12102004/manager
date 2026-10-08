# C# Conventions

## Application Services

- Default to one capability service such as `IProductService` / `ProductService` for ordinary CRUD and queries.
- Do not split command/query services preemptively. When evidence shows independent read/write change patterns or a god service, split to `IProductCommandService` and `IProductQueryService` or narrower capability services.
- Do not retain `IProductService` as a forwarding facade after a split. Keep it only when it owns real orchestration, transaction boundaries, or policy.
- A controller may inject multiple services, but each action calls exactly one service.
- Detect a god service by unrelated capabilities, dependencies used by disjoint method groups, costly test setup, and multiple independent reasons to change. Do not use line count alone, and do not move code to a repository merely to shorten a service.

## Filters And Clients

- Name a feature filter `{Feature}FilterParams`, for example `ProductFilterParams`. Name a reusable paging base `PagedFilterParams`; avoid an ambiguous bare `FilterParams`.
- Name an external-system or protocol wrapper `I{Capability}Client`, for example `IEmailClient` or `IInventoryClient`.
- Name business/application orchestration `I{Capability}Service`, for example `IEmailService`. A service may render templates or apply policy and then call the client.
- Do not use `Sender` when the established `Client`/`Service` distinction applies.

## Mapping

- Use AutoMapper `16.x` at no lower than patched `16.1.1` as the default DTO/entity mapper after the license gate passes.
- Name a mapping profile `{Feature}MappingProfile` or follow the established repository profile suffix; keep it in Application/the owning feature and never inject `IMapper` into controllers.
- Keep one cohesive profile per owning service/feature; never collect unrelated service mappings in a shared god profile.
- Inject `IMapper` into the service/use case and remove private `Map`/`MapList` entity-to-DTO helpers. Use a small feature-owned mapping-source record when repository or policy data enriches the projection.
- Prefer `ProjectTo<TResponse>()` for EF read projection after filters/sorts and before materialization when the mapping is provider-translatable.
- Use explicit domain factories/behavior for protected aggregate creation/update; mapping MUST NOT bypass invariants.
- Avoid unreviewed `ReverseMap()` and validate configuration in tests.

## Service Comments

- Comment non-obvious business orchestration in the service/use case, not routine mapping configuration or self-evident assignments.
- For a multi-step workflow, use local numbered comments such as `// 1. Resolve references.`, `// 2. Apply business rules.`, and `// 3. Persist atomically.`. Restart numbering per workflow; do not number unrelated methods across a class.
- Keep comments current and intent-focused. Do not narrate every line or use numbered comments in AutoMapper profiles.

## Constants

- Name every constant container with the singular suffix `Constant`, for example `ProductErrorCodeConstant`, `ProductPermissionConstant`, `KpiThresholdConstant`, or `AuditActionConstant`.
- Use PascalCase for constant members. A serialized string value may use the contract's stable form such as `PRODUCT_NOT_FOUND`.
- Use `const` for compile-time primitive/string values and `static readonly` otherwise.
- Place a constant beside the capability that owns its vocabulary. A repository may use an established technical `Common/Constants/` folder, but every contained `...Constant` type must remain capability-scoped; do not create one global constants class or mix unrelated vocabularies.
- Use constants for reusable/shared error codes, permissions, statuses, audit vocabulary, and business thresholds. Keep truly local internal non-contractual one-off strings inline.
- Do not localize Angular-facing UI text in the backend. Stable or reused safe fallback response messages may use an owning constant container such as `ProductMessageConstant`; Angular still localizes the stable success/error code and uses the backend message only for unknown-code fallback. Keep truly one-off internal strings inline.

## Enums

- Name enum types with the suffix `Enum`, for example `ProductStatusEnum`.
- Declare every ordinary member with an explicit value spaced by ten: `Draft = 10`, `Active = 20`, `Archived = 30`. Never rely on ordinal assignment, renumber a published member, or reuse a retired number for a different meaning.
- Serialize enums through HTTP as strings and persist them with EF Core string conversion. Configure a suitable column length and migrate stored values when renaming a member.
- Treat an enum-member rename as an API and data migration. Do not silently map unknown API or database values to a default; invalid API input returns 400 Problem Details.
- Do not add `Unknown = 0` unless Unknown is a real domain state.
- Use an enum only for a finite, stable, closed set. Use configurable/reference data when users or operations can add values. Do not use enums for error codes, permission codes, routes, or thresholds.
- Do not introduce `[Flags]` without confirmation and a real independently combinable set. When confirmed, use `None = 0` and powers of two (`1, 2, 4, 8...`) instead of the ordinary increments-of-ten convention.

## Persistence And Concurrency

- Treat EF Core `DbContext` as an existing repository/unit-of-work implementation. Do not wrap simple CRUD mechanically.
- Add a custom repository when persistence logic has meaningful reuse, joins/grouping/aggregation/subqueries, complex dynamic filters/sorts, consistent object-graph or data-scope rules, provider-specific SQL/performance strategy, or it obscures the application service's business flow.
- A normal paged/filter/sort/projection query may remain in the application service in a confirmed N-Layer project. A repository exposes an intent-named operation and never leaks `IQueryable` merely to move composition elsewhere.
- Do not require a custom Unit of Work merely because a repository exists. Add one only when the architecture requires an abstraction or a use case coordinates multiple repositories/persistence operations.
- Translate `DbUpdateConcurrencyException` at the nearest persistence boundary into `ConcurrencyConflictException` with a stable error code such as `ConcurrencyConflict`; the global handler maps it to HTTP 409 Problem Details. Never expose EF/database details.
