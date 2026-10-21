using DebtManager.Application.Common;
using DebtManager.Application.Common.Exceptions;
using DebtManager.Application.DTOs.Common;
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
        string? fromDate = null,
        string? toDate = null,
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
        var supplierIds = items.Select(s => s.Id).ToList();

        DateTime? startDate = null;
        DateTime? endDate = null;
        if (!string.IsNullOrWhiteSpace(fromDate) && DateTime.TryParse(fromDate.Trim(), out var pFrom))
        {
            startDate = new DateTime(pFrom.Year, pFrom.Month, pFrom.Day, 0, 0, 0, DateTimeKind.Utc);
        }
        if (!string.IsNullOrWhiteSpace(toDate) && DateTime.TryParse(toDate.Trim(), out var pTo))
        {
            endDate = new DateTime(pTo.Year, pTo.Month, pTo.Day, 23, 59, 59, 999, DateTimeKind.Utc);
        }

        var supplierImportsQuery = _uow.ImportVouchers.Query()
            .Where(v => supplierIds.Contains(v.SupplierId) && v.Status != "cancelled");
        if (startDate.HasValue)
        {
            supplierImportsQuery = supplierImportsQuery.Where(v => v.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            supplierImportsQuery = supplierImportsQuery.Where(v => v.Date <= endDate.Value);
        }

        var supplierImportsGroup = await supplierImportsQuery
            .GroupBy(v => new { v.SupplierId, Warehouse = v.Warehouse.ToLower() })
            .Select(g => new { g.Key.SupplierId, g.Key.Warehouse, Total = g.Sum(x => x.TotalAmount) })
            .ToListAsync(ct);

        var importsBySupplier = supplierImportsGroup
            .GroupBy(x => x.SupplierId)
            .ToDictionary(
                g => g.Key,
                g => g.ToDictionary(x => x.Warehouse, x => x.Total, StringComparer.OrdinalIgnoreCase)
            );

        var paymentsQuery = _uow.Payments.Query()
            .Where(p => p.SupplierId != null && supplierIds.Contains(p.SupplierId.Value) && p.Status != "cancelled");
        if (startDate.HasValue)
        {
            paymentsQuery = paymentsQuery.Where(p => p.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            paymentsQuery = paymentsQuery.Where(p => p.Date <= endDate.Value);
        }

        var paymentsMap = await paymentsQuery
            .GroupBy(p => p.SupplierId!.Value)
            .Select(g => new { SupplierId = g.Key, Total = g.Sum(x => x.Amount) })
            .ToDictionaryAsync(x => x.SupplierId, x => x.Total, ct);

        var receiptsQuery = _uow.Receipts.Query()
            .Where(r => r.SupplierId != null && supplierIds.Contains(r.SupplierId.Value));
        if (startDate.HasValue)
        {
            receiptsQuery = receiptsQuery.Where(r => r.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            receiptsQuery = receiptsQuery.Where(r => r.Date <= endDate.Value);
        }

        var receiptsMap = await receiptsQuery
            .GroupBy(r => r.SupplierId!.Value)
            .Select(g => new { SupplierId = g.Key, Total = g.Sum(x => x.Amount) })
            .ToDictionaryAsync(x => x.SupplierId, x => x.Total, ct);

        var dtos = items.Select(s =>
        {
            var dto = MapToDto(s);
            if (importsBySupplier.TryGetValue(s.Id, out var whDict))
            {
                dto.WarehouseImports = whDict;
                dto.TotalImportAmount = whDict.Values.Sum();
            }
            else
            {
                dto.WarehouseImports = new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase);
                dto.TotalImportAmount = 0;
            }
            dto.TotalPaymentAmount = paymentsMap.GetValueOrDefault(s.Id, 0);
            dto.TotalReceiptAmount = receiptsMap.GetValueOrDefault(s.Id, 0);
            return dto;
        }).ToList();

        return new SupplierPagedResult
        {
            Items = dtos,
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

    public async Task<EntityLedgerResponseDto> GetLedgerAsync(int supplierId, string? warehouse = null, string? month = null, CancellationToken ct = default)
    {
        var supplier = await _uow.Suppliers.GetByIdAsync(supplierId, ct)
            ?? throw new NotFoundException($"Không tìm thấy nhà cung cấp với ID {supplierId}");

        var wh = (warehouse ?? "").Trim().ToLower();
        var isAllWh = string.IsNullOrEmpty(wh) || wh == "all" || wh == "overview";

        DateTime? startDate = null;
        DateTime? endDate = null;
        if (!string.IsNullOrWhiteSpace(month))
        {
            if (DateTime.TryParseExact(month.Trim(), "yyyy-MM-dd", null, System.Globalization.DateTimeStyles.None, out var parsedDate))
            {
                startDate = new DateTime(parsedDate.Year, parsedDate.Month, parsedDate.Day, 0, 0, 0, DateTimeKind.Utc);
                endDate = startDate.Value.AddDays(1);
            }
            else if (DateTime.TryParseExact(month.Trim(), "yyyy-MM", null, System.Globalization.DateTimeStyles.None, out var parsedMonth))
            {
                startDate = new DateTime(parsedMonth.Year, parsedMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                endDate = startDate.Value.AddMonths(1);
            }
        }

        var ledgerItems = new List<EntityLedgerItemDto>();

        // 1. Import vouchers (Nhập hàng từ NCC)
        var importQuery = _uow.ImportVouchers.Query()
            .Where(v => v.SupplierId == supplierId && v.Status != "cancelled");
        if (!isAllWh)
        {
            importQuery = importQuery.Where(v => v.Warehouse.ToLower() == wh);
        }
        if (startDate.HasValue)
        {
            importQuery = importQuery.Where(v => v.Date >= startDate.Value.AddDays(-1) && v.Date <= endDate!.Value.AddDays(1));
        }
        var imports = await importQuery.ToListAsync(ct);
        foreach (var im in imports)
        {
            ledgerItems.Add(new EntityLedgerItemDto
            {
                Id = im.Id,
                Date = im.Date,
                VoucherNumber = im.VoucherNumber,
                VoucherType = "import",
                VoucherTypeLabel = "Phiếu nhập",
                Warehouse = im.Warehouse,
                Description = string.IsNullOrWhiteSpace(im.Notes) ? $"Nhập hàng hóa {im.VoucherNumber}" : im.Notes,
                ImportAmount = im.TotalAmount,
                ExportAmount = 0,
                ReceiptAmount = 0,
                PaymentAmount = 0
            });
        }

        // 2. Payments (Chi tiền trả nợ NCC)
        var paymentQuery = _uow.Payments.Query().Where(p => p.SupplierId == supplierId && p.Status != "cancelled");
        if (startDate.HasValue)
        {
            paymentQuery = paymentQuery.Where(p => p.Date >= startDate.Value.AddDays(-1) && p.Date <= endDate!.Value.AddDays(1));
        }
        var payments = await paymentQuery.ToListAsync(ct);
        foreach (var pm in payments)
        {
            ledgerItems.Add(new EntityLedgerItemDto
            {
                Id = pm.Id,
                Date = pm.Date,
                VoucherNumber = pm.PaymentNumber,
                VoucherType = "payment",
                VoucherTypeLabel = "Phiếu chi",
                Warehouse = isAllWh ? null : wh,
                Description = string.IsNullOrWhiteSpace(pm.Notes) ? $"Chi tiền trả NCC ({pm.Method})" : pm.Notes,
                ImportAmount = 0,
                ExportAmount = 0,
                ReceiptAmount = 0,
                PaymentAmount = pm.Amount
            });
        }

        // 3. Receipts (Thu tiền NCC bồi hoàn/trả lại)
        var receiptQuery = _uow.Receipts.Query().Where(r => r.SupplierId == supplierId);
        if (startDate.HasValue)
        {
            receiptQuery = receiptQuery.Where(r => r.Date >= startDate.Value.AddDays(-1) && r.Date <= endDate!.Value.AddDays(1));
        }
        var receipts = await receiptQuery.ToListAsync(ct);
        foreach (var rc in receipts)
        {
            ledgerItems.Add(new EntityLedgerItemDto
            {
                Id = rc.Id,
                Date = rc.Date,
                VoucherNumber = rc.ReceiptNumber,
                VoucherType = "receipt",
                VoucherTypeLabel = "Phiếu thu",
                Warehouse = isAllWh ? null : wh,
                Description = string.IsNullOrWhiteSpace(rc.Notes) ? $"Thu tiền NCC hoàn trả ({rc.Method})" : rc.Notes,
                ImportAmount = 0,
                ExportAmount = 0,
                ReceiptAmount = rc.Amount,
                PaymentAmount = 0
            });
        }

        // 4. Manual Debt Adjustments / Initial Debt
        var historyQuery = _uow.SupplierDebtHistories.Query()
            .Where(h => h.SupplierId == supplierId && (h.SourceType == DomainConstants.SourceTypes.ManualAdjustment || h.SourceType == "init"));
        if (startDate.HasValue)
        {
            historyQuery = historyQuery.Where(h => h.CreatedAt >= startDate.Value.AddDays(-1) && h.CreatedAt <= endDate!.Value.AddDays(1));
        }
        var histories = await historyQuery.ToListAsync(ct);
        foreach (var h in histories)
        {
            ledgerItems.Add(new EntityLedgerItemDto
            {
                Id = h.Id,
                Date = h.CreatedAt,
                VoucherNumber = h.ReferenceId ?? $"DC{h.Id:D5}",
                VoucherType = "adjust",
                VoucherTypeLabel = h.SourceType == "init" ? "Số dư đầu" : "Điều chỉnh",
                Warehouse = isAllWh ? null : wh,
                Description = string.IsNullOrWhiteSpace(h.Note) ? (h.Reason ?? "Điều chỉnh công nợ") : $"{h.Reason} - {h.Note}",
                ImportAmount = h.Delta > 0 ? h.Delta : 0,
                ExportAmount = 0,
                ReceiptAmount = 0,
                PaymentAmount = h.Delta < 0 ? -h.Delta : 0
            });
        }

        var sorted = ledgerItems.OrderBy(i => i.Date).ThenBy(i => i.Id).ToList();
        decimal runningBalance = 0;
        foreach (var item in sorted)
        {
            runningBalance += (item.ImportAmount + item.ReceiptAmount) - (item.PaymentAmount + item.ExportAmount);
            item.Balance = runningBalance;
        }

        var resultList = sorted.OrderByDescending(i => i.Date).ThenByDescending(i => i.Id).ToList();

        return new EntityLedgerResponseDto
        {
            EntityId = supplier.Id,
            EntityCode = supplier.Code,
            EntityName = supplier.Name,
            Warehouse = isAllWh ? "Tất cả kho" : wh,
            TotalImport = resultList.Sum(i => i.ImportAmount),
            TotalExport = resultList.Sum(i => i.ExportAmount),
            TotalReceipt = resultList.Sum(i => i.ReceiptAmount),
            TotalPayment = resultList.Sum(i => i.PaymentAmount),
            CurrentBalance = supplier.Debt,
            Items = resultList
        };
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
