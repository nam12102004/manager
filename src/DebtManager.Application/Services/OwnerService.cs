using DebtManager.Application.DTOs.Owners;
using DebtManager.Application.Interfaces;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Application.Services;

public class OwnerService : IOwnerService
{
    private readonly IUnitOfWork _uow;

    public OwnerService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<OwnerDto> GetOwnerInfoAsync(CancellationToken ct = default)
    {
        var owner = await _uow.Owners.Query().FirstOrDefaultAsync(ct);
        if (owner == null)
        {
            owner = new Owner
            {
                Info = "CỬA HÀNG - VUI LÒNG CẬP NHẬT THÔNG TIN TÀI KHOẢN",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            await _uow.Owners.AddAsync(owner, ct);
            await _uow.SaveChangesAsync(ct);
        }

        return new OwnerDto
        {
            Id = owner.Id,
            Info = owner.Info,
            CreatedAt = owner.CreatedAt,
            UpdatedAt = owner.UpdatedAt
        };
    }

    public async Task<OwnerDto> UpdateOwnerInfoAsync(UpdateOwnerDto dto, CancellationToken ct = default)
    {
        var owner = await _uow.Owners.Query().FirstOrDefaultAsync(ct);
        if (owner == null)
        {
            owner = new Owner
            {
                Info = dto.Info.Trim(),
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            await _uow.Owners.AddAsync(owner, ct);
        }
        else
        {
            owner.Info = dto.Info.Trim();
            owner.UpdatedAt = DateTime.UtcNow;
            _uow.Owners.Update(owner);
        }

        await _uow.SaveChangesAsync(ct);

        return new OwnerDto
        {
            Id = owner.Id,
            Info = owner.Info,
            CreatedAt = owner.CreatedAt,
            UpdatedAt = owner.UpdatedAt
        };
    }
}
