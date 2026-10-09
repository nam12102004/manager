using DebtManager.Application.Common;
using DebtManager.Application.Common.Exceptions;
using DebtManager.Application.DTOs.Suppliers;
using DebtManager.Application.Interfaces;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Domain.Common;
using DebtManager.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Application.Services;

public class SupplierService : ISupplierService
{
    private readonly IUnitOfWork _uow;

    public SupplierService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<List<SupplierDto>> GetSuppliersAsync(string? search = null, CancellationToken ct = default)
    {
        var query = _uow.Suppliers.Query().AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(sup => sup.Name.ToLower().Contains(s) ||
                                       sup.Code.ToLower().Contains(s) ||
                                       (sup.ContactName != null && sup.ContactName.ToLower().Contains(s)) ||
                                       (sup.PhonesJson != null && sup.PhonesJson.ToLower().Contains(s)) ||
                                       (sup.AddressesJson != null && sup.AddressesJson.ToLower().Contains(s)) ||
                                       (sup.Email != null && sup.Email.ToLower().Contains(s)) ||
                                       (sup.BankAccount != null && sup.BankAccount.ToLower().Contains(s)) ||
                                       (sup.Region != null && sup.Region.ToLower().Contains(s)));
        }

        var list = await query.OrderByDescending(sup => sup.Id).ToListAsync(ct);
        return list.Select(MapToDto).ToList();
    }

    public async Task<SupplierPagedResult> GetPagedSuppliersAsync(
        string? search = null,
        string? region = null,
        string? sortBy = null,
        int page = 1,
        int pageSize = 15,
        CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = pageSize > 0 ? pageSize : 15;

        var query = _uow.Suppliers.Query().AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(sup => sup.Name.ToLower().Contains(s) ||
                                       sup.Code.ToLower().Contains(s) ||
                                       (sup.ContactName != null && sup.ContactName.ToLower().Contains(s)) ||
                                       (sup.PhonesJson != null && sup.PhonesJson.ToLower().Contains(s)) ||
                                       (sup.AddressesJson != null && sup.AddressesJson.ToLower().Contains(s)) ||
                                       (sup.Email != null && sup.Email.ToLower().Contains(s)) ||
                                       (sup.BankAccount != null && sup.BankAccount.ToLower().Contains(s)) ||
                                       (sup.Region != null && sup.Region.ToLower().Contains(s)));
        }

        if (!string.IsNullOrWhiteSpace(region))
        {
            var r = region.Trim();
            if (r.Equals("NONE", StringComparison.OrdinalIgnoreCase))
            {
                query = query.Where(sup => string.IsNullOrEmpty(sup.Region));
            }
            else if (!r.Equals("ALL", StringComparison.OrdinalIgnoreCase))
            {
                var rLower = r.ToLower();
                query = query.Where(sup => sup.Region != null && sup.Region.ToLower() == rLower);
            }
        }

        var totalCount = await query.CountAsync(ct);
        var totalReceivables = await query.Where(sup => sup.Debt > 0).SumAsync(sup => (decimal?)sup.Debt, ct) ?? 0;
        var totalPayables = await query.Where(sup => sup.Debt < 0).SumAsync(sup => (decimal?)Math.Abs(sup.Debt), ct) ?? 0;

        query = sortBy switch
        {
            "payable_desc" => query.OrderBy(sup => sup.Debt).ThenByDescending(sup => sup.Id),
            "payable_asc" => query.OrderByDescending(sup => sup.Debt).ThenByDescending(sup => sup.Id),
            _ => query.OrderByDescending(sup => sup.Id)
        };

        var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return new SupplierPagedResult
        {
            Items = items.Select(MapToDto).ToList(),
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalReceivables = totalReceivables,
            TotalPayables = totalPayables
        };
    }

    public async Task<List<string>> GetRegionsAsync(CancellationToken ct = default)
    {
        return await _uow.Suppliers.Query()
            .Where(sup => sup.Region != null && sup.Region != "")
            .Select(sup => sup.Region!)
            .Distinct()
            .OrderBy(r => r)
            .ToListAsync(ct);
    }

    public async Task<SupplierDto> GetByIdAsync(int id, CancellationToken ct = default)
    {
        var supplier = await _uow.Suppliers.GetByIdAsync(id, ct)
            ?? throw new NotFoundException($"Không tìm thấy nhà cung cấp với ID {id}");

        return MapToDto(supplier);
    }

    public async Task<SupplierDto> CreateSupplierAsync(CreateSupplierDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
        {
            throw new ValidationException("Tên nhà cung cấp không được để trống");
        }

        var code = string.IsNullOrWhiteSpace(dto.Code)
            ? $"NCC{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 1000000):D6}"
            : dto.Code.Trim();

        var supplier = new Supplier
        {
            Code = code,
            Name = dto.Name.Trim(),
            ContactName = dto.ContactName?.Trim(),
            PhonesJson = dto.PhonesJson?.Trim(),
            Email = dto.Email?.Trim(),
            AddressesJson = dto.AddressesJson?.Trim(),
            Region = dto.Region?.Trim(),
            CreditLimit = dto.CreditLimit,
            Debt = dto.InitialDebt,
            BankAccount = dto.BankAccount?.Trim(),
            TaxNumber = dto.TaxNumber?.Trim(),
            Notes = dto.Notes?.Trim(),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        await _uow.Suppliers.AddAsync(supplier, ct);
        await _uow.SaveChangesAsync(ct);

        if (dto.InitialDebt != 0)
        {
            var history = new SupplierDebtHistory
            {
                SupplierId = supplier.Id,
                SourceType = "init",
                Reason = "Khởi tạo công nợ ban đầu",
                BeforeDebt = 0,
                Delta = dto.InitialDebt,
                AfterDebt = dto.InitialDebt,
                CreatedAt = DateTime.UtcNow
            };
            await _uow.SupplierDebtHistories.AddAsync(history, ct);
            await _uow.SaveChangesAsync(ct);
        }

        return MapToDto(supplier);
    }

    public async Task<SupplierDto> UpdateSupplierAsync(int id, UpdateSupplierDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
        {
            throw new ValidationException("Tên nhà cung cấp không được để trống");
        }

        var supplier = await _uow.Suppliers.GetByIdAsync(id, ct)
            ?? throw new NotFoundException($"Không tìm thấy nhà cung cấp với ID {id}");

        supplier.Name = dto.Name.Trim();
        supplier.ContactName = dto.ContactName?.Trim();
        supplier.PhonesJson = dto.PhonesJson?.Trim();
        supplier.Email = dto.Email?.Trim();
        supplier.AddressesJson = dto.AddressesJson?.Trim();
        supplier.Region = dto.Region?.Trim();
        supplier.CreditLimit = dto.CreditLimit;
        supplier.BankAccount = dto.BankAccount?.Trim();
        supplier.TaxNumber = dto.TaxNumber?.Trim();
        supplier.Notes = dto.Notes?.Trim();
        supplier.UpdatedAt = DateTime.UtcNow;

        _uow.Suppliers.Update(supplier);
        await _uow.SaveChangesAsync(ct);

        return MapToDto(supplier);
    }

    public async Task<List<SupplierDebtHistoryDto>> GetDebtHistoryAsync(int supplierId, string? month = null, CancellationToken ct = default)
    {
        var supplierExists = await _uow.Suppliers.Query().AnyAsync(s => s.Id == supplierId, ct);
        if (!supplierExists)
        {
            throw new NotFoundException($"Không tìm thấy nhà cung cấp với ID {supplierId}");
        }

        var query = _uow.SupplierDebtHistories.Query().Where(h => h.SupplierId == supplierId);

        if (!string.IsNullOrWhiteSpace(month))
        {
            if (DateTime.TryParseExact(month.Trim(), "yyyy-MM-dd", null, System.Globalization.DateTimeStyles.None, out var parsedDate))
            {
                var start = new DateTime(parsedDate.Year, parsedDate.Month, parsedDate.Day, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddDays(1);
                var windowStart = start.AddDays(-1);
                var windowEnd = end.AddDays(1);
                query = query.Where(h => h.CreatedAt >= windowStart && h.CreatedAt <= windowEnd);
            }
            else if (DateTime.TryParseExact(month.Trim(), "yyyy-MM", null, System.Globalization.DateTimeStyles.None, out var parsedMonth))
            {
                var start = new DateTime(parsedMonth.Year, parsedMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddMonths(1);
                var windowStart = start.AddDays(-1);
                var windowEnd = end.AddDays(1);
                query = query.Where(h => h.CreatedAt >= windowStart && h.CreatedAt <= windowEnd);
            }
        }

        var list = await query
            .OrderByDescending(h => h.CreatedAt)
            .ThenByDescending(h => h.Id)
            .ToListAsync(ct);

        return list.Select(h => new SupplierDebtHistoryDto
        {
            Id = h.Id,
            SupplierId = h.SupplierId,
            SourceType = h.SourceType,
            ReferenceType = h.ReferenceType,
            ReferenceId = h.ReferenceId,
            Reason = h.Reason,
            Note = h.Note,
            BeforeDebt = h.BeforeDebt,
            Delta = h.Delta,
            AfterDebt = h.AfterDebt,
            CreatedAt = h.CreatedAt
        }).ToList();
    }

    public async Task<bool> AdjustDebtAsync(int supplierId, SupplierDebtAdjustDto dto, CancellationToken ct = default)
    {
        var supplier = await _uow.Suppliers.GetByIdAsync(supplierId, ct)
            ?? throw new NotFoundException($"Không tìm thấy nhà cung cấp với ID {supplierId}");

        var beforeDebt = supplier.Debt;
        decimal delta;
        if (dto.NewDebt.HasValue)
        {
            delta = dto.NewDebt.Value - beforeDebt;
        }
        else
        {
            delta = dto.Delta.GetValueOrDefault();
        }

        var afterDebt = beforeDebt + delta;
        supplier.Debt = afterDebt;
        supplier.UpdatedAt = DateTime.UtcNow;

        var history = new SupplierDebtHistory
        {
            SupplierId = supplier.Id,
            SourceType = DomainConstants.SourceTypes.ManualAdjustment,
            Reason = dto.Reason ?? "Điều chỉnh công nợ nhà cung cấp",
            Note = dto.Note,
            BeforeDebt = beforeDebt,
            Delta = delta,
            AfterDebt = afterDebt,
            CreatedAt = DateTime.UtcNow
        };

        _uow.Suppliers.Update(supplier);
        await _uow.SupplierDebtHistories.AddAsync(history, ct);
        await _uow.SaveChangesAsync(ct);

        return true;
    }

    private static SupplierDto MapToDto(Supplier s) => new()
    {
        Id = s.Id,
        Code = s.Code,
        Name = s.Name,
        ContactName = s.ContactName,
        PhonesJson = s.PhonesJson,
        Email = s.Email,
        AddressesJson = s.AddressesJson,
        Region = s.Region,
        Debt = s.Debt,
        CreditLimit = s.CreditLimit,
        BankAccount = s.BankAccount,
        TaxNumber = s.TaxNumber,
        Notes = s.Notes,
        CreatedAt = s.CreatedAt,
        UpdatedAt = s.UpdatedAt
    };
}
