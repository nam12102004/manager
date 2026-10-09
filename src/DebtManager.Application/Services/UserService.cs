using System.Security.Cryptography;
using System.Text;
using DebtManager.Application.Common;
using DebtManager.Application.Common.Exceptions;
using DebtManager.Application.DTOs.Users;
using DebtManager.Application.Interfaces;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Application.Services;

public class UserService : IUserService
{
    private readonly IUnitOfWork _uow;

    public UserService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<List<UserDto>> GetUsersAsync(CancellationToken ct = default)
    {
        var users = await _uow.Users.Query()
            .OrderByDescending(u => u.Id)
            .ToListAsync(ct);

        return users.Select(u => new UserDto
        {
            Id = u.Id,
            Username = u.Username,
            Role = u.Role,
            CreatedAt = u.CreatedAt
        }).ToList();
    }

    public async Task<PagedResult<UserDto>> GetPagedUsersAsync(string? search = null, int page = 1, int pageSize = 15, CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = pageSize > 0 ? pageSize : 15;

        var query = _uow.Users.Query().AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(u => u.Username.ToLower().Contains(s) || u.Role.ToLower().Contains(s));
        }

        var totalCount = await query.CountAsync(ct);

        var items = await query
            .OrderByDescending(u => u.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new UserDto
            {
                Id = u.Id,
                Username = u.Username,
                Role = u.Role,
                CreatedAt = u.CreatedAt
            })
            .ToListAsync(ct);

        return new PagedResult<UserDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<UserDto> GetByIdAsync(int id, CancellationToken ct = default)
    {
        var user = await _uow.Users.GetByIdAsync(id, ct)
            ?? throw new NotFoundException($"Không tìm thấy tài khoản với ID {id}");

        return new UserDto
        {
            Id = user.Id,
            Username = user.Username,
            Role = user.Role,
            CreatedAt = user.CreatedAt
        };
    }

    public async Task<UserDto> CreateUserAsync(CreateUserDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Username))
        {
            throw new ValidationException("Tên đăng nhập không được để trống");
        }

        if (string.IsNullOrWhiteSpace(dto.Password) || dto.Password.Length < 6)
        {
            throw new ValidationException("Mật khẩu phải có ít nhất 6 ký tự");
        }

        var username = dto.Username.Trim().ToLower();
        var exists = await _uow.Users.Query().AnyAsync(u => u.Username.ToLower() == username, ct);
        if (exists)
        {
            throw new ValidationException($"Tên đăng nhập '{dto.Username.Trim()}' đã tồn tại trên hệ thống");
        }

        var role = string.IsNullOrWhiteSpace(dto.Role) ? "nv" : dto.Role.Trim().ToLower();
        if (role != "admin" && role != "nv")
        {
            role = "nv";
        }

        var user = new User
        {
            Username = dto.Username.Trim(),
            PasswordHash = HashPassword(dto.Password),
            Role = role,
            CreatedAt = DateTime.UtcNow
        };

        await _uow.Users.AddAsync(user, ct);
        await _uow.SaveChangesAsync(ct);

        return new UserDto
        {
            Id = user.Id,
            Username = user.Username,
            Role = user.Role,
            CreatedAt = user.CreatedAt
        };
    }

    public async Task<bool> ChangePasswordAsync(int id, ChangePasswordDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.NewPassword) || dto.NewPassword.Length < 6)
        {
            throw new ValidationException("Mật khẩu mới phải có ít nhất 6 ký tự");
        }

        var user = await _uow.Users.GetByIdAsync(id, ct)
            ?? throw new NotFoundException($"Không tìm thấy tài khoản với ID {id}");

        user.PasswordHash = HashPassword(dto.NewPassword);
        _uow.Users.Update(user);
        await _uow.SaveChangesAsync(ct);

        return true;
    }

    public async Task<bool> UpdateRoleAsync(int id, UpdateUserRoleDto dto, CancellationToken ct = default)
    {
        var user = await _uow.Users.GetByIdAsync(id, ct)
            ?? throw new NotFoundException($"Không tìm thấy tài khoản với ID {id}");

        var role = string.IsNullOrWhiteSpace(dto.Role) ? "nv" : dto.Role.Trim().ToLower();
        if (role != "admin" && role != "nv")
        {
            role = "nv";
        }

        user.Role = role;
        _uow.Users.Update(user);
        await _uow.SaveChangesAsync(ct);

        return true;
    }

    public async Task<bool> DeleteUserAsync(int id, CancellationToken ct = default)
    {
        var user = await _uow.Users.GetByIdAsync(id, ct)
            ?? throw new NotFoundException($"Không tìm thấy tài khoản với ID {id}");

        if (user.Username.ToLower() == "admin")
        {
            throw new ValidationException("Không thể xóa tài khoản Quản trị viên mặc định (admin)");
        }

        _uow.Users.Remove(user);
        await _uow.SaveChangesAsync(ct);

        return true;
    }

    private static string HashPassword(string password)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(password));
        return Convert.ToBase64String(bytes);
    }
}
