using DebtManager.Application.Common;
using DebtManager.Application.DTOs.Audit;
using DebtManager.Application.Interfaces;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Application.Services;

public class AuditService : IAuditService
{
    private readonly IUnitOfWork _uow;

    public AuditService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<AuditLogDto> LogActivityAsync(
        string action,
        string entityName,
        string entityId,
        string entityDisplayName,
        string? details,
        string username = "admin",
        string? ipAddress = null,
        CancellationToken ct = default)
    {
        var log = new AuditLog
        {
            Action = action,
            EntityName = entityName,
            EntityId = entityId,
            EntityDisplayName = entityDisplayName,
            Details = details,
            Username = string.IsNullOrWhiteSpace(username) ? "admin" : username.Trim(),
            IpAddress = ipAddress,
            CreatedAt = DateTime.UtcNow
        };

        await _uow.AuditLogs.AddAsync(log, ct);
        await _uow.SaveChangesAsync(ct);

        return new AuditLogDto
        {
            Id = log.Id,
            Action = log.Action,
            EntityName = log.EntityName,
            EntityId = log.EntityId,
            EntityDisplayName = log.EntityDisplayName,
            Details = log.Details,
            Username = log.Username,
            IpAddress = log.IpAddress,
            CreatedAt = log.CreatedAt
        };
    }

    public async Task<List<AuditLogDto>> GetAuditLogsAsync(
        string? entityName = null,
        string? action = null,
        string? username = null,
        string? q = null,
        DateTime? fromDate = null,
        DateTime? toDate = null,
        int limit = 100,
        CancellationToken ct = default)
    {
        var query = _uow.AuditLogs.Query();

        if (!string.IsNullOrWhiteSpace(entityName))
        {
            query = query.Where(l => l.EntityName.ToLower() == entityName.Trim().ToLower());
        }

        if (!string.IsNullOrWhiteSpace(action))
        {
            query = query.Where(l => l.Action.ToLower() == action.Trim().ToLower());
        }

        if (!string.IsNullOrWhiteSpace(username))
        {
            query = query.Where(l => l.Username.ToLower() == username.Trim().ToLower());
        }

        if (fromDate.HasValue)
        {
            query = query.Where(l => l.CreatedAt >= fromDate.Value);
        }

        if (toDate.HasValue)
        {
            query = query.Where(l => l.CreatedAt <= toDate.Value);
        }

        if (!string.IsNullOrWhiteSpace(q))
        {
            var search = q.Trim().ToLower();
            query = query.Where(l =>
                l.EntityDisplayName.ToLower().Contains(search) ||
                l.EntityId.ToLower().Contains(search) ||
                (l.Details != null && l.Details.ToLower().Contains(search)) ||
                l.Username.ToLower().Contains(search));
        }

        return await query
            .OrderByDescending(l => l.CreatedAt)
            .Take(limit > 0 ? limit : 100)
            .Select(l => new AuditLogDto
            {
                Id = l.Id,
                Action = l.Action,
                EntityName = l.EntityName,
                EntityId = l.EntityId,
                EntityDisplayName = l.EntityDisplayName,
                Details = l.Details,
                Username = l.Username,
                IpAddress = l.IpAddress,
                CreatedAt = l.CreatedAt
            })
            .ToListAsync(ct);
    }

    public async Task<LoginHistoryDto> LogLoginAsync(
        string username,
        bool isSuccess,
        string? ipAddress = null,
        string? userAgent = null,
        string? device = null,
        string? note = null,
        CancellationToken ct = default)
    {
        var history = new LoginHistory
        {
            Username = string.IsNullOrWhiteSpace(username) ? "unknown" : username.Trim(),
            IsSuccess = isSuccess,
            IpAddress = ipAddress,
            UserAgent = userAgent,
            Device = device,
            Note = note ?? (isSuccess ? "Đăng nhập thành công" : "Đăng nhập thất bại"),
            LoginTime = DateTime.UtcNow
        };

        await _uow.LoginHistories.AddAsync(history, ct);
        await _uow.SaveChangesAsync(ct);

        return new LoginHistoryDto
        {
            Id = history.Id,
            Username = history.Username,
            IsSuccess = history.IsSuccess,
            IpAddress = history.IpAddress,
            UserAgent = history.UserAgent,
            Device = history.Device,
            Note = history.Note,
            LoginTime = history.LoginTime
        };
    }

    public async Task<List<LoginHistoryDto>> GetLoginHistoriesAsync(
        string? username = null,
        bool? isSuccess = null,
        int limit = 100,
        CancellationToken ct = default)
    {
        var query = _uow.LoginHistories.Query();

        if (!string.IsNullOrWhiteSpace(username))
        {
            query = query.Where(h => h.Username.ToLower() == username.Trim().ToLower());
        }

        if (isSuccess.HasValue)
        {
            query = query.Where(h => h.IsSuccess == isSuccess.Value);
        }

        return await query
            .OrderByDescending(h => h.LoginTime)
            .Take(limit > 0 ? limit : 100)
            .Select(h => new LoginHistoryDto
            {
                Id = h.Id,
                Username = h.Username,
                IsSuccess = h.IsSuccess,
                IpAddress = h.IpAddress,
                UserAgent = h.UserAgent,
                Device = h.Device,
                Note = h.Note,
                LoginTime = h.LoginTime
            })
            .ToListAsync(ct);
    }

    public async Task<PagedResult<AuditLogDto>> GetPagedAuditLogsAsync(
        string? entityName = null,
        string? action = null,
        string? username = null,
        string? q = null,
        DateTime? fromDate = null,
        DateTime? toDate = null,
        int page = 1,
        int pageSize = 15,
        CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = pageSize > 0 ? pageSize : 15;

        var query = _uow.AuditLogs.Query();

        if (!string.IsNullOrWhiteSpace(entityName))
        {
            query = query.Where(l => l.EntityName.ToLower() == entityName.Trim().ToLower());
        }

        if (!string.IsNullOrWhiteSpace(action))
        {
            query = query.Where(l => l.Action.ToLower() == action.Trim().ToLower());
        }

        if (!string.IsNullOrWhiteSpace(username))
        {
            query = query.Where(l => l.Username.ToLower() == username.Trim().ToLower());
        }

        if (fromDate.HasValue)
        {
            query = query.Where(l => l.CreatedAt >= fromDate.Value);
        }

        if (toDate.HasValue)
        {
            query = query.Where(l => l.CreatedAt <= toDate.Value);
        }

        if (!string.IsNullOrWhiteSpace(q))
        {
            var search = q.Trim().ToLower();
            query = query.Where(l =>
                l.EntityDisplayName.ToLower().Contains(search) ||
                l.EntityId.ToLower().Contains(search) ||
                (l.Details != null && l.Details.ToLower().Contains(search)) ||
                l.Username.ToLower().Contains(search));
        }

        var totalCount = await query.CountAsync(ct);

        var items = await query
            .OrderByDescending(l => l.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(l => new AuditLogDto
            {
                Id = l.Id,
                Action = l.Action,
                EntityName = l.EntityName,
                EntityId = l.EntityId,
                EntityDisplayName = l.EntityDisplayName,
                Details = l.Details,
                Username = l.Username,
                IpAddress = l.IpAddress,
                CreatedAt = l.CreatedAt
            })
            .ToListAsync(ct);

        return new PagedResult<AuditLogDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<PagedResult<LoginHistoryDto>> GetPagedLoginHistoriesAsync(
        string? username = null,
        bool? isSuccess = null,
        string? q = null,
        int page = 1,
        int pageSize = 15,
        CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = pageSize > 0 ? pageSize : 15;

        var query = _uow.LoginHistories.Query();

        if (!string.IsNullOrWhiteSpace(username))
        {
            query = query.Where(h => h.Username.ToLower() == username.Trim().ToLower());
        }

        if (isSuccess.HasValue)
        {
            query = query.Where(h => h.IsSuccess == isSuccess.Value);
        }

        if (!string.IsNullOrWhiteSpace(q))
        {
            var s = q.Trim().ToLower();
            query = query.Where(h =>
                h.Username.ToLower().Contains(s) ||
                (h.Device != null && h.Device.ToLower().Contains(s)) ||
                (h.Note != null && h.Note.ToLower().Contains(s)));
        }

        var totalCount = await query.CountAsync(ct);

        var items = await query
            .OrderByDescending(h => h.LoginTime)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(h => new LoginHistoryDto
            {
                Id = h.Id,
                Username = h.Username,
                IsSuccess = h.IsSuccess,
                IpAddress = h.IpAddress,
                UserAgent = h.UserAgent,
                Device = h.Device,
                Note = h.Note,
                LoginTime = h.LoginTime
            })
            .ToListAsync(ct);

        return new PagedResult<LoginHistoryDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }
}
