# APIs And Testing

## Contents

- API Rules
- Validation
- Tests

## API Rules

- Choose one style per bounded context: controllers or Minimal APIs.
- Default every endpoint to authenticated access.
- Use anonymous access only for truly public endpoints.
- Use API versioning, usually URL segment versioning such as `/api/v1/products`.
- Inject only the correct use-case/query service into controllers/endpoints.
- Keep controller actions to binding input, calling exactly one use-case/query service, and returning its result. Apply permission through an attribute or equivalent declarative metadata.
- Reject claims access, imperative permission checks, mapping, response construction, business logic, `DbContext`, `IUnitOfWork`, repositories, or persistence implementations in controllers/endpoints.
- Build the standard `SuccessResponse<T>` or application result inside the use-case/query service. Do not construct success/error codes, messages, DTO mappings, or envelopes in the controller.
- Every endpoint returning a list that can grow (not a small fixed lookup) takes `page`/`pageSize` (or equivalent) query parameters and returns a paged envelope — see the `PagedResponse<T>` example below. Do not ship `Task<IEnumerable<T>>`/`Task<List<T>>` for anything but genuinely bounded, small collections (enum-like lookups, a handful of config rows).
- Register a global exception handler (`IExceptionHandler`, `UseExceptionHandler()`) before adding the first controller. For a new API, map typed custom exceptions to Problem Details with stable error code and trace ID. Preserve an established public custom error envelope until migration is approved; never return a framework development error page.
- Use explicit binding attributes in controllers: `[FromRoute]`, `[FromQuery]`, `[FromBody]`.
- Async action names end with `Async`.
- Return HTTP 200 with `SuccessResponse<T>(Code, Message, Data)` for every successful create, read, update, delete, and action. Use `data: null` when there is no payload; do not return 201 or 204.
- Throw domain exceptions or return typed not-found responses for missing resources.

Controller example:

```csharp
[ApiController]
[Route("api/v{version:apiVersion}/[controller]")]
[ApiVersion("1.0")]
[Authorize]
public sealed class ProductController(IProductService productService) : ControllerBase
{
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetProductByIdAsync(
        [FromRoute] Guid id,
        CancellationToken cancellationToken)
    {
        var result = await productService.GetProductByIdAsync(id, cancellationToken);
        return Ok(result);
    }
}
```

Minimal API example:

```csharp
public static class ProductEndpoints
{
    public static IEndpointRouteBuilder MapProductEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("api/v{version:apiVersion}/products")
            .WithTags("Products")
            .RequireAuthorization();

        group.MapGet("/{id:guid}", (
            Guid id,
            IProductService productService,
            CancellationToken cancellationToken) =>
            productService.GetProductByIdAsync(id, cancellationToken));

        return app;
    }
}
```

Paged list endpoint — the shape every growable list follows, built on repository-level `Skip`/`Take` (never an in-memory `.Skip().Take()` over a fully materialized list):

```csharp
public sealed class PagedResponse<T>
{
    public IReadOnlyList<T> Items { get; init; } = [];
    public int TotalCount { get; init; }
    public int PageNumber { get; init; }
    public int PageSize { get; init; }
    public int TotalPages => PageSize <= 0 ? 0 : (int)Math.Ceiling(TotalCount / (double)PageSize);
}

[HttpGet]
public async Task<IActionResult> GetProductsAsync(
    [FromQuery] int pageNumber = 1,
    [FromQuery] int pageSize = 20,
    CancellationToken cancellationToken = default)
{
    var result = await productService.GetPagedAsync(pageNumber, pageSize, cancellationToken);
    return Ok(result);
}
```

A dropdown/lookup that genuinely needs every row gets its own unpaged route rather than overloading the same one:

```csharp
[HttpGet("lookup")]
public async Task<IActionResult> GetProductsLookupAsync(
    CancellationToken cancellationToken)
{
    var result = await productService.GetAllForLookupAsync(cancellationToken);
    return Ok(result);
}
```

Forbidden persistence access in a controller:

```csharp
[HttpGet("users")]
public async Task<IActionResult> GetUsersAsync(
    [FromServices] IUnitOfWork unitOfWork)
{
    var users = await unitOfWork.Users.GetAllAsync();
    return Ok(users);
}
```

Required boundary:

```csharp
[HttpGet("users")]
public async Task<IActionResult> GetUsersAsync(
    CancellationToken cancellationToken)
{
    var result = await userQueryService.GetUsersAsync(cancellationToken);
    return Ok(result);
}
```

## Validation

- Put request validation in FluentValidation validators.
- Register validators by assembly scanning when possible.
- Keep service methods focused on business rules, not request shape checks.
- Return a stable field-level validation `code` plus safe interpolation `params`. Keep the backend message as a fallback only; Angular owns localization.

## Tests

- Unit tests mock repositories, Unit of Work, mapper, message bus, clock, and external clients.
- For CRUD behavior, test the service/use-case. Derive failure cases from actual exceptions and branches in that logic.
- Add controller tests only when transport-specific behavior requires proof; a controller test must never need a repository, `IUnitOfWork`, or DbContext mock.
- Do not use EF in-memory provider for unit tests.
- Keep Arrange, Act, Assert sections visible.
- Test names follow `{Method}_Should{Expected}_When{Condition}`.
- Write paths verify repository calls and `SaveChangesAsync`.
- Not-found paths assert the expected domain exception.
- When an optional minimal shared kernel changes, add broad tests or run the full suite because multiple modules may consume the changed domain primitive.

Example unit test shape:

```csharp
public sealed class ProductServiceTests
{
    private readonly Mock<IRepository<Product, Guid>> _productRepositoryMock = new();
    private readonly Mock<IUnitOfWork> _unitOfWorkMock = new();
    private readonly Mock<IMapper> _mapperMock = new();

    [Fact]
    public async Task CreateProductAsync_ShouldSaveChanges_WhenRequestIsValid()
    {
        // Arrange
        var request = new CreateProductRequest("Test", null);

        // Act
        await service.CreateProductAsync(request);

        // Assert
        _unitOfWorkMock.Verify(
            unitOfWork => unitOfWork.SaveChangesAsync(It.IsAny<CancellationToken>()),
            Times.Once);
    }
}
```

Adapt the mocking framework and helper builders to the target repo.
