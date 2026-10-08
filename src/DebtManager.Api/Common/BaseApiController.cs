using DebtManager.Application.Common;
using Microsoft.AspNetCore.Mvc;

namespace DebtManager.Api.Common;

[ApiController]
[Route("api/[controller]")]
public abstract class BaseApiController : ControllerBase
{
    protected ActionResult<ApiResponse<T>> Success<T>(T data, string? message = null)
        => Ok(ApiResponse<T>.Ok(data, message));

    protected ActionResult<ApiResponse<T>> Created<T>(string actionName, object? routeValues, T data, string? message = null)
        => CreatedAtAction(actionName, routeValues, ApiResponse<T>.Ok(data, message));
}
