using DebtManager.Application.Common;
using DebtManager.Application.Common.Exceptions;
using DebtManager.Application.DTOs.Common;
using DebtManager.Application.DTOs.Customers;
using DebtManager.Application.Interfaces;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Domain.Common;
using DebtManager.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Application.Services;

public class CustomerService : ICustomerService
{
    private readonly IUnitOfWork _uow;

    public CustomerService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<List<CustomerDto>> GetCustomersAsync(string? search = null, CancellationToken ct = default)
    {
        var query = _uow.Customers.Query()
            .Include(c => c.WarehouseDebts)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(c => c.Name.ToLower().Contains(s) ||
                                     c.Code.ToLower().Contains(s) ||
                                     (c.ContactName != null && c.ContactName.ToLower().Contains(s)) ||
                                     (c.PhonesJson != null && c.PhonesJson.ToLower().Contains(s)) ||
                                     (c.AddressesJson != null && c.AddressesJson.ToLower().Contains(s)) ||
                                     (c.Email != null && c.Email.ToLower().Contains(s)) ||
                                     (c.Region != null && c.Region.ToLower().Contains(s)));
        }

        var list = await query.OrderByDescending(c => c.Id).ToListAsync(ct);
        return list.Select(MapToDto).ToList();
    }

    public async Task<CustomerPagedResult> GetPagedCustomersAsync(
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

        var query = _uow.Customers.Query()
            .Include(c => c.WarehouseDebts)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(c => c.Name.ToLower().Contains(s) ||
                                     c.Code.ToLower().Contains(s) ||
                                     (c.ContactName != null && c.ContactName.ToLower().Contains(s)) ||
                                     (c.PhonesJson != null && c.PhonesJson.ToLower().Contains(s)) ||
                                     (c.AddressesJson != null && c.AddressesJson.ToLower().Contains(s)) ||
                                     (c.Email != null && c.Email.ToLower().Contains(s)) ||
                                     (c.Region != null && c.Region.ToLower().Contains(s)));
        }

        if (!string.IsNullOrWhiteSpace(region))
        {
            var r = region.Trim();
            if (r.Equals("NONE", StringComparison.OrdinalIgnoreCase))
            {
                query = query.Where(c => string.IsNullOrEmpty(c.Region));
            }
            else if (!r.Equals("ALL", StringComparison.OrdinalIgnoreCase))
            {
                var rLower = r.ToLower();
                query = query.Where(c => c.Region != null && c.Region.ToLower() == rLower);
            }
        }

        // Totals calculated on full filtered dataset before pagination
        var totalCount = await query.CountAsync(ct);
        var totalReceivables = await query.Where(c => c.Debt > 0).SumAsync(c => (decimal?)c.Debt, ct) ?? 0;
        var totalPayables = await query.Where(c => c.Debt < 0).SumAsync(c => (decimal?)Math.Abs(c.Debt), ct) ?? 0;

        // Sorting (customers having data for the ticked metrics come first)
        var priorityIds = BuildPriorityCustomerIds(query, priorityMetrics, fromDate, toDate);
        IOrderedQueryable<Customer> OrderFirst<TKey>(System.Linq.Expressions.Expression<Func<Customer, TKey>> key, bool desc)
        {
            if (priorityIds == null)
            {
                return desc ? query.OrderByDescending(key) : query.OrderBy(key);
            }
            var prioritized = query.OrderByDescending(c => priorityIds.Contains(c.Id));
            return desc ? prioritized.ThenByDescending(key) : prioritized.ThenBy(key);
        }

        query = sortBy switch
        {
            "debt_desc" => OrderFirst(c => c.Debt, true).ThenByDescending(c => c.Id),
            "debt_asc" => OrderFirst(c => c.Debt, false).ThenByDescending(c => c.Id),
            _ => OrderFirst(c => c.Id, true)
        };

        var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);
        var customerIds = items.Select(c => c.Id).ToList();

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

        var customerExportsQuery = _uow.ExportVouchers.Query()
            .Where(v => v.CustomerId.HasValue && customerIds.Contains(v.CustomerId.Value) && v.Status != "cancelled");
        if (startDate.HasValue)
        {
            customerExportsQuery = customerExportsQuery.Where(v => v.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            customerExportsQuery = customerExportsQuery.Where(v => v.Date <= endDate.Value);
        }

        var customerExports = await customerExportsQuery
            .Select(v => new { CustomerId = v.CustomerId!.Value, v.TotalSale, v.Warehouse })
            .ToListAsync(ct);

        var customerReceiptsQuery = _uow.Receipts.Query()
            .Where(r => r.CustomerId.HasValue && customerIds.Contains(r.CustomerId.Value));
        if (startDate.HasValue)
        {
            customerReceiptsQuery = customerReceiptsQuery.Where(r => r.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            customerReceiptsQuery = customerReceiptsQuery.Where(r => r.Date <= endDate.Value);
        }

        var customerReceipts = await customerReceiptsQuery
            .Select(r => new { CustomerId = r.CustomerId!.Value, r.Amount })
            .ToListAsync(ct);

        var customerPaymentsQuery = _uow.Payments.Query()
            .Where(p => p.CustomerId.HasValue && customerIds.Contains(p.CustomerId.Value) && p.Status != "cancelled");
        if (startDate.HasValue)
        {
            customerPaymentsQuery = customerPaymentsQuery.Where(p => p.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            customerPaymentsQuery = customerPaymentsQuery.Where(p => p.Date <= endDate.Value);
        }

        var customerPayments = await customerPaymentsQuery
            .Select(p => new { CustomerId = p.CustomerId!.Value, p.Amount })
            .ToListAsync(ct);

        var dtos = items.Select(c =>
        {
            var dto = MapToDto(c);
            var myExports = customerExports.Where(e => e.CustomerId == c.Id).ToList();
            dto.TotalExportAmount = myExports.Sum(e => e.TotalSale);
            dto.TotalReceiptAmount = customerReceipts.Where(r => r.CustomerId == c.Id).Sum(r => r.Amount);
            dto.TotalPaymentAmount = customerPayments.Where(p => p.CustomerId == c.Id).Sum(p => p.Amount);
            dto.TotalImportAmount = 0;

            foreach (var exp in myExports)
            {
                var wh = exp.Warehouse;
                dto.WarehouseExports[wh] = dto.WarehouseExports.GetValueOrDefault(wh) + exp.TotalSale;
            }

            return dto;
        }).ToList();

        return new CustomerPagedResult
        {
            Items = dtos,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalReceivables = totalReceivables,
            TotalPayables = totalPayables
        };
    }

    /// <summary>
    /// Builds a DB-side query of customer ids that have data for any of the ticked metrics
    /// (export / receipt / payment within the time range, or non-zero debt). Returns null when nothing is ticked.
    /// </summary>
    private IQueryable<int>? BuildPriorityCustomerIds(IQueryable<Customer> filtered, string? priorityMetrics, string? fromDate, string? toDate)
    {
        var metrics = PriorityMetrics.Parse(priorityMetrics);
        if (metrics.IsEmpty) return null;

        var (start, end) = PriorityMetrics.ParseDateRange(fromDate, toDate);
        IQueryable<int>? ids = null;
        void Add(IQueryable<int> part) => ids = ids == null ? part : ids.Union(part);

        var exportWhs = metrics.Get("export");
        if (exportWhs.Count > 0)
        {
            var exports = _uow.ExportVouchers.Query().Where(v => v.Status != "cancelled");
            if (start.HasValue) exports = exports.Where(v => v.Date >= start.Value);
            if (end.HasValue) exports = exports.Where(v => v.Date <= end.Value);
            if (!exportWhs.Contains(PriorityMetrics.AllWarehouses))
            {
                var whs = exportWhs.ToList();
                exports = exports.Where(v => whs.Contains(v.Warehouse.ToLower()));
            }
            Add(exports.Where(v => v.CustomerId.HasValue).Select(v => v.CustomerId!.Value));
        }

        if (metrics.Has("receipt"))
        {
            var receipts = _uow.Receipts.Query().Where(r => r.CustomerId.HasValue);
            if (start.HasValue) receipts = receipts.Where(r => r.Date >= start.Value);
            if (end.HasValue) receipts = receipts.Where(r => r.Date <= end.Value);
            Add(receipts.Select(r => r.CustomerId!.Value));
        }

        if (metrics.Has("payment"))
        {
            var payments = _uow.Payments.Query().Where(p => p.CustomerId.HasValue && p.Status != "cancelled");
            if (start.HasValue) payments = payments.Where(p => p.Date >= start.Value);
            if (end.HasValue) payments = payments.Where(p => p.Date <= end.Value);
            Add(payments.Select(p => p.CustomerId!.Value));
        }

        var debtWhs = metrics.Get("debt");
        if (debtWhs.Count > 0)
        {
            if (debtWhs.Contains(PriorityMetrics.AllWarehouses))
            {
                Add(filtered.Where(c => c.Debt != 0).Select(c => c.Id));
            }
            var whs = debtWhs.Where(w => w != PriorityMetrics.AllWarehouses).ToList();
            if (whs.Count > 0)
            {
                Add(filtered.Where(c => c.WarehouseDebts.Any(d => d.Debt != 0 && whs.Contains(d.Warehouse.ToLower()))).Select(c => c.Id));
            }
        }

        return ids;
    }

    public async Task<List<string>> GetRegionsAsync(CancellationToken ct = default)
    {
        var regions = await _uow.Customers.Query()
            .Where(c => c.Region != null && c.Region != "")
            .Select(c => c.Region!)
            .Distinct()
            .OrderBy(r => r)
            .ToListAsync(ct);

        return regions;
    }

    public async Task<CustomerDto> GetByIdAsync(int id, CancellationToken ct = default)
    {
        var customer = await _uow.Customers.Query()
            .Include(c => c.WarehouseDebts)
            .FirstOrDefaultAsync(c => c.Id == id, ct)
            ?? throw new NotFoundException($"Không tìm thấy khách hàng với ID {id}");

        return MapToDto(customer);
    }

    public async Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
        {
            throw new ValidationException("Tên khách hàng không được để trống");
        }

        var code = dto.Code?.Trim();
        if (string.IsNullOrWhiteSpace(code))
        {
            var maxId = await _uow.Customers.Query().MaxAsync(c => (int?)c.Id, ct) ?? 0;
            code = $"KH{(maxId + 1):D5}";
        }

        var customer = new Customer
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
            Notes = dto.Notes?.Trim(),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        await _uow.Customers.AddAsync(customer, ct);
        await _uow.SaveChangesAsync(ct);

        if (dto.InitialDebt != 0)
        {
            var wh = DebtHelper.NormalizeWarehouse(dto.InitialDebtWarehouse);
            await DebtHelper.SetCustomerDebtAsync(_uow, customer.Id, wh, dto.InitialDebt, ct);

            var history = new CustomerDebtHistory
            {
                CustomerId = customer.Id,
                Warehouse = wh,
                SourceType = "init",
                Reason = "Khởi tạo công nợ ban đầu",
                BeforeDebt = 0,
                Delta = dto.InitialDebt,
                AfterDebt = dto.InitialDebt,
                CreatedAt = DateTime.UtcNow
            };
            await _uow.CustomerDebtHistories.AddAsync(history, ct);
            await _uow.SaveChangesAsync(ct);
        }

        return await GetByIdAsync(customer.Id, ct);
    }

    public async Task<CustomerDto> UpdateCustomerAsync(int id, UpdateCustomerDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
        {
            throw new ValidationException("Tên khách hàng không được để trống");
        }

        var customer = await _uow.Customers.GetByIdAsync(id, ct)
            ?? throw new NotFoundException($"Không tìm thấy khách hàng với ID {id}");

        customer.Name = dto.Name.Trim();
        customer.ContactName = dto.ContactName?.Trim();
        customer.PhonesJson = dto.PhonesJson?.Trim();
        customer.Email = dto.Email?.Trim();
        customer.AddressesJson = dto.AddressesJson?.Trim();
        customer.Region = dto.Region?.Trim();
        customer.CreditLimit = dto.CreditLimit;
        customer.Notes = dto.Notes?.Trim();
        customer.UpdatedAt = DateTime.UtcNow;

        _uow.Customers.Update(customer);
        await _uow.SaveChangesAsync(ct);

        return await GetByIdAsync(customer.Id, ct);
    }

    public async Task<List<CustomerDebtHistoryDto>> GetDebtHistoryAsync(int customerId, string? month = null, string? fromDate = null, string? toDate = null, string? warehouse = null, CancellationToken ct = default)
    {
        var customerExists = await _uow.Customers.Query().AnyAsync(c => c.Id == customerId, ct);
        if (!customerExists)
        {
            throw new NotFoundException($"Không tìm thấy khách hàng với ID {customerId}");
        }

        var query = _uow.CustomerDebtHistories.Query().Where(h => h.CustomerId == customerId);

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

        return list.Select(h => new CustomerDebtHistoryDto
        {
            Id = h.Id,
            CustomerId = h.CustomerId,
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

    public async Task<bool> AdjustDebtAsync(int customerId, CustomerDebtAdjustDto dto, CancellationToken ct = default)
    {
        var customer = await _uow.Customers.GetByIdAsync(customerId, ct)
            ?? throw new NotFoundException($"Không tìm thấy khách hàng với ID {customerId}");

        var wh = DebtHelper.NormalizeWarehouse(dto.Warehouse);

        decimal delta;
        decimal beforeTotalDebt, afterTotalDebt;

        if (dto.NewDebt.HasValue)
        {
            var res = await DebtHelper.SetCustomerDebtAsync(_uow, customerId, wh, dto.NewDebt.Value, ct);
            delta = res.Delta;
            beforeTotalDebt = res.BeforeTotalDebt;
            afterTotalDebt = res.AfterTotalDebt;
        }
        else
        {
            delta = dto.Delta.GetValueOrDefault();
            var res = await DebtHelper.ApplyCustomerDebtAsync(_uow, customerId, wh, delta, ct);
            beforeTotalDebt = res.BeforeTotalDebt;
            afterTotalDebt = res.AfterTotalDebt;
        }

        var history = new CustomerDebtHistory
        {
            CustomerId = customer.Id,
            Warehouse = wh,
            SourceType = DomainConstants.SourceTypes.ManualAdjustment,
            Reason = dto.Reason ?? $"Điều chỉnh công nợ khách hàng ({wh})",
            Note = dto.Note,
            BeforeDebt = beforeTotalDebt,
            Delta = delta,
            AfterDebt = afterTotalDebt,
            CreatedAt = DateTime.UtcNow
        };

        await _uow.CustomerDebtHistories.AddAsync(history, ct);
        await _uow.SaveChangesAsync(ct);

        return true;
    }

    public async Task<EntityLedgerResponseDto> GetLedgerAsync(int customerId, string? warehouse = null, string? month = null, string? fromDate = null, string? toDate = null, CancellationToken ct = default)
    {
        var customer = await _uow.Customers.GetByIdAsync(customerId, ct)
            ?? throw new NotFoundException($"Không tìm thấy khách hàng với ID {customerId}");

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

        // 1. Phiếu xuất (Bán hàng)
        var exportQuery = _uow.ExportVouchers.Query()
            .Where(v => v.CustomerId == customerId && v.Status != "cancelled");
        if (!isAllWh) exportQuery = exportQuery.Where(v => v.Warehouse == wh);
        if (startDate.HasValue) exportQuery = exportQuery.Where(v => v.Date >= startDate.Value);
        if (endDate.HasValue) exportQuery = exportQuery.Where(v => v.Date < endDate.Value);

        var exports = await exportQuery.ToListAsync(ct);
        foreach (var exp in exports)
        {
            ledgerItems.Add(new EntityLedgerItemDto
            {
                Id = exp.Id,
                Date = exp.Date,
                VoucherNumber = exp.VoucherNumber,
                VoucherType = "export",
                VoucherTypeLabel = "Xuất bán",
                Warehouse = exp.Warehouse,
                Description = string.IsNullOrWhiteSpace(exp.Notes) ? $"Xuất bán nợ theo phiếu {exp.VoucherNumber}" : exp.Notes,
                ImportAmount = 0,
                ExportAmount = exp.TotalSale,
                ReceiptAmount = exp.PaidAmount,
                PaymentAmount = 0
            });
        }

        // 2. Phiếu thu (Khách thanh toán nợ)
        var receiptQuery = _uow.Receipts.Query()
            .Where(r => r.CustomerId == customerId);
        if (!isAllWh) receiptQuery = receiptQuery.Where(r => r.Warehouse == wh);
        if (startDate.HasValue) receiptQuery = receiptQuery.Where(r => r.Date >= startDate.Value);
        if (endDate.HasValue) receiptQuery = receiptQuery.Where(r => r.Date < endDate.Value);

        var receipts = await receiptQuery.ToListAsync(ct);
        foreach (var rc in receipts)
        {
            if (rc.RelatedVoucherType == "export_voucher" && exports.Any(e => e.VoucherNumber == rc.RelatedVoucherId))
            {
                continue;
            }

            ledgerItems.Add(new EntityLedgerItemDto
            {
                Id = rc.Id,
                Date = rc.Date,
                VoucherNumber = rc.ReceiptNumber,
                VoucherType = "receipt",
                VoucherTypeLabel = "Thu tiền",
                Warehouse = rc.Warehouse,
                Description = string.IsNullOrWhiteSpace(rc.Notes) ? $"Thu tiền công nợ theo phiếu {rc.ReceiptNumber}" : rc.Notes,
                ImportAmount = 0,
                ExportAmount = 0,
                ReceiptAmount = rc.Amount,
                PaymentAmount = 0
            });
        }

        // 3. Phiếu chi (Hoàn tiền hoặc chi trả lại cho khách)
        var paymentQuery = _uow.Payments.Query()
            .Where(p => p.CustomerId == customerId && p.Status != "cancelled");
        if (!isAllWh) paymentQuery = paymentQuery.Where(p => p.Warehouse == wh);
        if (startDate.HasValue) paymentQuery = paymentQuery.Where(p => p.Date >= startDate.Value);
        if (endDate.HasValue) paymentQuery = paymentQuery.Where(p => p.Date < endDate.Value);

        var payments = await paymentQuery.ToListAsync(ct);
        foreach (var pm in payments)
        {
            ledgerItems.Add(new EntityLedgerItemDto
            {
                Id = pm.Id,
                Date = pm.Date,
                VoucherNumber = pm.PaymentNumber,
                VoucherType = "payment",
                VoucherTypeLabel = "Chi tiền",
                Warehouse = pm.Warehouse,
                Description = string.IsNullOrWhiteSpace(pm.Notes) ? $"Chi tiền trả lại cho khách theo phiếu {pm.PaymentNumber}" : pm.Notes,
                ImportAmount = 0,
                ExportAmount = 0,
                ReceiptAmount = 0,
                PaymentAmount = pm.Amount
            });
        }

        // 4. Các điều chỉnh công nợ thủ công
        var historyQuery = _uow.CustomerDebtHistories.Query()
            .Where(h => h.CustomerId == customerId && h.SourceType == DomainConstants.SourceTypes.ManualAdjustment);
        if (!isAllWh) historyQuery = historyQuery.Where(h => h.Warehouse == wh);
        if (startDate.HasValue) historyQuery = historyQuery.Where(h => h.CreatedAt >= startDate.Value);
        if (endDate.HasValue) historyQuery = historyQuery.Where(h => h.CreatedAt < endDate.Value);

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
                ImportAmount = 0,
                ExportAmount = h.Delta > 0 ? h.Delta : 0,
                ReceiptAmount = h.Delta < 0 ? -h.Delta : 0,
                PaymentAmount = 0
            });
        }

        // Tính biến động phát sinh sau kỳ (nếu có endDate)
        decimal netChangeAfterEnd = 0;
        if (endDate.HasValue)
        {
            var expAfterQuery = _uow.ExportVouchers.Query()
                .Where(v => v.CustomerId == customerId && v.Status != "cancelled" && v.Date >= endDate.Value);
            var rcAfterQuery = _uow.Receipts.Query()
                .Where(r => r.CustomerId == customerId && r.Date >= endDate.Value);
            var pmAfterQuery = _uow.Payments.Query()
                .Where(p => p.CustomerId == customerId && p.Status != "cancelled" && p.Date >= endDate.Value);
            var adjAfterQuery = _uow.CustomerDebtHistories.Query()
                .Where(h => h.CustomerId == customerId && h.SourceType == DomainConstants.SourceTypes.ManualAdjustment && h.CreatedAt >= endDate.Value);

            if (!isAllWh)
            {
                expAfterQuery = expAfterQuery.Where(v => v.Warehouse == wh);
                rcAfterQuery = rcAfterQuery.Where(r => r.Warehouse == wh);
                pmAfterQuery = pmAfterQuery.Where(p => p.Warehouse == wh);
                adjAfterQuery = adjAfterQuery.Where(h => h.Warehouse == wh);
            }

            var expAfter = await expAfterQuery.SumAsync(v => (decimal?)v.TotalSale, ct) ?? 0;
            var rcAfter = await rcAfterQuery.SumAsync(r => (decimal?)r.Amount, ct) ?? 0;
            var pmAfter = await pmAfterQuery.SumAsync(p => (decimal?)p.Amount, ct) ?? 0;
            var adjAfter = await adjAfterQuery.SumAsync(h => (decimal?)h.Delta, ct) ?? 0;

            netChangeAfterEnd = expAfter + pmAfter - rcAfter + adjAfter;
        }

        decimal currentBalance;
        if (!isAllWh)
        {
            var whDebtRecord = await _uow.CustomerWarehouseDebts.Query()
                .FirstOrDefaultAsync(w => w.CustomerId == customerId && w.Warehouse == wh, ct);
            currentBalance = whDebtRecord?.Debt ?? 0;
        }
        else
        {
            currentBalance = customer.Debt;
        }

        var closingBalance = currentBalance - netChangeAfterEnd;
        var periodNetChange = ledgerItems.Sum(i => (i.ExportAmount + i.PaymentAmount) - (i.ReceiptAmount + i.ImportAmount));
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
                ImportAmount = 0,
                ExportAmount = openingBalance > 0 ? openingBalance : 0,
                ReceiptAmount = openingBalance < 0 ? -openingBalance : 0,
                PaymentAmount = 0,
                Balance = openingBalance
            });
        }

        decimal runningBalance = openingBalance;
        int startIndex = openingBalance != 0 ? 1 : 0;
        for (int i = startIndex; i < sorted.Count; i++)
        {
            var item = sorted[i];
            runningBalance += (item.ExportAmount + item.PaymentAmount) - (item.ReceiptAmount + item.ImportAmount);
            item.Balance = runningBalance;
        }

        var resultList = sorted.OrderByDescending(i => i.Date).ThenByDescending(i => i.Id).ToList();

        return new EntityLedgerResponseDto
        {
            EntityId = customer.Id,
            EntityCode = customer.Code,
            EntityName = customer.Name,
            Warehouse = isAllWh ? "Tất cả kho" : wh,
            TotalImport = resultList.Sum(i => i.ImportAmount),
            TotalExport = resultList.Sum(i => i.ExportAmount),
            TotalReceipt = resultList.Sum(i => i.ReceiptAmount),
            TotalPayment = resultList.Sum(i => i.PaymentAmount),
            CurrentBalance = currentBalance,
            Items = resultList
        };
    }

    private static CustomerDto MapToDto(Customer c) => new()
    {
        Id = c.Id,
        Code = c.Code,
        Name = c.Name,
        ContactName = c.ContactName,
        PhonesJson = c.PhonesJson,
        Email = c.Email,
        AddressesJson = c.AddressesJson,
        Region = c.Region,
        Debt = c.Debt,
        WarehouseDebts = c.WarehouseDebts != null && c.WarehouseDebts.Count > 0
            ? c.WarehouseDebts.ToDictionary(w => w.Warehouse, w => w.Debt, StringComparer.OrdinalIgnoreCase)
            : new(StringComparer.OrdinalIgnoreCase),
        CreditLimit = c.CreditLimit,
        Notes = c.Notes,
        CreatedAt = c.CreatedAt,
        UpdatedAt = c.UpdatedAt
    };
}
