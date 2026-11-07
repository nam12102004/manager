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
        var query = _uow.Suppliers.Query()
            .Include(s => s.WarehouseDebts)
            .AsQueryable();

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
        string? priorityMetrics = null,
        CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = pageSize > 0 ? pageSize : 15;

        var query = _uow.Suppliers.Query()
            .Include(s => s.WarehouseDebts)
            .AsQueryable();

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
        var totalPayables = await query.Where(s => s.Debt < 0).SumAsync(s => (decimal?)Math.Abs(s.Debt), ct) ?? 0;
        var totalPrepaid = await query.Where(s => s.Debt > 0).SumAsync(s => (decimal?)s.Debt, ct) ?? 0;

        // Sorting (suppliers having data for the ticked metrics come first)
        var priorityIds = BuildPrioritySupplierIds(query, priorityMetrics, fromDate, toDate);
        IOrderedQueryable<Supplier> OrderFirst<TKey>(System.Linq.Expressions.Expression<Func<Supplier, TKey>> key, bool desc)
        {
            if (priorityIds == null)
            {
                return desc ? query.OrderByDescending(key) : query.OrderBy(key);
            }
            var prioritized = query.OrderByDescending(s => priorityIds.Contains(s.Id));
            return desc ? prioritized.ThenByDescending(key) : prioritized.ThenBy(key);
        }

        query = sortBy switch
        {
            "debt_desc" => OrderFirst(s => s.Debt, false).ThenByDescending(s => s.Id),
            "debt_asc" => OrderFirst(s => s.Debt, true).ThenByDescending(s => s.Id),
            _ => OrderFirst(s => s.Id, true)
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

        var supplierImports = await supplierImportsQuery
            .Select(v => new { v.SupplierId, v.TotalAmount, v.Warehouse })
            .ToListAsync(ct);

        var supplierPaymentsQuery = _uow.Payments.Query()
            .Where(p => p.SupplierId.HasValue && supplierIds.Contains(p.SupplierId.Value) && p.Status != "cancelled");
        if (startDate.HasValue)
        {
            supplierPaymentsQuery = supplierPaymentsQuery.Where(p => p.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            supplierPaymentsQuery = supplierPaymentsQuery.Where(p => p.Date <= endDate.Value);
        }

        var supplierPayments = await supplierPaymentsQuery
            .Select(p => new { SupplierId = p.SupplierId!.Value, p.Amount })
            .ToListAsync(ct);

        var supplierReceiptsQuery = _uow.Receipts.Query()
            .Where(r => r.SupplierId.HasValue && supplierIds.Contains(r.SupplierId.Value));
        if (startDate.HasValue)
        {
            supplierReceiptsQuery = supplierReceiptsQuery.Where(r => r.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            supplierReceiptsQuery = supplierReceiptsQuery.Where(r => r.Date <= endDate.Value);
        }

        var supplierReceipts = await supplierReceiptsQuery
            .Select(r => new { SupplierId = r.SupplierId!.Value, r.Amount })
            .ToListAsync(ct);

        var dtos = items.Select(s =>
        {
            var dto = MapToDto(s);
            var myImports = supplierImports.Where(im => im.SupplierId == s.Id).ToList();
            dto.TotalImportAmount = myImports.Sum(im => im.TotalAmount);
            dto.TotalPaymentAmount = supplierPayments.Where(p => p.SupplierId == s.Id).Sum(p => p.Amount);
            dto.TotalReceiptAmount = supplierReceipts.Where(r => r.SupplierId == s.Id).Sum(r => r.Amount);
            dto.TotalExportAmount = 0;

            foreach (var imp in myImports)
            {
                var wh = imp.Warehouse;
                dto.WarehouseImports[wh] = dto.WarehouseImports.GetValueOrDefault(wh) + imp.TotalAmount;
            }

            return dto;
        }).ToList();

        return new SupplierPagedResult
        {
            Items = dtos,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalPayables = totalPayables,
            TotalPrepaid = totalPrepaid
        };
    }

    /// <summary>
    /// Builds a DB-side query of supplier ids that have data for any of the ticked metrics
    /// (import / receipt / payment within the time range, or non-zero debt). Returns null when nothing is ticked.
    /// </summary>
    private IQueryable<int>? BuildPrioritySupplierIds(IQueryable<Supplier> filtered, string? priorityMetrics, string? fromDate, string? toDate)
    {
        var metrics = PriorityMetrics.Parse(priorityMetrics);
        if (metrics.IsEmpty) return null;

        var (start, end) = PriorityMetrics.ParseDateRange(fromDate, toDate);
        IQueryable<int>? ids = null;
        void Add(IQueryable<int> part) => ids = ids == null ? part : ids.Union(part);

        var importWhs = metrics.Get("import");
        if (importWhs.Count > 0)
        {
            var imports = _uow.ImportVouchers.Query().Where(v => v.Status != "cancelled");
            if (start.HasValue) imports = imports.Where(v => v.Date >= start.Value);
            if (end.HasValue) imports = imports.Where(v => v.Date <= end.Value);
            if (!importWhs.Contains(PriorityMetrics.AllWarehouses))
            {
                var whs = importWhs.ToList();
                imports = imports.Where(v => whs.Contains(v.Warehouse.ToLower()));
            }
            Add(imports.Select(v => v.SupplierId));
        }

        if (metrics.Has("receipt"))
        {
            var receipts = _uow.Receipts.Query().Where(r => r.SupplierId.HasValue);
            if (start.HasValue) receipts = receipts.Where(r => r.Date >= start.Value);
            if (end.HasValue) receipts = receipts.Where(r => r.Date <= end.Value);
            Add(receipts.Select(r => r.SupplierId!.Value));
        }

        if (metrics.Has("payment"))
        {
            var payments = _uow.Payments.Query().Where(p => p.SupplierId.HasValue && p.Status != "cancelled");
            if (start.HasValue) payments = payments.Where(p => p.Date >= start.Value);
            if (end.HasValue) payments = payments.Where(p => p.Date <= end.Value);
            Add(payments.Select(p => p.SupplierId!.Value));
        }

        var debtWhs = metrics.Get("debt");
        if (debtWhs.Count > 0)
        {
            if (debtWhs.Contains(PriorityMetrics.AllWarehouses))
            {
                Add(filtered.Where(s => s.Debt != 0).Select(s => s.Id));
            }
            var whs = debtWhs.Where(w => w != PriorityMetrics.AllWarehouses).ToList();
            if (whs.Count > 0)
            {
                Add(filtered.Where(s => s.WarehouseDebts.Any(d => d.Debt != 0 && whs.Contains(d.Warehouse.ToLower()))).Select(s => s.Id));
            }
        }

        return ids;
    }

    public async Task<List<string>> GetRegionsAsync(CancellationToken ct = default)
    {
        var regions = await _uow.Suppliers.Query()
            .Where(s => s.Region != null && s.Region != "")
            .Select(s => s.Region!)
            .Distinct()
            .OrderBy(r => r)
            .ToListAsync(ct);

        return regions;
    }

    public async Task<SupplierDto> GetByIdAsync(int id, CancellationToken ct = default)
    {
        var supplier = await _uow.Suppliers.Query()
            .Include(s => s.WarehouseDebts)
            .FirstOrDefaultAsync(s => s.Id == id, ct)
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
            Debt = 0,
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
            var wh = DebtHelper.NormalizeWarehouse(dto.InitialDebtWarehouse);
            await DebtHelper.SetSupplierDebtAsync(_uow, supplier.Id, wh, dto.InitialDebt, ct);

            var history = new SupplierDebtHistory
            {
                SupplierId = supplier.Id,
                Warehouse = wh,
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

        return await GetByIdAsync(supplier.Id, ct);
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

        return await GetByIdAsync(supplier.Id, ct);
    }

    public async Task<List<SupplierDebtHistoryDto>> GetDebtHistoryAsync(int supplierId, string? month = null, string? fromDate = null, string? toDate = null, string? warehouse = null, CancellationToken ct = default)
    {
        var supplierExists = await _uow.Suppliers.Query().AnyAsync(s => s.Id == supplierId, ct);
        if (!supplierExists)
        {
            throw new NotFoundException($"Không tìm thấy nhà cung cấp với ID {supplierId}");
        }

        var query = _uow.SupplierDebtHistories.Query().Where(h => h.SupplierId == supplierId);

        if (!string.IsNullOrWhiteSpace(warehouse) && warehouse != "all" && warehouse != "overview")
        {
            query = query.Where(h => h.Warehouse == warehouse.Trim());
        }

        DateTime? startDate = null;
        DateTime? endDate = null;

        if (!string.IsNullOrWhiteSpace(fromDate) && DateTime.TryParse(fromDate.Trim(), out var pFrom))
        {
            startDate = new DateTime(pFrom.Year, pFrom.Month, pFrom.Day, 0, 0, 0, DateTimeKind.Utc);
        }
        if (!string.IsNullOrWhiteSpace(toDate) && DateTime.TryParse(toDate.Trim(), out var pTo))
        {
            endDate = new DateTime(pTo.Year, pTo.Month, pTo.Day, 0, 0, 0, DateTimeKind.Utc).AddDays(1);
        }

        if (string.IsNullOrWhiteSpace(fromDate) && string.IsNullOrWhiteSpace(toDate) && !string.IsNullOrWhiteSpace(month))
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

        if (startDate.HasValue)
        {
            query = query.Where(h => h.CreatedAt >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            query = query.Where(h => h.CreatedAt < endDate.Value);
        }

        var list = await query
            .OrderByDescending(h => h.CreatedAt)
            .ThenByDescending(h => h.Id)
            .ToListAsync(ct);

        return list.Select(h => new SupplierDebtHistoryDto
        {
            Id = h.Id,
            SupplierId = h.SupplierId,
            Warehouse = h.Warehouse,
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

        var wh = DebtHelper.NormalizeWarehouse(dto.Warehouse);

        decimal delta;
        decimal beforeTotalDebt, afterTotalDebt;

        if (dto.NewDebt.HasValue)
        {
            var res = await DebtHelper.SetSupplierDebtAsync(_uow, supplierId, wh, dto.NewDebt.Value, ct);
            delta = res.Delta;
            beforeTotalDebt = res.BeforeTotalDebt;
            afterTotalDebt = res.AfterTotalDebt;
        }
        else
        {
            delta = dto.Delta.GetValueOrDefault();
            var res = await DebtHelper.ApplySupplierDebtAsync(_uow, supplierId, wh, delta, ct);
            beforeTotalDebt = res.BeforeTotalDebt;
            afterTotalDebt = res.AfterTotalDebt;
        }

        var history = new SupplierDebtHistory
        {
            SupplierId = supplier.Id,
            Warehouse = wh,
            SourceType = DomainConstants.SourceTypes.ManualAdjustment,
            Reason = dto.Reason ?? $"Điều chỉnh công nợ nhà cung cấp ({wh})",
            Note = dto.Note,
            BeforeDebt = beforeTotalDebt,
            Delta = delta,
            AfterDebt = afterTotalDebt,
            CreatedAt = DateTime.UtcNow
        };

        await _uow.SupplierDebtHistories.AddAsync(history, ct);
        await _uow.SaveChangesAsync(ct);

        return true;
    }

    public async Task<EntityLedgerResponseDto> GetLedgerAsync(int supplierId, string? warehouse = null, string? month = null, string? fromDate = null, string? toDate = null, CancellationToken ct = default)
    {
        var supplier = await _uow.Suppliers.GetByIdAsync(supplierId, ct)
            ?? throw new NotFoundException($"Không tìm thấy nhà cung cấp với ID {supplierId}");

        var wh = (warehouse ?? "").Trim().ToLower();
        var isAllWh = string.IsNullOrEmpty(wh) || wh == "all" || wh == "overview";

        DateTime? startDate = null;
        DateTime? endDate = null;

        if (!string.IsNullOrWhiteSpace(fromDate) && DateTime.TryParse(fromDate.Trim(), out var pFrom))
        {
            startDate = new DateTime(pFrom.Year, pFrom.Month, pFrom.Day, 0, 0, 0, DateTimeKind.Utc);
        }
        if (!string.IsNullOrWhiteSpace(toDate) && DateTime.TryParse(toDate.Trim(), out var pTo))
        {
            endDate = new DateTime(pTo.Year, pTo.Month, pTo.Day, 0, 0, 0, DateTimeKind.Utc).AddDays(1);
        }

        if (string.IsNullOrWhiteSpace(fromDate) && string.IsNullOrWhiteSpace(toDate) && !string.IsNullOrWhiteSpace(month))
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
            importQuery = importQuery.Where(v => v.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            importQuery = importQuery.Where(v => v.Date < endDate.Value);
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
                PaymentAmount = im.PaidAmount
            });
        }

        // 2. Payments (Chi tiền trả nợ NCC)
        var paymentQuery = _uow.Payments.Query()
            .Where(p => p.SupplierId == supplierId && p.Status != "cancelled");
        if (!isAllWh)
        {
            paymentQuery = paymentQuery.Where(p => p.Warehouse == wh);
        }
        if (startDate.HasValue)
        {
            paymentQuery = paymentQuery.Where(p => p.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            paymentQuery = paymentQuery.Where(p => p.Date < endDate.Value);
        }
        var payments = await paymentQuery.ToListAsync(ct);
        foreach (var pm in payments)
        {
            if (pm.RelatedVoucherType == "import_voucher" && imports.Any(i => i.VoucherNumber == pm.RelatedVoucherId))
            {
                continue;
            }

            ledgerItems.Add(new EntityLedgerItemDto
            {
                Id = pm.Id,
                Date = pm.Date,
                VoucherNumber = pm.PaymentNumber,
                VoucherType = "payment",
                VoucherTypeLabel = "Phiếu chi",
                Warehouse = pm.Warehouse,
                Description = string.IsNullOrWhiteSpace(pm.Notes) ? $"Chi tiền thanh toán công nợ theo phiếu {pm.PaymentNumber}" : pm.Notes,
                ImportAmount = 0,
                ExportAmount = 0,
                ReceiptAmount = 0,
                PaymentAmount = pm.Amount
            });
        }

        // 3. Receipts (Thu tiền NCC bồi hoàn/trả lại)
        var receiptQuery = _uow.Receipts.Query().Where(r => r.SupplierId == supplierId);
        if (!isAllWh)
        {
            receiptQuery = receiptQuery.Where(r => r.Warehouse == wh);
        }
        if (startDate.HasValue)
        {
            receiptQuery = receiptQuery.Where(r => r.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            receiptQuery = receiptQuery.Where(r => r.Date < endDate.Value);
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
                Warehouse = rc.Warehouse,
                Description = string.IsNullOrWhiteSpace(rc.Notes) ? $"Thu tiền NCC hoàn trả ({rc.Method})" : rc.Notes,
                ImportAmount = 0,
                ExportAmount = 0,
                ReceiptAmount = rc.Amount,
                PaymentAmount = 0
            });
        }

        // 4. Manual Debt Adjustments (Điều chỉnh nợ thủ công)
        var historyQuery = _uow.SupplierDebtHistories.Query()
            .Where(h => h.SupplierId == supplierId && h.SourceType == DomainConstants.SourceTypes.ManualAdjustment);
        if (!isAllWh)
        {
            historyQuery = historyQuery.Where(h => h.Warehouse == wh);
        }
        if (startDate.HasValue)
        {
            historyQuery = historyQuery.Where(h => h.CreatedAt >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            historyQuery = historyQuery.Where(h => h.CreatedAt < endDate.Value);
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
                VoucherTypeLabel = "Điều chỉnh",
                Warehouse = h.Warehouse,
                Description = string.IsNullOrWhiteSpace(h.Note) ? (h.Reason ?? "Điều chỉnh công nợ") : $"{h.Reason} - {h.Note}",
                ImportAmount = h.Delta < 0 ? -h.Delta : 0,
                ExportAmount = 0,
                ReceiptAmount = 0,
                PaymentAmount = h.Delta > 0 ? h.Delta : 0
            });
        }

        // Tính biến động phát sinh sau kỳ (nếu có endDate)
        decimal netChangeAfterEnd = 0;
        if (endDate.HasValue)
        {
            var impAfterQuery = _uow.ImportVouchers.Query()
                .Where(v => v.SupplierId == supplierId && v.Status != "cancelled" && v.Date >= endDate.Value);
            var rcAfterQuery = _uow.Receipts.Query()
                .Where(r => r.SupplierId == supplierId && r.Date >= endDate.Value);
            var pmAfterQuery = _uow.Payments.Query()
                .Where(p => p.SupplierId == supplierId && p.Status != "cancelled" && p.Date >= endDate.Value);
            var adjAfterQuery = _uow.SupplierDebtHistories.Query()
                .Where(h => h.SupplierId == supplierId && h.SourceType == DomainConstants.SourceTypes.ManualAdjustment && h.CreatedAt >= endDate.Value);

            if (!isAllWh)
            {
                impAfterQuery = impAfterQuery.Where(v => v.Warehouse == wh);
                rcAfterQuery = rcAfterQuery.Where(r => r.Warehouse == wh);
                pmAfterQuery = pmAfterQuery.Where(p => p.Warehouse == wh);
                adjAfterQuery = adjAfterQuery.Where(h => h.Warehouse == wh);
            }

            var impAfter = await impAfterQuery.SumAsync(v => (decimal?)v.TotalAmount, ct) ?? 0;
            var rcAfter = await rcAfterQuery.SumAsync(r => (decimal?)r.Amount, ct) ?? 0;
            var pmAfter = await pmAfterQuery.SumAsync(p => (decimal?)p.Amount, ct) ?? 0;
            var adjAfter = await adjAfterQuery.SumAsync(h => (decimal?)h.Delta, ct) ?? 0;
            // Biến động nợ NCC sau kỳ: Nhập (-impAfter), Chi trả (+pmAfter), Thu hoàn (-rcAfter), Điều chỉnh (+adjAfter)
            netChangeAfterEnd = -impAfter + pmAfter - rcAfter + adjAfter;
        }

        decimal currentBalance;
        if (!isAllWh)
        {
            var whDebtRecord = await _uow.SupplierWarehouseDebts.Query()
                .FirstOrDefaultAsync(w => w.SupplierId == supplierId && w.Warehouse == wh, ct);
            currentBalance = whDebtRecord?.Debt ?? 0;
        }
        else
        {
            currentBalance = supplier.Debt;
        }

        var closingBalance = currentBalance - netChangeAfterEnd;
        // Biến động nợ trong kỳ: Nhập (-ImportAmount), Chi trả (+PaymentAmount), Thu hoàn (-ReceiptAmount), Xuất trả (+ExportAmount)
        var periodNetChange = ledgerItems.Sum(i => (i.PaymentAmount + i.ExportAmount) - (i.ImportAmount + i.ReceiptAmount));
        var openingBalance = closingBalance - periodNetChange;

        var sorted = ledgerItems.OrderBy(i => i.Date).ThenBy(i => i.Id).ToList();

        // Nếu có số dư đầu kỳ, thêm bản ghi đầu kỳ vào Sổ chi tiết
        if (openingBalance != 0)
        {
            var earliestDate = sorted.Count > 0 ? sorted[0].Date.AddSeconds(-1) : (startDate ?? DateTime.UtcNow);
            sorted.Insert(0, new EntityLedgerItemDto
            {
                Id = 0,
                Date = earliestDate,
                VoucherNumber = "DUDAY",
                VoucherType = "init",
                VoucherTypeLabel = "Số dư đầu",
                Warehouse = isAllWh ? null : wh,
                Description = startDate.HasValue ? "Số dư nợ đầu kỳ" : "Số dư công nợ ban đầu",
                ImportAmount = openingBalance < 0 ? -openingBalance : 0,
                ExportAmount = 0,
                ReceiptAmount = openingBalance > 0 ? openingBalance : 0,
                PaymentAmount = 0,
                Balance = openingBalance
            });
        }

        decimal runningBalance = openingBalance;
        int startIndex = openingBalance != 0 ? 1 : 0;
        for (int i = startIndex; i < sorted.Count; i++)
        {
            var item = sorted[i];
            runningBalance += (item.PaymentAmount + item.ExportAmount) - (item.ImportAmount + item.ReceiptAmount);
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
            CurrentBalance = currentBalance,
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
        WarehouseDebts = s.WarehouseDebts != null && s.WarehouseDebts.Count > 0
            ? s.WarehouseDebts.ToDictionary(w => w.Warehouse, w => w.Debt, StringComparer.OrdinalIgnoreCase)
            : new(StringComparer.OrdinalIgnoreCase),
        CreditLimit = s.CreditLimit,
        BankAccount = s.BankAccount,
        TaxNumber = s.TaxNumber,
        Notes = s.Notes,
        CreatedAt = s.CreatedAt,
        UpdatedAt = s.UpdatedAt
    };
}
