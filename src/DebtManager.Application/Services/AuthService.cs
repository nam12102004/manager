using System.Security.Cryptography;
using System.Text;
using DebtManager.Application.Common.Exceptions;
using DebtManager.Application.DTOs.Auth;
using DebtManager.Application.Interfaces;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Application.Services;

public class AuthService : IAuthService
{
    private readonly IUnitOfWork _uow;

    public AuthService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<LoginResponseDto> LoginAsync(LoginRequestDto request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
        {
            throw new ValidationException("Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu");
        }

        var usersCount = await _uow.Users.Query().CountAsync(ct);
        if (usersCount == 0)
        {
            // Seed default admin account
            var adminUser = new User
            {
                Username = "admin",
                PasswordHash = HashPassword("admin123"),
                Role = "admin",
                CreatedAt = DateTime.UtcNow
            };
            await _uow.Users.AddAsync(adminUser, ct);
            await _uow.SaveChangesAsync(ct);
        }

        var user = await _uow.Users.Query()
            .FirstOrDefaultAsync(u => u.Username.ToLower() == request.Username.Trim().ToLower(), ct);

        if (user == null || !VerifyPassword(request.Password, user.PasswordHash))
        {
            try
            {
                await _uow.LoginHistories.AddAsync(new LoginHistory
                {
                    Username = request.Username.Trim(),
                    IsSuccess = false,
                    Note = "Sai mật khẩu hoặc tài khoản không tồn tại",
                    LoginTime = DateTime.UtcNow
                }, ct);
                await _uow.SaveChangesAsync(ct);
            }
            catch { /* Ignore logging error */ }

            throw new UnauthorizedException("Tên đăng nhập hoặc mật khẩu không chính xác");
        }

        try
        {
            await _uow.LoginHistories.AddAsync(new LoginHistory
            {
                Username = user.Username,
                IsSuccess = true,
                Note = "Đăng nhập thành công",
                LoginTime = DateTime.UtcNow
            }, ct);
            await _uow.SaveChangesAsync(ct);
        }
        catch { /* Ignore logging error */ }

        return new LoginResponseDto
        {
            Token = Guid.NewGuid().ToString("N"),
            Username = user.Username,
            Role = user.Role
        };
    }

    private static string HashPassword(string password)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(password));
        return Convert.ToBase64String(bytes);
    }

    private static bool VerifyPassword(string password, string storedHash)
    {
        var hash = HashPassword(password);
        return hash == storedHash;
    }
}
