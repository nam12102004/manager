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

    public async Task<List<ReceiptDto>> GetReceiptsAsync(int? customerId = null, int? supplierId = null, string? search = null, CancellationToken ct = default)
    {
        var query = _uow.Receipts.Query()
            .Include(r => r.Customer)
            .Include(r => r.Supplier)
            .AsQueryable();

        if (customerId.HasValue) query = query.Where(r => r.CustomerId == customerId.Value);
        if (supplierId.HasValue) query = query.Where(r => r.SupplierId == supplierId.Value);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(r => r.ReceiptNumber.ToLower().Contains(s) ||
                                     (r.Customer != null && r.Customer.Name.ToLower().Contains(s)) ||
                                     (r.Supplier != null && r.Supplier.Name.ToLower().Contains(s)));
        }

        var list = await query.OrderByDescending(r => r.Date)
                              .ThenByDescending(r => r.Id)
                              .ToListAsync(ct);

        return list.Select(MapToDto).ToList();
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
            var receipt = new Receipt
            {
                ReceiptNumber = receiptNumber,
                Date = dto.Date ?? DateTime.UtcNow,
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

                var beforeDebt = customer.Debt;
                var delta = -dto.Amount; // Thu tiền làm giảm nợ khách hàng
                var afterDebt = beforeDebt + delta;
                customer.Debt = afterDebt;
                customer.UpdatedAt = DateTime.UtcNow;
                _uow.Customers.Update(customer);

                await _uow.CustomerDebtHistories.AddAsync(new CustomerDebtHistory
                {
                    CustomerId = customer.Id,
                    SourceType = DomainConstants.SourceTypes.Receipt,
                    ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                    ReferenceId = receiptNumber,
                    Reason = $"Thu tiền khách theo phiếu {receiptNumber}",
                    BeforeDebt = beforeDebt,
                    Delta = delta,
                    AfterDebt = afterDebt,
                    CreatedAt = DateTime.UtcNow
                }, ct);
            }
            else if (dto.SupplierId.HasValue)
            {
                var supplier = await _uow.Suppliers.GetByIdAsync(dto.SupplierId.Value, ct)
                    ?? throw new NotFoundException($"Không tìm thấy nhà cung cấp với ID {dto.SupplierId.Value}");

                var beforeDebt = supplier.Debt;
                var delta = -dto.Amount; // Thu tiền từ NCC: giảm phải thu / tăng phải trả (delta = -Amount)
                var afterDebt = beforeDebt + delta;
                supplier.Debt = afterDebt;
                supplier.UpdatedAt = DateTime.UtcNow;
                _uow.Suppliers.Update(supplier);

                await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                {
                    SupplierId = supplier.Id,
                    SourceType = DomainConstants.SourceTypes.Receipt,
                    ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                    ReferenceId = receiptNumber,
                    Reason = $"Thu hoàn tiền từ NCC theo phiếu {receiptNumber}",
                    BeforeDebt = beforeDebt,
                    Delta = delta,
                    AfterDebt = afterDebt,
                    CreatedAt = DateTime.UtcNow
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

        await _uow.BeginTransactionAsync(ct);
        try
        {
            if (receipt.CustomerId.HasValue)
            {
                var customer = await _uow.Customers.GetByIdAsync(receipt.CustomerId.Value, ct);
                if (customer != null)
                {
                    var beforeDebt = customer.Debt;
                    var delta = receipt.Amount; // Trả lại số nợ chưa thu
                    var afterDebt = beforeDebt + delta;
                    customer.Debt = afterDebt;
                    customer.UpdatedAt = DateTime.UtcNow;
                    _uow.Customers.Update(customer);

                    await _uow.CustomerDebtHistories.AddAsync(new CustomerDebtHistory
                    {
                        CustomerId = customer.Id,
                        SourceType = "receipt_deleted",
                        ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                        ReferenceId = receipt.ReceiptNumber,
                        Reason = $"Khôi phục nợ do xóa phiếu thu {receipt.ReceiptNumber}",
                        BeforeDebt = beforeDebt,
                        Delta = delta,
                        AfterDebt = afterDebt,
                        CreatedAt = DateTime.UtcNow
                    }, ct);
                }
            }
            else if (receipt.SupplierId.HasValue)
            {
                var supplier = await _uow.Suppliers.GetByIdAsync(receipt.SupplierId.Value, ct);
                if (supplier != null)
                {
                    var beforeDebt = supplier.Debt;
                    var delta = receipt.Amount;
                    var afterDebt = beforeDebt + delta;
                    supplier.Debt = afterDebt;
                    supplier.UpdatedAt = DateTime.UtcNow;
                    _uow.Suppliers.Update(supplier);

                    await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                    {
                        SupplierId = supplier.Id,
                        SourceType = "receipt_deleted",
                        ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                        ReferenceId = receipt.ReceiptNumber,
                        Reason = $"Hoàn tác thu tiền NCC do xóa phiếu thu {receipt.ReceiptNumber}",
                        BeforeDebt = beforeDebt,
                        Delta = delta,
                        AfterDebt = afterDebt,
                        CreatedAt = DateTime.UtcNow
                    }, ct);
                }
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
        CustomerId = r.CustomerId,
        CustomerName = r.Customer?.Name,
        SupplierId = r.SupplierId,
        SupplierName = r.Supplier?.Name,
        Amount = r.Amount,
        Method = r.Method,
        RelatedVoucherType = r.RelatedVoucherType,
        RelatedVoucherId = r.RelatedVoucherId,
        Notes = r.Notes,
        CreatedAt = r.CreatedAt
    };
}
