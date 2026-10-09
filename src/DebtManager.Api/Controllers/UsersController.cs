using DebtManager.Api.Common;
using DebtManager.Application.Common;
using DebtManager.Application.DTOs.Users;
using DebtManager.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DebtManager.Api.Controllers;

public class UsersController : BaseApiController
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet]
    public async Task<IActionResult> GetUsers(
        [FromQuery] string? q,
        [FromQuery] int? page,
        [FromQuery] int pageSize = 15,
        [FromQuery] bool all = false,
        CancellationToken ct = default)
    {
        if (page.HasValue && !all)
        {
            var paged = await _userService.GetPagedUsersAsync(q, page.Value, pageSize, ct);
            return Success(paged);
        }

        var users = await _userService.GetUsersAsync(ct);
        return Success(users);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<UserDto>>> GetById(int id, CancellationToken ct)
    {
        var user = await _userService.GetByIdAsync(id, ct);
        return Success(user);
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<UserDto>>> CreateUser(
        [FromBody] CreateUserDto dto,
        CancellationToken ct)
    {
        var user = await _userService.CreateUserAsync(dto, ct);
        return Created(nameof(GetById), new { id = user.Id }, user, "Tạo tài khoản thành công");
    }

    [HttpPut("{id:int}/password")]
    public async Task<ActionResult<ApiResponse<bool>>> ChangePassword(
        int id,
        [FromBody] ChangePasswordDto dto,
        CancellationToken ct)
    {
        var result = await _userService.ChangePasswordAsync(id, dto, ct);
        return Success(result, "Đổi mật khẩu thành công");
    }

    [HttpPut("{id:int}/role")]
    public async Task<ActionResult<ApiResponse<bool>>> UpdateRole(
        int id,
        [FromBody] UpdateUserRoleDto dto,
        CancellationToken ct)
    {
        var result = await _userService.UpdateRoleAsync(id, dto, ct);
        return Success(result, "Cập nhật quyền thành công");
    }

    [HttpDelete("{id:int}")]
    public async Task<ActionResult<ApiResponse<bool>>> DeleteUser(
        int id,
        CancellationToken ct)
    {
        var result = await _userService.DeleteUserAsync(id, ct);
        return Success(result, "Xóa tài khoản thành công");
    }
}
