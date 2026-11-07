using DebtManager.Application.Common;
using DebtManager.Application.Common.Exceptions;
using DebtManager.Application.DTOs.Receipts;
using DebtManager.Application.Interfaces;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Domain.Common;
using DebtManager.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Application.Services;

public class ReceiptService : IReceiptService
{
    private readonly IUnitOfWork _uow;

    public ReceiptService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<List<ReceiptDto>> GetReceiptsAsync(int? customerId = null, int? supplierId = null, string? search = null, string? month = null, string? date = null, string? fromDate = null, string? toDate = null, string? warehouse = null, CancellationToken ct = default)
    {
        var query = _uow.Receipts.Query()
            .Include(r => r.Customer)
            .Include(r => r.Supplier)
            .AsQueryable();

        if (customerId.HasValue) query = query.Where(r => r.CustomerId == customerId.Value);
        if (supplierId.HasValue) query = query.Where(r => r.SupplierId == supplierId.Value);

        if (!string.IsNullOrWhiteSpace(warehouse) && warehouse != "all" && warehouse != "overview")
        {
            query = query.Where(r => r.Warehouse == warehouse.Trim());
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(r => r.ReceiptNumber.ToLower().Contains(s) ||
                                     (r.Customer != null && ((r.Customer.Code != null && r.Customer.Code.ToLower().Contains(s)) || r.Customer.Name.ToLower().Contains(s))) ||
                                     (r.Supplier != null && ((r.Supplier.Code != null && r.Supplier.Code.ToLower().Contains(s)) || r.Supplier.Name.ToLower().Contains(s))) ||
                                     (r.Notes != null && r.Notes.ToLower().Contains(s)));
        }

        var effectiveDate = !string.IsNullOrWhiteSpace(date) ? date : month;

        if (!string.IsNullOrWhiteSpace(fromDate) && DateTime.TryParse(fromDate.Trim(), out var pFrom))
        {
            var start = new DateTime(pFrom.Year, pFrom.Month, pFrom.Day, 0, 0, 0, DateTimeKind.Utc);
            query = query.Where(r => r.Date >= start);
        }

        if (!string.IsNullOrWhiteSpace(toDate) && DateTime.TryParse(toDate.Trim(), out var pTo))
        {
            var end = new DateTime(pTo.Year, pTo.Month, pTo.Day, 23, 59, 59, 999, DateTimeKind.Utc);
            query = query.Where(r => r.Date <= end);
        }

        if (string.IsNullOrWhiteSpace(fromDate) && string.IsNullOrWhiteSpace(toDate) && !string.IsNullOrWhiteSpace(effectiveDate))
        {
            if (DateTime.TryParseExact(effectiveDate.Trim(), "yyyy-MM-dd", null, System.Globalization.DateTimeStyles.None, out var parsedDate))
            {
                var start = new DateTime(parsedDate.Year, parsedDate.Month, parsedDate.Day, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddDays(1);
                query = query.Where(r => r.Date >= start && r.Date < end);
            }
            else if (DateTime.TryParseExact(effectiveDate.Trim(), "yyyy-MM", null, System.Globalization.DateTimeStyles.None, out var parsedMonth))
            {
                var start = new DateTime(parsedMonth.Year, parsedMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddMonths(1);
                query = query.Where(r => r.Date >= start && r.Date < end);
            }
        }

        var list = await query.OrderByDescending(r => r.Date)
                              .ThenByDescending(r => r.Id)
                              .ToListAsync(ct);

        return list.Select(MapToDto).ToList();
    }

    public async Task<ReceiptPagedResult> GetPagedReceiptsAsync(
        int? customerId = null,
        int? supplierId = null,
        string? search = null,
        string? month = null,
        string? date = null,
        string? fromDate = null,
        string? toDate = null,
        string? warehouse = null,
        int page = 1,
        int pageSize = 15,
        CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = pageSize > 0 ? pageSize : 15;

        var query = _uow.Receipts.Query()
            .Include(r => r.Customer)
            .Include(r => r.Supplier)
            .AsQueryable();

        if (customerId.HasValue) query = query.Where(r => r.CustomerId == customerId.Value);
        if (supplierId.HasValue) query = query.Where(r => r.SupplierId == supplierId.Value);

        if (!string.IsNullOrWhiteSpace(warehouse) && warehouse != "all" && warehouse != "overview")
        {
            query = query.Where(r => r.Warehouse == warehouse.Trim());
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(r => r.ReceiptNumber.ToLower().Contains(s) ||
                                     (r.Customer != null && ((r.Customer.Code != null && r.Customer.Code.ToLower().Contains(s)) || r.Customer.Name.ToLower().Contains(s))) ||
                                     (r.Supplier != null && ((r.Supplier.Code != null && r.Supplier.Code.ToLower().Contains(s)) || r.Supplier.Name.ToLower().Contains(s))) ||
                                     (r.Notes != null && r.Notes.ToLower().Contains(s)));
        }

        var effectiveDate = !string.IsNullOrWhiteSpace(date) ? date : month;

        if (!string.IsNullOrWhiteSpace(fromDate) && DateTime.TryParse(fromDate.Trim(), out var pFrom))
        {
            var start = new DateTime(pFrom.Year, pFrom.Month, pFrom.Day, 0, 0, 0, DateTimeKind.Utc);
            query = query.Where(r => r.Date >= start);
        }

        if (!string.IsNullOrWhiteSpace(toDate) && DateTime.TryParse(toDate.Trim(), out var pTo))
        {
            var end = new DateTime(pTo.Year, pTo.Month, pTo.Day, 23, 59, 59, 999, DateTimeKind.Utc);
            query = query.Where(r => r.Date <= end);
        }

        if (string.IsNullOrWhiteSpace(fromDate) && string.IsNullOrWhiteSpace(toDate) && !string.IsNullOrWhiteSpace(effectiveDate))
        {
            if (DateTime.TryParseExact(effectiveDate.Trim(), "yyyy-MM-dd", null, System.Globalization.DateTimeStyles.None, out var parsedDate))
            {
                var start = new DateTime(parsedDate.Year, parsedDate.Month, parsedDate.Day, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddDays(1);
                query = query.Where(r => r.Date >= start && r.Date < end);
            }
            else if (DateTime.TryParseExact(effectiveDate.Trim(), "yyyy-MM", null, System.Globalization.DateTimeStyles.None, out var parsedMonth))
            {
                var start = new DateTime(parsedMonth.Year, parsedMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddMonths(1);
                query = query.Where(r => r.Date >= start && r.Date < end);
            }
        }

        var totalCount = await query.CountAsync(ct);
        var totalAmount = await query.SumAsync(r => (decimal?)r.Amount, ct) ?? 0;

        var items = await query.OrderByDescending(r => r.Date)
                              .ThenByDescending(r => r.Id)
                              .Skip((page - 1) * pageSize)
                              .Take(pageSize)
                              .ToListAsync(ct);

        return new ReceiptPagedResult
        {
            Items = items.Select(MapToDto).ToList(),
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalAmount = totalAmount
        };
    }

    public async Task<ReceiptDto> GetByIdAsync(long id, CancellationToken ct = default)
    {
        var receipt = await _uow.Receipts.Query()
            .Include(r => r.Customer)
            .Include(r => r.Supplier)
            .FirstOrDefaultAsync(r => r.Id == id, ct)
            ?? throw new NotFoundException($"Không tìm thấy phiếu thu có ID {id}");

        return MapToDto(receipt);
    }

    public async Task<ReceiptDto> CreateReceiptAsync(CreateReceiptDto dto, CancellationToken ct = default)
    {
        if (dto.Amount <= 0)
        {
            throw new ValidationException("Số tiền thu phải lớn hơn 0");
        }

        await _uow.BeginTransactionAsync(ct);
        try
        {
            var receiptNumber = $"PT{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 100000000):D8}";
            var warehouse = DebtHelper.NormalizeWarehouse(dto.Warehouse);

            var receipt = new Receipt
            {
                ReceiptNumber = receiptNumber,
                Date = dto.Date.HasValue
                    ? (dto.Date.Value.TimeOfDay == TimeSpan.Zero ? dto.Date.Value.Date.Add(DateTime.UtcNow.TimeOfDay) : dto.Date.Value)
                    : DateTime.UtcNow,
                Warehouse = warehouse,
                CustomerId = dto.CustomerId,
                SupplierId = dto.SupplierId,
                Amount = dto.Amount,
                Method = dto.Method,
                RelatedVoucherType = dto.RelatedVoucherType,
                RelatedVoucherId = dto.RelatedVoucherId,
                Notes = dto.Notes?.Trim(),
                CreatedAt = DateTime.UtcNow
            };

            if (dto.CustomerId.HasValue)
            {
                var customer = await _uow.Customers.GetByIdAsync(dto.CustomerId.Value, ct)
                    ?? throw new InvalidOperationException("Không tìm thấy khách hàng");
                receipt.Customer = customer;

                // Khấu trừ nợ tại kho tương ứng
                var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                    await DebtHelper.ApplyCustomerDebtAsync(_uow, customer.Id, warehouse, -dto.Amount, ct);

                await _uow.CustomerDebtHistories.AddAsync(new CustomerDebtHistory
                {
                    CustomerId = customer.Id,
                    Warehouse = warehouse,
                    SourceType = DomainConstants.SourceTypes.Receipt,
                    ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                    ReferenceId = receiptNumber,
                    Reason = $"Thu tiền khách theo phiếu {receiptNumber}",
                    BeforeDebt = beforeTotalDebt,
                    Delta = -dto.Amount,
                    AfterDebt = afterTotalDebt,
                    CreatedAt = receipt.Date
                }, ct);
            }
            else if (dto.SupplierId.HasValue)
            {
                var supplier = await _uow.Suppliers.GetByIdAsync(dto.SupplierId.Value, ct)
                    ?? throw new NotFoundException($"Không tìm thấy nhà cung cấp với ID {dto.SupplierId.Value}");
                receipt.Supplier = supplier;

                // Thu tiền từ NCC: giảm phải thu / tăng phải trả (delta = -Amount)
                var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                    await DebtHelper.ApplySupplierDebtAsync(_uow, supplier.Id, warehouse, -dto.Amount, ct);

                await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                {
                    SupplierId = supplier.Id,
                    Warehouse = warehouse,
                    SourceType = DomainConstants.SourceTypes.Receipt,
                    ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                    ReferenceId = receiptNumber,
                    Reason = $"Thu hoàn tiền từ NCC theo phiếu {receiptNumber}",
                    BeforeDebt = beforeTotalDebt,
                    Delta = -dto.Amount,
                    AfterDebt = afterTotalDebt,
                    CreatedAt = receipt.Date
                }, ct);
            }

            await _uow.Receipts.AddAsync(receipt, ct);
            await _uow.SaveChangesAsync(ct);
            await _uow.CommitAsync(ct);

            return MapToDto(receipt);
        }
        catch
        {
            await _uow.RollbackAsync(ct);
            throw;
        }
    }

    public async Task<bool> DeleteReceiptAsync(long id, CancellationToken ct = default)
    {
        var receipt = await _uow.Receipts.GetByIdAsync(id, ct)
            ?? throw new NotFoundException($"Không tìm thấy phiếu thu có ID {id}");

        if (receipt.RelatedVoucherType == "export_voucher" && !string.IsNullOrWhiteSpace(receipt.RelatedVoucherId))
        {
            throw new BusinessRuleException($"Phiếu thu {receipt.ReceiptNumber} được tạo tự động từ Phiếu xuất {receipt.RelatedVoucherId}. Vui lòng hủy hoặc điều chỉnh trực tiếp trên Phiếu xuất tương ứng để đảm bảo toàn vẹn dữ liệu.");
        }

        await _uow.BeginTransactionAsync(ct);
        try
        {
            var warehouse = DebtHelper.NormalizeWarehouse(receipt.Warehouse);

            if (receipt.CustomerId.HasValue)
            {
                // Hoàn lại nợ tại kho của phiếu thu
                var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                    await DebtHelper.ApplyCustomerDebtAsync(_uow, receipt.CustomerId.Value, warehouse, receipt.Amount, ct);

                await _uow.CustomerDebtHistories.AddAsync(new CustomerDebtHistory
                {
                    CustomerId = receipt.CustomerId.Value,
                    Warehouse = warehouse,
                    SourceType = "receipt_deleted",
                    ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                    ReferenceId = receipt.ReceiptNumber,
                    Reason = $"Khôi phục nợ do xóa phiếu thu {receipt.ReceiptNumber}",
                    BeforeDebt = beforeTotalDebt,
                    Delta = receipt.Amount,
                    AfterDebt = afterTotalDebt,
                    CreatedAt = receipt.Date
                }, ct);
            }
            else if (receipt.SupplierId.HasValue)
            {
                var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                    await DebtHelper.ApplySupplierDebtAsync(_uow, receipt.SupplierId.Value, warehouse, receipt.Amount, ct);

                await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                {
                    SupplierId = receipt.SupplierId.Value,
                    Warehouse = warehouse,
                    SourceType = "receipt_deleted",
                    ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                    ReferenceId = receipt.ReceiptNumber,
                    Reason = $"Hoàn tác thu tiền NCC do xóa phiếu thu {receipt.ReceiptNumber}",
                    BeforeDebt = beforeTotalDebt,
                    Delta = receipt.Amount,
                    AfterDebt = afterTotalDebt,
                    CreatedAt = receipt.Date
                }, ct);
            }

            _uow.Receipts.Remove(receipt);
            await _uow.SaveChangesAsync(ct);
            await _uow.CommitAsync(ct);
            return true;
        }
        catch
        {
            await _uow.RollbackAsync(ct);
            throw;
        }
    }

    private static ReceiptDto MapToDto(Receipt r) => new()
    {
        Id = r.Id,
        ReceiptNumber = r.ReceiptNumber,
        Date = r.Date,
        Warehouse = r.Warehouse ?? "warehouse1",
        CustomerId = r.CustomerId,
        CustomerName = r.Customer?.Name,
        CustomerCode = r.Customer?.Code,
        SupplierId = r.SupplierId,
        SupplierName = r.Supplier?.Name,
        SupplierCode = r.Supplier?.Code,
        Amount = r.Amount,
        Method = r.Method,
        RelatedVoucherType = r.RelatedVoucherType,
        RelatedVoucherId = r.RelatedVoucherId,
        Notes = r.Notes,
        CreatedAt = r.CreatedAt
    };
}
