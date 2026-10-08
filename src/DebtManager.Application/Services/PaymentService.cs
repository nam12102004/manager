using DebtManager.Application.Common.Exceptions;
using DebtManager.Application.DTOs.Payments;
using DebtManager.Application.Interfaces;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Domain.Common;
using DebtManager.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Application.Services;

public class PaymentService : IPaymentService
{
    private readonly IUnitOfWork _uow;

    public PaymentService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<List<PaymentDto>> GetPaymentsAsync(int? supplierId = null, int? customerId = null, string? search = null, CancellationToken ct = default)
    {
        var query = _uow.Payments.Query()
            .Include(p => p.Supplier)
            .Include(p => p.Customer)
            .AsQueryable();

        if (supplierId.HasValue) query = query.Where(p => p.SupplierId == supplierId.Value);
        if (customerId.HasValue) query = query.Where(p => p.CustomerId == customerId.Value);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(p => p.PaymentNumber.ToLower().Contains(s) ||
                                     (p.Supplier != null && p.Supplier.Name.ToLower().Contains(s)) ||
                                     (p.Customer != null && p.Customer.Name.ToLower().Contains(s)));
        }

        var list = await query.OrderByDescending(p => p.Date)
                              .ThenByDescending(p => p.Id)
                              .ToListAsync(ct);

        return list.Select(MapToDto).ToList();
    }

    public async Task<PaymentDto> GetByIdAsync(long id, CancellationToken ct = default)
    {
        var payment = await _uow.Payments.Query()
            .Include(p => p.Supplier)
            .Include(p => p.Customer)
            .FirstOrDefaultAsync(p => p.Id == id, ct)
            ?? throw new NotFoundException($"Không tìm thấy phiếu chi có ID {id}");

        return MapToDto(payment);
    }

    public async Task<PaymentDto> CreatePaymentAsync(CreatePaymentDto dto, CancellationToken ct = default)
    {
        if (dto.Amount <= 0)
        {
            throw new ValidationException("Số tiền chi phải lớn hơn 0");
        }

        await _uow.BeginTransactionAsync(ct);
        try
        {
            var paymentNumber = $"PC{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 100000000):D8}";
            var payment = new Payment
            {
                PaymentNumber = paymentNumber,
                Date = dto.Date ?? DateTime.UtcNow,
                SupplierId = dto.SupplierId,
                CustomerId = dto.CustomerId,
                Amount = dto.Amount,
                Method = dto.Method,
                Status = DomainConstants.VoucherStatuses.Confirmed,
                RelatedVoucherType = dto.RelatedVoucherType,
                RelatedVoucherId = dto.RelatedVoucherId,
                Notes = dto.Notes?.Trim(),
                CreatedAt = DateTime.UtcNow
            };

            if (dto.SupplierId.HasValue)
            {
                var supplier = await _uow.Suppliers.GetByIdAsync(dto.SupplierId.Value, ct)
                    ?? throw new InvalidOperationException("Không tìm thấy nhà cung cấp");

                var beforeDebt = supplier.Debt;
                var delta = dto.Amount; // Chi tiền trả NCC làm nợ âm tiến về 0 (+delta)
                var afterDebt = beforeDebt + delta;
                supplier.Debt = afterDebt;
                supplier.UpdatedAt = DateTime.UtcNow;
                _uow.Suppliers.Update(supplier);

                await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                {
                    SupplierId = supplier.Id,
                    SourceType = DomainConstants.SourceTypes.Payment,
                    ReferenceType = DomainConstants.ReferenceTypes.Payment,
                    ReferenceId = paymentNumber,
                    Reason = $"Chi tiền trả nợ NCC theo phiếu {paymentNumber}",
                    BeforeDebt = beforeDebt,
                    Delta = delta,
                    AfterDebt = afterDebt,
                    CreatedAt = DateTime.UtcNow
                }, ct);
            }
            else if (dto.CustomerId.HasValue)
            {
                var customer = await _uow.Customers.GetByIdAsync(dto.CustomerId.Value, ct)
                    ?? throw new NotFoundException($"Không tìm thấy khách hàng với ID {dto.CustomerId.Value}");

                var beforeDebt = customer.Debt;
                var delta = dto.Amount; // Chi tiền cho khách (hoàn tiền hoặc tăng phải thu): delta = +Amount
                var afterDebt = beforeDebt + delta;
                customer.Debt = afterDebt;
                customer.UpdatedAt = DateTime.UtcNow;
                _uow.Customers.Update(customer);

                await _uow.CustomerDebtHistories.AddAsync(new CustomerDebtHistory
                {
                    CustomerId = customer.Id,
                    SourceType = DomainConstants.SourceTypes.Payment,
                    ReferenceType = DomainConstants.ReferenceTypes.Payment,
                    ReferenceId = paymentNumber,
                    Reason = $"Chi trả lại tiền cho khách theo phiếu {paymentNumber}",
                    BeforeDebt = beforeDebt,
                    Delta = delta,
                    AfterDebt = afterDebt,
                    CreatedAt = DateTime.UtcNow
                }, ct);
            }

            await _uow.Payments.AddAsync(payment, ct);
            await _uow.SaveChangesAsync(ct);
            await _uow.CommitAsync(ct);

            return MapToDto(payment);
        }
        catch
        {
            await _uow.RollbackAsync(ct);
            throw;
        }
    }

    public async Task<bool> UpdateStatusAsync(long id, string action, CancellationToken ct = default)
    {
        var payment = await _uow.Payments.Query()
            .Include(p => p.Supplier)
            .Include(p => p.Customer)
            .FirstOrDefaultAsync(p => p.Id == id, ct)
            ?? throw new NotFoundException($"Không tìm thấy phiếu chi có ID {id}");

        if (!action.Equals("cancel", StringComparison.OrdinalIgnoreCase) && !action.Equals("restore", StringComparison.OrdinalIgnoreCase))
        {
            throw new BusinessRuleException($"Hành động '{action}' không được hỗ trợ");
        }

        await _uow.BeginTransactionAsync(ct);
        try
        {
            if (action.Equals("cancel", StringComparison.OrdinalIgnoreCase))
            {
                if (payment.Status == DomainConstants.VoucherStatuses.Cancelled) return true;

                if (payment.SupplierId.HasValue && payment.Supplier != null)
                {
                    var beforeDebt = payment.Supplier.Debt;
                    var delta = -payment.Amount; // Re-debt to supplier
                    var afterDebt = beforeDebt + delta;
                    payment.Supplier.Debt = afterDebt;
                    payment.Supplier.UpdatedAt = DateTime.UtcNow;
                    _uow.Suppliers.Update(payment.Supplier);

                    await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                    {
                        SupplierId = payment.Supplier.Id,
                        SourceType = "payment_cancelled",
                        ReferenceType = DomainConstants.ReferenceTypes.Payment,
                        ReferenceId = payment.PaymentNumber,
                        Reason = $"Khôi phục nợ NCC do hủy phiếu chi {payment.PaymentNumber}",
                        BeforeDebt = beforeDebt,
                        Delta = delta,
                        AfterDebt = afterDebt,
                        CreatedAt = DateTime.UtcNow
                    }, ct);
                }
                else if (payment.CustomerId.HasValue && payment.Customer != null)
                {
                    var beforeDebt = payment.Customer.Debt;
                    var delta = -payment.Amount; // Hủy phiếu chi cho khách: giảm nợ lại
                    var afterDebt = beforeDebt + delta;
                    payment.Customer.Debt = afterDebt;
                    payment.Customer.UpdatedAt = DateTime.UtcNow;
                    _uow.Customers.Update(payment.Customer);

                    await _uow.CustomerDebtHistories.AddAsync(new CustomerDebtHistory
                    {
                        CustomerId = payment.Customer.Id,
                        SourceType = "payment_cancelled",
                        ReferenceType = DomainConstants.ReferenceTypes.Payment,
                        ReferenceId = payment.PaymentNumber,
                        Reason = $"Hủy phiếu chi cho khách {payment.PaymentNumber}",
                        BeforeDebt = beforeDebt,
                        Delta = delta,
                        AfterDebt = afterDebt,
                        CreatedAt = DateTime.UtcNow
                    }, ct);
                }

                payment.Status = DomainConstants.VoucherStatuses.Cancelled;
                payment.CancelledAt = DateTime.UtcNow;
            }
            else if (action.Equals("restore", StringComparison.OrdinalIgnoreCase))
            {
                if (payment.Status == DomainConstants.VoucherStatuses.Confirmed) return true;

                if (payment.SupplierId.HasValue && payment.Supplier != null)
                {
                    var beforeDebt = payment.Supplier.Debt;
                    var delta = payment.Amount;
                    var afterDebt = beforeDebt + delta;
                    payment.Supplier.Debt = afterDebt;
                    payment.Supplier.UpdatedAt = DateTime.UtcNow;
                    _uow.Suppliers.Update(payment.Supplier);

                    await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                    {
                        SupplierId = payment.Supplier.Id,
                        SourceType = "payment_restored",
                        ReferenceType = DomainConstants.ReferenceTypes.Payment,
                        ReferenceId = payment.PaymentNumber,
                        Reason = $"Trừ nợ NCC do khôi phục phiếu chi {payment.PaymentNumber}",
                        BeforeDebt = beforeDebt,
                        Delta = delta,
                        AfterDebt = afterDebt,
                        CreatedAt = DateTime.UtcNow
                    }, ct);
                }
                else if (payment.CustomerId.HasValue && payment.Customer != null)
                {
                    var beforeDebt = payment.Customer.Debt;
                    var delta = payment.Amount; // Khôi phục phiếu chi cho khách: tăng lại
                    var afterDebt = beforeDebt + delta;
                    payment.Customer.Debt = afterDebt;
                    payment.Customer.UpdatedAt = DateTime.UtcNow;
                    _uow.Customers.Update(payment.Customer);

                    await _uow.CustomerDebtHistories.AddAsync(new CustomerDebtHistory
                    {
                        CustomerId = payment.Customer.Id,
                        SourceType = "payment_restored",
                        ReferenceType = DomainConstants.ReferenceTypes.Payment,
                        ReferenceId = payment.PaymentNumber,
                        Reason = $"Khôi phục phiếu chi cho khách {payment.PaymentNumber}",
                        BeforeDebt = beforeDebt,
                        Delta = delta,
                        AfterDebt = afterDebt,
                        CreatedAt = DateTime.UtcNow
                    }, ct);
                }

                payment.Status = DomainConstants.VoucherStatuses.Confirmed;
                payment.CancelledAt = null;
            }

            _uow.Payments.Update(payment);
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

    public async Task<bool> DeletePaymentAsync(long id, CancellationToken ct = default)
    {
        var payment = await _uow.Payments.Query()
            .Include(p => p.Supplier)
            .Include(p => p.Customer)
            .FirstOrDefaultAsync(p => p.Id == id, ct)
            ?? throw new NotFoundException($"Không tìm thấy phiếu chi có ID {id}");

        await _uow.BeginTransactionAsync(ct);
        try
        {
            if (payment.Status == DomainConstants.VoucherStatuses.Confirmed)
            {
                await UpdateStatusAsync(id, "cancel", ct);
            }

            _uow.Payments.Remove(payment);
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

    private static PaymentDto MapToDto(Payment p) => new()
    {
        Id = p.Id,
        PaymentNumber = p.PaymentNumber,
        Date = p.Date,
        SupplierId = p.SupplierId,
        SupplierName = p.Supplier?.Name,
        CustomerId = p.CustomerId,
        CustomerName = p.Customer?.Name,
        Amount = p.Amount,
        Method = p.Method,
        Status = p.Status,
        CancelledAt = p.CancelledAt,
        RelatedVoucherType = p.RelatedVoucherType,
        RelatedVoucherId = p.RelatedVoucherId,
        Notes = p.Notes,
        CreatedAt = p.CreatedAt
    };
}
