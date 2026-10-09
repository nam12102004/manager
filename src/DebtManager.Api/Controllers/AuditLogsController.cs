using DebtManager.Api.Common;
using DebtManager.Application.Common;
using DebtManager.Application.DTOs.Audit;
using DebtManager.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

[Route("api/audit-logs")]
[Route("api/[controller]")]
public class AuditLogsController : BaseApiController
{
    private readonly IAuditService _auditService;

    public AuditLogsController(IAuditService auditService)
    {
        _auditService = auditService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAuditLogs(
        [FromQuery] string? entityName,
        [FromQuery] string? action,
        [FromQuery] string? username,
        [FromQuery] string? q,
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate,
        [FromQuery] int? page,
        [FromQuery] int pageSize = 15,
        [FromQuery] int limit = 100,
        CancellationToken ct = default)
    {
        if (page.HasValue)
        {
            var paged = await _auditService.GetPagedAuditLogsAsync(entityName, action, username, q, fromDate, toDate, page.Value, pageSize, ct);
            return Success(paged);
        }

        var logs = await _auditService.GetAuditLogsAsync(entityName, action, username, q, fromDate, toDate, limit, ct);
        return Success(logs);
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<AuditLogDto>>> CreateAuditLog(
        [FromBody] CreateAuditLogDto request,
        CancellationToken ct = default)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _auditService.LogActivityAsync(
            request.Action,
            request.EntityName,
            request.EntityId,
            request.EntityDisplayName,
            request.Details,
            request.Username,
            request.IpAddress ?? ip,
            ct);

        return Success(result, "Ghi nhận lịch sử thao tác thành công");
    }

    [HttpGet("login-history")]
    public async Task<IActionResult> GetLoginHistories(
        [FromQuery] string? username,
        [FromQuery] bool? isSuccess,
        [FromQuery] string? q,
        [FromQuery] int? page,
        [FromQuery] int pageSize = 15,
        [FromQuery] int limit = 100,
        CancellationToken ct = default)
    {
        if (page.HasValue)
        {
            var paged = await _auditService.GetPagedLoginHistoriesAsync(username, isSuccess, q, page.Value, pageSize, ct);
            return Success(paged);
        }

        var history = await _auditService.GetLoginHistoriesAsync(username, isSuccess, limit, ct);
        return Success(history);
    }

    [HttpPost("login-history")]
    public async Task<ActionResult<ApiResponse<LoginHistoryDto>>> CreateLoginHistory(
        [FromBody] CreateLoginHistoryDto request,
        CancellationToken ct = default)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var ua = Request.Headers.UserAgent.ToString();
        var result = await _auditService.LogLoginAsync(
            request.Username,
            request.IsSuccess,
            request.IpAddress ?? ip,
            request.UserAgent ?? ua,
            request.Device,
            request.Note,
            ct);

        return Success(result, "Ghi nhận lịch sử đăng nhập thành công");
    }
}
