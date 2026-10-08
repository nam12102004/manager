using DebtManager.Application.Common.Exceptions;
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
                                     (c.PhonesJson != null && c.PhonesJson.ToLower().Contains(s)));
        }

        var list = await query.OrderByDescending(c => c.Id).ToListAsync(ct);
        return list.Select(MapToDto).ToList();
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
        customer.CreditLimit = dto.CreditLimit;
        customer.Notes = dto.Notes?.Trim();
        customer.UpdatedAt = DateTime.UtcNow;

        _uow.Customers.Update(customer);
        await _uow.SaveChangesAsync(ct);

        return MapToDto(customer);
    }

    public async Task<List<CustomerDebtHistoryDto>> GetDebtHistoryAsync(int customerId, CancellationToken ct = default)
    {
        var customerExists = await _uow.Customers.Query().AnyAsync(c => c.Id == customerId, ct);
        if (!customerExists)
        {
            throw new NotFoundException($"Không tìm thấy khách hàng với ID {customerId}");
        }

        var list = await _uow.CustomerDebtHistories.Query()
            .Where(h => h.CustomerId == customerId)
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

    private static CustomerDto MapToDto(Customer c) => new()
    {
        Id = c.Id,
        Code = c.Code,
        Name = c.Name,
        ContactName = c.ContactName,
        PhonesJson = c.PhonesJson,
        Email = c.Email,
        AddressesJson = c.AddressesJson,
        Debt = c.Debt,
        CreditLimit = c.CreditLimit,
        Notes = c.Notes,
        CreatedAt = c.CreatedAt,
        UpdatedAt = c.UpdatedAt
    };
}
