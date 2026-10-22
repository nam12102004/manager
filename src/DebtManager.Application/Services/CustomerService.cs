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
        var query = _uow.Customers.Query().AsQueryable();

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
        CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = pageSize > 0 ? pageSize : 15;

        var query = _uow.Customers.Query().AsQueryable();

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

        // Sorting
        query = sortBy switch
        {
            "debt_desc" => query.OrderByDescending(c => c.Debt).ThenByDescending(c => c.Id),
            "debt_asc" => query.OrderBy(c => c.Debt).ThenByDescending(c => c.Id),
            _ => query.OrderByDescending(c => c.Id)
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
            .Where(v => customerIds.Contains(v.CustomerId) && v.Status != "cancelled");
        if (startDate.HasValue)
        {
            customerExportsQuery = customerExportsQuery.Where(v => v.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            customerExportsQuery = customerExportsQuery.Where(v => v.Date <= endDate.Value);
        }

        var customerExportsGroup = await customerExportsQuery
            .GroupBy(v => new { v.CustomerId, Warehouse = v.Warehouse.ToLower() })
            .Select(g => new { g.Key.CustomerId, g.Key.Warehouse, Total = g.Sum(x => x.TotalSale) })
            .ToListAsync(ct);

        var exportsByCustomer = customerExportsGroup
            .GroupBy(x => x.CustomerId)
            .ToDictionary(
                g => g.Key,
                g => g.ToDictionary(x => x.Warehouse, x => x.Total, StringComparer.OrdinalIgnoreCase)
            );

        var receiptsQuery = _uow.Receipts.Query()
            .Where(r => r.CustomerId != null && customerIds.Contains(r.CustomerId.Value));
        if (startDate.HasValue)
        {
            receiptsQuery = receiptsQuery.Where(r => r.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            receiptsQuery = receiptsQuery.Where(r => r.Date <= endDate.Value);
        }

        var receiptsMap = await receiptsQuery
            .GroupBy(r => r.CustomerId!.Value)
            .Select(g => new { CustomerId = g.Key, Total = g.Sum(x => x.Amount) })
            .ToDictionaryAsync(x => x.CustomerId, x => x.Total, ct);

        var paymentsQuery = _uow.Payments.Query()
            .Where(p => p.CustomerId != null && customerIds.Contains(p.CustomerId.Value) && p.Status != "cancelled");
        if (startDate.HasValue)
        {
            paymentsQuery = paymentsQuery.Where(p => p.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            paymentsQuery = paymentsQuery.Where(p => p.Date <= endDate.Value);
        }

        var paymentsMap = await paymentsQuery
            .GroupBy(p => p.CustomerId!.Value)
            .Select(g => new { CustomerId = g.Key, Total = g.Sum(x => x.Amount) })
            .ToDictionaryAsync(x => x.CustomerId, x => x.Total, ct);

        var dtos = items.Select(c =>
        {
            var dto = MapToDto(c);
            if (exportsByCustomer.TryGetValue(c.Id, out var whDict))
            {
                dto.WarehouseExports = whDict;
                dto.TotalExportAmount = whDict.Values.Sum();
            }
            else
            {
                dto.WarehouseExports = new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase);
                dto.TotalExportAmount = 0;
            }
            dto.TotalReceiptAmount = receiptsMap.GetValueOrDefault(c.Id, 0);
            dto.TotalPaymentAmount = paymentsMap.GetValueOrDefault(c.Id, 0);
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

    public async Task<List<string>> GetRegionsAsync(CancellationToken ct = default)
    {
        return await _uow.Customers.Query()
            .Where(c => c.Region != null && c.Region != "")
            .Select(c => c.Region!)
            .Distinct()
            .OrderBy(r => r)
            .ToListAsync(ct);
    }

    public async Task<CustomerDto> GetByIdAsync(int id, CancellationToken ct = default)
    {
        var customer = await _uow.Customers.GetByIdAsync(id, ct)
            ?? throw new NotFoundException($"Không tìm thấy khách hàng với ID {id}");

        return MapToDto(customer);
    }

    public async Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
        {
            throw new ValidationException("Tên khách hàng không được để trống");
        }

        var code = string.IsNullOrWhiteSpace(dto.Code)
            ? $"KH{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 1000000):D6}"
            : dto.Code.Trim();

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
            Debt = dto.InitialDebt,
            Notes = dto.Notes?.Trim(),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        await _uow.Customers.AddAsync(customer, ct);
        await _uow.SaveChangesAsync(ct);

        if (dto.InitialDebt != 0)
        {
            var history = new CustomerDebtHistory
            {
                CustomerId = customer.Id,
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

        return MapToDto(customer);
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

        return MapToDto(customer);
    }

    public async Task<List<CustomerDebtHistoryDto>> GetDebtHistoryAsync(int customerId, string? month = null, string? fromDate = null, string? toDate = null, CancellationToken ct = default)
    {
        var customerExists = await _uow.Customers.Query().AnyAsync(c => c.Id == customerId, ct);
        if (!customerExists)
        {
            throw new NotFoundException($"Không tìm thấy khách hàng với ID {customerId}");
        }

        var query = _uow.CustomerDebtHistories.Query().Where(h => h.CustomerId == customerId);

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

        var beforeDebt = customer.Debt;
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
        customer.Debt = afterDebt;
        customer.UpdatedAt = DateTime.UtcNow;

        var history = new CustomerDebtHistory
        {
            CustomerId = customer.Id,
            SourceType = DomainConstants.SourceTypes.ManualAdjustment,
            Reason = dto.Reason ?? "Điều chỉnh công nợ khách hàng",
            Note = dto.Note,
            BeforeDebt = beforeDebt,
            Delta = delta,
            AfterDebt = afterDebt,
            CreatedAt = DateTime.UtcNow
        };

        _uow.Customers.Update(customer);
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

        // 1. Export vouchers (Xuất hàng)
        var exportQuery = _uow.ExportVouchers.Query()
            .Where(v => v.CustomerId == customerId && v.Status != "cancelled");
        if (!isAllWh)
        {
            exportQuery = exportQuery.Where(v => v.Warehouse.ToLower() == wh);
        }
        if (startDate.HasValue)
        {
            exportQuery = exportQuery.Where(v => v.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            exportQuery = exportQuery.Where(v => v.Date < endDate.Value);
        }
        var exports = await exportQuery.ToListAsync(ct);
        foreach (var ex in exports)
        {
            ledgerItems.Add(new EntityLedgerItemDto
            {
                Id = ex.Id,
                Date = ex.Date,
                VoucherNumber = ex.VoucherNumber,
                VoucherType = "export",
                VoucherTypeLabel = "Phiếu xuất",
                Warehouse = ex.Warehouse,
                Description = string.IsNullOrWhiteSpace(ex.Notes) ? $"Xuất bán hàng {ex.VoucherNumber}" : ex.Notes,
                ImportAmount = 0,
                ExportAmount = ex.TotalSale,
                ReceiptAmount = 0,
                PaymentAmount = 0
            });
        }

        // 2. Receipts (Thu tiền)
        var receiptQuery = _uow.Receipts.Query().Where(r => r.CustomerId == customerId);
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
            if (!isAllWh && rc.RelatedVoucherType == "export" && !string.IsNullOrWhiteSpace(rc.RelatedVoucherId))
            {
                var relatedExport = exports.FirstOrDefault(e => e.VoucherNumber == rc.RelatedVoucherId);
                if (relatedExport == null)
                {
                    var existsInWh = await _uow.ExportVouchers.Query().AnyAsync(e => e.VoucherNumber == rc.RelatedVoucherId && e.Warehouse.ToLower() == wh, ct);
                    if (!existsInWh) continue;
                }
            }
            ledgerItems.Add(new EntityLedgerItemDto
            {
                Id = rc.Id,
                Date = rc.Date,
                VoucherNumber = rc.ReceiptNumber,
                VoucherType = "receipt",
                VoucherTypeLabel = "Phiếu thu",
                Warehouse = isAllWh ? null : wh,
                Description = string.IsNullOrWhiteSpace(rc.Notes) ? $"Thu tiền ({rc.Method})" : rc.Notes,
                ImportAmount = 0,
                ExportAmount = 0,
                ReceiptAmount = rc.Amount,
                PaymentAmount = 0
            });
        }

        // 3. Payments (Chi tiền hoàn lại/trả khách)
        var paymentQuery = _uow.Payments.Query().Where(p => p.CustomerId == customerId && p.Status != "cancelled");
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
            ledgerItems.Add(new EntityLedgerItemDto
            {
                Id = pm.Id,
                Date = pm.Date,
                VoucherNumber = pm.PaymentNumber,
                VoucherType = "payment",
                VoucherTypeLabel = "Phiếu chi",
                Warehouse = isAllWh ? null : wh,
                Description = string.IsNullOrWhiteSpace(pm.Notes) ? $"Chi tiền ({pm.Method})" : pm.Notes,
                ImportAmount = 0,
                ExportAmount = 0,
                ReceiptAmount = 0,
                PaymentAmount = pm.Amount
            });
        }

        // 4. Manual Debt Adjustments / Initial Debt
        var historyQuery = _uow.CustomerDebtHistories.Query()
            .Where(h => h.CustomerId == customerId && (h.SourceType == DomainConstants.SourceTypes.ManualAdjustment || h.SourceType == "init"));
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
                VoucherTypeLabel = h.SourceType == "init" ? "Số dư đầu" : "Điều chỉnh",
                Warehouse = isAllWh ? null : wh,
                Description = string.IsNullOrWhiteSpace(h.Note) ? (h.Reason ?? "Điều chỉnh công nợ") : $"{h.Reason} - {h.Note}",
                ImportAmount = 0,
                ExportAmount = h.Delta > 0 ? h.Delta : 0,
                ReceiptAmount = h.Delta < 0 ? -h.Delta : 0,
                PaymentAmount = 0
            });
        }

        var sorted = ledgerItems.OrderBy(i => i.Date).ThenBy(i => i.Id).ToList();
        decimal runningBalance = 0;
        foreach (var item in sorted)
        {
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
            CurrentBalance = customer.Debt,
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
        CreditLimit = c.CreditLimit,
        Notes = c.Notes,
        CreatedAt = c.CreatedAt,
        UpdatedAt = c.UpdatedAt
    };
}
