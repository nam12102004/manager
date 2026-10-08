using DebtManager.Api.Common;
using DebtManager.Application.Common;
using DebtManager.Application.DTOs.Auth;
using DebtManager.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DebtManager.Api.Controllers;

public class AuthController : BaseApiController
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<LoginResponseDto>>> Login(
        [FromBody] LoginRequestDto request,
        CancellationToken ct)
        => Success(await _authService.LoginAsync(request, ct), "Đăng nhập thành công");
}
